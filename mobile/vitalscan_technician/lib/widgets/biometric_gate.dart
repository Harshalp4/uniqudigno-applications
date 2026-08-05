import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/security/biometric_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../providers/security_provider.dart';
import 'buttons.dart';

/// Blocks [child] until the user passes a biometric / device-credential check,
/// and denies entirely on a rooted/jailbroken device (Section 4D — required
/// before report detail, downloads, AI chat).
class BiometricGate extends ConsumerStatefulWidget {
  final Widget child;
  final String reason;
  const BiometricGate({
    super.key,
    required this.child,
    this.reason = 'Authenticate to view your report',
  });

  @override
  ConsumerState<BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends ConsumerState<BiometricGate> {
  final _service = BiometricService();
  bool _unlocked = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _attempt();
  }

  Future<void> _attempt() async {
    setState(() => _checking = true);
    final ok = await _service.authenticate(reason: widget.reason);
    if (!mounted) return;
    setState(() {
      _unlocked = ok;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final compromised = ref.watch(deviceCompromisedProvider).maybeWhen(
        data: (v) => v, orElse: () => false);

    if (compromised) {
      return _Locked(
        icon: Icons.gpp_bad_outlined,
        color: AppColors.errorRed,
        title: 'Security risk detected',
        message:
            'This device appears to be rooted or jailbroken. Viewing health '
            'data is disabled to protect your privacy.',
      );
    }

    if (_unlocked) return widget.child;

    return _Locked(
      icon: Icons.fingerprint,
      color: AppColors.teal700,
      title: 'Protected health data',
      message: "Verify it's you to continue.",
      action: SizedBox(
        width: 220,
        child: PrimaryButton(
          label: 'Unlock',
          loading: _checking,
          onPressed: _checking ? null : _attempt,
        ),
      ),
    );
  }
}

class _Locked extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final Widget? action;
  const _Locked({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 64, color: color),
              const SizedBox(height: AppSpacing.s16),
              Text(title, style: AppTextStyles.h3, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.s8),
              Text(message,
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
              if (action != null) ...[
                const SizedBox(height: AppSpacing.s24),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
