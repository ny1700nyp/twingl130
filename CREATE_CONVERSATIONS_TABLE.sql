-- Create conversations table for training requests and chat sessions
-- This table stores conversation metadata between trainers and trainees

CREATE TABLE IF NOT EXISTS public.conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trainer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  trainee_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'completed')),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(trainer_id, trainee_id)
);

-- Add comments
COMMENT ON TABLE public.conversations IS 'Stores conversations between trainers and trainees';
COMMENT ON COLUMN public.conversations.status IS 'Conversation status: pending, accepted, declined, completed';

-- Create indexes
CREATE INDEX IF NOT EXISTS conversations_trainer_id_idx ON public.conversations(trainer_id);
CREATE INDEX IF NOT EXISTS conversations_trainee_id_idx ON public.conversations(trainee_id);
CREATE INDEX IF NOT EXISTS conversations_status_idx ON public.conversations(status);
CREATE INDEX IF NOT EXISTS conversations_updated_at_idx ON public.conversations(updated_at DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can read their own conversations" ON public.conversations;
DROP POLICY IF EXISTS "Users can create conversations" ON public.conversations;
DROP POLICY IF EXISTS "Users can update their own conversations" ON public.conversations;

-- Policy: Users can read conversations they are part of
CREATE POLICY "Users can read their own conversations"
  ON public.conversations
  FOR SELECT
  USING (auth.uid() = trainer_id OR auth.uid() = trainee_id);

-- Policy: Trainees can create conversations (request training)
CREATE POLICY "Users can create conversations"
  ON public.conversations
  FOR INSERT
  WITH CHECK (auth.uid() = trainee_id);

-- Policy: Trainers can update conversations (accept/decline)
CREATE POLICY "Users can update their own conversations"
  ON public.conversations
  FOR UPDATE
  USING (auth.uid() = trainer_id OR auth.uid() = trainee_id);
