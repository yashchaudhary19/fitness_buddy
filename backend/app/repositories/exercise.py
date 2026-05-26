import uuid
from datetime import date
from typing import List, Dict, Any, Optional
from sqlalchemy import select, and_, func
from sqlalchemy.orm import joinedload
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.exercise import ExerciseLog, ExerciseSet, ExerciseType
from app.repositories.base import BaseRepository

class ExerciseLogRepository(BaseRepository[ExerciseLog]):
    def __init__(self, db: AsyncSession):
        super().__init__(ExerciseLog, db)

    async def remove(self, id: uuid.UUID) -> Optional[ExerciseLog]:
        """Delete an exercise log by ID, eagerly loading sets so ORM cascade works correctly."""
        stmt = (
            select(ExerciseLog)
            .filter(ExerciseLog.id == id)
            .options(joinedload(ExerciseLog.sets))
        )
        result = await self.db.execute(stmt)
        obj = result.scalars().first()
        if obj:
            await self.db.delete(obj)
            await self.db.flush()
        return obj

    async def get_logs_by_date(self, user_id: uuid.UUID, log_date: date) -> List[ExerciseLog]:
        """Fetch all exercise logs by user for a given date, including all sets."""
        stmt = (
            select(ExerciseLog)
            .filter(and_(ExerciseLog.user_id == user_id, ExerciseLog.log_date == log_date))
            .options(joinedload(ExerciseLog.sets))
        )
        result = await self.db.execute(stmt)
        return list(result.unique().scalars().all())

    async def get_daily_calories_burned(self, user_id: uuid.UUID, log_date: date) -> float:
        """Sum total calories burned via exercise on a given date."""
        stmt = (
            select(func.sum(ExerciseLog.calories_burned))
            .filter(and_(ExerciseLog.user_id == user_id, ExerciseLog.log_date == log_date))
        )
        result = await self.db.execute(stmt)
        return float(result.scalar() or 0.0)

    async def create_log_with_sets(
        self,
        user_id: uuid.UUID,
        log_data: Dict[str, Any],
        sets_data: Optional[List[Dict[str, Any]]] = None
    ) -> ExerciseLog:
        """Create exercise log with associated sets."""
        db_log = ExerciseLog(
            user_id=user_id,
            exercise_name=log_data["exercise_name"],
            exercise_type=log_data["exercise_type"],
            duration_minutes=log_data.get("duration_minutes"),
            calories_burned=log_data["calories_burned"],
            notes=log_data.get("notes"),
            log_date=log_data["log_date"]
        )
        
        self.db.add(db_log)
        await self.db.flush()  # Populates db_log.id

        if sets_data and log_data["exercise_type"] == ExerciseType.STRENGTH:
            for s in sets_data:
                db_set = ExerciseSet(
                    exercise_log_id=db_log.id,
                    set_number=s["set_number"],
                    reps=s.get("reps"),
                    weight_kg=s.get("weight_kg"),
                    completed=s.get("completed", True)
                )
                self.db.add(db_set)
            await self.db.flush()

        # Refresh log to include loaded sets
        await self.db.refresh(db_log)
        return db_log
