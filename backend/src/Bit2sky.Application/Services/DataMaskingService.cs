using Bit2sky.Application.Abstractions;

namespace Bit2sky.Application.Services;

public interface IDataMaskingService
{
    string MaskPhone(string phone);
    string? MaskEmail(string? email);
}

// PHI masking per role (Section 4B / 4E). Phone → +91 XXXXX XX210.
public class DataMaskingService : IDataMaskingService
{
    public string MaskPhone(string phone)
    {
        if (string.IsNullOrWhiteSpace(phone)) return phone;
        var digits = new string(phone.Where(char.IsDigit).ToArray());
        if (digits.Length < 4) return "XXXX";
        var last3 = digits[^3..];
        return $"+91 XXXXX XX{last3}";
    }

    public string? MaskEmail(string? email)
    {
        if (string.IsNullOrWhiteSpace(email) || !email.Contains('@')) return email;
        var parts = email.Split('@', 2);
        var name = parts[0];
        var masked = name.Length <= 2 ? "**" : $"{name[0]}***{name[^1]}";
        return $"{masked}@{parts[1]}";
    }
}
