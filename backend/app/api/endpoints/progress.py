from datetime import date, datetime, timedelta, timezone
import uuid
from typing import List, Dict, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select, and_, func, cast, Date
from sqlalchemy.ext.asyncio import AsyncSession

from app.api import deps
from app.core.database import get_db
from app.models.user import User
from app.models.food import FoodLogEntry
from app.models.exercise import ExerciseLog
from app.models.weight import WeightEntry
from app.models.measurement import BodyMeasurement
from app.repositories.progress import BodyMeasurementRepository, StreakRepository
from app.repositories.goal import GoalRepository
from app.schemas.base import ResponseEnvelope
from app.schemas.progress import (
    BodyMeasurementCreate,
    BodyMeasurementResponse,
    StreakResponse,
    CalorieProgressPoint,
    MacroProgressPoint,
    MacroProgressResponse,
    WeightProgressPoint,
)

router = APIRouter()

@router.get(
    "/streak",
    response_model=ResponseEnvelope[StreakResponse],
    summary="Retrieve user activity login streak stats"
)
async def get_streak(
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(get_db)
):
    streak_repo = StreakRepository(db)
    stats = await streak_repo.get_streak_stats(current_user.id)
    
    return ResponseEnvelope(
        success=True,
        data=StreakResponse(**stats),
        message="Logging streak calculated successfully."
    )


@router.get(
    "/measurements",
    response_model=ResponseEnvelope[List[BodyMeasurementResponse]],
    summary="Retrieve body tape measurement log history"
)
async def get_measurements(
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(get_db)
):
    measure_repo = BodyMeasurementRepository(db)
    history = await measure_repo.get_history(current_user.id)
    
    return ResponseEnvelope(
        success=True,
        data=[BodyMeasurementResponse.model_validate(m) for m in history],
        message="Body measurements history retrieved successfully."
    )


@router.post(
    "/measurements",
    response_model=ResponseEnvelope[BodyMeasurementResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Log a new body tape measurement"
)
async def log_measurement(
    schema: BodyMeasurementCreate,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(get_db)
):
    measure_repo = BodyMeasurementRepository(db)
    
    db_obj = BodyMeasurement(
        user_id=current_user.id,
        waist_cm=schema.waist_cm,
        chest_cm=schema.chest_cm,
        hips_cm=schema.hips_cm,
        left_arm_cm=schema.left_arm_cm,
        right_arm_cm=schema.right_arm_cm,
        left_thigh_cm=schema.left_thigh_cm,
        right_thigh_cm=schema.right_thigh_cm
    )
    
    await measure_repo.create(db_obj)
    await db.commit()
    await db.refresh(db_obj)
    
    return ResponseEnvelope(
        success=True,
        data=BodyMeasurementResponse.model_validate(db_obj),
        message="Body measurements logged successfully."
    )


@router.get(
    "/calories-timeline",
    response_model=ResponseEnvelope[List[CalorieProgressPoint]],
    summary="Retrieve daily calorie totals for charting"
)
async def get_calories_timeline(
    days: int = Query(7, ge=1, le=90, description="Number of historical days to pull."),
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(get_db)
):
    end_date = date.today()
    start_date = end_date - timedelta(days=days - 1)
    
    # 1. Fetch calorie goal
    goal_repo = GoalRepository(db)
    goal_obj = await goal_repo.get_by_user_id(current_user.id)
    cal_goal = goal_obj.daily_calorie_target if goal_obj else 2000.0
    
    # 2. Query consumed calories grouped by date
    food_stmt = (
        select(
            FoodLogEntry.log_date,
            func.sum(FoodLogEntry.calories).label("calories")
        )
        .filter(and_(
            FoodLogEntry.user_id == current_user.id,
            FoodLogEntry.log_date >= start_date,
            FoodLogEntry.log_date <= end_date
        ))
        .group_by(FoodLogEntry.log_date)
    )
    food_res = await db.execute(food_stmt)
    food_map = {row.log_date: float(row.calories) for row in food_res.fetchall()}
    
    # 3. Query burned calories grouped by date
    exec_stmt = (
        select(
            ExerciseLog.log_date,
            func.sum(ExerciseLog.calories_burned).label("burned")
        )
        .filter(and_(
            ExerciseLog.user_id == current_user.id,
            ExerciseLog.log_date >= start_date,
            ExerciseLog.log_date <= end_date
        ))
        .group_by(ExerciseLog.log_date)
    )
    exec_res = await db.execute(exec_stmt)
    exec_map = {row.log_date: float(row.burned) for row in exec_res.fetchall()}
    
    # 4. Construct response timeline
    timeline = []
    for i in range(days):
        d = start_date + timedelta(days=i)
        timeline.append(CalorieProgressPoint(
            date=d,
            calories_consumed=round(food_map.get(d, 0.0), 1),
            calories_goal=float(cal_goal),
            calories_burned=round(exec_map.get(d, 0.0), 1)
        ))
        
    return ResponseEnvelope(
        success=True,
        data=timeline,
        message="Calorie progress timeline retrieved successfully."
    )


@router.get(
    "/macros-timeline",
    response_model=ResponseEnvelope[MacroProgressResponse],
    summary="Retrieve daily macro breakdown totals and averages for charting"
)
async def get_macros_timeline(
    days: int = Query(7, ge=1, le=90, description="Number of historical days to pull."),
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(get_db)
):
    end_date = date.today()
    start_date = end_date - timedelta(days=days - 1)
    
    # Query daily macro totals
    stmt = (
        select(
            FoodLogEntry.log_date,
            func.sum(FoodLogEntry.carbs_g).label("carbs"),
            func.sum(FoodLogEntry.protein_g).label("protein"),
            func.sum(FoodLogEntry.fat_g).label("fat")
        )
        .filter(and_(
            FoodLogEntry.user_id == current_user.id,
            FoodLogEntry.log_date >= start_date,
            FoodLogEntry.log_date <= end_date
        ))
        .group_by(FoodLogEntry.log_date)
    )
    res = await db.execute(stmt)
    
    macro_map = {
        row.log_date: (float(row.carbs), float(row.protein), float(row.fat)) 
        for row in res.fetchall()
    }
    
    timeline = []
    total_carbs = 0.0
    total_protein = 0.0
    total_fat = 0.0
    logged_days_count = 0
    
    for i in range(days):
        d = start_date + timedelta(days=i)
        carbs, protein, fat = macro_map.get(d, (0.0, 0.0, 0.0))
        
        timeline.append(MacroProgressPoint(
            date=d,
            carbs_g=round(carbs, 1),
            protein_g=round(protein, 1),
            fat_g=round(fat, 1)
        ))
        
        if (carbs + protein + fat) > 0.0:
            total_carbs += carbs
            total_protein += protein
            total_fat += fat
            logged_days_count += 1
            
    avg_carbs = total_carbs / logged_days_count if logged_days_count > 0 else 0.0
    avg_protein = total_protein / logged_days_count if logged_days_count > 0 else 0.0
    avg_fat = total_fat / logged_days_count if logged_days_count > 0 else 0.0
    
    return ResponseEnvelope(
        success=True,
        data=MacroProgressResponse(
            timeline=timeline,
            average_carbs_g=round(avg_carbs, 1),
            average_protein_g=round(avg_protein, 1),
            average_fat_g=round(avg_fat, 1)
        ),
        message="Macros progress timeline retrieved successfully."
    )


@router.get(
    "/weight-timeline",
    response_model=ResponseEnvelope[List[WeightProgressPoint]],
    summary="Retrieve daily weight log history and 7d moving average for charting"
)
async def get_weight_timeline(
    days: int = Query(7, ge=1, le=90, description="Number of historical days to pull."),
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(get_db)
):
    end_date = date.today()
    start_date = end_date - timedelta(days=days - 1)
    
    # 1. Fetch user goal initial weight for fallback carry-forward
    goal_repo = GoalRepository(db)
    goal_obj = await goal_repo.get_by_user_id(current_user.id)
    fallback_w = goal_obj.current_weight_kg if goal_obj else 70.0
    
    # 2. Query all weight entries up to end_date to carry forward properly
    stmt = (
        select(WeightEntry)
        .filter(and_(
            WeightEntry.user_id == current_user.id,
            cast(WeightEntry.logged_at, Date) <= end_date
        ))
        .order_by(WeightEntry.logged_at.asc())
    )
    res = await db.execute(stmt)
    entries = res.scalars().all()
    
    # Map entries by date (taking the latest entry if multiple logged in one day)
    weight_by_date = {}
    for entry in entries:
        entry_date = entry.logged_at.date()
        weight_by_date[entry_date] = entry.weight_kg
        
    # 3. Create a continuous timeline of daily weights (carry forward if missing)
    continuous_weights: Dict[date, float] = {}
    last_weight = fallback_w
    
    # Scan chronologically to populate the continuous timeline
    # We start 7 days prior to start_date to enable 7d moving average for day 1!
    extended_start = start_date - timedelta(days=7)
    
    # Find any weight before extended_start to seed the carry-forward
    pre_entries = [w for w in entries if w.logged_at.date() < extended_start]
    if pre_entries:
        last_weight = pre_entries[-1].weight_kg
        
    current_scan_date = extended_start
    while current_scan_date <= end_date:
        if current_scan_date in weight_by_date:
            last_weight = weight_by_date[current_scan_date]
        continuous_weights[current_scan_date] = last_weight
        current_scan_date += timedelta(days=1)
        
    # 4. Construct final timeline points with 7-day moving averages
    timeline = []
    for i in range(days):
        d = start_date + timedelta(days=i)
        
        # Calculate moving average (average of d-6 to d)
        seven_day_sum = 0.0
        for offset in range(7):
            sd = d - timedelta(days=offset)
            seven_day_sum += continuous_weights.get(sd, last_weight)
        moving_avg = seven_day_sum / 7.0
        
        timeline.append(WeightProgressPoint(
            date=d,
            weight_kg=round(continuous_weights.get(d, last_weight), 2),
            moving_average_7d=round(moving_avg, 2)
        ))
        
    return ResponseEnvelope(
        success=True,
        data=timeline,
        message="Weight progress timeline retrieved successfully."
    )
