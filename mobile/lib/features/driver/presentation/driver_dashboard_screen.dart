import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/domain/auth_state.dart';
import '../domain/driver_state.dart';

class DriverDashboardScreen extends ConsumerStatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  ConsumerState<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends ConsumerState<DriverDashboardScreen> {
  Timer? _offerPollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(driverNotifierProvider.notifier).fetchEarnings();
    });

    _offerPollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      final driver = ref.read(driverNotifierProvider);
      if (driver.dutyStatus == 'ONLINE') {
        ref.read(driverNotifierProvider.notifier).checkOffers();
      }
    });
  }

  @override
  void dispose() {
    _offerPollTimer?.cancel();
    super.dispose();
  }

  void _showIncomingOfferModal(Map<String, dynamic> offer) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _IncomingOfferSheet(offer: offer),
    );
  }

  @override
  Widget build(BuildContext context) {
    final driverState = ref.watch(driverNotifierProvider);
    final auth = ref.watch(authNotifierProvider);
    final isOnline = driverState.dutyStatus == 'ONLINE';
    final isOnTrip = driverState.dutyStatus == 'ON_TRIP';
    final earnings = driverState.earnings?['total_earnings'] ?? 142.50;

    // Listen for incoming offer
    ref.listen(driverNotifierProvider, (prev, next) {
      if (next.pendingOffer != null && (prev?.pendingOffer == null || prev?.pendingOffer?['id'] != next.pendingOffer?['id'])) {
        _showIncomingOfferModal(next.pendingOffer!);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Simulated Radar/Map Background
          Container(
            color: const Color(0xFF0B132B),
            child: Center(
              child: isOnline
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.success.withOpacity(0.1),
                            border: Border.all(color: AppColors.success.withOpacity(0.3), width: 2),
                          ),
                          child: const Icon(Icons.radar_rounded, size: 56, color: AppColors.success),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Searching for ride requests nearby...',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.power_settings_new_rounded, size: 64, color: AppColors.textSecondary),
                        SizedBox(height: 16),
                        Text(
                          'You are currently OFFLINE\nSwitch duty toggle below to start receiving trips.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
            ),
          ),

          // Top Header Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Text(
                      auth.user?.fullName?.isNotEmpty == true ? auth.user!.fullName![0] : 'D',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(auth.user?.fullName ?? 'Partner Chauffeur', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const Row(
                        children: [
                          Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                          SizedBox(width: 4),
                          Text('4.96 • Verified Driver', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Earnings quick link
                  GestureDetector(
                    onTap: () => context.push('/driver/earnings'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.trending_up_rounded, size: 16, color: AppColors.success),
                          const SizedBox(width: 6),
                          Text('\$$earnings', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Switch to Customer App',
                    icon: const Icon(Icons.person_outline_rounded, size: 20, color: AppColors.primaryLight),
                    onPressed: () async {
                      await ref.read(authNotifierProvider.notifier).switchRole('CUSTOMER');
                      if (context.mounted) context.go('/home');
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, size: 20, color: AppColors.textSecondary),
                    onPressed: () async {
                      await ref.read(authNotifierProvider.notifier).logout();
                      if (context.mounted) context.go('/auth/phone');
                    },
                  ),
                ],
              ),
            ),
          ),

          // Active Trip Floating Card
          if (isOnTrip && driverState.activeTrip != null)
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              child: GlassCard(
                color: AppColors.secondary.withOpacity(0.9),
                onTap: () => context.push('/driver/trip/${driverState.activeTrip!.id}'),
                child: Row(
                  children: [
                    const Icon(Icons.navigation_rounded, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Current Trip: ${driverState.activeTrip!.status}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          const Text('Tap to return to navigation', style: TextStyle(fontSize: 12, color: Colors.white70)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white),
                  ],
                ),
              ),
            ),

          // Bottom Control Card & Duty Switch
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, -4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Performance metrics row
                  Row(
                    children: [
                      _buildMetricItem('Acceptance', '98%'),
                      Container(width: 1, height: 28, color: AppColors.divider),
                      _buildMetricItem('Completion', '100%'),
                      Container(width: 1, height: 28, color: AppColors.divider),
                      _buildMetricItem('Trips Today', '4'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Giant Duty Toggle Button
                  GestureDetector(
                    onTap: () {
                      ref.read(driverNotifierProvider.notifier).toggleDuty(!isOnline);
                    },
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: isOnline ? AppColors.success : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          if (isOnline)
                            BoxShadow(color: AppColors.success.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(isOnline ? Icons.check_circle_rounded : Icons.power_settings_new_rounded, color: Colors.white),
                          const SizedBox(width: 10),
                          Text(
                            isOnline ? 'ONLINE • ACCEPTING TRIPS' : 'GO ONLINE',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _IncomingOfferSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> offer;
  const _IncomingOfferSheet({required this.offer});

  @override
  ConsumerState<_IncomingOfferSheet> createState() => _IncomingOfferSheetState();
}

class _IncomingOfferSheetState extends ConsumerState<_IncomingOfferSheet> {
  int _secondsLeft = 30;
  Timer? _countdown;
  bool _isResponding = false;

  @override
  void initState() {
    super.initState();
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        timer.cancel();
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }

  Future<void> _respond(bool accept) async {
    setState(() => _isResponding = true);
    final bookingId = widget.offer['booking_id'] as String? ?? widget.offer['id'] as String;
    final booking = await ref.read(driverNotifierProvider.notifier).respondOffer(bookingId, accept);
    if (!mounted) return;
    setState(() => _isResponding = false);
    Navigator.of(context).pop();
    if (accept && booking != null) {
      context.push('/driver/trip/${booking.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final estFare = widget.offer['estimated_fare'] ?? 35.0;
    final duration = widget.offer['duration_hours'] ?? 2;
    final pickup = widget.offer['pickup_address'] ?? 'Indiranagar 100ft Rd';
    final transmission = widget.offer['transmission'] ?? 'AUTOMATIC';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('NEW RIDE OFFER • $_secondsLeft s', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary, fontSize: 12)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$transmission TRANSMISSION',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text('\$$estFare', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
          Text('Guaranteed Payout • $duration Hours Package', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          GlassCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.fmd_good_rounded, color: AppColors.secondary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(pickup.toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Decline',
                  variant: AppButtonVariant.outline,
                  onPressed: () => _respond(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: AppButton(
                  text: 'Accept Trip',
                  isLoading: _isResponding,
                  onPressed: () => _respond(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
