"""
SQLAlchemy engine + session factory.

We use Core (text() queries) rather than the ORM to stay close to the SQL
written in the assignment-friendly PHP version. This keeps the code
transparent for the report.
"""
from sqlalchemy import create_engine
from sqlalchemy.orm import scoped_session, sessionmaker

import config

engine = create_engine(
    config.SQLALCHEMY_URL,
    pool_pre_ping=True,
    pool_recycle=3600,
    future=True,
)

SessionLocal = scoped_session(
    sessionmaker(bind=engine, autoflush=False, autocommit=False, future=True)
)


def get_db():
    """Yield a session; caller should close it (we use teardown in app.py)."""
    return SessionLocal()
