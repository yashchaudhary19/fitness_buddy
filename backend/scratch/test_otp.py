import asyncio
import httpx
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import select

from app.core.config import settings
from app.models.otp import OTPCode

async def get_latest_otp(email: str) -> str:
    db_url = settings.DATABASE_URL
    engine = create_async_engine(db_url)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with async_session() as session:
        stmt = select(OTPCode).where(OTPCode.email == email).order_by(OTPCode.created_at.desc())
        result = await session.execute(stmt)
        otp_entry = result.scalars().first()
        code = otp_entry.code if otp_entry else None
        
    await engine.dispose()
    return code

async def test_otp_flow():
    email = "test_otp_user@example.com"
    base_url = "http://localhost:8000" # We will mock/test locally or query endpoint directly if server is not up
    
    print("\n--- Testing send-otp endpoint ---")
    payload_send = {"email": email}
    headers = {"Content-Type": "application/json"}
    
    # We can invoke the FastAPI endpoint handler functions directly to test without running a full server!
    from fastapi import Request
    from app.api.endpoints.auth import send_otp, verify_otp
    from app.schemas.user import OTPSendRequest, OTPVerifyRequest
    from app.core.database import SessionLocal
    
    # 1. Direct call to send_otp
    async with SessionLocal() as db:
        req = OTPSendRequest(email=email)
        res_send = await send_otp(req, db)
        print("Send OTP Response:", res_send.message)
        
    # 2. Get the generated code from database
    code = await get_latest_otp(email)
    print(f"Retrieved generated OTP from DB: {code}")
    assert code is not None, "OTP Code should be generated in the database"
    
    # 3. Direct call to verify_otp
    print("\n--- Testing verify-otp endpoint ---")
    async with SessionLocal() as db:
        req_verify = OTPVerifyRequest(email=email, code=code, name="OTP Test User")
        res_verify = await verify_otp(req_verify, db)
        print("Verify OTP Success! Response Message:", res_verify.message)
        print("Access Token:", res_verify.data.access_token[:20] + "...")
        print("User profile:", res_verify.data.user.name, f"({res_verify.data.user.email})")

if __name__ == "__main__":
    asyncio.run(test_otp_flow())
