namespace Bit2sky.Shared;

// Standard response envelope (Section 7).
public class ApiResponse<T>
{
    public bool Success { get; set; }
    public T? Data { get; set; }
    public string Message { get; set; } = "OK";
    public IEnumerable<ApiError>? Errors { get; set; }
    public string? CorrelationId { get; set; }
    public PaginationMeta? Pagination { get; set; }

    public static ApiResponse<T> Ok(T data, string message = "OK", PaginationMeta? pagination = null)
        => new() { Success = true, Data = data, Message = message, Pagination = pagination };

    public static ApiResponse<T> Fail(string message, IEnumerable<ApiError>? errors = null)
        => new() { Success = false, Message = message, Errors = errors };
}

public class ApiError
{
    public string Field { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
}

public class PaginationMeta
{
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int Total { get; set; }
    public int TotalPages => PageSize == 0 ? 0 : (int)Math.Ceiling(Total / (double)PageSize);
}
