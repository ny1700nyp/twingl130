-- RPC: Dashboard conversation list with enrich (1 query)
-- Returns: conversations + other_profile + latest_message + request_message + unread_count + is_requester
--
-- How to apply:
-- - Supabase Dashboard → SQL Editor → run this file.
-- - Then the app will automatically use `supabase.rpc('get_dashboard_conversations')`.

-- Helpful indexes for the RPC (safe to run multiple times).
CREATE INDEX IF NOT EXISTS messages_conversation_created_at_desc_idx
  ON public.messages (conversation_id, created_at DESC);

CREATE INDEX IF NOT EXISTS messages_conversation_type_created_at_desc_idx
  ON public.messages (conversation_id, type, created_at DESC);

CREATE INDEX IF NOT EXISTS messages_conversation_unread_idx
  ON public.messages (conversation_id)
  WHERE is_read = false;

-- Main RPC function.
CREATE OR REPLACE FUNCTION public.get_dashboard_conversations()
RETURNS TABLE (
  id uuid,
  trainer_id uuid,
  trainee_id uuid,
  status text,
  created_at timestamptz,
  updated_at timestamptz,
  scheduled_start_time timestamptz,
  scheduled_end_time timestamptz,
  schedule_state text,
  trainer_schedule_agreed boolean,
  trainee_schedule_agreed boolean,
  other_user_id uuid,
  is_requester boolean,
  other_profile jsonb,
  latest_message jsonb,
  request_message jsonb,
  unread_count int
)
LANGUAGE sql
STABLE
AS $$
  WITH me AS (SELECT auth.uid() AS uid)
  SELECT
    c.id,
    c.trainer_id,
    c.trainee_id,
    c.status,
    c.created_at,
    c.updated_at,
    c.scheduled_start_time,
    c.scheduled_end_time,
    c.schedule_state,
    c.trainer_schedule_agreed,
    c.trainee_schedule_agreed,
    CASE WHEN c.trainer_id = me.uid THEN c.trainee_id ELSE c.trainer_id END AS other_user_id,
    (c.trainee_id = me.uid) AS is_requester,
    -- Compact profile payload: keep basic fields; drop potential large arrays if present.
    (
      COALESCE(to_jsonb(p), '{}'::jsonb)
      - 'certificate_photos'
      - 'profile_photos'
      - 'photos'
      - 'sub_photos'
      - 'trainee_photos'
    ) AS other_profile,
    lm.msg AS latest_message,
    rm.msg AS request_message,
    COALESCE(uc.cnt, 0)::int AS unread_count
  FROM public.conversations c
  CROSS JOIN me
  LEFT JOIN public.profiles p
    ON p.user_id = (CASE WHEN c.trainer_id = me.uid THEN c.trainee_id ELSE c.trainer_id END)
  LEFT JOIN LATERAL (
    SELECT to_jsonb(m.*) AS msg
    FROM public.messages m
    WHERE m.conversation_id = c.id
    ORDER BY m.created_at DESC
    LIMIT 1
  ) lm ON TRUE
  LEFT JOIN LATERAL (
    SELECT to_jsonb(m.*) AS msg
    FROM public.messages m
    WHERE m.conversation_id = c.id
      AND m.type = 'request'
    ORDER BY m.created_at DESC
    LIMIT 1
  ) rm ON TRUE
  LEFT JOIN LATERAL (
    SELECT COUNT(*) AS cnt
    FROM public.messages m
    WHERE m.conversation_id = c.id
      AND m.is_read = FALSE
      AND m.sender_id <> me.uid
  ) uc ON TRUE
  WHERE c.trainer_id = me.uid OR c.trainee_id = me.uid
  ORDER BY
    (COALESCE(uc.cnt, 0) > 0) DESC,
    COALESCE((lm.msg->>'created_at')::timestamptz, c.updated_at) DESC;
$$;

