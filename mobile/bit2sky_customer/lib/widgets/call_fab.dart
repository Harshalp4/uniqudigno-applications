import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/app_colors.dart';
import '../providers/app_providers.dart';
import '../providers/brand_palette_provider.dart';
import 'cart_snackbar.dart';
import 'pressable.dart';

/// Fixed call-to-book button (Healthians pattern): a circular accent-green
/// button pinned to the bottom-right, always available while browsing. A soft
/// ripple ring pulses outward on a loop to invite the tap; static under
/// reduce-motion. Dials the server-driven branding support phone.
class CallFab extends ConsumerStatefulWidget {
  const CallFab({super.key});

  static const double size = 52;

  @override
  ConsumerState<CallFab> createState() => _CallFabState();
}

class _CallFabState extends ConsumerState<CallFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ripple = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _ripple.stop();
    } else if (!_ripple.isAnimating) {
      _ripple.repeat();
    }
  }

  @override
  void dispose() {
    _ripple.dispose();
    super.dispose();
  }

  Future<void> _call() async {
    final phone = ref
        .read(brandingProvider)
        .maybeWhen(data: (b) => b.supportPhone, orElse: () => null);
    if (phone == null || phone.isEmpty) {
      showAppSnackBar(context, 'Support line coming soon');
      return;
    }
    final opened = await launchUrl(Uri(scheme: 'tel', path: phone));
    if (!opened && mounted) {
      showAppSnackBar(context, 'Could not call $phone');
    }
  }

  @override
  Widget build(BuildContext context) {
    final green = ref.watch(brandPaletteProvider).accent;
    final darkGreen = Color.lerp(green, Colors.black, 0.18)!;

    return Semantics(
      button: true,
      label: 'Call to book',
      child: Pressable(
        onTap: _call,
        child: SizedBox(
          width: CallFab.size + 16,
          height: CallFab.size + 16,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outward ripple ring: scale 1→1.55 while fading out.
              AnimatedBuilder(
                animation: _ripple,
                builder: (context, _) {
                  final t = Curves.easeOut.transform(_ripple.value);
                  return Transform.scale(
                    scale: 1 + 0.55 * t,
                    child: Container(
                      width: CallFab.size,
                      height: CallFab.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          width: 2,
                          color:
                              green.withValues(alpha: 0.45 * (1 - t)),
                        ),
                      ),
                    ),
                  );
                },
              ),
              Container(
                width: CallFab.size,
                height: CallFab.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [green, darkGreen],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: darkGreen.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.call_rounded,
                    color: AppColors.textInverse, size: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
