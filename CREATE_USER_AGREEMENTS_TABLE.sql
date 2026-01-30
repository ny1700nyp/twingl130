-- Create user_agreements table to store user legal agreements
-- This table tracks when users agree to terms, waivers, etc.

-- Create the table
CREATE TABLE IF NOT EXISTS public.user_agreements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  agreement_type TEXT NOT NULL,
  agreed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  version TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Add comments for documentation
COMMENT ON TABLE public.user_agreements IS 'Stores user legal agreements (terms, waivers, etc.)';
COMMENT ON COLUMN public.user_agreements.id IS 'Primary key';
COMMENT ON COLUMN public.user_agreements.user_id IS 'Reference to auth.users';
COMMENT ON COLUMN public.user_agreements.agreement_type IS 'Type of agreement (e.g., trainer_terms, trainee_waiver)';
COMMENT ON COLUMN public.user_agreements.agreed_at IS 'Timestamp when user agreed';
COMMENT ON COLUMN public.user_agreements.version IS 'Version of the agreement (e.g., v1.0)';

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS user_agreements_user_id_idx ON public.user_agreements(user_id);
CREATE INDEX IF NOT EXISTS user_agreements_agreement_type_idx ON public.user_agreements(agreement_type);
CREATE INDEX IF NOT EXISTS user_agreements_user_id_type_idx ON public.user_agreements(user_id, agreement_type);

-- Enable Row Level Security (RLS)
ALTER TABLE public.user_agreements ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (for clean setup)
DROP POLICY IF EXISTS "Users can insert their own agreements" ON public.user_agreements;
DROP POLICY IF EXISTS "Users can view their own agreements" ON public.user_agreements;

-- Policy: Users can insert their own records
CREATE POLICY "Users can insert their own agreements"
  ON public.user_agreements
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can view their own records (usually needed for checking agreement status)
CREATE POLICY "Users can view their own agreements"
  ON public.user_agreements
  FOR SELECT
  USING (auth.uid() = user_id);

-- Optional: Create a function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_user_agreements_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
DROP TRIGGER IF EXISTS update_user_agreements_updated_at_trigger ON public.user_agreements;
CREATE TRIGGER update_user_agreements_updated_at_trigger
  BEFORE UPDATE ON public.user_agreements
  FOR EACH ROW
  EXECUTE FUNCTION update_user_agreements_updated_at();
