import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/session_reset.dart';
import '../../widgets/buttons.dart';
import 'google_sign_in_helper.dart';

/// "Log in or sign up" bottom sheet. Email OTP is the primary flow (no phone
/// required); Google and mobile-OTP are alternatives. Guests browse and build a
/// cart freely; identity is only needed to place a booking.
/// Returns `true` once authenticated (guest cart already merged).
Future<bool> showLoginSheet(BuildContext context, {String? reason}) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _LoginSheet(reason: reason),
  );
  return ok ?? false;
}

enum _Mode { email, phone }

class _LoginSheet extends ConsumerStatefulWidget {
  final String? reason;
  const _LoginSheet({this.reason});

  @override
  ConsumerState<_LoginSheet> createState() => _LoginSheetState();
}

class _LoginSheetState extends ConsumerState<_LoginSheet> {
  final _email = TextEditingController();
  final _mobile = TextEditingController();
  final _otp = TextEditingController();
  _Mode _mode = _Mode.email;
  bool _otpSent = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _mobile.dispose();
    _otp.dispose();
    super.dispose();
  }

  bool get _isEmail => _mode == _Mode.email;

  Future<void> _send() async {
    setState(() { _busy = true; _error = null; });
    final auth = ref.read(authProvider.notifier);
    final ok = _isEmail
        ? await auth.sendEmailOtp(_email.text.trim())
        : await auth.sendOtp(_mobile.text.trim());
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) {
        _otpSent = true;
        // Dev: prefill the echoed OTP when no mail provider is wired.
        final dev = ref.read(authProvider).devOtp;
        if (dev != null && dev.isNotEmpty) _otp.text = dev;
      } else {
        // Surface the real reason (network / rate-limit / server).
        _error = ref.read(authProvider).error ??
            'Could not send a code. Check your ${_isEmail ? 'email' : 'number'}.';
      }
    });
  }

  Future<void> _verify() async {
    setState(() { _busy = true; _error = null; });
    final auth = ref.read(authProvider.notifier);
    final ok = _isEmail
        ? await auth.verifyEmailOtp(_otp.text.trim())
        : await auth.verifyOtp(_otp.text.trim());
    if (!mounted) return;
    if (ok) {
      await _finishLogin();
    } else {
      setState(() { _busy = false; _error = 'Incorrect code. Try again.'; });
    }
  }

  Future<void> _google() async {
    setState(() => _busy = true);
    final err = await signInWithGoogle(ref);
    if (!mounted) return;
    if (err == null) {
      await _finishLogin();
    } else {
      setState(() {
        _busy = false;
        if (err != 'cancelled') _error = err;
      });
    }
  }

  /// Merge the guest cart, then either close (profile complete) or send a
  /// new/incomplete user to mandatory profile setup (health app needs patient data).
  Future<void> _finishLogin() async {
    final merge = await ref.read(cartProvider.notifier).mergeGuestCartToServer();
    if (!mounted) return;
    if (merge.hasFailures) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            "${merge.failed} item(s) couldn't be added to your cart — they're still saved, please try again."),
      ));
    }
    invalidateSessionProviders(ref);
    MeProfile? me;
    try {
      me = await ref.read(meProvider.future);
    } catch (_) {}
    if (!mounted) return;
    if (me == null || !me.profileComplete) {
      context.go('/auth/setup');
      Navigator.pop(context, false);
    } else {
      Navigator.pop(context, true);
    }
  }

  void _switchMode() => setState(() {
        _mode = _isEmail ? _Mode.phone : _Mode.email;
        _error = null;
      });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final target = _isEmail ? _email.text.trim() : '+91 ${_mobile.text.trim()}';
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.s20, AppSpacing.s12, AppSpacing.s20, AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4, margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                    color: AppColors.borderStrong,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text(_otpSent ? 'Enter code' : 'Log in or sign up',
                style: AppTextStyles.h2),
            const SizedBox(height: 4),
            Text(
              _otpSent
                  ? 'We sent a 6-digit code to $target'
                  : widget.reason ??
                      'Sign in with your email — no phone number needed.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.s20),

            if (!_otpSent) ...[
              if (_isEmail)
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                  decoration: const InputDecoration(
                      labelText: 'Email address',
                      hintText: 'you@example.com',
                      prefixIcon: Icon(Icons.mail_outline)),
                )
              else
                TextField(
                  controller: _mobile,
                  keyboardType: TextInputType.phone,
                  autofocus: true,
                  decoration: const InputDecoration(
                      prefixText: '+91  ',
                      labelText: 'Mobile number',
                      hintText: '9876543210'),
                ),
            ] else
              TextField(
                controller: _otp,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                    labelText: 'OTP', hintText: '6-digit code'),
              ),

            if (_error != null) ...[
              const SizedBox(height: AppSpacing.s8),
              Text(_error!,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.errorRed)),
            ],
            const SizedBox(height: AppSpacing.s20),
            PrimaryButton(
              label: _otpSent
                  ? 'Verify & Continue'
                  : (_isEmail ? 'Email me a code' : 'Send OTP'),
              loading: _busy,
              onPressed: _busy ? null : (_otpSent ? _verify : _send),
            ),

            if (_otpSent)
              Center(
                child: TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() { _otpSent = false; _error = null; }),
                  child: Text(_isEmail ? 'Change email' : 'Change number'),
                ),
              )
            else ...[
              const SizedBox(height: AppSpacing.s16),
              Row(children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                ),
                const Expanded(child: Divider()),
              ]),
              const SizedBox(height: AppSpacing.s12),
              OutlinedButton.icon(
                onPressed: _google,
                icon: const Icon(Icons.g_mobiledata, size: 28),
                label: const Text('Continue with Google'),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.s8),
              Center(
                child: TextButton(
                  onPressed: _busy ? null : _switchMode,
                  child: Text(_isEmail
                      ? 'Use mobile number instead'
                      : 'Use email instead'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
