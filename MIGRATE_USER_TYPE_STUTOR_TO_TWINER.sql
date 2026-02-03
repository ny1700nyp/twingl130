-- Migrate profiles.user_type: stutor → twiner (hybrid Tutor+Student).
-- Run in Supabase SQL Editor after deploying app code that uses 'twiner'.

-- 1) Drop existing CHECK
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_user_type_check;

-- 2) Migrate existing data: stutor → twiner
UPDATE profiles SET user_type = 'twiner' WHERE user_type = 'stutor';

-- 3) Add new CHECK (tutor, student, twiner only)
ALTER TABLE profiles
  ADD CONSTRAINT profiles_user_type_check
  CHECK (user_type IN ('tutor', 'student', 'twiner'));

-- 4) Comment
COMMENT ON COLUMN profiles.user_type IS 'tutor | student | twiner (tutor=선생, student=학생, twiner=둘 다)';

-- 5) RPC 사용 시 CREATE_TALENT_MATCHING_PROFILES_FUNCTION.sql 재실행 (user_type에 twiner 반영됨).
