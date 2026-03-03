# Hooks

Custom React hooks that encapsulate stateful logic and side effects.

## Key Files

- **`useSearch.ts`** — Manages search query state, mode (keyword/semantic), pagination, and API calls to the search endpoints.
- **`useAuth.ts`** — Convenience wrapper around the `AuthContext` that throws if used outside an `AuthProvider`.
- **`useBookmarks.ts`** — Manages bookmark state for search result cards. Fetches existing bookmarks on mount when authenticated, maintains a set of bookmarked chunk IDs, and exposes a `saveBookmark` function that calls `POST /bookmarks` and updates local state optimistically.

## useBookmarks Implementation Decisions

- **Two-layer state**: Uses `fetchedChunkIds` (from the initial GET request) and `locallyAdded` (from POST calls during the session) merged via `useMemo` to avoid re-fetching the full list after each save.
- **Ref-based cancellation**: Uses `useRef` instead of a local `cancelled` variable with `setLoading` to avoid the `react-hooks/set-state-in-effect` lint rule that disallows synchronous `setState` calls directly in effect bodies.
- **Graceful degradation**: Fetch errors for bookmarks are silently ignored since bookmark state is non-critical — search results still render normally without bookmark indicators.
- **Empty set constant**: A module-level `EMPTY_SET` is reused when the user is logged out to avoid creating new Set instances on every render.
