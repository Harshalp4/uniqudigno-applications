import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';

/// The one way to show transient confirmations ("X added to cart").
///
/// Fixes the stuck-SnackBar defect: every call gets an explicit 2500 ms
/// duration, floats ABOVE the bottom dock instead of sitting under/behind it,
/// queues at most one at a time, and is swipe-dismissible. An [actionLabel]
/// tap also dismisses.
void showAppSnackBar(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(milliseconds: 2500),
      behavior: SnackBarBehavior.floating,
      dismissDirection: DismissDirection.horizontal,
      // Clear the floating dock: dock 64 + its 8 bottom inset + sm gap.
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        0,
        AppSpacing.s16,
        AppSpacing.bottomNavHeight + AppSpacing.s8 + AppSpacing.s8,
      ),
      action: actionLabel == null
          ? null
          : SnackBarAction(
              label: actionLabel,
              onPressed: () {
                messenger.hideCurrentSnackBar();
                onAction?.call();
              },
            ),
    ),
  );
}
