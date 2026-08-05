using Bit2sky.Application.Abstractions;

namespace Bit2sky.Infrastructure.Security;

// bcrypt hashing for OTPs (Section 4A) and admin passwords (cost factor 12).
public class HashService : IHashService
{
    private const int WorkFactor = 12;

    public string Hash(string value) => BCrypt.Net.BCrypt.HashPassword(value, WorkFactor);

    public bool Verify(string value, string hash)
    {
        try { return BCrypt.Net.BCrypt.Verify(value, hash); }
        catch { return false; }
    }
}
