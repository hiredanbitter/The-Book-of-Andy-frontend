/**
 * Custom hook that manages bookmark state for search result cards.
 *
 * Fetches the user's existing bookmarks on mount (when authenticated) and
 * exposes helpers to check whether a chunk is bookmarked and to create new
 * bookmarks.
 */

import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { useAuth } from './useAuth'
import {
  BookmarkLimitError,
  createBookmark,
  fetchBookmarks,
} from '../services/bookmarksApi'

interface UseBookmarksReturn {
  /** Set of chunk IDs that the current user has bookmarked. */
  bookmarkedChunkIds: Set<string>
  /**
   * Save a bookmark for the given chunk.
   * Returns an object indicating success or a limit-reached error message.
   */
  saveBookmark: (chunkId: string) => Promise<{ success: boolean; error?: string }>
}

const EMPTY_SET: Set<string> = new Set()

export function useBookmarks(): UseBookmarksReturn {
  const { session } = useAuth()
  const accessToken = session?.access_token ?? null
  const [fetchedChunkIds, setFetchedChunkIds] = useState<Set<string>>(
    new Set(),
  )
  const [locallyAdded, setLocallyAdded] = useState<Set<string>>(new Set())
  const cancelledRef = useRef(false)

  // Fetch existing bookmarks when user is authenticated
  useEffect(() => {
    cancelledRef.current = false

    if (!accessToken) return

    fetchBookmarks(accessToken)
      .then((bookmarks) => {
        if (!cancelledRef.current) {
          const ids = new Set(bookmarks.map((b) => b.chunk_id))
          setFetchedChunkIds(ids)
        }
      })
      .catch(() => {
        // Silently ignore fetch errors — bookmarks are not critical
      })

    return () => {
      cancelledRef.current = true
    }
  }, [accessToken])

  // Merge fetched + locally-added IDs, or return empty set if logged out
  const bookmarkedChunkIds = useMemo(() => {
    if (!accessToken) return EMPTY_SET
    if (locallyAdded.size === 0) return fetchedChunkIds
    const merged = new Set(fetchedChunkIds)
    for (const id of locallyAdded) {
      merged.add(id)
    }
    return merged
  }, [accessToken, fetchedChunkIds, locallyAdded])

  const saveBookmark = useCallback(
    async (chunkId: string): Promise<{ success: boolean; error?: string }> => {
      if (!accessToken) {
        return { success: false, error: 'Not authenticated' }
      }

      try {
        await createBookmark(accessToken, chunkId)
        setLocallyAdded((prev) => new Set(prev).add(chunkId))
        return { success: true }
      } catch (err) {
        if (err instanceof BookmarkLimitError) {
          return { success: false, error: err.message }
        }
        return {
          success: false,
          error: 'Failed to save bookmark. Please try again.',
        }
      }
    },
    [accessToken],
  )

  return {
    bookmarkedChunkIds,
    saveBookmark,
  }
}
