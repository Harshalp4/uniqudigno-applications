using Bit2sky.Application.Abstractions;
using Bit2sky.Shared;
using Microsoft.AspNetCore.Mvc;

namespace Bit2sky.API.Controllers;

[ApiController]
[Route("api/v1")]
[Produces("application/json")]
public abstract class ApiControllerBase : ControllerBase
{
    protected ICurrentUser CurrentUser => HttpContext.RequestServices.GetRequiredService<ICurrentUser>();

    protected Guid RequireUserId() =>
        CurrentUser.UserId ?? throw new UnauthorizedAppException();

    protected string ClientIp => HttpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";

    protected IActionResult Ok<T>(T data, string message = "OK", PaginationMeta? pagination = null)
    {
        var body = ApiResponse<T>.Ok(data, message, pagination);
        body.CorrelationId = HttpContext.Items[Middleware.CorrelationIdMiddleware.HeaderName]?.ToString();
        return base.Ok(body);
    }
}
