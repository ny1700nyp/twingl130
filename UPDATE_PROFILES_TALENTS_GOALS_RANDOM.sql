-- 풀: 아래 항목 중 중복 제거 후, 프로필마다 랜덤하게 12개 선택 → 6개는 talents, 6개는 goals
-- (talents와 goals 간 겹치지 않음)

WITH pool AS (
  SELECT unnest(ARRAY[
    'Personal Training (PT)',
    'Cycling/Bicycle',
    'Inline Skate',
    'Horse Riding',
    'Shooting',
    'Ice Skating',
    'Marathon/Running',
    'Skateboarding',
    'Climbing/Bouldering',
    'Gymnastics',
    'sleeping',
    'Neon Craft',
    'Fashion Design',
    'String Art',
    'Chess',
    'Career Coaching',
    'Skiing',
    'Video Editing',
    'American Literature',
    'Fishing',
    'Social Role Play',
    'Nunchaku',
    'British Literature',
    'Kayak',
    'Sand Art',
    'Tamil',
    'Kung Fu',
    'Eastern Astrology/Saju',
    'Napkin Art'
  ]) AS item
),
distinct_pool AS (
  SELECT DISTINCT item FROM pool
),
-- 프로필별로 풀을 랜덤 섞어서 12개만 취함 (행마다 다른 random: LATERAL에서 p.user_id 참조로 행별 재실행)
per_profile AS (
  SELECT p.user_id, sh.shuffled
  FROM profiles p
  CROSS JOIN LATERAL (
    SELECT array_agg(d.item ORDER BY random()) AS shuffled
    FROM distinct_pool d
    WHERE p.user_id IS NOT NULL
  ) sh
),
first_12 AS (
  SELECT
    user_id,
    shuffled[1:12] AS arr12
  FROM per_profile
)
UPDATE profiles p
SET
  talents    = f.arr12[1:6],
  goals      = f.arr12[7:12],
  updated_at = NOW()
FROM first_12 f
WHERE p.user_id = f.user_id;
