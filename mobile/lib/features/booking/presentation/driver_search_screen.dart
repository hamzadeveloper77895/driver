import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../domain/booking_state.dart';

class DriverSearchScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const DriverSearchScreen({super.key, required this.bookingId});

  @override
  ConsumerState<DriverSearchScreen> createState() => _DriverSearchScreenState();
}

class _DriverSearchScreenState extends ConsumerState<DriverSearchScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  int _secondsRemaining = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingNotifierProvider.notifier).fetchBookingById(widget.bookingId);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _cancelBooking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Cancel Request?'),
        content: const Text('Are you sure you want to stop searching for nearby chauffeurs?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep Searching')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Request', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(bookingNotifierProvider.notifier).cancelBooking(widget.bookingId, 'User cancelled search');
      if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for state transitions: when driver is assigned, auto-navigate to live tracking!
    ref.listen(bookingNotifierProvider, (previous, next) {
      final b = next.activeBooking;
      if (b != null && b.id == widget.bookingId) {
        if (b.status == 'DRIVER_ASSIGNED' || b.status == 'ON_WAY' || b.status == 'ARRIVED' || b.status == 'IN_PROGRESS') {
          context.go('/booking/tracking/${widget.bookingId}');
        }
      }
    });

    final booking = ref.watch(bookingNotifierProvider).activeBooking;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 32),
              const Text(
                'Matching Your Chauffeur',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Broadcasting request to nearby chauffeurs matching your vehicle gearbox...',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const Spacer(),

              // Sonar Radar Waves
              Center(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Ripple 1
                        Container(
                          width: 220 * _pulseController.value,
                          height: 220 * _pulseController.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withOpacity(1.0 - _pulseController.value),
                              width: 2,
                            ),
                          ),
                        ),
                        // Ripple 2
                        Container(
                          width: 140 * ((_pulseController.value + 0.5) % 1.0),
                          height: 140 * ((_pulseController.value + 0.5) % 1.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.secondary.withOpacity(1.0 - ((_pulseController.value + 0.5) % 1.0)),
                              width: 1.5,
                            ),
                          ),
                        ),
                        // Central Radar Node
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.5),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.radar_rounded, size: 40, color: Colors.white),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),

              // Countdown Timer Indicator
              Text(
                '00:${_secondsRemaining.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.secondary),
              ),
              const SizedBox(height: 6),
              const Text('Connecting to closest verified driver', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const Spacer(),

              // Trip Mini-Card
              if (booking != null)
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.fmd_good_rounded, color: AppColors.secondary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          booking.pickupAddress,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '\$${booking.estimatedFare.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Cancel button
              AppButton(
                text: 'Cancel Request',
                variant: AppButtonVariant.outline,
                onPressed: _cancelBooking,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
