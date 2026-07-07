import asyncio
import httpx
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import select

from app.core.config import settings
from app.models.app_settings import AppSettings

async def main():
    db_url = settings.DATABASE_URL
    print(f"[INFO] Connecting to database using URL: {db_url}")
    engine = create_async_engine(
        db_url,
        connect_args={
            "prepared_statement_cache_size": 0,
            "statement_cache_size": 0,
        }
    )
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with async_session() as session:
        stmt = select(AppSettings).where(AppSettings.id == "active_settings")
        result = await session.execute(stmt)
        active_settings = result.scalars().first()

        if not active_settings or not active_settings.gemini_api_key:
            print("[ERROR] Gemini API Key is missing in database settings!")
            await engine.dispose()
            return

        model = active_settings.gemini_model
        api_key = active_settings.gemini_api_key

    await engine.dispose()

    print(f"[INFO] Testing Gemini API with Model: {model}")
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"
    payload = {
        "contents": [
            {
                "role": "user",
                "parts": [{"text": "Hello, respond with 'OK'."}]
            }
        ]
    }
    headers = {
        "Content-Type": "application/json",
        "x-goog-api-key": api_key
    }

    async with httpx.AsyncClient(timeout=10.0) as client:
        try:
            response = await client.post(url, headers=headers, json=payload)
            print(f"\nResponse Status: {response.status_code}")
            print("Response Body:")
            print(response.text)
        except Exception as e:
            print(f"[ERROR] HTTP Request failed: {e}")

if __name__ == "__main__":
    asyncio.run(main())
