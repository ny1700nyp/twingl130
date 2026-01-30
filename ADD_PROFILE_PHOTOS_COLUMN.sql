-- Add profile_photos column to profiles table
-- This column stores an array of base64-encoded profile images (main photo + additional photos)
-- For trainers: main_photo_path + sub_photos
-- For trainees: all trainee photos

ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS profile_photos TEXT[];

-- Add comment to describe the column
COMMENT ON COLUMN profiles.profile_photos IS 'Array of base64-encoded profile images. For trainers: main photo + sub photos. For trainees: all trainee photos.';
