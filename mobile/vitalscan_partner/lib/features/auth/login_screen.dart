import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/buttons.dart';

/// Login (Part 6/Screen3) — mobile entry → Send OTP.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _mobile = TextEditingController();

  @override
  void dispose() {
    _mobile.dispose();
    super.dispose();
  }

  bool get _valid => _mobile.text.length == 10;

  Future<void> _send() async {
    final ok = await ref.read(authProvider.notifier).sendOtp('+91${_mobile.text}');
    if (ok && mounted) context.push('/otp');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.s48),
              Center(
                child: Icon(Icons.health_and_safety_rounded,
                    size: 56, color: AppColors.teal700),
              ),
              const SizedBox(height: AppSpacing.s32),
              Text('Welcome back 👋', style: AppTextStyles.h1),
              const SizedBox(height: AppSpacing.s8),
              Text('Enter your mobile to continue',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.s32),
              Container(
                padding: const EdgeInsets.all(AppSpacing.s20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.r20),
                  boxShadow: AppShadows.shadow3,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mobile Number',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: AppSpacing.s8),
                    TextField(
                      controller: _mobile,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      onChanged: (_) => setState(() {}),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        counterText: '',
                        prefixIcon: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Align(
                            widthFactor: 1,
                            child: Text('🇮🇳 +91',
                                style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        hintText: '9876543210',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    PrimaryButton(
                      label: 'Send OTP',
                      icon: Icons.arrow_forward_rounded,
                      loading: auth.busy,
                      onPressed: _valid ? _send : null,
                    ),
                    if (auth.error != null) ...[
                      const SizedBox(height: AppSpacing.s12),
                      Text(auth.error!,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.errorRed)),
                    ],
                    const SizedBox(height: AppSpacing.s16),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('OR',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textSecondary)),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    SecondaryButton(
                      label: 'Continue with Google',
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Google sign-in coming soon')),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Browse as Guest →'),
                ),
              ),
              const SizedBox(height: AppSpacing.s24),
              Center(
                child: Text('🔒 Encrypted · NABL · ⭐ 4.8',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
