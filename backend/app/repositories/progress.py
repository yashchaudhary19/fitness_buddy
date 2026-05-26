import uuid
from datetime import date, timedelta
from typing import List, Optional, Set
from sqlalchemy import select, and_, or_
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.measurement import BodyMeasurement
from app.models.food import FoodLogEntry
from app.models.water import WaterLog
from app.models.exercise import ExerciseLog
from app.repositories.base import BaseRepository

class BodyMeasurementRepository(BaseRepository[BodyMeasurement]):
    def __init__(self, db: AsyncSession):
        super().__init__(BodyMeasurement, db)

    async def get_history(self, user_id: uuid.UUID, limit: int = 100) -> List[BodyMeasurement]:
        """Fetch body measurements logged by a user sorted by logged_at descending."""
        stmt = (
            select(BodyMeasurement)
            .filter(BodyMeasurement.user_id == user_id)
            .order_by(BodyMeasurement.logged_at.desc())
            .limit(limit)
        )
        result = await self.db.execute(stmt)
        return list(result.scalars().all())


class StreakRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_streak_stats(self, user_id: uuid.UUID) -> dict:
        """
        Calculate user logging streaks.
        A user is active on a given date if they logged food, water, or exercise.
        """
        # Fetch unique dates user logged food
        food_stmt = select(FoodLogEntry.log_date).filter(FoodLogEntry.user_id == user_id).distinct()
        food_res = await self.db.execute(food_stmt)
        food_dates = {row[0] for row in food_res.fetchall()}

        # Fetch unique dates user logged water
        water_stmt = select(WaterLog.log_date).filter(WaterLog.user_id == user_id).distinct()
        water_res = await self.db.execute(water_stmt)
        water_dates = {row[0] for row in water_res.fetchall()}

        # Fetch unique dates user logged exercise
        exec_stmt = select(ExerciseLog.log_date).filter(ExerciseLog.user_id == user_id).distinct()
        exec_res = await self.db.execute(exec_stmt)
        exec_dates = {row[0] for row in exec_res.fetchall()}

        # Union all active logging dates
        active_dates: Set[date] = food_dates.union(water_dates).union(exec_dates)
        
        if not active_dates:
            return {
                "current_streak": 0,
                "longest_streak": 0,
                "last_logged_date": None
            }

        sorted_dates = sorted(list(active_dates), reverse=True)
        last_logged = sorted_dates[0]
        today = date.today()

        # Check if the user logged today or yesterday
        # If not, current streak has expired and is 0
        if (today - last_logged).days > 1:
            current_streak = 0
        else:
            current_streak = 0
            check_date = last_logged
            while check_date in active_dates:
                current_streak += 1
                check_date -= timedelta(days=1)

        # Calculate all-time longest streak
        sorted_dates_asc = sorted(list(active_dates))
        longest_streak = 0
        temp_streak = 0
        prev_date = None

        for d in sorted_dates_asc:
            if prev_date is None:
                temp_streak = 1
            elif (d - prev_date).days == 1:
                temp_streak += 1
            elif (d - prev_date).days > 1:
                if temp_streak > longest_streak:
                    longest_streak = temp_streak
                temp_streak = 1
            prev_date = d

        if temp_streak > longest_streak:
            longest_streak = temp_streak

        return {
            "current_streak": current_streak,
            "longest_streak": longest_streak,
            "last_logged_date": last_logged
        }
