# Database Migrations

SQL migration files for the Supabase PostgreSQL database. These are applied via the Supabase dashboard or CLI.

## Migrations

| File | Description |
|---|---|
| `001_keyword_search_function.sql` | Creates the `keyword_search` RPC function for full-text search with episode/podcast metadata joins and pagination |

## How to Apply

Migrations can be applied through the Supabase SQL Editor in the dashboard, or via the Supabase CLI:

```bash
supabase db push
```
