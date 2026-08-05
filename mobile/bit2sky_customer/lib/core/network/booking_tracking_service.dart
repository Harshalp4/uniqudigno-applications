import 'dart:async';

import 'package:signalr_netcore/signalr_client.dart';

import '../storage/secure_storage.dart';
import 'dio_client.dart';

/// One live status update from the BookingTrackingHub (P0d).
class BookingStatusUpdate {
  final String bookingId;
  final String status;
  final String paymentStatus;
  final int rescheduleCount;

  const BookingStatusUpdate({
    required this.bookingId,
    required this.status,
    required this.paymentStatus,
    required this.rescheduleCount,
  });

  factory BookingStatusUpdate.fromJson(Map<String, dynamic> j) =>
      BookingStatusUpdate(
        bookingId: (j['bookingId'] ?? '').toString(),
        status: (j['status'] ?? '').toString(),
        paymentStatus: (j['paymentStatus'] ?? '').toString(),
        rescheduleCount: (j['rescheduleCount'] as num?)?.toInt() ?? 0,
      );
}

/// SignalR client for /hubs/booking-tracking. The caller owns the lifecycle:
/// [watch] connects + joins the per-booking group and yields updates;
/// [dispose] leaves and stops. Connection failures surface as a closed
/// stream so the provider can fall back to polling.
class BookingTrackingService {
  BookingTrackingService({SecureStorageService? storage})
      : _storage = storage ?? SecureStorageService();

  final SecureStorageService _storage;
  HubConnection? _connection;
  String? _joinedBookingId;

  static String get hubUrl {
    final base = DioClient.defaultBaseUrl;
    final root = base.replaceFirst(RegExp(r'/api/v\d+/?$'), '');
    return '$root/hubs/booking-tracking';
  }

  Stream<BookingStatusUpdate> watch(String bookingId, {void Function()? onConnected}) {
    final controller = StreamController<BookingStatusUpdate>();

    Future<void> connect() async {
      final connection = HubConnectionBuilder()
          .withUrl(
            hubUrl,
            options: HttpConnectionOptions(
              accessTokenFactory: () async =>
                  await _storage.accessToken ?? '',
            ),
          )
          .withAutomaticReconnect()
          .build();
      _connection = connection;

      connection.on('BookingStatusChanged', (args) {
        final payload = args?.firstOrNull;
        if (payload is Map) {
          final update = BookingStatusUpdate.fromJson(
              Map<String, dynamic>.from(payload));
          if (update.bookingId == bookingId && !controller.isClosed) {
            controller.add(update);
          }
        }
      });
      connection.onreconnected(({connectionId}) async {
        // Groups don't survive a reconnect — rejoin.
        try {
          await connection.invoke('JoinBooking', args: [bookingId]);
        } catch (_) {}
      });
      connection.onclose(({error}) {
        if (!controller.isClosed) controller.close();
      });

      await connection.start();
      await connection.invoke('JoinBooking', args: [bookingId]);
      _joinedBookingId = bookingId;
      onConnected?.call();
    }

    connect().catchError((_) {
      // Hub unreachable → close the stream; the provider falls back to polling.
      if (!controller.isClosed) controller.close();
    });

    controller.onCancel = dispose;
    return controller.stream;
  }

  Future<void> dispose() async {
    final connection = _connection;
    _connection = null;
    if (connection == null) return;
    try {
      if (_joinedBookingId != null &&
          connection.state == HubConnectionState.Connected) {
        await connection.invoke('LeaveBooking', args: [_joinedBookingId!]);
      }
    } catch (_) {}
    try {
      await connection.stop();
    } catch (_) {}
  }
}
