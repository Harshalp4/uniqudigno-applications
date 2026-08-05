namespace Bit2sky.Shared;

// Domain exceptions mapped to consistent HTTP responses by the exception middleware.
// Section 4B: 403 and 404 return the SAME body shape to prevent resource enumeration.
public abstract class AppException : Exception
{
    public int StatusCode { get; }
    public IEnumerable<ApiError>? Errors { get; }

    protected AppException(string message, int statusCode, IEnumerable<ApiError>? errors = null)
        : base(message)
    {
        StatusCode = statusCode;
        Errors = errors;
    }
}

public class ValidationAppException : AppException
{
    public ValidationAppException(IEnumerable<ApiError> errors)
        : base("Validation failed", 400, errors) { }
}

public class UnauthorizedAppException : AppException
{
    public UnauthorizedAppException() : base("Authentication required", 401) { }
}

// Both forbidden and not-found surface as "Resource not found" with 404 semantics where
// enumeration is a risk; ForbiddenAppException is used for explicit access denials.
public class ForbiddenAppException : AppException
{
    public ForbiddenAppException(string message = "Access denied") : base(message, 403) { }
}

public class NotFoundAppException : AppException
{
    public NotFoundAppException(string message = "Resource not found") : base(message, 404) { }
}

public class RateLimitAppException : AppException
{
    public int RetryAfterSeconds { get; }
    public RateLimitAppException(int retryAfterSeconds)
        : base($"Too many requests. Retry after {retryAfterSeconds}s.", 429)
        => RetryAfterSeconds = retryAfterSeconds;
}

public class ConflictAppException : AppException
{
    public ConflictAppException(string message) : base(message, 409) { }
}
