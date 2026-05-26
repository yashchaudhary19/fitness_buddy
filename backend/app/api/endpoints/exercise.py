from datetime import date
import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api import deps
from app.core.database import get_db
from app.core.exercise_library import EXERCISE_LIBRARY
from app.models.user import User
from app.repositories.exercise import ExerciseLogRepository
from app.schemas.base import ResponseEnvelope
from app.schemas.exercise import ExerciseLogCreate, ExerciseLogResponse, ExerciseLibraryItem

router = APIRouter()

@router.get(
    "/",
    response_model=ResponseEnvelope[List[ExerciseLogResponse]],
    summary="Retrieve daily exercise logs"
)
async def get_exercise_logs(
    log_date: Optional[date] = Query(None, description="Log date YYYY-MM-DD. Defaults to today."),
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(get_db)
):
    target_date = log_date or date.today()
    exec_repo = ExerciseLogRepository(db)
    
    logs = await exec_repo.get_logs_by_date(current_user.id, target_date)
    return ResponseEnvelope(
        success=True,
        data=[ExerciseLogResponse.model_validate(l) for l in logs],
        message="Daily exercise logs retrieved successfully."
    )


@router.post(
    "/",
    response_model=ResponseEnvelope[ExerciseLogResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Log an exercise workout entry"
)
async def create_exercise_log(
    schema: ExerciseLogCreate,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(get_db)
):
    exec_repo = ExerciseLogRepository(db)
    
    log_data = schema.model_dump(exclude={"sets"})
    sets_data = [s.model_dump() for s in schema.sets] if schema.sets else []
    
    new_log = await exec_repo.create_log_with_sets(
        user_id=current_user.id,
        log_data=log_data,
        sets_data=sets_data
    )
    await db.commit()
    
    return ResponseEnvelope(
        success=True,
        data=ExerciseLogResponse.model_validate(new_log),
        message="Workout logged successfully."
    )


@router.delete(
    "/{id}",
    response_model=ResponseEnvelope[dict],
    summary="Delete a logged exercise workout"
)
async def delete_exercise_log(
    id: uuid.UUID,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(get_db)
):
    exec_repo = ExerciseLogRepository(db)
    
    db_obj = await exec_repo.get(id)
    if not db_obj or db_obj.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Exercise log not found."
        )
        
    await exec_repo.remove(id)
    await db.commit()
    
    return ResponseEnvelope(
        success=True,
        data={},
        message="Workout log deleted successfully."
    )


@router.get(
    "/library",
    response_model=ResponseEnvelope[List[ExerciseLibraryItem]],
    summary="Search matching workouts in exercise library template"
)
async def search_exercise_library(
    query: Optional[str] = Query(None, description="Search term for matching exercises.")
):
    if not query or not query.strip():
        # Return entire library if no search query provided
        return ResponseEnvelope(
            success=True,
            data=[ExerciseLibraryItem(**item) for item in EXERCISE_LIBRARY],
            message="Retrieved all exercises in library."
        )
        
    search_term = query.strip().lower()
    matches = []
    
    for item in EXERCISE_LIBRARY:
        # Match name or muscle group
        name_match = search_term in item["name"].lower()
        muscle_match = (
            item["muscle_group"] is not None 
            and search_term in item["muscle_group"].lower()
        )
        
        if name_match or muscle_match:
            matches.append(ExerciseLibraryItem(**item))
            
    return ResponseEnvelope(
        success=True,
        data=matches,
        message=f"Found {len(matches)} exercise templates matching '{query}'."
    )
