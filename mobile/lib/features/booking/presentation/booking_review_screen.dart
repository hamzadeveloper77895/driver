import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../../garage/domain/garage_state.dart';
import '../domain/booking_state.dart';

class BookingReviewScreen extends ConsumerStatefulWidget {
  final String pickupAddress;
  final String dropoffAddress;
  final double dropLat;
  final double dropLng;

  const BookingReviewScreen({
    super.key,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.dropLat,
    required this.dropLng,
  });

  @override
  ConsumerState<BookingReviewScreen> createState() => _BookingReviewScreenState();
}

class _BookingReviewScreenState extends ConsumerState<BookingReviewScreen> {
  int _durationHours = 2;
  String _paymentMethod = 'WALLET';
  final _promoController = TextEditingController();
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateFare();
    });
  }

  void _calculateFare() {
    ref.read(bookingNotifierProvider.notifier).fetchEstimate(
          serviceType: 'HOURLY',
          durationHours: _durationHours,
          pickupLat: 12.9716,
          pickupLng: 77.5946,
        );
  }

  Future<void> _confirmBooking() async {
    final garageState = ref.read(garageNotifierProvider);
    final vehicle = garageState.selectedVehicle;

    if (vehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle from your garage first!')),
      );
      context.push('/garage');
      return;
    }

    setState(() => _isBooking = true);
    final booking = await ref.read(bookingNotifierProvider.notifier).createBooking(
          serviceType: 'HOURLY',
          carId: vehicle.id,
          pickupAddress: widget.pickupAddress,
          pickupLat: 12.9716,
          pickupLng: 77.5946,
          dropoffAddress: widget.dropoffAddress,
          dropoffLat: widget.dropLat,
          dropoffLng: widget.dropLng,
          durationHours: _durationHours,
          paymentMethod: _paymentMethod,
        );

    if (!mounted) return;
    setState(() => _isBooking = false);

    if (booking != null) {
      context.go('/booking/searching/${booking.id}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(bookingNotifierProvider).errorMessage ?? 'Failed to create booking'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingNotifierProvider);
    final garageState = ref.watch(garageNotifierProvider);
    final estimate = bookingState.estimate;
    final vehicle = garageState.selectedVehicle;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Review Booking'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Route Card
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.radio_button_checked, size: 18, color: AppColors.secondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Pickup Point', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            Text(widget.pickupAddress, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        Container(width: 2, height: 24, color: AppColors.surfaceLight),
                      ],
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, size: 18, color: AppColors.primaryLight),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Destination', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            Text(widget.dropoffAddress, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Duration Package Selector
            const Text('Booking Duration Package', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            Row(
              children: [2, 4, 8, 12].map((hours) {
                final isSelected = _durationHours == hours;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _durationHours = hours);
                      _calculateFare();
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? AppColors.primaryLight : Colors.white.withOpacity(0.06)),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Text(
                            '$hours hrs',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            hours == 2 ? 'Base' : 'Popular',
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? Colors.white.withOpacity(0.8) : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Selected Car Card
            const Text('Vehicle to be Driven', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            GlassCard(
              onTap: () => context.push('/garage'),
              child: Row(
                children: [
                  const Icon(Icons.directions_car_filled_rounded, color: AppColors.secondary, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle != null ? vehicle.displayName : 'No vehicle selected',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        if (vehicle != null)
                          Text(
                            'Transmission: ${vehicle.transmission} • Plate: ${vehicle.plateNumber}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                  const Text('Change', style: TextStyle(color: AppColors.primaryLight, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Itemized Fare Breakdown
            const Text('Fare Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: bookingState.isLoading && estimate == null
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        _buildFareRow('Base Fare ($_durationHours hrs package)', '\$${estimate?.baseFare.toStringAsFixed(2) ?? "25.00"}'),
                        const SizedBox(height: 8),
                        _buildFareRow('Night Surcharge (22:00 - 06:00)', '\$${estimate?.nightCharge.toStringAsFixed(2) ?? "0.00"}'),
                        const SizedBox(height: 8),
                        _buildFareRow('Taxes & Regulatory Fees (18% GST)', '\$${estimate?.taxes.toStringAsFixed(2) ?? "4.50"}'),
                        const Divider(color: AppColors.divider, height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Estimated Fare', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(
                              '\$${estimate?.totalFare.toStringAsFixed(2) ?? "29.50"}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primaryLight),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),

            // Payment method selector
            const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildPaymentChip('WALLET', Icons.account_balance_wallet_rounded, 'ChauffeurX Wallet'),
                const SizedBox(width: 8),
                _buildPaymentChip('CASH', Icons.payments_rounded, 'Cash to Driver'),
              ],
            ),
            const SizedBox(height: 28),

            // Book Button
            AppButton(
              text: 'Confirm & Dispatch Driver',
              isLoading: _isBooking,
              onPressed: _confirmBooking,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFareRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
        const SizedBox(width: 8),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildPaymentChip(String mode, IconData icon, String label) {
    final isSelected = _paymentMethod == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _paymentMethod = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.15) : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.06),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? AppColors.primaryLight : AppColors.textSecondary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
