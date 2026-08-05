using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Bit2sky.Application.Abstractions;
using Bit2sky.Shared.Options;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Tokens;

namespace Bit2sky.Infrastructure.Security;

// RS256 token issuance per Section 4A. Private key sourced from Azure Key Vault.
public class JwtService : IJwtService, IDisposable
{
    public const string PermissionClaim = "permission";

    private readonly JwtOptions _options;
    private readonly RSA _rsa;
    private readonly RsaSecurityKey _signingKey;

    public JwtService(IOptions<JwtOptions> options)
    {
        _options = options.Value;
        _rsa = RSA.Create(2048);
        if (!string.IsNullOrWhiteSpace(_options.PrivateKeyPem))
            _rsa.ImportFromPem(_options.PrivateKeyPem);
        else if (!string.IsNullOrWhiteSpace(_options.PublicKeyPem))
            _rsa.ImportFromPem(_options.PublicKeyPem);
        _signingKey = new RsaSecurityKey(_rsa) { KeyId = _options.KeyId };
    }

    public (string AccessToken, DateTimeOffset ExpiresAt) IssueAccessToken(
        Guid userId, string role, IEnumerable<string> permissions, string deviceId)
    {
        var now = DateTimeOffset.UtcNow;
        var expires = now.AddMinutes(_options.AccessTokenMinutes);

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, userId.ToString()),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            new("role", role),
            new("device_id", deviceId),
        };
        claims.AddRange(permissions.Select(p => new Claim(PermissionClaim, p)));

        var descriptor = new SecurityTokenDescriptor
        {
            Issuer = _options.Issuer,
            Audience = _options.Audience,
            Subject = new ClaimsIdentity(claims),
            Expires = expires.UtcDateTime,
            IssuedAt = now.UtcDateTime,
            SigningCredentials = new SigningCredentials(_signingKey, SecurityAlgorithms.RsaSha256),
        };

        var token = new JsonWebTokenHandler().CreateToken(descriptor);
        return (token, expires);
    }

    public (string Token, string TokenHash) GenerateRefreshToken()
    {
        var bytes = RandomNumberGenerator.GetBytes(64);
        var token = Convert.ToBase64String(bytes);
        return (token, HashRefreshToken(token));
    }

    public string HashRefreshToken(string token)
        => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(token)));

    public string GetJwksJson()
    {
        var p = _rsa.ExportParameters(false);
        var jwk = new
        {
            keys = new[]
            {
                new
                {
                    kty = "RSA",
                    use = "sig",
                    alg = "RS256",
                    kid = _options.KeyId,
                    n = Base64UrlEncoder.Encode(p.Modulus),
                    e = Base64UrlEncoder.Encode(p.Exponent),
                }
            }
        };
        return JsonSerializer.Serialize(jwk);
    }

    public RsaSecurityKey ValidationKey => _signingKey;

    public void Dispose() => _rsa.Dispose();
}
