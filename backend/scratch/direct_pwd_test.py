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
    # Direct hostname with direct username on port 6543 (this succeeded earlier with yash@1234##@)
    # Let's test with the new password yash9supabase12
    url = "postgresql+asyncpg://postgres:yash9supabase12@db.pxcwkgrpkkoukgaqicky.supabase.co:6543/postgres"
    await test_conn(url)

if __name__ == "__main__":
    asyncio.run(main())
