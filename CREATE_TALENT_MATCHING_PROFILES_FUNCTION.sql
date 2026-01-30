-- Talent matching profiles function (distance independent)
-- Shows only trainer cards with >0 keyword matches, ordered by match_count desc.
--
-- Matching logic:
-- - If current user is trainer: match (my talents) vs (trainer talents)
-- - If current user is trainee: match (my talents-as-goals) vs (trainer talents)
--
-- Exclusion:
-- - matches.is_match = true  => always excluded
-- - matches.is_match = false => excluded only if within 5 minutes

CREATE OR REPLACE FUNCTION get_talent_matching_profiles(
  p_user_id UUID,
  p_user_type TEXT,
  p_limit INTEGER DEFAULT 100
)
RETURNS TABLE (
  id UUID,
  user_id UUID,
  user_type TEXT,
  name TEXT,
  gender TEXT,
  age INTEGER,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  talents TEXT[],
  interests TEXT[],
  main_photo_path TEXT,
  experience_description TEXT,
  certificate_photos TEXT[],
  created_at TIMESTAMP WITH TIME ZONE,
  match_count INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  WITH current_user_keywords AS (
    SELECT ARRAY(
      SELECT lower(x)
      FROM unnest(
        COALESCE(
          (SELECT talents FROM profiles WHERE user_id = p_user_id),
          '{}'::text[]
        )
      ) AS x
      WHERE x IS NOT NULL AND btrim(x) <> ''
    ) AS keywords
  ),
  excluded_users AS (
    SELECT swiped_user_id
    FROM matches
    WHERE user_id = p_user_id
      AND (
        is_match = true
        OR (
          is_match = false
          AND created_at > NOW() - INTERVAL '5 minutes'
        )
      )
  )
  SELECT
    p.id,
    p.user_id,
    p.user_type,
    p.name,
    p.gender,
    p.age,
    p.latitude,
    p.longitude,
    p.talents,
    p.interests,
    p.main_photo_path,
    p.experience_description,
    p.certificate_photos,
    p.created_at,
    mc.match_count
  FROM profiles p
  CROSS JOIN current_user_keywords cuk
  CROSS JOIN LATERAL (
    SELECT count(*)::int AS match_count
    FROM unnest(COALESCE(p.talents, '{}'::text[])) t
    WHERE lower(t) = ANY(cuk.keywords)
  ) mc
  WHERE p.user_type = 'trainer'
    AND p.user_id != get_talent_matching_profiles.p_user_id
    AND p.user_id NOT IN (SELECT swiped_user_id FROM excluded_users)
    AND mc.match_count > 0
  ORDER BY mc.match_count DESC, p.name ASC
  LIMIT p_limit;
END;
$$;

