-- Allow schedule_proposal message type for Scheduling feature
ALTER TABLE public.messages DROP CONSTRAINT IF EXISTS messages_type_check;
ALTER TABLE public.messages ADD CONSTRAINT messages_type_check
  CHECK (type IN ('text', 'request', 'system', 'schedule_proposal'));

COMMENT ON COLUMN public.messages.type IS 'Message type: text, request, system, schedule_proposal (Scheduling with Add to Calendar)';
