# System Prompt & Instructions for NutriTrack Development Agent

You are a senior full-stack engineer. Your task is to build a complete, production-ready fitness tracking app called **"NutriTrack"** (similar to MyFitnessPal) with a Flutter frontend and a FastAPI backend, fully integrated and working end-to-end.

---

## 📁 MONOREPO STRUCTURE

```text
nutritrack/
├── frontend/                  # Flutter app
│   ├── lib/
│   │   ├── core/
│   │   │   ├── theme/         # AppTheme, colors, text styles
│   │   │   ├── router/        # GoRouter config, routes
│   │   │   ├── constants/     # API constants, strings
│   │   │   ├── network/       # Dio client, interceptors, ApiException
│   │   │   └── utils/         # date/weight helpers
│   │   ├── features/
│   │   │   ├── auth/          # Login, Register, AuthProvider
│   │   │   ├── onboarding/    # Multi-step goals wizard
│   │   │   ├── dashboard/     # Daily summary, circular progress, water intake
│   │   │   ├── diary/         # 4 meals log, serving edit, sliding delete
│   │   │   ├── food_log/      # Manual log, food list
│   │   │   ├── exercise/      # Cardio / strength exercises logs, library
│   │   │   ├── water/         # Wave animation, logged list
│   │   │   ├── weight/        # Weight line chart, logs, stats
│   │   │   ├── progress/      # Overview, nutrition, body measurements, calendar heatmap
│   │   │   └── profile/       # Targets, preferences, custom meals, notifications
│   │   ├── shared/
│   │   │   ├── widgets/       # reusable UI components
│   │   │   └── models/        # shared models (FoodItem, User, etc.)
│   │   └── main.dart
│   ├── pubspec.yaml
│   └── .env
├── backend/                   # FastAPI app
│   ├── app/
│   │   ├── api/
│   │   │   ├── v1/
│   │   │   │   ├── auth.py
│   │   │   │   ├── goals.py
│   │   │   │   ├── diary.py
│   │   │   │   ├── foods.py
│   │   │   │   ├── exercise.py
│   │   │   │   ├── water.py
│   │   │   │   ├── weight.py
│   │   │   │   ├── progress.py
│   │   │   │   ├── ai.py
│   │   │   │   └── profile.py
│   │   │   └── deps.py        # Dependency injection (e.g., get_current_user, get_db)
│   │   ├── core/
│   │   │   ├── config.py      # Pydantic Settings
│   │   │   ├── security.py    # JWT, password hashing
│   │   │   ├── database.py    # Async engine, sessionmaker
│   │   │   └── redis.py       # Redis cache connection
│   │   ├── models/            # SQLAlchemy ORM models (base.py, user.py, etc.)
│   │   ├── schemas/           # Pydantic v2 schemas
│   │   ├── services/          # Business logic
│   │   ├── repositories/      # Database queries (CRUD)
│   │   └── main.py            # App initialization, middlewares, routing
│   ├── alembic/               # Database migrations
│   │   ├── env.py
│   │   └── script.py.mako
│   ├── tests/                 # Pytest test suite
│   ├── requirements.txt
│   └── .env
└── README.md
```

---

## ⚙️ BACKEND — FASTAPI SPECIFICATION

### Tech Stack
* **FastAPI 0.111+** with async/await throughout.
* **Python 3.11+**.
* **PostgreSQL 15** via SQLAlchemy 2.0 (async) + `asyncpg` driver.
* **Alembic** for schema migrations.
* **Redis 7** via `aioredis` (food search cache + rate limiting).
* **JWT Auth** via `python-jose` + `passlib[bcrypt]`.
* **Pydantic v2** for strict data validation and serialization.
* **Cloudinary SDK** for uploading and hosting progress photos and scanned meals.
* **httpx** for asynchronous HTTP calls to the Claude API and Open Food Facts.
* **Local environment**: Python virtual environment & local services setup.

---

### Environment Variables (`backend/.env`)
```bash
DATABASE_URL=postgresql+asyncpg://nutritrack:password@postgres:5432/nutritrack
REDIS_URL=redis://redis:6379/0
SECRET_KEY=your-256-bit-secret-key-here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60
REFRESH_TOKEN_EXPIRE_DAYS=30
CLAUDE_API_KEY=your-claude-api-key
CLAUDE_MODEL=claude-3-5-sonnet-20241022
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-cloudinary-key
CLOUDINARY_API_SECRET=your-cloudinary-secret
OPEN_FOOD_FACTS_BASE=https://world.openfoodfacts.org
FOOD_CACHE_TTL_SECONDS=86400
BARCODE_CACHE_TTL_SECONDS=604800
ENVIRONMENT=development
ALLOWED_ORIGINS=http://localhost,http://10.0.2.2
```

---

### Database Schema (SQLAlchemy Models)

* **`users` Table**
  * `id`: UUID (PK, default `gen_random_uuid()`)
  * `email`: VARCHAR(255) (UNIQUE, NOT NULL, INDEXED)
  * `password_hash`: VARCHAR(255) (NOT NULL)
  * `name`: VARCHAR(100) (NOT NULL)
  * `avatar_url`: TEXT (nullable)
  * `unit_system`: ENUM('metric', 'imperial') (default 'metric')
  * `is_active`: BOOLEAN (default true)
  * `created_at`: TIMESTAMP (default now())
  * `updated_at`: TIMESTAMP (nullable)

* **`user_goals` Table**
  * `id`: UUID (PK)
  * `user_id`: UUID (FK -> `users.id` ON DELETE CASCADE, UNIQUE)
  * `goal_type`: ENUM('lose', 'maintain', 'gain')
  * `current_weight_kg`: FLOAT (NOT NULL)
  * `target_weight_kg`: FLOAT (NOT NULL)
  * `height_cm`: FLOAT (NOT NULL)
  * `age`: INTEGER (NOT NULL)
  * `gender`: ENUM('male', 'female', 'other')
  * `activity_level`: ENUM('sedentary', 'light', 'moderate', 'active', 'very_active')
  * `weekly_pace_kg`: FLOAT (default 0.5)
  * `daily_calorie_target`: INTEGER (NOT NULL)
  * `daily_protein_g`: INTEGER (NOT NULL)
  * `daily_carbs_g`: INTEGER (NOT NULL)
  * `daily_fat_g`: INTEGER (NOT NULL)
  * `daily_fiber_g`: INTEGER (default 25)
  * `daily_water_ml`: INTEGER (NOT NULL)
  * `updated_at`: TIMESTAMP (default now())

* **`food_items` Table**
  * `id`: UUID (PK)
  * `name`: VARCHAR(255) (NOT NULL, INDEXED)
  * `brand`: VARCHAR(255) (nullable)
  * `barcode`: VARCHAR(50) (UNIQUE, nullable, INDEXED)
  * `calories_per_100g`: FLOAT (NOT NULL)
  * `carbs_per_100g`: FLOAT (NOT NULL)
  * `protein_per_100g`: FLOAT (NOT NULL)
  * `fat_per_100g`: FLOAT (NOT NULL)
  * `fiber_per_100g`: FLOAT (default 0.0)
  * `sugar_per_100g`: FLOAT (default 0.0)
  * `sodium_per_100g`: FLOAT (default 0.0)
  * `saturated_fat_per_100g`: FLOAT (default 0.0)
  * `image_url`: TEXT (nullable)
  * `source`: ENUM('api', 'barcode', 'custom', 'ai_scan') (default 'api')
  * `created_by`: UUID (FK -> `users.id` ON DELETE SET NULL, nullable, INDEXED)
  * `created_at`: TIMESTAMP (default now())

* **`food_log_entries` Table**
  * `id`: UUID (PK)
  * `user_id`: UUID (FK -> `users.id` ON DELETE CASCADE, INDEXED)
  * `food_item_id`: UUID (FK -> `food_items.id` ON DELETE RESTRICT)
  * `meal_type`: ENUM('breakfast', 'lunch', 'dinner', 'snacks')
  * `serving_size_g`: FLOAT (NOT NULL)
  * `calories`: FLOAT (NOT NULL)
  * `carbs_g`: FLOAT (NOT NULL)
  * `protein_g`: FLOAT (NOT NULL)
  * `fat_g`: FLOAT (NOT NULL)
  * `fiber_g`: FLOAT (nullable)
  * `log_date`: DATE (NOT NULL, INDEXED)
  * `logged_at`: TIMESTAMP (default now())
  * *Index on `(user_id, log_date)`*

* **`water_logs` Table**
  * `id`: UUID (PK)
  * `user_id`: UUID (FK -> `users.id` ON DELETE CASCADE, INDEXED)
  * `amount_ml`: INTEGER (NOT NULL)
  * `log_date`: DATE (NOT NULL)
  * `logged_at`: TIMESTAMP (default now())
  * *Index on `(user_id, log_date)`*

* **`exercise_logs` Table**
  * `id`: UUID (PK)
  * `user_id`: UUID (FK -> `users.id` ON DELETE CASCADE, INDEXED)
  * `exercise_name`: VARCHAR(255) (NOT NULL)
  * `exercise_type`: ENUM('cardio', 'strength')
  * `duration_minutes`: INTEGER (nullable)
  * `calories_burned`: FLOAT (NOT NULL)
  * `notes`: TEXT (nullable)
  * `log_date`: DATE (NOT NULL, INDEXED)
  * `logged_at`: TIMESTAMP (default now())

* **`exercise_sets` Table**
  * `id`: UUID (PK)
  * `exercise_log_id`: UUID (FK -> `exercise_logs.id` ON DELETE CASCADE, INDEXED)
  * `set_number`: INTEGER (NOT NULL)
  * `reps`: INTEGER (nullable)
  * `weight_kg`: FLOAT (nullable)
  * `completed`: BOOLEAN (default true)

* **`weight_entries` Table**
  * `id`: UUID (PK)
  * `user_id`: UUID (FK -> `users.id` ON DELETE CASCADE, INDEXED)
  * `weight_kg`: FLOAT (NOT NULL)
  * `note`: TEXT (nullable)
  * `logged_at`: TIMESTAMP (default now())

* **`body_measurements` Table**
  * `id`: UUID (PK)
  * `user_id`: UUID (FK -> `users.id` ON DELETE CASCADE, INDEXED)
  * `waist_cm`: FLOAT (nullable)
  * `chest_cm`: FLOAT (nullable)
  * `hips_cm`: FLOAT (nullable)
  * `left_arm_cm`: FLOAT (nullable)
  * `right_arm_cm`: FLOAT (nullable)
  * `left_thigh_cm`: FLOAT (nullable)
  * `right_thigh_cm`: FLOAT (nullable)
  * `logged_at`: TIMESTAMP (default now())

* **`refresh_tokens` Table**
  * `id`: UUID (PK)
  * `user_id`: UUID (FK -> `users.id` ON DELETE CASCADE)
  * `token_hash`: VARCHAR(255) (UNIQUE, NOT NULL)
  * `expires_at`: TIMESTAMP (NOT NULL)
  * `created_at`: TIMESTAMP (default now())

---

### API Endpoints (All prefixed `/api/v1`)

#### AUTH (`/auth`)
* `POST /register`: Registers a new user. Hashes password using bcrypt. Returns standard envelope containing access and refresh tokens, and user details.
* `POST /login`: Verifies user password and returns standard envelope with a new JWT access token and refresh token.
* `POST /refresh`: Expects `{ "refresh_token": "..." }`. Validates token against database and issues a new access token.
* `POST /logout` (Auth Required): Invalidates/deletes the refresh token from the database.
* `GET /me` (Auth Required): Returns the profile data of the logged-in user.
* `PUT /me` (Auth Required): Updates user's name, avatar_url, or unit_system.
* `PUT /me/password` (Auth Required): Verifies `current_password` and updates it to `new_password`.

#### GOALS (`/goals`)
* `POST /` (Auth Required): Calculates TDEE, Calorie Targets, Macros, and Water target. Saves to `user_goals` database table and returns details.
  * **TDEE Formula (Mifflin-St Jeor)**:
    * *Male*: `(10 * weight_kg) + (6.25 * height_cm) - (5 * age) + 5`
    * *Female*: `(10 * weight_kg) + (6.25 * height_cm) - (5 * age) - 161`
    * *Activity Multiplier*: `sedentary=1.2`, `light=1.375`, `moderate=1.55`, `active=1.725`, `very_active=1.9`
  * **Daily Calorie Target Calculation**:
    * *Lose weight*: `TDEE - (weekly_pace_kg * 1100)`
    * *Gain muscle*: `TDEE + (weekly_pace_kg * 550)`
    * *Maintain*: `TDEE`
  * **Default Macro Split**: Protein = 30%, Carbs = 40%, Fat = 30%.
    * Protein: 4 kcal/g
    * Carbs: 4 kcal/g
    * Fat: 9 kcal/g
  * **Water Target**: `weight_kg * 35 ml`
* `GET /` (Auth Required): Returns current active goal metrics.
* `PUT /` (Auth Required): Updates metrics, recalculates targets, and updates goals.

#### DIARY (`/diary`)
* `GET /?date=YYYY-MM-DD` (Auth Required): Retrieves food logs for date, grouped by meal types (`breakfast`, `lunch`, `dinner`, `snacks`), with daily summary totals (calories consumed, macro totals, remaining calories).
* `POST /entries` (Auth Required): Logs food item entry, calculating actual macros based on item's per-100g values and selected portion weight.
* `PUT /entries/{id}` (Auth Required): Updates logged food entry (serving size or meal type), recalculating macros.
* `DELETE /entries/{id}` (Auth Required): Deletes user-owned food log entry.
* `GET /summary?date=YYYY-MM-DD` (Auth Required): Returns summary stats: `{ calories_consumed, calories_goal, calories_remaining, carbs_consumed, carbs_goal, protein_consumed, protein_goal, fat_consumed, fat_goal, water_consumed, water_goal, exercise_calories_burned, net_calories }`.

#### FOODS (`/foods`)
* `GET /search?q={query}&page=1&limit=20` (Auth Required):
  * Check Redis search cache first (`key: search:{query}:{page}`).
  * If Redis miss: Call Open Food Facts API, mapping schema attributes. Cache result in Redis (TTL = 24 hrs).
  * Concurrently search user's custom foods from database.
  * Return merged list.
* `GET /barcode/{code}` (Auth Required): Check Redis (`key: barcode:{code}`). If miss: call Open Food Facts barcode API, map to schema, cache in Redis (TTL = 7 days).
* `POST /custom` (Auth Required): Creates and returns a new user-owned custom food item.
* `GET /recent` (Auth Required): Returns last 20 unique food items logged by the user.
* `GET /frequent` (Auth Required): Returns top 10 most logged food items by the user (count-based, last 30 days).
* `GET /{id}` (Auth Required): Returns details for a single food item.

#### WATER (`/water`)
* `GET /?date=YYYY-MM-DD` (Auth Required): Returns logged water entries, daily total ml, and water goal.
* `POST /` (Auth Required): Logs water intake (ml) for the day. Returns log entry + updated daily total.
* `DELETE /{id}` (Auth Required): Deletes logged water entry.

#### EXERCISE (`/exercise`)
* `GET /?date=YYYY-MM-DD` (Auth Required): Returns logged exercises for a specific date + total active calories burned.
* `POST /` (Auth Required): Log cardio or strength exercise. Strength exercises can include sets (reps, weight).
* `DELETE /{id}` (Auth Required): Deletes exercise log entry (cascades delete to strength sets).
* `GET /library?q={query}&type=cardio|strength` (Auth Required): Returns exercises from the static static exercise list JSON. Cardio exercises include MET values. Strength exercises include target muscle groups.

#### WEIGHT (`/weight`)
* `GET /` (Auth Required): Returns weight logs ordered by timestamp desc.
* `POST /` (Auth Required): Logs a new weight entry.
* `DELETE /{id}` (Auth Required): Deletes weight entry.
* `GET /stats` (Auth Required): Returns summary stats: `{ start_weight_kg, current_weight_kg, goal_weight_kg, total_change_kg, trend_kg_per_week (calculated using linear regression over last 30 days), entries_count }`.

#### PROGRESS (`/progress`)
* `GET /calories?range=7d|30d|90d|1y` (Auth Required): Returns timeline list of `{ date, calories_consumed, calories_goal, calories_burned }`.
* `GET /macros?range=7d|30d` (Auth Required): Returns daily timeline of `{ date, carbs_g, protein_g, fat_g }` + period averages.
* `GET /streak` (Auth Required): Computes consecutive logging streak (minimum 1 diary entry per day). Returns current streak, longest streak, and last logged date.
* `GET /weight?range=30d|90d|180d|1y|all` (Auth Required): Returns weight timeline along with 7-day moving averages.
* `POST /measurements` (Auth Required): Logs body measurements.
* `GET /measurements` (Auth Required): Returns measurements ordered by date.

#### AI (`/ai`)
* `POST /meal-scan` (Auth Required, multipart/form-data): Uploads meal image to Cloudinary, then passes URL to Claude Vision with system prompt instructions. Expects Claude to analyze and return strict JSON containing food items, portion sizes, estimated macros, and overall confidence score. Returns parsed items matching database or ready to log.
* `POST /voice-parse` (Auth Required): Sends voice text transcript to Claude API. Returns parsed foods, quantities, units, and meal suggestions in JSON.
* `GET /insights?period=7d|30d` (Auth Required): Compiles user stats and sends details to Claude to generate 3 personalized nutrition insights and 2 actionable tips.

---

### Backend Rules
1. **Security**: All endpoints except registration and login require JWT authentication (via `get_current_user` dependency injection).
2. **Response Envelope**:
   * *Success (HTTP 200/201)*: `{ "success": true, "data": {...}, "message": "Optional message" }`
   * *Error (HTTP 400/401/403/404/422/429/500)*: `{ "success": false, "error": "Error Type", "detail": "Detailed error message" }`
3. **Pagination**: Return paginated responses for lists: `?page=1&limit=20` returning `{ "data": [...], "total": 100, "page": 1, "limit": 20, "has_next": true }`.
4. **Exception Handling**: Global exception handler logs errors and outputs clean 500 responses without leakages.
5. **Rate Limiting**: sliding window rate limiter at 100 requests/minute per authenticated user.
6. **SQL Session**: All SQLAlchemy sessions must be async (`AsyncSession`).
7. **Seed Data**: Run a seed script (`seed_exercises.py`) to populate the exercise library with 50+ exercises (cardio with METs, strength with muscle groups).

---

## 📱 FRONTEND — FLUTTER SPECIFICATION

### Tech Stack
* **Flutter 3.x** and **Dart 3.x** (null safety enabled).
* **State Management**: `flutter_riverpod` + `riverpod_generator`.
* **Routing**: `go_router`.
* **HTTP Client**: `dio` + `retrofit` generator.
* **Local Storage**: `hive_flutter` for caching API state.
* **Secure Storage**: `flutter_secure_storage` for JWT tokens.
* **Visualization**: `fl_chart` for progress visualizer graphs.
* **Camera / Barcode / Audio Scanner**: `mobile_scanner`, `image_picker`, `speech_to_text`.
* **Notifications**: `flutter_local_notifications`.
* **UI**: `percent_indicator`, `lottie`, `shimmer`, `cached_network_image`, `google_fonts (Inter)`, `flutter_svg`.

---

### Environment Configuration (`frontend/.env`)
* **Android Emulator**: `API_BASE_URL=http://10.0.2.2:8000/api/v1`
* **iOS Simulator / Local Web**: `API_BASE_URL=http://localhost:8000/api/v1`

---

### Network Layer
* **Dio Client Integration**:
  * Set timeouts: connect = 30s, receive = 30s.
  * **`AuthInterceptor`**:
    * Reads `access_token` from secure storage. Appends `Authorization: Bearer <token>` to requests.
    * Intercepts `401 Unauthorized`. Attempts token refresh via `/auth/refresh`.
    * If successful: Updates local tokens in Secure Storage and retries original request.
    * If refresh fails: Clears tokens and redirects router to login.
  * **`ErrorInterceptor`**: Maps HTTP statuses to custom exceptions: `NetworkException`, `AuthException`, `ValidationException`, `ServerException`, `NotFoundException`.
  * **`Retrofit Client`**: Connects endpoints using type-safe APIs, wrapping outputs in standard `ApiResponse<T>` wrappers.

---

### Styling & Theme Design System
* **Colors (AppColors)**:
  * Primary: `#0066FF` (Vibrant Blue)
  * Secondary: `#00C853` (Success Green)
  * Warning: `#FF6D00` (Amber Orange)
  * Danger: `#E53935` (Warning Red)
  * Background: Light `#F5F7FA` | Dark `#121212`
  * Surface/Cards: Light `#FFFFFF` | Dark `#1E1E1E`
* **Typography**: Google Fonts Inter with defined styles for `displayLarge`, `headlineMedium`, `titleLarge`, `bodyLarge`, etc.
* **Decorations**: Rounded corners (12px on card borders, 8px on buttons, 24px on bottom sheets), border-based elevation-0 outlines.

---

### Screens Specification

* **`SplashScreen`**: Fades in app logo (1.5s). Validates JWT `access_token`. Redirects to Dashboard if valid, attempts refresh if expired, or routes to Onboarding/Login on failure.
* **`OnboardingScreen`**: Multi-step wizard pageview:
  1. *Goal Choice*: Select Lose Weight / Maintain Weight / Gain Muscle (large animated selectable cards).
  2. *Basic Data*: Input Name, select age using a wheel picker, select gender using segmented control.
  3. *Body Specs*: Enter height and current weight with live BMI calculator display.
  4. *Target Target*: Specify target weight and use slider to pick pace (0.25 to 1.0 kg/week) with live date estimates.
  5. *Activity Factor*: Select from 5 levels. Clicking "Calculate Plan" calls `POST /goals`, registers variables, and routes user home.
* **`LoginScreen` / `RegisterScreen`**: Form validation, error state indicators, password strength meter, auto-login redirect.
* **`DashboardScreen`**:
  * *Datepicker Strip*: Horizontal scrollable header showing 7 days. Tap updates target date and invalidates stats.
  * *Remaining Calorie Ring*: `percent_indicator` showing remaining kcal. Animates 0 to actual value (800ms curve). Changes colors (green -> orange -> red).
  * *Macros display*: Linear progress bars showing carbs, protein, and fat.
  * *Water quick-tap widget*: Grid/row of 8 interactive cups. Tapping updates intake.
  * *Meal logs list*: Breakfast, lunch, dinner, snacks widgets with shortcut entry links.
  * *Streak & Daily Insights widget*: Fire streak indicator + Claude personalized dynamic tips.
* **`DiaryScreen`**: Expandable panels for meals. Shows logged food items, serving quantities, and macros. Left-swipe triggers deletion. Tap opens serving size sheet.
* **`FoodSearchScreen`**: Live search input with 400ms debounce. Categorized tabs: Results, Recent, Frequent, Custom Foods. Tap items to open calorie configurator bottom sheet.
* **`BarcodeScanScreen`**: Viewport camera scanning overlay using `mobile_scanner`. Features green brackets, scrolling red line, and haptic feedback.
* **`VoiceLogScreen`**: Record button with a concentric wave pulse indicator. Shows live transcript, parses details via FastAPI Claude service, and displays editable log preview cards.
* **`MealScanScreen`**: Shimmering camera/gallery loader passing photos to Claude Vision. Displays categorized list of parsed foods and estimated weights for instant log options.
* **`WaterScreen`**: Displays a custom sinusoidal wave filling visual matching targets. Features quick-add volume adjustments and a history log.
* **`ExerciseLogScreen`**:
  * *Cardio Log*: Searchable exercises calculating metabolic MET rates against body weight.
  * *Strength Log*: Grouped by muscles, builder to add/remove sets (reps & weight inputs).
* **`WeightScreen`**: fl_chart line graphs depicting weights vs goals, supporting multiple timelines (1M, 3M, 6M, etc.), with custom weight entries below.
* **`ProgressScreen`**: Tabs for weekly totals, macronutrient stacked charts, measurement histories, and monthly logging heatmap calendars.
* **`ProfileScreen`**: Manage goals, edit calorie bounds, toggle units (metric/imperial), customize meal names, export metrics as CSV, or sign out.

---

### Local Cache and Offline Strategy
* **Hive Cache**: Stores data in `diary_cache`, `water_cache`, `weight_cache`, and `food_search_cache` boxes.
* **Behavior**: Optimistically shows cached data. Launches background API synchronizer.
* **Queue Handling**: Queues offline writes (e.g. food logs) in a Hive queue. Listens for network changes via `connectivity_plus` to sync logs once online.

---

## 🚀 BUILD ORDER (IMPLEMENT EXACTLY IN THIS ORDER)

Follow this structured phase roadmap. Verify build steps, test dependencies, and address compile issues before proceeding.

### Phase 1: Backend Infrastructure & Foundation
1. **Setup Core**: Write `backend/requirements.txt`.
2. **Configuration**: Implement `backend/app/core/config.py` (Pydantic settings), `database.py` (SQLAlchemy async engine), `redis.py` (aioredis client), and `security.py` (bcrypt hashing, JWT tokens generation).
3. **ORM Models**: Create files inside `backend/app/models/` mapping user tables, goals, logs, food items, exercise, weight, and measurements.
4. **Migrations**: Configure Alembic and run the initial migration (`alembic revision --autogenerate`) to create all PostgreSQL tables.
5. **Validation Schemas**: Write Pydantic v2 schemas in `backend/app/schemas/` covering request, response, and inner models.
6. **Repository Layer**: Build async CRUD helper classes in `backend/app/repositories/`.

### Phase 2: Core Backend Services
7. **Auth Endpoints**: Implement `auth.py` router handling `/register`, `/login`, `/refresh`, `/logout`, and `/me`. Define dependency injection for `/me` authentication validation.
8. **Goals Management**: Implement TDEE and calorie allocation routines in `goals.py`.
9. **Foods Service**: Implement `/foods/search` with Redis caching, `/foods/barcode/{code}`, and custom food creation endpoints.
10. **Diary Logs**: Write `/diary` and `/diary/summary` routers matching specific dates.
11. **Water Tracker**: Implement `/water` logger with daily totals.
12. **Exercise Tracker & Seed**: Implement `/exercise` and its set tracker. Write `seed_exercises.py` to pre-populate 50+ cardio/strength exercise objects.
13. **Weight Logs**: Write weight logger, statistics aggregator, and linear regression trend calculator in `weight.py`.
14. **Progress Tracker**: Implement `/progress` charts aggregation (calories, macros, weights timelines) and body measurement trackers.
15. **AI Services**: Integrate Claude API endpoints (`/ai/meal-scan`, `/ai/voice-parse`, `/ai/insights`).
16. **Backend Testing**: Add tests in `tests/` verifying authentication, goal calculations, and diary logging.

### Phase 3: Flutter App Setup & Core Layers
17. **Project Initialization**: Initialize Flutter structure, add packages to `pubspec.yaml`, define `AppTheme` colors, and configure routes in `app_router.dart`.
18. **Network Layer**: Write Dio config client, `AuthInterceptor`, error mappers, and Retrofit `api_service.dart`.
19. **Local Cache / Riverpod**: Set up Hive boxes and write Riverpod providers. Run `build_runner` to generate files.
20. **Auth Flow & Onboarding**: Implement Splash screen, multi-page Onboarding wizard, and Login/Register views.
21. **Navigation Shell**: Build main interface scaffolding containing GoRouter nested bottom tabs.

### Phase 4: Frontend Feature Screens
22. **Dashboard**: Implement circular progress charts, macro bars, water quick-add icons, and daily summaries.
23. **Diary Details**: Implement expandable meals list, swipe-to-delete logs, and macros summaries.
24. **Search UI**: Implement search list with debounce, recent/frequent tabs, and serving size details modal sheet.
25. **Barcode View**: Implement camera viewfinder overlay with bracket guides and flash toggle.
26. **Voice Log**: Build record panel with mic wave visualizer and logs validation cards.
27. **Meal Image Scan**: Set up picture uploader with loader widget and parsed output selector.
28. **Water Tracking**: Build wave-filled bottle graphic and water logs list.
29. **Exercises**: Create cardio and strength configuration sheets.
30. **Weight Dashboard**: Integrate weight charts, stats, and weight logging dialogs.
31. **Progress Charts**: Add stacked calorie, macro, and measurement trend views.
32. **Settings Profile**: Configure targets, custom meal types, unit conversion switches, and notification settings.

### Phase 5: Polish & Sync Integration
33. **Notification Scheduling**: Set up background meal/water reminders using `flutter_local_notifications`.
34. **Offline Sync Queue**: Configure Hive database queues to hold offline logs and sync them when connectivity changes.
35. **Final QA Check**: Address Flutter analysis hints, Python lint warnings, check dark mode styles, and write the project README.md.

---

## 🛠️ FINAL CODE QUALITY & QA RULES

* **Build complete files**: Implement all files and screens completely, avoiding placeholders or TODOs.
* **Flutter Analysis**: Ensure `flutter analyze` runs without errors. Keep UI widgets cleanly split, using const constructors where possible.
* **Python Cleanliness**: Ensure `ruff check .` passes without errors or warnings.
* **Error Handling**: Catch API, database, and hardware errors (e.g. camera, microphone permissions), displaying friendly snackbars or fallback UIs.
* **Visuals**: Maintain high-fidelity styling across both light and dark modes. Avoid using raw colors or unformatted fonts.
