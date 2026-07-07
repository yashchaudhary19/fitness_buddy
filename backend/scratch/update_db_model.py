import asyncio
from app.core.database import SessionLocal
from app.models.app_settings import AppSettings
from sqlalchemy import select

async def update_settings():
    async with SessionLocal() as db:
        stmt = select(AppSettings).where(AppSettings.id == "active_settings")
        result = await db.execute(stmt)
        active_settings = result.scalars().first()
        if active_settings:
            active_settings.gemini_model = "gemini-2.5-flash"
            await db.commit()
            print("Successfully updated active gemini_model to gemini-2.5-flash in database settings!")
        else:
            print("No active_settings row found to update.")

if __name__ == "__main__":
    asyncio.run(update_settings())
