import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../domain/auth_state.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String phone;
  final String role;

  const OtpVerificationScreen({
    super.key,
    required this.phone,
    required this.role,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _otpController = TextEditingController(text: '123456');
  bool _isLoading = false;
  String? _errorMessage;
  int _timerSeconds = 30;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timerSeconds = 30;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        setState(() => _timerSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _errorMessage = 'Please enter a 6-digit OTP');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await ref.read(authNotifierProvider.notifier).verifyOtp(
          widget.phone,
          otp,
          role: widget.role,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      final user = ref.read(authNotifierProvider).user;
      final isDriver = (user?.role == 'DRIVER') || (widget.role == 'DRIVER');
      if (user != null && (user.fullName == null || user.fullName!.isEmpty)) {
        context.go('/auth/profile-setup');
      } else if (isDriver) {
        context.go('/driver/dashboard');
      } else {
        context.go('/home');
      }
    } else {
      setState(() {
        _errorMessage = ref.read(authNotifierProvider).errorMessage ?? 'Invalid verification code';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Verify OTP'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text(
                'Enter Verification Code',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Code sent to +91 ${widget.phone}',
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 12,
                  color: AppColors.primaryLight,
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: '••••••',
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: AppColors.primaryLight),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Demo mode: Default OTP is 123456',
                        style: TextStyle(fontSize: 13, color: AppColors.primaryLight),
                      ),
                    ),
                  ],
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ],
              const SizedBox(height: 24),
              Center(
                child: _timerSeconds > 0
                    ? Text(
                        'Resend code in 00:${_timerSeconds.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      )
                    : TextButton(
                        onPressed: () {
                          _startTimer();
                          ref.read(authNotifierProvider.notifier).requestOtp(widget.phone, role: widget.role);
                        },
                        child: const Text('Resend Code via SMS', style: TextStyle(color: AppColors.primaryLight)),
                      ),
              ),
              const Spacer(),
              AppButton(
                text: 'Verify & Proceed',
                isLoading: _isLoading,
                onPressed: _verify,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
