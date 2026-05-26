from datetime import datetime, timezone
import uuid
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api import deps
from app.core.database import get_db
from app.models.user import User
from app.models.weight import WeightEntry
from app.repositories.weight import WeightEntryRepository
from app.schemas.base import ResponseEnvelope
from app.schemas.weight import WeightEntryCreate, WeightEntryResponse, WeightStatsResponse

router = APIRouter()

@router.get(
    "/",
    response_model=ResponseEnvelope[List[WeightEntryResponse]],
    summary="Retrieve weight history logs"
)
async def get_weight_entries(
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(get_db)
):
    weight_repo = WeightEntryRepository(db)
    entries = await weight_repo.get_by_user_id(current_user.id)
    
    return ResponseEnvelope(
        success=True,
        data=[WeightEntryResponse.model_validate(e) for e in entries],
        message="Weight log history retrieved successfully."
    )


@router.post(
    "/",
    response_model=ResponseEnvelope[WeightEntryResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Log a new weight entry"
)
async def create_weight_entry(
    schema: WeightEntryCreate,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(get_db)
):
    weight_repo = WeightEntryRepository(db)
    
    logged_at = schema.logged_at or datetime.now(timezone.utc).replace(tzinfo=None)
    
    db_obj = WeightEntry(
        user_id=current_user.id,
        weight_kg=schema.weight_kg,
        note=schema.note,
        logged_at=logged_at
    )
    
    await weight_repo.create(db_obj)
    await db.commit()
    await db.refresh(db_obj)
    
    return ResponseEnvelope(
        success=True,
        data=WeightEntryResponse.model_validate(db_obj),
        message="Weight logged successfully."
    )


@router.get(
    "/stats",
    response_model=ResponseEnvelope[WeightStatsResponse],
    summary="Retrieve user weight progress statistics"
)
async def get_weight_stats(
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(get_db)
):
    weight_repo = WeightEntryRepository(db)
    stats = await weight_repo.get_weight_stats(current_user.id)
    
    return ResponseEnvelope(
        success=True,
        data=WeightStatsResponse(**stats),
        message="Weight statistics calculated successfully."
    )


@router.delete(
    "/{id}",
    response_model=ResponseEnvelope[dict],
    summary="Delete a weight entry"
)
async def delete_weight_entry(
    id: uuid.UUID,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(get_db)
):
    weight_repo = WeightEntryRepository(db)
    
    db_obj = await weight_repo.get(id)
    if not db_obj or db_obj.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Weight entry not found."
        )
        
    await weight_repo.remove(id)
    await db.commit()
    
    return ResponseEnvelope(
        success=True,
        data={},
        message="Weight entry deleted successfully."
    )
