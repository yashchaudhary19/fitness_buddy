import uuid
from datetime import date
from typing import List
from sqlalchemy import select, and_, func
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.water import WaterLog
from app.repositories.base import BaseRepository

class WaterLogRepository(BaseRepository[WaterLog]):
    def __init__(self, db: AsyncSession):
        super().__init__(WaterLog, db)

    async def get_logs_by_date(self, user_id: uuid.UUID, log_date: date) -> List[WaterLog]:
        """Fetch all water logs logged by a user on a given date."""
        stmt = select(WaterLog).filter(and_(WaterLog.user_id == user_id, WaterLog.log_date == log_date))
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def get_daily_total(self, user_id: uuid.UUID, log_date: date) -> int:
        """Sum total water (ml) consumed by a user on a given date."""
        stmt = (
            select(func.sum(WaterLog.amount_ml))
            .filter(and_(WaterLog.user_id == user_id, WaterLog.log_date == log_date))
        )
        result = await self.db.execute(stmt)
        return result.scalar() or 0
