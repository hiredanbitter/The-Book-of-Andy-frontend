-- ============================================
-- Initial database schema for Podcast Transcript Search App
-- ============================================

-- Create podcasts table
CREATE TABLE public.podcasts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create episodes table
CREATE TABLE public.episodes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  podcast_id UUID NOT NULL REFERENCES public.podcasts(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  episode_number INTEGER,
  publication_date DATE,
  description TEXT,
  transcript_file_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create transcript_chunks table
CREATE TABLE public.transcript_chunks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  episode_id UUID NOT NULL REFERENCES public.episodes(id) ON DELETE CASCADE,
  chunk_text TEXT NOT NULL,
  speaker_label TEXT,
  start_timestamp TEXT,
  end_timestamp TEXT,
  embedding extensions.vector(1536),
  chunk_index INTEGER NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create bookmarks table
CREATE TABLE public.bookmarks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  chunk_id UUID NOT NULL REFERENCES public.transcript_chunks(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, chunk_id)
);

-- ============================================
-- Indexes
-- ============================================

CREATE INDEX idx_episodes_podcast_id ON public.episodes(podcast_id);
CREATE INDEX idx_transcript_chunks_episode_id ON public.transcript_chunks(episode_id);
CREATE INDEX idx_transcript_chunks_chunk_index ON public.transcript_chunks(episode_id, chunk_index);
CREATE INDEX idx_bookmarks_user_id ON public.bookmarks(user_id);
CREATE INDEX idx_bookmarks_chunk_id ON public.bookmarks(chunk_id);

-- HNSW index for vector similarity search (cosine distance)
CREATE INDEX idx_transcript_chunks_embedding ON public.transcript_chunks
  USING hnsw (embedding extensions.vector_cosine_ops);

-- Full-text search support
ALTER TABLE public.transcript_chunks ADD COLUMN fts tsvector
  GENERATED ALWAYS AS (to_tsvector('english', chunk_text)) STORED;
CREATE INDEX idx_transcript_chunks_fts ON public.transcript_chunks USING gin(fts);

-- ============================================
-- Row Level Security
-- ============================================

ALTER TABLE public.podcasts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.episodes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transcript_chunks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookmarks ENABLE ROW LEVEL SECURITY;

-- Podcasts: readable by everyone, writable by service role only
CREATE POLICY "Podcasts are viewable by everyone"
  ON public.podcasts FOR SELECT
  USING (true);

-- Episodes: readable by everyone, writable by service role only
CREATE POLICY "Episodes are viewable by everyone"
  ON public.episodes FOR SELECT
  USING (true);

-- Transcript chunks: readable by everyone, writable by service role only
CREATE POLICY "Transcript chunks are viewable by everyone"
  ON public.transcript_chunks FOR SELECT
  USING (true);

-- Bookmarks: users can only see and manage their own bookmarks
CREATE POLICY "Users can view their own bookmarks"
  ON public.bookmarks FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own bookmarks"
  ON public.bookmarks FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own bookmarks"
  ON public.bookmarks FOR DELETE
  USING (auth.uid() = user_id);
