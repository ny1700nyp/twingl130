-- Unify trainer/trainee profile schema:
-- - Remove goals column (trainee goals will be stored in talents)
-- - Add about_me (used by both)
-- - Keep experience_description but treat it as "About the lesson" (trainer only, UI rename)
-- - teaching_methods applies to both (UI label: "Preferred lesson location" / "Lesson location")

BEGIN;

-- 1) Add about_me for both trainer/trainee
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS about_me TEXT;

COMMENT ON COLUMN profiles.about_me IS 'About me (trainer/trainee)';

-- 2) Backfill: copy trainee goals -> talents (only if talents is empty)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'profiles'
      AND column_name = 'goals'
  ) THEN
    UPDATE profiles
    SET talents = goals
    WHERE user_type = 'trainee'
      AND goals IS NOT NULL
      AND COALESCE(array_length(goals, 1), 0) > 0
      AND COALESCE(array_length(talents, 1), 0) = 0;
  END IF;
END $$;

-- 3) Drop goals column (after backfill)
ALTER TABLE profiles
  DROP COLUMN IF EXISTS goals;

-- 4) Update column comments to reflect unified model
COMMENT ON COLUMN profiles.talents IS 'Trainer talents OR Trainee goals (stored in talents; UI label changes by user_type)';
COMMENT ON COLUMN profiles.teaching_methods IS 'Preferred lesson location: array of onsite and/or online (trainer/trainee)';
COMMENT ON COLUMN profiles.experience_description IS 'About the lesson (trainer only)';

COMMIT;

