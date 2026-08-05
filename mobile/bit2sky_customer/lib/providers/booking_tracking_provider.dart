import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/booking_tracking_service.dart';
import 'booking_provider.dart';

/// Live tracking state for the order-detail screen (P0d): true while the
/// SignalR stream is delivering; false = polling fallback is active.
class LiveFlagNotifier extends Notifier<bool> {
  LiveFlagNotifier(this.bookingId);
  final String bookingId;

  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final bookingTrackingLiveProvider =
    NotifierProvider.family<LiveFlagNotifier, bool, String>(
        LiveFlagNotifier.new);

/// Streams live status updates for a booking; when the hub is unreachable
/// (or drops), degrades to a 15s poll of the REST detail so the tracker
/// still advances. Every event refreshes [bookingDetailProvider].
final bookingTrackingProvider =
    StreamProvider.family<BookingStatusUpdate?, String>((ref, bookingId) {
  final controller = StreamController<BookingStatusUpdate?>();
  final service = BookingTrackingService();
  Timer? pollTimer;

  void startPolling() {
    ref.read(bookingTrackingLiveProvider(bookingId).notifier).set(false);
    pollTimer ??= Timer.periodic(const Duration(seconds: 15), (_) {
      ref.invalidate(bookingDetailProvider(bookingId));
    });
  }

  final sub = service
      .watch(bookingId, onConnected: () {
        ref.read(bookingTrackingLiveProvider(bookingId).notifier).set(true);
      })
      .listen(
    (update) {
      ref.read(bookingTrackingLiveProvider(bookingId).notifier).set(true);
      ref.invalidate(bookingDetailProvider(bookingId));
      ref.invalidate(myBookingsProvider);
      if (!controller.isClosed) controller.add(update);
    },
    onDone: startPolling,
    onError: (_) => startPolling(),
  );

  ref.onDispose(() {
    pollTimer?.cancel();
    sub.cancel();
    service.dispose();
    controller.close();
  });
  return controller.stream;
});
