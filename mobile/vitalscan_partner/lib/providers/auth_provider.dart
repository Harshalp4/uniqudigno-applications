import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../core/storage/secure_storage.dart';
import 'app_providers.dart';

enum AuthStatus { unknown, unauthenticated, otpSent, authenticated }

class AuthState {
  final AuthStatus status;
  final String? mobile;
  final String? sessionId;
  final int otpExpirySeconds;
  final String? role;
  final bool busy;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.mobile,
    this.sessionId,
    this.otpExpirySeconds = 300,
    this.role,
    this.busy = false,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? mobile,
    String? sessionId,
    int? otpExpirySeconds,
    String? role,
    bool? busy,
    String? error,
  }) =>
      AuthState(
        status: status ?? this.status,
        mobile: mobile ?? this.mobile,
        sessionId: sessionId ?? this.sessionId,
        otpExpirySeconds: otpExpirySeconds ?? this.otpExpirySeconds,
        role: role ?? this.role,
        busy: busy ?? this.busy,
        error: error,
      );
}

final secureStorageProvider =
    Provider<SecureStorageService>((ref) => SecureStorageService());

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  DioClient get _dio => ref.read(dioClientProvider);
  SecureStorageService get _storage => ref.read(secureStorageProvider);
  String get _deviceInfo => '${Platform.operatingSystem}-bit2sky-partner';

  /// Decides the start destination: authenticated if a token is already stored.
  Future<void> bootstrap() async {
    final token = await _storage.accessToken;
    state = state.copyWith(
      status:
          token == null ? AuthStatus.unauthenticated : AuthStatus.authenticated,
    );
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
      return true;
    } catch (e) {
      state = state.copyWith(busy: false, error: DioClient.errorMessage(e));
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.clear();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
