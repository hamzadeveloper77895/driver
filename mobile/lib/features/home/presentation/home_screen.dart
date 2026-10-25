import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/domain/auth_state.dart';
import '../../booking/domain/booking_state.dart';
import '../../garage/domain/garage_state.dart';
import '../../wallet/domain/wallet_state.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedCategoryIndex = 0;
  final List<String> _categories = [
    'Hourly Drive',
    'Outstation',
    'Car Care',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingNotifierProvider.notifier).fetchActiveBooking();
      ref.read(walletNotifierProvider.notifier).fetchWallet();
      ref.read(garageNotifierProvider.notifier).fetchVehicles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final bookingState = ref.watch(bookingNotifierProvider);
    final garageState = ref.watch(garageNotifierProvider);
    final walletState = ref.watch(walletNotifierProvider);

    final activeBooking = bookingState.activeBooking;
    final balance = walletState.wallet?.balance ?? 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Simulated Map Background
          _buildMapBackground(),

          // Top Header Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _showUserMenu(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.person, color: AppColors.primaryLight),
                    ),
                  ),
                  const Spacer(),
                  // Switch to Driver Mode Quick Button
                  IconButton(
                    tooltip: 'Switch to Driver Partner Mode',
                    onPressed: () async {
                      await ref.read(authNotifierProvider.notifier).switchRole('DRIVER');
                      if (context.mounted) context.go('/driver/dashboard');
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primaryLight.withOpacity(0.5)),
                      ),
                      child: const Icon(Icons.drive_eta_rounded, color: AppColors.primaryLight, size: 20),
                    ),
                  ),
                  // Safety Shield Quick Access
                  IconButton(
                    onPressed: () => context.push('/safety'),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: const Icon(Icons.shield_rounded, color: AppColors.success, size: 20),
                    ),
                  ),
                  // Wallet Balance Pill
                  GestureDetector(
                    onTap: () => context.push('/wallet'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet_rounded, size: 16, color: AppColors.secondary),
                          const SizedBox(width: 6),
                          Text(
                            '\$${balance.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Active Trip Floating Alert (if any active ride)
          if (activeBooking != null)
            Positioned(
              top: 110,
              left: 16,
              right: 16,
              child: GlassCard(
                color: AppColors.primary.withOpacity(0.92),
                onTap: () {
                  if (activeBooking.status == 'REQUESTED' || activeBooking.status == 'SEARCHING') {
                    context.push('/booking/searching/${activeBooking.id}');
                  } else {
                    context.push('/booking/tracking/${activeBooking.id}');
                  }
                },
                child: Row(
                  children: [
                    const Icon(Icons.navigation_rounded, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Trip: ${activeBooking.status}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            'Tap to view live tracking & OTP',
                            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white),
                  ],
                ),
              ),
            ),

          // Bottom Interactive Sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Category selection tabs
                  Row(
                    children: List.generate(_categories.length, (index) {
                      final isSelected = _selectedCategoryIndex == index;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedCategoryIndex = index),
                          child: Container(
                            margin: EdgeInsets.only(right: index < _categories.length - 1 ? 8 : 0),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.surfaceLight.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _categories[index],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  // Where to search trigger card
                  GlassCard(
                    padding: const EdgeInsets.all(14),
                    onTap: () => context.push('/location/search'),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.search_rounded, color: AppColors.primaryLight, size: 20),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Where would you like to drive?',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Pickup: Current Location',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Selected Garage Car Preview
                  GestureDetector(
                    onTap: () => context.push('/garage'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.background.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.06)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.directions_car_filled_outlined, size: 20, color: AppColors.secondary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              garageState.selectedVehicle != null
                                  ? 'Car: ${garageState.selectedVehicle!.displayName} (${garageState.selectedVehicle!.transmission})'
                                  : 'Select Vehicle from Garage',
                              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                            ),
                          ),
                          const Text(
                            'Change',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Saved places pills
                  Row(
                    children: [
                      _buildPlaceChip(Icons.home_rounded, 'Home', () => context.push('/location/search?prefill=Home')),
                      const SizedBox(width: 8),
                      _buildPlaceChip(Icons.work_rounded, 'Office', () => context.push('/location/search?prefill=Office')),
                      const SizedBox(width: 8),
                      _buildPlaceChip(Icons.history_rounded, 'History', () => context.push('/history')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceChip(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapBackground() {
    return Container(
      color: const Color(0xFF0F172A),
      child: Stack(
        children: [
          // Stylized map grid lines
          CustomPaint(
            size: Size.infinite,
            painter: _MapGridPainter(),
          ),
          // User current location marker
          Center(
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withOpacity(0.6), blurRadius: 16),
                ],
              ),
            ),
          ),
          // Nearby simulated available driver markers
          const Positioned(
            top: 280,
            left: 120,
            child: _DriverMarker(bearing: 45),
          ),
          const Positioned(
            top: 240,
            right: 90,
            child: _DriverMarker(bearing: 180),
          ),
          const Positioned(
            bottom: 340,
            left: 80,
            child: _DriverMarker(bearing: 310),
          ),
        ],
      ),
    );
  }

  void _showUserMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final auth = ref.watch(authNotifierProvider);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(auth.user?.fullName ?? 'Valued Customer', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(auth.user?.phone ?? ''),
                ),
                const Divider(color: AppColors.divider),
                ListTile(
                  leading: const Icon(Icons.drive_eta_rounded, color: AppColors.primaryLight),
                  title: const Text('Switch to Driver Partner Mode', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
                  subtitle: const Text('Go Online, accept incoming rides & view earnings'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ref.read(authNotifierProvider.notifier).switchRole('DRIVER');
                    if (context.mounted) context.go('/driver/dashboard');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.directions_car_rounded, color: AppColors.secondary),
                  title: const Text('My Garage & Vehicles'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/garage');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history_rounded, color: AppColors.primaryLight),
                  title: const Text('Ride History'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/history');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.warning),
                  title: const Text('Digital Wallet'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/wallet');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.shield_outlined, color: AppColors.success),
                  title: const Text('Safety & SOS'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/safety');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                  title: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ref.read(authNotifierProvider.notifier).logout();
                    if (context.mounted) context.go('/auth/phone');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DriverMarker extends StatelessWidget {
  final double bearing;
  const _DriverMarker({required this.bearing});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: bearing * 3.14159 / 180,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 6),
          ],
        ),
        child: const Icon(Icons.navigation, size: 16, color: AppColors.secondary),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1.0;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
