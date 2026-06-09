import time
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, status, HTTPException
from fastapi.responses import JSONResponse, HTMLResponse, FileResponse
from fastapi.staticfiles import StaticFiles
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
    title="NutriVault API",
    description="Backend service API for NutriVault Fitness tracker app.",
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
        "message": "NutriVault Backend API is healthy"
    }

# Mount static assets directory
app.mount("/assets", StaticFiles(directory="static/assets"), name="assets")

@app.get("/app.js", include_in_schema=False)
async def get_app_js():
    return FileResponse("static/app.js")

@app.get("/style.css", include_in_schema=False)
async def get_style_css():
    return FileResponse("static/style.css")

@app.get("/robots.txt", include_in_schema=False)
async def get_robots():
    return FileResponse("static/robots.txt")

@app.get("/sitemap.xml", include_in_schema=False)
async def get_sitemap():
    return FileResponse("static/sitemap.xml")

# Root Welcome Endpoint serving the marketing landing page
@app.get("/", response_class=FileResponse, tags=["Root"])
async def root():
    return FileResponse("static/index.html")




# Privacy Policy Endpoint
@app.get("/privacy", response_class=HTMLResponse, tags=["Privacy"])
async def privacy_policy():
    html_content = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Privacy Policy - NutriVault</title>
        <style>
            body {
                font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                line-height: 1.6;
                color: #333;
                max-width: 800px;
                margin: 0 auto;
                padding: 40px 20px;
                background-color: #fafafa;
            }
            .container {
                background: #fff;
                padding: 40px;
                border-radius: 8px;
                box-shadow: 0 4px 6px rgba(0, 0, 0, 0.05);
            }
            h1 {
                color: #2e7d32;
                border-bottom: 2px solid #eaeaea;
                padding-bottom: 10px;
            }
            h2 {
                color: #1b5e20;
                margin-top: 30px;
            }
            ul {
                padding-left: 20px;
            }
            .footer {
                margin-top: 40px;
                font-size: 0.9em;
                color: #777;
                text-align: center;
                border-top: 1px solid #eaeaea;
                padding-top: 20px;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>Privacy Policy for NutriVault</h1>
            <p><strong>Effective Date: June 8, 2026</strong></p>
            <p>NutriVault ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application ("NutriVault").</p>
            
            <h2>1. Information We Collect</h2>
            <p>We only collect and process information necessary to provide the features of NutriVault. This includes:</p>
            <ul>
                <li><strong>Account Information</strong>: When you register, we collect your email address, name, and password. This is securely managed using Supabase Authentication.</li>
                <li><strong>Camera Access</strong>: With your permission, we access your device's camera to scan food barcodes and analyze meal photos using AI. We do not store your photos permanently on our servers.</li>
                <li><strong>Microphone and Audio Access</strong>: With your permission, we access your device's microphone to allow speech-to-text recording for voice-based meal logging. Audio files are processed in real-time and are not saved or recorded on our servers.</li>
            </ul>

            <h2>2. Third-Party Integrations</h2>
            <p>NutriVault integrates with trusted third-party services to offer core functionalities:</p>
            <ul>
                <li><strong>Supabase</strong>: Used for secure user authentication and database storage.</li>
                <li><strong>Google Mobile Ads (AdMob)</strong>: We display advertisements to support our services. AdMob may collect and process device identifiers or cookies to deliver relevant ads.</li>
                <li><strong>AI Services</strong>: Image analysis and voice transcriptions are processed via secure API gateways to parse and estimate nutrition info. No personal identifiers are shared with AI providers.</li>
            </ul>

            <h2>3. Data Security</h2>
            <p>We implement industry-standard security measures, including encryption in transit and secure database practices, to protect your personal information against unauthorized access, alteration, or disclosure.</p>

            <h2>4. Your Rights and Choices</h2>
            <p>You can access, modify, or delete your account information at any time directly within the app settings. If you delete your account, all your associated diary and fitness logs will be permanently deleted from our database.</p>

            <h2>5. Changes to This Privacy Policy</h2>
            <p>We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Effective Date".</p>

            <h2>6. Contact Us</h2>
            <p>If you have any questions or suggestions about this Privacy Policy, please contact us at:</p>
            <p>Email: <a href="mailto:support@techotd.in">support@techotd.in</a></p>

            <div class="footer">
                <p>&copy; 2026 NutriVault. All rights reserved.</p>
            </div>
        </div>
    </body>
    </html>
    """
    return HTMLResponse(content=html_content, status_code=200)


# Account Deletion Request Endpoint
@app.get("/delete-account", response_class=HTMLResponse, tags=["Privacy"])
async def delete_account_page():
    html_content = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Delete Account & Data - NutriVault</title>
        <style>
            body {
                font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                line-height: 1.6;
                color: #333;
                max-width: 600px;
                margin: 0 auto;
                padding: 40px 20px;
                background-color: #fafafa;
            }
            .container {
                background: #fff;
                padding: 40px;
                border-radius: 12px;
                box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
            }
            h1 {
                color: #c62828;
                border-bottom: 2px solid #eaeaea;
                padding-bottom: 10px;
                margin-top: 0;
            }
            h2 {
                color: #333;
                font-size: 1.2em;
                margin-top: 20px;
            }
            p {
                margin: 15px 0;
            }
            .warning-box {
                background-color: #ffebee;
                border-left: 4px solid #ef5350;
                padding: 15px;
                border-radius: 4px;
                margin: 20px 0;
                color: #c62828;
                font-weight: 500;
            }
            .btn-email {
                display: inline-block;
                background-color: #ef5350;
                color: white;
                text-decoration: none;
                padding: 12px 24px;
                border-radius: 6px;
                font-weight: bold;
                margin-top: 15px;
                transition: background-color 0.2s;
            }
            .btn-email:hover {
                background-color: #d32f2f;
            }
            .footer {
                margin-top: 40px;
                font-size: 0.9em;
                color: #777;
                text-align: center;
                border-top: 1px solid #eaeaea;
                padding-top: 20px;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>Request Account & Data Deletion</h1>
            <p>We are sorry to see you go! Under Google Play Developer Policies and data protection regulations, you have the right to request the permanent deletion of your account and all associated data.</p>
            
            <div class="warning-box">
                <strong>Important:</strong> Deleting your account is permanent and cannot be undone. All your diet logs, water tracking history, goals, and weight records will be permanently erased.
            </div>

            <h2>How to request deletion:</h2>
            <p>Please send an email from your registered email address to our support desk:</p>
            <p><strong>Email:</strong> <a href="mailto:support@techotd.in?subject=NutriVault Account Deletion Request">support@techotd.in</a></p>
            <p><strong>Subject:</strong> NutriVault Account Deletion Request</p>
            
            <a href="mailto:support@techotd.in?subject=NutriVault Account Deletion Request" class="btn-email">Email Support to Delete Account</a>
            
            <p style="margin-top: 25px; font-size: 0.9em; color: #666;">
                Once your request is received, our team will process your deletion request and confirm via email within <strong>24 to 48 hours</strong>.
            </p>

            <div class="footer">
                <p><a href="/privacy" style="color: #666; text-decoration: underline;">Back to Privacy Policy</a></p>
                <p>&copy; 2026 NutriVault. All rights reserved.</p>
            </div>
        </div>
    </body>
    </html>
    """
    return HTMLResponse(content=html_content, status_code=200)


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

