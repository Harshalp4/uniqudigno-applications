import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../models/booking_models.dart';
import 'app_providers.dart';
import 'cart_provider.dart';

class BookingDraft {
  final DateTime date;
  final String? timeSlot; // "HH:mm"
  final String? slotId;
  final String? addressId;
  final String? familyMemberId; // null = the account holder (self)
  final String paymentMethod; // "online" | "cod"
  const BookingDraft({
    required this.date,
    this.timeSlot,
    this.slotId,
    this.addressId,
    this.familyMemberId,
    this.paymentMethod = 'cod',
  });
}

class BookingController extends Notifier<AsyncValue<CreateBookingResult?>> {
  DioClient get _dio => ref.read(dioClientProvider);

  @override
  AsyncValue<CreateBookingResult?> build() => const AsyncData(null);

  /// Creates a booking from the active cart (backend creates the Razorpay order).
  Future<CreateBookingResult?> create(BookingDraft draft) async {
    state = const AsyncLoading();
    try {
      final dateStr = draft.date.toIso8601String().split('T').first;
      final body = <String, dynamic>{
        'scheduledDate': dateStr,
        'paymentMethod': draft.paymentMethod,
      };
      if (draft.timeSlot != null) {
        body['scheduledTime'] = '${draft.timeSlot}:00';
      }
      if (draft.slotId != null) body['slotId'] = draft.slotId;
      if (draft.addressId != null) body['addressId'] = draft.addressId;
      if (draft.familyMemberId != null) {
        body['familyMemberId'] = draft.familyMemberId;
      }

      final data = await _dio.postData<Map<String, dynamic>>(
        '/bookings',
        body: body,
      );
      final result = CreateBookingResult.fromJson(data);
      state = AsyncData(result);
      // Cart is cleared server-side on checkout — refresh the local view.
      ref.read(cartProvider.notifier).refresh();
      return result;
    } catch (e) {
      state = AsyncError(DioClient.errorMessage(e), StackTrace.current);
      return null;
    }
  }

  /// Confirms payment (Razorpay HMAC verified server-side).
  Future<bool> confirm(
    String bookingId,
    String paymentId,
    String signature,
  ) async {
    try {
      await _dio.postData<dynamic>(
        '/bookings/$bookingId/confirm',
        body: {'razorpayPaymentId': paymentId, 'razorpaySignature': signature},
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Reschedules a booking (P0c). Returns null on success, otherwise the
  /// server's envelope message (slot full / limit reached / window passed).
  Future<String?> reschedule(
    String bookingId, {
    required DateTime date,
    String? slotId,
    String? time,
  }) async {
    try {
      final body = <String, dynamic>{
        'scheduledDate': date.toIso8601String().split('T').first,
      };
      if (time != null) body['scheduledTime'] = '$time:00';
      if (slotId != null) body['slotId'] = slotId;
      await _dio.postData<dynamic>('/bookings/$bookingId/reschedule',
          body: body);
      ref.invalidate(myBookingsProvider);
      ref.invalidate(activeBookingProvider);
      ref.invalidate(bookingDetailProvider(bookingId));
      return null;
    } catch (e) {
      return DioClient.errorMessage(e);
    }
  }
}

/// Full booking detail with payment + reschedule state (`GET /bookings/{id}`).
final bookingDetailProvider =
    FutureProvider.family<BookingDetail?, String>((ref, id) async {
  try {
    final data = await ref
        .read(dioClientProvider)
        .getData<Map<String, dynamic>>('/bookings/$id');
    return BookingDetail.fromJson(data);
  } catch (_) {
    return null;
  }
});

/// Available collection slots for a date (real availability from the backend).
final slotsProvider = FutureProvider.family<List<SlotOption>, DateTime>((
  ref,
  date,
) async {
  try {
    final dateStr = date.toIso8601String().split('T').first;
    final data = await ref
        .read(dioClientProvider)
        .getData<List<dynamic>>('/slots?date=$dateStr');
    return data
        .map((e) => SlotOption.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return const [];
  }
});

/// The user's current in-progress booking, or null (guest / nothing active).
/// Drives the Home "Active Booking" card — which stays hidden when null.
final activeBookingProvider = FutureProvider<MyBooking?>((ref) async {
  try {
    final data = await ref
        .read(dioClientProvider)
        .getData<List<dynamic>>('/bookings')
        .timeout(const Duration(seconds: 2));
    final bookings = data
        .map((e) => MyBooking.fromJson(e as Map<String, dynamic>))
        .where((b) => b.isActive)
        .toList();
    return bookings.isEmpty ? null : bookings.first;
  } catch (_) {
    return null; // guest / unreachable → no active booking
  }
});

final myBookingsProvider = FutureProvider<List<MyBooking>>((ref) async {
  try {
    final data = await ref
        .read(dioClientProvider)
        .getData<List<dynamic>>('/bookings')
        .timeout(const Duration(seconds: 2));
    return data
        .map((e) => MyBooking.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return const [];
  }
});

final bookingControllerProvider =
    NotifierProvider<BookingController, AsyncValue<CreateBookingResult?>>(
      BookingController.new,
    );

/// UI context for the confirmation screen — details the create-booking API
/// response doesn't echo back (chosen address + slot). Set by the booking
/// screen right before navigating to /booking/confirm.
typedef LastBookingUiContext = ({
  String? addressType,
  String? addressLine,
  String? slotTime,
});

class LastBookingUiContextNotifier extends Notifier<LastBookingUiContext?> {
  @override
  LastBookingUiContext? build() => null;

  void set(LastBookingUiContext value) => state = value;
}

final lastBookingUiContextProvider =
    NotifierProvider<LastBookingUiContextNotifier, LastBookingUiContext?>(
  LastBookingUiContextNotifier.new,
);
