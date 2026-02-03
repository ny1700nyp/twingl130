-- Migrate profiles.user_type: tudent → stutor (hybrid). (레거시: 현재는 stutor→twiner 사용)
-- Run after deploying app code that uses 'stutor' instead of 'tudent'.

-- 1) Drop existing CHECK so we can change the allowed value
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_user_type_check;

-- 2) Migrate existing data: tudent → stutor
UPDATE profiles SET user_type = 'stutor' WHERE user_type = 'tudent';

-- 3) Add new CHECK (tutor, student, stutor only)
ALTER TABLE profiles
  ADD CONSTRAINT profiles_user_type_check
  CHECK (user_type IN ('tutor', 'student', 'stutor'));

-- 4) Comment
COMMENT ON COLUMN profiles.user_type IS 'tutor | student | stutor (tutor=선생, student=학생, stutor=둘 다)';

-- 5) 이후 stutor→twiner 마이그레이션은 MIGRATE_USER_TYPE_STUTOR_TO_TWINER.sql 실행.
