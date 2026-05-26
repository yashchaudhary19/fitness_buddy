import uuid
from typing import List, Optional, Dict, Any
from sqlalchemy import select, and_, func
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.weight import WeightEntry
from app.models.goal import UserGoal
from app.repositories.base import BaseRepository

class WeightEntryRepository(BaseRepository[WeightEntry]):
    def __init__(self, db: AsyncSession):
        super().__init__(WeightEntry, db)

    async def get_by_user_id(self, user_id: uuid.UUID, limit: int = 100) -> List[WeightEntry]:
        """Fetch weight log history sorted chronologically descending."""
        stmt = select(WeightEntry).filter(WeightEntry.user_id == user_id).order_by(WeightEntry.logged_at.desc()).limit(limit)
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def get_latest_weight(self, user_id: uuid.UUID) -> Optional[WeightEntry]:
        """Fetch the most recent weight entry for a user."""
        stmt = select(WeightEntry).filter(WeightEntry.user_id == user_id).order_by(WeightEntry.logged_at.desc()).limit(1)
        result = await self.db.execute(stmt)
        return result.scalars().first()

    async def get_first_weight(self, user_id: uuid.UUID) -> Optional[WeightEntry]:
        """Fetch the oldest weight entry for a user (baseline weight)."""
        stmt = select(WeightEntry).filter(WeightEntry.user_id == user_id).order_by(WeightEntry.logged_at.asc()).limit(1)
        result = await self.db.execute(stmt)
        return result.scalars().first()

    async def get_weight_stats(self, user_id: uuid.UUID) -> Dict[str, Any]:
        """
        Calculate weight change stats:
          - start_weight_kg
          - current_weight_kg
          - goal_weight_kg
          - total_change_kg
          - trend_kg_per_week (weekly weight loss/gain rate since starting)
          - entries_count
        """
        # Get count
        stmt_count = select(func.count(WeightEntry.id)).filter(WeightEntry.user_id == user_id)
        count_result = await self.db.execute(stmt_count)
        count = count_result.scalar() or 0

        if count == 0:
            # Try to fall back to user goal current_weight if no logs exist
            goal_stmt = select(UserGoal).filter(UserGoal.user_id == user_id)
            goal_res = await self.db.execute(goal_stmt)
            goal = goal_res.scalars().first()
            if goal:
                return {
                    "start_weight_kg": goal.current_weight_kg,
                    "current_weight_kg": goal.current_weight_kg,
                    "goal_weight_kg": goal.target_weight_kg,
                    "total_change_kg": 0.0,
                    "trend_kg_per_week": 0.0,
                    "entries_count": 0
                }
            return {
                "start_weight_kg": 0.0,
                "current_weight_kg": 0.0,
                "goal_weight_kg": 0.0,
                "total_change_kg": 0.0,
                "trend_kg_per_week": 0.0,
                "entries_count": 0
            }

        first_entry = await self.get_first_weight(user_id)
        latest_entry = await self.get_latest_weight(user_id)
        
        goal_stmt = select(UserGoal).filter(UserGoal.user_id == user_id)
        goal_res = await self.db.execute(goal_stmt)
        goal = goal_res.scalars().first()
        goal_weight = goal.target_weight_kg if goal else 0.0

        start_w = first_entry.weight_kg
        curr_w = latest_entry.weight_kg
        total_change = curr_w - start_w

        # Weekly trend (slope of start vs latest)
        trend = 0.0
        time_diff = latest_entry.logged_at - first_entry.logged_at
        days = time_diff.days
        if days >= 7:
            weeks = days / 7.0
            trend = total_change / weeks
        elif days > 0:
            # Fallback for less than a week
            trend = total_change

        return {
            "start_weight_kg": start_w,
            "current_weight_kg": curr_w,
            "goal_weight_kg": goal_weight,
            "total_change_kg": round(total_change, 2),
            "trend_kg_per_week": round(trend, 2),
            "entries_count": count
        }
