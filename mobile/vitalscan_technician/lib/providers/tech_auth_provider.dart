import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../core/storage/secure_storage.dart';
import 'app_providers.dart';

enum TechAuthStatus { unknown, unauthenticated, authenticated }

class TechAuthState {
  final TechAuthStatus status;
  final bool busy;
  final String? error;
  const TechAuthState({
    this.status = TechAuthStatus.unknown,
    this.busy = false,
    this.error,
  });

  TechAuthState copyWith({TechAuthStatus? status, bool? busy, String? error}) =>
      TechAuthState(
          status: status ?? this.status, busy: busy ?? this.busy, error: error);
}

final secureStorageProvider = Provider((ref) => SecureStorageService());

/// Employee-ID + password login (bcrypt verified by the API, Section 9).
class TechAuthNotifier extends Notifier<TechAuthState> {
  @override
  TechAuthState build() => const TechAuthState();

  Future<void> bootstrap() async {
    final token = await ref.read(secureStorageProvider).accessToken;
    state = state.copyWith(
        status: token == null
            ? TechAuthStatus.unauthenticated
            : TechAuthStatus.authenticated);
  }

  Future<bool> login(String employeeId, String password) async {
    state = state.copyWith(busy: true, error: null);
    try {
      final data = await ref.read(dioClientProvider).postData<Map<String, dynamic>>(
        '/auth/technician/login',
        body: {
          'employeeId': employeeId,
          'password': password,
          'deviceInfo': DioClient.deviceInfo,
        },
      );
      final access = (data['accessToken'] ?? data['access_token']).toString();
      final refresh = (data['refreshToken'] ?? data['refresh_token']).toString();
      await ref.read(secureStorageProvider).saveTokens(access, refresh);
      state = state.copyWith(busy: false, status: TechAuthStatus.authenticated);
      return true;
    } catch (e) {
      state = state.copyWith(busy: false, error: DioClient.errorMessage(e));
      return false;
    }
  }

  Future<void> logout() async {
    await ref.read(secureStorageProvider).clear();
    state = const TechAuthState(status: TechAuthStatus.unauthenticated);
  }
}

final techAuthProvider =
    NotifierProvider<TechAuthNotifier, TechAuthState>(TechAuthNotifier.new);
