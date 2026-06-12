import os
from pydantic_settings import BaseSettings
from pydantic import ConfigDict
from typing import List

# Get the directory where config.py is located
BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ENV_FILE = os.path.join(BASE_DIR, ".env")
print(f"DEBUG: BASE_DIR={BASE_DIR}")
print(f"DEBUG: ENV_FILE={ENV_FILE}")
print(f"DEBUG: EXISTS={os.path.exists(ENV_FILE)}")

# Explicitly override os.environ with .env contents to prevent OS-level env vars from taking precedence
if os.path.exists(ENV_FILE):
    with open(ENV_FILE, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" in line:
                key, val = line.split("=", 1)
                key = key.strip()
                val = val.strip()
                if (val.startswith('"') and val.endswith('"')) or (val.startswith("'") and val.endswith("'")):
                    val = val[1:-1]
                os.environ[key] = val


class Settings(BaseSettings):
    model_config = ConfigDict(env_file=ENV_FILE, env_file_encoding="utf-8", case_sensitive=True, extra="ignore")

    DATABASE_URL: str = "sqlite+aiosqlite:///./nutritrack.db"
    REDIS_URL: str = "redis://localhost:6379/0"
    SECRET_KEY: str = "94bcde832b4b4554b7ae28d484ea388ba72ef2cfce71a0b3b4bc8fa77a2efde5"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    # Supabase (Google OAuth verification)
    SUPABASE_URL: str = "https://pxcwkgrpkkoukgaqicky.supabase.co"
    SUPABASE_SERVICE_ROLE_KEY: str = ""

    # Google Gemini API
    GEMINI_API_KEY: str = ""
    GEMINI_MODEL: str = "gemini-flash-latest"

    # Cloudinary (Progress Photos & Meal Scan Images)
    CLOUDINARY_CLOUD_NAME: str = ""
    CLOUDINARY_API_KEY: str = ""
    CLOUDINARY_API_SECRET: str = ""

    # Open Food Facts API
    OPEN_FOOD_FACTS_BASE: str = "https://world.openfoodfacts.org"
    FOOD_CACHE_TTL_SECONDS: int = 86400
    BARCODE_CACHE_TTL_SECONDS: int = 604800

    # App Settings
    ENVIRONMENT: str = "development"
    ALLOWED_ORIGINS: str = "http://localhost,http://10.0.2.2,http://127.0.0.1"

    @property
    def cors_origins(self) -> List[str]:
        return [origin.strip() for origin in self.ALLOWED_ORIGINS.split(",") if origin.strip()]

def _resolve_sqlite_url(database_url: str) -> str:
    prefix = "sqlite+aiosqlite:///./"
    if database_url.startswith(prefix):
        rel_path = database_url[len(prefix):]
        abs_path = os.path.abspath(os.path.join(BASE_DIR, rel_path))
        abs_path = abs_path.replace("\\", "/")
        return f"sqlite+aiosqlite:///{abs_path}"
    return database_url

settings = Settings()
settings.DATABASE_URL = _resolve_sqlite_url(settings.DATABASE_URL)
print(f"DEBUG: FINAL_DATABASE_URL={settings.DATABASE_URL}")
