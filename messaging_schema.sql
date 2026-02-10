-- ============================================================================
-- MESSAGING / CHAT TABLES
-- Run this in Supabase SQL Editor to create the messaging functionality
-- ============================================================================

-- First, drop existing objects to avoid conflicts
DROP TRIGGER IF EXISTS update_conversation_on_message ON messages;
DROP TRIGGER IF EXISTS on_new_message ON messages;
DROP FUNCTION IF EXISTS update_conversation_timestamp() CASCADE;

-- Drop existing policies (ignore errors if they don't exist)
DO $$ BEGIN
    DROP POLICY IF EXISTS "Users can view their conversations" ON conversations;
    DROP POLICY IF EXISTS "Users can create conversations" ON conversations;
    DROP POLICY IF EXISTS "Users can update their conversations" ON conversations;
EXCEPTION WHEN undefined_table THEN NULL;
END $$;

DO $$ BEGIN
    DROP POLICY IF EXISTS "Users can view messages in their conversations" ON messages;
    DROP POLICY IF EXISTS "Users can send messages to their conversations" ON messages;
    DROP POLICY IF EXISTS "Users can update their own messages" ON messages;
EXCEPTION WHEN undefined_table THEN NULL;
END $$;

-- Drop tables if they exist (messages first due to foreign key)
DROP TABLE IF EXISTS messages CASCADE;
DROP TABLE IF EXISTS conversations CASCADE;

-- Conversations table
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    participant1_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    participant2_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(participant1_id, participant2_id)
);

-- Messages table
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL DEFAULT '',
    message_type VARCHAR(20) DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'file', 'link')),
    attachment_url TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    is_edited BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_conversations_participant1 ON conversations(participant1_id);
CREATE INDEX IF NOT EXISTS idx_conversations_participant2 ON conversations(participant2_id);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at);

-- Enable RLS (Row Level Security)
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Conversations RLS policies
CREATE POLICY "Users can view their conversations"
    ON conversations FOR SELECT
    USING (auth.uid() = participant1_id OR auth.uid() = participant2_id);

CREATE POLICY "Users can create conversations"
    ON conversations FOR INSERT
    WITH CHECK (auth.uid() = participant1_id OR auth.uid() = participant2_id);

CREATE POLICY "Users can update their conversations"
    ON conversations FOR UPDATE
    USING (auth.uid() = participant1_id OR auth.uid() = participant2_id);

-- Messages RLS policies
CREATE POLICY "Users can view messages in their conversations"
    ON messages FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM conversations
            WHERE conversations.id = messages.conversation_id
            AND (conversations.participant1_id = auth.uid() OR conversations.participant2_id = auth.uid())
        )
    );

CREATE POLICY "Users can send messages to their conversations"
    ON messages FOR INSERT
    WITH CHECK (
        auth.uid() = sender_id
        AND EXISTS (
            SELECT 1 FROM conversations
            WHERE conversations.id = messages.conversation_id
            AND (conversations.participant1_id = auth.uid() OR conversations.participant2_id = auth.uid())
        )
    );

CREATE POLICY "Users can update their own messages"
    ON messages FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM conversations
            WHERE conversations.id = messages.conversation_id
            AND (conversations.participant1_id = auth.uid() OR conversations.participant2_id = auth.uid())
        )
    );

-- Enable realtime for messages (important for chat functionality)
ALTER PUBLICATION supabase_realtime ADD TABLE conversations;
ALTER PUBLICATION supabase_realtime ADD TABLE messages;

-- Function to update conversation's updated_at timestamp when a new message is sent
CREATE OR REPLACE FUNCTION update_conversation_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE conversations
    SET updated_at = NOW()
    WHERE id = NEW.conversation_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to update conversation timestamp on new message
CREATE TRIGGER update_conversation_on_message
    AFTER INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_conversation_timestamp();

-- Grant necessary permissions
GRANT ALL ON conversations TO authenticated;
GRANT ALL ON messages TO authenticated;

SELECT 'Messaging schema created successfully!' AS status;
