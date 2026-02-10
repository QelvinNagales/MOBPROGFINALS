-- Group Chat Migration SQL
-- Run this in your Supabase SQL Editor to enable group chat functionality
-- If you get errors about existing objects, run the DROP section first

-- ============ CLEANUP (run if you have partial setup) ============
-- Uncomment these lines if you need to start fresh:
-- DROP TABLE IF EXISTS group_messages CASCADE;
-- DROP TABLE IF EXISTS group_participants CASCADE;
-- DROP TABLE IF EXISTS group_conversations CASCADE;
-- DROP FUNCTION IF EXISTS is_group_member(UUID);
-- DROP FUNCTION IF EXISTS is_group_creator(UUID);
-- DROP FUNCTION IF EXISTS is_group_admin(UUID);
-- DROP FUNCTION IF EXISTS update_group_last_message();

-- ============ GROUP CONVERSATIONS TABLE ============
CREATE TABLE IF NOT EXISTS group_conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  creator_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  avatar_url TEXT,
  description TEXT,
  last_message_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============ GROUP PARTICIPANTS TABLE ============
CREATE TABLE IF NOT EXISTS group_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID REFERENCES group_conversations(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  role TEXT DEFAULT 'member',
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(group_id, user_id)
);

-- ============ GROUP MESSAGES TABLE ============
CREATE TABLE IF NOT EXISTS group_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID REFERENCES group_conversations(id) ON DELETE CASCADE NOT NULL,
  sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  content TEXT NOT NULL,
  message_type TEXT DEFAULT 'text',
  attachment_url TEXT,
  is_edited BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============ ENABLE RLS ============
ALTER TABLE group_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_messages ENABLE ROW LEVEL SECURITY;

-- ============ HELPER FUNCTION (must be created before policies) ============
-- This function bypasses RLS to check group membership
CREATE OR REPLACE FUNCTION is_group_member(p_group_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM group_participants 
    WHERE group_id = p_group_id AND user_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper function to check if user is group creator (bypasses RLS)
CREATE OR REPLACE FUNCTION is_group_creator(p_group_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM group_conversations 
    WHERE id = p_group_id AND creator_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper function to check if user is group admin (bypasses RLS)
CREATE OR REPLACE FUNCTION is_group_admin(p_group_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM group_participants 
    WHERE group_id = p_group_id AND user_id = auth.uid() AND role = 'admin'
  ) OR EXISTS (
    SELECT 1 FROM group_conversations 
    WHERE id = p_group_id AND creator_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============ DROP EXISTING POLICIES (prevents conflicts) ============
DROP POLICY IF EXISTS "Users can view their groups" ON group_conversations;
DROP POLICY IF EXISTS "Users can create groups" ON group_conversations;
DROP POLICY IF EXISTS "Group admins can update" ON group_conversations;
DROP POLICY IF EXISTS "Creators can delete groups" ON group_conversations;
DROP POLICY IF EXISTS "Users can view group participants" ON group_participants;
DROP POLICY IF EXISTS "Admins can add participants" ON group_participants;
DROP POLICY IF EXISTS "Admins can update participant roles" ON group_participants;
DROP POLICY IF EXISTS "Users can leave groups" ON group_participants;
DROP POLICY IF EXISTS "Users can view group messages" ON group_messages;
DROP POLICY IF EXISTS "Users can send group messages" ON group_messages;
DROP POLICY IF EXISTS "Users can edit own messages" ON group_messages;
DROP POLICY IF EXISTS "Users can delete own messages" ON group_messages;

-- ============ POLICIES FOR GROUP CONVERSATIONS ============
-- Use SECURITY DEFINER functions to avoid RLS recursion
CREATE POLICY "Users can view their groups" ON group_conversations FOR SELECT
  USING (is_group_member(id) OR creator_id = auth.uid());

CREATE POLICY "Users can create groups" ON group_conversations FOR INSERT
  WITH CHECK (auth.uid() = creator_id);

CREATE POLICY "Group admins can update" ON group_conversations FOR UPDATE
  USING (is_group_admin(id));

CREATE POLICY "Creators can delete groups" ON group_conversations FOR DELETE
  USING (is_group_creator(id));

-- ============ POLICIES FOR GROUP PARTICIPANTS ============
CREATE POLICY "Users can view group participants" ON group_participants FOR SELECT
  USING (is_group_member(group_id));

CREATE POLICY "Admins can add participants" ON group_participants FOR INSERT
  WITH CHECK (is_group_admin(group_id));

CREATE POLICY "Admins can update participant roles" ON group_participants FOR UPDATE
  USING (is_group_admin(group_id));

CREATE POLICY "Users can leave groups" ON group_participants FOR DELETE
  USING (
    auth.uid() = user_id OR 
    is_group_admin(group_id)
  );

-- ============ POLICIES FOR GROUP MESSAGES ============
CREATE POLICY "Users can view group messages" ON group_messages FOR SELECT
  USING (is_group_member(group_id));

CREATE POLICY "Users can send group messages" ON group_messages FOR INSERT
  WITH CHECK (auth.uid() = sender_id AND is_group_member(group_id));

CREATE POLICY "Users can edit own messages" ON group_messages FOR UPDATE
  USING (auth.uid() = sender_id);

CREATE POLICY "Users can delete own messages" ON group_messages FOR DELETE
  USING (auth.uid() = sender_id);

-- ============ INDEXES ============
CREATE INDEX IF NOT EXISTS idx_group_participants_group_id ON group_participants(group_id);
CREATE INDEX IF NOT EXISTS idx_group_participants_user_id ON group_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_group_messages_group_id ON group_messages(group_id);
CREATE INDEX IF NOT EXISTS idx_group_messages_created_at ON group_messages(created_at);

-- ============ TRIGGER FUNCTION ============
CREATE OR REPLACE FUNCTION update_group_last_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE group_conversations 
  SET last_message_at = NEW.created_at, updated_at = NOW()
  WHERE id = NEW.group_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_group_message_sent ON group_messages;
CREATE TRIGGER on_group_message_sent
  AFTER INSERT ON group_messages
  FOR EACH ROW
  EXECUTE FUNCTION update_group_last_message();

-- ============ ENABLE REALTIME ============
-- Enable realtime for group_messages table (required for live updates)
ALTER PUBLICATION supabase_realtime ADD TABLE group_messages;
