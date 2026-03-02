-- Migration: Create semantic_search RPC function
-- This function performs cosine similarity search on transcript_chunks.embedding
-- using pgvector, joins with episodes and podcasts for metadata, and returns
-- paginated results with a total count.

CREATE OR REPLACE FUNCTION semantic_search(
    query_embedding vector(1536),
    result_limit INT DEFAULT 10,
    result_offset INT DEFAULT 0
)
RETURNS TABLE (
    chunk_id UUID,
    chunk_text TEXT,
    speaker_label TEXT,
    start_timestamp TEXT,
    end_timestamp TEXT,
    chunk_index INT,
    episode_id UUID,
    episode_title TEXT,
    episode_number INT,
    podcast_name TEXT,
    publication_date DATE,
    similarity FLOAT,
    total_count BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH matches AS (
        SELECT
            tc.id AS chunk_id,
            tc.chunk_text,
            tc.speaker_label,
            tc.start_timestamp,
            tc.end_timestamp,
            tc.chunk_index,
            tc.episode_id,
            e.title AS episode_title,
            e.episode_number,
            p.name AS podcast_name,
            e.publication_date,
            1 - (tc.embedding <=> query_embedding) AS similarity,
            COUNT(*) OVER() AS total_count
        FROM transcript_chunks tc
        JOIN episodes e ON tc.episode_id = e.id
        JOIN podcasts p ON e.podcast_id = p.id
        WHERE tc.embedding IS NOT NULL
        ORDER BY tc.embedding <=> query_embedding
        LIMIT result_limit
        OFFSET result_offset
    )
    SELECT * FROM matches;
END;
$$;
