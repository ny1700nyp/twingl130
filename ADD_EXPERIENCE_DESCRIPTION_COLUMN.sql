-- Add experience_description column to profiles table for Trainer profiles
-- UI label: "About the lesson" (trainer only)

ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS experience_description TEXT;

-- Add comment to describe the column
COMMENT ON COLUMN profiles.experience_description IS 'About the lesson (trainer only)';
