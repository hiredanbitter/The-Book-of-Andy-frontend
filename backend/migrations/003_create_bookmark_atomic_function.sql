-- Migration: Create create_bookmark_atomic RPC function
-- This function atomically checks the bookmark count for a user and inserts
-- a new bookmark only if the user is under the limit. It uses SELECT ... FOR
-- UPDATE to lock existing bookmark rows for the user, preventing concurrent
-- requests from both passing the count check simultaneously.

CREATE OR REPLACE FUNCTION create_bookmark_atomic(
    p_user_id UUID,
    p_chunk_id UUID,
    p_limit INT DEFAULT 100
)
RETURNS TABLE (
    bookmark_id UUID,
    bookmark_user_id UUID,
    bookmark_chunk_id UUID,
    bookmark_created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
DECLARE
    current_count INT;
BEGIN
    -- Lock the user's bookmark rows to prevent concurrent inserts
    PERFORM 1 FROM bookmarks WHERE user_id = p_user_id FOR UPDATE;

    -- Count existing bookmarks for this user
    SELECT COUNT(*) INTO current_count FROM bookmarks WHERE user_id = p_user_id;

    -- Enforce the cap
    IF current_count >= p_limit THEN
        RAISE EXCEPTION 'BOOKMARK_LIMIT_REACHED'
            USING ERRCODE = 'P0001';
    END IF;

    -- Insert and return the new bookmark
    RETURN QUERY
    INSERT INTO bookmarks (user_id, chunk_id)
    VALUES (p_user_id, p_chunk_id)
    RETURNING id, user_id, chunk_id, created_at;
END;
$$;
