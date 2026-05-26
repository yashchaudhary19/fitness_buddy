import uuid
from datetime import datetime
from typing import Optional
from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.user import User
from app.models.token import RefreshToken
from app.repositories.base import BaseRepository

class UserRepository(BaseRepository[User]):
    def __init__(self, db: AsyncSession):
        super().__init__(User, db)

    async def get_by_email(self, email: str) -> Optional[User]:
        """Fetch user by email address."""
        result = await self.db.execute(select(User).filter(User.email == email))
        return result.scalars().first()


class RefreshTokenRepository(BaseRepository[RefreshToken]):
    def __init__(self, db: AsyncSession):
        super().__init__(RefreshToken, db)

    async def get_by_token_hash(self, token_hash: str) -> Optional[RefreshToken]:
        """Fetch a refresh token by its hashed value."""
        result = await self.db.execute(select(RefreshToken).filter(RefreshToken.token_hash == token_hash))
        return result.scalars().first()

    async def delete_by_user(self, user_id: uuid.UUID) -> None:
        """Delete all refresh tokens associated with a user."""
        await self.db.execute(delete(RefreshToken).filter(RefreshToken.user_id == user_id))
