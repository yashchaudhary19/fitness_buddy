import asyncio
import httpx
from app.core.config import settings

async def test_model(model_name: str, api_key: str):
    print(f"\n--- Testing Model: {model_name} ---")
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model_name}:generateContent"
    payload = {
        "contents": [
            {
                "role": "user",
                "parts": [{"text": "Hello, respond with 'OK'."}]
            }
        ]
    }
    headers = {
        "Content-Type": "application/json",
        "x-goog-api-key": api_key
    }

    async with httpx.AsyncClient(timeout=10.0) as client:
        try:
            response = await client.post(url, headers=headers, json=payload)
            print(f"Status Code: {response.status_code}")
            if response.status_code == 200:
                print("Success!")
                print(response.json().get("candidates", [{}])[0].get("content", {}).get("parts", [{}])[0].get("text", ""))
            else:
                print("Error Details:")
                print(response.text)
        except Exception as e:
            print(f"Request failed: {e}")

async def main():
    api_key = settings.GEMINI_API_KEY
    if not api_key:
        print("GEMINI_API_KEY is missing from settings!")
        return
    
    print(f"Using API Key: {api_key[:8]}...")
    models = ["gemini-2.0-flash", "gemini-1.5-flash", "gemini-1.5-flash-latest", "gemini-2.5-flash"]
    for m in models:
        await test_model(m, api_key)

if __name__ == "__main__":
    asyncio.run(main())
