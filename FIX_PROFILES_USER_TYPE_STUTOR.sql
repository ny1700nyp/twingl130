-- Fix: allow user_type = 'twiner' (resolve 23514 check constraint violation)
-- Run in Supabase SQL Editor.

-- 1) Drop existing check
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_user_type_check;

-- 2) Migrate stutor → twiner (if any)
UPDATE profiles SET user_type = 'twiner' WHERE user_type = 'stutor';

-- 3) Add new check (tutor, student, twiner)
ALTER TABLE profiles
  ADD CONSTRAINT profiles_user_type_check
  CHECK (user_type IN ('tutor', 'student', 'twiner'));
