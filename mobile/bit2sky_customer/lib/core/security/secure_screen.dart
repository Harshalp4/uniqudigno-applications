import 'package:flutter/widgets.dart';
import 'package:screen_protector/screen_protector.dart';

/// Wraps a PHI screen (report detail, AI copilot, health score) and prevents
/// screenshots / screen recording for its lifetime — Android FLAG_SECURE,
/// iOS app-switcher blur (Section 4D).
class SecureScreen extends StatefulWidget {
  final Widget child;
  const SecureScreen({super.key, required this.child});

  @override
  State<SecureScreen> createState() => _SecureScreenState();
}

class _SecureScreenState extends State<SecureScreen> {
  @override
  void initState() {
    super.initState();
    _protect();
  }

  Future<void> _protect() async {
    try {
      await ScreenProtector.preventScreenshotOn();
      await ScreenProtector.protectDataLeakageWithBlur();
    } catch (_) {
      // No-op where the platform channel is unavailable (e.g. tests).
    }
  }

  @override
  void dispose() {
    ScreenProtector.preventScreenshotOff().ignore();
    ScreenProtector.protectDataLeakageWithBlurOff().ignore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
