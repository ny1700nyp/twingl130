-- Remove UNIQUE constraint from conversations table to allow multiple conversations
-- between the same trainer and trainee (one conversation per request)

-- Drop the unique constraint
ALTER TABLE public.conversations 
DROP CONSTRAINT IF EXISTS conversations_trainer_id_trainee_id_key;

-- Note: After this migration, multiple conversations can exist between the same trainer and trainee
-- Each training request will create a new conversation
