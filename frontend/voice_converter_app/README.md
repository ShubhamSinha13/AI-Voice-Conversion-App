# Frontend Setup Instructions

## Prerequisites
- Flutter SDK 3.13+
- Android Studio (for Android development) or Xcode (for iOS)
- iOS 12+ / Android 21+ (API level 21)

## Installation

### 1. Install Flutter (if not already installed)
```bash
# Get Flutter SDK from https://flutter.dev/docs/get-started/install
# Add Flutter to PATH
flutter doctor  # Verify installation
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Configure for iOS
```bash
cd ios
pod install
cd ..
```

### 4. Run the App

**For Development:**
```bash
flutter run
```

**For Android Release:**
```bash
flutter build apk
```

**For iOS Release:**
```bash
flutter build ios
```

## Project Structure

```
voice_converter_app/
├── lib/
│   ├── main.dart              # App entry point
│   ├── models/                # Data models (Voice, User)
│   ├── screens/               # UI screens
│   │   └── home_screen.dart   # Home with tabs
│   ├── widgets/               # Reusable widgets
│   ├── services/              # API and business logic
│   │   └── api_service.dart   # Backend communication
│   └── utils/                 # Utility functions
├── android/                   # Android configuration
├── ios/                       # iOS configuration
└── pubspec.yaml              # Dependencies
```

## Features

### Phase 1: Foundation
- [x] Project setup
- [ ] User authentication
- [ ] Predefined voices list
- [ ] Custom voice creation UI

### Phase 2: Real-time Conversion
- [ ] Voice processing engine
- [ ] Real-time inference
- [ ] Audio quality validation

### Phase 3: Call Integration
- [ ] Android call integration
- [ ] iOS call integration
- [ ] Background processing

### Phase 4: Polish
- [ ] UI refinement
- [ ] Dark mode support
- [ ] Onboarding tutorial

## Testing

```bash
flutter test  # Run unit tests
```

## Build & Deploy

See specific guides:
- [Android Deployment](docs/android_deployment.md)
- [iOS Deployment](docs/ios_deployment.md)
