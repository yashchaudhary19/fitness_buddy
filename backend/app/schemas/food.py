import uuid
from datetime import datetime, date
from typing import Optional, List, Dict
from pydantic import BaseModel, Field
from app.models.food import FoodSource, MealType

# Food Item Schemas
class FoodItemBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    brand: Optional[str] = Field(None, max_length=255)
    barcode: Optional[str] = Field(None, max_length=50)
    calories_per_100g: float = Field(..., ge=0)
    carbs_per_100g: float = Field(..., ge=0)
    protein_per_100g: float = Field(..., ge=0)
    fat_per_100g: float = Field(..., ge=0)
    fiber_per_100g: float = Field(0.0, ge=0)
    sugar_per_100g: float = Field(0.0, ge=0)
    sodium_per_100g: float = Field(0.0, ge=0)
    saturated_fat_per_100g: float = Field(0.0, ge=0)
    image_url: Optional[str] = None

class FoodItemCreate(FoodItemBase):
    pass

class FoodItemResponse(FoodItemBase):
    id: uuid.UUID
    source: FoodSource
    created_by: Optional[uuid.UUID] = None
    created_at: datetime

    class Config:
        from_attributes = True

# Food Log Entry Schemas
class FoodLogEntryCreate(BaseModel):
    food_item_id: uuid.UUID
    meal_type: MealType
    serving_size_g: float = Field(..., gt=0)
    log_date: date

class FoodLogEntryUpdate(BaseModel):
    serving_size_g: Optional[float] = Field(None, gt=0)
    meal_type: Optional[MealType] = None

class FoodLogEntryResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    food_item_id: uuid.UUID
    meal_type: MealType
    serving_size_g: float
    calories: float
    carbs_g: float
    protein_g: float
    fat_g: float
    fiber_g: float
    log_date: date
    logged_at: datetime
    food_item: FoodItemResponse

    class Config:
        from_attributes = True

# Diary Summary & Groups Schemas
class DiarySummaryResponse(BaseModel):
    calories_consumed: float
    calories_goal: float
    calories_remaining: float
    carbs_consumed: float
    carbs_goal: float
    protein_consumed: float
    protein_goal: float
    fat_consumed: float
    fat_goal: float
    fiber_consumed: float
    fiber_goal: float
    water_consumed: float
    water_goal: float
    exercise_calories_burned: float
    net_calories: float

class MealSection(BaseModel):
    entries: List[FoodLogEntryResponse]
    total_calories: float
    total_carbs: float
    total_protein: float
    total_fat: float

class DiaryResponse(BaseModel):
    date: date
    meals: Dict[MealType, MealSection]
    daily_totals: Dict[str, float]
    remaining_calories: float
