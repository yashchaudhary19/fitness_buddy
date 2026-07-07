import asyncio
import httpx
from app.core.config import settings

async def main():
    api_key = settings.GEMINI_API_KEY
    if not api_key:
        print("GEMINI_API_KEY is missing from settings!")
        return

    url = f"https://generativelanguage.googleapis.com/v1beta/models?key={api_key}"
    async with httpx.AsyncClient(timeout=10.0) as client:
        try:
            response = await client.get(url)
            print(f"Status Code: {response.status_code}")
            if response.status_code == 200:
                models = response.json().get("models", [])
                print("\nAvailable Models:")
                for m in models:
                    name = m.get("name", "")
                    supported_methods = m.get("supportedGenerationMethods", [])
                    print(f"- {name} (Methods: {supported_methods})")
            else:
                print("Error Details:")
                print(response.text)
        except Exception as e:
            print(f"Request failed: {e}")

if __name__ == "__main__":
    asyncio.run(main())
