import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/buttons.dart';
import '../../widgets/otp_input.dart';
import 'profile_setup_screen.dart';

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

  String? _devOtp;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    // Dev: the API echoes the OTP; prefill + auto-verify so login works with no inbox.
    _devOtp = ref.read(authProvider).devOtp;
    if (_devOtp != null && _devOtp!.length == 6) {
      _otp = _devOtp!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _verify();
        });
      });
    }
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
    final ok = await ref.read(authProvider.notifier).verifyCurrent(_otp);
    if (!mounted) return;
    if (ok) {
      await routeAfterLogin(context, ref); // new user → /auth/setup, else /home
    } else {
      setState(() => _error = true);
    }
  }

  Future<void> _resend() async {
    final auth = ref.read(authProvider);
    if (auth.emailFlow) {
      if (auth.email != null) {
        await ref.read(authProvider.notifier).sendEmailOtp(auth.email!);
      }
    } else if (auth.mobile != null) {
      await ref.read(authProvider.notifier).sendOtp(auth.mobile!);
    }
    _startCountdown();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final target = auth.emailFlow ? (auth.email ?? '') : (auth.mobile ?? '');

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
              Text(auth.emailFlow ? 'Verify your email' : 'Verify your number',
                  style: AppTextStyles.h1),
              const SizedBox(height: AppSpacing.s8),
              Text('Enter the 6-digit code sent to $target',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.s32),
              OtpInput(
                error: _error,
                initialValue: _devOtp,
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
