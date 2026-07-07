import uuid
from datetime import datetime, timezone
from typing import Optional
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.otp import OTPCode
from app.repositories.base import BaseRepository

class OTPCodeRepository(BaseRepository[OTPCode]):
    def __init__(self, db: AsyncSession):
        super().__init__(OTPCode, db)

    async def get_valid_otp(self, email: str, code: str) -> Optional[OTPCode]:
        """Fetch a valid (non-expired, non-used) OTP code for an email."""
        # Use timezone-aware UTC datetime but make it naive for comparing with SQLite/postgres DateTime fields
        now_utc = datetime.now(timezone.utc).replace(tzinfo=None)
        stmt = select(OTPCode).where(
            OTPCode.email == email,
            OTPCode.code == code,
            OTPCode.is_used == False,
            OTPCode.expires_at > now_utc
        )
        result = await self.db.execute(stmt)
        return result.scalars().first()
