namespace Bit2sky.Shared.Options;

public class JwtOptions
{
    public const string Section = "Jwt";
    public string Issuer { get; set; } = "vitalscan-auth";
    public string Audience { get; set; } = "vitalscan-api";
    public int AccessTokenMinutes { get; set; } = 15;
    public string? PrivateKeyPem { get; set; }   // from Key Vault
    public string? PublicKeyPem { get; set; }    // from Key Vault / JWKS
    public string KeyId { get; set; } = "vitalscan-rs256-1";
}

public class PhiEncryptionOptions
{
    public const string Section = "PhiEncryption";
    public string? Key { get; set; }             // base64 32-byte AES-256 key (Key Vault)
}

public class AzureKeyVaultOptions
{
    public const string Section = "Azure:KeyVault";
    public string? Uri { get; set; }
}
