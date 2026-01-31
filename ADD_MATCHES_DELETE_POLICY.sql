-- Enable deleting favorites (matches) for the owner.
-- Run in Supabase Dashboard → SQL Editor.

ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can delete own matches" ON public.matches;

CREATE POLICY "Users can delete own matches"
  ON public.matches
  FOR DELETE
  USING (auth.uid() = user_id);

