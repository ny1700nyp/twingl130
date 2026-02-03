-- Fix: allow user_type = 'stutor' (resolve 23514 check constraint violation)
-- Run in Supabase SQL Editor.

-- 1) Drop existing check (allows only tutor, student, tudent)
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_user_type_check;

-- 2) Rename existing tudent → stutor (if any)
UPDATE profiles SET user_type = 'stutor' WHERE user_type = 'tudent';

-- 3) Add new check (tutor, student, stutor)
ALTER TABLE profiles
  ADD CONSTRAINT profiles_user_type_check
  CHECK (user_type IN ('tutor', 'student', 'stutor'));
