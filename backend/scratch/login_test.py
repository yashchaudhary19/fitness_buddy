import httpx
import json

async def test_login():
    url = "https://nutrivault.techotd.in/api/auth/login"
    data = {
        "email": "demo@gmail.com",
        "password": "pass1234"
    }
    
    print(f"Sending POST request to {url}...")
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.post(url, json=data)
            print(f"Status Code: {resp.status_code}")
            print("Response Headers:")
            for k, v in resp.headers.items():
                print(f"  {k}: {v}")
            print("Response Body:")
            print(resp.text)
    except Exception as e:
        print(f"Request failed: {e}")

import asyncio
asyncio.run(test_login())
