import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/otp_verification_screen.dart';
import '../../features/auth/presentation/phone_auth_screen.dart';
import '../../features/auth/presentation/profile_setup_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/booking/presentation/booking_review_screen.dart';
import '../../features/booking/presentation/chat_screen.dart';
import '../../features/booking/presentation/driver_search_screen.dart';
import '../../features/booking/presentation/rating_screen.dart';
import '../../features/booking/presentation/trip_history_screen.dart';
import '../../features/booking/presentation/trip_receipt_screen.dart';
import '../../features/booking/presentation/trip_tracking_screen.dart';
import '../../features/driver/presentation/driver_dashboard_screen.dart';
import '../../features/driver/presentation/driver_earnings_screen.dart';
import '../../features/driver/presentation/driver_trip_screen.dart';
import '../../features/garage/presentation/garage_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/location/presentation/location_search_screen.dart';
import '../../features/location/presentation/map_pin_picker_screen.dart';
import '../../features/safety/presentation/safety_screen.dart';
import '../../features/wallet/presentation/wallet_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth/phone',
        builder: (context, state) => const PhoneAuthScreen(),
      ),
      GoRoute(
        path: '/auth/verify-otp',
        builder: (context, state) {
          final phone = state.uri.queryParameters['phone'] ?? '';
          final role = state.uri.queryParameters['role'] ?? 'CUSTOMER';
          return OtpVerificationScreen(phone: phone, role: role);
        },
      ),
      GoRoute(
        path: '/auth/profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/location/search',
        builder: (context, state) {
          final prefill = state.uri.queryParameters['prefill'];
          return LocationSearchScreen(prefill: prefill);
        },
      ),
      GoRoute(
        path: '/location/map-picker',
        builder: (context, state) => const MapPinPickerScreen(),
      ),
      GoRoute(
        path: '/garage',
        builder: (context, state) => const GarageScreen(),
      ),
      GoRoute(
        path: '/booking/review',
        builder: (context, state) {
          final pickup = state.uri.queryParameters['pickup'] ?? 'Current Location';
          final dropoff = state.uri.queryParameters['dropoff'] ?? 'Destination';
          final dropLat = double.tryParse(state.uri.queryParameters['dropLat'] ?? '') ?? 12.9716;
          final dropLng = double.tryParse(state.uri.queryParameters['dropLng'] ?? '') ?? 77.5946;
          return BookingReviewScreen(
            pickupAddress: pickup,
            dropoffAddress: dropoff,
            dropLat: dropLat,
            dropLng: dropLng,
          );
        },
      ),
      GoRoute(
        path: '/booking/searching/:bookingId',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId']!;
          return DriverSearchScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: '/booking/tracking/:bookingId',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId']!;
          return TripTrackingScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: '/booking/chat/:bookingId',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId']!;
          return ChatScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: '/safety',
        builder: (context, state) => const SafetyScreen(),
      ),
      GoRoute(
        path: '/booking/receipt/:bookingId',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId']!;
          return TripReceiptScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: '/booking/rate/:bookingId',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId']!;
          return RatingScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const TripHistoryScreen(),
      ),
      GoRoute(
        path: '/wallet',
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: '/driver/dashboard',
        builder: (context, state) => const DriverDashboardScreen(),
      ),
      GoRoute(
        path: '/driver/trip/:bookingId',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId']!;
          return DriverTripScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: '/driver/earnings',
        builder: (context, state) => const DriverEarningsScreen(),
      ),
    ],
  );
});
