import time
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, status, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.core.redis import init_redis, close_redis

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("nutritrack.main")

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Connect to Redis
    logger.info("Initializing services...")
    await init_redis()
    yield
    # Shutdown: Close Redis
    logger.info("Tearing down services...")
    await close_redis()

app = FastAPI(
    title="NutriTrack API",
    description="Backend service API for NutriTrack Fitness tracker app.",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS middleware configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Temporarily allow all for debugging real devices
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Request logging middleware
@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    duration = (time.time() - start_time) * 1000
    if response.status_code >= 400:
        logger.error(
            f"Method: {request.method} | Path: {request.url.path} | "
            f"Status: {response.status_code} | Duration: {duration:.2f}ms"
        )
    else:
        logger.info(
            f"Method: {request.method} | Path: {request.url.path} | "
            f"Status: {response.status_code} | Duration: {duration:.2f}ms"
        )
    return response

# Global Exception Handler
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    if isinstance(exc, HTTPException):
        return JSONResponse(
            status_code=exc.status_code,
            content={
                "success": False,
                "error": "ClientError" if exc.status_code < 500 else "ServerError",
                "detail": exc.detail
            }
        )
    logger.exception(f"Unhandled exception occurred on path {request.url.path}: {exc}")
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "success": False,
            "error": "InternalServerError",
            "detail": str(exc) if settings.ENVIRONMENT == "development" else "An unexpected error occurred. Please contact administrator or check logs."
        }
    )

# Root Healthcheck Endpoint
@app.get("/health", tags=["Health"])
async def health_check():
    return {
        "success": True,
        "data": {
            "status": "healthy",
            "environment": settings.ENVIRONMENT
        },
        "message": "NutriTrack Backend API is healthy"
    }

# Import Routers
from app.api.endpoints import auth, goals, foods, diary, water, exercise, weight, progress, ai

# Register Routers
app.include_router(auth.router, prefix="/api/auth", tags=["Authentication"])
app.include_router(goals.router, prefix="/api/goals", tags=["Goals"])
app.include_router(foods.router, prefix="/api/foods", tags=["Foods"])
app.include_router(diary.router, prefix="/api/diary", tags=["Diary"])
app.include_router(water.router, prefix="/api/water", tags=["Water"])
app.include_router(exercise.router, prefix="/api/exercises", tags=["Exercises"])
app.include_router(weight.router, prefix="/api/weight", tags=["Weight"])
app.include_router(progress.router, prefix="/api/progress", tags=["Progress"])
app.include_router(ai.router, prefix="/api/ai", tags=["AI"])
app.include_router(ai.router, prefix="/api/v1/ai", tags=["AI"])

