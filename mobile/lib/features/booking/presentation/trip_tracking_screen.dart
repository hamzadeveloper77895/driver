import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../domain/booking_state.dart';

class TripTrackingScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const TripTrackingScreen({super.key, required this.bookingId});

  @override
  ConsumerState<TripTrackingScreen> createState() => _TripTrackingScreenState();
}

class _TripTrackingScreenState extends ConsumerState<TripTrackingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingNotifierProvider.notifier).fetchBookingById(widget.bookingId);
      ref.read(bookingNotifierProvider.notifier).connectTripWebSocket(widget.bookingId);
    });
  }

  Future<void> _cancelBooking() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Cancel Ride?'),
        content: const Text('Cancellation fees may apply if driver is already en route.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep Ride')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'Changed plans'),
            child: const Text('Confirm Cancel', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (reason != null && mounted) {
      await ref.read(bookingNotifierProvider.notifier).cancelBooking(widget.bookingId, reason);
      if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(bookingNotifierProvider, (previous, next) {
      final b = next.activeBooking;
      if (b != null && b.id == widget.bookingId) {
        if (b.status == 'COMPLETED') {
          context.go('/booking/receipt/${widget.bookingId}');
        }
      }
    });

    final bookingState = ref.watch(bookingNotifierProvider);
    final booking = bookingState.activeBooking;
    final driver = booking?.driver;

    final driverLat = bookingState.driverLat ?? (booking?.pickupLat ?? 12.9716) + 0.003;
    final driverLng = bookingState.driverLng ?? (booking?.pickupLng ?? 77.5946) + 0.003;
    final driverBearing = bookingState.driverBearing;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Live Map Area
          _buildLiveMap(driverLat, driverLng, driverBearing),

          // Top Safety Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 6)],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.go('/home'),
                    ),
                  ),
                  const Spacer(),
                  // SOS Emergency Shield
                  IconButton(
                    onPressed: () => context.push('/safety'),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Dynamic Sheet
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Headline & Estimated Time
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(booking?.status ?? '').withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getStatusTitle(booking?.status ?? ''),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(booking?.status ?? ''),
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (booking?.status == 'ON_WAY' || booking?.status == 'DRIVER_ASSIGNED')
                        const Row(
                          children: [
                            Icon(Icons.schedule, size: 14, color: AppColors.textSecondary),
                            SizedBox(width: 4),
                            Text('ETA ~6 mins', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Start-Trip OTP Security Badge (Before trip starts)
                  if (booking?.startOtp != null && booking?.status != 'IN_PROGRESS' && booking?.status != 'COMPLETED') ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.pin_rounded, color: AppColors.primaryLight),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Share OTP with driver on arrival',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                                Text(
                                  booking!.startOtp!,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 6,
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Driver Details Row
                  GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.secondary.withOpacity(0.2),
                          child: const Icon(Icons.person, color: AppColors.secondary, size: 26),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                driver?.fullName ?? 'Assigned Chauffeur',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${driver?.rating.toStringAsFixed(1) ?? "4.9"} • ${driver?.totalTrips ?? 120} rides',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Chat Button
                        IconButton(
                          onPressed: () => context.push('/booking/chat/${widget.bookingId}'),
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppColors.primaryLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cancel / Actions Row
                  if (booking?.status != 'IN_PROGRESS')
                    AppButton(
                      text: 'Cancel Ride',
                      variant: AppButtonVariant.outline,
                      onPressed: _cancelBooking,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusTitle(String status) {
    switch (status) {
      case 'DRIVER_ASSIGNED':
        return 'Chauffeur Assigned';
      case 'ON_WAY':
        return 'Chauffeur En Route';
      case 'ARRIVED':
        return 'Chauffeur Arrived at Pickup';
      case 'IN_PROGRESS':
        return 'Trip In Progress';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ARRIVED':
        return AppColors.success;
      case 'IN_PROGRESS':
        return AppColors.secondary;
      default:
        return AppColors.primaryLight;
    }
  }

  Widget _buildLiveMap(double dLat, double dLng, double bearing) {
    return Container(
      color: const Color(0xFF0F172A),
      child: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: _RoutePainter(),
          ),
          // Destination Pin
          Positioned(
            top: 220,
            left: 240,
            child: Column(
              children: const [
                Icon(Icons.location_on, color: AppColors.error, size: 32),
                Text('Destination', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          // Live Driver Vehicle Pin with Bearing Rotation
          Positioned(
            top: 360,
            left: 140,
            child: Transform.rotate(
              angle: bearing * 3.14159 / 180,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(color: AppColors.secondary.withOpacity(0.5), blurRadius: 12),
                  ],
                ),
                child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final routePaint = Paint()
      ..color = AppColors.primaryLight.withOpacity(0.8)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(140, 360)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.35, 240, 220);

    canvas.drawPath(path, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
