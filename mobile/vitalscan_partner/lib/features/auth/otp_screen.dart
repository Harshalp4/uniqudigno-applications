import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/buttons.dart';
import '../../widgets/otp_input.dart';

/// OTP verification (C19 + A28).
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  String _otp = '';
  bool _error = false;
  int _resendIn = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _resendIn = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendIn <= 1) {
        t.cancel();
        if (mounted) setState(() => _resendIn = 0);
      } else if (mounted) {
        setState(() => _resendIn--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _verify() async {
    setState(() => _error = false);
    final ok = await ref.read(authProvider.notifier).verifyOtp(_otp);
    if (!mounted) return;
    if (ok) {
      context.go('/home');
    } else {
      setState(() => _error = true);
    }
  }

  Future<void> _resend() async {
    final mobile = ref.read(authProvider).mobile;
    if (mobile == null) return;
    await ref.read(authProvider.notifier).sendOtp(mobile);
    _startCountdown();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final mobile = auth.mobile ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.s24),
              Text('Verify your number', style: AppTextStyles.h1),
              const SizedBox(height: AppSpacing.s8),
              Text('Enter the 6-digit code sent to $mobile',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.s32),
              OtpInput(
                error: _error,
                onChanged: (v) => setState(() {
                  _otp = v;
                  _error = false;
                }),
                onCompleted: (v) {
                  _otp = v;
                  _verify();
                },
              ),
              if (_error) ...[
                const SizedBox(height: AppSpacing.s12),
                Text(auth.error ?? 'Incorrect code. Try again.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.errorRed)),
              ],
              const SizedBox(height: AppSpacing.s24),
              PrimaryButton(
                label: 'Verify',
                loading: auth.busy,
                onPressed: _otp.length == 6 ? _verify : null,
              ),
              const SizedBox(height: AppSpacing.s16),
              Center(
                child: _resendIn > 0
                    ? Text('Resend code in ${_resendIn}s',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary))
                    : TextButton(onPressed: _resend, child: const Text('Resend OTP')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
