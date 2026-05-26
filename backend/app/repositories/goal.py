import uuid
from typing import Optional, Dict, Any
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.goal import UserGoal, GoalType, Gender, ActivityLevel
from app.repositories.base import BaseRepository

class GoalRepository(BaseRepository[UserGoal]):
    def __init__(self, db: AsyncSession):
        super().__init__(UserGoal, db)

    async def get_by_user_id(self, user_id: uuid.UUID) -> Optional[UserGoal]:
        """Fetch the goal profile of a specific user."""
        result = await self.db.execute(select(UserGoal).filter(UserGoal.user_id == user_id))
        return result.scalars().first()

    def calculate_targets(
        self,
        weight: float,
        height: float,
        age: int,
        gender: Gender,
        activity_level: ActivityLevel,
        goal_type: GoalType,
        weekly_pace: float
    ) -> Dict[str, int]:
        """
        Calculate BMR, TDEE, calories target, macro distribution, and daily water needs.
        Formulas:
          - Mifflin-St Jeor BMR
          - TDEE Activity Multipliers
          - 2.0g/kg Protein, 25% Fat, Remainder Carbs
        """
        # BMR
        if gender == Gender.MALE:
            bmr = (10.0 * weight) + (6.25 * height) - (5.0 * age) + 5.0
        elif gender == Gender.FEMALE:
            bmr = (10.0 * weight) + (6.25 * height) - (5.0 * age) - 161.0
        else:
            # Other/Non-binary average constant
            bmr = (10.0 * weight) + (6.25 * height) - (5.0 * age) - 78.0

        # TDEE
        multipliers = {
            ActivityLevel.SEDENTARY: 1.2,
            ActivityLevel.LIGHT: 1.375,
            ActivityLevel.MODERATE: 1.55,
            ActivityLevel.ACTIVE: 1.725,
            ActivityLevel.VERY_ACTIVE: 1.9,
        }
        multiplier = multipliers.get(activity_level, 1.2)
        tdee = bmr * multiplier

        # Calorie Adjustments
        # 1 kg of body fat is roughly 7700 kcal
        calorie_pace = weekly_pace * 7700.0 / 7.0
        
        if goal_type == GoalType.LOSE:
            calories = tdee - calorie_pace
        elif goal_type == GoalType.GAIN:
            calories = tdee + calorie_pace
        else:
            calories = tdee

        # Safety minimum limits
        min_calories = 1200 if gender == Gender.FEMALE else 1500
        if calories < min_calories:
            calories = min_calories
        
        daily_calories = int(round(calories))

        # Macro Splits
        # Protein: 2.0g per kg of bodyweight (4 kcal per gram)
        protein_g = int(round(2.0 * weight))
        protein_kcal = protein_g * 4

        # Fat: 25% of daily calories (9 kcal per gram)
        fat_kcal = daily_calories * 0.25
        fat_g = int(round(fat_kcal / 9.0))
        fat_kcal_actual = fat_g * 9

        # Carbs: Remaining calories (4 kcal per gram)
        remaining_kcal = daily_calories - (protein_kcal + fat_kcal_actual)
        carbs_g = int(round(remaining_kcal / 4.0))
        if carbs_g < 0:
            carbs_g = 0

        # Fiber
        fiber_g = 25

        # Water: 35ml per kg of bodyweight
        water_ml = int(round(35.0 * weight))

        return {
            "daily_calorie_target": daily_calories,
            "daily_protein_g": protein_g,
            "daily_carbs_g": carbs_g,
            "daily_fat_g": fat_g,
            "daily_fiber_g": fiber_g,
            "daily_water_ml": water_ml
        }

    async def create_or_update(self, user_id: uuid.UUID, goal_data: Dict[str, Any]) -> UserGoal:
        """Create or update goal configurations for a user, recalculating targets."""
        calculated = self.calculate_targets(
            weight=goal_data["current_weight_kg"],
            height=goal_data["height_cm"],
            age=goal_data["age"],
            gender=goal_data["gender"],
            activity_level=goal_data["activity_level"],
            goal_type=goal_data["goal_type"],
            weekly_pace=goal_data.get("weekly_pace_kg", 0.5)
        )
        
        full_data = {**goal_data, **calculated, "user_id": user_id}
        
        existing = await self.get_by_user_id(user_id)
        if existing:
            return await self.update(existing, full_data)
        
        new_goal = UserGoal(**full_data)
        return await self.create(new_goal)
