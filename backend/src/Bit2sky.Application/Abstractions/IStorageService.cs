namespace Bit2sky.Application.Abstractions;

public interface IStorageService
{
    // Short-lived signed URL for a private blob (Section 7: 15-min expiry).
    Task<string> GetSignedUrlAsync(string container, string blobPath, TimeSpan expiry, CancellationToken ct = default);
    Task<string> UploadAsync(string container, string blobPath, Stream content, string contentType, CancellationToken ct = default);
}
