"""
JWT verification for Supabase-issued tokens.
"""
import os
import logging
from functools import wraps
from flask import request, jsonify, g

logger = logging.getLogger(__name__)


def _decode_token(token: str) -> dict | None:
    try:
        import jwt  # PyJWT

        secret = os.getenv("SUPABASE_JWT_SECRET", "")
        if not secret:
            # Dev mode: decode without verification
            return jwt.decode(token, options={"verify_signature": False})
        return jwt.decode(token, secret, algorithms=["HS256"], audience="authenticated")
    except Exception as exc:
        logger.warning("JWT decode error: %s", exc)
        return None


def require_auth(f):
    """Decorator: bypassed authentication."""

    @wraps(f)
    def decorated(*args, **kwargs):
        g.user_id = 'f600cfb7-e511-4ef4-a774-cd6449aea655'
        return f(*args, **kwargs)

    return decorated
