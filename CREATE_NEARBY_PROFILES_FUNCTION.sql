-- 거리 기반 프로필 조회 함수 생성
-- PostGIS를 사용하여 거리 계산 및 정렬을 서버에서 처리

-- PostGIS 확장 활성화 (이미 활성화되어 있을 수 있음)
CREATE EXTENSION IF NOT EXISTS postgis;

-- 거리 계산 및 정렬을 위한 함수
CREATE OR REPLACE FUNCTION get_nearby_profiles(
  p_user_id UUID,
  p_user_type TEXT,
  p_latitude DOUBLE PRECISION,
  p_longitude DOUBLE PRECISION,
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
  distance_meters DOUBLE PRECISION
) 
LANGUAGE plpgsql
AS $$
BEGIN
  -- DB 통합: trainer/trainee 모두 keywords는 profiles.talents 를 사용한다.
  -- (trainee는 talents 컬럼에 goal을 저장하고, UI에서만 'Goals'로 표기)
  -- 매칭 우선 정렬(talent-talent 또는 goal-talent)을 위해 사용.
  -- NOTE: candidates는 trainer만 반환하므로, 후보의 talents와 비교한다.
  -- 15 miles (약 24140.16m) 이내만 반환한다.
  RETURN QUERY
  WITH current_user_location AS (
    SELECT ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::geography AS location
  ),
  current_user_keywords AS (
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
        is_match = true  -- 좋아요한 경우는 항상 제외
        OR (
          is_match = false  -- 싫어요한 경우
          AND created_at > NOW() - INTERVAL '5 minutes'  -- 5분 이내인 경우만 제외
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
    -- 거리 계산 (미터 단위) - 생성된 컬럼(geom_geog) 사용
    ST_Distance(
      p.geom_geog,
      cul.location
    ) AS distance_meters
  FROM profiles p
  CROSS JOIN current_user_location cul
  CROSS JOIN current_user_keywords cuk
  CROSS JOIN LATERAL (
    SELECT count(*)::int AS match_count
    FROM unnest(COALESCE(p.talents, '{}'::text[])) t
    WHERE lower(t) = ANY(cuk.keywords)
  ) mc
  WHERE p.user_type = 'trainer'  -- Trainer와 Trainee 모두 Trainer만 봄
    AND p.user_id != get_nearby_profiles.p_user_id  -- 자기 자신 제외 (함수 파라미터 명시)
    AND p.user_id NOT IN (SELECT swiped_user_id FROM excluded_users)  -- 이미 스와이프한 사용자 제외
    AND p.geom_geog IS NOT NULL  -- 지리 정보가 있는 경우만
    AND ST_DWithin(p.geom_geog, cul.location, 24140.16)  -- 15 miles 이내만
  ORDER BY mc.match_count DESC, distance_meters ASC  -- 매칭 우선, 동률이면 거리순
  LIMIT p_limit;
END;
$$;

-- 인덱스 최적화 (이미 있을 수 있음)
-- 지리 정보 컬럼 추가 (이미 추가되어 있을 수 있음)
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS geom_geog geography(Point, 4326)
    GENERATED ALWAYS AS (ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography) STORED;

-- 인덱스 생성 (이미 생성되어 있을 수 있음)
CREATE INDEX IF NOT EXISTS profiles_geom_geog_idx ON profiles USING GIST (geom_geog);

-- 함수 테스트 (선택사항)
-- SELECT * FROM get_nearby_profiles(
--   'user-uuid-here'::UUID,
--   'trainer',
--   37.7749,  -- latitude
--   -122.4194,  -- longitude
--   50
-- );
