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
    OTPSendRequest,
    OTPVerifyRequest,
)
from app.models.otp import OTPCode
from app.repositories.otp import OTPCodeRepository
from app.services.email import send_otp_email
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
    "/send-otp",
    response_model=ResponseEnvelope[dict],
    summary="Send OTP code to email"
)
async def send_otp(schema: OTPSendRequest, db: AsyncSession = Depends(get_db)):
    import secrets
    from datetime import datetime, timedelta, timezone
    
    email = schema.email.strip().lower()
    if email == "yash1@gmail.com":
        return ResponseEnvelope(
            success=True,
            data={},
            message="Verification code sent to your email."
        )
    
    # Check if user exists in the database
    user_repo = UserRepository(db)
    user = await user_repo.get_by_email(email)
    
    if schema.flow == "login" and not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Account does not exist. Please sign up first."
        )
    elif schema.flow == "signup" and user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Account already exists. Please log in instead."
        )
    
    # Generate 6-digit numeric OTP
    otp_code = "".join(secrets.choice("0123456789") for _ in range(6))
    
    # Expiration: 5 minutes from now in UTC naive datetime
    expires_at = datetime.now(timezone.utc).replace(tzinfo=None) + timedelta(minutes=5)
    
    # Persist the code
    otp_repo = OTPCodeRepository(db)
    db_otp = OTPCode(
        email=email,
        code=otp_code,
        expires_at=expires_at,
        is_used=False
    )
    await otp_repo.create(db_otp)
    await db.commit()
    
    # Send email (either real SMTP or simulated log/console)
    email_sent = await send_otp_email(email, otp_code)
    
    if not email_sent:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to send verification code email."
        )
        
    return ResponseEnvelope(
        success=True,
        data={},
        message="Verification code sent to your email."
    )


@router.post(
    "/verify-otp",
    response_model=ResponseEnvelope[AuthResponse],
    summary="Verify OTP code and authenticate user"
)
async def verify_otp(schema: OTPVerifyRequest, db: AsyncSession = Depends(get_db)):
    from app.repositories.user import UserRepository
    from app.core.security import get_password_hash
    import secrets
    
    email = schema.email.strip().lower()
    
    # Check valid OTP
    if email == "yash1@gmail.com" and schema.code == "123456":
        # Bypass verification for Google Play Store review tester
        pass
    else:
        otp_repo = OTPCodeRepository(db)
        valid_otp = await otp_repo.get_valid_otp(email, schema.code)
        if not valid_otp:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or expired verification code."
            )
            
        # Mark code as used
        await otp_repo.update(valid_otp, {"is_used": True})
    
    # Look up user or create new
    user_repo = UserRepository(db)
    user = await user_repo.get_by_email(email)
    
    is_new_user = False
    if not user:
        is_new_user = True
        # For new users, we register them!
        # Derive name from email prefix or schema.name
        name = schema.name or email.split("@")[0].capitalize()
        # Generate random unusable password hash
        random_pass = secrets.token_hex(32)
        password_hash = get_password_hash(random_pass)
        
        user = User(
            email=email,
            password_hash=password_hash,
            name=name
        )
        await user_repo.create(user)
        await db.flush()
        
    # Generate session tokens
    from app.core.security import create_access_token, create_refresh_token, decode_token
    from app.models.token import RefreshToken
    from app.repositories.user import RefreshTokenRepository
    from datetime import datetime, timezone
    import hashlib
    
    access_token = create_access_token(subject=user.id)
    refresh_token = create_refresh_token(subject=user.id)
    
    # Hash and save refresh token
    token_payload = decode_token(refresh_token)
    expires_at = datetime.fromtimestamp(token_payload["exp"], tz=timezone.utc).replace(tzinfo=None)
    token_hash = hashlib.sha256(refresh_token.encode()).hexdigest()
    
    token_repo = RefreshTokenRepository(db)
    db_refresh = RefreshToken(
        user_id=user.id,
        token_hash=token_hash,
        expires_at=expires_at
    )
    await token_repo.create(db_refresh)
    await db.commit()
    
    return ResponseEnvelope(
        success=True,
        data=AuthResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            user=UserResponse.model_validate(user)
        ),
        message="Registration successful." if is_new_user else "Login successful."
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
