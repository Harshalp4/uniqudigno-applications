using System.Net.Http.Headers;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Bit2sky.Application.Abstractions;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace Bit2sky.Infrastructure.Payments;

// Razorpay order creation + HMAC-SHA256 signature verification (Section 7 / 4B).
// Keys are sourced from Key Vault via configuration; never hardcoded.
//
// With credentials configured (Razorpay:KeyId + Razorpay:KeySecret) a REAL order
// is created via the Orders API — the mobile checkout sheet refuses order ids
// that don't exist on Razorpay's side, so this is required for live payments.
// Without credentials (dev) a deterministic local id is returned; the client
// detects the missing KeyId in the booking response and hides online payment.
public class RazorpayService : IRazorpayService
{
    private const string OrdersUrl = "https://api.razorpay.com/v1/orders";

    private readonly string _keyId;
    private readonly string _keySecret;
    private readonly string _webhookSecret;
    private readonly IHttpClientFactory _httpFactory;
    private readonly ILogger<RazorpayService> _logger;

    public RazorpayService(IConfiguration config, IHttpClientFactory httpFactory,
        ILogger<RazorpayService> logger)
    {
        _keyId = config["Razorpay:KeyId"] ?? string.Empty;
        _keySecret = config["Razorpay:KeySecret"] ?? string.Empty;
        _webhookSecret = config["Razorpay:WebhookSecret"] ?? string.Empty;
        _httpFactory = httpFactory;
        _logger = logger;
    }

    public string? KeyId => string.IsNullOrEmpty(_keyId) ? null : _keyId;

    public bool IsConfigured =>
        !string.IsNullOrEmpty(_keyId) && !string.IsNullOrEmpty(_keySecret);

    public async Task<string> CreateOrderAsync(decimal amount, string currency, string receipt, CancellationToken ct = default)
    {
        // Dev fallback: no credentials → local id (client hides online payment).
        if (!IsConfigured)
            return $"order_{Guid.NewGuid():N}";

        var client = _httpFactory.CreateClient(nameof(RazorpayService));
        using var request = new HttpRequestMessage(HttpMethod.Post, OrdersUrl);
        request.Headers.Authorization = new AuthenticationHeaderValue(
            "Basic", Convert.ToBase64String(Encoding.UTF8.GetBytes($"{_keyId}:{_keySecret}")));
        request.Content = new StringContent(JsonSerializer.Serialize(new
        {
            amount = (long)Math.Round(amount * 100), // paise
            currency,
            receipt,
        }), Encoding.UTF8, "application/json");

        using var response = await client.SendAsync(request, ct);
        var body = await response.Content.ReadAsStringAsync(ct);
        if (!response.IsSuccessStatusCode)
        {
            _logger.LogError("Razorpay order creation failed ({Status}): {Body}",
                (int)response.StatusCode, body);
            throw new InvalidOperationException("Payment gateway is unavailable. Please try again.");
        }

        using var doc = JsonDocument.Parse(body);
        return doc.RootElement.GetProperty("id").GetString()
            ?? throw new InvalidOperationException("Payment gateway returned an invalid order.");
    }

    public bool VerifyPaymentSignature(string orderId, string paymentId, string signature)
        => FixedTimeEquals(Sign($"{orderId}|{paymentId}", _keySecret), signature);

    public bool VerifyWebhookSignature(string payload, string signature)
        => FixedTimeEquals(Sign(payload, _webhookSecret), signature);

    private static string Sign(string data, string secret)
    {
        using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(secret));
        return Convert.ToHexString(hmac.ComputeHash(Encoding.UTF8.GetBytes(data))).ToLowerInvariant();
    }

    private static bool FixedTimeEquals(string a, string b)
        => CryptographicOperations.FixedTimeEquals(
            Encoding.UTF8.GetBytes(a), Encoding.UTF8.GetBytes(b));
}
