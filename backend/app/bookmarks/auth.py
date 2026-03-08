"""Authentication dependency for bookmark endpoints.

Verifies the Supabase JWT locally using the JWT secret and extracts
the authenticated user's ID from the token claims — no network call required.
"""

import os

import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

security = HTTPBearer()


def _get_jwt_secret() -> str:
    """Return the Supabase JWT secret from environment variables."""
    secret = os.environ.get("SUPABASE_JWT_SECRET")
    if not secret:
        raise RuntimeError(
            "SUPABASE_JWT_SECRET environment variable must be set."
        )
    return secret


def get_current_user_id(
    credentials: HTTPAuthorizationCredentials = Depends(security),  # noqa: B008
) -> str:
    """Extract and verify the user ID from a Supabase JWT.

    Decodes and verifies the token locally using the Supabase JWT secret.
    Returns the user's UUID string from the ``sub`` claim.

    Raises
    ------
    HTTPException (401)
        If the token is missing, invalid, or expired.
    """
    token = credentials.credentials
    secret = _get_jwt_secret()

    try:
        payload = jwt.decode(
            token,
            secret,
            algorithms=["HS256"],
            audience="authenticated",
        )
    except jwt.ExpiredSignatureError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired.",
        ) from exc
    except jwt.InvalidTokenError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired authentication token.",
        ) from exc

    user_id: str | None = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired authentication token.",
        )

    return user_id
