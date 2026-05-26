from typing import List, Optional
from pydantic import BaseModel, Field

# Meal Scan Schemas
class MealScanItem(BaseModel):
    name: str
    estimated_grams: float
    calories_per_100g: float
    carbs_per_100g: float
    protein_per_100g: float
    fat_per_100g: float
    confidence: str = Field(..., description="high | medium | low")

class MealScanResponse(BaseModel):
    items: List[MealScanItem]
    total_estimated_calories: float
    overall_confidence: str = Field(..., description="high | medium | low")
    meal_description: str
    image_url: Optional[str] = None

# Voice Logging Schemas
class VoiceParseRequest(BaseModel):
    transcript: str

class VoiceParseItem(BaseModel):
    food_name: str
    quantity_g: float
    unit_used: str
    meal_type: str = Field(..., description="breakfast | lunch | dinner | snacks")
    confidence: str = Field(..., description="high | medium | low")
    calories_per_100g: float
    carbs_per_100g: float
    protein_per_100g: float
    fat_per_100g: float

class VoiceParseResponse(BaseModel):
    items: List[VoiceParseItem]
    unparsed_text: Optional[str] = None

# Insights Schemas
class InsightItem(BaseModel):
    type: str
    message: str
    icon: str

class TipItem(BaseModel):
    message: str
    priority: str = Field(..., description="high | medium | low")

class InsightsResponse(BaseModel):
    insights: List[InsightItem]
    tips: List[TipItem]
    overall_score: int = Field(..., ge=0, le=100)

# AI Chat Coach Schemas
class ChatMessage(BaseModel):
    role: str = Field(..., description="user | assistant")
    content: str

class ChatRequest(BaseModel):
    messages: List[ChatMessage]

class ChatResponse(BaseModel):
    response: str

# Daily Nutrition Debrief Schemas
class DailyDebriefResponse(BaseModel):
    summary: str
    deficits: List[str]
    tweaks: List[str]

# Weight Trend Interpretation Schemas
class WeightInterpretationResponse(BaseModel):
    interpretation: str
    suggestion: str

