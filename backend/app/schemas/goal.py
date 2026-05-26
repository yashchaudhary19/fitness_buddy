import uuid
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field
from app.models.goal import GoalType, Gender, ActivityLevel

class UserGoalBase(BaseModel):
    goal_type: GoalType
    current_weight_kg: float = Field(..., gt=0)
    target_weight_kg: float = Field(..., gt=0)
    height_cm: float = Field(..., gt=0)
    age: int = Field(..., gt=0, lt=150)
    gender: Gender
    activity_level: ActivityLevel
    weekly_pace_kg: float = Field(0.5, ge=0.0, le=2.0)

class UserGoalCreate(UserGoalBase):
    pass

class UserGoalUpdate(UserGoalBase):
    pass

class UserGoalResponse(UserGoalBase):
    id: uuid.UUID
    user_id: uuid.UUID
    daily_calorie_target: int
    daily_protein_g: int
    daily_carbs_g: int
    daily_fat_g: int
    daily_fiber_g: int
    daily_water_ml: int
    updated_at: datetime

    class Config:
        from_attributes = True
