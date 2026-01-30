-- Allow public read access to profiles for sharing links
-- This policy allows anyone (even without authentication) to read profile data
-- This is necessary for sharing profile links that can be viewed without login

-- First, ensure RLS is enabled
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Drop the policy if it already exists (for idempotency - safe re-run)
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;

-- Create a policy that allows public read access to profiles
-- This allows anyone to read profile data, which is needed for shared profile links
CREATE POLICY "Public profiles are viewable by everyone"
  ON public.profiles
  FOR SELECT
  TO authenticated, anon
  USING (true);

-- Note: This makes all profiles publicly readable
-- If you want to restrict this to only certain profiles or add conditions,
-- you can modify the USING clause. For example:
-- USING (is_public = true) -- if you add an is_public column
-- or
-- USING (user_type = 'trainer') -- to only allow trainer profiles to be public
