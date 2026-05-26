import uuid
from datetime import datetime, date
from typing import Optional, List
from pydantic import BaseModel, Field
from app.models.exercise import ExerciseType

class ExerciseSetCreate(BaseModel):
    set_number: int = Field(..., ge=1)
    reps: Optional[int] = Field(None, ge=0)
    weight_kg: Optional[float] = Field(None, ge=0.0)

class ExerciseSetResponse(BaseModel):
    id: uuid.UUID
    exercise_log_id: uuid.UUID
    set_number: int
    reps: Optional[int] = None
    weight_kg: Optional[float] = None
    completed: bool

    class Config:
        from_attributes = True

class ExerciseLogCreate(BaseModel):
    exercise_name: str = Field(..., min_length=1, max_length=255)
    exercise_type: ExerciseType
    duration_minutes: Optional[int] = Field(None, ge=0)
    calories_burned: float = Field(..., ge=0.0)
    notes: Optional[str] = Field(None, max_length=1000)
    sets: Optional[List[ExerciseSetCreate]] = None
    log_date: date

class ExerciseLogResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    exercise_name: str
    exercise_type: ExerciseType
    duration_minutes: Optional[int] = None
    calories_burned: float
    notes: Optional[str] = None
    log_date: date
    logged_at: datetime
    sets: List[ExerciseSetResponse]

    class Config:
        from_attributes = True

# Static Exercise Schema
class ExerciseLibraryItem(BaseModel):
    name: str
    type: ExerciseType
    met: Optional[float] = None  # For cardio
    muscle_group: Optional[str] = None  # For strength
