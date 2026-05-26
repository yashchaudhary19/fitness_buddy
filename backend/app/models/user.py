import uuid
import enum
from datetime import datetime
from sqlalchemy import String, Boolean, DateTime, Enum, func, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base

class UnitSystem(str, enum.Enum):
    METRIC = "metric"
    IMPERIAL = "imperial"

class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    avatar_url: Mapped[str] = mapped_column(String(1024), nullable=True)
    unit_system: Mapped[UnitSystem] = mapped_column(Enum(UnitSystem), default=UnitSystem.METRIC, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=func.now(), nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=func.now(), onupdate=func.now(), nullable=True)

    # Relationships
    goal = relationship("UserGoal", back_populates="user", uselist=False, cascade="all, delete-orphan")
    food_logs = relationship("FoodLogEntry", back_populates="user", cascade="all, delete-orphan")
    water_logs = relationship("WaterLog", back_populates="user", cascade="all, delete-orphan")
    exercise_logs = relationship("ExerciseLog", back_populates="user", cascade="all, delete-orphan")
    weight_entries = relationship("WeightEntry", back_populates="user", cascade="all, delete-orphan")
    body_measurements = relationship("BodyMeasurement", back_populates="user", cascade="all, delete-orphan")
    refresh_tokens = relationship("RefreshToken", back_populates="user", cascade="all, delete-orphan")
