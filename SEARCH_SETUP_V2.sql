-- -----------------------------------------------------------------------------
-- UPDATED SEARCH FUNCTION (CONTEXT AWARE)
-- -----------------------------------------------------------------------------
-- Run this in your Supabase SQL Editor to enable context snippets in search results.
-- -----------------------------------------------------------------------------

DROP FUNCTION IF EXISTS search_conversations(text);

CREATE OR REPLACE FUNCTION search_conversations(search_query TEXT)
RETURNS TABLE (
  id UUID,
  user_id TEXT,
  title TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  match_snippet TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.id,
    c.user_id,
    c.title,
    c.created_at,
    c.updated_at,
    (
      SELECT m.content
      FROM messages m
      WHERE m.conversation_id = c.id
      AND m.content ILIKE '%' || search_query || '%'
      LIMIT 1
    ) as match_snippet
  FROM conversations c
  WHERE c.user_id = auth.uid()::text
  AND (
    c.title ILIKE '%' || search_query || '%'
    OR EXISTS (
        SELECT 1 FROM messages m
        WHERE m.conversation_id = c.id
        AND m.content ILIKE '%' || search_query || '%'
    )
  )
  ORDER BY c.updated_at DESC;
END;
$$ LANGUAGE plpgsql;
