using System.Security.Cryptography;
using System.Text;
using Bit2sky.Application.Abstractions;
using Bit2sky.Shared.Options;
using Microsoft.Extensions.Options;

namespace Bit2sky.Infrastructure.Security;

// AES-256-GCM field encryption for PHI at rest (Section 4F).
// Format: base64( nonce(12) | tag(16) | ciphertext ).
public class PhiEncryptionService : IPhiEncryptionService
{
    private const int NonceSize = 12;
    private const int TagSize = 16;
    private readonly byte[] _key;

    public PhiEncryptionService(IOptions<PhiEncryptionOptions> options)
    {
        var configured = options.Value.Key;
        _key = !string.IsNullOrWhiteSpace(configured)
            ? Convert.FromBase64String(configured)
            : RandomNumberGenerator.GetBytes(32); // ephemeral fallback (dev only)
        if (_key.Length != 32)
            throw new InvalidOperationException("PHI encryption key must be 32 bytes (AES-256).");
    }

    public string Encrypt(string plaintext)
    {
        if (string.IsNullOrEmpty(plaintext)) return plaintext;

        var plainBytes = Encoding.UTF8.GetBytes(plaintext);
        var nonce = RandomNumberGenerator.GetBytes(NonceSize);
        var cipher = new byte[plainBytes.Length];
        var tag = new byte[TagSize];

        using var aes = new AesGcm(_key, TagSize);
        aes.Encrypt(nonce, plainBytes, cipher, tag);

        var output = new byte[NonceSize + TagSize + cipher.Length];
        Buffer.BlockCopy(nonce, 0, output, 0, NonceSize);
        Buffer.BlockCopy(tag, 0, output, NonceSize, TagSize);
        Buffer.BlockCopy(cipher, 0, output, NonceSize + TagSize, cipher.Length);
        return Convert.ToBase64String(output);
    }

    public string Decrypt(string ciphertext)
    {
        if (string.IsNullOrEmpty(ciphertext)) return ciphertext;

        var input = Convert.FromBase64String(ciphertext);
        var nonce = input.AsSpan(0, NonceSize);
        var tag = input.AsSpan(NonceSize, TagSize);
        var cipher = input.AsSpan(NonceSize + TagSize);
        var plain = new byte[cipher.Length];

        using var aes = new AesGcm(_key, TagSize);
        aes.Decrypt(nonce, cipher, tag, plain);
        return Encoding.UTF8.GetString(plain);
    }
}
