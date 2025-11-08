# Luber Technician App

Flutter mobile application for technicians to accept and complete oil change service jobs.

## Features

- Technician application system
- Find nearby available jobs
- Accept and complete jobs
- Real-time location tracking
- Photo uploads for completed work
- Earnings tracking
- Profile management

## Setup

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK
- Android Studio / Xcode for mobile development

### Installation

1. Install dependencies:
\`\`\`bash
flutter pub get
\`\`\`

2. Configure environment variables:

Update `lib/config/constants.dart` with your actual values:
- `supabaseUrl`: Your Supabase project URL
- `supabaseAnonKey`: Your Supabase anon key
- `apiBaseUrl`: Your Next.js API base URL

3. Run the app:
\`\`\`bash
flutter run
\`\`\`

## Project Structure

\`\`\`
lib/
├── main.dart                          # App entry point
├── config/
│   └── constants.dart                 # Environment configuration
├── models/
│   ├── technician_model.dart          # Technician data model
│   └── job_model.dart                 # Job data model
├── providers/
│   ├── auth_provider.dart             # Authentication state
│   ├── job_provider.dart              # Job management
│   └── location_provider.dart         # Location tracking
└── screens/
    ├── splash_screen.dart             # Initial loading
    ├── auth/                          # Authentication screens
    ├── home/                          # Home dashboard
    ├── jobs/                          # Job browsing and management
    └── profile/                       # Technician profile
\`\`\`

## Backend Integration

This app connects to the Next.js backend and requires:

1. The Next.js API deployed and accessible
2. Supabase database with correct schema
3. Admin approval for technician accounts

## Building for Production

### Android
\`\`\`bash
flutter build apk --release
\`\`\`

### iOS
\`\`\`bash
flutter build ios --release
\`\`\`

## Important Notes

- Technicians must be approved by admin before accepting jobs
- Location permissions are required for job matching
- Camera permissions needed for photo uploads
- Background location tracking during active jobs
