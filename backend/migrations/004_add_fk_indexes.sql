-- Migration: Add indexes on foreign key columns
-- Ensures that FK columns used in joins for bookmark and search queries
-- are indexed, preventing full table scans as data grows.
--
-- Targeted FK columns:
--   bookmarks.chunk_id       -> transcript_chunks.id
--   bookmarks.user_id        -> auth.users.id
--   transcript_chunks.episode_id -> episodes.id
--   episodes.podcast_id      -> podcasts.id

CREATE INDEX IF NOT EXISTS idx_bookmarks_chunk_id
    ON public.bookmarks USING btree (chunk_id);

CREATE INDEX IF NOT EXISTS idx_bookmarks_user_id
    ON public.bookmarks USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_transcript_chunks_episode_id
    ON public.transcript_chunks USING btree (episode_id);

CREATE INDEX IF NOT EXISTS idx_episodes_podcast_id
    ON public.episodes USING btree (podcast_id);
