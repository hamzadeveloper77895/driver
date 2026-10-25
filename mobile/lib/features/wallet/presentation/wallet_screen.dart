import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../domain/wallet_state.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  final _amountController = TextEditingController();
  bool _isToppingUp = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletNotifierProvider.notifier).fetchWallet();
    });
  }

  void _showAddMoneySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Top Up Wallet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Funds can be used instantly for 1-click booking checkouts.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 20),
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.attach_money_rounded, size: 28, color: AppColors.primaryLight),
                    hintText: '50.00',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [25, 50, 100].map((amt) {
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setModalState(() => _amountController.text = amt.toString());
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text('+\$$amt', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                AppButton(
                  text: 'Add Funds Now',
                  isLoading: _isToppingUp,
                  onPressed: () async {
                    final val = double.tryParse(_amountController.text.trim());
                    if (val == null || val <= 0) return;
                    setModalState(() => _isToppingUp = true);
                    final ok = await ref.read(walletNotifierProvider.notifier).topUp(val);
                    if (!mounted) return;
                    setModalState(() => _isToppingUp = false);
                    if (ok) {
                      _amountController.clear();
                      if (ctx.mounted) Navigator.pop(ctx);
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletNotifierProvider);
    final wallet = walletState.wallet;
    final balance = wallet?.balance ?? 0.0;
    final txs = wallet?.transactions ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Digital Wallet'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(walletNotifierProvider.notifier).fetchWallet(),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Balance Gradient Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4338CA), Color(0xFF6366F1), Color(0xFF0EA5E9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Text(
                      '\$${balance.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        minimumSize: const Size(140, 42),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Top Up Balance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      onPressed: _showAddMoneySheet,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Recent Transactions Header
              const Text('Recent Transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 12),

              if (txs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'No transactions yet.\nTop up funds for seamless 1-tap bookings.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                )
              else
                ...txs.map((tx) {
                  final isCredit = tx.transactionType == 'CREDIT';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (isCredit ? AppColors.success : AppColors.error).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                              color: isCredit ? AppColors.success : AppColors.error,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx.description.isNotEmpty ? tx.description : (isCredit ? 'Wallet Top-Up' : 'Trip Payment'),
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tx.createdAt.isNotEmpty ? tx.createdAt.split('T').first : 'Recent',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${isCredit ? "+" : "-"}\$${tx.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isCredit ? AppColors.success : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
