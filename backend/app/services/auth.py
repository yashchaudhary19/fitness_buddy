import hashlib
import uuid
from datetime import datetime, timezone
from typing import Optional, Tuple
from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User
from app.models.token import RefreshToken
from app.core.security import verify_password, get_password_hash, create_access_token, create_refresh_token, decode_token
from app.schemas.user import UserRegister, UserLogin
from app.repositories.user import UserRepository, RefreshTokenRepository

class AuthService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.user_repo = UserRepository(db)
        self.token_repo = RefreshTokenRepository(db)

    def _hash_token(self, token: str) -> str:
        """Hash a token using SHA-256 for secure DB storage."""
        return hashlib.sha256(token.encode()).hexdigest()

    async def register_user(self, schema: UserRegister) -> Tuple[User, str, str]:
        """Register a new user, generating active access/refresh tokens."""
        existing_user = await self.user_repo.get_by_email(schema.email)
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="A user with this email address already exists."
            )

        hashed_password = get_password_hash(schema.password)
        db_user = User(
            email=schema.email,
            password_hash=hashed_password,
            name=schema.name
        )
        
        await self.user_repo.create(db_user)
        
        access_token = create_access_token(subject=db_user.id)
        refresh_token = create_refresh_token(subject=db_user.id)
        
        # Save hashed refresh token to DB
        token_payload = decode_token(refresh_token)
        expires_at = datetime.fromtimestamp(token_payload["exp"], tz=timezone.utc).replace(tzinfo=None)
        
        db_refresh = RefreshToken(
            user_id=db_user.id,
            token_hash=self._hash_token(refresh_token),
            expires_at=expires_at
        )
        await self.token_repo.create(db_refresh)
        
        await self.db.commit()
        return db_user, access_token, refresh_token

    async def authenticate_user(self, schema: UserLogin) -> Tuple[User, str, str]:
        """Authenticate user credentials and return new session tokens."""
        user = await self.user_repo.get_by_email(schema.email)
        if not user or not verify_password(schema.password, user.password_hash):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect email or password.",
                headers={"WWW-Authenticate": "Bearer"},
            )
            
        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="User account is deactivated."
            )

        access_token = create_access_token(subject=user.id)
        refresh_token = create_refresh_token(subject=user.id)
        
        # Save hashed refresh token to DB
        token_payload = decode_token(refresh_token)
        expires_at = datetime.fromtimestamp(token_payload["exp"], tz=timezone.utc).replace(tzinfo=None)
        
        db_refresh = RefreshToken(
            user_id=user.id,
            token_hash=self._hash_token(refresh_token),
            expires_at=expires_at
        )
        await self.token_repo.create(db_refresh)
        
        await self.db.commit()
        return user, access_token, refresh_token

    async def refresh_access_token(self, refresh_token: str) -> str:
        """Validate refresh token and issue a new access token."""
        payload = decode_token(refresh_token)
        if not payload or payload.get("type") != "refresh":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid refresh token."
            )

        token_hash = self._hash_token(refresh_token)
        db_token = await self.token_repo.get_by_token_hash(token_hash)
        if not db_token or db_token.expires_at < datetime.now(timezone.utc).replace(tzinfo=None):
            if db_token:
                await self.token_repo.remove(db_token.id)
                await self.db.commit()
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Refresh token expired or revoked."
            )

        # Retrieve user
        user = await self.user_repo.get(db_token.user_id)
        if not user or not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User inactive or not found."
            )

        # Issue new access token
        new_access_token = create_access_token(subject=user.id)
        return new_access_token

    async def revoke_refresh_token(self, refresh_token: str) -> None:
        """Revoke a refresh token (logout)."""
        token_hash = self._hash_token(refresh_token)
        db_token = await self.token_repo.get_by_token_hash(token_hash)
        if db_token:
            await self.token_repo.remove(db_token.id)
            await self.db.commit()
