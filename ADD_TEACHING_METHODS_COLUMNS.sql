-- Add teaching_methods and parent_participation_welcomed columns to profiles table
-- teaching_methods: Preferred lesson location (e.g., ['onsite', 'online']) - trainer/trainee 공통
-- parent_participation_welcomed: Boolean indicating if parent participation is welcomed for kid training

ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS teaching_methods TEXT[];

ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS parent_participation_welcomed BOOLEAN DEFAULT false;

-- Add comments to describe the columns
COMMENT ON COLUMN profiles.teaching_methods IS 'Preferred lesson location: array of onsite and/or online (trainer/trainee)';
COMMENT ON COLUMN profiles.parent_participation_welcomed IS 'Trainer option: whether parent participation is welcomed for kid training';
