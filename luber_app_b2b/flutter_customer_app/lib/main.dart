import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/shop_selection_screen.dart';
import 'screens/booking/new_booking_screen.dart';
import 'screens/booking/booking_details_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/vehicles/vehicles_screen.dart';
import 'screens/booking/shop_services_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/shop_provider.dart';
import 'providers/vehicle_provider.dart';
import 'config/supabase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SupabaseOptions.ensureConfigured();
  await Supabase.initialize(
    url: SupabaseOptions.url,
    anonKey: SupabaseOptions.anonKey,
  );

  runApp(const LuberCustomerApp());
}

class LuberCustomerApp extends StatelessWidget {
  const LuberCustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => ShopProvider()),
        ChangeNotifierProvider(create: (_) => VehicleProvider()),
      ],
      child: MaterialApp.router(
        title: 'Luber Customer',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1E40AF),
            primary: const Color(0xFF1E40AF),
            secondary: const Color(0xFFF97316),
          ),
          textTheme: GoogleFonts.interTextTheme(),
          useMaterial3: true,
        ),
        routerConfig: _router,
      ),
    );
  }
}

final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/shop-selection',
      builder: (context, state) => const ShopSelectionScreen(),
    ),
    GoRoute(
      path: '/shop-services',
      builder: (context, state) => const ShopServicesScreen(),
    ),
    GoRoute(
      path: '/new-booking',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>?;
        return NewBookingScreen(
          selectedShop: extras?['shop'] as Map<String, dynamic>?,
          selectedPackage: extras?['package'] as Map<String, dynamic>?,
        );
      },
    ),
    GoRoute(
      path: '/booking/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return BookingDetailsScreen(bookingId: id);
      },
    ),
    GoRoute(
      path: '/vehicles',
      builder: (context, state) => const VehiclesScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);
