-- Store FCM tokens for push notifications (background/terminated)
-- One user can have multiple tokens (e.g., phone + tablet)

CREATE TABLE IF NOT EXISTS public.user_fcm_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  fcm_token TEXT NOT NULL,
  platform TEXT NOT NULL CHECK (platform IN ('android', 'ios')),
  notifications_enabled BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, fcm_token)
);

CREATE INDEX IF NOT EXISTS user_fcm_tokens_user_id_idx ON public.user_fcm_tokens(user_id);
CREATE INDEX IF NOT EXISTS user_fcm_tokens_fcm_token_idx ON public.user_fcm_tokens(fcm_token);

COMMENT ON TABLE public.user_fcm_tokens IS 'FCM tokens for push notifications when app is in background';

ALTER TABLE public.user_fcm_tokens ENABLE ROW LEVEL SECURITY;

-- Users can manage their own tokens
DROP POLICY IF EXISTS "Users can insert own fcm token" ON public.user_fcm_tokens;
CREATE POLICY "Users can insert own fcm token"
  ON public.user_fcm_tokens FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own fcm token" ON public.user_fcm_tokens;
CREATE POLICY "Users can update own fcm token"
  ON public.user_fcm_tokens FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own fcm token" ON public.user_fcm_tokens;
CREATE POLICY "Users can delete own fcm token"
  ON public.user_fcm_tokens FOR DELETE
  USING (auth.uid() = user_id);

-- Edge Function uses service_role client which bypasses RLS for reading tokens
