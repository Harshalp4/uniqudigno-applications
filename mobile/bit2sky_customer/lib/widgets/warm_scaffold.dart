import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import 'pressable.dart';

/// The app-wide warm page shell: cream canvas, floating circular back button
/// (cold-start-safe), bold title with optional subtitle, optional trailing
/// actions. Replaces plain `AppBar` screens so every page shares one look.
class WarmScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  const WarmScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  static const canvas = Color(0xFFFAF3EA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: canvas,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16, AppSpacing.s8, AppSpacing.s16, 0),
              child: Row(
                children: [
                  WarmCircleButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => context.canPop()
                        ? context.pop()
                        : context.go('/home'),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.h2.copyWith(
                                fontSize: 17, fontWeight: FontWeight.w800)),
                        if (subtitle != null)
                          Text(subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  ...actions,
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

/// Floating round white button used across warm headers.
class WarmCircleButton extends StatelessWidget {
  final IconData icon;
  final int badge;
  final VoidCallback onTap;
  const WarmCircleButton(
      {super.key, required this.icon, this.badge = 0, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Color(0x12000000),
                blurRadius: 10,
                offset: Offset(0, 3)),
          ],
        ),
        child: Badge(
          isLabelVisible: badge > 0,
          label: Text('$badge'),
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
