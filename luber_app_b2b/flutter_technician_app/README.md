# Luber Technician App

Flutter mobile application for Luber technicians to manage oil change jobs.

## Features

- Technician authentication (sign up, sign in, sign out)
- View available jobs
- Accept and manage jobs
- Update job status (accepted, in progress, completed)
- Track earnings
- Availability toggle
- Profile management with stats

## Setup

1. Install Flutter SDK (3.0.0 or higher)
2. Run `flutter pub get` to install dependencies
3. Configure environment variables (reuse the values from the Next.js workspace):
   - `NEXT_PUBLIC_SUPABASE_LUBER_PUBLIC_SUPABASE_URL` (or `SUPABASE_URL`)
   - `NEXT_PUBLIC_SUPABASE_LUBER_PUBLIC_SUPABASE_ANON_KEY` (or `SUPABASE_ANON_KEY`)

## Running the App

\`\`\`bash
flutter run \
  --dart-define=NEXT_PUBLIC_SUPABASE_LUBER_PUBLIC_SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=NEXT_PUBLIC_SUPABASE_LUBER_PUBLIC_SUPABASE_ANON_KEY=public-anon-key
\`\`\`

## Build for Production

### Android
\`\`\`bash
flutter build apk --release
\`\`\`

### iOS
\`\`\`bash
flutter build ios --release
\`\`\`

## Project Structure

- `lib/main.dart` - App entry point and routing
- `lib/providers/` - State management providers
- `lib/screens/` - UI screens
- `lib/models/` - Data models
- `lib/services/` - API and business logic services
