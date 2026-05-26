import uuid
from datetime import datetime
from sqlalchemy import Float, ForeignKey, DateTime, Index, func, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base

class BodyMeasurement(Base):
    __tablename__ = "body_measurements"

    id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    
    waist_cm: Mapped[float] = mapped_column(Float, nullable=True)
    chest_cm: Mapped[float] = mapped_column(Float, nullable=True)
    hips_cm: Mapped[float] = mapped_column(Float, nullable=True)
    left_arm_cm: Mapped[float] = mapped_column(Float, nullable=True)
    right_arm_cm: Mapped[float] = mapped_column(Float, nullable=True)
    left_thigh_cm: Mapped[float] = mapped_column(Float, nullable=True)
    right_thigh_cm: Mapped[float] = mapped_column(Float, nullable=True)
    
    logged_at: Mapped[datetime] = mapped_column(DateTime, default=func.now(), nullable=False)

    # Relationships
    user = relationship("User", back_populates="body_measurements")

    # Indices
    __table_args__ = (
        Index("idx_body_measurements_user_logged", "user_id", "logged_at"),
    )
