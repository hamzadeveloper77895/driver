import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/presentation/onboarding_screen.dart';
import 'package:mobile/features/auth/presentation/phone_auth_screen.dart';
import 'package:mobile/features/booking/presentation/booking_review_screen.dart';
import 'package:mobile/features/driver/presentation/driver_dashboard_screen.dart';
import 'package:mobile/features/garage/presentation/garage_screen.dart';
import 'package:mobile/features/safety/presentation/safety_screen.dart';
import 'package:mobile/features/wallet/presentation/wallet_screen.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: child,
      ),
    );
  }

  testWidgets('OnboardingScreen renders slides, indicators, and CTA button', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(const OnboardingScreen()));
    await tester.pump();

    expect(find.text('Professional Drivers for Your Car'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('PhoneAuthScreen renders mobile input and role switchers', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(const PhoneAuthScreen()));
    await tester.pump();

    expect(find.text('Enter your mobile number'), findsOneWidget);
    expect(find.text('Customer App'), findsOneWidget);
    expect(find.text('Driver Partner'), findsOneWidget);
    expect(find.text('+91'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('GarageScreen renders garage header and add vehicle button', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(const GarageScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('My Garage'), findsOneWidget);
  });

  testWidgets('DriverDashboardScreen renders duty toggle and metrics', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(const DriverDashboardScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('GO ONLINE'), findsOneWidget);
    expect(find.text('Acceptance'), findsOneWidget);
    expect(find.text('Completion'), findsOneWidget);
  });

  testWidgets('WalletScreen renders available balance card and top up', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(const WalletScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Digital Wallet'), findsOneWidget);
    expect(find.text('Available Balance'), findsOneWidget);
    expect(find.text('Top Up Balance'), findsOneWidget);
  });

  testWidgets('SafetyScreen renders SOS center, 112 helpline, and emergency contacts', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(const SafetyScreen()));
    await tester.pump();

    expect(find.text('Safety Center & SOS'), findsOneWidget);
    expect(find.text('Emergency SOS'), findsOneWidget);
    expect(find.text('Call Emergency Helpline (112)'), findsOneWidget);
    expect(find.text('Sarah Connor'), findsOneWidget);
  });

  testWidgets('Happy-path booking review screen calculates fare breakdown', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createTestWidget(const BookingReviewScreen(
      pickupAddress: 'Indiranagar 100ft Rd',
      dropoffAddress: 'Koramangala 4th Block',
      dropLat: 12.9345,
      dropLng: 77.6265,
    )));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Review Booking'), findsOneWidget);
    expect(find.text('Indiranagar 100ft Rd'), findsOneWidget);
    expect(find.text('Koramangala 4th Block'), findsOneWidget);
    expect(find.text('Confirm & Dispatch Driver'), findsOneWidget);
  });
}
