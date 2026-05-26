import uuid
import enum
from datetime import datetime, date
from sqlalchemy import String, Integer, Float, ForeignKey, DateTime, Date, Enum, Index, Boolean, func, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base

class ExerciseType(str, enum.Enum):
    CARDIO = "cardio"
    STRENGTH = "strength"

class ExerciseLog(Base):
    __tablename__ = "exercise_logs"

    id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    exercise_name: Mapped[str] = mapped_column(String(255), nullable=False)
    exercise_type: Mapped[ExerciseType] = mapped_column(Enum(ExerciseType), nullable=False)
    
    duration_minutes: Mapped[int] = mapped_column(Integer, nullable=True)
    calories_burned: Mapped[float] = mapped_column(Float, nullable=False)
    notes: Mapped[str] = mapped_column(String(1000), nullable=True)
    
    log_date: Mapped[date] = mapped_column(Date, nullable=False)
    logged_at: Mapped[datetime] = mapped_column(DateTime, default=func.now(), nullable=False)

    # Relationships
    user = relationship("User", back_populates="exercise_logs")
    sets = relationship("ExerciseSet", back_populates="exercise_log", cascade="all, delete-orphan", lazy="joined")

    # Indices
    __table_args__ = (
        Index("idx_exercise_logs_user_date", "user_id", "log_date"),
    )


class ExerciseSet(Base):
    __tablename__ = "exercise_sets"

    id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    exercise_log_id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), ForeignKey("exercise_logs.id", ondelete="CASCADE"), nullable=False)
    set_number: Mapped[int] = mapped_column(Integer, nullable=False)
    reps: Mapped[int] = mapped_column(Integer, nullable=True)
    weight_kg: Mapped[float] = mapped_column(Float, nullable=True)
    completed: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    # Relationships
    exercise_log = relationship("ExerciseLog", back_populates="sets")
