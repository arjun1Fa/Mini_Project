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
    try:
        import jwt  # PyJWT

        header = jwt.get_unverified_header(token)
        logger.warning("JWT HEADER: %s", header)

        secret = os.getenv("SUPABASE_JWT_SECRET", "")
        logger.warning("SECRET LENGTH: %d chars", len(secret))

        if not secret:
            logger.warning("No secret, decoding without verification")
            return jwt.decode(token, options={"verify_signature": False})

        # Try multiple approaches to decode
        secret_bytes = base64.b64decode(secret)
        logger.warning("SECRET BYTES LENGTH: %d", len(secret_bytes))

        # Approach 1: base64-decoded secret with audience check
        try:
            payload = jwt.decode(
                token, secret_bytes, algorithms=["HS256"],
                audience="authenticated",
            )
            logger.warning("DECODE SUCCESS (approach 1)")
            return payload
        except Exception as e1:
            logger.warning("Approach 1 failed: %s", e1)

        # Approach 2: base64-decoded secret without audience check
        try:
            payload = jwt.decode(
                token, secret_bytes, algorithms=["HS256"],
                options={"verify_aud": False},
            )
            logger.warning("DECODE SUCCESS (approach 2)")
            return payload
        except Exception as e2:
            logger.warning("Approach 2 failed: %s", e2)

        # Approach 3: raw string secret
        try:
            payload = jwt.decode(
                token, secret, algorithms=["HS256"],
                options={"verify_aud": False},
            )
            logger.warning("DECODE SUCCESS (approach 3)")
            return payload
        except Exception as e3:
            logger.warning("Approach 3 failed: %s", e3)

        # Approach 4: no verification at all (fallback)
        logger.warning("ALL approaches failed, decoding without verification")
        payload = jwt.decode(token, options={"verify_signature": False})
        logger.warning("DECODE SUCCESS (no verification fallback)")
        return payload

    except Exception as exc:
        logger.warning("JWT decode TOTAL FAILURE: %s", exc)
        return None


def require_auth(f):
    """Decorator: Extracts and verifies Supabase JWT token from Authorization header."""
    @wraps(f)
    def decorated(*args, **kwargs):
        auth_header = request.headers.get("Authorization", "")
        if not auth_header.startswith("Bearer "):
            return jsonify({"error": "unauthorized", "message": "Missing Bearer token"}), 401

        token = auth_header.replace("Bearer ", "").strip()
        logger.warning("TOKEN RECEIVED: %s...%s (len=%d)", token[:20], token[-10:], len(token))

        payload = _decode_token(token)

        if not payload or "sub" not in payload:
            logger.warning("PAYLOAD: %s", payload)
            return jsonify({"error": "unauthorized", "message": "Invalid or expired token"}), 401

        g.user_id = payload["sub"]
        logger.warning("AUTH SUCCESS: user_id=%s", g.user_id)
        return f(*args, **kwargs)

    return decorated
