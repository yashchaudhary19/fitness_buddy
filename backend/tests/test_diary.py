import pytest
from datetime import date
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_diary_end_to_end(client: AsyncClient):
    """Test full diary flow including portion scaling, logging, water, and exercise calorie offset."""
    # 1. Register user
    payload = {
        "email": "diary@example.com",
        "password": "Password123!",
        "name": "Diary User"
    }
    reg_response = await client.post("/api/auth/register", json=payload)
    token = reg_response.json()["data"]["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    
    # 2. Configure Goals (2380 kcal target)
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
    await client.post("/api/goals/", json=goal_payload, headers=headers)
    
    # 3. Create Custom Food Item
    food_payload = {
        "name": "Peanut Butter",
        "brand": "Skippy",
        "calories_per_100g": 600.0,
        "carbs_per_100g": 20.0,
        "protein_per_100g": 30.0,
        "fat_per_100g": 50.0,
        "fiber_per_100g": 10.0,
        "sugar_per_100g": 5.0,
        "sodium_per_100g": 0.5,
        "saturated_fat_per_100g": 10.0
    }
    food_res = await client.post("/api/foods/custom", json=food_payload, headers=headers)
    assert food_res.status_code == 201
    food_id = food_res.json()["data"]["id"]
    
    # 4. Log portion of food (50g) in diary
    today = date.today().isoformat()
    log_payload = {
        "food_item_id": food_id,
        "meal_type": "breakfast",
        "serving_size_g": 50.0,
        "log_date": today
    }
    log_res = await client.post("/api/diary/entries", json=log_payload, headers=headers)
    assert log_res.status_code == 201
    
    log_data = log_res.json()["data"]
    # 50g of 600 kcal/100g should be 300 kcal
    assert log_data["calories"] == 300.0
    assert log_data["protein_g"] == 15.0
    assert log_data["fat_g"] == 25.0
    assert log_data["carbs_g"] == 10.0
    
    # 5. Fetch Diary Grouped entries
    diary_res = await client.get(f"/api/diary/?log_date={today}", headers=headers)
    assert diary_res.status_code == 200
    diary_data = diary_res.json()["data"]
    assert len(diary_data["meals"]["breakfast"]["entries"]) == 1
    assert diary_data["daily_totals"]["calories"] == 300.0
    
    # 6. Fetch Diary Summary
    summary_res = await client.get(f"/api/diary/summary?log_date={today}", headers=headers)
    assert summary_res.status_code == 200
    summary_data = summary_res.json()["data"]
    assert summary_data["calories_consumed"] == 300.0
    # Remaining = Goal (2380) - Consumed (300) = 2080
    assert summary_data["calories_remaining"] == 2080.0
    
    # 7. Log Water (500ml)
    water_payload = {
        "amount_ml": 500,
        "log_date": today
    }
    water_res = await client.post("/api/water/", json=water_payload, headers=headers)
    assert water_res.status_code == 201
    
    # 8. Log Exercise (300 kcal burned)
    exec_payload = {
        "exercise_name": "Jogging",
        "exercise_type": "cardio",
        "duration_minutes": 30.0,
        "calories_burned": 300.0,
        "log_date": today
    }
    exec_res = await client.post("/api/exercises/", json=exec_payload, headers=headers)
    assert exec_res.status_code == 201
    
    # 9. Verify updated Diary Summary incorporates water, exercise, and offsets remaining calories budget
    summary_res2 = await client.get(f"/api/diary/summary?log_date={today}", headers=headers)
    assert summary_res2.status_code == 200
    summary_data2 = summary_res2.json()["data"]
    
    # Water consumed should be 500
    assert summary_data2["water_consumed"] == 500.0
    # Exercise calories burned should be 300
    assert summary_data2["exercise_calories_burned"] == 300.0
    # Consumed (300) - Burned (300) = Net (0)
    assert summary_data2["net_calories"] == 0.0
    # Remaining = Goal (2380) - Net (0) = 2380
    assert summary_data2["calories_remaining"] == 2380.0
