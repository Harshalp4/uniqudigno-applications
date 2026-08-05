using Bit2sky.Application.DTOs;

namespace Bit2sky.Application.Abstractions;

public interface IAdminAuthService
{
    Task<AdminLoginResult> LoginAsync(string email, string password, CancellationToken ct = default);
    Task<Enroll2faResult> EnrollAsync(string sessionId, CancellationToken ct = default);
    Task<TokenPair> VerifyAsync(string sessionId, string code, CancellationToken ct = default);
}
