import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../core/notifications/push_service.dart';
import '../core/storage/secure_storage.dart';
import 'app_providers.dart';

enum AuthStatus { unknown, unauthenticated, otpSent, authenticated }

class AuthState {
  final AuthStatus status;
  final String? mobile;
  final String? email;
  final String? sessionId;
  final int otpExpirySeconds;
  final String? role;
  final bool busy;
  final String? error;
  final String? devOtp; // dev-only echo when no mail provider is wired
  final bool emailFlow; // true → the pending OTP is an email code

  const AuthState({
    this.status = AuthStatus.unknown,
    this.mobile,
    this.email,
    this.sessionId,
    this.otpExpirySeconds = 300,
    this.role,
    this.busy = false,
    this.error,
    this.devOtp,
    this.emailFlow = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? mobile,
    String? email,
    String? sessionId,
    int? otpExpirySeconds,
    String? role,
    bool? busy,
    String? error,
    String? devOtp,
    bool? emailFlow,
  }) =>
      AuthState(
        status: status ?? this.status,
        mobile: mobile ?? this.mobile,
        email: email ?? this.email,
        sessionId: sessionId ?? this.sessionId,
        otpExpirySeconds: otpExpirySeconds ?? this.otpExpirySeconds,
        role: role ?? this.role,
        busy: busy ?? this.busy,
        error: error,
        devOtp: devOtp,
        emailFlow: emailFlow ?? this.emailFlow,
      );
}

final secureStorageProvider =
    Provider<SecureStorageService>((ref) => SecureStorageService());

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // When a token refresh definitively fails the session is gone — reflect
    // it immediately so screens fall back to guest/login states instead of
    // surfacing generic network errors everywhere.
    ref.read(dioClientProvider).onSessionExpired =
        () => state = const AuthState(status: AuthStatus.unauthenticated);
    return const AuthState();
  }

  DioClient get _dio => ref.read(dioClientProvider);
  SecureStorageService get _storage => ref.read(secureStorageProvider);
  String get _deviceInfo => '${Platform.operatingSystem}-bit2sky-customer';

  /// Uploads the FCM token so this user receives push. Fire-and-forget — push
  /// registration must never block or fail an otherwise successful login.
  void _registerPush() => unawaited(PushService.instance.registerDevice(_dio));

  /// Decides the start destination: authenticated only when the session is
  /// actually recoverable (a refresh token exists) — a lone access token is a
  /// zombie session that would 401 on every call.
  Future<void> bootstrap() async {
    final token = await _storage.accessToken;
    final refresh = await _storage.refreshToken;
    final authed = token != null && refresh != null;
    state = state.copyWith(
      status: authed ? AuthStatus.authenticated : AuthStatus.unauthenticated,
    );
    if (authed) _registerPush();
  }

  Future<bool> sendOtp(String mobile) async {
    state = state.copyWith(busy: true, error: null);
    try {
      final data = await _dio.postData<Map<String, dynamic>>(
        '/auth/otp/send',
        body: {'mobile': mobile},
      );
      state = state.copyWith(
        busy: false,
        status: AuthStatus.otpSent,
        mobile: mobile,
        emailFlow: false,
        sessionId: (data['sessionId'] ?? data['session_id'])?.toString(),
        otpExpirySeconds:
            (data['expirySeconds'] ?? data['expiry_seconds'] ?? 300) as int,
      );
      return true;
    } catch (e) {
      state = state.copyWith(busy: false, error: DioClient.errorMessage(e));
      return false;
    }
  }

  Future<bool> verifyOtp(String otp) async {
    final sessionId = state.sessionId;
    if (sessionId == null) return false;
    state = state.copyWith(busy: true, error: null);
    try {
      final data = await _dio.postData<Map<String, dynamic>>(
        '/auth/otp/verify',
        body: {'sessionId': sessionId, 'otp': otp, 'deviceInfo': _deviceInfo},
      );
      final access = (data['accessToken'] ?? data['access_token']).toString();
      final refresh = (data['refreshToken'] ?? data['refresh_token']).toString();
      await _storage.saveTokens(access, refresh);
      state = state.copyWith(
        busy: false,
        status: AuthStatus.authenticated,
        role: (data['role'] ?? 'customer').toString(),
      );
      _registerPush();
      return true;
    } catch (e) {
      state = state.copyWith(busy: false, error: DioClient.errorMessage(e));
      return false;
    }
  }

  Future<bool> sendEmailOtp(String email) async {
    state = state.copyWith(busy: true, error: null);
    try {
      final data = await _dio.postData<Map<String, dynamic>>(
        '/auth/email/otp/send',
        body: {'email': email},
      );
      state = state.copyWith(
        busy: false,
        status: AuthStatus.otpSent,
        email: email,
        emailFlow: true,
        sessionId: (data['sessionId'] ?? data['session_id'])?.toString(),
        otpExpirySeconds:
            (data['expirySeconds'] ?? data['expiry_seconds'] ?? 300) as int,
        devOtp: (data['devOtp'] ?? data['dev_otp'])?.toString(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(busy: false, error: DioClient.errorMessage(e));
      return false;
    }
  }

  Future<bool> verifyEmailOtp(String otp) async {
    final sessionId = state.sessionId;
    if (sessionId == null) return false;
    state = state.copyWith(busy: true, error: null);
    try {
      final data = await _dio.postData<Map<String, dynamic>>(
        '/auth/email/otp/verify',
        body: {'sessionId': sessionId, 'otp': otp, 'deviceInfo': _deviceInfo},
      );
      await _saveAuth(data);
      return true;
    } catch (e) {
      state = state.copyWith(busy: false, error: DioClient.errorMessage(e));
      return false;
    }
  }

  /// Verifies the pending OTP using whichever channel sent it.
  Future<bool> verifyCurrent(String otp) =>
      state.emailFlow ? verifyEmailOtp(otp) : verifyOtp(otp);

  /// Exchanges a Google ID token for our session (mobile not required).
  Future<bool> loginWithGoogle(String idToken) async {
    state = state.copyWith(busy: true, error: null);
    try {
      final data = await _dio.postData<Map<String, dynamic>>(
        '/auth/google',
        body: {'idToken': idToken, 'deviceInfo': _deviceInfo},
      );
      await _saveAuth(data);
      return true;
    } catch (e) {
      state = state.copyWith(busy: false, error: DioClient.errorMessage(e));
      return false;
    }
  }

  Future<void> _saveAuth(Map<String, dynamic> data) async {
    final access = (data['accessToken'] ?? data['access_token']).toString();
    final refresh = (data['refreshToken'] ?? data['refresh_token']).toString();
    await _storage.saveTokens(access, refresh);
    state = state.copyWith(
      busy: false,
      status: AuthStatus.authenticated,
      role: (data['role'] ?? 'customer').toString(),
    );
    _registerPush();
  }

  Future<void> logout() async {
    await _storage.clear();
    await ref.read(encryptedCacheProvider)?.clear(); // clear offline PHI cache
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Permanently deletes the account and its data (DELETE /users/me), then logs
  /// out locally. The server anonymizes the profile, revokes sessions, and drops
  /// device tokens. Returns true on success.
  Future<bool> deleteAccount() async {
    state = state.copyWith(busy: true, error: null);
    try {
      await _dio.raw.delete('/users/me');
    } catch (e) {
      state = state.copyWith(busy: false, error: DioClient.errorMessage(e));
      return false;
    }
    await logout();
    return true;
  }
}

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
