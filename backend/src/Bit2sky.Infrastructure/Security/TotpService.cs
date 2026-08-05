using System.Security.Cryptography;
using Bit2sky.Application.Abstractions;
using OtpNet;

namespace Bit2sky.Infrastructure.Security;

// Admin 2FA via TOTP (Google Authenticator / Authy compatible) — Section 4A.
public class TotpService : ITotpService
{
    private const string Issuer = "Unique Diagnostic Centre";

    public (string Secret, string OtpAuthUri) Generate(string accountName)
    {
        var key = KeyGeneration.GenerateRandomKey(20);
        var secret = Base32Encoding.ToString(key);
        var uri = $"otpauth://totp/{Uri.EscapeDataString(Issuer)}:{Uri.EscapeDataString(accountName)}"
                + $"?secret={secret}&issuer={Uri.EscapeDataString(Issuer)}&algorithm=SHA1&digits=6&period=30";
        return (secret, uri);
    }

    public bool Verify(string secret, string code)
    {
        if (string.IsNullOrWhiteSpace(secret) || string.IsNullOrWhiteSpace(code))
            return false;
        var totp = new Totp(Base32Encoding.ToBytes(secret));
        return totp.VerifyTotp(code.Trim(), out _, new VerificationWindow(previous: 1, future: 1));
    }

    // 8 single-use backup codes (Section 4A). Caller stores only the hashes.
    public IReadOnlyList<string> GenerateBackupCodes(int count = 8)
    {
        var codes = new List<string>(count);
        for (var i = 0; i < count; i++)
        {
            var n = RandomNumberGenerator.GetInt32(0, 100_000_000);
            codes.Add(n.ToString("D8"));
        }
        return codes;
    }
}
