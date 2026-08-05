import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../providers/tech_auth_provider.dart';
import '../widgets/buttons.dart';

/// Technician login — Employee ID + password (Section 9).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _employeeId = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _employeeId.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final ok = await ref
        .read(techAuthProvider.notifier)
        .login(_employeeId.text.trim(), _password.text);
    if (ok && mounted) context.go('/today');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(techAuthProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.s48),
              const Icon(Icons.badge_outlined, size: 56, color: AppColors.teal700),
              const SizedBox(height: AppSpacing.s24),
              Text('Technician Login', style: AppTextStyles.h1, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.s8),
              Text('Sign in to view your assigned collections',
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.s32),
              TextField(
                controller: _employeeId,
                decoration: const InputDecoration(labelText: 'Employee ID'),
              ),
              const SizedBox(height: AppSpacing.s12),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              if (auth.error != null) ...[
                const SizedBox(height: AppSpacing.s12),
                Text(auth.error!,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.errorRed)),
              ],
              const SizedBox(height: AppSpacing.s24),
              PrimaryButton(label: 'Get Code', loading: auth.busy, onPressed: _login),
            ],
          ),
        ),
      ),
    );
  }
}
