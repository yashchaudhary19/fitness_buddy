from datetime import date
import uuid
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api import deps
from app.core.database import get_db
from app.models.user import User
from app.models.water import WaterLog
from app.repositories.water import WaterLogRepository
from app.repositories.goal import GoalRepository
from app.schemas.base import ResponseEnvelope
from app.schemas.water import WaterLogCreate, WaterLogResponse, WaterResponse

router = APIRouter()

@router.get(
    "/",
    response_model=ResponseEnvelope[WaterResponse],
    summary="Retrieve daily water consumption logs"
)
async def get_water_logs(
    log_date: Optional[date] = Query(None, description="Logs date YYYY-MM-DD. Defaults to today."),
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(get_db)
):
    target_date = log_date or date.today()
    
    water_repo = WaterLogRepository(db)
    goal_repo = GoalRepository(db)
    
    # 1. Get entries
    entries = await water_repo.get_logs_by_date(current_user.id, target_date)
    
    # 2. Get total volume
    total = await water_repo.get_daily_total(current_user.id, target_date)
    
    # 3. Get user goal
    goal = await goal_repo.get_by_user_id(current_user.id)
    goal_ml = goal.daily_water_ml if goal else 2000 # default fallback
    
    return ResponseEnvelope(
        success=True,
        data=WaterResponse(
            entries=[WaterLogResponse.model_validate(e) for e in entries],
            daily_total_ml=total,
            goal_ml=goal_ml
        ),
        message="Water logs retrieved successfully."
    )


@router.post(
    "/",
    response_model=ResponseEnvelope[WaterLogResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Log water consumption"
)
async def create_water_log(
    schema: WaterLogCreate,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(get_db)
):
    water_repo = WaterLogRepository(db)
    
    db_obj = WaterLog(
        user_id=current_user.id,
        amount_ml=schema.amount_ml,
        log_date=schema.log_date
    )
    
    await water_repo.create(db_obj)
    await db.commit()
    await db.refresh(db_obj)
    
    return ResponseEnvelope(
        success=True,
        data=WaterLogResponse.model_validate(db_obj),
        message="Water logged successfully."
    )


@router.delete(
    "/{id}",
    response_model=ResponseEnvelope[dict],
    summary="Delete a water intake log entry"
)
async def delete_water_log(
    id: uuid.UUID,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(get_db)
):
    water_repo = WaterLogRepository(db)
    
    db_obj = await water_repo.get(id)
    if not db_obj or db_obj.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Water log entry not found."
        )
        
    await water_repo.remove(id)
    await db.commit()
    
    return ResponseEnvelope(
        success=True,
        data={},
        message="Water log entry deleted successfully."
    )
