import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../domain/driver_state.dart';

class DriverEarningsScreen extends ConsumerStatefulWidget {
  const DriverEarningsScreen({super.key});

  @override
  ConsumerState<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends ConsumerState<DriverEarningsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(driverNotifierProvider.notifier).fetchEarnings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driverState = ref.watch(driverNotifierProvider);
    final earnings = driverState.earnings?['total_earnings'] ?? 142.50;
    final trips = driverState.earnings?['trips_completed'] ?? 4;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Driver Earnings & Payouts'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.success,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'This Week'),
            Tab(text: 'This Month'),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Top Earnings Gradient Summary Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF065F46), Color(0xFF059669), Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(color: AppColors.success.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Net Earnings', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text('\$$earnings', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniStat('Trips Done', '$trips'),
                      _buildMiniStat('Hours Online', '5.5 hrs'),
                      _buildMiniStat('Customer Tips', '\$14.00'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bank Account Card
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance_rounded, color: AppColors.secondary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Direct Deposit: HDFC Bank •••• 4129', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Auto-payout every Tuesday • Next: Tomorrow', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Ledger breakdown
            const Text('Completed Trip Payouts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),

            _buildTripPayoutItem('Hourly Trip (2 hrs) • Indiranagar', '14:20 PM', 32.50, 4.0),
            _buildTripPayoutItem('Hourly Trip (4 hrs) • Whitefield', '10:00 AM', 58.00, 5.0),
            _buildTripPayoutItem('Night Drive (2 hrs) • Koramangala', 'Yesterday', 38.00, 5.0),
            _buildTripPayoutItem('Round Trip • Airport Terminal 2', '22 Oct', 42.00, 0.0),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String title, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(title, style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }

  Widget _buildTripPayoutItem(String title, String time, double fare, double tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text('$time • Direct Settlement', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('+\$${fare.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.success)),
                if (tip > 0)
                  Text('+\$${tip.toStringAsFixed(2)} tip', style: const TextStyle(fontSize: 10, color: AppColors.warning)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
