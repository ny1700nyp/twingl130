-- Migrate profiles.user_type: trainer → tutor, trainee → student.
-- Only values: tutor (구 trainer), student (구 trainee), stutor (hybrid; 구 tudent).
-- Run this after deploying code that uses tutor/student/stutor.

-- 1) 먼저 기존 CHECK 제약 제거 (그래야 tutor/student로 UPDATE·INSERT 가능)
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_user_type_check;
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_user_type_fkey;

-- 2) 기존 데이터 값 변경
UPDATE profiles SET user_type = 'tutor'  WHERE user_type = 'trainer';
UPDATE profiles SET user_type = 'student' WHERE user_type = 'trainee';
-- user_type = 'stutor' (hybrid) 는 그대로 둠.

-- 3) 새 CHECK 제약 추가 (tutor, student, stutor 만 허용)
ALTER TABLE profiles
  ADD CONSTRAINT profiles_user_type_check
  CHECK (user_type IN ('tutor', 'student', 'stutor'));

-- 3) Comment
COMMENT ON COLUMN profiles.user_type IS 'tutor | student | stutor (tutor=선생, student=학생, stutor=둘 다)';

-- 4) RPC 함수가 user_type을 사용하면 재생성 필요 (CREATE_NEARBY_PROFILES_FUNCTION.sql, CREATE_TALENT_MATCHING_PROFILES_FUNCTION.sql 참고)

-- ---------------------------------------------------------------------------
-- [에러 나는 경우만] CHECK 위반(23514) 이미 났다면, 아래만 실행해서 제약만 교체
-- ---------------------------------------------------------------------------
-- ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_user_type_check;
-- ALTER TABLE profiles ADD CONSTRAINT profiles_user_type_check
--   CHECK (user_type IN ('tutor', 'student', 'stutor'));
-- (그 다음 2)번 UPDATE 두 줄 실행해서 기존 trainer/trainee 를 tutor/student 로 변경)
