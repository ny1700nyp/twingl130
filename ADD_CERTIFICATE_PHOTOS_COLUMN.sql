-- Add certificate_photos column to profiles table for Trainer profiles
-- This column stores an array of base64-encoded certificate/award/degree images

ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS certificate_photos TEXT[];

-- Add comment to describe the column
COMMENT ON COLUMN profiles.certificate_photos IS 'Array of base64-encoded certificate, award, and degree images for Trainer profiles';
