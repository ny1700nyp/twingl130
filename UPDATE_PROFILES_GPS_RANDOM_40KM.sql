-- profiles 테이블의 latitude, longitude를 기준점에서 최대 40km 랜덤 오프셋으로 업데이트
-- 기준: lat 37.2351185151669, lon -121.787107723681 (행마다 동일한 거리·방위로 lat/lon 계산)

WITH base AS (
  SELECT 37.2351185151669   AS lat0,
         -121.787107723681  AS lon0,
         6371.0             AS R_km
),
per_row AS (
  SELECT
    p.user_id,
    random() * 40 AS dist_km,
    2 * pi() * random() AS bearing_rad,
    (SELECT lat0 FROM base) * pi()/180 AS lat0_rad,
    (SELECT lon0 FROM base) * pi()/180 AS lon0_rad,
    (SELECT R_km FROM base) AS R_km
  FROM profiles p
),
computed AS (
  SELECT
    user_id,
    dist_km,
    bearing_rad,
    lat0_rad,
    lon0_rad,
    asin(sin(lat0_rad) * cos(dist_km / R_km)
         + cos(lat0_rad) * sin(dist_km / R_km) * cos(bearing_rad)) AS new_lat_rad,
    lon0_rad + atan2(
      sin(bearing_rad) * sin(dist_km / R_km) * cos(lat0_rad),
      cos(dist_km / R_km) - sin(lat0_rad) * sin(asin(
        sin(lat0_rad) * cos(dist_km / R_km)
        + cos(lat0_rad) * sin(dist_km / R_km) * cos(bearing_rad)
      ))
    ) AS new_lon_rad
  FROM per_row
)
UPDATE profiles p
SET
  latitude  = (c.new_lat_rad * 180/pi()),
  longitude = (c.new_lon_rad * 180/pi()),
  updated_at = NOW()
FROM computed c
WHERE p.user_id = c.user_id;
