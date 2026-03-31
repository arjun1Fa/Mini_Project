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
    """Decorator: validates Bearer JWT and sets g.user_id."""

    @wraps(f)
    def decorated(*args, **kwargs):
        auth = request.headers.get("Authorization", "")
        if not auth.startswith("Bearer "):
            return jsonify({"error": "missing_token", "message": "Authorization header required"}), 401
        token = auth[7:]
        payload = _decode_token(token)
        if payload is None:
            return jsonify({"error": "invalid_token", "message": "Invalid or expired token"}), 401
        g.user_id = payload.get("sub")
        return f(*args, **kwargs)

    return decorated
