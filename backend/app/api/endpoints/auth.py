from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
import httpx

from app.api import deps
from app.core.config import settings
from app.core.database import get_db
from app.core.security import get_password_hash, verify_password
from app.models.user import User
from app.repositories.user import UserRepository
from app.schemas.base import ResponseEnvelope
from app.schemas.user import (
    UserRegister,
    UserLogin,
    UserUpdate,
    PasswordUpdate,
    UserResponse,
    AuthResponse,
    TokenRefreshRequest,
    TokenRefreshResponse,
)
from app.services.auth import AuthService
from pydantic import BaseModel

router = APIRouter()

class GoogleAuthRequest(BaseModel):
    supabase_token: str

@router.post(
    "/register",
    response_model=ResponseEnvelope[AuthResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Register a new user account"
)
async def register(schema: UserRegister, db: AsyncSession = Depends(get_db)):
    auth_service = AuthService(db)
    user, access_token, refresh_token = await auth_service.register_user(schema)
    
    return ResponseEnvelope(
        success=True,
        data=AuthResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            user=UserResponse.model_validate(user)
        ),
        message="User registered successfully."
    )


@router.post(
    "/login",
    response_model=ResponseEnvelope[AuthResponse],
    summary="Log into user account"
)
async def login(schema: UserLogin, db: AsyncSession = Depends(get_db)):
    auth_service = AuthService(db)
    user, access_token, refresh_token = await auth_service.authenticate_user(schema)
    
    return ResponseEnvelope(
        success=True,
        data=AuthResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            user=UserResponse.model_validate(user)
        ),
        message="Login successful."
    )


@router.post(
    "/refresh",
    response_model=ResponseEnvelope[TokenRefreshResponse],
    summary="Refresh access token"
)
async def refresh(schema: TokenRefreshRequest, db: AsyncSession = Depends(get_db)):
    auth_service = AuthService(db)
    new_access_token = await auth_service.refresh_access_token(schema.refresh_token)
    
    return ResponseEnvelope(
        success=True,
        data=TokenRefreshResponse(access_token=new_access_token),
        message="Access token refreshed successfully."
    )


@router.post(
    "/logout",
    response_model=ResponseEnvelope[dict],
    summary="Log out of user account"
)
async def logout(schema: TokenRefreshRequest, db: AsyncSession = Depends(get_db)):
    auth_service = AuthService(db)
    await auth_service.revoke_refresh_token(schema.refresh_token)
    
    return ResponseEnvelope(
        success=True,
        data={},
        message="Logout successful."
    )


@router.post(
    "/google",
    response_model=ResponseEnvelope[AuthResponse],
    summary="Sign in or sign up with Google via Supabase OAuth"
)
async def google_login(schema: GoogleAuthRequest, db: AsyncSession = Depends(get_db)):
    """
    Verify a Supabase access token from Google OAuth, then find or create
    the user in our database and return native JWT tokens.
    """
    # 1. Verify the Supabase token by calling the Supabase Admin /auth/v1/user endpoint
    supabase_url = settings.SUPABASE_URL
    service_key = settings.SUPABASE_SERVICE_ROLE_KEY

    async with httpx.AsyncClient() as client:
        resp = await client.get(
            f"{supabase_url}/auth/v1/user",
            headers={
                "Authorization": f"Bearer {schema.supabase_token}",
                "apikey": service_key,
            },
        )

    if resp.status_code != 200:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired Google token. Please sign in again.",
        )

    supabase_user = resp.json()
    email = supabase_user.get("email")
    if not email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Google account does not have an email address.",
        )

    # Extract display name from Supabase user metadata
    user_metadata = supabase_user.get("user_metadata", {})
    name = (
        user_metadata.get("full_name")
        or user_metadata.get("name")
        or email.split("@")[0]
    )

    # 2. Find or create the user in our database
    auth_service = AuthService(db)
    user_repo = UserRepository(db)

    existing_user = await user_repo.get_by_email(email)
    if existing_user:
        # Existing user — just issue new tokens
        user = existing_user
    else:
        # New user — create account without a password (Google-only account)
        from app.schemas.user import UserRegister as _UserRegister
        import secrets
        random_password = secrets.token_hex(32)  # Random, unusable password
        new_user = User(
            email=email,
            password_hash=get_password_hash(random_password),
            name=name,
        )
        await user_repo.create(new_user)
        await db.flush()
        user = new_user

    # 3. Issue our app's JWT tokens
    from app.core.security import create_access_token, create_refresh_token, decode_token
    from app.models.token import RefreshToken
    from app.repositories.user import RefreshTokenRepository
    from datetime import datetime, timezone
    import hashlib

    access_token = create_access_token(subject=user.id)
    refresh_token = create_refresh_token(subject=user.id)

    token_payload = decode_token(refresh_token)
    expires_at = datetime.fromtimestamp(token_payload["exp"], tz=timezone.utc).replace(tzinfo=None)
    token_hash = hashlib.sha256(refresh_token.encode()).hexdigest()

    token_repo = RefreshTokenRepository(db)
    db_refresh = RefreshToken(
        user_id=user.id,
        token_hash=token_hash,
        expires_at=expires_at,
    )
    await token_repo.create(db_refresh)
    await db.commit()

    return ResponseEnvelope(
        success=True,
        data=AuthResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            user=UserResponse.model_validate(user),
        ),
        message="Google sign-in successful.",
    )


@router.get(
    "/me",
    response_model=ResponseEnvelope[UserResponse],
    summary="Retrieve current user profile"
)
async def get_me(current_user: User = Depends(deps.get_current_user)):
    return ResponseEnvelope(
        success=True,
        data=UserResponse.model_validate(current_user),
        message="User profile retrieved successfully."
    )


@router.put(
    "/me",
    response_model=ResponseEnvelope[UserResponse],
    summary="Update current user profile"
)
async def update_me(
    schema: UserUpdate,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(get_db)
):
    user_repo = UserRepository(db)
    updated_data = schema.model_dump(exclude_unset=True)
    
    if not updated_data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No update parameters provided."
        )

    updated_user = await user_repo.update(current_user, updated_data)
    await db.commit()
    
    return ResponseEnvelope(
        success=True,
        data=UserResponse.model_validate(updated_user),
        message="User profile updated successfully."
    )


@router.put(
    "/password",
    response_model=ResponseEnvelope[dict],
    summary="Update user password"
)
async def update_password(
    schema: PasswordUpdate,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(get_db)
):
    user_repo = UserRepository(db)
    
    if not verify_password(schema.current_password, current_user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Incorrect current password."
        )

    new_hash = get_password_hash(schema.new_password)
    await user_repo.update(current_user, {"password_hash": new_hash})
    await db.commit()
    
    return ResponseEnvelope(
        success=True,
        data={},
        message="Password updated successfully."
    )
