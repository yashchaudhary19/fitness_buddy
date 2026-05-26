from fastapi import APIRouter, Depends, HTTPException, File, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api import deps
from app.core.database import get_db
from app.models.user import User
from app.schemas.base import ResponseEnvelope
from app.schemas.ai import (
    VoiceParseRequest,
    VoiceParseResponse,
    MealScanResponse,
    InsightsResponse,
    ChatRequest,
    ChatResponse,
    DailyDebriefResponse,
    WeightInterpretationResponse,
)
from app.services.ai import AIService
from app.services.cloudinary import upload_image

router = APIRouter()

@router.post(
    "/meal-scan",
    response_model=ResponseEnvelope[MealScanResponse],
    summary="Scan meal photo using computer vision"
)
async def scan_meal(
    file: UploadFile = File(...),
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(get_db)
):
    # Verify file is an image
    if not file.content_type.startswith("image/"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File must be an image type."
        )

    try:
        # Read file contents
        file_bytes = await file.read()
        
        # 1. Upload to Cloudinary (will return dummy link if not configured)
        image_url = await upload_image(file_bytes, folder="meal_scans")
        
        # 2. Analyze photo using AI Service
        ai_service = AIService(db)
        scan_data = await ai_service.scan_meal_photo(file_bytes, file.content_type)
        
        # Inject the image URL into the response
        scan_data["image_url"] = image_url
        
        return ResponseEnvelope(
            success=True,
            data=MealScanResponse(**scan_data),
            message="Meal photo scanned and analyzed successfully."
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to analyze meal photo: {str(e)}"
        )


@router.post(
    "/voice-parse",
    response_model=ResponseEnvelope[VoiceParseResponse],
    summary="Parse verbal diary logging description"
)
async def parse_voice(
    schema: VoiceParseRequest,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(get_db)
):
    ai_service = AIService(db)
    try:
        parsed_items = await ai_service.parse_voice_log(schema.transcript)
        return ResponseEnvelope(
            success=True,
            data=VoiceParseResponse(**parsed_items),
            message="Speech transcript parsed successfully."
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to parse speech transcript: {str(e)}"
        )


@router.get(
    "/insights",
    response_model=ResponseEnvelope[InsightsResponse],
    summary="Retrieve automated personal health insights and tips"
)
async def get_insights(
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(get_db)
):
    ai_service = AIService(db)
    try:
        insights_data = await ai_service.generate_insights(current_user.id)
        return ResponseEnvelope(
            success=True,
            data=InsightsResponse(**insights_data),
            message="Coaching insights retrieved successfully."
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate coaching insights: {str(e)}"
        )


@router.post(
    "/chat",
    response_model=ResponseEnvelope[ChatResponse],
    summary="Chat with personal AI Coach"
)
async def chat_coach(
    schema: ChatRequest,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(get_db)
):
    ai_service = AIService(db)
    try:
        reply = await ai_service.chat_with_coach(current_user.id, schema.messages)
        return ResponseEnvelope(
            success=True,
            data=ChatResponse(response=reply),
            message="Coach reply generated successfully."
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate coach reply: {str(e)}"
        )


@router.get(
    "/debrief",
    response_model=ResponseEnvelope[DailyDebriefResponse],
    summary="Get daily nutrition debrief"
)
async def get_daily_debrief(
    date_str: str = None,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(get_db)
):
    from datetime import date
    ai_service = AIService(db)
    try:
        if date_str:
            log_date = date.fromisoformat(date_str)
        else:
            log_date = date.today()
            
        debrief_data = await ai_service.get_daily_debrief(current_user.id, log_date)
        return ResponseEnvelope(
            success=True,
            data=DailyDebriefResponse(**debrief_data),
            message="Daily debrief generated successfully."
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate daily debrief: {str(e)}"
        )


@router.get(
    "/weight-interpretation",
    response_model=ResponseEnvelope[WeightInterpretationResponse],
    summary="Get interpretation of weight trends"
)
async def get_weight_interpretation(
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(get_db)
):
    ai_service = AIService(db)
    try:
        interpretation_data = await ai_service.get_weight_trend_interpretation(current_user.id)
        return ResponseEnvelope(
            success=True,
            data=WeightInterpretationResponse(**interpretation_data),
            message="Weight trend interpretation generated successfully."
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate weight interpretation: {str(e)}"
        )
