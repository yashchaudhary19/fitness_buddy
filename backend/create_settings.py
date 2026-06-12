import asyncio
import os
import sys

# Add the parent directory to sys.path so we can import app
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.core.database import engine, SessionLocal, Base
from app.models.app_settings import AppSettings
from app.core.config import settings
from sqlalchemy import select

async def main():
    print("Connecting to database...")
    async with engine.begin() as conn:
        print("Checking/creating tables...")
        # This will create only the app_settings table if it doesn't exist
        await conn.run_sync(Base.metadata.create_all)
        print("Tables checked successfully.")

    async with SessionLocal() as session:
        # Check if active_settings row exists
        stmt = select(AppSettings).where(AppSettings.id == "active_settings")
        result = await session.execute(stmt)
        active_settings = result.scalars().first()

        if not active_settings:
            print("Creating default 'active_settings' row...")
            default_settings = AppSettings(
                id="active_settings",
                ai_provider="gemini",
                gemini_model="gemini-flash-latest",
                claude_model="claude-3-5-sonnet-20241022",
                gemini_api_key=settings.GEMINI_API_KEY or None,
                claude_api_key=None
            )
            session.add(default_settings)
            await session.commit()
            print("Default settings row created successfully.")
        else:
            print("active_settings row already exists:")
            print(f"  AI Provider: {active_settings.ai_provider}")
            print(f"  Gemini Model: {active_settings.gemini_model}")
            print(f"  Claude Model: {active_settings.claude_model}")
            print(f"  Gemini Key Configured: {active_settings.gemini_api_key is not None}")
            print(f"  Claude Key Configured: {active_settings.claude_api_key is not None}")

if __name__ == "__main__":
    asyncio.run(main())
