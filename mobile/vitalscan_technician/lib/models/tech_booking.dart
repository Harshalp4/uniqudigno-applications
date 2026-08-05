/// Booking as seen by a technician (own assigned only — server-enforced).
library;

class TechBooking {
  final String id;
  final String bookingNumber;
  final String status;
  final String scheduledDate;
  final String? scheduledTime;
  final String collectionType;
  final int itemCount;

  const TechBooking({
    required this.id,
    required this.bookingNumber,
    required this.status,
    required this.scheduledDate,
    this.scheduledTime,
    required this.collectionType,
    this.itemCount = 0,
  });

  factory TechBooking.fromJson(Map<String, dynamic> j) => TechBooking(
        id: (j['id'] ?? '').toString(),
        bookingNumber: (j['bookingNumber'] ?? '').toString(),
        status: (j['status'] ?? 'Confirmed').toString(),
        scheduledDate: (j['scheduledDate'] ?? '').toString(),
        scheduledTime: j['scheduledTime']?.toString(),
        collectionType: (j['collectionType'] ?? 'HomeCollection').toString(),
        itemCount: ((j['items'] as List?)?.length) ?? 0,
      );
}

/// Status flow a technician can advance through (Section 9 / C14).
const techStatuses = [
  'Confirmed',
  'TechnicianAssigned',
  'SampleCollected',
  'InLab',
];
