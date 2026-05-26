import uuid
from datetime import datetime
from sqlalchemy import Float, ForeignKey, String, DateTime, Index, func, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base

class WeightEntry(Base):
    __tablename__ = "weight_entries"

    id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    weight_kg: Mapped[float] = mapped_column(Float, nullable=False)
    note: Mapped[str] = mapped_column(String(500), nullable=True)
    logged_at: Mapped[datetime] = mapped_column(DateTime, default=func.now(), nullable=False)

    # Relationships
    user = relationship("User", back_populates="weight_entries")

    # Indices
    __table_args__ = (
        Index("idx_weight_entries_user_logged", "user_id", "logged_at"),
    )
