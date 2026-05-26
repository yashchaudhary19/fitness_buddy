"""
seed_db.py — Database seeding script for NutriTrack.

Run with:
    .venv\\Scripts\\python.exe seed_db.py

Seeds the following:
  - food_items: ~200 curated common foods with USDA-based nutrition data
"""
import asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import select, func

from app.core.config import settings
from app.models.food import FoodItem, FoodSource
from app.core.food_library import FOOD_LIBRARY


async def seed_foods(session: AsyncSession):
    """Seed curated food library into DB (idempotent — skips already existing items by name)."""
    # Count existing public food items
    result = await session.execute(
        select(func.count()).select_from(FoodItem).where(FoodItem.created_by == None)
    )
    existing_count = result.scalar() or 0

    if existing_count >= len(FOOD_LIBRARY):
        print(f"[OK] Foods already seeded ({existing_count} public food items found). Skipping.")
        return

    # Fetch all existing food names for deduplication (case-insensitive)
    name_result = await session.execute(
        select(FoodItem.name).where(FoodItem.created_by == None)
    )
    existing_names = {row[0].lower() for row in name_result.fetchall()}

    added = 0
    skipped = 0
    for item in FOOD_LIBRARY:
        name_lower = item["name"].lower()
        if name_lower in existing_names:
            skipped += 1
            continue

        food = FoodItem(
            name=item["name"],
            brand=item.get("brand"),
            barcode=None,  # No barcodes for curated seeds (avoids unique constraint issues)
            calories_per_100g=float(item["calories_per_100g"]),
            carbs_per_100g=float(item["carbs_per_100g"]),
            protein_per_100g=float(item["protein_per_100g"]),
            fat_per_100g=float(item["fat_per_100g"]),
            fiber_per_100g=float(item.get("fiber_per_100g", 0.0)),
            sugar_per_100g=float(item.get("sugar_per_100g", 0.0)),
            sodium_per_100g=float(item.get("sodium_per_100g", 0.0)),
            saturated_fat_per_100g=float(item.get("saturated_fat_per_100g", 0.0)),
            image_url=item.get("image_url"),
            source=FoodSource.API,
            created_by=None,  # Public/global — visible to all users
        )
        session.add(food)
        existing_names.add(name_lower)
        added += 1

    if added > 0:
        await session.commit()
        print(f"[OK] Seeded {added} food items successfully ({skipped} already existed and were skipped).")
    else:
        print(f"[OK] No new food items to add ({skipped} items already exist).")


async def main():
    print(f"[INFO] Connecting to: {settings.DATABASE_URL}")
    engine = create_async_engine(settings.DATABASE_URL)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with async_session() as session:
        print(f"[INFO] Seeding {len(FOOD_LIBRARY)} food items from curated USDA-based library...")
        await seed_foods(session)

    await engine.dispose()
    print("\n[DONE] Database seeding complete!")


if __name__ == "__main__":
    asyncio.run(main())
