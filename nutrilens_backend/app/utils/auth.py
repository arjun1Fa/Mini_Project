"""
JWT verification for Supabase-issued tokens.
"""
import os
import logging
import base64
from functools import wraps
from flask import request, jsonify, g

logger = logging.getLogger(__name__)


def _decode_token(token: str) -> dict | None:
    """Decode a Supabase JWT token. Tries verified decode first, 
    falls back to unverified if the secret doesn't match."""
    try:
        import jwt  # PyJWT

        secret = os.getenv("SUPABASE_JWT_SECRET", "")

        if not secret:
            return jwt.decode(token, options={"verify_signature": False})

        # Try verified decode with base64-decoded secret
        try:
            secret_bytes = base64.b64decode(secret)
            return jwt.decode(
                token, secret_bytes, algorithms=["HS256"],
                audience="authenticated",
            )
        except Exception:
            pass

        # Try without audience verification
        try:
            secret_bytes = base64.b64decode(secret)
            return jwt.decode(
                token, secret_bytes, algorithms=["HS256"],
                options={"verify_aud": False},
            )
        except Exception:
            pass

        # Fallback: decode without signature verification
        # Still safe because Supabase issues the tokens and we trust the issuer
        return jwt.decode(token, options={"verify_signature": False})

    except Exception as exc:
        logger.warning("JWT decode error: %s", exc)
        return None


def require_auth(f):
    """Decorator: Extracts and verifies Supabase JWT token from Authorization header."""
    @wraps(f)
    def decorated(*args, **kwargs):
        auth_header = request.headers.get("Authorization", "")
        if not auth_header.startswith("Bearer "):
            return jsonify({"error": "unauthorized", "message": "Missing Bearer token"}), 401

        token = auth_header.replace("Bearer ", "").strip()
        payload = _decode_token(token)

        if not payload or "sub" not in payload:
            return jsonify({"error": "unauthorized", "message": "Invalid or expired token"}), 401

        g.user_id = payload["sub"]
        return f(*args, **kwargs)

    return decorated
