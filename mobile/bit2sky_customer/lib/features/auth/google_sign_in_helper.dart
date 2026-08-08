import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../providers/auth_provider.dart';

/// Google web client id (audience the server validates against). Not a secret.
/// Firebase project `uniquediagnostic-48052`. The Android OAuth client only
/// resolves once the app SHA-1 is registered in that project and the resulting
/// google-services.json (with a non-empty oauth_client) is bundled.
const googleServerClientId =
    '381464039988-8nku4nsibvti1c6j8eiav8h95q45oe9m.apps.googleusercontent.com';

/// iOS OAuth client id — required for Google Sign-In on iPhone/iPad, together
/// with its REVERSED form as a URL scheme in ios/Runner/Info.plist.
const googleIosClientId = 'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com';

/// Runs the native Google flow and exchanges the id token for our session.
/// Returns null on success, `'cancelled'` if the user backed out, or an error.
Future<String?> signInWithGoogle(WidgetRef ref) async {
  try {
    final gsi = GoogleSignIn(
      serverClientId: googleServerClientId,
      // Android resolves its client from google-services; iOS needs it explicitly.
      clientId: Platform.isIOS ? googleIosClientId : null,
    );
    final account = await gsi.signIn();
    if (account == null) return 'cancelled';
    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) return 'Google sign-in failed. Please try again.';
    final ok = await ref.read(authProvider.notifier).loginWithGoogle(idToken);
    return ok ? null : 'Google sign-in failed. Please try again.';
  } catch (_) {
    return 'Google sign-in failed. Please try again.';
  }
}
