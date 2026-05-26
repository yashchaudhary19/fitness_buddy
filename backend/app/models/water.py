import uuid
from datetime import datetime, date
from sqlalchemy import Integer, Date, ForeignKey, DateTime, Index, func, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base

class WaterLog(Base):
    __tablename__ = "water_logs"

    id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    amount_ml: Mapped[int] = mapped_column(Integer, nullable=False)
    log_date: Mapped[date] = mapped_column(Date, nullable=False)
    logged_at: Mapped[datetime] = mapped_column(DateTime, default=func.now(), nullable=False)

    # Relationships
    user = relationship("User", back_populates="water_logs")

    # Indices
    __table_args__ = (
        Index("idx_water_logs_user_date", "user_id", "log_date"),
    )
