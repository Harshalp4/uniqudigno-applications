import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../providers/auth_provider.dart';

/// Google web client id (audience the server validates against). Not a secret.
/// Using PRESSO's project for now — the app package/SHA-1 (Android) and an iOS
/// OAuth client id must be registered in that Google Cloud project to work.
const googleServerClientId =
    '1041835508819-qrbgrlv5cikih6uiieb598o974urufkl.apps.googleusercontent.com';

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
