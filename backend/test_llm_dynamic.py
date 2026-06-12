import asyncio
import os
import sys

# Add parent directory to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.core.database import SessionLocal
from app.services.ai import AIService

async def test():
    print("Testing dynamic settings loading...")
    async with SessionLocal() as db:
        ai = AIService(db=db)
        
        print("\n--- Before loading settings ---")
        print("Provider:", ai.provider)
        print("Model:", ai.model)
        
        print("\n--- Loading settings from database ---")
        await ai._load_settings()
        print("Loaded Provider:", ai.provider)
        print("Loaded Model:", ai.model)
        print("API Key configured:", ai.api_key is not None)

if __name__ == "__main__":
    asyncio.run(test())
