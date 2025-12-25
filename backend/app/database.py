"""Database connection and session management."""
from sqlalchemy import create_engine, event
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from typing import Generator
from app.config import settings

# Create database engine
engine = create_engine(
    settings.DATABASE_URL,
    pool_pre_ping=True,
    pool_size=10,
    max_overflow=20,
    echo=settings.DEBUG
)

# Create session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base class for models
Base = declarative_base()


# Set user_id in session for audit triggers
def set_user_id_for_audit(session: Session, user_id: int):
    """Set user_id in PostgreSQL session for audit triggers."""
    from sqlalchemy import text
    # SET LOCAL работает только в рамках текущей транзакции
    # Используем параметризованный запрос для безопасности
    session.execute(text("SET LOCAL app.user_id = :user_id"), {"user_id": str(user_id)})


# Dependency for getting database session
def get_db() -> Generator[Session, None, None]:
    """Get database session."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

