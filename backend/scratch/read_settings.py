import asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import select

from app.core.config import settings
from app.models.app_settings import AppSettings

async def main():
    print(f"[INFO] Connecting to database...")
    engine = create_async_engine(settings.DATABASE_URL)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with async_session() as session:
        stmt = select(AppSettings).where(AppSettings.id == "active_settings")
        result = await session.execute(stmt)
        active_settings = result.scalars().first()

        if active_settings:
            print("\nActive Settings in Database:")
            print(f"- Provider: {active_settings.ai_provider}")
            print(f"- Gemini Model: {active_settings.gemini_model}")
            print(f"- Claude Model: {active_settings.claude_model}")
            # Mask API Keys for security but show if they are configured
            gemini_key = active_settings.gemini_api_key
            claude_key = active_settings.claude_api_key
            print(f"- Gemini Key: {gemini_key[:8] + '...' if gemini_key else 'None/Missing'}")
            print(f"- Claude Key: {claude_key[:8] + '...' if claude_key else 'None/Missing'}")
        else:
            print("\n[WARNING] No 'active_settings' row found in the database!")

    await engine.dispose()

if __name__ == "__main__":
    asyncio.run(main())
