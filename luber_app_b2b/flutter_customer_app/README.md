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
3. Configure environment variables:
   - `SUPABASE_URL`: Your Supabase project URL
   - `SUPABASE_ANON_KEY`: Your Supabase anonymous key

## Running the App

\`\`\`bash
flutter run --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key
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
