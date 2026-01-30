-- Add tutoring_rate column to profiles table for Trainer profiles
-- tutoring_rate: Text field storing the hourly rate (e.g., "50", "100")

ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS tutoring_rate TEXT;

-- Add comment to describe the column
COMMENT ON COLUMN profiles.tutoring_rate IS 'Trainer hourly tutoring rate (e.g., "50", "100")';
