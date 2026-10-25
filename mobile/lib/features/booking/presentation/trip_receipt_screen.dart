import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../domain/booking_state.dart';

class TripReceiptScreen extends ConsumerWidget {
  final String bookingId;
  const TripReceiptScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = ref.watch(bookingNotifierProvider).activeBooking;
    final totalFare = booking?.totalFare ?? booking?.estimatedFare ?? 32.50;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Trip Receipt'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.success, width: 2),
                ),
                child: const Icon(Icons.check_rounded, color: AppColors.success, size: 40),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Trip Completed!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                '\$${totalFare.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  booking?.paymentMethod == 'CASH' ? 'Cash Settled to Driver' : 'Paid via ChauffeurX Wallet',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Itemized Breakdown Card
            GlassCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Invoice Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 14),
                  _buildRow('Base Package (${booking?.durationHours ?? 2} hrs)', '\$${(totalFare * 0.75).toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  _buildRow('Night Surcharge', '\$0.00'),
                  const SizedBox(height: 8),
                  _buildRow('Taxes & Regulatory Fee', '\$${(totalFare * 0.25).toStringAsFixed(2)}'),
                  const Divider(color: AppColors.divider, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Charged', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(
                        '\$${totalFare.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Route & Car Summary Card
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 18, color: AppColors.secondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          booking?.dropoffAddress ?? 'Destination',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 10),
                      Text(
                        'Chauffeur: ${booking?.driver?.fullName ?? "Partner Chauffeur"}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            AppButton(
              text: 'Rate Your Chauffeur',
              onPressed: () => context.go('/booking/rate/$bookingId'),
            ),
            const SizedBox(height: 12),
            AppButton(
              text: 'Back to Home',
              variant: AppButtonVariant.outline,
              onPressed: () => context.go('/home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String title, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ],
    );
  }
}
