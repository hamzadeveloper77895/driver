import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../domain/booking_state.dart';

class RatingScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const RatingScreen({super.key, required this.bookingId});

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  int _stars = 5;
  double _tip = 0.0;
  final _commentController = TextEditingController();
  final Set<String> _selectedChips = {};
  bool _isSubmitting = false;

  final List<String> _positiveChips = ['Punctual', 'Smooth Driving', 'Clean & Polite', 'Great Route Knowledge'];
  final List<String> _negativeChips = ['Late Arrival', 'Rough Driving', 'Rude Behavior', 'Navigation Issue'];

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    await ref.read(bookingNotifierProvider.notifier).rateBooking(
          widget.bookingId,
          _stars,
          comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
          tip: _tip > 0 ? _tip : null,
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    context.go('/home');
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeChips = _stars >= 4 ? _positiveChips : _negativeChips;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rate Your Ride'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              const CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.secondary,
                child: Icon(Icons.person, size: 48, color: Colors.white),
              ),
              const SizedBox(height: 14),
              const Text(
                'How was your chauffeur?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your honest feedback helps us maintain 5-star service standards.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              // Star Rating Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return IconButton(
                    iconSize: 42,
                    icon: Icon(
                      starIndex <= _stars ? Icons.star_rounded : Icons.star_border_rounded,
                      color: AppColors.warning,
                    ),
                    onPressed: () => setState(() {
                      _stars = starIndex;
                      _selectedChips.clear();
                    }),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Feedback Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: activeChips.map((tag) {
                  final isSelected = _selectedChips.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedChips.add(tag);
                        } else {
                          _selectedChips.remove(tag);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Tip Options
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Add a Tip (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              const SizedBox(height: 10),
              Row(
                children: [0.0, 2.0, 5.0, 10.0].map((amount) {
                  final isSelected = _tip == amount;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _tip = amount),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isSelected ? AppColors.primaryLight : Colors.white.withOpacity(0.06)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          amount == 0.0 ? 'None' : '\$${amount.toInt()}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Comment Area
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Leave an optional note for your chauffeur...',
                ),
              ),
              const SizedBox(height: 32),

              AppButton(
                text: 'Submit Feedback',
                isLoading: _isSubmitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
