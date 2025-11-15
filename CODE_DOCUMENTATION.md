👩‍⚕️ **SoulSupport Code Documentation & Algorithms**
====================================================

This document explains the entire codebase by walking through every backend (Python/Django) and frontend (Flutter/Dart) module, showing how the algorithms work, and illustrating the data flow between layers. Use this file as a companion to `README.md` when you need a deeper understanding of “how the code works under the hood”.

---

TABLE OF CONTENTS
-----------------

1. [System Overview](#system-overview)
2. [Backend Architecture](#backend-architecture)
    1. [API Modules](#api-modules)
    2. [Data Models](#data-models)
    3. [Serializers](#serializers)
    4. [Views & Algorithms](#views--algorithms)
    5. [URL Routing Graph](#url-routing-graph)
3. [Frontend Architecture](#frontend-architecture)
    1. [App Entry & Routing](#app-entry--routing)
    2. [Service Layer (ApiClient)](#service-layer-apiclient)
    3. [Screen-by-Screen Reference](#screen-by-screen-reference)
4. [End-to-End Algorithms](#end-to-end-algorithms)
    1. [Registration & OTP Flow](#registration--otp-flow)
    2. [Mood Update & Reset Logic](#mood-update--reset-logic)
    3. [Wallet Billing](#wallet-billing)
    4. [Session Scheduling Rules](#session-scheduling-rules)
    5. [Nickname Propagation](#nickname-propagation)
    6. [Breathing Animation Cycle](#breathing-animation-cycle)
5. [Data Flow Examples](#data-flow-examples)
6. [Testing Hooks](#testing-hooks)
7. [Extending the Codebase](#extending-the-codebase)

---

1. SYSTEM OVERVIEW
------------------

- **Backend**: Django REST Framework (DRF) provides the API surface. Authentication uses JWT. Models live in `backend/api/models.py`, and everything is exposed via `backend/api/views.py`.
- **Frontend**: Flutter app located under `flutter_app/`. `main.dart` bootstraps the app. Screen-level widgets live in `flutter_app/lib/screens/`, and network calls happen in `flutter_app/lib/services/api_client.dart`.
- **Communication**: All client requests go through `ApiClient`, which adds JWT headers, handles token refresh, and serializes responses into typed models or dictionaries.

---

2. BACKEND ARCHITECTURE
-----------------------

### API Modules

| File | Responsibility |
|------|----------------|
| `api/models.py` | Database schema (UserProfile, WellnessTask, MoodLog, etc.) |
| `api/serializers.py` | Validation & (de)serialization rules |
| `api/views.py` | REST endpoints (auth, wallet, mood, content, sessions, etc.) |
| `api/urls.py` | URL routing to view classes |
| `api/migrations/` | Schema migrations (nickname field, wallet defaults, etc.) |

### Data Models (Highlights)

- `UserProfile`: Extends Django User with full name, nickname, phone, age, gender, wallet balance (rupees), mood tracking fields, timezone, UI preferences.
- `WellnessTask`: Stores customizable tasks categorized as daily or evening.
- `WellnessJournalEntry`: Personal journal with mood tags and entry types.
- `SupportGroup` & `SupportGroupMembership`: Manage community groups.
- `UpcomingSession`: Scheduled counselling sessions with metadata.
- `MoodLog`, `GuidanceResource`, `MindCareBooster`, `MeditationSession`, `MusicTrack`: Content and tracking models.

### Serializers

- `RegisterSerializer`: Validates OTP token, normalizes username/email, creates user + profile (including favorite nickname).
- `UserProfileSerializer` & `UserSettingsSerializer`: Expose/accept profile fields (nickname included).
- Specialized serializers exist for wallets, tasks, boosters, meditations, etc., controlling read/write fields.

### Views & Algorithms

Key endpoints inside `api/views.py` (each inherits from DRF base classes):

| View | Purpose |
|------|---------|
| `RegisterView`, `RegistrationSendOTPView`, `RegistrationVerifyOTPView` | OTP-driven signup pipeline |
| `EmailOrUsernameTokenObtainPairView` | JWT login |
| `ProfileView`, `UserSettingsView` | Profile + nickname + settings management |
| `WalletDetailView`, `WalletRechargeView`, `WalletUsageView` | Balance tracking and service billing |
| `MoodUpdateView` | Mood recording with timezone reset logic |
| `WellnessTaskListCreateView`, `WellnessTaskDetailView` | Task CRUD |
| `WellnessJournalEntry*` | Journal CRUD |
| `SupportGroupListView` | Group listing/join/leave |
| `UpcomingSessionListCreateView`, `QuickSessionView` | Session management |
| `MindCareBoosterListView`, `MeditationSessionListView`, `ProfessionalGuidanceListView` | Content APIs |

#### Example Algorithm: Mood Update

Pseudo-code summarizing `MoodUpdateView.post()`:

```
if profile.timezone missing:
    detect from request or fallback to server tz
if provided timezone differs from stored:
    update profile.timezone

local_now = utc_now -> convert to timezone
if last_mood_updates_date != local_now.date:
    reset mood_updates_count to 0

if mood_updates_count >= 3:
    compute next midnight in timezone
    return {"status": "limit_reached", "reset_at_local": ...}

record mood:
    profile.last_mood = payload.value
    profile.last_mood_updated = now
    profile.mood_updates_count += 1
    MoodLog.create(...)
return {"status": "ok", "updates_used": mood_updates_count}
```

#### Example Algorithm: Wallet Deduction

```
rate = SERVICE_RATE_MAP[service]  # call=5, chat=1
min_balance = SERVICE_MIN_BALANCE_MAP[service]
charge = minutes * rate

if wallet < min_balance:
    return 400: minimum balance required
if wallet < charge:
    return 400: insufficient funds

wallet -= charge
save profile
return {"charged": charge, "wallet_minutes": wallet}
```

### URL Routing Graph

```
/api/
  auth/
    register/
    send-otp/
    verify-otp/
    token/
    token/refresh/
  profile/
  settings/
  mood/
  wallet/, wallet/recharge/, wallet/use/
  wellness/
    tasks/, tasks/<id>/
    journals/, journals/<id>/
  support-groups/
  sessions/, sessions/<id>/, sessions/quick/
  reports/analytics/
  guidance/resources/
  content/
    boosters/
    meditations/
    music/
```

---

3. FRONTEND ARCHITECTURE
------------------------

### App Entry & Routing

- `lib/main.dart` bootstraps `MyApp`, sets global theme, routes to `SplashScreen`.
- Routing strategy:
  - `SplashScreen` checks stored tokens → loads profile → navigates to `HomeScreen` or `LoginScreen`.
  - `Navigator.push` is used for sub-pages (Wallet, Settings, Profile, etc.).

### Service Layer (`ApiClient`)

Located at `lib/services/api_client.dart`. Responsibilities:

1. **Token Storage**: Stores JWT access/refresh tokens in secure storage / shared preferences.
2. **HTTP Helpers**: `_sendAuthorized` attaches Authorization header, handles 401 by refreshing token.
3. **Endpoints**: Each API call is encapsulated (login, register, send OTP, wallet, mood, tasks, sessions, etc.).
4. **Models**: Local Dart classes (`UserSettings`, `WalletInfo`, `MindCareBoosterItem`, etc.) parse JSON responses.

### Screen-by-Screen Reference

| Screen | File | Highlights |
|--------|------|------------|
| Splash | `splash_screen.dart` | Animated splash, profile fetch, navigation |
| Login | `login_screen.dart` | Gradient design, form validation, Enter-to-submit |
| Register | `register_screen.dart` | Three-step wizard (basic info → OTP → password) |
| Home | `home_screen.dart` | Massive dashboard: header, mood card, quick access grid, wallet indicator, chat button |
| Wallet | `wallet_page.dart` | Shows balance (₹), recharge options, custom amount input |
| Schedule Session | `schedule_session_page.dart` | Date/time pickers, 1-hour recommendation, 10-min minimum logic |
| Settings | `settings_page.dart` | Account info, notification toggles, dark mode, logout |
| MindCare Booster | `mindcare_booster_page.dart` | Grid of boosters, bottom sheet details, filtered categories |
| Meditation | `meditation_page.dart` | List by category, play buttons |
| Support Groups | `support_groups_page.dart` | Join/leave groups with counters |
| Reports & Analytics | `reports_analytics_page.dart` | Graphs for mood/task/session data |
| Breathing | `breathing_page.dart` | Animated inhale/exhale circle with adjustable phase length |

---

4. END-TO-END ALGORITHMS
------------------------

### Registration & OTP Flow

1. **User enters basic info** (username, name, nickname, age, gender, phone, email).
2. `sendRegistrationOtp(email)` → backend sends OTP email (console backend in dev).
3. User enters OTP → `verifyRegistrationOtp(email, code)` → returns OTP token.
4. User sets password → `register` call with OTP token + personal info.
5. Backend validates OTP via `EmailOTP` model, creates Django `User` + `UserProfile`.
6. On success, user is prompted to login.

### Mood Update & Reset Logic

1. Flutter mood card calls `_api.updateMood(value, timezone)`.
2. Backend resolves timezone (request payload → stored profile → server default).
3. If new day in timezone → reset `mood_updates_count`.
4. If user already used 3 updates → respond with limit reached + reset time.
5. Otherwise record mood, increment count, return updated data.
6. Flutter updates UI and caches timezone for future resets.

### Wallet Billing

1. Wallet detail: `GET /wallet/` returns balance, per-service rates, minimums.
2. Recharge: `POST /wallet/recharge/` adds amount directly (integers represent rupees).
3. During services (call/chat) Flutter calls `POST /wallet/use/` with service type + duration.
4. Backend enforces minimum and per-minute rate, deducts, and returns new balance.

### Session Scheduling Rules

Pseudo-code from `schedule_session_page.dart`:

```
start = combine(selected_date, selected_time)
now = DateTime.now()
earliest = now + 10 minutes
recommended = now + 1 hour

if start < earliest:
    show snackbar "choose at least 10 minutes from now"
else if start < recommended:
    show dialog explaining recommendation
    if user cancels -> abort
    else -> proceed

call _api.scheduleQuickSession(start, title, notes)
```

### Nickname Propagation

1. **Registration** collects nickname (defaults to username if blank).
2. Backend stores it in `UserProfile.nickname`.
3. API responses include nickname everywhere.
4. Home screen uses `nickname` → `full_name` → `username` fallback for greeting and avatar.
5. Profile page includes nickname field; updates call `updateUserSettings` to persist to backend.
6. Settings account sheet shows nickname separate from full name.

### Breathing Animation Cycle

Located in `breathing_page.dart`:

```
phaseSeconds = dropdown value (3,4,5,6,8,10)
_controller.duration = Duration(seconds: phaseSeconds)
_expanding flag indicates inhale/exhale state

Animation flow:
  start -> forward -> complete -> set expanding=false -> reverse
  reverse complete -> set expanding=true -> forward

Displayed text = "Inhale" if expanding else "Exhale"
```

---

5. DATA FLOW EXAMPLES
---------------------

### Example: Updating Mood

```
Flutter UI (slider) -> _attemptMoodChange() -> ApiClient.updateMood()
 -> HTTP POST /api/mood/
 -> MoodUpdateView validates, updates DB, returns JSON
 -> ApiClient parses MoodUpdateResult
 -> HomeScreen updates state, shows snackbar, adjusts counters
```

### Example: Scheduling Session

```
User selects date/time -> _saveSession()
 -> validation (10 min min, 1 hr recommended)
 -> ApiClient.scheduleQuickSession()
 -> POST /api/sessions/quick/
 -> QuickSessionView handles creation, returns UpcomingSessionSerializer data
 -> Flutter shows success message + pops back with new session object
```

### Example: Wallet Recharge

```
WalletPage -> tap amount -> _recharge()
 -> ApiClient.rechargeWallet(amount)
 -> POST /api/wallet/recharge/
 -> WalletRechargeView increments wallet_minutes, returns new balance
 -> Flutter updates card + notifies parent (HomeScreen)
```

---

6. TESTING HOOKS
----------------

- **Backend**: `python manage.py test` runs default Django + API tests.
- **Flutter**: `flutter test` executes widget/unit tests.
- **Manual QA**: Use `run_all.ps1` to spin everything up, then exercise flows (register, login, mood update, wallet, scheduling).
- **Logging**: Backend prints to console; Flutter uses `debugPrint` and snackbars for user feedback.

---

7. EXTENDING THE CODEBASE
-------------------------

### Adding a New Backend Feature

1. **Model**: Update `models.py`, run `makemigrations`.
2. **Serializer**: Add serialization/validation logic.
3. **View**: Create API view using DRF classes.
4. **URL**: Register endpoint in `api/urls.py`.
5. **Flutter**: Implement matching method in `ApiClient`, update UI screen.

### Adding a New Screen

1. Create file in `flutter_app/lib/screens/`.
2. Add route or direct `Navigator.push`.
3. Fetch data via `ApiClient`.
4. Style with `_Palette` or new theme classes.

### Ensuring Nickname Privacy

Display logic should prefer `nickname` when showing names to counsellors or other users. When implementing new features, follow this pattern:

```
String get displayName {
  if (profile.nickname?.isNotEmpty ?? false) return profile.nickname!;
  if (profile.fullName?.isNotEmpty ?? false) return profile.fullName!;
  return profile.username ?? 'Soul Support User';
}
```

---

📌 Summary
----------

- Backend provides a rich set of REST endpoints via Django/DRF, with JWT auth, OTP registration, wallet billing, and timezone-aware mood tracking.
- Frontend uses Flutter with a centralized `ApiClient` for all HTTP requests, stateful widgets for each major feature, and consistent styling through `_Palette`.
- Algorithms covering OTP registration, wallet deductions, mood limits, session scheduling, nickname usage, and breathing animations are carefully implemented and documented above.
- Follow the described workflows to safely extend, test, and deploy the SoulSupport platform.

