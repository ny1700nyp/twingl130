-- Add scheduling fields to conversations to support "Do you agree? → both agree → Add to Calendar"
-- Apply via Supabase Dashboard → SQL Editor.

ALTER TABLE public.conversations
  ADD COLUMN IF NOT EXISTS scheduled_start_time TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS scheduled_end_time   TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS schedule_state       TEXT,
  ADD COLUMN IF NOT EXISTS trainer_schedule_agreed BOOLEAN,
  ADD COLUMN IF NOT EXISTS trainee_schedule_agreed BOOLEAN;

-- Optional: enforce allowed states
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'conversations_schedule_state_check'
  ) THEN
    ALTER TABLE public.conversations
      ADD CONSTRAINT conversations_schedule_state_check
      CHECK (schedule_state IS NULL OR schedule_state IN ('proposed', 'agreed', 'declined'));
  END IF;
END $$;

-- Helpful index for sorting/filtering if you later show schedules in list.
CREATE INDEX IF NOT EXISTS conversations_scheduled_start_idx
  ON public.conversations (scheduled_start_time DESC);

