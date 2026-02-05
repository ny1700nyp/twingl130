-- Global Talent Matching: DB에서 매칭 후 앱에 반환 (트래픽 절감)
-- [The Perfect Tutors, Anywhere] 전용.
--
-- 매칭 로직:
--   내 쪽: Student/Twiner의 Goals (I want to learn)
--   상대 쪽: Tutor/Twiner의 Talents (I can teach)
--   → Goals ∩ Talents > 0 인 튜터만 반환
--
-- Exclusion: liked users (is_match = true)만 제외
--
-- Schema: goals 컬럼이 있으면 Student/Twiner는 goals 사용, 없으면 talents 사용 (unified)

-- Return type 변경 시 기존 함수 제거 필요 (OUT parameters 다름)
DROP FUNCTION IF EXISTS get_talent_matching_profiles(uuid, text, integer);

CREATE OR REPLACE FUNCTION get_talent_matching_profiles(
  p_user_id UUID,
  p_user_type TEXT,
  p_limit INTEGER DEFAULT 30
)
RETURNS TABLE (
  user_id UUID,
  match_count INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_keywords TEXT[];
  v_has_goals BOOLEAN;
BEGIN
  -- goals 컬럼 존재 여부 확인
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'goals'
  ) INTO v_has_goals;

  -- 내 키워드: Student/Twiner → goals (I want to learn); goals 없으면 talents 사용
  IF v_has_goals AND p_user_type IN ('student', 'twiner') THEN
    SELECT ARRAY(
      SELECT lower(btrim(x))
      FROM unnest(
        COALESCE(
          (SELECT goals FROM profiles WHERE profiles.user_id = p_user_id),
          '{}'::text[]
        )
      ) AS x
      WHERE x IS NOT NULL AND btrim(x) <> ''
    ) INTO v_keywords;
  ELSE
    SELECT ARRAY(
      SELECT lower(btrim(x))
      FROM unnest(
        COALESCE(
          (SELECT talents FROM profiles WHERE profiles.user_id = p_user_id),
          '{}'::text[]
        )
      ) AS x
      WHERE x IS NOT NULL AND btrim(x) <> ''
    ) INTO v_keywords;
  END IF;

  -- 대상: Tutor/Twiner 프로필의 talents와 매칭
  RETURN QUERY
  WITH excluded_users AS (
    SELECT m.swiped_user_id
    FROM matches m
    WHERE m.user_id = p_user_id AND m.is_match = true
  ),
  matched AS (
    SELECT
      p.user_id,
      (SELECT count(*)::int
       FROM unnest(COALESCE(p.talents, '{}'::text[])) t
       WHERE lower(btrim(t)) = ANY(v_keywords)
      ) AS cnt
    FROM profiles p
    WHERE p.user_type IN ('tutor', 'twiner')
      AND p.user_id != p_user_id
      AND p.user_id NOT IN (SELECT excluded_users.swiped_user_id FROM excluded_users)
  )
  SELECT m.user_id, m.cnt
  FROM matched m
  WHERE m.cnt > 0
  ORDER BY m.cnt DESC
  LIMIT p_limit;
END;
$$;

-- RPC 호출 권한 (authenticated 사용자)
GRANT EXECUTE ON FUNCTION get_talent_matching_profiles(UUID, TEXT, INTEGER) TO authenticated;
