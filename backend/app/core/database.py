from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.orm import DeclarativeBase
from app.core.config import settings
from typing import AsyncGenerator

# Create async database engine
is_sqlite = settings.DATABASE_URL.startswith("sqlite")
connect_args = (
    {"check_same_thread": False}
    if is_sqlite
    else {
        # Disable prepared statement caching — required for PgBouncer transaction mode
        "prepared_statement_cache_size": 0,
        "statement_cache_size": 0,
    }
)

# Pool settings differ for SQLite (single-file, no pool) vs PostgreSQL (Supabase)
_pool_kwargs = {} if is_sqlite else {
    "pool_size": 5,           # Max persistent connections kept open
    "max_overflow": 10,       # Extra connections allowed under peak load
    "pool_recycle": 300,      # Recycle connections every 5 minutes (Supabase drops idle ~10 min)
    "pool_timeout": 30,       # Timeout waiting for a connection from pool
    "pool_pre_ping": True,    # Always test connection health before handing out
}

engine = create_async_engine(
    settings.DATABASE_URL,
    echo=True if settings.ENVIRONMENT == "development" else False,
    connect_args=connect_args,
    future=True,
    **_pool_kwargs,
)

# Async session factory
SessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False,
    autocommit=False
)

# Declarative base class for SQLAlchemy models
class Base(DeclarativeBase):
    pass

# DB dependency to yield session per request
async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with SessionLocal() as session:
        try:
            yield session
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()
