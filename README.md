# VARSHA Flutter

Independent college mini project for weather monitoring, rainfall forecasting, and disaster alert notifications.

## Project Structure

```text
VARSHA-Flutter/
│
├── flutter_app/          # Mobile client (Flutter, Dart, Material Design)
│   ├── android/
│   ├── ios/
│   ├── lib/
│   ├── test/
│   └── pubspec.yaml
│
├── backend/              # Python FastAPI service (migrated from VARSHA core)
│   ├── app/              # FastAPI application (routes, schemas, services)
│   ├── tests/            # Pytest test suite (159 unit/integration tests)
│   ├── requirements.txt  # Python package requirements
│   ├── .env.example      # Environment variable template
│   └── .gitignore        # Backend gitignore rules
│
├── docs/                 # Project documentation and specifications
│   └── README.md
│
├── .gitignore            # Root ignore rules
└── README.md             # Project documentation
```

## Backend Quickstart

1. Navigate to backend:
   ```bash
   cd backend
   ```
2. Create and activate Python virtual environment:
   ```bash
   python -m venv .venv
   # Windows PowerShell:
   .venv\Scripts\Activate.ps1
   ```
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Configure environment:
   ```bash
   copy .env.example .env
   ```
5. Run tests:
   ```bash
   pytest
   ```
6. Run API server:
   ```bash
   uvicorn app.main:app --reload
   ```

## Flutter App Quickstart

1. Navigate to client:
   ```bash
   cd flutter_app
   ```
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Run static analysis:
   ```bash
   flutter analyze
   ```
4. Run tests:
   ```bash
   flutter test
   ```
5. Run on device / emulator:
   ```bash
   flutter run
   ```

