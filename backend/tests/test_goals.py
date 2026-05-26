import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_create_and_fetch_goals(client: AsyncClient):
    """Test creating user goals and checking Mifflin-St Jeor calculator values."""
    # 1. Register user
    payload = {
        "email": "goals@example.com",
        "password": "Password123!",
        "name": "Goals User"
    }
    reg_response = await client.post("/api/auth/register", json=payload)
    token = reg_response.json()["data"]["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    
    # 2. Get goals (should return 404 since it's not configured yet)
    get_res = await client.get("/api/goals/", headers=headers)
    assert get_res.status_code == 404
    
    # 3. Post goal setup
    goal_payload = {
        "goal_type": "lose",
        "current_weight_kg": 90.0,
        "target_weight_kg": 80.0,
        "height_cm": 180.0,
        "age": 28,
        "gender": "male",
        "activity_level": "moderate",
        "weekly_pace_kg": 0.5
    }
    
    post_res = await client.post("/api/goals/", json=goal_payload, headers=headers)
    assert post_res.status_code == 201
    
    post_data = post_res.json()
    assert post_data["success"] is True
    
    goal_data = post_data["data"]
    assert goal_data["goal_type"] == "lose"
    assert goal_data["current_weight_kg"] == 90.0
    assert goal_data["target_weight_kg"] == 80.0
    
    # BMR calculation validation (Male: 10 * 90 + 6.25 * 180 - 5 * 28 + 5 = 900 + 1125 - 140 + 5 = 1890)
    # TDEE (Moderate: 1890 * 1.55 = 2929.5)
    # Calorie Adjustment for losing 0.5kg/week: 2929.5 - (0.5 * 7700 / 7) = 2929.5 - 550 = 2379.5
    # Daily Calories target should be rounded to ~2380 kcal
    assert abs(goal_data["daily_calorie_target"] - 2380) < 5
    
    # Macros:
    # Protein: 2.0g per kg of weight -> 2 * 90 = 180g
    assert goal_data["daily_protein_g"] == 180
    
    # Water: 35ml per kg of weight -> 35 * 90 = 3150ml
    assert goal_data["daily_water_ml"] == 3150
    
    # 4. Fetch goal again
    get_res2 = await client.get("/api/goals/", headers=headers)
    assert get_res2.status_code == 200
    assert get_res2.json()["data"]["daily_calorie_target"] == goal_data["daily_calorie_target"]
