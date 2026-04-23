# AI Voice Converter App

AI Voice Converter App is a Flutter and FastAPI project for experimenting with AI-assisted voice conversion, voice previews, custom sample uploads, and progress-tracked conversion flows. The repository is split into a Python backend and a Flutter frontend, with PostgreSQL for persistent storage.

## What Is Included

- FastAPI backend with authentication, voice, sample, preview, and conversion endpoints.
- Flutter frontend with voice browsing, conversion flows, progress tracking, and audio playback.
- PostgreSQL-backed persistence for users, voices, samples, and conversion history.
- Model download and caching helpers for local ML workflows.
- Backend and Flutter test scripts for smoke testing and regression checks.

## Tech Stack

- Backend: Python 3.10+, FastAPI, SQLAlchemy, PostgreSQL, Uvicorn, JWT auth, PyTorch-based ML helpers.
- Frontend: Flutter 3.x, Dart 3.x, Riverpod, Dio, just_audio, file_picker.
- Optional ML assets: HuBERT, RVC-style conversion assets, and audio preprocessing utilities.

## Repository Layout

```text
.
├── backend/
│   ├── app/
│   ├── scripts/
│   ├── test_*.py
│   ├── requirements.txt
│   └── README.md
├── frontend/voice_converter_app/
│   ├── lib/
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
├── docs/
└── LICENSE
```

## Prerequisites

- Python 3.10+ for the backend.
- Flutter SDK 3.x for the frontend.
- PostgreSQL 12+.
- Git and internet access for downloading local ML assets.
- Optional: CUDA-capable GPU for faster inference.

## Backend Setup

```bash
cd backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
```

Set at least these environment variables in `backend/.env`:

- `DATABASE_URL`
- `SECRET_KEY`
- `API_HOST`
- `API_PORT`
- `MODEL_PATH`

Start the API with:

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

The API will be available at `http://localhost:8000` and the docs at `http://localhost:8000/docs`.

## Frontend Setup

```bash
cd frontend/voice_converter_app
flutter pub get
flutter run
```

If you want to target a specific device, use:

```bash
flutter devices
flutter run -d <device-id>
```

## Local Model Downloads

Large model files are not committed to the repository. Use the backend download script to fetch them locally when needed:

```bash
cd backend
python scripts/download_models.py
```

Downloaded cache files are stored under `backend/model_cache/`, which is ignored by Git.

## Running Tests

Backend-focused checks:

```bash
cd backend
python test_imports.py
python test_api.py
python test_phase2_endpoints.py
python test_phase3_conversion.py
```

Flutter tests:

```bash
cd frontend/voice_converter_app
flutter test
```

## API Overview

Authentication:

- `POST /auth/register`
- `POST /auth/login`

Voice management:

- `GET /api/voices/predefined`
- `GET /api/voices/my-voices`
- `POST /api/voices/create`
- `GET /api/voices/{voice_id}`
- `DELETE /api/voices/{voice_id}`

Voice samples:

- `POST /api/voice-samples/upload/{voice_id}`

Conversion and preview:

- `POST /api/voices/{voice_id}/convert`
- `GET /api/voices/{voice_id}/preview`

Health:

- `GET /health`

## Environment Notes

- Default backend host is `0.0.0.0` and the default port is `8000`.
- Uploaded audio and generated outputs are written to the `uploads/` directories under backend.
- The Flutter app includes progress tracking and preview flows for conversions.
- Large model artifacts stay out of Git to keep the repository light.

## Troubleshooting

- If the backend cannot connect to PostgreSQL, verify `DATABASE_URL` and that the database server is running.
- If Flutter cannot reach the backend on Android emulator, use `10.0.2.2` instead of `localhost`.
- If a model download fails, delete the partial files under `backend/model_cache/` and rerun the download script.
- If `flutter pub get` changes platform files, commit only the source changes you actually need.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for the full text.
