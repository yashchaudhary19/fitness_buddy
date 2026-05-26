from datetime import date
import uuid
from typing import Dict, List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api import deps
from app.core.database import get_db
from app.models.user import User
from app.models.food import MealType
from app.repositories.food import FoodItemRepository, FoodLogEntryRepository
from app.repositories.goal import GoalRepository
from app.repositories.water import WaterLogRepository
from app.repositories.exercise import ExerciseLogRepository
from app.schemas.base import ResponseEnvelope
from app.schemas.food import (
    FoodLogEntryCreate,
    FoodLogEntryUpdate,
    FoodLogEntryResponse,
    DiarySummaryResponse,
    DiaryResponse,
    MealSection,
)

router = APIRouter()

async def _get_user_goals_or_defaults(db: AsyncSession, user_id: uuid.UUID):
    """Retrieve user's goal targets or return standard defaults if unset."""
    goal_repo = GoalRepository(db)
    goal = await goal_repo.get_by_user_id(user_id)
    if goal:
        return {
            "calories": goal.daily_calorie_target,
            "protein": goal.daily_protein_g,
            "carbs": goal.daily_carbs_g,
            "fat": goal.daily_fat_g,
            "fiber": goal.daily_fiber_g,
            "water": goal.daily_water_ml
        }
    return {
        "calories": 2000,
        "protein": 150,
        "carbs": 250,
        "fat": 65,
        "fiber": 25,
        "water": 2000
    }

@router.get(
    "/",
    response_model=ResponseEnvelope[DiaryResponse],
    summary="Retrieve diary food log entries grouped by meal type"
)
async def get_diary_entries(
    log_date: Optional[date] = Query(None, description="Diary log date YYYY-MM-DD. Defaults to today."),
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(get_db)
):
    target_date = log_date or date.today()
    
    log_repo = FoodLogEntryRepository(db)
    water_repo = WaterLogRepository(db)
    exec_repo = ExerciseLogRepository(db)
    
    # 1. Fetch entries
    entries = await log_repo.get_entries_by_date(current_user.id, target_date)
    
    # 2. Get goals
    goals = await _get_user_goals_or_defaults(db, current_user.id)
    
    # 3. Setup grouping
    meals: Dict[MealType, MealSection] = {
        MealType.BREAKFAST: MealSection(entries=[], total_calories=0.0, total_carbs=0.0, total_protein=0.0, total_fat=0.0),
        MealType.LUNCH: MealSection(entries=[], total_calories=0.0, total_carbs=0.0, total_protein=0.0, total_fat=0.0),
        MealType.DINNER: MealSection(entries=[], total_calories=0.0, total_carbs=0.0, total_protein=0.0, total_fat=0.0),
        MealType.SNACKS: MealSection(entries=[], total_calories=0.0, total_carbs=0.0, total_protein=0.0, total_fat=0.0)
    }
    
    daily_totals = {"calories": 0.0, "carbs": 0.0, "protein": 0.0, "fat": 0.0, "fiber": 0.0}
    
    for entry in entries:
        section = meals[entry.meal_type]
        section.entries.append(FoodLogEntryResponse.model_validate(entry))
        
        section.total_calories += entry.calories
        section.total_carbs += entry.carbs_g
        section.total_protein += entry.protein_g
        section.total_fat += entry.fat_g
        
        daily_totals["calories"] += entry.calories
        daily_totals["carbs"] += entry.carbs_g
        daily_totals["protein"] += entry.protein_g
        daily_totals["fat"] += entry.fat_g
        daily_totals["fiber"] += entry.fiber_g

    # Round totals
    for s in meals.values():
        s.total_calories = round(s.total_calories, 1)
        s.total_carbs = round(s.total_carbs, 1)
        s.total_protein = round(s.total_protein, 1)
        s.total_fat = round(s.total_fat, 1)
        
    for k in daily_totals:
        daily_totals[k] = round(daily_totals[k], 1)

    # 4. Calculate remaining calories (net offset with exercise)
    exercise_burned = await exec_repo.get_daily_calories_burned(current_user.id, target_date)
    remaining = goals["calories"] - daily_totals["calories"] + exercise_burned
    
    return ResponseEnvelope(
        success=True,
        data=DiaryResponse(
            date=target_date,
            meals=meals,
            daily_totals=daily_totals,
            remaining_calories=round(remaining, 1)
        ),
        message="Diary entries retrieved successfully."
    )


@router.get(
    "/summary",
    response_model=ResponseEnvelope[DiarySummaryResponse],
    summary="Retrieve daily calorie, macros, water, and exercise summary"
)
async def get_diary_summary(
    log_date: Optional[date] = Query(None, description="Summary date YYYY-MM-DD. Defaults to today."),
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(get_db)
):
    target_date = log_date or date.today()
    
    log_repo = FoodLogEntryRepository(db)
    water_repo = WaterLogRepository(db)
    exec_repo = ExerciseLogRepository(db)
    
    # 1. Fetch calorie/macro consumed
    consumed = await log_repo.get_daily_macro_totals(current_user.id, target_date)
    
    # 2. Fetch water logged
    water_consumed = await water_repo.get_daily_total(current_user.id, target_date)
    
    # 3. Fetch exercise burned
    exercise_burned = await exec_repo.get_daily_calories_burned(current_user.id, target_date)
    
    # 4. Get active goals
    goals = await _get_user_goals_or_defaults(db, current_user.id)
    
    # 5. Calculations
    cal_consumed = consumed.get("calories") or 0.0
    burned = exercise_burned or 0.0
    
    net_calories = cal_consumed - burned
    remaining = goals["calories"] - net_calories
    
    summary = DiarySummaryResponse(
        calories_consumed=round(cal_consumed, 1),
        calories_goal=float(goals["calories"]),
        calories_remaining=round(remaining, 1),
        carbs_consumed=round(consumed.get("carbs") or 0.0, 1),
        carbs_goal=float(goals["carbs"]),
        protein_consumed=round(consumed.get("protein") or 0.0, 1),
        protein_goal=float(goals["protein"]),
        fat_consumed=round(consumed.get("fat") or 0.0, 1),
        fat_goal=float(goals["fat"]),
        fiber_consumed=round(consumed.get("fiber") or 0.0, 1),
        fiber_goal=float(goals["fiber"]),
        water_consumed=float(water_consumed or 0.0),
        water_goal=float(goals["water"]),
        exercise_calories_burned=round(burned, 1),
        net_calories=round(net_calories, 1)
    )
    
    return ResponseEnvelope(
        success=True,
        data=summary,
        message="Daily diary summary retrieved successfully."
    )


@router.post(
    "/entries",
    response_model=ResponseEnvelope[FoodLogEntryResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Log a food item entry"
)
async def create_diary_entry(
    schema: FoodLogEntryCreate,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(get_db)
):
    food_repo = FoodItemRepository(db)
    log_repo = FoodLogEntryRepository(db)
    
    food_item = await food_repo.get(schema.food_item_id)
    if not food_item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Food item not found."
        )
        
    new_entry = await log_repo.create_log_entry(
        user_id=current_user.id,
        food_item=food_item,
        meal_type=schema.meal_type,
        serving_size_g=schema.serving_size_g,
        log_date=schema.log_date
    )
    await db.commit()
    
    # Refresh to load food relation for response serialization
    await db.refresh(new_entry)
    
    return ResponseEnvelope(
        success=True,
        data=FoodLogEntryResponse.model_validate(new_entry),
        message="Food item logged successfully."
    )


@router.put(
    "/entries/{id}",
    response_model=ResponseEnvelope[FoodLogEntryResponse],
    summary="Update logged food item entry details"
)
async def update_diary_entry(
    id: uuid.UUID,
    schema: FoodLogEntryUpdate,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(get_db)
):
    log_repo = FoodLogEntryRepository(db)
    
    db_entry = await log_repo.get(id)
    if not db_entry or db_entry.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Logged entry not found."
        )
        
    update_data = schema.model_dump(exclude_unset=True)
    if not update_data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No updates specified."
        )

    await log_repo.update_log_entry(db_entry, update_data)
    await db.commit()
    await db.refresh(db_entry)
    
    return ResponseEnvelope(
        success=True,
        data=FoodLogEntryResponse.model_validate(db_entry),
        message="Logged entry updated successfully."
    )


@router.delete(
    "/entries/{id}",
    response_model=ResponseEnvelope[dict],
    summary="Delete logged food item entry"
)
async def delete_diary_entry(
    id: uuid.UUID,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(get_db)
):
    log_repo = FoodLogEntryRepository(db)
    
    db_entry = await log_repo.get(id)
    if not db_entry or db_entry.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Logged entry not found."
        )
        
    await log_repo.remove(id)
    await db.commit()
    
    return ResponseEnvelope(
        success=True,
        data={},
        message="Logged entry deleted successfully."
    )
