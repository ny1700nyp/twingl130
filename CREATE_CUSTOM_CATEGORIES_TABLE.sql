-- Create custom_categories table to store user-suggested topics
-- This table allows users to add new categories that are not in the default list

CREATE TABLE IF NOT EXISTS public.custom_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_name TEXT NOT NULL,
  created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected'))
);

-- Add comments
COMMENT ON TABLE public.custom_categories IS 'Stores user-suggested custom categories/topics';
COMMENT ON COLUMN public.custom_categories.item_name IS 'Name of the custom category/topic';
COMMENT ON COLUMN public.custom_categories.created_by IS 'User who suggested this category';
COMMENT ON COLUMN public.custom_categories.status IS 'Status: pending, approved, or rejected';

-- Create indexes
CREATE INDEX IF NOT EXISTS custom_categories_created_by_idx ON public.custom_categories(created_by);
CREATE INDEX IF NOT EXISTS custom_categories_status_idx ON public.custom_categories(status);
CREATE INDEX IF NOT EXISTS custom_categories_item_name_idx ON public.custom_categories(item_name);

-- Enable Row Level Security (RLS)
ALTER TABLE public.custom_categories ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can insert their own custom categories" ON public.custom_categories;
DROP POLICY IF EXISTS "Users can view approved custom categories" ON public.custom_categories;

-- Policy: Users can insert their own records
CREATE POLICY "Users can insert their own custom categories"
  ON public.custom_categories
  FOR INSERT
  WITH CHECK (auth.uid() = created_by);

-- Policy: Users can view approved custom categories
CREATE POLICY "Users can view approved custom categories"
  ON public.custom_categories
  FOR SELECT
  USING (status = 'approved' OR auth.uid() = created_by);

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_custom_categories_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS update_custom_categories_updated_at_trigger ON public.custom_categories;
CREATE TRIGGER update_custom_categories_updated_at_trigger
  BEFORE UPDATE ON public.custom_categories
  FOR EACH ROW
  EXECUTE FUNCTION update_custom_categories_updated_at();
