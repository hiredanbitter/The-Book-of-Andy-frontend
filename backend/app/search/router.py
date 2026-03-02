"""FastAPI router for search endpoints."""

from fastapi import APIRouter, Query

from app.search.schemas import SearchResponse
from app.search.service import keyword_search

router = APIRouter(prefix="/search", tags=["search"])


@router.get("/keyword", response_model=SearchResponse)
def search_keyword(
    q: str = Query(..., min_length=1, description="Search term"),
    page: int = Query(1, ge=1, description="Page number (1-based)"),
    page_size: int = Query(10, ge=1, le=100, description="Results per page"),
) -> SearchResponse:
    """Search transcript chunks using PostgreSQL full-text search.

    Returns paginated results with matching chunks, surrounding context
    (2 chunks before and after), and episode/podcast metadata.
    """
    return keyword_search(query=q, page=page, page_size=page_size)
