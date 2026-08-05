using Bit2sky.Application.DTOs;

namespace Bit2sky.Application.Abstractions;

public interface IAuthService
{
    Task<SendOtpResult> SendOtpAsync(string mobile, string ip, CancellationToken ct = default);
    Task<TokenPair> VerifyOtpAsync(string sessionId, string otp, string deviceInfo, CancellationToken ct = default);
    Task<SendOtpResult> SendEmailOtpAsync(string email, string ip, CancellationToken ct = default);
    Task<TokenPair> VerifyEmailOtpAsync(string sessionId, string otp, string deviceInfo, CancellationToken ct = default);
    Task<TokenPair> LoginWithGoogleAsync(string idToken, string deviceInfo, CancellationToken ct = default);
    Task<TokenPair> TechnicianLoginAsync(string employeeId, string password, string ip, CancellationToken ct = default);
    Task<TokenPair> RefreshAsync(string refreshToken, string deviceInfo, CancellationToken ct = default);
    Task LogoutAsync(string refreshToken, CancellationToken ct = default);
    Task LogoutAllAsync(Guid userId, CancellationToken ct = default);
    Task<MePermissions> GetPermissionsAsync(Guid userId, CancellationToken ct = default);
}
