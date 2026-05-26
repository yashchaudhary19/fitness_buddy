import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_register_success(client: AsyncClient):
    """Test user registration."""
    payload = {
        "email": "test@example.com",
        "password": "Password123!",
        "name": "Test User"
    }
    response = await client.post("/api/auth/register", json=payload)
    assert response.status_code == 201
    
    res_data = response.json()
    assert res_data["success"] is True
    assert "access_token" in res_data["data"]
    assert "refresh_token" in res_data["data"]
    assert res_data["data"]["user"]["email"] == "test@example.com"
    assert res_data["data"]["user"]["name"] == "Test User"


@pytest.mark.asyncio
async def test_register_duplicate(client: AsyncClient):
    """Test that duplicate registrations fail with 400."""
    payload = {
        "email": "dup@example.com",
        "password": "Password123!",
        "name": "Dup User"
    }
    
    # First registration
    res1 = await client.post("/api/auth/register", json=payload)
    assert res1.status_code == 201
    
    # Duplicate registration
    res2 = await client.post("/api/auth/register", json=payload)
    assert res2.status_code == 400
    assert "already exists" in res2.json()["detail"]


@pytest.mark.asyncio
async def test_login_success(client: AsyncClient):
    """Test login with valid credentials."""
    # Register user
    payload = {
        "email": "login@example.com",
        "password": "Password123!",
        "name": "Login User"
    }
    await client.post("/api/auth/register", json=payload)
    
    # Login user
    login_payload = {
        "email": "login@example.com",
        "password": "Password123!"
    }
    response = await client.post("/api/auth/login", json=login_payload)
    assert response.status_code == 200
    
    res_data = response.json()
    assert res_data["success"] is True
    assert "access_token" in res_data["data"]
    assert res_data["data"]["user"]["email"] == "login@example.com"


@pytest.mark.asyncio
async def test_get_me(client: AsyncClient):
    """Test retrieving user profile context."""
    # Register
    payload = {
        "email": "me@example.com",
        "password": "Password123!",
        "name": "Me User"
    }
    reg_response = await client.post("/api/auth/register", json=payload)
    token = reg_response.json()["data"]["access_token"]
    
    # Retrieve profile
    headers = {"Authorization": f"Bearer {token}"}
    response = await client.get("/api/auth/me", headers=headers)
    assert response.status_code == 200
    
    res_data = response.json()
    assert res_data["success"] is True
    assert res_data["data"]["email"] == "me@example.com"
    assert res_data["data"]["name"] == "Me User"
