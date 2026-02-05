-- 거리 기반 Search RPC: DB에서 처리 후 최대 N개만 반환 (트래픽 절감)
-- latitude, longitude 직접 사용 (PostGIS/geom_geog/확장 불필요)
--
-- =============================================================================
-- 세 함수 조건 정리
-- =============================================================================
--
-- | 항목        | 1) Meet Tutors       | 2) Fellow tutors     | 3) Student candidates |
-- |-------------|----------------------|----------------------|------------------------|
-- | 화면        | Meet Tutors in area  | Fellow tutors area   | Student candidates     |
-- | 사용자      | Student/Twiner       | Tutor/Twiner         | Tutor/Twiner           |
-- | 내 키워드   | Goals (I want to learn) | Talents (I can teach) | Talents (I can teach) |
-- | 상대 키워드 | Talents              | Talents              | Goals                  |
-- | 대상 타입   | Tutor, Twiner        | Tutor, Twiner        | Student, Twiner        |
-- | 거리        | ≤30km                | ≤30km                | ≤30km                  |
-- | match_count | 0도 표시             | 0도 표시             | > 0 만 표시            |
-- | 정렬        | match DESC, distance ASC | match DESC, distance ASC | match DESC, distance ASC |
-- | limit       | 20                   | 30                   | 30                     |
-- | Exclusion   | liked (is_match=true) | liked (is_match=true) | liked (is_match=true) |
--
-- =============================================================================

-- Haversine 거리(미터). 표준 SQL만 사용, 확장 불필요.
CREATE OR REPLACE FUNCTION _haversine_meters(
  lat1 DOUBLE PRECISION, lon1 DOUBLE PRECISION,
  lat2 DOUBLE PRECISION, lon2 DOUBLE PRECISION
) RETURNS DOUBLE PRECISION
LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE
    WHEN lat1 IS NULL OR lon1 IS NULL OR lat2 IS NULL OR lon2 IS NULL THEN NULL
    ELSE 6371000.0 * acos(LEAST(1.0, GREATEST(-1.0,
      sin(radians(lat1)) * sin(radians(lat2)) +
      cos(radians(lat1)) * cos(radians(lat2)) * cos(radians(lon2 - lon1))
    )))
  END
$$;

-- =============================================================================
-- 1) [Meet Tutors in your area] Student/Twiner: my goals ↔ target talents
--    Target: Tutor+Twiner, ≤30km, match_count 0도 표시, 정렬: match DESC, distance ASC
-- =============================================================================
CREATE OR REPLACE FUNCTION get_nearby_tutors_for_student(
  p_user_id UUID,
  p_latitude DOUBLE PRECISION,
  p_longitude DOUBLE PRECISION,
  p_max_distance_meters DOUBLE PRECISION DEFAULT 30000,
  p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (user_id UUID, match_count INTEGER, distance_meters DOUBLE PRECISION)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_keywords TEXT[];
  v_has_goals BOOLEAN;
  v_uid UUID := p_user_id;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'goals'
  ) INTO v_has_goals;

  IF v_has_goals THEN
    SELECT ARRAY(
      SELECT lower(btrim(x)) FROM unnest(
        COALESCE((SELECT goals FROM profiles WHERE profiles.user_id = v_uid), '{}'::text[])
      ) AS x
      WHERE x IS NOT NULL AND btrim(x) <> ''
    ) INTO v_keywords;
  ELSE
    SELECT ARRAY(
      SELECT lower(btrim(x)) FROM unnest(
        COALESCE((SELECT talents FROM profiles WHERE profiles.user_id = v_uid), '{}'::text[])
      ) AS x
      WHERE x IS NOT NULL AND btrim(x) <> ''
    ) INTO v_keywords;
  END IF;

  RETURN QUERY
  WITH excluded AS (
    SELECT m.swiped_user_id FROM matches m WHERE m.user_id = v_uid AND m.is_match = true
  ),
  candidates AS (
    SELECT
      p.user_id,
      (SELECT count(*)::int
       FROM unnest(COALESCE(p.talents, '{}'::text[])) t
       WHERE lower(btrim(t)) = ANY(v_keywords)
      ) AS cnt,
      _haversine_meters(p_latitude, p_longitude, p.latitude::double precision, p.longitude::double precision) AS dist
    FROM profiles p
    WHERE p.user_type IN ('tutor', 'twiner')
      AND p.user_id != v_uid
      AND p.user_id NOT IN (SELECT excluded.swiped_user_id FROM excluded)
      AND p.latitude IS NOT NULL
      AND p.longitude IS NOT NULL
      AND _haversine_meters(p_latitude, p_longitude, p.latitude::double precision, p.longitude::double precision) <= p_max_distance_meters
  )
  SELECT c.user_id, c.cnt, c.dist
  FROM candidates c
  WHERE c.dist IS NOT NULL
  ORDER BY c.cnt DESC, c.dist ASC
  LIMIT p_limit;
END;
$$;

-- =============================================================================
-- 2) [Fellow tutors in the area] Tutor/Twiner: my talents ↔ target talents
--    Target: Tutor+Twiner, ≤30km, 정렬: match DESC, distance ASC
-- =============================================================================
CREATE OR REPLACE FUNCTION get_nearby_trainers_for_tutor(
  p_user_id UUID,
  p_latitude DOUBLE PRECISION,
  p_longitude DOUBLE PRECISION,
  p_max_distance_meters DOUBLE PRECISION DEFAULT 30000,
  p_limit INTEGER DEFAULT 30
)
RETURNS TABLE (user_id UUID, match_count INTEGER, distance_meters DOUBLE PRECISION)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_keywords TEXT[];
  v_uid UUID := p_user_id;
BEGIN
  SELECT ARRAY(
    SELECT lower(btrim(x)) FROM unnest(
      COALESCE((SELECT talents FROM profiles WHERE profiles.user_id = v_uid), '{}'::text[])
    ) AS x
    WHERE x IS NOT NULL AND btrim(x) <> ''
  ) INTO v_keywords;

  RETURN QUERY
  WITH excluded AS (
    SELECT m.swiped_user_id FROM matches m WHERE m.user_id = v_uid AND m.is_match = true
  ),
  candidates AS (
    SELECT
      p.user_id,
      (SELECT count(*)::int
       FROM unnest(COALESCE(p.talents, '{}'::text[])) t
       WHERE lower(btrim(t)) = ANY(v_keywords)
      ) AS cnt,
      _haversine_meters(p_latitude, p_longitude, p.latitude::double precision, p.longitude::double precision) AS dist
    FROM profiles p
    WHERE p.user_type IN ('tutor', 'twiner')
      AND p.user_id != v_uid
      AND p.user_id NOT IN (SELECT excluded.swiped_user_id FROM excluded)
      AND p.latitude IS NOT NULL
      AND p.longitude IS NOT NULL
      AND _haversine_meters(p_latitude, p_longitude, p.latitude::double precision, p.longitude::double precision) <= p_max_distance_meters
  )
  SELECT c.user_id, c.cnt, c.dist
  FROM candidates c
  WHERE c.dist IS NOT NULL
  ORDER BY c.cnt DESC, c.dist ASC
  LIMIT p_limit;
END;
$$;

-- =============================================================================
-- 3) [Student candidates] Tutor/Twiner: my talents ↔ target goals
--    Target: Student+Twiner, ≤30km, match_count > 0 만, 정렬: match DESC, distance ASC
--    상대 키워드: goals 컬럼만. goals 없으면 no match (talents fallback 없음)
-- =============================================================================
CREATE OR REPLACE FUNCTION get_nearby_students_for_tutor(
  p_user_id UUID,
  p_latitude DOUBLE PRECISION,
  p_longitude DOUBLE PRECISION,
  p_max_distance_meters DOUBLE PRECISION DEFAULT 30000,
  p_limit INTEGER DEFAULT 30
)
RETURNS TABLE (user_id UUID, match_count INTEGER, distance_meters DOUBLE PRECISION)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_keywords TEXT[];
  v_uid UUID := p_user_id;
  v_has_goals BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'goals'
  ) INTO v_has_goals;

  IF NOT v_has_goals THEN
    RETURN;  -- goals 컬럼 없으면 no match
  END IF;

  SELECT ARRAY(
    SELECT lower(btrim(x)) FROM unnest(
      COALESCE((SELECT talents FROM profiles WHERE profiles.user_id = v_uid), '{}'::text[])
    ) AS x
    WHERE x IS NOT NULL AND btrim(x) <> ''
  ) INTO v_keywords;

  RETURN QUERY
  WITH excluded AS (
    SELECT m.swiped_user_id FROM matches m WHERE m.user_id = v_uid AND m.is_match = true
  ),
  candidates AS (
    SELECT
      p.user_id,
      (SELECT count(*)::int
       FROM unnest(COALESCE((SELECT goals FROM profiles pr WHERE pr.user_id = p.user_id), '{}'::text[])) AS t(x)
       WHERE lower(btrim(x)) = ANY(v_keywords)
      ) AS cnt,
      _haversine_meters(p_latitude, p_longitude, p.latitude::double precision, p.longitude::double precision) AS dist
    FROM profiles p
    WHERE p.user_type IN ('student', 'twiner')
      AND p.user_id != v_uid
      AND p.user_id NOT IN (SELECT excluded.swiped_user_id FROM excluded)
      AND p.latitude IS NOT NULL
      AND p.longitude IS NOT NULL
      AND _haversine_meters(p_latitude, p_longitude, p.latitude::double precision, p.longitude::double precision) <= p_max_distance_meters
  )
  SELECT c.user_id, c.cnt, c.dist
  FROM candidates c
  WHERE c.cnt > 0 AND c.dist IS NOT NULL
  ORDER BY c.cnt DESC, c.dist ASC
  LIMIT p_limit;
END;
$$;

GRANT EXECUTE ON FUNCTION get_nearby_tutors_for_student(uuid, double precision, double precision, double precision, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION get_nearby_trainers_for_tutor(uuid, double precision, double precision, double precision, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION get_nearby_students_for_tutor(uuid, double precision, double precision, double precision, integer) TO authenticated;
