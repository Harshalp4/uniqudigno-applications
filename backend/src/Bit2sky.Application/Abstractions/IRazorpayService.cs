namespace Bit2sky.Application.Abstractions;

public interface IRazorpayService
{
    /// The PUBLIC Razorpay key id (rzp_test_… / rzp_live_…) the client checkout
    /// sheet needs. Null/empty when the gateway is not configured (dev mode).
    string? KeyId { get; }

    /// True when real credentials are configured and genuine orders are created.
    bool IsConfigured { get; }

    Task<string> CreateOrderAsync(decimal amount, string currency, string receipt, CancellationToken ct = default);
    // HMAC-SHA256 signature verification (Section 7 / Section 4B).
    bool VerifyPaymentSignature(string orderId, string paymentId, string signature);
    bool VerifyWebhookSignature(string payload, string signature);
}
