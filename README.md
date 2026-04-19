# AI Voice Conversion App

A mobile application that converts voices in real-time using AI/ML for calls, videos, and presentations.

## Overview

**Two Core Features:**

1. **Predefined Voices** - 12 built-in voices ready to use instantly:
   - Female Voice 1, 2, 3, 4 (different tones)
   - Men Voice 1, 2, 3, 4 (different tones)
   - Special: Robotic, Whisper, Cartoon, Elder

2. **Custom Voice Cloning** - Clone any voice with progressive accuracy:
   - 1 sample: 80% accuracy
   - 2 samples: 90% accuracy
   - 3 samples: 96% accuracy
   - 4+ samples: 99%+ accuracy

## Technology Stack

### Backend
- **Framework**: FastAPI (Python)
- **Database**: PostgreSQL
- **ML**: RVC + HuBERT + HiFi-GAN
- **Inference**: ONNX Runtime
- **Auth**: JWT + Bcrypt

### Frontend
- **Framework**: Flutter (Dart)
- **State Management**: Provider/Riverpod
- **HTTP**: Dio
- **Audio**: flutter_sound, record
- **Storage**: Hive, SQLite

## Project Structure

```
AI voice/
├── backend/
│   ├── app/
│   │   ├── api/            # API routes
│   │   ├── models/         # Database models
│   │   ├── services/       # Business logic
│   │   ├── schemas/        # Request/response schemas
│   │   ├── database/       # Database setup
│   │   └── utils/          # Utilities
│   ├── ml_models/          # ML models
│   ├── requirements.txt    # Python dependencies
│   ├── .env.example        # Environment config
│   └── README.md           # Backend docs
│
├── frontend/
│   └── voice_converter_app/
│       ├── lib/
│       │   ├── main.dart
│       │   ├── models/      # Data models
│       │   ├── screens/     # UI screens
│       │   ├── services/    # API calls
│       │   └── widgets/     # Reusable UI
│       ├── pubspec.yaml     # Dependencies
│       └── README.md        # Frontend docs
│
└── docs/                    # Documentation

```

## Quick Start

### Backend
```bash
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
# Configure .env with database credentials
uvicorn app.main:app --reload
```

### Frontend
```bash
cd frontend/voice_converter_app
flutter pub get
flutter run
```

## API Endpoints

### Authentication
- `POST /auth/register` - Register user
- `POST /auth/login` - Login

### Voices
- `GET /api/voices/predefined` - Get predefined voices
- `GET /api/voices/my-voices` - Get custom voices
- `POST /api/voices/create` - Create voice
- `POST /api/voices/{id}/add-sample` - Add sample
- `DELETE /api/voices/{id}` - Delete voice

## Implementation Timeline

- **Phase 1** (2-3 weeks): Backend + voice training
- **Phase 2** (2-3 weeks): Real-time conversion
- **Phase 3** (3-4 weeks): Call integration
- **Phase 4** (2 weeks): UI/UX polish

**Total: 9-12 weeks**

## Features Roadmap

### Phase 1 ✅
- User authentication
- Voice database setup
- Accuracy scoring system

### Phase 2
- Real-time voice conversion
- On-device inference
- Quality validation

### Phase 3
- Android call integration
- iOS VoIP support
- Background processing

### Phase 4
- Professional UI
- Advanced features (blending, effects)
- Analytics dashboard

## Key Architecture Decisions

| Component | Choice | Rationale |
|-----------|--------|-----------|
| **Framework** | Flutter | Cross-platform, superior audio |
| **ML Model** | RVC + HuBERT + HiFi-GAN | Accuracy-first, human-like |
| **Database** | PostgreSQL | Reliable, scalable |
| **Inference** | ONNX + Quantized | Fast, mobile-optimized |
| **Auth** | JWT | Stateless, scalable |

## Accuracy Guarantee

Voice conversion accuracy depends on samples provided:

| Samples | Accuracy | Use Case |
|---------|----------|----------|
| 1 sample | 80-85% | Casual fun |
| 2 samples | 90-93% | Most calls |
| 3 samples | 96-98% | Professional |
| 4+ samples | 99%+ | Presentations |

## Legal & Privacy

- ✅ Custom voice cloning (user/friend voices)
- ✅ Predefined voices (synthetic, no copyright)
- ✅ On-device processing (privacy-first)
- ❌ Celebrity voice cloning (avoided for copyright)
- ❌ Impersonation (platform ToS compliant)

## Contributing

[To be added]

## License

[To be added]

## Contact

[To be added]

---

**Status**: Initial implementation phase
**Last Updated**: April 19, 2026
