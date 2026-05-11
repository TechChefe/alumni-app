"""
JWT issue + verify helpers.
Mirrors the Firebase JWT helper from the PHP version.
"""
import time
from functools import wraps
from typing import Optional

import jwt
from flask import request, jsonify

import config


def issue_token(alumni_id: int, email: str) -> str:
    now = int(time.time())
    payload = {
        "iss": "alumni.ds.uth.gr",
        "iat": now,
        "nbf": now,
        "exp": now + config.JWT_TTL_SECONDS,
        "sub": str(alumni_id),
        "email": email,
    }
    return jwt.encode(payload, config.JWT_SECRET, algorithm=config.JWT_ALGO)


def decode_token(token: str) -> Optional[dict]:
    try:
        return jwt.decode(token, config.JWT_SECRET, algorithms=[config.JWT_ALGO])
    except jwt.PyJWTError:
        return None


def get_bearer_token() -> Optional[str]:
    header = request.headers.get("Authorization", "")
    if header.lower().startswith("bearer "):
        return header[7:].strip()
    return None


def require_auth(fn):
    """Decorator: rejects with 401 unless a valid Bearer JWT is present.
    The decoded sub (alumni id) is injected as kwarg 'auth_id'."""
    @wraps(fn)
    def wrapper(*args, **kwargs):
        token = get_bearer_token()
        if not token:
            return jsonify({"error": "Missing Authorization Bearer token"}), 401
        payload = decode_token(token)
        if not payload or "sub" not in payload:
            return jsonify({"error": "Invalid or expired token"}), 401
        kwargs["auth_id"] = int(payload["sub"])
        return fn(*args, **kwargs)
    return wrapper
