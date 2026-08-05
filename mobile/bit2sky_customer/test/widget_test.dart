import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bit2sky_customer/main.dart';
import 'package:bit2sky_customer/models/branding_config.dart';
import 'package:bit2sky_customer/providers/app_providers.dart';

void main() {
  testWidgets('App boots into the splash screen with branding', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Stub network-backed config so no real Dio call / timer runs in test.
          brandingProvider.overrideWith((ref) async => BrandingConfig.fallback),
          featureFlagsProvider.overrideWith((ref) async => const {}),
        ],
        child: const Bit2SkyApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Health, decoded.'), findsOneWidget);

    // Dispose the tree so the splash navigation timer is cancelled before exit.
    await tester.pumpWidget(const SizedBox());
  });
}
