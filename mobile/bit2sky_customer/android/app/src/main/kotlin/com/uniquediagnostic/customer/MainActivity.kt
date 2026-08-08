package com.uniquediagnostic.customer

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity (not FlutterActivity): local_auth's BiometricPrompt
// requires a FragmentActivity host. With plain FlutterActivity the plugin throws,
// BiometricService.authenticate() swallows it and returns false, and the PHI gate
// on reports/family vault fails closed for every user.
class MainActivity : FlutterFragmentActivity()
