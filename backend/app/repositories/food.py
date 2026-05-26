import uuid
from datetime import date
from typing import List, Optional, Dict, Any
from sqlalchemy import select, or_, and_, func
from sqlalchemy.orm import joinedload
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.food import FoodItem, FoodLogEntry, FoodSource, MealType
from app.repositories.base import BaseRepository

class FoodItemRepository(BaseRepository[FoodItem]):
    def __init__(self, db: AsyncSession):
        super().__init__(FoodItem, db)

    async def get_by_barcode(self, barcode: str) -> Optional[FoodItem]:
        """Fetch food item by barcode."""
        result = await self.db.execute(select(FoodItem).filter(FoodItem.barcode == barcode))
        return result.scalars().first()

    async def search_foods(self, query: str, user_id: Optional[uuid.UUID] = None) -> List[FoodItem]:
        """
        Search food database by name or brand.
        Returns matches that are public (created_by is null) OR created by the requesting user.
        """
        search_filter = or_(
            FoodItem.name.ilike(f"%{query}%"),
            FoodItem.brand.ilike(f"%{query}%")
        )
        
        user_filter = or_(
            FoodItem.created_by == None,
            FoodItem.created_by == user_id if user_id else False
        )
        
        stmt = select(FoodItem).filter(and_(search_filter, user_filter)).limit(50)
        result = await self.db.execute(stmt)
        return list(result.scalars().all())


class FoodLogEntryRepository(BaseRepository[FoodLogEntry]):
    def __init__(self, db: AsyncSession):
        super().__init__(FoodLogEntry, db)

    async def get_entries_by_date(self, user_id: uuid.UUID, log_date: date) -> List[FoodLogEntry]:
        """Fetch all food logs logged by a user on a given date."""
        stmt = (
            select(FoodLogEntry)
            .filter(and_(FoodLogEntry.user_id == user_id, FoodLogEntry.log_date == log_date))
            .options(joinedload(FoodLogEntry.food_item))
        )
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def create_log_entry(
        self,
        user_id: uuid.UUID,
        food_item: FoodItem,
        meal_type: MealType,
        serving_size_g: float,
        log_date: date
    ) -> FoodLogEntry:
        """Create a food log entry, scaling calories and macros based on serving size."""
        factor = serving_size_g / 100.0
        
        db_obj = FoodLogEntry(
            user_id=user_id,
            food_item=food_item,  # Use the relationship object directly
            meal_type=meal_type,
            serving_size_g=serving_size_g,
            calories=food_item.calories_per_100g * factor,
            carbs_g=food_item.carbs_per_100g * factor,
            protein_g=food_item.protein_per_100g * factor,
            fat_g=food_item.fat_per_100g * factor,
            fiber_g=food_item.fiber_per_100g * factor,
            log_date=log_date
        )
        
        return await self.create(db_obj)

    async def update_log_entry(
        self,
        db_obj: FoodLogEntry,
        update_data: Dict[str, Any]
    ) -> FoodLogEntry:
        """Update a food log entry and recalculate scaled calories/macros if serving size changes."""
        # If serving size is updated, recalculate based on associated food item
        if "serving_size_g" in update_data and update_data["serving_size_g"] != db_obj.serving_size_g:
            new_size = update_data["serving_size_g"]
            factor = new_size / 100.0
            
            # Ensure food_item is loaded
            food_item = db_obj.food_item
            
            update_data["calories"] = food_item.calories_per_100g * factor
            update_data["carbs_g"] = food_item.carbs_per_100g * factor
            update_data["protein_g"] = food_item.protein_per_100g * factor
            update_data["fat_g"] = food_item.fat_per_100g * factor
            update_data["fiber_g"] = food_item.fiber_per_100g * factor
            
        return await self.update(db_obj, update_data)

    async def get_daily_macro_totals(self, user_id: uuid.UUID, log_date: date) -> Dict[str, float]:
        """Sum total macros consumed by user on a given date."""
        stmt = (
            select(
                func.sum(FoodLogEntry.calories).label("calories"),
                func.sum(FoodLogEntry.carbs_g).label("carbs"),
                func.sum(FoodLogEntry.protein_g).label("protein"),
                func.sum(FoodLogEntry.fat_g).label("fat"),
                func.sum(FoodLogEntry.fiber_g).label("fiber")
            )
            .filter(and_(FoodLogEntry.user_id == user_id, FoodLogEntry.log_date == log_date))
        )
        
        result = await self.db.execute(stmt)
        row = result.fetchone()
        
        if not row or row.calories is None:
            return {
                "calories": 0.0,
                "carbs": 0.0,
                "protein": 0.0,
                "fat": 0.0,
                "fiber": 0.0
            }
        
        return {
            "calories": float(row.calories),
            "carbs": float(row.carbs),
            "protein": float(row.protein),
            "fat": float(row.fat),
            "fiber": float(row.fiber)
        }
