using Bit2sky.Application.Abstractions;
using Bit2sky.Domain.Entities;
using Bit2sky.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace Bit2sky.Application.Services;

// Reports — PHI with strict ownership (Section 7 / 4F). Download returns a 15-min
// signed URL; the access is audited by AuditLoggingMiddleware.
public class ReportService : IReportService
{
    private const string ReportsContainer = "vitalscan-reports";
    private static readonly TimeSpan SignedUrlExpiry = TimeSpan.FromMinutes(15);

    private readonly IAppDbContext _db;
    private readonly IOwnershipService _ownership;
    private readonly IStorageService _storage;

    public ReportService(IAppDbContext db, IOwnershipService ownership, IStorageService storage)
    {
        _db = db;
        _ownership = ownership;
        _storage = storage;
    }

    public async Task<IReadOnlyList<LabReport>> ListAsync(Guid userId, CancellationToken ct = default)
    {
        var familyIds = await _db.Set<FamilyMember>().Where(f => f.UserId == userId).Select(f => f.Id).ToListAsync(ct);
        return await _db.Set<LabReport>().AsNoTracking()
            .Where(r => r.UserId == userId || (r.FamilyMemberId != null && familyIds.Contains(r.FamilyMemberId.Value)))
            .OrderByDescending(r => r.CreatedAt)
            .ToListAsync(ct);
    }

    public async Task<LabReport> GetAsync(Guid userId, Guid reportId, CancellationToken ct = default)
    {
        if (!await _ownership.CanAccessReportAsync(userId, reportId, ct))
            throw new Bit2sky.Shared.NotFoundAppException();
        return await _db.Set<LabReport>().Include(r => r.Parameters).FirstAsync(r => r.Id == reportId, ct);
    }

    public async Task<IReadOnlyList<ReportParameter>> GetParametersAsync(Guid userId, Guid reportId, CancellationToken ct = default)
    {
        if (!await _ownership.CanAccessReportAsync(userId, reportId, ct))
            throw new Bit2sky.Shared.NotFoundAppException();
        return await _db.Set<ReportParameter>().AsNoTracking()
            .Where(p => p.LabReportId == reportId).OrderBy(p => p.SortOrder).ToListAsync(ct);
    }

    public async Task<string> GetDownloadUrlAsync(Guid userId, Guid reportId, CancellationToken ct = default)
    {
        if (!await _ownership.CanAccessReportAsync(userId, reportId, ct))
            throw new Bit2sky.Shared.NotFoundAppException();
        var report = await _db.Set<LabReport>().FirstAsync(r => r.Id == reportId, ct);
        if (string.IsNullOrWhiteSpace(report.PdfBlobPath))
            throw new Bit2sky.Shared.NotFoundAppException();
        return await _storage.GetSignedUrlAsync(ReportsContainer, report.PdfBlobPath, SignedUrlExpiry, ct);
    }

    public async Task RequestCounsellingAsync(Guid userId, Guid reportId, CancellationToken ct = default)
    {
        if (!await _ownership.CanAccessReportAsync(userId, reportId, ct))
            throw new Bit2sky.Shared.NotFoundAppException();
        var report = await _db.Set<LabReport>().FirstAsync(r => r.Id == reportId, ct);
        report.CounsellingStatus = CounsellingStatus.Requested;
        _db.Set<Consultation>().Add(new Consultation
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            LabReportId = reportId,
            Status = "requested",
        });
        await _db.SaveChangesAsync(ct);
    }
}
