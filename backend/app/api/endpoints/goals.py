from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api import deps
from app.core.database import get_db
from app.models.user import User
from app.repositories.goal import GoalRepository
from app.schemas.base import ResponseEnvelope
from app.schemas.goal import UserGoalCreate, UserGoalResponse

router = APIRouter()

@router.get(
    "/",
    response_model=ResponseEnvelope[UserGoalResponse],
    summary="Retrieve current user goal profiles"
)
async def get_user_goal(
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(get_db)
):
    goal_repo = GoalRepository(db)
    goal = await goal_repo.get_by_user_id(current_user.id)
    
    if not goal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Goal profile not set. Please complete onboarding."
        )
        
    return ResponseEnvelope(
        success=True,
        data=UserGoalResponse.model_validate(goal),
        message="Goal profile retrieved successfully."
    )


@router.post(
    "/",
    response_model=ResponseEnvelope[UserGoalResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Create or update user goal profiles"
)
async def create_or_update_goal(
    schema: UserGoalCreate,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(get_db)
):
    goal_repo = GoalRepository(db)
    goal_data = schema.model_dump()
    
    goal = await goal_repo.create_or_update(current_user.id, goal_data)
    await db.commit()
    
    return ResponseEnvelope(
        success=True,
        data=UserGoalResponse.model_validate(goal),
        message="Goal profile updated and targets recalculated successfully."
    )


@router.put(
    "/",
    response_model=ResponseEnvelope[UserGoalResponse],
    summary="Update user goal profiles"
)
async def update_goal(
    schema: UserGoalCreate,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(get_db)
):
    # Map PUT directly to create_or_update logic
    return await create_or_update_goal(schema, current_user, db)
