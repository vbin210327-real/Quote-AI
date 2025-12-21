-- Quote AI Database Schema
-- Run this in your Supabase SQL Editor

-- Create conversations table
CREATE TABLE IF NOT EXISTS conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    title TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create messages table
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_user BOOLEAN NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_conversations_user_id ON conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_conversations_updated_at ON conversations(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_timestamp ON messages(timestamp);

-- Enable Row Level Security (RLS)
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Conversations RLS Policies
-- Users can only see their own conversations
CREATE POLICY "Users can view own conversations"
    ON conversations FOR SELECT
    USING (auth.uid()::text = user_id);

-- Users can only insert their own conversations
CREATE POLICY "Users can insert own conversations"
    ON conversations FOR INSERT
    WITH CHECK (auth.uid()::text = user_id);

-- Users can only update their own conversations
CREATE POLICY "Users can update own conversations"
    ON conversations FOR UPDATE
    USING (auth.uid()::text = user_id);

-- Users can only delete their own conversations
CREATE POLICY "Users can delete own conversations"
    ON conversations FOR DELETE
    USING (auth.uid()::text = user_id);

-- Messages RLS Policies
-- Users can only see messages from their own conversations
CREATE POLICY "Users can view own messages"
    ON messages FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM conversations
            WHERE conversations.id = messages.conversation_id
            AND conversations.user_id = auth.uid()::text
        )
    );

-- Users can only insert messages to their own conversations
CREATE POLICY "Users can insert own messages"
    ON messages FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM conversations
            WHERE conversations.id = conversation_id
            AND conversations.user_id = auth.uid()::text
        )
    );

-- Users can only delete messages from their own conversations
CREATE POLICY "Users can delete own messages"
    ON messages FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM conversations
            WHERE conversations.id = messages.conversation_id
            AND conversations.user_id = auth.uid()::text
        )
    );

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_conversations_updated_at
    BEFORE UPDATE ON conversations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- RPC Function for searching conversations by content
CREATE OR REPLACE FUNCTION search_conversations(search_query TEXT)
RETURNS SETOF conversations AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT c.*
  FROM conversations c
  JOIN messages m ON c.id = m.conversation_id
  WHERE c.user_id = auth.uid()::text
  AND (
    c.title ILIKE '%' || search_query || '%'
    OR m.content ILIKE '%' || search_query || '%'
  )
  ORDER BY c.updated_at DESC;
END;
$$ LANGUAGE plpgsql;