from typing import List
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api import deps
from app.core.database import get_db
from app.models.user import User
from app.models.food import FoodItem, FoodSource
from app.schemas.base import ResponseEnvelope
from app.schemas.food import FoodItemCreate, FoodItemResponse
from app.services.food import FoodService
from app.repositories.food import FoodItemRepository

router = APIRouter()

@router.get(
    "/search",
    response_model=ResponseEnvelope[List[FoodItemResponse]],
    summary="Search for food items by name or brand"
)
async def search_foods(
    query: str = Query(..., min_length=1),
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(get_db)
):
    food_service = FoodService(db)
    items = await food_service.search_foods(query, current_user.id)
    
    return ResponseEnvelope(
        success=True,
        data=[FoodItemResponse.model_validate(item) for item in items],
        message=f"Found {len(items)} food items matching '{query}'."
    )


@router.get(
    "/barcode/{barcode}",
    response_model=ResponseEnvelope[FoodItemResponse],
    summary="Lookup food item by barcode"
)
async def lookup_barcode(
    barcode: str,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(get_db)
):
    food_service = FoodService(db)
    item = await food_service.lookup_barcode(barcode)
    
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product barcode not found. Please create a custom food."
        )

    return ResponseEnvelope(
        success=True,
        data=FoodItemResponse.model_validate(item),
        message="Food product found."
    )


@router.post(
    "/custom",
    response_model=ResponseEnvelope[FoodItemResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Create a custom food item"
)
async def create_custom_food(
    schema: FoodItemCreate,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(get_db)
):
    food_repo = FoodItemRepository(db)
    
    # Check if barcode already exists if provided
    if schema.barcode:
        existing = await food_repo.get_by_barcode(schema.barcode)
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Food item with barcode {schema.barcode} already exists."
            )

    food_data = schema.model_dump()
    food_data["source"] = FoodSource.CUSTOM
    food_data["created_by"] = current_user.id
    
    new_food = FoodItem(**food_data)
    await food_repo.create(new_food)
    await db.commit()
    
    return ResponseEnvelope(
        success=True,
        data=FoodItemResponse.model_validate(new_food),
        message="Custom food item created successfully."
    )
