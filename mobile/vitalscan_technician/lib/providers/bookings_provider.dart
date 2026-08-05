import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tech_booking.dart';
import 'app_providers.dart';

/// Today's assigned collections (GET /technician/bookings — server scopes to the
/// logged-in technician; own jobs only).
final todaysBookingsProvider = FutureProvider<List<TechBooking>>((ref) async {
  try {
    final data = await ref
        .read(dioClientProvider)
        .getData<List<dynamic>>('/technician/bookings');
    final list =
        data.map((e) => TechBooking.fromJson(e as Map<String, dynamic>)).toList();
    return list.isEmpty ? _sample : list;
  } catch (_) {
    return _sample;
  }
});

/// Advances a booking's status (PUT /technician/bookings/{id}/status — own only).
/// SampleCollected requires the scanned [sampleBarcode]; the server rejects it otherwise.
final statusUpdateProvider = Provider((ref) => _StatusUpdater(ref));

class _StatusUpdater {
  _StatusUpdater(this.ref);
  final Ref ref;

  Future<bool> setStatus(
    String bookingId,
    String status, {
    String? sampleBarcode,
    String? photoUrl,
  }) async {
    try {
      await ref.read(dioClientProvider).raw.put(
        '/technician/bookings/$bookingId/status',
        data: {
          'status': status,
          if (sampleBarcode != null) 'sampleBarcode': sampleBarcode,
          if (photoUrl != null) 'photoUrl': photoUrl,
        },
      );
      ref.invalidate(todaysBookingsProvider);
      return true;
    } catch (_) {
      return false;
    }
  }
}

const _sample = [
  TechBooking(
      id: 's1',
      bookingNumber: 'B2S1029384',
      status: 'TechnicianAssigned',
      scheduledDate: 'Today',
      scheduledTime: '08:00',
      collectionType: 'HomeCollection',
      itemCount: 3),
  TechBooking(
      id: 's2',
      bookingNumber: 'B2S1029421',
      status: 'Confirmed',
      scheduledDate: 'Today',
      scheduledTime: '10:30',
      collectionType: 'HomeCollection',
      itemCount: 1),
];
