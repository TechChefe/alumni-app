"""
Configuration for the Alumni REST API.

XAMPP defaults (Windows): MySQL on 127.0.0.1:3306, root user, empty password.
If your MySQL root has a password, set DB_PASS below.
"""
import os

# --- Database ---
DB_HOST = os.getenv("DB_HOST", "127.0.0.1")
DB_PORT = int(os.getenv("DB_PORT", "3306"))
DB_NAME = os.getenv("DB_NAME", "alumni_db")
DB_USER = os.getenv("DB_USER", "root")
DB_PASS = os.getenv("DB_PASS", "")  # XAMPP default

SQLALCHEMY_URL = (
    f"mysql+pymysql://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    "?charset=utf8mb4"
)

# --- JWT ---
# CHANGE THIS in production. For coursework localhost it's fine.
JWT_SECRET = os.getenv("JWT_SECRET", "uth-ds-alumni-2026-super-secret-please-change")
JWT_ALGO = "HS256"
JWT_TTL_SECONDS = 8 * 60 * 60  # 8 hours

# --- API ---
API_HOST = os.getenv("API_HOST", "0.0.0.0")
API_PORT = int(os.getenv("API_PORT", "5000"))
DEBUG = os.getenv("FLASK_DEBUG", "1") == "1"
