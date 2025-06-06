-- Create chats table
CREATE TABLE IF NOT EXISTS public.chats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  user_id UUID REFERENCES auth.users(id),
  title TEXT NOT NULL,
  repository_id UUID,
  messages JSONB DEFAULT '{}',
  deploy_settings JSONB DEFAULT '{}',
  deleted BOOLEAN DEFAULT FALSE,
  last_protocol_chat_id UUID,
  last_protocol_chat_response_id TEXT
);

-- Create updated_at trigger for chats table
CREATE TRIGGER update_chats_updated_at
  BEFORE UPDATE ON public.chats
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Enable Row-Level Security (RLS)
ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;

-- === RLS Policies for chats ===

-- Allow admin read access to all chats
CREATE POLICY "Allow admin read access to all chats"
  ON public.chats FOR SELECT
  TO public
  USING (
    auth.uid() IN (
      SELECT id FROM public.profiles WHERE is_admin = true
    )
  );

-- Allow users to read their own chats
CREATE POLICY "Allow users to read their own chats"
  ON public.chats FOR SELECT
  TO public
  USING (auth.uid() = user_id);

-- Allow anyone to create chats (even unauthenticated users)
CREATE POLICY "Allow anyone to create chats"
  ON public.chats FOR INSERT
  TO public
  WITH CHECK (true);

-- Allow admins to update any chats
CREATE POLICY "Allow admins to update any chats"
  ON public.chats FOR UPDATE
  TO public
  USING (
    auth.uid() IN (
      SELECT id FROM public.profiles WHERE is_admin = true
    )
  );

-- Allow users to update their own chats
CREATE POLICY "Allow users to update their own chats"
  ON public.chats FOR UPDATE
  TO public
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Create function to get public data for a chat
CREATE OR REPLACE FUNCTION get_chat_public_data(chat_id UUID)
RETURNS TABLE (
  id UUID,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  title TEXT,
  repository_id UUID
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.id,
    p.created_at,
    p.updated_at,
    p.title,
    p.repository_id
  FROM chats p
  WHERE p.id = chat_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
