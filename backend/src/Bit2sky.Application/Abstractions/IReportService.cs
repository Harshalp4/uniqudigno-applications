using Bit2sky.Domain.Entities;

namespace Bit2sky.Application.Abstractions;

public interface IReportService
{
    Task<IReadOnlyList<LabReport>> ListAsync(Guid userId, CancellationToken ct = default);
    Task<LabReport> GetAsync(Guid userId, Guid reportId, CancellationToken ct = default);
    Task<IReadOnlyList<ReportParameter>> GetParametersAsync(Guid userId, Guid reportId, CancellationToken ct = default);
    Task<string> GetDownloadUrlAsync(Guid userId, Guid reportId, CancellationToken ct = default);
    Task RequestCounsellingAsync(Guid userId, Guid reportId, CancellationToken ct = default);
}
