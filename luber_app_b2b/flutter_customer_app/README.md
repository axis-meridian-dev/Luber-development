# Luber Customer App

Flutter mobile application for Luber customers to book on-demand oil changes.

## Features

- User authentication (sign up, sign in, sign out)
- Browse available services
- Book oil changes with scheduling
- View booking history
- Manage vehicles
- User profile management

## Setup

1. Install Flutter SDK (3.0.0 or higher)
2. Run `flutter pub get` to install dependencies
3. Configure environment variables (reuse the same values that power the Next.js web app):
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
