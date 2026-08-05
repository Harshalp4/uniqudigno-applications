using Azure.Identity;
using Azure.Security.KeyVault.Secrets;
using Bit2sky.Application.Abstractions;
using Bit2sky.Shared.Options;
using Microsoft.Extensions.Options;

namespace Bit2sky.Infrastructure.Security;

// Azure Key Vault access via Managed Identity (Section 4C). No credentials stored.
public class KeyVaultService : IKeyVaultService
{
    private readonly SecretClient? _client;

    public KeyVaultService(IOptions<AzureKeyVaultOptions> options)
    {
        var uri = options.Value.Uri;
        if (!string.IsNullOrWhiteSpace(uri))
            _client = new SecretClient(new Uri(uri), new DefaultAzureCredential());
    }

    public async Task<string?> GetSecretAsync(string name, CancellationToken ct = default)
    {
        if (_client is null) return null;
        var response = await _client.GetSecretAsync(name, cancellationToken: ct);
        return response.Value.Value;
    }
}
