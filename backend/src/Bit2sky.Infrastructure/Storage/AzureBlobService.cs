using Azure.Storage.Blobs;
using Azure.Storage.Sas;
using Bit2sky.Application.Abstractions;
using Microsoft.Extensions.Configuration;

namespace Bit2sky.Infrastructure.Storage;

// Private containers + short-lived signed URLs (Section 2 / Section 7). Connection
// string sourced from Key Vault; never public URLs.
public class AzureBlobService : IStorageService
{
    private readonly BlobServiceClient? _client;

    public AzureBlobService(IConfiguration config)
    {
        var conn = config.GetConnectionString("AzureBlob");
        if (!string.IsNullOrWhiteSpace(conn))
            _client = new BlobServiceClient(conn);
    }

    public Task<string> GetSignedUrlAsync(string container, string blobPath, TimeSpan expiry, CancellationToken ct = default)
    {
        if (_client is null) return Task.FromResult($"https://blob.invalid/{container}/{blobPath}");

        var blob = _client.GetBlobContainerClient(container).GetBlobClient(blobPath);
        if (!blob.CanGenerateSasUri)
            return Task.FromResult(blob.Uri.ToString());

        var sas = new BlobSasBuilder
        {
            BlobContainerName = container,
            BlobName = blobPath,
            Resource = "b",
            ExpiresOn = DateTimeOffset.UtcNow.Add(expiry),
        };
        sas.SetPermissions(BlobSasPermissions.Read);
        return Task.FromResult(blob.GenerateSasUri(sas).ToString());
    }

    public async Task<string> UploadAsync(string container, string blobPath, Stream content, string contentType, CancellationToken ct = default)
    {
        if (_client is null) return blobPath;
        var c = _client.GetBlobContainerClient(container);
        await c.CreateIfNotExistsAsync(cancellationToken: ct);
        var blob = c.GetBlobClient(blobPath);
        await blob.UploadAsync(content, overwrite: true, cancellationToken: ct);
        return blobPath;
    }
}
