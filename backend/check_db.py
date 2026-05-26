import asyncio
import os
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text

async def check_tables():
    db_path = "C:/Users/chaud/OneDrive/Desktop/fitness/backend/nutritrack.db"
    if not os.path.exists(db_path):
        print(f"DB file {db_path} does not exist")
        return
    
    engine = create_async_engine(f"sqlite+aiosqlite:///{db_path}")
    async with engine.connect() as conn:
        result = await conn.execute(text("SELECT name FROM sqlite_master WHERE type='table';"))
        tables = result.fetchall()
        print("Tables found:")
        for t in tables:
            print(f" - {t[0]}")

if __name__ == "__main__":
    asyncio.run(check_tables())
