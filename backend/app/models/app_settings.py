from datetime import datetime
from sqlalchemy import String, Text, DateTime, func
from sqlalchemy.orm import Mapped, mapped_column
from app.core.database import Base

class AppSettings(Base):
    __tablename__ = "app_settings"

    id: Mapped[str] = mapped_column(String(50), primary_key=True)
    ai_provider: Mapped[str] = mapped_column(String(20), default="gemini", nullable=False)
    gemini_model: Mapped[str] = mapped_column(String(100), default="gemini-flash-latest", nullable=False)
    claude_model: Mapped[str] = mapped_column(String(100), default="claude-3-5-sonnet-20241022", nullable=False)
    gemini_api_key: Mapped[str] = mapped_column(Text, nullable=True)
    claude_api_key: Mapped[str] = mapped_column(Text, nullable=True)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=func.now(), onupdate=func.now(), nullable=False)
