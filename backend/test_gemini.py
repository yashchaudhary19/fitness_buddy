import asyncio
import os
import sys

# Add the current directory to sys.path so we can import app
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.services.ai import AIService

async def main():
    ai = AIService(db=None)
    ai.model = "gemini-2.0-flash"
    print("API Key configured:", ai.api_key is not None)
    print("API Key:", ai.api_key[:8] + "..." if ai.api_key else "None")
    print("Tested Model (forcing error model to check fallback):", ai.model)
    
    # 1x1 black PNG bytes
    dummy_png = b'\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15c4\x00\x00\x00\rIDATx\x9cc`\x00\x00\x00\x02\x00\x01H\xaf\xa4q\x00\x00\x00\x00IEND\xaeB`\x82'

    try:
        print("\n--- Testing image scan_meal_photo ---")
        res = await ai.scan_meal_photo(dummy_png, "image/png")
        print("Success! Scan result:")
        import pprint
        pprint.pprint(res)
    except Exception as e:
        print("Error during scan:")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(main())
