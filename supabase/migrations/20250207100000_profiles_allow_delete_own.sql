-- Allow users to delete their own profile row (for "Leave Twingl" / re-onboarding flow).
-- The app uses this to clear profile so the user goes through onboarding again on next login.

DROP POLICY IF EXISTS "Users can delete own profile" ON public.profiles;
CREATE POLICY "Users can delete own profile"
  ON public.profiles
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Allow users to delete conversations they are part of (trainer or trainee).
-- Used when leaving Twingl to clear chat/conversation data. Messages are CASCADE deleted.
DROP POLICY IF EXISTS "Users can delete own conversations" ON public.conversations;
CREATE POLICY "Users can delete own conversations"
  ON public.conversations
  FOR DELETE
  TO authenticated
  USING (auth.uid() = trainer_id OR auth.uid() = trainee_id);
