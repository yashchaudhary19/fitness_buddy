import uuid
import enum
from datetime import datetime
from sqlalchemy import Float, Integer, ForeignKey, DateTime, Enum, func, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base

class GoalType(str, enum.Enum):
    LOSE = "lose"
    MAINTAIN = "maintain"
    GAIN = "gain"

class Gender(str, enum.Enum):
    MALE = "male"
    FEMALE = "female"
    OTHER = "other"

class ActivityLevel(str, enum.Enum):
    SEDENTARY = "sedentary"
    LIGHT = "light"
    MODERATE = "moderate"
    ACTIVE = "active"
    VERY_ACTIVE = "very_active"

class UserGoal(Base):
    __tablename__ = "user_goals"

    id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    goal_type: Mapped[GoalType] = mapped_column(Enum(GoalType), nullable=False)
    current_weight_kg: Mapped[float] = mapped_column(Float, nullable=False)
    target_weight_kg: Mapped[float] = mapped_column(Float, nullable=False)
    height_cm: Mapped[float] = mapped_column(Float, nullable=False)
    age: Mapped[int] = mapped_column(Integer, nullable=False)
    gender: Mapped[Gender] = mapped_column(Enum(Gender), nullable=False)
    activity_level: Mapped[ActivityLevel] = mapped_column(Enum(ActivityLevel), nullable=False)
    weekly_pace_kg: Mapped[float] = mapped_column(Float, default=0.5, nullable=False)
    
    daily_calorie_target: Mapped[int] = mapped_column(Integer, nullable=False)
    daily_protein_g: Mapped[int] = mapped_column(Integer, nullable=False)
    daily_carbs_g: Mapped[int] = mapped_column(Integer, nullable=False)
    daily_fat_g: Mapped[int] = mapped_column(Integer, nullable=False)
    daily_fiber_g: Mapped[int] = mapped_column(Integer, default=25, nullable=False)
    daily_water_ml: Mapped[int] = mapped_column(Integer, nullable=False)
    
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=func.now(), onupdate=func.now(), nullable=False)

    # Relationships
    user = relationship("User", back_populates="goal")
