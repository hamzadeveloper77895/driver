import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../domain/auth_state.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _referralController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    await ref.read(authNotifierProvider.notifier).updateProfile(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    final user = ref.read(authNotifierProvider).user;
    if (user?.role == 'DRIVER') {
      context.go('/driver/dashboard');
    } else {
      context.go('/home');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Complete Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryLight, width: 2),
                  ),
                  child: const Icon(Icons.person_rounded, size: 48, color: AppColors.primaryLight),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.badge_outlined, color: AppColors.textSecondary),
                    hintText: 'e.g. John Doe',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Full name is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address (for invoices)',
                    prefixIcon: Icon(Icons.mail_outline_rounded, color: AppColors.textSecondary),
                    hintText: 'john@example.com',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _referralController,
                  decoration: const InputDecoration(
                    labelText: 'Referral Code (Optional)',
                    prefixIcon: Icon(Icons.confirmation_number_outlined, color: AppColors.textSecondary),
                    hintText: 'e.g. WELCOME50',
                  ),
                ),
                const SizedBox(height: 48),
                AppButton(
                  text: 'Complete Setup',
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
