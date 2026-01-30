-- Create messages table for chat messages within conversations
-- This table stores individual messages including request messages and regular chat

CREATE TABLE IF NOT EXISTS public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL DEFAULT 'text' CHECK (type IN ('text', 'request', 'system')),
  content TEXT NOT NULL,
  metadata JSONB, -- For storing additional data like skill, method, etc.
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Add comments
COMMENT ON TABLE public.messages IS 'Stores messages within conversations';
COMMENT ON COLUMN public.messages.type IS 'Message type: text (regular chat), request (training request), system (system messages)';
COMMENT ON COLUMN public.messages.metadata IS 'JSON metadata for additional data (e.g., skill, method for requests)';
COMMENT ON COLUMN public.messages.is_read IS 'Whether the message has been read by the recipient';

-- Create indexes
CREATE INDEX IF NOT EXISTS messages_conversation_id_idx ON public.messages(conversation_id);
CREATE INDEX IF NOT EXISTS messages_sender_id_idx ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS messages_created_at_idx ON public.messages(created_at DESC);
CREATE INDEX IF NOT EXISTS messages_is_read_idx ON public.messages(is_read) WHERE is_read = false;

-- Enable Row Level Security (RLS)
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can read messages in their conversations" ON public.messages;
DROP POLICY IF EXISTS "Users can send messages in their conversations" ON public.messages;
DROP POLICY IF EXISTS "Users can update their own messages" ON public.messages;

-- Policy: Users can read messages in conversations they are part of
CREATE POLICY "Users can read messages in their conversations"
  ON public.messages
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.conversations
      WHERE conversations.id = messages.conversation_id
      AND (conversations.trainer_id = auth.uid() OR conversations.trainee_id = auth.uid())
    )
  );

-- Policy: Users can send messages in conversations they are part of
CREATE POLICY "Users can send messages in their conversations"
  ON public.messages
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.conversations
      WHERE conversations.id = messages.conversation_id
      AND (conversations.trainer_id = auth.uid() OR conversations.trainee_id = auth.uid())
      AND messages.sender_id = auth.uid()
    )
  );

-- Policy: Users can update their own messages (e.g., mark as read)
CREATE POLICY "Users can update their own messages"
  ON public.messages
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.conversations
      WHERE conversations.id = messages.conversation_id
      AND (conversations.trainer_id = auth.uid() OR conversations.trainee_id = auth.uid())
    )
  );
