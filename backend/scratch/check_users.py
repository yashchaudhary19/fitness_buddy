import asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import select

from app.core.config import settings
from app.models.user import User

async def main():
    print(f"[INFO] Connecting to: {settings.DATABASE_URL}")
    engine = create_async_engine(settings.DATABASE_URL)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with async_session() as session:
        result = await session.execute(select(User))
        users = result.scalars().all()
        print(f"\nFound {len(users)} users:")
        for u in users:
            print(f"- ID: {u.id} | Email: {u.email} | Name: {u.name} | Active: {u.is_active} | Created: {u.created_at}")

    await engine.dispose()

if __name__ == "__main__":
    asyncio.run(main())
