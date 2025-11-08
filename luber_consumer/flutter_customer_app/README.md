# Luber Customer App

Flutter mobile application for customers to book on-demand oil change services.

## Features

- Authentication (Sign In / Sign Up)
- Book oil change services
- Real-time job tracking
- Manage vehicles, addresses, and payment methods
- Service history
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
- `stripePublishableKey`: Your Stripe publishable key
- `apiBaseUrl`: Your Next.js API base URL (e.g., https://your-app.vercel.app)

3. Run the app:
\`\`\`bash
flutter run
\`\`\`

## Project Structure

\`\`\`
lib/
├── main.dart                 # App entry point
├── config/
│   └── constants.dart        # Environment configuration
├── models/
│   ├── user_model.dart       # User data model
│   ├── vehicle_model.dart    # Vehicle data model
│   └── job_model.dart        # Job data model
├── providers/
│   ├── auth_provider.dart    # Authentication state management
│   └── job_provider.dart     # Job state management
└── screens/
    ├── splash_screen.dart    # Initial loading screen
    ├── auth/                 # Authentication screens
    ├── home/                 # Home dashboard
    ├── booking/              # Booking flow
    ├── job/                  # Job tracking
    └── profile/              # User profile
\`\`\`

## Backend Integration

This app connects to the Next.js backend you built earlier. Make sure:

1. The Next.js API is deployed and accessible
2. Supabase database is set up with the correct schema
3. Stripe is configured with the correct keys
4. CORS is enabled on your API routes if needed

## Building for Production

### Android
\`\`\`bash
flutter build apk --release
\`\`\`

### iOS
\`\`\`bash
flutter build ios --release
\`\`\`

## Notes

- The booking flow screen is a placeholder and needs full implementation
- Google Maps integration requires API keys configured in platform-specific files
- Push notifications require FCM setup
- Real-time location tracking requires background location permissions
