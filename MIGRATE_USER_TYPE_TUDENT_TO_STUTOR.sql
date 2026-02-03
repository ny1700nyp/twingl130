-- Migrate profiles.user_type: tudent → stutor (hybrid Tutor+Student).
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

-- 5) Recreate RPCs if they filter by user_type: run CREATE_NEARBY_PROFILES_FUNCTION.sql and CREATE_TALENT_MATCHING_PROFILES_FUNCTION.sql with 'stutor' in place of 'tudent'.
