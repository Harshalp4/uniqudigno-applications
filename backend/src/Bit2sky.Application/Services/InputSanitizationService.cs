using System.Text.RegularExpressions;
using Bit2sky.Application.Abstractions;
using Ganss.Xss;

namespace Bit2sky.Application.Services;

// Input hardening (Section 4B + Section 13). HTML strip/sanitize, SSRF allowlist,
// MIME magic-byte validation, prompt-injection stripping.
public partial class InputSanitizationService : IInputSanitizationService
{
    // Section 2 SSRF allowlist (host suffixes). Should be overridable from app_config.
    private static readonly string[] AllowedHostSuffixes =
    {
        "images.unsplash.com", "images.pexels.com", "picsum.photos",
        ".blob.core.windows.net", "bit2sky.com",
    };

    private static readonly string[] InjectionPatterns =
    {
        "ignore previous instructions", "ignore all previous", "disregard the above",
        "system:", "<system>", "</system>", "you are now", "act as",
        "reveal your prompt", "developer mode",
    };

    private readonly HtmlSanitizer _richSanitizer = new();

    public string StripHtml(string input)
        => string.IsNullOrEmpty(input) ? input : StripTagsRegex().Replace(input, string.Empty).Trim();

    public string SanitizeRichHtml(string html)
        => string.IsNullOrEmpty(html) ? html : _richSanitizer.Sanitize(html);

    public bool IsUrlAllowed(string url)
    {
        if (!Uri.TryCreate(url, UriKind.Absolute, out var uri)) return false;
        if (uri.Scheme != Uri.UriSchemeHttps) return false;
        var host = uri.Host.ToLowerInvariant();
        return AllowedHostSuffixes.Any(s =>
            s.StartsWith('.') ? host.EndsWith(s) : host == s || host.EndsWith("." + s));
    }

    // Magic-byte sniffing — never trust the declared Content-Type (Section 4B).
    public bool IsAllowedFile(ReadOnlySpan<byte> content, string declaredMime, long maxBytes, out string detectedMime)
    {
        detectedMime = "application/octet-stream";
        if (content.Length == 0 || content.Length > maxBytes) return false;

        if (content.Length >= 4 && content[0] == 0x25 && content[1] == 0x50 && content[2] == 0x44 && content[3] == 0x46)
            detectedMime = "application/pdf";
        else if (content.Length >= 3 && content[0] == 0xFF && content[1] == 0xD8 && content[2] == 0xFF)
            detectedMime = "image/jpeg";
        else if (content.Length >= 8 && content[0] == 0x89 && content[1] == 0x50 && content[2] == 0x4E && content[3] == 0x47)
            detectedMime = "image/png";
        else if (content.Length >= 12 && content[0] == 0x52 && content[1] == 0x49 && content[2] == 0x46 && content[3] == 0x46
                 && content[8] == 0x57 && content[9] == 0x45 && content[10] == 0x42 && content[11] == 0x50)
            detectedMime = "image/webp";
        else
            return false;

        // Declared MIME must agree with sniffed type.
        return string.Equals(detectedMime, declaredMime, StringComparison.OrdinalIgnoreCase);
    }

    public string StripPromptInjection(string message)
    {
        if (string.IsNullOrEmpty(message)) return message;
        var cleaned = message;
        foreach (var pattern in InjectionPatterns)
            cleaned = Regex.Replace(cleaned, Regex.Escape(pattern), "[removed]", RegexOptions.IgnoreCase);
        return cleaned;
    }

    [GeneratedRegex("<.*?>", RegexOptions.Singleline)]
    private static partial Regex StripTagsRegex();
}
