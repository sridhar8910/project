# SoulSupport App

Unified workspace containing the Django REST backend and Flutter client for the SoulSupport platform.

## Project Layout

- `backend/` – Django project, including a checked-in virtual environment under `backend/venv` for convenience.
- `flutter_app/` – Flutter desktop/mobile client.
- `run_all.ps1` – Helper script that runs the backend and Flutter app together.
- `run_android.ps1` – Script for launching the Flutter client on Android (if the Android toolchain is configured).

## Prerequisites

- Windows 10/11 with PowerShell.
- Flutter SDK (3.3.0 or higher as configured in `flutter_app/pubspec.yaml`).
- Python 3.11 (if you prefer to recreate the virtual environment).
- Android Studio / Xcode optional for mobile targets.

> **Note:** `run_all.ps1` looks for a virtual environment at `.\.venv\Scripts\python.exe` and falls back to `backend\venv\Scripts\python.exe`. You can use the checked-in environment or replace it with your own.

## Initial Setup

1. Clone the repository.
2. (Optional) Recreate the Python environment:
   ```powershell
   python -m venv .venv
   .\.venv\Scripts\Activate.ps1
   pip install -r backend\requirements.txt
   ```
   The repository includes `backend\requirements.txt` generated from the bundled environment. If you skip this step, the checked-in `backend\venv` will be used.
3. Install Flutter dependencies:
   ```powershell
   cd flutter_app
   flutter pub get
   cd ..
   ```

## Environment Configuration

- Default settings (`backend/core/settings.py`) ship with `DEBUG=True`, `SECRET_KEY="change-me"`, and `ALLOWED_HOSTS=["*"]`. Update these before deploying anywhere outside local development.
- The project uses SQLite by default (`backend/db.sqlite3`). If you switch to another database, update `DATABASES["default"]` and create the corresponding environment variables.
- CORS is fully open (`CORS_ALLOW_ALL_ORIGINS = True`). Tighten this list for production builds.

## Running Everything

From the repository root run:

```powershell
.\run_all.ps1           # Desktop (Windows) by default
.\run_all.ps1 -Device chrome   # Launch the Flutter web client
.\run_all.ps1 -Device windows -Release  # Release mode build
```

The script will:

1. Start the Django dev server at `http://localhost:8000`.
2. Launch the Flutter client for the specified device.
3. Shut down the backend once you exit the Flutter process.

## Running Components Individually

### Backend

```powershell
.\.venv\Scripts\Activate.ps1  # or backend\venv\Scripts\Activate.ps1
cd backend
python manage.py migrate
python manage.py runserver 0.0.0.0:8000
```

### Flutter Client

```powershell
cd flutter_app
flutter run -d windows
```

Adjust the `-d` flag for `chrome`, `edge`, `web-server`, or any connected device.

## Tests

- Backend: `cd backend` then `python manage.py test`.
- Flutter: `cd flutter_app` then `flutter test`.
- Combined smoke test: run `flutter test test/widget_test.dart` after ensuring the main counter widget matches expectations.

## Troubleshooting

- If the script cannot find `pubspec.yaml`, make sure you are running it from the repository root.
- On first run, Flutter may need to download platform artifacts (allow time for that step).
- To switch virtual environments, update or recreate `.\.venv`; the script will automatically pick it up on the next run.
- If `run_all.ps1` complains about the Python interpreter, confirm that either `.\.venv` or `backend\venv` exists and contains an activated environment.
