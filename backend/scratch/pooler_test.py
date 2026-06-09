import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text

async def test_conn(url):
    print(f"Testing: {url}")
    engine = create_async_engine(url)
    try:
        async with engine.connect() as conn:
            result = await conn.execute(text("SELECT 1"))
            print(f"  SUCCESS! {result.fetchall()}")
            return True
    except Exception as e:
        print(f"  FAILED: {e}")
        return False
    finally:
        await engine.dispose()

async def main():
    urls = [
        # 1. Singapore pooler on port 6543 (Transaction Mode)
        "postgresql+asyncpg://postgres.pxcwkgrpkkoukgaqicky:yash9supabase12@aws-1-ap-southeast-1.pooler.supabase.com:6543/postgres",
        # 2. Singapore pooler on port 5432 (Session Mode)
        "postgresql+asyncpg://postgres.pxcwkgrpkkoukgaqicky:yash9supabase12@aws-1-ap-southeast-1.pooler.supabase.com:5432/postgres",
    ]
    for url in urls:
        await test_conn(url)

if __name__ == "__main__":
    asyncio.run(main())
