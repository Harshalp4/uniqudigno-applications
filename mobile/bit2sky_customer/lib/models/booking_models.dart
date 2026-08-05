/// Booking models from /bookings.
library;

/// Single source of truth for status → 5-stage tracker index (Booked ·
/// Confirmed · On the way · Collected · Report). A rescheduled booking sits
/// at "Confirmed" — it re-enters the flow once ops re-assigns a technician.
int trackerIndexFor(String status) => switch (status) {
      'Confirmed' => 1,
      'Rescheduled' => 1,
      'TechnicianAssigned' => 2,
      'SampleCollected' => 3,
      'InLab' => 3,
      'ReportReady' => 4,
      'Completed' => 4,
      _ => 0,
    };

class CreateBookingResult {
  final String bookingId;
  final String bookingNumber;
  final String razorpayOrderId;
  final num amountPayable;

  /// Public Razorpay key id for the checkout sheet. Null when the gateway is
  /// not configured (dev), the booking is COD, or nothing is left to charge —
  /// in those cases the payment sheet is never opened.
  final String? razorpayKeyId;

  const CreateBookingResult({
    required this.bookingId,
    required this.bookingNumber,
    required this.razorpayOrderId,
    required this.amountPayable,
    this.razorpayKeyId,
  });

  /// True when an online charge is both required and possible.
  bool get canPayOnline =>
      razorpayKeyId != null &&
      razorpayKeyId!.isNotEmpty &&
      razorpayOrderId.isNotEmpty &&
      amountPayable > 0;

  factory CreateBookingResult.fromJson(Map<String, dynamic> j) =>
      CreateBookingResult(
        bookingId: (j['bookingId'] ?? '').toString(),
        bookingNumber: (j['bookingNumber'] ?? '').toString(),
        razorpayOrderId: (j['razorpayOrderId'] ?? '').toString(),
        amountPayable: (j['amountPayable'] ?? 0) as num,
        razorpayKeyId: j['razorpayKeyId']?.toString(),
      );
}

/// A home-collection slot from `GET /slots?date=`.
class SlotOption {
  final String id;
  final String startTime; // "HH:mm"
  final String endTime;
  final String period; // Morning | Afternoon | Evening
  final bool available;

  const SlotOption({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.period,
    required this.available,
  });

  factory SlotOption.fromJson(Map<String, dynamic> j) => SlotOption(
        id: (j['id'] ?? '').toString(),
        startTime: (j['startTime'] ?? '').toString(),
        endTime: (j['endTime'] ?? '').toString(),
        period: (j['period'] ?? 'Morning').toString(),
        available: j['available'] == true,
      );
}

/// Full booking detail (`GET /bookings/{id}` → BookingDetailDto). Carries
/// payment state so the tracker can show COD "Paid" flips, plus the
/// reschedule counters that gate the Reschedule action.
class BookingDetail {
  final String id;
  final String bookingNumber;
  final String status;
  final String scheduledDate; // yyyy-MM-dd
  final String? scheduledTime; // HH:mm
  final String? slotId;
  final String? patientName;
  final num itemsTotal;
  final num discountTotal;
  final num walletApplied;
  final num amountPayable;
  final int rescheduleCount;
  final int maxReschedules;
  final String paymentStatus; // Created | Pending | Paid | Failed | Refunded…
  final String paymentMethod; // Upi | Card | Netbanking | CashOnCollection…
  final List<String> itemNames;

  const BookingDetail({
    required this.id,
    required this.bookingNumber,
    required this.status,
    required this.scheduledDate,
    this.scheduledTime,
    this.slotId,
    this.patientName,
    required this.itemsTotal,
    required this.discountTotal,
    required this.walletApplied,
    required this.amountPayable,
    required this.rescheduleCount,
    required this.maxReschedules,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.itemNames,
  });

  bool get isPaid => paymentStatus == 'Paid';
  bool get isCod => paymentMethod == 'CashOnCollection';
  bool get isCancelled => status == 'Cancelled' || status == 'NoShow';
  int get trackerIndex => trackerIndexFor(status);
  bool get canReschedule =>
      const {'Confirmed', 'TechnicianAssigned', 'Rescheduled'}
          .contains(status) &&
      rescheduleCount < maxReschedules;

  BookingDetail copyWith({String? status, String? paymentStatus, int? rescheduleCount}) =>
      BookingDetail(
        id: id,
        bookingNumber: bookingNumber,
        status: status ?? this.status,
        scheduledDate: scheduledDate,
        scheduledTime: scheduledTime,
        slotId: slotId,
        patientName: patientName,
        itemsTotal: itemsTotal,
        discountTotal: discountTotal,
        walletApplied: walletApplied,
        amountPayable: amountPayable,
        rescheduleCount: rescheduleCount ?? this.rescheduleCount,
        maxReschedules: maxReschedules,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        paymentMethod: paymentMethod,
        itemNames: itemNames,
      );

  factory BookingDetail.fromJson(Map<String, dynamic> j) => BookingDetail(
        id: (j['id'] ?? '').toString(),
        bookingNumber: (j['bookingNumber'] ?? '').toString(),
        status: (j['status'] ?? '').toString(),
        scheduledDate: (j['scheduledDate'] ?? '').toString(),
        scheduledTime: j['scheduledTime']?.toString(),
        slotId: j['slotId']?.toString(),
        patientName: j['patientName']?.toString(),
        itemsTotal: (j['itemsTotal'] ?? 0) as num,
        discountTotal: (j['discountTotal'] ?? 0) as num,
        walletApplied: (j['walletApplied'] ?? 0) as num,
        amountPayable: (j['amountPayable'] ?? 0) as num,
        rescheduleCount: (j['rescheduleCount'] ?? 0) as int,
        maxReschedules: (j['maxReschedules'] ?? 2) as int,
        paymentStatus: (j['paymentStatus'] ?? 'Created').toString(),
        paymentMethod: (j['paymentMethod'] ?? 'Upi').toString(),
        itemNames: ((j['items'] ?? []) as List)
            .map((e) => (e is Map ? (e['itemName'] ?? '') : '').toString())
            .where((s) => s.isNotEmpty)
            .toList(),
      );
}

/// A booking as the customer sees it in their list (`GET /bookings`).
class MyBooking {
  final String id;
  final String bookingNumber;
  final String status;
  final List<String> itemNames;

  const MyBooking({
    required this.id,
    required this.bookingNumber,
    required this.status,
    required this.itemNames,
  });

  /// Title from the tests/packages booked, e.g. "CBC + Lipid Profile".
  String get title =>
      itemNames.isEmpty ? 'Your booking' : itemNames.join(' + ');

  /// In-progress = confirmed through in-lab (not pending/completed/cancelled).
  bool get isActive => const {
        'Confirmed',
        'Rescheduled',
        'TechnicianAssigned',
        'SampleCollected',
        'InLab',
      }.contains(status);

  /// 0-based step in the 5-stage tracker (Booked · Confirmed · On the way ·
  /// Collected · Report).
  int get currentStep => trackerIndexFor(status);

  factory MyBooking.fromJson(Map<String, dynamic> j) => MyBooking(
        id: (j['id'] ?? '').toString(),
        bookingNumber: (j['bookingNumber'] ?? '').toString(),
        status: (j['status'] ?? '').toString(),
        itemNames: ((j['items'] ?? []) as List)
            .map((e) => (e is Map ? (e['itemName'] ?? '') : '').toString())
            .where((s) => s.isNotEmpty)
            .toList(),
      );
}
