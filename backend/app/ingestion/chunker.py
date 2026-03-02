"""Fixed-size chunker for transcript lines.

Groups parsed transcript lines into non-overlapping chunks.  The chunk
size is configurable via a function parameter, with a sensible default
from ``config.py``.
"""

import logging
from dataclasses import dataclass

from app.ingestion.config import DEFAULT_CHUNK_SIZE
from app.ingestion.parser import TranscriptLine

logger = logging.getLogger(__name__)


@dataclass
class TranscriptChunk:
    """A chunk of consecutive transcript lines ready for embedding."""

    chunk_text: str
    speaker_label: str
    start_timestamp: str
    end_timestamp: str
    chunk_index: int


def build_chunks(
    lines: list[TranscriptLine],
    chunk_size: int = DEFAULT_CHUNK_SIZE,
) -> list[TranscriptChunk]:
    """Create non-overlapping chunks from a list of parsed transcript lines.

    Parameters
    ----------
    lines:
        Ordered list of transcript lines for a single episode.
    chunk_size:
        Number of lines per chunk (default from config).

    Returns
    -------
    list[TranscriptChunk]
        Ordered list of chunks with metadata derived from their lines.
    """
    if not lines:
        return []

    chunks: list[TranscriptChunk] = []

    for chunk_index, start in enumerate(range(0, len(lines), chunk_size)):
        window = lines[start : start + chunk_size]
        if not window:
            break

        # Combine line texts, preserving the original transcript format
        chunk_text = "\n".join(
            f"[{line.start_timestamp} - {line.end_timestamp}] "
            f"{line.speaker_label}: {line.text}"
            for line in window
        )

        chunks.append(
            TranscriptChunk(
                chunk_text=chunk_text,
                speaker_label=window[0].speaker_label,
                start_timestamp=window[0].start_timestamp,
                end_timestamp=window[-1].end_timestamp,
                chunk_index=chunk_index,
            )
        )

    logger.info(
        "Created %d chunks (chunk_size=%d) from %d lines",
        len(chunks),
        chunk_size,
        len(lines),
    )
    return chunks
