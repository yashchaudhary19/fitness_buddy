import uuid
from datetime import datetime, date
from typing import List
from pydantic import BaseModel, Field

class WaterLogCreate(BaseModel):
    amount_ml: int = Field(..., gt=0)
    log_date: date

class WaterLogResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    amount_ml: int
    log_date: date
    logged_at: datetime

    class Config:
        from_attributes = True

class WaterResponse(BaseModel):
    entries: List[WaterLogResponse]
    daily_total_ml: int
    goal_ml: int
