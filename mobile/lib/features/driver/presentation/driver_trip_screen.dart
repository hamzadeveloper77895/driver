import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../../booking/domain/booking_state.dart';
import '../domain/driver_state.dart';

class DriverTripScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const DriverTripScreen({super.key, required this.bookingId});

  @override
  ConsumerState<DriverTripScreen> createState() => _DriverTripScreenState();
}

class _DriverTripScreenState extends ConsumerState<DriverTripScreen> {
  final _otpController = TextEditingController();
  bool _isActionLoading = false;

  void _showOtpDialog() {
    _otpController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final driverState = ref.watch(driverNotifierProvider);
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Enter Customer Start OTP'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ask the customer for the 4-digit security code shown in their app to start the trip.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, letterSpacing: 10, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                  decoration: const InputDecoration(
                    counterText: '',
                    hintText: '••••',
                  ),
                ),
                if (driverState.errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(driverState.errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size(120, 42)),
                onPressed: () async {
                  final code = _otpController.text.trim();
                  if (code.length != 4) return;
                  setDialogState(() => _isActionLoading = true);
                  final ok = await ref.read(driverNotifierProvider.notifier).startTrip(widget.bookingId, code);
                  setDialogState(() => _isActionLoading = false);
                  if (ok && mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Trip started successfully! Driving to destination.')),
                    );
                  }
                },
                child: const Text('Verify & Start'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showTripCompletionSummary(double fare, String paymentMethod) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Trip Finished!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, size: 54, color: AppColors.success),
            const SizedBox(height: 12),
            Text('\$${fare.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: paymentMethod == 'CASH' ? AppColors.warning.withOpacity(0.15) : AppColors.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                paymentMethod == 'CASH'
                    ? 'COLLECT CASH FROM CUSTOMER: \$${fare.toStringAsFixed(2)}'
                    : 'Digital Wallet Payment Settled. Do not collect cash.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: paymentMethod == 'CASH' ? AppColors.warning : AppColors.success,
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/driver/dashboard');
            },
            child: const Text('Back to Duty Dashboard'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driverState = ref.watch(driverNotifierProvider);
    final booking = driverState.activeTrip;
    final status = booking?.status ?? 'ON_WAY';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Active Ride Navigation'),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          // Navigation Canvas Mock
          Container(
            color: const Color(0xFF0F172A),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.navigation_rounded, size: 48, color: AppColors.primaryLight),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    status == 'IN_PROGRESS' ? 'Navigating to Destination...' : 'Navigating to Pickup Location...',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status == 'IN_PROGRESS'
                        ? (booking?.dropoffAddress ?? 'Destination')
                        : (booking?.pickupAddress ?? 'Pickup Point'),
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Step-by-Step Action Sheet
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
                  // Vehicle Details reminder
                  GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: const [
                        Icon(Icons.directions_car_filled_rounded, color: AppColors.secondary, size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Customer Vehicle: Honda City ZX', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('Automatic Transmission • Plate: KA01MJ9088', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Dynamic Action Button based on state machine
                  if (status == 'DRIVER_ASSIGNED' || status == 'ON_WAY')
                    AppButton(
                      text: 'I Have Arrived at Pickup',
                      isLoading: _isActionLoading,
                      onPressed: () async {
                        setState(() => _isActionLoading = true);
                        await ref.read(driverNotifierProvider.notifier).arriveAtPickup(widget.bookingId);
                        setState(() => _isActionLoading = false);
                      },
                    )
                  else if (status == 'ARRIVED')
                    AppButton(
                      text: 'Start Trip (Enter OTP)',
                      onPressed: _showOtpDialog,
                    )
                  else if (status == 'IN_PROGRESS')
                    AppButton(
                      text: 'End Trip at Destination',
                      isLoading: _isActionLoading,
                      onPressed: () async {
                        setState(() => _isActionLoading = true);
                        final ok = await ref.read(driverNotifierProvider.notifier).completeTrip(widget.bookingId);
                        setState(() => _isActionLoading = false);
                        if (ok && mounted) {
                          _showTripCompletionSummary(
                            booking?.totalFare ?? booking?.estimatedFare ?? 35.0,
                            booking?.paymentMethod ?? 'WALLET',
                          );
                        }
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
