using Bit2sky.Application.Abstractions;
using Bit2sky.Application.DTOs;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Bit2sky.API.Controllers;

[Route("api/v1/auth")]
public class AuthController : ApiControllerBase
{
    private readonly IAuthService _auth;
    private readonly IAdminAuthService _adminAuth;

    public AuthController(IAuthService auth, IAdminAuthService adminAuth)
    {
        _auth = auth;
        _adminAuth = adminAuth;
    }

    [HttpPost("otp/send")]
    [AllowAnonymous]
    public async Task<IActionResult> SendOtp([FromBody] SendOtpRequest req, CancellationToken ct)
        => Ok(await _auth.SendOtpAsync(req.Mobile, ClientIp, ct), "OTP sent");

    [HttpPost("email/otp/send")]
    [AllowAnonymous]
    public async Task<IActionResult> SendEmailOtp([FromBody] SendEmailOtpRequest req, CancellationToken ct)
        => Ok(await _auth.SendEmailOtpAsync(req.Email, ClientIp, ct), "OTP sent");

    [HttpPost("email/otp/verify")]
    [AllowAnonymous]
    public async Task<IActionResult> VerifyEmailOtp([FromBody] VerifyOtpRequest req, CancellationToken ct)
        => Ok(await _auth.VerifyEmailOtpAsync(req.SessionId, req.Otp, req.DeviceInfo, ct), "Authenticated");

    [HttpPost("google")]
    [AllowAnonymous]
    public async Task<IActionResult> Google([FromBody] GoogleLoginRequest req, CancellationToken ct)
        => Ok(await _auth.LoginWithGoogleAsync(req.IdToken, req.DeviceInfo, ct), "Authenticated");

    [HttpPost("otp/verify")]
    [AllowAnonymous]
    public async Task<IActionResult> VerifyOtp([FromBody] VerifyOtpRequest req, CancellationToken ct)
        => Ok(await _auth.VerifyOtpAsync(req.SessionId, req.Otp, req.DeviceInfo, ct), "Authenticated");

    [HttpPost("token/refresh")]
    [AllowAnonymous]
    public async Task<IActionResult> Refresh([FromBody] RefreshRequest req, CancellationToken ct)
        => Ok(await _auth.RefreshAsync(req.RefreshToken, req.DeviceInfo, ct), "Refreshed");

    [HttpPost("logout")]
    [Authorize]
    public async Task<IActionResult> Logout([FromBody] RefreshRequest req, CancellationToken ct)
    {
        await _auth.LogoutAsync(req.RefreshToken, ct);
        return Ok<object?>(null, "Logged out");
    }

    [HttpPost("logout-all")]
    [Authorize]
    public async Task<IActionResult> LogoutAll(CancellationToken ct)
    {
        await _auth.LogoutAllAsync(RequireUserId(), ct);
        return Ok<object?>(null, "All sessions revoked");
    }

    [HttpGet("me/permissions")]
    [Authorize]
    public async Task<IActionResult> MyPermissions(CancellationToken ct)
        => Ok(await _auth.GetPermissionsAsync(RequireUserId(), ct));

    // ── Admin portal: email + password → mandatory TOTP (Section 4A) ──────────
    [HttpPost("admin/login")]
    [AllowAnonymous]
    public async Task<IActionResult> AdminLogin([FromBody] AdminLoginRequest req, CancellationToken ct)
        => Ok(await _adminAuth.LoginAsync(req.Email, req.Password, ct),
            "Password accepted — complete two-factor authentication");

    [HttpPost("admin/2fa/enroll")]
    [AllowAnonymous]
    public async Task<IActionResult> AdminEnroll2fa([FromBody] Enroll2faRequest req, CancellationToken ct)
        => Ok(await _adminAuth.EnrollAsync(req.SessionId, ct), "Scan the QR and verify a code to finish");

    [HttpPost("admin/2fa/verify")]
    [AllowAnonymous]
    public async Task<IActionResult> AdminVerify2fa([FromBody] Admin2faVerifyRequest req, CancellationToken ct)
        => Ok(await _adminAuth.VerifyAsync(req.SessionId, req.Code, ct), "Authenticated");

    // ── Technician app: employee ID + password ───────────────────────────────
    [HttpPost("technician/login")]
    [AllowAnonymous]
    public async Task<IActionResult> TechnicianLogin([FromBody] TechnicianLoginRequest req, CancellationToken ct)
        => Ok(await _auth.TechnicianLoginAsync(req.EmployeeId, req.Password, ClientIp, ct), "Authenticated");
}
