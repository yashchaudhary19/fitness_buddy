import uuid
from datetime import datetime, date
from typing import Optional, List
from pydantic import BaseModel, Field

# Measurements
class BodyMeasurementCreate(BaseModel):
    waist_cm: Optional[float] = Field(None, ge=0.0)
    chest_cm: Optional[float] = Field(None, ge=0.0)
    hips_cm: Optional[float] = Field(None, ge=0.0)
    left_arm_cm: Optional[float] = Field(None, ge=0.0)
    right_arm_cm: Optional[float] = Field(None, ge=0.0)
    left_thigh_cm: Optional[float] = Field(None, ge=0.0)
    right_thigh_cm: Optional[float] = Field(None, ge=0.0)

class BodyMeasurementResponse(BodyMeasurementCreate):
    id: uuid.UUID
    user_id: uuid.UUID
    logged_at: datetime

    class Config:
        from_attributes = True

# Streak
class StreakResponse(BaseModel):
    current_streak: int
    longest_streak: int
    last_logged_date: Optional[date] = None

# Charts and Timelines
class CalorieProgressPoint(BaseModel):
    date: date
    calories_consumed: float
    calories_goal: float
    calories_burned: float

class MacroProgressPoint(BaseModel):
    date: date
    carbs_g: float
    protein_g: float
    fat_g: float

class MacroProgressResponse(BaseModel):
    timeline: List[MacroProgressPoint]
    average_carbs_g: float
    average_protein_g: float
    average_fat_g: float

class WeightProgressPoint(BaseModel):
    date: date
    weight_kg: float
    moving_average_7d: float
