import logging
from typing import Optional
import cloudinary
import cloudinary.uploader
from app.core.config import settings

logger = logging.getLogger("nutritrack.cloudinary")

_cloudinary_initialized = False

def init_cloudinary() -> None:
    """Lazy initialize Cloudinary config."""
    global _cloudinary_initialized
    if not _cloudinary_initialized:
        if settings.CLOUDINARY_CLOUD_NAME and settings.CLOUDINARY_API_KEY and \
           not settings.CLOUDINARY_CLOUD_NAME.startswith("your-cloudinary") and \
           not settings.CLOUDINARY_API_KEY.startswith("your-cloudinary"):
            try:
                cloudinary.config(
                    cloud_name=settings.CLOUDINARY_CLOUD_NAME,
                    api_key=settings.CLOUDINARY_API_KEY,
                    api_secret=settings.CLOUDINARY_API_SECRET,
                    secure=True
                )
                _cloudinary_initialized = True
                logger.info("Cloudinary SDK initialized successfully.")
            except Exception as e:
                logger.error(f"Failed to configure Cloudinary SDK: {e}")
        else:
            logger.warning("Cloudinary credentials are not fully set in .env. Falling back to dummy upload.")

async def upload_image(file_bytes: bytes, folder: str = "nutritrack") -> Optional[str]:
    """
    Upload image bytes to Cloudinary.
    Returns the secure URL on success, or a fallback mock URL if Cloudinary is not configured.
    """
    init_cloudinary()
    if not _cloudinary_initialized:
        # Fallback placeholder image for offline/local development
        logger.info("Using placeholder URL for local simulation.")
        return "https://res.cloudinary.com/demo/image/upload/v1580976192/sample.jpg"

    try:
        # Run upload in executor to keep it async
        import asyncio
        from concurrent.futures import ThreadPoolExecutor
        
        loop = asyncio.get_event_loop()
        executor = ThreadPoolExecutor(max_workers=2)
        
        # cloudinary.uploader.upload accepts bytes, file-like objects, or local paths
        result = await loop.run_in_executor(
            executor,
            lambda: cloudinary.uploader.upload(file_bytes, folder=folder)
        )
        return result.get("secure_url")
    except Exception as e:
        logger.error(f"Cloudinary image upload failed: {e}")
        # Return fallback placeholder to prevent app crash
        return "https://res.cloudinary.com/demo/image/upload/v1580976192/sample.jpg"
