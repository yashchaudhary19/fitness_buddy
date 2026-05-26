import uuid
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field

class WeightEntryCreate(BaseModel):
    weight_kg: float = Field(..., gt=0.0)
    note: Optional[str] = Field(None, max_length=500)
    logged_at: Optional[datetime] = None

class WeightEntryResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    weight_kg: float
    note: Optional[str] = None
    logged_at: datetime

    class Config:
        from_attributes = True

class WeightStatsResponse(BaseModel):
    start_weight_kg: float
    current_weight_kg: float
    goal_weight_kg: float
    total_change_kg: float
    trend_kg_per_week: float
    entries_count: int
