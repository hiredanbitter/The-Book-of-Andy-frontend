# Supabase — Database & Infrastructure

This directory contains the SQL migration files that define the Supabase database schema, storage configuration, and security policies for the Podcast Transcript Search App.

## Purpose

The Supabase project provides:

- **PostgreSQL Database** — Stores all structured data (podcasts, episodes, transcript chunks, bookmarks)
- **pgvector Extension** — Enables vector similarity search on transcript chunk embeddings (1536-dimensional vectors from OpenAI)
- **Supabase Storage** — Stores raw transcript text files in a private `transcripts` bucket
- **Supabase Auth** — Handles Google OAuth authentication for user sign-in

## Key Files

| File | Description |
|------|-------------|
| `migrations/20260301_001_enable_pgvector.sql` | Enables the pgvector extension for vector similarity search |
| `migrations/20260301_002_create_initial_schema.sql` | Creates all database tables, indexes, RLS policies, and full-text search support |
| `migrations/20260301_003_create_storage_bucket.sql` | Creates the `transcripts` storage bucket and access policies |

## Database Schema

### `podcasts`
| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key, auto-generated |
| name | TEXT | Podcast name |
| created_at | TIMESTAMPTZ | Auto-set on creation |

### `episodes`
| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key, auto-generated |
| podcast_id | UUID | FK to `podcasts.id`, cascade delete |
| title | TEXT | Episode title |
| episode_number | INTEGER | Nullable |
| publication_date | DATE | Nullable |
| description | TEXT | Nullable |
| transcript_file_url | TEXT | URL to raw transcript in Supabase Storage |
| created_at | TIMESTAMPTZ | Auto-set on creation |

### `transcript_chunks`
| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key, auto-generated |
| episode_id | UUID | FK to `episodes.id`, cascade delete |
| chunk_text | TEXT | Raw text of the chunk |
| speaker_label | TEXT | Speaker identifier |
| start_timestamp | TEXT | Start time of the chunk |
| end_timestamp | TEXT | End time of the chunk |
| embedding | vector(1536) | OpenAI embedding vector |
| chunk_index | INTEGER | Position in the episode |
| created_at | TIMESTAMPTZ | Auto-set on creation |
| fts | tsvector | Auto-generated full-text search column |

### `bookmarks`
| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key, auto-generated |
| user_id | UUID | FK to `auth.users.id`, cascade delete |
| chunk_id | UUID | FK to `transcript_chunks.id`, cascade delete |
| created_at | TIMESTAMPTZ | Auto-set on creation |

Unique constraint on `(user_id, chunk_id)` prevents duplicate bookmarks.

## Row Level Security (RLS)

All tables have RLS enabled:

- **podcasts, episodes, transcript_chunks** — Readable by everyone (anonymous + authenticated). Write operations require the service role key (used by the backend).
- **bookmarks** — Users can only view, insert, and delete their own bookmarks (enforced via `auth.uid() = user_id`).

## Storage

A private `transcripts` bucket stores raw transcript text files. Access policies:
- Service role has full access (read/write/delete)
- Authenticated users can read files

## Indexes

- B-tree indexes on foreign keys for join performance
- Composite index on `(episode_id, chunk_index)` for ordered chunk retrieval
- HNSW index on `embedding` column for fast cosine similarity search
- GIN index on `fts` column for full-text keyword search

## Implementation Decisions

- **UUID primary keys** — Used across all tables for consistency with Supabase conventions and to avoid sequential ID enumeration.
- **Cascade deletes** — Deleting a podcast removes its episodes, which removes their chunks, which removes related bookmarks. This keeps the database clean.
- **1536-dimensional vectors** — Matches the output of OpenAI's `text-embedding-ada-002` and `text-embedding-3-small` models.
- **HNSW index** — Chosen over IVFFlat for better recall and no need for periodic retraining. Suitable for the expected data size.
- **Generated `fts` column** — Automatically maintained by PostgreSQL, no application-level sync needed.
- **Separate migration files** — Each migration handles a single concern (extension, schema, storage) for clarity and easier debugging.
