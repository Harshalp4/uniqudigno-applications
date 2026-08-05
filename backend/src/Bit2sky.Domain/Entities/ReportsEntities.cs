using Bit2sky.Domain.Enums;

namespace Bit2sky.Domain.Entities;

// reports.lab_reports (PHI — strict ownership; values encrypted at rest).
public class LabReport
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid? FamilyMemberId { get; set; }
    public Guid? BookingId { get; set; }
    public string Title { get; set; } = null!;
    public ReportStatus Status { get; set; } = ReportStatus.Pending;
    public string? PdfBlobPath { get; set; }             // private container path
    public string? DietEnhancedPdfBlobPath { get; set; }
    public string? LabName { get; set; }
    public DateOnly? ReportDate { get; set; }
    public CounsellingStatus CounsellingStatus { get; set; } = CounsellingStatus.NotRequired;
    public bool HardCopyRequested { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }

    public User User { get; set; } = null!;
    public ICollection<ReportParameter> Parameters { get; set; } = new List<ReportParameter>();
}

// reports.report_parameters (PHI).
public class ReportParameter
{
    public Guid Id { get; set; }
    public Guid LabReportId { get; set; }
    public string ParameterName { get; set; } = null!;
    public string? Value { get; set; }                   // encrypted at rest
    public string? Unit { get; set; }
    public string? ReferenceRange { get; set; }
    public ParameterStatus Status { get; set; } = ParameterStatus.Normal;
    public int SortOrder { get; set; }

    public LabReport LabReport { get; set; } = null!;
}

// reports.diet_plans — AI/curated diet plan tied to a report.
public class DietPlan
{
    public Guid Id { get; set; }
    public Guid LabReportId { get; set; }
    public string? Summary { get; set; }
    public string? PlanJson { get; set; }                // structured plan (JSONB)
    public string? GeneratedBy { get; set; }             // ai|nutritionist
    public DateTimeOffset CreatedAt { get; set; }
}

// reports.consultations — free counselling / doctor consults.
public class Consultation
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid? LabReportId { get; set; }
    public Guid? DoctorId { get; set; }
    public DateTimeOffset? ScheduledAt { get; set; }
    public string Status { get; set; } = "requested";    // requested|scheduled|completed|cancelled
    public string? Notes { get; set; }
    public string? MeetingLink { get; set; }
    public DateTimeOffset CreatedAt { get; set; }

    public User User { get; set; } = null!;
}
