-- -----------------------------------------------------------------------------
-- SEARCH FUNCTION SETUP
-- -----------------------------------------------------------------------------
-- To enable searching within conversation content, you must run this SQL script
-- in your Supabase SQL Editor.
-- -----------------------------------------------------------------------------

-- 1. Create the search function (RPC)
-- This function allows the app to search for text in both titles and message content.
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

-- 2. Performance Optimization (Optional but recommended)
-- Add indexes to make searching faster as your data grows.
CREATE INDEX IF NOT EXISTS idx_messages_content_search ON messages USING gin(to_tsvector('english', content));
