import uuid
import enum
from datetime import datetime, date
from sqlalchemy import String, Float, ForeignKey, DateTime, Date, Enum, Index, func, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base

class FoodSource(str, enum.Enum):
    API = "api"
    BARCODE = "barcode"
    CUSTOM = "custom"
    AI_SCAN = "ai_scan"

class MealType(str, enum.Enum):
    BREAKFAST = "breakfast"
    LUNCH = "lunch"
    DINNER = "dinner"
    SNACKS = "snacks"

class FoodItem(Base):
    __tablename__ = "food_items"

    id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    brand: Mapped[str] = mapped_column(String(255), nullable=True)
    barcode: Mapped[str] = mapped_column(String(50), unique=True, nullable=True)
    
    calories_per_100g: Mapped[float] = mapped_column(Float, nullable=False)
    carbs_per_100g: Mapped[float] = mapped_column(Float, nullable=False)
    protein_per_100g: Mapped[float] = mapped_column(Float, nullable=False)
    fat_per_100g: Mapped[float] = mapped_column(Float, nullable=False)
    fiber_per_100g: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    sugar_per_100g: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    sodium_per_100g: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    saturated_fat_per_100g: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    
    image_url: Mapped[str] = mapped_column(String(1024), nullable=True)
    source: Mapped[FoodSource] = mapped_column(Enum(FoodSource), default=FoodSource.API, nullable=False)
    created_by: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=func.now(), nullable=False)

    # Relationships
    creator = relationship("User")
    log_entries = relationship("FoodLogEntry", back_populates="food_item")

    # Indices
    __table_args__ = (
        Index("idx_food_items_name", "name"),
        Index("idx_food_items_barcode", "barcode"),
        Index("idx_food_items_created_by", "created_by"),
    )


class FoodLogEntry(Base):
    __tablename__ = "food_log_entries"

    id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    food_item_id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), ForeignKey("food_items.id", ondelete="RESTRICT"), nullable=False)
    meal_type: Mapped[MealType] = mapped_column(Enum(MealType), nullable=False)
    
    serving_size_g: Mapped[float] = mapped_column(Float, nullable=False)
    calories: Mapped[float] = mapped_column(Float, nullable=False)
    carbs_g: Mapped[float] = mapped_column(Float, nullable=False)
    protein_g: Mapped[float] = mapped_column(Float, nullable=False)
    fat_g: Mapped[float] = mapped_column(Float, nullable=False)
    fiber_g: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    
    log_date: Mapped[date] = mapped_column(Date, nullable=False)
    logged_at: Mapped[datetime] = mapped_column(DateTime, default=func.now(), nullable=False)

    # Relationships
    user = relationship("User", back_populates="food_logs")
    food_item = relationship("FoodItem", back_populates="log_entries", lazy="joined")

    # Indices
    __table_args__ = (
        Index("idx_food_log_entries_user_date", "user_id", "log_date"),
    )
