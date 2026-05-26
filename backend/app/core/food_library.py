"""
FOOD_LIBRARY — Curated nutrition database seed data.
Values are per 100g based on USDA FoodData Central (FDC) / USDA SR28 references.
All items have created_by=None (public/global) and source=FoodSource.API.
"""

FOOD_LIBRARY = [
    # ────────────────────────────────────────────
    # RAW MEATS & POULTRY
    # ────────────────────────────────────────────
    {"name": "Chicken Breast (Raw)", "brand": None, "calories_per_100g": 120.0, "protein_per_100g": 22.5, "carbs_per_100g": 0.0, "fat_per_100g": 2.6, "fiber_per_100g": 0.0, "sugar_per_100g": 0.0, "sodium_per_100g": 0.074, "saturated_fat_per_100g": 0.7},
    {"name": "Chicken Breast (Cooked, Grilled)", "brand": None, "calories_per_100g": 165.0, "protein_per_100g": 31.0, "carbs_per_100g": 0.0, "fat_per_100g": 3.6, "fiber_per_100g": 0.0, "sugar_per_100g": 0.0, "sodium_per_100g": 0.074, "saturated_fat_per_100g": 1.0},
    {"name": "Chicken Thigh (Raw)", "brand": None, "calories_per_100g": 177.0, "protein_per_100g": 18.0, "carbs_per_100g": 0.0, "fat_per_100g": 11.0, "fiber_per_100g": 0.0, "sugar_per_100g": 0.0, "sodium_per_100g": 0.079, "saturated_fat_per_100g": 3.0},
    {"name": "Chicken Drumstick (Raw)", "brand": None, "calories_per_100g": 170.0, "protein_per_100g": 18.7, "carbs_per_100g": 0.0, "fat_per_100g": 10.2, "fiber_per_100g": 0.0, "sugar_per_100g": 0.0, "sodium_per_100g": 0.082, "saturated_fat_per_100g": 2.8},
    {"name": "Chicken Wings (Raw)", "brand": None, "calories_per_100g": 203.0, "protein_per_100g": 18.3, "carbs_per_100g": 0.0, "fat_per_100g": 14.1, "fiber_per_100g": 0.0, "sugar_per_100g": 0.0, "sodium_per_100g": 0.082, "saturated_fat_per_100g": 3.9},
    {"name": "Ground Beef (80% Lean, Raw)", "brand": None, "calories_per_100g": 254.0, "protein_per_100g": 17.2, "carbs_per_100g": 0.0, "fat_per_100g": 20.0, "fiber_per_100g": 0.0, "sugar_per_100g": 0.0, "sodium_per_100g": 0.075, "saturated_fat_per_100g": 7.7},
    {"name": "Ground Beef (95% Lean, Raw)", "brand": None, "calories_per_100g": 137.0, "protein_per_100g": 21.4, "carbs_per_100g": 0.0, "fat_per_100g": 5.5, "fiber_per_100g": 0.0, "sugar_per_100g": 0.0, "sodium_per_100g": 0.074, "saturated_fat_per_100g": 2.2},
    {"name": "Beef Steak (Sirloin, Raw)", "brand": None, "calories_per_100g": 207.0, "protein_per_100g": 21.7, "carbs_per_100g": 0.0, "fat_per_100g": 13.0, "fiber_per_100g": 0.0, "sugar_per_100g": 0.0, "sodium_per_100g": 0.063, "saturated_fat_per_100g": 5.0},
    {"name": "Pork Tenderloin (Raw)", "brand": None, "calories_per_100g": 122.0, "protein_per_100g": 21.3, "carbs_per_100g": 0.0, "fat_per_100g": 3.5, "fiber_per_100g": 0.0, "sugar_per_100g": 0.0, "sodium_per_100g": 0.063, "saturated_fat_per_100g": 1.2},
    {"name": "Pork Chops (Raw)", "brand": None, "calories_per_100g": 250.0, "protein_per_100g": 16.9, "carbs_per_100g": 0.0, "fat_per_100g": 20.0, "fiber_per_100g": 0.0, "sugar_per_100g": 0.0, "sodium_per_100g": 0.065, "saturated_fat_per_100g": 7.1},
    {"name": "Lamb (Leg, Raw)", "brand": None, "calories_per_100g": 206.0, "protein_per_100g": 20.3, "carbs_per_100g": 0.0, "fat_per_100g": 13.5, "fiber_per_100g": 0.0, "sugar_per_100g": 0.0, "sodium_per_100g": 0.072, "saturated_fat_per_100g": 5.9},
    {"name": "Turkey Breast (Raw)", "brand": None, "calories_per_100g": 104.0, "protein_per_100g": 21.9, "carbs_per_100g": 0.0, "fat_per_100g": 1.7, "fiber_per_100g": 0.0, "sugar_per_100g": 0.0, "sodium_per_100g": 0.063, "saturated_fat_per_100g": 0.5},
    {"name": "Mutton (Raw)", "brand": None, "calories_per_100g": 294.0, "protein_per_100g": 16.6, "carbs_per_100g": 0.0, "fat_per_100g": 25.1, "fiber_per_100g": 0.0, "sugar_per_100g": 0.0, "sodium_per_100g": 0.072, "saturated_fat_per_100g": 11.5},

    # ────────────────────────────────────────────
    # SEAFOOD & FISH
    # ────────────────────────────────────────────
    {"name": "Salmon (Atlantic, Raw)", "brand": None, "calories_per_100g": 208.0, "protein_per_100g": 20.4, "carbs_per_100g": 0.0, "fat_per_100g": 13.4, "fiber_per_100g": 0.0, "sugar_per_100g": 0.0, "sodium_per_100g": 0.059, "saturated_fat_per_100g": 3.1},
    {"name": "Tuna (Yellowfin, Raw)", "brand": None, "calories_per_100g": 109.0, "protein_per_100g": 24.4, "carbs_per_100g": 0.0, "fat_per_100g": 1.0, "fiber_per_100g": 0.0, "sugar_per_100g": 0.0, "sodium_per_100g": 0.047, "saturated_fat_per_100g": 0.3},
    {"name": "Tuna (Canned in Water)", "brand": None, "calories_per_100g": 116.0, "protein_per_100g": 25.5, "carbs_per_100g": 0.0, "fat_per_100g": 0.8, "fiber_per_100g": 0.0, "sugar_per_100g": 0.0, "sodium_per_100g": 0.375, "saturated_fat_per_100g": 0.2},
    {"name": "Cod (Raw)", "brand": None, "calories_per_100g": 82.0, "protein_per_100g": 17.8, "carbs_per_100g": 0.0, "fat_per_100g": 0.7, "fiber_per_100g": 0.0, "sugar_per_100g": 0.0, "sodium_per_100g": 0.054, "saturated_fat_per_100g": 0.1},
    {"name": "Shrimp (Raw)", "brand": None, "calories_per_100g": 85.0, "protein_per_100g": 20.3, "carbs_per_100g": 0.0, "fat_per_100g": 0.9, "fiber_per_100g": 0.0, "sugar_per_100g": 0.0, "sodium_per_100g": 0.119, "saturated_fat_per_100g": 0.2},
    {"name": "Tilapia (Raw)", "brand": None, "calories_per_100g": 96.0, "protein_per_100g": 20.1, "carbs_per_100g": 0.0, "fat_per_100g": 1.7, "fiber_per_100g": 0.0, "sugar_per_100g": 0.0, "sodium_per_100g": 0.052, "saturated_fat_per_100g": 0.6},
    {"name": "Rohu Fish (Raw)", "brand": None, "calories_per_100g": 97.0, "protein_per_100g": 16.0, "carbs_per_100g": 0.0, "fat_per_100g": 3.4, "fiber_per_100g": 0.0, "sugar_per_100g": 0.0, "sodium_per_100g": 0.072, "saturated_fat_per_100g": 0.9},
    {"name": "Sardines (Canned in Oil)", "brand": None, "calories_per_100g": 208.0, "protein_per_100g": 24.6, "carbs_per_100g": 0.0, "fat_per_100g": 11.5, "fiber_per_100g": 0.0, "sugar_per_100g": 0.0, "sodium_per_100g": 0.505, "saturated_fat_per_100g": 1.5},

    # ────────────────────────────────────────────
    # EGGS & DAIRY
    # ────────────────────────────────────────────
    {"name": "Whole Egg (Raw)", "brand": None, "calories_per_100g": 155.0, "protein_per_100g": 13.0, "carbs_per_100g": 1.1, "fat_per_100g": 10.6, "fiber_per_100g": 0.0, "sugar_per_100g": 1.1, "sodium_per_100g": 0.124, "saturated_fat_per_100g": 3.1},
    {"name": "Egg White (Raw)", "brand": None, "calories_per_100g": 52.0, "protein_per_100g": 10.9, "carbs_per_100g": 0.7, "fat_per_100g": 0.2, "fiber_per_100g": 0.0, "sugar_per_100g": 0.7, "sodium_per_100g": 0.166, "saturated_fat_per_100g": 0.0},
    {"name": "Egg Yolk (Raw)", "brand": None, "calories_per_100g": 322.0, "protein_per_100g": 15.9, "carbs_per_100g": 3.6, "fat_per_100g": 26.5, "fiber_per_100g": 0.0, "sugar_per_100g": 0.6, "sodium_per_100g": 0.048, "saturated_fat_per_100g": 8.0},
    {"name": "Whole Milk (3.25% Fat)", "brand": None, "calories_per_100g": 61.0, "protein_per_100g": 3.2, "carbs_per_100g": 4.8, "fat_per_100g": 3.3, "fiber_per_100g": 0.0, "sugar_per_100g": 5.0, "sodium_per_100g": 0.043, "saturated_fat_per_100g": 1.9},
    {"name": "Skimmed Milk (0.1% Fat)", "brand": None, "calories_per_100g": 35.0, "protein_per_100g": 3.4, "carbs_per_100g": 5.1, "fat_per_100g": 0.1, "fiber_per_100g": 0.0, "sugar_per_100g": 5.1, "sodium_per_100g": 0.044, "saturated_fat_per_100g": 0.1},
    {"name": "Greek Yogurt (Full Fat)", "brand": None, "calories_per_100g": 97.0, "protein_per_100g": 9.0, "carbs_per_100g": 3.6, "fat_per_100g": 5.0, "fiber_per_100g": 0.0, "sugar_per_100g": 3.2, "sodium_per_100g": 0.036, "saturated_fat_per_100g": 2.9},
    {"name": "Greek Yogurt (0% Fat)", "brand": None, "calories_per_100g": 59.0, "protein_per_100g": 10.2, "carbs_per_100g": 3.6, "fat_per_100g": 0.4, "fiber_per_100g": 0.0, "sugar_per_100g": 3.2, "sodium_per_100g": 0.047, "saturated_fat_per_100g": 0.1},
    {"name": "Curd / Dahi (Plain)", "brand": None, "calories_per_100g": 61.0, "protein_per_100g": 3.5, "carbs_per_100g": 4.7, "fat_per_100g": 3.3, "fiber_per_100g": 0.0, "sugar_per_100g": 4.7, "sodium_per_100g": 0.046, "saturated_fat_per_100g": 2.1},
    {"name": "Paneer (Cottage Cheese Indian)", "brand": None, "calories_per_100g": 296.0, "protein_per_100g": 18.3, "carbs_per_100g": 1.2, "fat_per_100g": 24.1, "fiber_per_100g": 0.0, "sugar_per_100g": 1.2, "sodium_per_100g": 0.028, "saturated_fat_per_100g": 15.0},
    {"name": "Cheddar Cheese", "brand": None, "calories_per_100g": 403.0, "protein_per_100g": 24.9, "carbs_per_100g": 1.3, "fat_per_100g": 33.1, "fiber_per_100g": 0.0, "sugar_per_100g": 0.5, "sodium_per_100g": 0.621, "saturated_fat_per_100g": 21.1},
    {"name": "Mozzarella Cheese", "brand": None, "calories_per_100g": 280.0, "protein_per_100g": 19.4, "carbs_per_100g": 3.6, "fat_per_100g": 17.1, "fiber_per_100g": 0.0, "sugar_per_100g": 1.0, "sodium_per_100g": 0.627, "saturated_fat_per_100g": 10.9},
    {"name": "Butter (Salted)", "brand": None, "calories_per_100g": 717.0, "protein_per_100g": 0.9, "carbs_per_100g": 0.1, "fat_per_100g": 81.1, "fiber_per_100g": 0.0, "sugar_per_100g": 0.1, "sodium_per_100g": 0.714, "saturated_fat_per_100g": 51.4},
    {"name": "Ghee (Clarified Butter)", "brand": None, "calories_per_100g": 900.0, "protein_per_100g": 0.0, "carbs_per_100g": 0.0, "fat_per_100g": 100.0, "fiber_per_100g": 0.0, "sugar_per_100g": 0.0, "sodium_per_100g": 0.002, "saturated_fat_per_100g": 62.0},
    {"name": "Whey Protein Powder", "brand": None, "calories_per_100g": 359.0, "protein_per_100g": 75.0, "carbs_per_100g": 10.0, "fat_per_100g": 3.7, "fiber_per_100g": 0.0, "sugar_per_100g": 5.0, "sodium_per_100g": 0.400, "saturated_fat_per_100g": 2.3},

    # ────────────────────────────────────────────
    # LEGUMES & PULSES
    # ────────────────────────────────────────────
    {"name": "Chickpeas / Chana (Cooked)", "brand": None, "calories_per_100g": 164.0, "protein_per_100g": 8.9, "carbs_per_100g": 27.4, "fat_per_100g": 2.6, "fiber_per_100g": 7.6, "sugar_per_100g": 4.8, "sodium_per_100g": 0.024, "saturated_fat_per_100g": 0.3},
    {"name": "Lentils / Masoor Dal (Cooked)", "brand": None, "calories_per_100g": 116.0, "protein_per_100g": 9.0, "carbs_per_100g": 20.1, "fat_per_100g": 0.4, "fiber_per_100g": 7.9, "sugar_per_100g": 1.8, "sodium_per_100g": 0.002, "saturated_fat_per_100g": 0.1},
    {"name": "Toor Dal (Split Pigeon Peas, Cooked)", "brand": None, "calories_per_100g": 127.0, "protein_per_100g": 7.2, "carbs_per_100g": 22.5, "fat_per_100g": 0.4, "fiber_per_100g": 6.2, "sugar_per_100g": 0.0, "sodium_per_100g": 0.002, "saturated_fat_per_100g": 0.1},
    {"name": "Moong Dal (Yellow, Cooked)", "brand": None, "calories_per_100g": 105.0, "protein_per_100g": 7.0, "carbs_per_100g": 19.2, "fat_per_100g": 0.4, "fiber_per_100g": 7.6, "sugar_per_100g": 0.0, "sodium_per_100g": 0.002, "saturated_fat_per_100g": 0.1},
    {"name": "Urad Dal (Black Gram, Cooked)", "brand": None, "calories_per_100g": 118.0, "protein_per_100g": 7.6, "carbs_per_100g": 20.6, "fat_per_100g": 0.6, "fiber_per_100g": 6.8, "sugar_per_100g": 0.0, "sodium_per_100g": 0.002, "saturated_fat_per_100g": 0.1},
    {"name": "Rajma (Kidney Beans, Cooked)", "brand": None, "calories_per_100g": 127.0, "protein_per_100g": 8.7, "carbs_per_100g": 22.8, "fat_per_100g": 0.5, "fiber_per_100g": 6.4, "sugar_per_100g": 0.3, "sodium_per_100g": 0.002, "saturated_fat_per_100g": 0.1},
    {"name": "Black Beans (Cooked)", "brand": None, "calories_per_100g": 132.0, "protein_per_100g": 8.9, "carbs_per_100g": 23.7, "fat_per_100g": 0.5, "fiber_per_100g": 8.7, "sugar_per_100g": 0.3, "sodium_per_100g": 0.002, "saturated_fat_per_100g": 0.1},
    {"name": "Soybean (Cooked)", "brand": None, "calories_per_100g": 173.0, "protein_per_100g": 16.6, "carbs_per_100g": 9.9, "fat_per_100g": 9.0, "fiber_per_100g": 6.0, "sugar_per_100g": 3.0, "sodium_per_100g": 0.001, "saturated_fat_per_100g": 1.3},
    {"name": "Tofu (Firm)", "brand": None, "calories_per_100g": 76.0, "protein_per_100g": 8.0, "carbs_per_100g": 1.9, "fat_per_100g": 4.8, "fiber_per_100g": 0.3, "sugar_per_100g": 0.6, "sodium_per_100g": 0.007, "saturated_fat_per_100g": 0.7},
    {"name": "Edamame (Cooked)", "brand": None, "calories_per_100g": 121.0, "protein_per_100g": 11.9, "carbs_per_100g": 8.9, "fat_per_100g": 5.2, "fiber_per_100g": 5.2, "sugar_per_100g": 2.2, "sodium_per_100g": 0.006, "saturated_fat_per_100g": 0.6},

    # ────────────────────────────────────────────
    # GRAINS & CEREALS
    # ────────────────────────────────────────────
    {"name": "White Rice (Cooked)", "brand": None, "calories_per_100g": 130.0, "protein_per_100g": 2.7, "carbs_per_100g": 28.2, "fat_per_100g": 0.3, "fiber_per_100g": 0.4, "sugar_per_100g": 0.1, "sodium_per_100g": 0.001, "saturated_fat_per_100g": 0.1},
    {"name": "Brown Rice (Cooked)", "brand": None, "calories_per_100g": 123.0, "protein_per_100g": 2.7, "carbs_per_100g": 25.6, "fat_per_100g": 0.9, "fiber_per_100g": 1.8, "sugar_per_100g": 0.2, "sodium_per_100g": 0.001, "saturated_fat_per_100g": 0.2},
    {"name": "Basmati Rice (Cooked)", "brand": None, "calories_per_100g": 130.0, "protein_per_100g": 2.7, "carbs_per_100g": 27.5, "fat_per_100g": 0.4, "fiber_per_100g": 0.4, "sugar_per_100g": 0.1, "sodium_per_100g": 0.001, "saturated_fat_per_100g": 0.1},
    {"name": "Rolled Oats (Dry)", "brand": None, "calories_per_100g": 389.0, "protein_per_100g": 16.9, "carbs_per_100g": 66.3, "fat_per_100g": 6.9, "fiber_per_100g": 10.6, "sugar_per_100g": 0.0, "sodium_per_100g": 0.002, "saturated_fat_per_100g": 1.2},
    {"name": "Oatmeal / Porridge (Cooked)", "brand": None, "calories_per_100g": 71.0, "protein_per_100g": 2.5, "carbs_per_100g": 12.0, "fat_per_100g": 1.5, "fiber_per_100g": 1.7, "sugar_per_100g": 0.0, "sodium_per_100g": 0.049, "saturated_fat_per_100g": 0.3},
    {"name": "Whole Wheat Flour (Atta)", "brand": None, "calories_per_100g": 340.0, "protein_per_100g": 13.2, "carbs_per_100g": 72.0, "fat_per_100g": 2.5, "fiber_per_100g": 10.7, "sugar_per_100g": 0.4, "sodium_per_100g": 0.002, "saturated_fat_per_100g": 0.4},
    {"name": "Whole Wheat Bread", "brand": None, "calories_per_100g": 247.0, "protein_per_100g": 9.0, "carbs_per_100g": 41.0, "fat_per_100g": 4.2, "fiber_per_100g": 6.0, "sugar_per_100g": 5.0, "sodium_per_100g": 0.477, "saturated_fat_per_100g": 0.7},
    {"name": "White Bread", "brand": None, "calories_per_100g": 265.0, "protein_per_100g": 9.0, "carbs_per_100g": 49.0, "fat_per_100g": 3.2, "fiber_per_100g": 2.4, "sugar_per_100g": 5.0, "sodium_per_100g": 0.477, "saturated_fat_per_100g": 0.7},
    {"name": "Roti / Chapati (Plain)", "brand": None, "calories_per_100g": 297.0, "protein_per_100g": 9.8, "carbs_per_100g": 59.8, "fat_per_100g": 3.7, "fiber_per_100g": 3.7, "sugar_per_100g": 0.5, "sodium_per_100g": 0.316, "saturated_fat_per_100g": 0.6},
    {"name": "Naan Bread", "brand": None, "calories_per_100g": 317.0, "protein_per_100g": 9.1, "carbs_per_100g": 52.7, "fat_per_100g": 7.8, "fiber_per_100g": 2.5, "sugar_per_100g": 2.3, "sodium_per_100g": 0.533, "saturated_fat_per_100g": 2.7},
    {"name": "Pasta (Cooked, Plain)", "brand": None, "calories_per_100g": 158.0, "protein_per_100g": 5.8, "carbs_per_100g": 30.9, "fat_per_100g": 0.9, "fiber_per_100g": 1.8, "sugar_per_100g": 0.6, "sodium_per_100g": 0.001, "saturated_fat_per_100g": 0.2},
    {"name": "Quinoa (Cooked)", "brand": None, "calories_per_100g": 120.0, "protein_per_100g": 4.4, "carbs_per_100g": 21.3, "fat_per_100g": 1.9, "fiber_per_100g": 2.8, "sugar_per_100g": 0.9, "sodium_per_100g": 0.007, "saturated_fat_per_100g": 0.2},
    {"name": "Cornmeal / Makki ka Atta (Dry)", "brand": None, "calories_per_100g": 362.0, "protein_per_100g": 8.1, "carbs_per_100g": 76.9, "fat_per_100g": 3.6, "fiber_per_100g": 7.3, "sugar_per_100g": 0.6, "sodium_per_100g": 0.035, "saturated_fat_per_100g": 0.5},
    {"name": "Semolina / Sooji (Dry)", "brand": None, "calories_per_100g": 360.0, "protein_per_100g": 12.7, "carbs_per_100g": 72.8, "fat_per_100g": 1.1, "fiber_per_100g": 3.9, "sugar_per_100g": 0.6, "sodium_per_100g": 0.001, "saturated_fat_per_100g": 0.2},
    {"name": "Poha (Flattened Rice)", "brand": None, "calories_per_100g": 357.0, "protein_per_100g": 6.0, "carbs_per_100g": 78.0, "fat_per_100g": 1.7, "fiber_per_100g": 1.3, "sugar_per_100g": 0.5, "sodium_per_100g": 0.010, "saturated_fat_per_100g": 0.4},
    {"name": "Upma (Semolina, Cooked)", "brand": None, "calories_per_100g": 135.0, "protein_per_100g": 3.8, "carbs_per_100g": 21.0, "fat_per_100g": 4.5, "fiber_per_100g": 1.5, "sugar_per_100g": 1.0, "sodium_per_100g": 0.240, "saturated_fat_per_100g": 0.8},

    # ────────────────────────────────────────────
    # FRUITS
    # ────────────────────────────────────────────
    {"name": "Apple (Raw)", "brand": None, "calories_per_100g": 52.0, "protein_per_100g": 0.3, "carbs_per_100g": 14.0, "fat_per_100g": 0.2, "fiber_per_100g": 2.4, "sugar_per_100g": 10.4, "sodium_per_100g": 0.001, "saturated_fat_per_100g": 0.0},
    {"name": "Banana (Raw)", "brand": None, "calories_per_100g": 89.0, "protein_per_100g": 1.1, "carbs_per_100g": 23.0, "fat_per_100g": 0.3, "fiber_per_100g": 2.6, "sugar_per_100g": 12.2, "sodium_per_100g": 0.001, "saturated_fat_per_100g": 0.1},
    {"name": "Orange (Raw)", "brand": None, "calories_per_100g": 47.0, "protein_per_100g": 0.9, "carbs_per_100g": 11.8, "fat_per_100g": 0.1, "fiber_per_100g": 2.4, "sugar_per_100g": 9.4, "sodium_per_100g": 0.0, "saturated_fat_per_100g": 0.0},
    {"name": "Mango (Raw)", "brand": None, "calories_per_100g": 60.0, "protein_per_100g": 0.8, "carbs_per_100g": 15.0, "fat_per_100g": 0.4, "fiber_per_100g": 1.6, "sugar_per_100g": 13.7, "sodium_per_100g": 0.001, "saturated_fat_per_100g": 0.1},
    {"name": "Grapes (Raw)", "brand": None, "calories_per_100g": 69.0, "protein_per_100g": 0.7, "carbs_per_100g": 18.1, "fat_per_100g": 0.2, "fiber_per_100g": 0.9, "sugar_per_100g": 15.5, "sodium_per_100g": 0.002, "saturated_fat_per_100g": 0.1},
    {"name": "Strawberry (Raw)", "brand": None, "calories_per_100g": 33.0, "protein_per_100g": 0.7, "carbs_per_100g": 7.7, "fat_per_100g": 0.3, "fiber_per_100g": 2.0, "sugar_per_100g": 4.9, "sodium_per_100g": 0.001, "saturated_fat_per_100g": 0.0},
    {"name": "Watermelon (Raw)", "brand": None, "calories_per_100g": 30.0, "protein_per_100g": 0.6, "carbs_per_100g": 7.6, "fat_per_100g": 0.2, "fiber_per_100g": 0.4, "sugar_per_100g": 6.2, "sodium_per_100g": 0.001, "saturated_fat_per_100g": 0.0},
    {"name": "Papaya (Raw)", "brand": None, "calories_per_100g": 43.0, "protein_per_100g": 0.5, "carbs_per_100g": 10.8, "fat_per_100g": 0.3, "fiber_per_100g": 1.7, "sugar_per_100g": 7.8, "sodium_per_100g": 0.008, "saturated_fat_per_100g": 0.1},
    {"name": "Guava (Raw)", "brand": None, "calories_per_100g": 68.0, "protein_per_100g": 2.6, "carbs_per_100g": 14.3, "fat_per_100g": 1.0, "fiber_per_100g": 5.4, "sugar_per_100g": 8.9, "sodium_per_100g": 0.002, "saturated_fat_per_100g": 0.3},
    {"name": "Pineapple (Raw)", "brand": None, "calories_per_100g": 50.0, "protein_per_100g": 0.5, "carbs_per_100g": 13.1, "fat_per_100g": 0.1, "fiber_per_100g": 1.4, "sugar_per_100g": 9.9, "sodium_per_100g": 0.001, "saturated_fat_per_100g": 0.0},
    {"name": "Pomegranate (Raw)", "brand": None, "calories_per_100g": 83.0, "protein_per_100g": 1.7, "carbs_per_100g": 18.7, "fat_per_100g": 1.2, "fiber_per_100g": 4.0, "sugar_per_100g": 13.7, "sodium_per_100g": 0.003, "saturated_fat_per_100g": 0.1},
    {"name": "Kiwi (Raw)", "brand": None, "calories_per_100g": 61.0, "protein_per_100g": 1.1, "carbs_per_100g": 14.7, "fat_per_100g": 0.5, "fiber_per_100g": 3.0, "sugar_per_100g": 9.0, "sodium_per_100g": 0.003, "saturated_fat_per_100g": 0.0},
    {"name": "Blueberries (Raw)", "brand": None, "calories_per_100g": 57.0, "protein_per_100g": 0.7, "carbs_per_100g": 14.5, "fat_per_100g": 0.3, "fiber_per_100g": 2.4, "sugar_per_100g": 10.0, "sodium_per_100g": 0.001, "saturated_fat_per_100g": 0.0},
    {"name": "Avocado (Raw)", "brand": None, "calories_per_100g": 160.0, "protein_per_100g": 2.0, "carbs_per_100g": 8.5, "fat_per_100g": 14.7, "fiber_per_100g": 6.7, "sugar_per_100g": 0.7, "sodium_per_100g": 0.007, "saturated_fat_per_100g": 2.1},
    {"name": "Dates (Dried)", "brand": None, "calories_per_100g": 277.0, "protein_per_100g": 1.8, "carbs_per_100g": 75.0, "fat_per_100g": 0.2, "fiber_per_100g": 6.7, "sugar_per_100g": 63.4, "sodium_per_100g": 0.002, "saturated_fat_per_100g": 0.0},
    {"name": "Raisins (Dry)", "brand": None, "calories_per_100g": 299.0, "protein_per_100g": 3.1, "carbs_per_100g": 79.2, "fat_per_100g": 0.5, "fiber_per_100g": 3.7, "sugar_per_100g": 59.2, "sodium_per_100g": 0.011, "saturated_fat_per_100g": 0.2},

    # ────────────────────────────────────────────
    # VEGETABLES
    # ────────────────────────────────────────────
    {"name": "Broccoli (Raw)", "brand": None, "calories_per_100g": 34.0, "protein_per_100g": 2.8, "carbs_per_100g": 6.6, "fat_per_100g": 0.4, "fiber_per_100g": 2.6, "sugar_per_100g": 1.7, "sodium_per_100g": 0.033, "saturated_fat_per_100g": 0.0},
    {"name": "Spinach (Raw)", "brand": None, "calories_per_100g": 23.0, "protein_per_100g": 2.9, "carbs_per_100g": 3.6, "fat_per_100g": 0.4, "fiber_per_100g": 2.2, "sugar_per_100g": 0.4, "sodium_per_100g": 0.079, "saturated_fat_per_100g": 0.1},
    {"name": "Kale (Raw)", "brand": None, "calories_per_100g": 49.0, "protein_per_100g": 4.3, "carbs_per_100g": 8.8, "fat_per_100g": 0.9, "fiber_per_100g": 3.6, "sugar_per_100g": 2.3, "sodium_per_100g": 0.038, "saturated_fat_per_100g": 0.1},
    {"name": "Carrot (Raw)", "brand": None, "calories_per_100g": 41.0, "protein_per_100g": 0.9, "carbs_per_100g": 9.6, "fat_per_100g": 0.2, "fiber_per_100g": 2.8, "sugar_per_100g": 4.7, "sodium_per_100g": 0.069, "saturated_fat_per_100g": 0.0},
    {"name": "Tomato (Raw)", "brand": None, "calories_per_100g": 18.0, "protein_per_100g": 0.9, "carbs_per_100g": 3.9, "fat_per_100g": 0.2, "fiber_per_100g": 1.2, "sugar_per_100g": 2.6, "sodium_per_100g": 0.005, "saturated_fat_per_100g": 0.0},
    {"name": "Onion (Raw)", "brand": None, "calories_per_100g": 40.0, "protein_per_100g": 1.1, "carbs_per_100g": 9.3, "fat_per_100g": 0.1, "fiber_per_100g": 1.7, "sugar_per_100g": 4.2, "sodium_per_100g": 0.004, "saturated_fat_per_100g": 0.0},
    {"name": "Garlic (Raw)", "brand": None, "calories_per_100g": 149.0, "protein_per_100g": 6.4, "carbs_per_100g": 33.1, "fat_per_100g": 0.5, "fiber_per_100g": 2.1, "sugar_per_100g": 1.0, "sodium_per_100g": 0.017, "saturated_fat_per_100g": 0.1},
    {"name": "Ginger (Raw)", "brand": None, "calories_per_100g": 80.0, "protein_per_100g": 1.8, "carbs_per_100g": 17.8, "fat_per_100g": 0.8, "fiber_per_100g": 2.0, "sugar_per_100g": 1.7, "sodium_per_100g": 0.013, "saturated_fat_per_100g": 0.2},
    {"name": "Potato (Raw)", "brand": None, "calories_per_100g": 77.0, "protein_per_100g": 2.0, "carbs_per_100g": 17.5, "fat_per_100g": 0.1, "fiber_per_100g": 2.2, "sugar_per_100g": 0.8, "sodium_per_100g": 0.006, "saturated_fat_per_100g": 0.0},
    {"name": "Sweet Potato (Raw)", "brand": None, "calories_per_100g": 86.0, "protein_per_100g": 1.6, "carbs_per_100g": 20.1, "fat_per_100g": 0.1, "fiber_per_100g": 3.0, "sugar_per_100g": 4.2, "sodium_per_100g": 0.055, "saturated_fat_per_100g": 0.0},
    {"name": "Bell Pepper (Red, Raw)", "brand": None, "calories_per_100g": 31.0, "protein_per_100g": 1.0, "carbs_per_100g": 6.0, "fat_per_100g": 0.3, "fiber_per_100g": 2.1, "sugar_per_100g": 4.2, "sodium_per_100g": 0.004, "saturated_fat_per_100g": 0.0},
    {"name": "Bell Pepper (Green, Raw)", "brand": None, "calories_per_100g": 20.0, "protein_per_100g": 0.9, "carbs_per_100g": 4.6, "fat_per_100g": 0.2, "fiber_per_100g": 1.7, "sugar_per_100g": 2.4, "sodium_per_100g": 0.004, "saturated_fat_per_100g": 0.0},
    {"name": "Cucumber (Raw)", "brand": None, "calories_per_100g": 15.0, "protein_per_100g": 0.7, "carbs_per_100g": 3.6, "fat_per_100g": 0.1, "fiber_per_100g": 0.5, "sugar_per_100g": 1.7, "sodium_per_100g": 0.002, "saturated_fat_per_100g": 0.0},
    {"name": "Cabbage (Raw)", "brand": None, "calories_per_100g": 25.0, "protein_per_100g": 1.3, "carbs_per_100g": 5.8, "fat_per_100g": 0.1, "fiber_per_100g": 2.5, "sugar_per_100g": 3.2, "sodium_per_100g": 0.018, "saturated_fat_per_100g": 0.0},
    {"name": "Cauliflower (Raw)", "brand": None, "calories_per_100g": 25.0, "protein_per_100g": 1.9, "carbs_per_100g": 5.0, "fat_per_100g": 0.3, "fiber_per_100g": 2.0, "sugar_per_100g": 1.9, "sodium_per_100g": 0.030, "saturated_fat_per_100g": 0.0},
    {"name": "Peas (Raw)", "brand": None, "calories_per_100g": 81.0, "protein_per_100g": 5.4, "carbs_per_100g": 14.5, "fat_per_100g": 0.4, "fiber_per_100g": 5.1, "sugar_per_100g": 5.7, "sodium_per_100g": 0.005, "saturated_fat_per_100g": 0.1},
    {"name": "Corn / Maize (Raw)", "brand": None, "calories_per_100g": 86.0, "protein_per_100g": 3.2, "carbs_per_100g": 19.0, "fat_per_100g": 1.2, "fiber_per_100g": 2.7, "sugar_per_100g": 3.2, "sodium_per_100g": 0.015, "saturated_fat_per_100g": 0.2},
    {"name": "Beetroot (Raw)", "brand": None, "calories_per_100g": 43.0, "protein_per_100g": 1.6, "carbs_per_100g": 9.6, "fat_per_100g": 0.2, "fiber_per_100g": 2.8, "sugar_per_100g": 6.8, "sodium_per_100g": 0.078, "saturated_fat_per_100g": 0.0},
    {"name": "Mushroom (Raw)", "brand": None, "calories_per_100g": 22.0, "protein_per_100g": 3.1, "carbs_per_100g": 3.3, "fat_per_100g": 0.3, "fiber_per_100g": 1.0, "sugar_per_100g": 2.0, "sodium_per_100g": 0.005, "saturated_fat_per_100g": 0.0},
    {"name": "Bottle Gourd / Lauki (Raw)", "brand": None, "calories_per_100g": 14.0, "protein_per_100g": 0.6, "carbs_per_100g": 3.4, "fat_per_100g": 0.0, "fiber_per_100g": 0.5, "sugar_per_100g": 0.0, "sodium_per_100g": 0.002, "saturated_fat_per_100g": 0.0},
    {"name": "Bitter Gourd / Karela (Raw)", "brand": None, "calories_per_100g": 17.0, "protein_per_100g": 1.0, "carbs_per_100g": 3.7, "fat_per_100g": 0.2, "fiber_per_100g": 2.8, "sugar_per_100g": 0.0, "sodium_per_100g": 0.005, "saturated_fat_per_100g": 0.0},
    {"name": "Okra / Bhindi (Raw)", "brand": None, "calories_per_100g": 33.0, "protein_per_100g": 1.9, "carbs_per_100g": 7.5, "fat_per_100g": 0.2, "fiber_per_100g": 3.2, "sugar_per_100g": 1.5, "sodium_per_100g": 0.007, "saturated_fat_per_100g": 0.0},
    {"name": "Eggplant / Brinjal (Raw)", "brand": None, "calories_per_100g": 25.0, "protein_per_100g": 1.0, "carbs_per_100g": 5.9, "fat_per_100g": 0.2, "fiber_per_100g": 3.0, "sugar_per_100g": 3.5, "sodium_per_100g": 0.002, "saturated_fat_per_100g": 0.0},
    {"name": "Lettuce (Raw)", "brand": None, "calories_per_100g": 15.0, "protein_per_100g": 1.4, "carbs_per_100g": 2.9, "fat_per_100g": 0.2, "fiber_per_100g": 1.3, "sugar_per_100g": 1.2, "sodium_per_100g": 0.028, "saturated_fat_per_100g": 0.0},

    # ────────────────────────────────────────────
    # NUTS & SEEDS
    # ────────────────────────────────────────────
    {"name": "Almonds (Raw)", "brand": None, "calories_per_100g": 579.0, "protein_per_100g": 21.2, "carbs_per_100g": 21.6, "fat_per_100g": 49.9, "fiber_per_100g": 12.5, "sugar_per_100g": 4.4, "sodium_per_100g": 0.001, "saturated_fat_per_100g": 3.8},
    {"name": "Walnuts (Raw)", "brand": None, "calories_per_100g": 654.0, "protein_per_100g": 15.2, "carbs_per_100g": 13.7, "fat_per_100g": 65.2, "fiber_per_100g": 6.7, "sugar_per_100g": 2.6, "sodium_per_100g": 0.002, "saturated_fat_per_100g": 6.1},
    {"name": "Cashews (Raw)", "brand": None, "calories_per_100g": 553.0, "protein_per_100g": 18.2, "carbs_per_100g": 30.2, "fat_per_100g": 43.9, "fiber_per_100g": 3.3, "sugar_per_100g": 5.9, "sodium_per_100g": 0.012, "saturated_fat_per_100g": 7.8},
    {"name": "Peanuts (Raw)", "brand": None, "calories_per_100g": 567.0, "protein_per_100g": 25.8, "carbs_per_100g": 16.1, "fat_per_100g": 49.2, "fiber_per_100g": 8.5, "sugar_per_100g": 4.7, "sodium_per_100g": 0.018, "saturated_fat_per_100g": 6.8},
    {"name": "Peanut Butter (Smooth)", "brand": None, "calories_per_100g": 588.0, "protein_per_100g": 25.1, "carbs_per_100g": 20.0, "fat_per_100g": 50.4, "fiber_per_100g": 6.0, "sugar_per_100g": 9.0, "sodium_per_100g": 0.459, "saturated_fat_per_100g": 10.5},
    {"name": "Chia Seeds", "brand": None, "calories_per_100g": 486.0, "protein_per_100g": 16.5, "carbs_per_100g": 42.1, "fat_per_100g": 30.7, "fiber_per_100g": 34.4, "sugar_per_100g": 0.0, "sodium_per_100g": 0.016, "saturated_fat_per_100g": 3.3},
    {"name": "Flaxseeds / Linseed", "brand": None, "calories_per_100g": 534.0, "protein_per_100g": 18.3, "carbs_per_100g": 28.9, "fat_per_100g": 42.2, "fiber_per_100g": 27.3, "sugar_per_100g": 1.6, "sodium_per_100g": 0.030, "saturated_fat_per_100g": 3.7},
    {"name": "Sunflower Seeds", "brand": None, "calories_per_100g": 584.0, "protein_per_100g": 20.8, "carbs_per_100g": 20.0, "fat_per_100g": 51.5, "fiber_per_100g": 8.6, "sugar_per_100g": 2.6, "sodium_per_100g": 0.009, "saturated_fat_per_100g": 4.5},
    {"name": "Sesame Seeds (Til)", "brand": None, "calories_per_100g": 573.0, "protein_per_100g": 17.7, "carbs_per_100g": 23.4, "fat_per_100g": 49.7, "fiber_per_100g": 11.8, "sugar_per_100g": 0.3, "sodium_per_100g": 0.011, "saturated_fat_per_100g": 7.0},
    {"name": "Pistachios (Roasted)", "brand": None, "calories_per_100g": 562.0, "protein_per_100g": 20.2, "carbs_per_100g": 27.5, "fat_per_100g": 44.4, "fiber_per_100g": 10.3, "sugar_per_100g": 7.7, "sodium_per_100g": 0.006, "saturated_fat_per_100g": 5.4},

    # ────────────────────────────────────────────
    # OILS & COOKING FATS
    # ────────────────────────────────────────────
    {"name": "Olive Oil", "brand": None, "calories_per_100g": 884.0, "protein_per_100g": 0.0, "carbs_per_100g": 0.0, "fat_per_100g": 100.0, "fiber_per_100g": 0.0, "sugar_per_100g": 0.0, "sodium_per_100g": 0.002, "saturated_fat_per_100g": 13.8},
    {"name": "Coconut Oil", "brand": None, "calories_per_100g": 862.0, "protein_per_100g": 0.0, "carbs_per_100g": 0.0, "fat_per_100g": 100.0, "fiber_per_100g": 0.0, "sugar_per_100g": 0.0, "sodium_per_100g": 0.0, "saturated_fat_per_100g": 86.5},
    {"name": "Sunflower Oil", "brand": None, "calories_per_100g": 884.0, "protein_per_100g": 0.0, "carbs_per_100g": 0.0, "fat_per_100g": 100.0, "fiber_per_100g": 0.0, "sugar_per_100g": 0.0, "sodium_per_100g": 0.0, "saturated_fat_per_100g": 10.1},
    {"name": "Mustard Oil", "brand": None, "calories_per_100g": 884.0, "protein_per_100g": 0.0, "carbs_per_100g": 0.0, "fat_per_100g": 100.0, "fiber_per_100g": 0.0, "sugar_per_100g": 0.0, "sodium_per_100g": 0.0, "saturated_fat_per_100g": 11.6},

    # ────────────────────────────────────────────
    # COMMON INDIAN DISHES (Prepared)
    # ────────────────────────────────────────────
    {"name": "Dal Makhani", "brand": None, "calories_per_100g": 131.0, "protein_per_100g": 5.0, "carbs_per_100g": 14.7, "fat_per_100g": 5.8, "fiber_per_100g": 2.5, "sugar_per_100g": 2.0, "sodium_per_100g": 0.280, "saturated_fat_per_100g": 2.8},
    {"name": "Dal Tadka", "brand": None, "calories_per_100g": 105.0, "protein_per_100g": 5.0, "carbs_per_100g": 14.0, "fat_per_100g": 3.2, "fiber_per_100g": 3.5, "sugar_per_100g": 1.5, "sodium_per_100g": 0.250, "saturated_fat_per_100g": 1.3},
    {"name": "Idli (Plain)", "brand": None, "calories_per_100g": 58.0, "protein_per_100g": 2.0, "carbs_per_100g": 12.1, "fat_per_100g": 0.1, "fiber_per_100g": 0.5, "sugar_per_100g": 0.3, "sodium_per_100g": 0.120, "saturated_fat_per_100g": 0.0},
    {"name": "Dosa (Plain)", "brand": None, "calories_per_100g": 168.0, "protein_per_100g": 4.0, "carbs_per_100g": 30.0, "fat_per_100g": 3.7, "fiber_per_100g": 0.8, "sugar_per_100g": 0.5, "sodium_per_100g": 0.150, "saturated_fat_per_100g": 0.5},
    {"name": "Sambar", "brand": None, "calories_per_100g": 47.0, "protein_per_100g": 2.7, "carbs_per_100g": 6.8, "fat_per_100g": 1.0, "fiber_per_100g": 2.1, "sugar_per_100g": 2.0, "sodium_per_100g": 0.230, "saturated_fat_per_100g": 0.2},
    {"name": "Palak Paneer", "brand": None, "calories_per_100g": 166.0, "protein_per_100g": 7.1, "carbs_per_100g": 7.3, "fat_per_100g": 12.5, "fiber_per_100g": 1.5, "sugar_per_100g": 2.0, "sodium_per_100g": 0.380, "saturated_fat_per_100g": 6.5},
    {"name": "Paneer Butter Masala", "brand": None, "calories_per_100g": 189.0, "protein_per_100g": 7.5, "carbs_per_100g": 9.0, "fat_per_100g": 14.0, "fiber_per_100g": 1.0, "sugar_per_100g": 4.5, "sodium_per_100g": 0.420, "saturated_fat_per_100g": 7.0},
    {"name": "Chicken Curry", "brand": None, "calories_per_100g": 152.0, "protein_per_100g": 11.0, "carbs_per_100g": 5.8, "fat_per_100g": 9.5, "fiber_per_100g": 1.0, "sugar_per_100g": 2.5, "sodium_per_100g": 0.360, "saturated_fat_per_100g": 2.5},
    {"name": "Biryani (Chicken)", "brand": None, "calories_per_100g": 190.0, "protein_per_100g": 10.5, "carbs_per_100g": 22.5, "fat_per_100g": 6.5, "fiber_per_100g": 0.5, "sugar_per_100g": 1.0, "sodium_per_100g": 0.310, "saturated_fat_per_100g": 1.8},
    {"name": "Biryani (Vegetable)", "brand": None, "calories_per_100g": 155.0, "protein_per_100g": 3.5, "carbs_per_100g": 26.0, "fat_per_100g": 4.5, "fiber_per_100g": 1.5, "sugar_per_100g": 2.0, "sodium_per_100g": 0.290, "saturated_fat_per_100g": 1.2},
    {"name": "Chana Masala", "brand": None, "calories_per_100g": 140.0, "protein_per_100g": 7.0, "carbs_per_100g": 20.0, "fat_per_100g": 4.0, "fiber_per_100g": 5.5, "sugar_per_100g": 3.0, "sodium_per_100g": 0.310, "saturated_fat_per_100g": 0.7},
    {"name": "Aloo Gobi", "brand": None, "calories_per_100g": 97.0, "protein_per_100g": 2.3, "carbs_per_100g": 13.0, "fat_per_100g": 4.0, "fiber_per_100g": 2.5, "sugar_per_100g": 2.5, "sodium_per_100g": 0.250, "saturated_fat_per_100g": 0.5},
    {"name": "Rajma (Kidney Bean Curry)", "brand": None, "calories_per_100g": 127.0, "protein_per_100g": 7.5, "carbs_per_100g": 18.0, "fat_per_100g": 3.0, "fiber_per_100g": 5.0, "sugar_per_100g": 2.0, "sodium_per_100g": 0.280, "saturated_fat_per_100g": 0.5},
    {"name": "Khichdi (Dal & Rice)", "brand": None, "calories_per_100g": 124.0, "protein_per_100g": 4.2, "carbs_per_100g": 23.2, "fat_per_100g": 1.8, "fiber_per_100g": 1.5, "sugar_per_100g": 0.5, "sodium_per_100g": 0.180, "saturated_fat_per_100g": 0.5},
    {"name": "Pulao (Plain Vegetable)", "brand": None, "calories_per_100g": 145.0, "protein_per_100g": 3.0, "carbs_per_100g": 28.0, "fat_per_100g": 2.5, "fiber_per_100g": 1.0, "sugar_per_100g": 1.0, "sodium_per_100g": 0.200, "saturated_fat_per_100g": 0.7},
    {"name": "Paratha (Plain)", "brand": None, "calories_per_100g": 315.0, "protein_per_100g": 8.0, "carbs_per_100g": 50.0, "fat_per_100g": 9.0, "fiber_per_100g": 3.0, "sugar_per_100g": 1.0, "sodium_per_100g": 0.360, "saturated_fat_per_100g": 3.5},
    {"name": "Paratha (Aloo Stuffed)", "brand": None, "calories_per_100g": 278.0, "protein_per_100g": 6.5, "carbs_per_100g": 42.0, "fat_per_100g": 9.5, "fiber_per_100g": 3.5, "sugar_per_100g": 1.5, "sodium_per_100g": 0.350, "saturated_fat_per_100g": 3.8},
    {"name": "Poha (Cooked)", "brand": None, "calories_per_100g": 133.0, "protein_per_100g": 2.3, "carbs_per_100g": 26.4, "fat_per_100g": 2.8, "fiber_per_100g": 0.9, "sugar_per_100g": 1.2, "sodium_per_100g": 0.180, "saturated_fat_per_100g": 0.5},
    {"name": "Masala Chai (with Milk & Sugar)", "brand": None, "calories_per_100g": 43.0, "protein_per_100g": 1.5, "carbs_per_100g": 7.0, "fat_per_100g": 1.0, "fiber_per_100g": 0.0, "sugar_per_100g": 6.5, "sodium_per_100g": 0.025, "saturated_fat_per_100g": 0.6},
    {"name": "Lassi (Sweet)", "brand": None, "calories_per_100g": 72.0, "protein_per_100g": 2.3, "carbs_per_100g": 12.0, "fat_per_100g": 1.5, "fiber_per_100g": 0.0, "sugar_per_100g": 11.5, "sodium_per_100g": 0.045, "saturated_fat_per_100g": 1.0},

    # ────────────────────────────────────────────
    # COMMON FAST FOOD / PROCESSED
    # ────────────────────────────────────────────
    {"name": "French Fries (Fried)", "brand": None, "calories_per_100g": 312.0, "protein_per_100g": 3.4, "carbs_per_100g": 41.4, "fat_per_100g": 15.0, "fiber_per_100g": 3.8, "sugar_per_100g": 0.5, "sodium_per_100g": 0.210, "saturated_fat_per_100g": 2.4},
    {"name": "Pizza (Cheese, 1 Slice)", "brand": None, "calories_per_100g": 266.0, "protein_per_100g": 11.0, "carbs_per_100g": 33.0, "fat_per_100g": 10.0, "fiber_per_100g": 2.3, "sugar_per_100g": 3.6, "sodium_per_100g": 0.598, "saturated_fat_per_100g": 4.5},
    {"name": "Burger Patty (Beef)", "brand": None, "calories_per_100g": 290.0, "protein_per_100g": 17.0, "carbs_per_100g": 3.8, "fat_per_100g": 23.0, "fiber_per_100g": 0.0, "sugar_per_100g": 0.0, "sodium_per_100g": 0.340, "saturated_fat_per_100g": 9.0},
    {"name": "Instant Noodles (Cooked)", "brand": None, "calories_per_100g": 138.0, "protein_per_100g": 3.5, "carbs_per_100g": 21.6, "fat_per_100g": 4.5, "fiber_per_100g": 0.9, "sugar_per_100g": 0.8, "sodium_per_100g": 0.734, "saturated_fat_per_100g": 2.0},
    {"name": "White Rice (Steamed, Restaurant)", "brand": None, "calories_per_100g": 130.0, "protein_per_100g": 2.4, "carbs_per_100g": 28.7, "fat_per_100g": 0.2, "fiber_per_100g": 0.3, "sugar_per_100g": 0.0, "sodium_per_100g": 0.001, "saturated_fat_per_100g": 0.1},

    # ────────────────────────────────────────────
    # SNACKS & SWEETS
    # ────────────────────────────────────────────
    {"name": "Digestive Biscuit", "brand": None, "calories_per_100g": 471.0, "protein_per_100g": 7.4, "carbs_per_100g": 62.0, "fat_per_100g": 20.5, "fiber_per_100g": 3.5, "sugar_per_100g": 16.0, "sodium_per_100g": 0.480, "saturated_fat_per_100g": 9.0},
    {"name": "Rice Cake (Plain)", "brand": None, "calories_per_100g": 387.0, "protein_per_100g": 8.0, "carbs_per_100g": 82.0, "fat_per_100g": 2.9, "fiber_per_100g": 2.0, "sugar_per_100g": 0.7, "sodium_per_100g": 0.006, "saturated_fat_per_100g": 0.6},
    {"name": "Granola Bar", "brand": None, "calories_per_100g": 471.0, "protein_per_100g": 9.2, "carbs_per_100g": 64.0, "fat_per_100g": 20.0, "fiber_per_100g": 4.0, "sugar_per_100g": 29.0, "sodium_per_100g": 0.180, "saturated_fat_per_100g": 3.5},
    {"name": "Dark Chocolate (70%+)", "brand": None, "calories_per_100g": 598.0, "protein_per_100g": 7.8, "carbs_per_100g": 46.0, "fat_per_100g": 42.6, "fiber_per_100g": 10.9, "sugar_per_100g": 24.0, "sodium_per_100g": 0.020, "saturated_fat_per_100g": 24.5},
    {"name": "Milk Chocolate", "brand": None, "calories_per_100g": 535.0, "protein_per_100g": 7.6, "carbs_per_100g": 59.4, "fat_per_100g": 29.7, "fiber_per_100g": 3.4, "sugar_per_100g": 51.5, "sodium_per_100g": 0.079, "saturated_fat_per_100g": 18.0},
    {"name": "Laddoo (Besan / Gram)", "brand": None, "calories_per_100g": 434.0, "protein_per_100g": 7.5, "carbs_per_100g": 58.0, "fat_per_100g": 18.5, "fiber_per_100g": 2.0, "sugar_per_100g": 35.0, "sodium_per_100g": 0.020, "saturated_fat_per_100g": 9.0},
    {"name": "Halwa (Sooji / Semolina)", "brand": None, "calories_per_100g": 230.0, "protein_per_100g": 3.5, "carbs_per_100g": 35.0, "fat_per_100g": 8.5, "fiber_per_100g": 0.5, "sugar_per_100g": 22.0, "sodium_per_100g": 0.012, "saturated_fat_per_100g": 5.0},

    # ────────────────────────────────────────────
    # BEVERAGES
    # ────────────────────────────────────────────
    {"name": "Orange Juice (100% Fresh)", "brand": None, "calories_per_100g": 45.0, "protein_per_100g": 0.7, "carbs_per_100g": 10.4, "fat_per_100g": 0.2, "fiber_per_100g": 0.2, "sugar_per_100g": 8.4, "sodium_per_100g": 0.001, "saturated_fat_per_100g": 0.0},
    {"name": "Coconut Water", "brand": None, "calories_per_100g": 19.0, "protein_per_100g": 0.7, "carbs_per_100g": 3.7, "fat_per_100g": 0.2, "fiber_per_100g": 1.1, "sugar_per_100g": 2.6, "sodium_per_100g": 0.105, "saturated_fat_per_100g": 0.2},
    {"name": "Protein Shake (Prepared, Milk Based)", "brand": None, "calories_per_100g": 68.0, "protein_per_100g": 8.5, "carbs_per_100g": 6.0, "fat_per_100g": 1.3, "fiber_per_100g": 0.0, "sugar_per_100g": 5.0, "sodium_per_100g": 0.100, "saturated_fat_per_100g": 0.6},
    {"name": "Black Coffee", "brand": None, "calories_per_100g": 2.0, "protein_per_100g": 0.3, "carbs_per_100g": 0.0, "fat_per_100g": 0.0, "fiber_per_100g": 0.0, "sugar_per_100g": 0.0, "sodium_per_100g": 0.002, "saturated_fat_per_100g": 0.0},
    {"name": "Green Tea (Brewed)", "brand": None, "calories_per_100g": 1.0, "protein_per_100g": 0.2, "carbs_per_100g": 0.2, "fat_per_100g": 0.0, "fiber_per_100g": 0.0, "sugar_per_100g": 0.0, "sodium_per_100g": 0.001, "saturated_fat_per_100g": 0.0},
]
