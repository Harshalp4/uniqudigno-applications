import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../models/booking_models.dart';
import '../../models/branding_config.dart';

/// Thin wrapper around the Razorpay checkout sheet (P0a).
///
/// Owns the SDK lifecycle so the booking screen stays declarative: create one
/// instance per screen, call [open] with the booking's order details, and
/// always call [dispose] from the screen's dispose(). Brand name and theme
/// color come from the DB-driven [BrandingConfig] — never hardcoded.
class RazorpayCheckout {
  Razorpay? _razorpay;

  /// Opens the payment sheet for [result] (which must have [canPayOnline]).
  ///
  /// [onSuccess] receives the gateway payment id + HMAC signature to send to
  /// `POST /bookings/{id}/confirm`. [onFailure] receives a user-showable
  /// message (dismissal, declined payment, wallet redirect, …).
  void open({
    required CreateBookingResult result,
    required BrandingConfig branding,
    String? contact,
    String? email,
    required void Function(String paymentId, String signature) onSuccess,
    required void Function(String message) onFailure,
  }) {
    // Fresh instance per attempt: clears stale listeners from a prior retry.
    _razorpay?.clear();
    final rzp = Razorpay();
    _razorpay = rzp;

    rzp.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse r) {
      final paymentId = r.paymentId ?? '';
      final signature = r.signature ?? '';
      if (paymentId.isEmpty || signature.isEmpty) {
        onFailure('Payment reference missing — if money was deducted it will '
            'be reconciled automatically.');
        return;
      }
      onSuccess(paymentId, signature);
    });
    rzp.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse r) {
      // Code 2 = user cancelled; anything else is a gateway/network decline.
      final cancelled = r.code == Razorpay.PAYMENT_CANCELLED;
      onFailure(cancelled
          ? 'Payment cancelled — your booking is saved, you can retry.'
          : 'Payment failed — nothing was charged. Please try again.');
    });
    rzp.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse r) {
      onFailure('External wallet selected — complete the payment there, '
          'then check your booking status.');
    });

    rzp.open({
      'key': result.razorpayKeyId,
      'order_id': result.razorpayOrderId,
      'amount': (result.amountPayable * 100).round(), // paise
      'currency': 'INR',
      'name': branding.appName,
      'description': 'Booking ${result.bookingNumber}',
      'prefill': {
        if (contact != null && contact.isNotEmpty) 'contact': contact,
        if (email != null && email.isNotEmpty) 'email': email,
      },
      'theme': {'color': branding.primaryColor},
    });
  }

  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }
}
