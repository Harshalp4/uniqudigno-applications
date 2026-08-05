using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Bit2sky.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class FullSchema : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.EnsureSchema(
                name: "comms");

            migrationBuilder.EnsureSchema(
                name: "content");

            migrationBuilder.EnsureSchema(
                name: "booking");

            migrationBuilder.EnsureSchema(
                name: "commerce");

            migrationBuilder.EnsureSchema(
                name: "catalogue");

            migrationBuilder.EnsureSchema(
                name: "reports");

            migrationBuilder.EnsureSchema(
                name: "health");

            migrationBuilder.AddColumn<string>(
                name: "AvatarUrl",
                schema: "core",
                table: "users",
                type: "character varying(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "CreatedAt",
                schema: "core",
                table: "users",
                type: "timestamp with time zone",
                nullable: false,
                defaultValueSql: "now()");

            migrationBuilder.AddColumn<DateOnly>(
                name: "DateOfBirth",
                schema: "core",
                table: "users",
                type: "date",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Email",
                schema: "core",
                table: "users",
                type: "character varying(255)",
                maxLength: 255,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Gender",
                schema: "core",
                table: "users",
                type: "character varying(40)",
                maxLength: 40,
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsActive",
                schema: "core",
                table: "users",
                type: "boolean",
                nullable: false,
                defaultValue: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsAdminPortalUser",
                schema: "core",
                table: "users",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "IsDeleted",
                schema: "core",
                table: "users",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "LastLoginAt",
                schema: "core",
                table: "users",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "MembershipTierId",
                schema: "core",
                table: "users",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Mobile",
                schema: "core",
                table: "users",
                type: "character varying(20)",
                maxLength: 20,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "Name",
                schema: "core",
                table: "users",
                type: "character varying(150)",
                maxLength: 150,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ReferralCode",
                schema: "core",
                table: "users",
                type: "character varying(20)",
                maxLength: 20,
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "ReferredByUserId",
                schema: "core",
                table: "users",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "UpdatedAt",
                schema: "core",
                table: "users",
                type: "timestamp with time zone",
                nullable: false,
                defaultValueSql: "now()");

            migrationBuilder.AddColumn<string>(
                name: "DeviceId",
                schema: "core",
                table: "refresh_tokens",
                type: "character varying(128)",
                maxLength: 128,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "ExpiresAt",
                schema: "core",
                table: "refresh_tokens",
                type: "timestamp with time zone",
                nullable: false,
                defaultValue: new DateTimeOffset(new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)));

            migrationBuilder.AddColumn<string>(
                name: "ReplacedByTokenHash",
                schema: "core",
                table: "refresh_tokens",
                type: "character varying(128)",
                maxLength: 128,
                nullable: true);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "RevokedAt",
                schema: "core",
                table: "refresh_tokens",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "TokenHash",
                schema: "core",
                table: "refresh_tokens",
                type: "character varying(128)",
                maxLength: 128,
                nullable: false,
                defaultValue: "");

            migrationBuilder.CreateTable(
                name: "addresses",
                schema: "core",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Type = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    Line1 = table.Column<string>(type: "text", nullable: false),
                    Line2 = table.Column<string>(type: "text", nullable: true),
                    Landmark = table.Column<string>(type: "text", nullable: true),
                    City = table.Column<string>(type: "text", nullable: false),
                    State = table.Column<string>(type: "text", nullable: false),
                    Pincode = table.Column<string>(type: "text", nullable: false),
                    Latitude = table.Column<double>(type: "double precision", nullable: true),
                    Longitude = table.Column<double>(type: "double precision", nullable: true),
                    IsDefault = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_addresses", x => x.Id);
                    table.ForeignKey(
                        name: "FK_addresses_users_UserId",
                        column: x => x.UserId,
                        principalSchema: "core",
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ai_prompts",
                schema: "content",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "text", nullable: false),
                    Version = table.Column<int>(type: "integer", nullable: false),
                    SystemPrompt = table.Column<string>(type: "text", nullable: false),
                    Model = table.Column<string>(type: "text", nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedByAdminId = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ai_prompts", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "ai_sessions",
                schema: "comms",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Title = table.Column<string>(type: "text", nullable: true),
                    Status = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    PromptVersionId = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()"),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ai_sessions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ai_sessions_users_UserId",
                        column: x => x.UserId,
                        principalSchema: "core",
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "app_config",
                schema: "core",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Key = table.Column<string>(type: "text", nullable: false),
                    Value = table.Column<string>(type: "text", nullable: true),
                    ValueType = table.Column<string>(type: "text", nullable: false),
                    Category = table.Column<string>(type: "text", nullable: true),
                    Description = table.Column<string>(type: "text", nullable: true),
                    IsPublic = table.Column<bool>(type: "boolean", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_app_config", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "articles",
                schema: "content",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Title = table.Column<string>(type: "text", nullable: false),
                    Slug = table.Column<string>(type: "text", nullable: false),
                    Excerpt = table.Column<string>(type: "text", nullable: true),
                    Body = table.Column<string>(type: "text", nullable: false),
                    CoverImageUrl = table.Column<string>(type: "text", nullable: true),
                    Category = table.Column<string>(type: "text", nullable: true),
                    IsFeatured = table.Column<bool>(type: "boolean", nullable: false),
                    IsPublished = table.Column<bool>(type: "boolean", nullable: false),
                    ViewCount = table.Column<int>(type: "integer", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()"),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_articles", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "audit_logs",
                schema: "core",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: true),
                    UserRole = table.Column<string>(type: "text", nullable: true),
                    Action = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    EntityType = table.Column<string>(type: "text", nullable: false),
                    EntityId = table.Column<string>(type: "text", nullable: true),
                    OldValues = table.Column<string>(type: "jsonb", nullable: true),
                    NewValues = table.Column<string>(type: "jsonb", nullable: true),
                    IpAddress = table.Column<string>(type: "text", nullable: true),
                    UserAgent = table.Column<string>(type: "text", nullable: true),
                    CorrelationId = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_audit_logs", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "banners",
                schema: "content",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Title = table.Column<string>(type: "text", nullable: false),
                    ImageUrl = table.Column<string>(type: "text", nullable: false),
                    DeepLink = table.Column<string>(type: "text", nullable: true),
                    SortOrder = table.Column<int>(type: "integer", nullable: false),
                    ValidFrom = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    ValidUntil = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_banners", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "bookings",
                schema: "booking",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    BookingNumber = table.Column<string>(type: "text", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    FamilyMemberId = table.Column<Guid>(type: "uuid", nullable: true),
                    PartnerId = table.Column<Guid>(type: "uuid", nullable: true),
                    TechnicianId = table.Column<Guid>(type: "uuid", nullable: true),
                    AddressId = table.Column<Guid>(type: "uuid", nullable: true),
                    SlotId = table.Column<Guid>(type: "uuid", nullable: true),
                    CentreId = table.Column<Guid>(type: "uuid", nullable: true),
                    CollectionType = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    ScheduledDate = table.Column<DateOnly>(type: "date", nullable: false),
                    ScheduledTime = table.Column<TimeOnly>(type: "time without time zone", nullable: true),
                    Status = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    ItemsTotal = table.Column<decimal>(type: "numeric", nullable: false),
                    DiscountTotal = table.Column<decimal>(type: "numeric", nullable: false),
                    WalletApplied = table.Column<decimal>(type: "numeric", nullable: false),
                    AmountPayable = table.Column<decimal>(type: "numeric", nullable: false),
                    CouponId = table.Column<Guid>(type: "uuid", nullable: true),
                    RescheduleCount = table.Column<int>(type: "integer", nullable: false),
                    CancellationReason = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()"),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_bookings", x => x.Id);
                    table.ForeignKey(
                        name: "FK_bookings_users_UserId",
                        column: x => x.UserId,
                        principalSchema: "core",
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "carts",
                schema: "commerce",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    CouponId = table.Column<Guid>(type: "uuid", nullable: true),
                    WalletPointsApplied = table.Column<decimal>(type: "numeric", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_carts", x => x.Id);
                    table.ForeignKey(
                        name: "FK_carts_users_UserId",
                        column: x => x.UserId,
                        principalSchema: "core",
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "cashback_offers",
                schema: "commerce",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Title = table.Column<string>(type: "text", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: true),
                    RewardType = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    RewardValue = table.Column<decimal>(type: "numeric", nullable: false),
                    MaxCashback = table.Column<decimal>(type: "numeric", nullable: true),
                    MinOrderValue = table.Column<decimal>(type: "numeric", nullable: true),
                    ValidFrom = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    ValidUntil = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_cashback_offers", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "cashbacks",
                schema: "commerce",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    OfferId = table.Column<Guid>(type: "uuid", nullable: true),
                    BookingId = table.Column<Guid>(type: "uuid", nullable: true),
                    Amount = table.Column<decimal>(type: "numeric", nullable: false),
                    Status = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    CreditAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_cashbacks", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "categories",
                schema: "catalogue",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "text", nullable: false),
                    Slug = table.Column<string>(type: "text", nullable: false),
                    Type = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    IconUrl = table.Column<string>(type: "text", nullable: true),
                    Tag = table.Column<string>(type: "text", nullable: true),
                    ShowInFilter = table.Column<bool>(type: "boolean", nullable: false),
                    SortOrder = table.Column<int>(type: "integer", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_categories", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "centre_pricing",
                schema: "catalogue",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CentreId = table.Column<Guid>(type: "uuid", nullable: false),
                    TestId = table.Column<Guid>(type: "uuid", nullable: true),
                    PackageId = table.Column<Guid>(type: "uuid", nullable: true),
                    Price = table.Column<decimal>(type: "numeric", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_centre_pricing", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "centres",
                schema: "catalogue",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "text", nullable: false),
                    AddressLine = table.Column<string>(type: "text", nullable: true),
                    City = table.Column<string>(type: "text", nullable: false),
                    State = table.Column<string>(type: "text", nullable: false),
                    Pincode = table.Column<string>(type: "text", nullable: false),
                    Latitude = table.Column<double>(type: "double precision", nullable: true),
                    Longitude = table.Column<double>(type: "double precision", nullable: true),
                    Phone = table.Column<string>(type: "text", nullable: true),
                    OpenHours = table.Column<string>(type: "text", nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_centres", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "consultations",
                schema: "reports",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    LabReportId = table.Column<Guid>(type: "uuid", nullable: true),
                    DoctorId = table.Column<Guid>(type: "uuid", nullable: true),
                    ScheduledAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    Status = table.Column<string>(type: "text", nullable: false),
                    Notes = table.Column<string>(type: "text", nullable: true),
                    MeetingLink = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_consultations", x => x.Id);
                    table.ForeignKey(
                        name: "FK_consultations_users_UserId",
                        column: x => x.UserId,
                        principalSchema: "core",
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "coupons",
                schema: "commerce",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Code = table.Column<string>(type: "text", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: true),
                    Type = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    Value = table.Column<decimal>(type: "numeric", nullable: false),
                    MaxDiscount = table.Column<decimal>(type: "numeric", nullable: true),
                    MinOrderValue = table.Column<decimal>(type: "numeric", nullable: true),
                    TotalUsageLimit = table.Column<int>(type: "integer", nullable: true),
                    PerUserLimit = table.Column<int>(type: "integer", nullable: false),
                    UsedCount = table.Column<int>(type: "integer", nullable: false),
                    ValidFrom = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    ValidUntil = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_coupons", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "custom_packages",
                schema: "booking",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "text", nullable: false),
                    Mrp = table.Column<decimal>(type: "numeric", nullable: false),
                    Price = table.Column<decimal>(type: "numeric", nullable: false),
                    DiscountPercent = table.Column<decimal>(type: "numeric", nullable: false),
                    TestIds = table.Column<string>(type: "text", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_custom_packages", x => x.Id);
                    table.ForeignKey(
                        name: "FK_custom_packages_users_UserId",
                        column: x => x.UserId,
                        principalSchema: "core",
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "devices",
                schema: "core",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    FcmToken = table.Column<string>(type: "text", nullable: false),
                    Platform = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    DeviceModel = table.Column<string>(type: "text", nullable: true),
                    AppVersion = table.Column<string>(type: "text", nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()"),
                    LastSeenAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_devices", x => x.Id);
                    table.ForeignKey(
                        name: "FK_devices_users_UserId",
                        column: x => x.UserId,
                        principalSchema: "core",
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "diet_plans",
                schema: "reports",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    LabReportId = table.Column<Guid>(type: "uuid", nullable: false),
                    Summary = table.Column<string>(type: "text", nullable: true),
                    PlanJson = table.Column<string>(type: "text", nullable: true),
                    GeneratedBy = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_diet_plans", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "doctor_slots",
                schema: "catalogue",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    DoctorId = table.Column<Guid>(type: "uuid", nullable: false),
                    Date = table.Column<DateOnly>(type: "date", nullable: false),
                    StartTime = table.Column<TimeOnly>(type: "time without time zone", nullable: false),
                    EndTime = table.Column<TimeOnly>(type: "time without time zone", nullable: false),
                    Capacity = table.Column<int>(type: "integer", nullable: false),
                    Booked = table.Column<int>(type: "integer", nullable: false),
                    IsAvailable = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_doctor_slots", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "family_members",
                schema: "core",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "text", nullable: false),
                    Relationship = table.Column<string>(type: "text", nullable: false),
                    DateOfBirth = table.Column<DateOnly>(type: "date", nullable: true),
                    Gender = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: true),
                    BloodGroup = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    Mobile = table.Column<string>(type: "text", nullable: true),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_family_members", x => x.Id);
                    table.ForeignKey(
                        name: "FK_family_members_users_UserId",
                        column: x => x.UserId,
                        principalSchema: "core",
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "group_bookings",
                schema: "booking",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Code = table.Column<string>(type: "text", nullable: false),
                    CreatedByUserId = table.Column<Guid>(type: "uuid", nullable: false),
                    PackageId = table.Column<Guid>(type: "uuid", nullable: true),
                    TestId = table.Column<Guid>(type: "uuid", nullable: true),
                    MinMembers = table.Column<int>(type: "integer", nullable: false),
                    MaxMembers = table.Column<int>(type: "integer", nullable: false),
                    DiscountPercent = table.Column<decimal>(type: "numeric", nullable: false),
                    Status = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    ExpiresAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_group_bookings", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "health_scores",
                schema: "health",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Score = table.Column<int>(type: "integer", nullable: false),
                    Grade = table.Column<string>(type: "text", nullable: true),
                    BreakdownJson = table.Column<string>(type: "text", nullable: true),
                    CalculatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_health_scores", x => x.Id);
                    table.ForeignKey(
                        name: "FK_health_scores_users_UserId",
                        column: x => x.UserId,
                        principalSchema: "core",
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "home_sections",
                schema: "content",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Title = table.Column<string>(type: "text", nullable: false),
                    SectionType = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    ConfigJson = table.Column<string>(type: "text", nullable: true),
                    SortOrder = table.Column<int>(type: "integer", nullable: false),
                    IsVisible = table.Column<bool>(type: "boolean", nullable: false),
                    ValidFrom = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    ValidUntil = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_home_sections", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "lab_reports",
                schema: "reports",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    FamilyMemberId = table.Column<Guid>(type: "uuid", nullable: true),
                    BookingId = table.Column<Guid>(type: "uuid", nullable: true),
                    Title = table.Column<string>(type: "text", nullable: false),
                    Status = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    PdfBlobPath = table.Column<string>(type: "text", nullable: true),
                    DietEnhancedPdfBlobPath = table.Column<string>(type: "text", nullable: true),
                    LabName = table.Column<string>(type: "text", nullable: true),
                    ReportDate = table.Column<DateOnly>(type: "date", nullable: true),
                    CounsellingStatus = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    HardCopyRequested = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()"),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_lab_reports", x => x.Id);
                    table.ForeignKey(
                        name: "FK_lab_reports_users_UserId",
                        column: x => x.UserId,
                        principalSchema: "core",
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "lifestyle_logs",
                schema: "health",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    LogDate = table.Column<DateOnly>(type: "date", nullable: false),
                    Category = table.Column<string>(type: "text", nullable: false),
                    Value = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_lifestyle_logs", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "membership_tiers",
                schema: "commerce",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "text", nullable: false),
                    SortOrder = table.Column<int>(type: "integer", nullable: false),
                    MinSpend = table.Column<decimal>(type: "numeric", nullable: false),
                    CashbackMultiplier = table.Column<decimal>(type: "numeric", nullable: false),
                    DiscountPercent = table.Column<decimal>(type: "numeric", nullable: false),
                    BenefitsJson = table.Column<string>(type: "text", nullable: true),
                    BadgeColor = table.Column<string>(type: "text", nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_membership_tiers", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "nav_items",
                schema: "content",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Label = table.Column<string>(type: "text", nullable: false),
                    IconUrl = table.Column<string>(type: "text", nullable: false),
                    Route = table.Column<string>(type: "text", nullable: false),
                    SortOrder = table.Column<int>(type: "integer", nullable: false),
                    IsVisible = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_nav_items", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "notifications",
                schema: "comms",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Title = table.Column<string>(type: "text", nullable: false),
                    Body = table.Column<string>(type: "text", nullable: false),
                    Channel = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    Status = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    DeepLink = table.Column<string>(type: "text", nullable: true),
                    DataJson = table.Column<string>(type: "text", nullable: true),
                    IsRead = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()"),
                    ReadAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_notifications", x => x.Id);
                    table.ForeignKey(
                        name: "FK_notifications_users_UserId",
                        column: x => x.UserId,
                        principalSchema: "core",
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "onboarding_slides",
                schema: "content",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Title = table.Column<string>(type: "text", nullable: false),
                    Subtitle = table.Column<string>(type: "text", nullable: true),
                    ImageUrl = table.Column<string>(type: "text", nullable: false),
                    SortOrder = table.Column<int>(type: "integer", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_onboarding_slides", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "otp_requests",
                schema: "core",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Mobile = table.Column<string>(type: "text", nullable: false),
                    OtpHash = table.Column<string>(type: "text", nullable: false),
                    SessionId = table.Column<string>(type: "text", nullable: false),
                    AttemptCount = table.Column<int>(type: "integer", nullable: false),
                    ExpiresAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    IsVerified = table.Column<bool>(type: "boolean", nullable: false),
                    IpAddress = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_otp_requests", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "packages",
                schema: "catalogue",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "text", nullable: false),
                    Slug = table.Column<string>(type: "text", nullable: false),
                    ShortDescription = table.Column<string>(type: "text", nullable: true),
                    Description = table.Column<string>(type: "text", nullable: true),
                    CategoryId = table.Column<Guid>(type: "uuid", nullable: true),
                    Mrp = table.Column<decimal>(type: "numeric", nullable: false),
                    Price = table.Column<decimal>(type: "numeric", nullable: false),
                    TestCount = table.Column<int>(type: "integer", nullable: false),
                    ParameterCount = table.Column<int>(type: "integer", nullable: false),
                    FastingRequired = table.Column<bool>(type: "boolean", nullable: false),
                    ReportTimeText = table.Column<string>(type: "text", nullable: true),
                    IsPopular = table.Column<bool>(type: "boolean", nullable: false),
                    IsFeatured = table.Column<bool>(type: "boolean", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_packages", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "partner_commissions",
                schema: "admin",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    PartnerId = table.Column<Guid>(type: "uuid", nullable: false),
                    BookingId = table.Column<Guid>(type: "uuid", nullable: false),
                    BookingAmount = table.Column<decimal>(type: "numeric", nullable: false),
                    CommissionAmount = table.Column<decimal>(type: "numeric", nullable: false),
                    Status = table.Column<string>(type: "text", nullable: false),
                    PayoutId = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_partner_commissions", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "partners",
                schema: "admin",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: true),
                    Name = table.Column<string>(type: "text", nullable: false),
                    Mobile = table.Column<string>(type: "text", nullable: false),
                    Email = table.Column<string>(type: "text", nullable: true),
                    Type = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    Status = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    CommissionPercent = table.Column<decimal>(type: "numeric", nullable: false),
                    BankAccountJson = table.Column<string>(type: "text", nullable: true),
                    GstNumber = table.Column<string>(type: "text", nullable: true),
                    VerifiedByAdminId = table.Column<Guid>(type: "uuid", nullable: true),
                    VerifiedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_partners", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "quick_actions",
                schema: "content",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Label = table.Column<string>(type: "text", nullable: false),
                    IconUrl = table.Column<string>(type: "text", nullable: false),
                    DeepLink = table.Column<string>(type: "text", nullable: false),
                    SortOrder = table.Column<int>(type: "integer", nullable: false),
                    IsVisible = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_quick_actions", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "referrals",
                schema: "commerce",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    ReferrerUserId = table.Column<Guid>(type: "uuid", nullable: false),
                    RefereeUserId = table.Column<Guid>(type: "uuid", nullable: true),
                    Code = table.Column<string>(type: "text", nullable: false),
                    Status = table.Column<string>(type: "text", nullable: false),
                    RewardAmount = table.Column<decimal>(type: "numeric", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_referrals", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "refunds",
                schema: "commerce",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    PaymentId = table.Column<Guid>(type: "uuid", nullable: false),
                    BookingId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Amount = table.Column<decimal>(type: "numeric", nullable: false),
                    Method = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    Status = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    Reason = table.Column<string>(type: "text", nullable: true),
                    RazorpayRefundId = table.Column<string>(type: "text", nullable: true),
                    ProcessedByAdminId = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()"),
                    ProcessedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_refunds", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "reminders",
                schema: "health",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Type = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    Title = table.Column<string>(type: "text", nullable: false),
                    Notes = table.Column<string>(type: "text", nullable: true),
                    RemindAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    IsRecurring = table.Column<bool>(type: "boolean", nullable: false),
                    RecurrenceRule = table.Column<string>(type: "text", nullable: true),
                    IsDismissed = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_reminders", x => x.Id);
                    table.ForeignKey(
                        name: "FK_reminders_users_UserId",
                        column: x => x.UserId,
                        principalSchema: "core",
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "slots",
                schema: "booking",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Date = table.Column<DateOnly>(type: "date", nullable: false),
                    StartTime = table.Column<TimeOnly>(type: "time without time zone", nullable: false),
                    EndTime = table.Column<TimeOnly>(type: "time without time zone", nullable: false),
                    Pincode = table.Column<string>(type: "text", nullable: true),
                    CentreId = table.Column<Guid>(type: "uuid", nullable: true),
                    Capacity = table.Column<int>(type: "integer", nullable: false),
                    Booked = table.Column<int>(type: "integer", nullable: false),
                    IsAvailable = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_slots", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "specialties",
                schema: "catalogue",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "text", nullable: false),
                    Slug = table.Column<string>(type: "text", nullable: false),
                    IconUrl = table.Column<string>(type: "text", nullable: true),
                    ShowInFilter = table.Column<bool>(type: "boolean", nullable: false),
                    SortOrder = table.Column<int>(type: "integer", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_specialties", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "steps",
                schema: "health",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Date = table.Column<DateOnly>(type: "date", nullable: false),
                    Steps = table.Column<int>(type: "integer", nullable: false),
                    Source = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_steps", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "subscriptions",
                schema: "booking",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    PackageId = table.Column<Guid>(type: "uuid", nullable: true),
                    TestId = table.Column<Guid>(type: "uuid", nullable: true),
                    Frequency = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    Status = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    StartDate = table.Column<DateOnly>(type: "date", nullable: false),
                    NextBookingDate = table.Column<DateOnly>(type: "date", nullable: true),
                    PausedUntil = table.Column<DateOnly>(type: "date", nullable: true),
                    PricePerCycle = table.Column<decimal>(type: "numeric", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_subscriptions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_subscriptions_users_UserId",
                        column: x => x.UserId,
                        principalSchema: "core",
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "supplements",
                schema: "catalogue",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "text", nullable: false),
                    Slug = table.Column<string>(type: "text", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: true),
                    ImageUrl = table.Column<string>(type: "text", nullable: true),
                    Mrp = table.Column<decimal>(type: "numeric", nullable: false),
                    Price = table.Column<decimal>(type: "numeric", nullable: false),
                    ForConcernTags = table.Column<string>(type: "text", nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_supplements", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "support_tickets",
                schema: "comms",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TicketNumber = table.Column<string>(type: "text", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Subject = table.Column<string>(type: "text", nullable: false),
                    Category = table.Column<string>(type: "text", nullable: false),
                    Status = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    Priority = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    AssignedToAdminId = table.Column<Guid>(type: "uuid", nullable: true),
                    RelatedBookingId = table.Column<Guid>(type: "uuid", nullable: true),
                    SlaDueAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()"),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_support_tickets", x => x.Id);
                    table.ForeignKey(
                        name: "FK_support_tickets_users_UserId",
                        column: x => x.UserId,
                        principalSchema: "core",
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "symptom_checks",
                schema: "health",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: true),
                    SymptomsJson = table.Column<string>(type: "text", nullable: false),
                    ResultJson = table.Column<string>(type: "text", nullable: true),
                    RecommendedTestsJson = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_symptom_checks", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "technicians",
                schema: "booking",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: true),
                    Name = table.Column<string>(type: "text", nullable: false),
                    Mobile = table.Column<string>(type: "text", nullable: false),
                    PhotoUrl = table.Column<string>(type: "text", nullable: true),
                    ServiceZones = table.Column<string>(type: "text", nullable: true),
                    Status = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    CurrentLatitude = table.Column<double>(type: "double precision", nullable: true),
                    CurrentLongitude = table.Column<double>(type: "double precision", nullable: true),
                    RatingAverage = table.Column<double>(type: "double precision", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_technicians", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "test_faqs",
                schema: "catalogue",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TestId = table.Column<Guid>(type: "uuid", nullable: false),
                    Question = table.Column<string>(type: "text", nullable: false),
                    Answer = table.Column<string>(type: "text", nullable: false),
                    SortOrder = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_test_faqs", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "test_reviews",
                schema: "catalogue",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TestId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: true),
                    AuthorName = table.Column<string>(type: "text", nullable: true),
                    Rating = table.Column<int>(type: "integer", nullable: false),
                    Comment = table.Column<string>(type: "text", nullable: true),
                    IsApproved = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_test_reviews", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "vitals",
                schema: "health",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Type = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    Value = table.Column<string>(type: "text", nullable: false),
                    Unit = table.Column<string>(type: "text", nullable: true),
                    Source = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    RecordedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_vitals", x => x.Id);
                    table.ForeignKey(
                        name: "FK_vitals_users_UserId",
                        column: x => x.UserId,
                        principalSchema: "core",
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "wallets",
                schema: "commerce",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Balance = table.Column<decimal>(type: "numeric", nullable: false),
                    LifetimeEarned = table.Column<decimal>(type: "numeric", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_wallets", x => x.Id);
                    table.ForeignKey(
                        name: "FK_wallets_users_UserId",
                        column: x => x.UserId,
                        principalSchema: "core",
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "whatsapp_templates",
                schema: "comms",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Key = table.Column<string>(type: "text", nullable: false),
                    TemplateName = table.Column<string>(type: "text", nullable: false),
                    LanguageCode = table.Column<string>(type: "text", nullable: false),
                    VariablesJson = table.Column<string>(type: "text", nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_whatsapp_templates", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "ai_chat_messages",
                schema: "comms",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    SessionId = table.Column<Guid>(type: "uuid", nullable: false),
                    Role = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    Content = table.Column<string>(type: "text", nullable: false),
                    TokensUsed = table.Column<int>(type: "integer", nullable: true),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ai_chat_messages", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ai_chat_messages_ai_sessions_SessionId",
                        column: x => x.SessionId,
                        principalSchema: "comms",
                        principalTable: "ai_sessions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "booking_items",
                schema: "booking",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    BookingId = table.Column<Guid>(type: "uuid", nullable: false),
                    TestId = table.Column<Guid>(type: "uuid", nullable: true),
                    PackageId = table.Column<Guid>(type: "uuid", nullable: true),
                    ItemName = table.Column<string>(type: "text", nullable: false),
                    Mrp = table.Column<decimal>(type: "numeric", nullable: false),
                    Price = table.Column<decimal>(type: "numeric", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_booking_items", x => x.Id);
                    table.ForeignKey(
                        name: "FK_booking_items_bookings_BookingId",
                        column: x => x.BookingId,
                        principalSchema: "booking",
                        principalTable: "bookings",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "payments",
                schema: "commerce",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    BookingId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    RazorpayOrderId = table.Column<string>(type: "text", nullable: true),
                    RazorpayPaymentId = table.Column<string>(type: "text", nullable: true),
                    RazorpaySignature = table.Column<string>(type: "text", nullable: true),
                    Amount = table.Column<decimal>(type: "numeric", nullable: false),
                    Currency = table.Column<string>(type: "text", nullable: false),
                    Method = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    Status = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()"),
                    PaidAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_payments", x => x.Id);
                    table.ForeignKey(
                        name: "FK_payments_bookings_BookingId",
                        column: x => x.BookingId,
                        principalSchema: "booking",
                        principalTable: "bookings",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "cart_items",
                schema: "commerce",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CartId = table.Column<Guid>(type: "uuid", nullable: false),
                    TestId = table.Column<Guid>(type: "uuid", nullable: true),
                    PackageId = table.Column<Guid>(type: "uuid", nullable: true),
                    CustomPackageId = table.Column<Guid>(type: "uuid", nullable: true),
                    FamilyMemberId = table.Column<Guid>(type: "uuid", nullable: true),
                    ItemName = table.Column<string>(type: "text", nullable: false),
                    Mrp = table.Column<decimal>(type: "numeric", nullable: false),
                    Price = table.Column<decimal>(type: "numeric", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_cart_items", x => x.Id);
                    table.ForeignKey(
                        name: "FK_cart_items_carts_CartId",
                        column: x => x.CartId,
                        principalSchema: "commerce",
                        principalTable: "carts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "tests",
                schema: "catalogue",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "text", nullable: false),
                    Slug = table.Column<string>(type: "text", nullable: false),
                    ShortDescription = table.Column<string>(type: "text", nullable: true),
                    Description = table.Column<string>(type: "text", nullable: true),
                    CategoryId = table.Column<Guid>(type: "uuid", nullable: true),
                    Mrp = table.Column<decimal>(type: "numeric", nullable: false),
                    Price = table.Column<decimal>(type: "numeric", nullable: false),
                    ParameterCount = table.Column<int>(type: "integer", nullable: false),
                    SampleType = table.Column<string>(type: "text", nullable: true),
                    FastingRequired = table.Column<bool>(type: "boolean", nullable: false),
                    ReportTimeText = table.Column<string>(type: "text", nullable: true),
                    HomeCollectionAvailable = table.Column<bool>(type: "boolean", nullable: false),
                    IsPopular = table.Column<bool>(type: "boolean", nullable: false),
                    ConcernTags = table.Column<string>(type: "text", nullable: true),
                    RiskTags = table.Column<string>(type: "text", nullable: true),
                    RatingAverage = table.Column<double>(type: "double precision", nullable: false),
                    RatingCount = table.Column<int>(type: "integer", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_tests", x => x.Id);
                    table.ForeignKey(
                        name: "FK_tests_categories_CategoryId",
                        column: x => x.CategoryId,
                        principalSchema: "catalogue",
                        principalTable: "categories",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "group_booking_members",
                schema: "booking",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    GroupBookingId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    BookingId = table.Column<Guid>(type: "uuid", nullable: true),
                    JoinedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_group_booking_members", x => x.Id);
                    table.ForeignKey(
                        name: "FK_group_booking_members_group_bookings_GroupBookingId",
                        column: x => x.GroupBookingId,
                        principalSchema: "booking",
                        principalTable: "group_bookings",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "report_parameters",
                schema: "reports",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    LabReportId = table.Column<Guid>(type: "uuid", nullable: false),
                    ParameterName = table.Column<string>(type: "text", nullable: false),
                    Value = table.Column<string>(type: "text", nullable: true),
                    Unit = table.Column<string>(type: "text", nullable: true),
                    ReferenceRange = table.Column<string>(type: "text", nullable: true),
                    Status = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    SortOrder = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_report_parameters", x => x.Id);
                    table.ForeignKey(
                        name: "FK_report_parameters_lab_reports_LabReportId",
                        column: x => x.LabReportId,
                        principalSchema: "reports",
                        principalTable: "lab_reports",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "doctors",
                schema: "catalogue",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "text", nullable: false),
                    Slug = table.Column<string>(type: "text", nullable: false),
                    SpecialtyId = table.Column<Guid>(type: "uuid", nullable: true),
                    Qualification = table.Column<string>(type: "text", nullable: true),
                    ExperienceYears = table.Column<int>(type: "integer", nullable: false),
                    PhotoUrl = table.Column<string>(type: "text", nullable: true),
                    About = table.Column<string>(type: "text", nullable: true),
                    ConsultationFee = table.Column<decimal>(type: "numeric", nullable: false),
                    Languages = table.Column<string>(type: "text", nullable: true),
                    RatingAverage = table.Column<double>(type: "double precision", nullable: false),
                    RatingCount = table.Column<int>(type: "integer", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_doctors", x => x.Id);
                    table.ForeignKey(
                        name: "FK_doctors_specialties_SpecialtyId",
                        column: x => x.SpecialtyId,
                        principalSchema: "catalogue",
                        principalTable: "specialties",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "support_messages",
                schema: "comms",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TicketId = table.Column<Guid>(type: "uuid", nullable: false),
                    SenderUserId = table.Column<Guid>(type: "uuid", nullable: true),
                    IsFromAgent = table.Column<bool>(type: "boolean", nullable: false),
                    Body = table.Column<string>(type: "text", nullable: false),
                    AttachmentUrl = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_support_messages", x => x.Id);
                    table.ForeignKey(
                        name: "FK_support_messages_support_tickets_TicketId",
                        column: x => x.TicketId,
                        principalSchema: "comms",
                        principalTable: "support_tickets",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "wallet_transactions",
                schema: "commerce",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    WalletId = table.Column<Guid>(type: "uuid", nullable: false),
                    Type = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    Reason = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    Amount = table.Column<decimal>(type: "numeric", nullable: false),
                    BalanceAfter = table.Column<decimal>(type: "numeric", nullable: false),
                    ReferenceId = table.Column<string>(type: "text", nullable: true),
                    Note = table.Column<string>(type: "text", nullable: true),
                    AdjustedByAdminId = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_wallet_transactions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_wallet_transactions_wallets_WalletId",
                        column: x => x.WalletId,
                        principalSchema: "commerce",
                        principalTable: "wallets",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "package_tests",
                schema: "catalogue",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    PackageId = table.Column<Guid>(type: "uuid", nullable: false),
                    TestId = table.Column<Guid>(type: "uuid", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_package_tests", x => x.Id);
                    table.ForeignKey(
                        name: "FK_package_tests_packages_PackageId",
                        column: x => x.PackageId,
                        principalSchema: "catalogue",
                        principalTable: "packages",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_package_tests_tests_TestId",
                        column: x => x.TestId,
                        principalSchema: "catalogue",
                        principalTable: "tests",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "test_parameters",
                schema: "catalogue",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TestId = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "text", nullable: false),
                    Unit = table.Column<string>(type: "text", nullable: true),
                    ReferenceRange = table.Column<string>(type: "text", nullable: true),
                    Description = table.Column<string>(type: "text", nullable: true),
                    SortOrder = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_test_parameters", x => x.Id);
                    table.ForeignKey(
                        name: "FK_test_parameters_tests_TestId",
                        column: x => x.TestId,
                        principalSchema: "catalogue",
                        principalTable: "tests",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_users_MembershipTierId",
                schema: "core",
                table: "users",
                column: "MembershipTierId");

            migrationBuilder.CreateIndex(
                name: "IX_users_Mobile",
                schema: "core",
                table: "users",
                column: "Mobile",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_users_ReferralCode",
                schema: "core",
                table: "users",
                column: "ReferralCode",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_refresh_tokens_TokenHash",
                schema: "core",
                table: "refresh_tokens",
                column: "TokenHash",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_addresses_UserId",
                schema: "core",
                table: "addresses",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_ai_chat_messages_SessionId",
                schema: "comms",
                table: "ai_chat_messages",
                column: "SessionId");

            migrationBuilder.CreateIndex(
                name: "IX_ai_sessions_UserId",
                schema: "comms",
                table: "ai_sessions",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_app_config_Key",
                schema: "core",
                table: "app_config",
                column: "Key",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_articles_Slug",
                schema: "content",
                table: "articles",
                column: "Slug",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_booking_items_BookingId",
                schema: "booking",
                table: "booking_items",
                column: "BookingId");

            migrationBuilder.CreateIndex(
                name: "IX_bookings_BookingNumber",
                schema: "booking",
                table: "bookings",
                column: "BookingNumber",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_bookings_UserId",
                schema: "booking",
                table: "bookings",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_cart_items_CartId",
                schema: "commerce",
                table: "cart_items",
                column: "CartId");

            migrationBuilder.CreateIndex(
                name: "IX_carts_UserId",
                schema: "commerce",
                table: "carts",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_categories_Slug",
                schema: "catalogue",
                table: "categories",
                column: "Slug",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_consultations_UserId",
                schema: "reports",
                table: "consultations",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_coupons_Code",
                schema: "commerce",
                table: "coupons",
                column: "Code",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_custom_packages_UserId",
                schema: "booking",
                table: "custom_packages",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_devices_UserId",
                schema: "core",
                table: "devices",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_doctors_Slug",
                schema: "catalogue",
                table: "doctors",
                column: "Slug",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_doctors_SpecialtyId",
                schema: "catalogue",
                table: "doctors",
                column: "SpecialtyId");

            migrationBuilder.CreateIndex(
                name: "IX_family_members_UserId",
                schema: "core",
                table: "family_members",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_group_booking_members_GroupBookingId",
                schema: "booking",
                table: "group_booking_members",
                column: "GroupBookingId");

            migrationBuilder.CreateIndex(
                name: "IX_group_bookings_Code",
                schema: "booking",
                table: "group_bookings",
                column: "Code",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_health_scores_UserId",
                schema: "health",
                table: "health_scores",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_lab_reports_UserId",
                schema: "reports",
                table: "lab_reports",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_notifications_UserId",
                schema: "comms",
                table: "notifications",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_package_tests_PackageId",
                schema: "catalogue",
                table: "package_tests",
                column: "PackageId");

            migrationBuilder.CreateIndex(
                name: "IX_package_tests_TestId",
                schema: "catalogue",
                table: "package_tests",
                column: "TestId");

            migrationBuilder.CreateIndex(
                name: "IX_packages_Slug",
                schema: "catalogue",
                table: "packages",
                column: "Slug",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_payments_BookingId",
                schema: "commerce",
                table: "payments",
                column: "BookingId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_reminders_UserId",
                schema: "health",
                table: "reminders",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_report_parameters_LabReportId",
                schema: "reports",
                table: "report_parameters",
                column: "LabReportId");

            migrationBuilder.CreateIndex(
                name: "IX_specialties_Slug",
                schema: "catalogue",
                table: "specialties",
                column: "Slug",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_subscriptions_UserId",
                schema: "booking",
                table: "subscriptions",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_supplements_Slug",
                schema: "catalogue",
                table: "supplements",
                column: "Slug",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_support_messages_TicketId",
                schema: "comms",
                table: "support_messages",
                column: "TicketId");

            migrationBuilder.CreateIndex(
                name: "IX_support_tickets_TicketNumber",
                schema: "comms",
                table: "support_tickets",
                column: "TicketNumber",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_support_tickets_UserId",
                schema: "comms",
                table: "support_tickets",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_test_parameters_TestId",
                schema: "catalogue",
                table: "test_parameters",
                column: "TestId");

            migrationBuilder.CreateIndex(
                name: "IX_tests_CategoryId",
                schema: "catalogue",
                table: "tests",
                column: "CategoryId");

            migrationBuilder.CreateIndex(
                name: "IX_tests_Slug",
                schema: "catalogue",
                table: "tests",
                column: "Slug",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_vitals_UserId",
                schema: "health",
                table: "vitals",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_wallet_transactions_WalletId",
                schema: "commerce",
                table: "wallet_transactions",
                column: "WalletId");

            migrationBuilder.CreateIndex(
                name: "IX_wallets_UserId",
                schema: "commerce",
                table: "wallets",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_whatsapp_templates_Key",
                schema: "comms",
                table: "whatsapp_templates",
                column: "Key",
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_users_membership_tiers_MembershipTierId",
                schema: "core",
                table: "users",
                column: "MembershipTierId",
                principalSchema: "commerce",
                principalTable: "membership_tiers",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_users_membership_tiers_MembershipTierId",
                schema: "core",
                table: "users");

            migrationBuilder.DropTable(
                name: "addresses",
                schema: "core");

            migrationBuilder.DropTable(
                name: "ai_chat_messages",
                schema: "comms");

            migrationBuilder.DropTable(
                name: "ai_prompts",
                schema: "content");

            migrationBuilder.DropTable(
                name: "app_config",
                schema: "core");

            migrationBuilder.DropTable(
                name: "articles",
                schema: "content");

            migrationBuilder.DropTable(
                name: "audit_logs",
                schema: "core");

            migrationBuilder.DropTable(
                name: "banners",
                schema: "content");

            migrationBuilder.DropTable(
                name: "booking_items",
                schema: "booking");

            migrationBuilder.DropTable(
                name: "cart_items",
                schema: "commerce");

            migrationBuilder.DropTable(
                name: "cashback_offers",
                schema: "commerce");

            migrationBuilder.DropTable(
                name: "cashbacks",
                schema: "commerce");

            migrationBuilder.DropTable(
                name: "centre_pricing",
                schema: "catalogue");

            migrationBuilder.DropTable(
                name: "centres",
                schema: "catalogue");

            migrationBuilder.DropTable(
                name: "consultations",
                schema: "reports");

            migrationBuilder.DropTable(
                name: "coupons",
                schema: "commerce");

            migrationBuilder.DropTable(
                name: "custom_packages",
                schema: "booking");

            migrationBuilder.DropTable(
                name: "devices",
                schema: "core");

            migrationBuilder.DropTable(
                name: "diet_plans",
                schema: "reports");

            migrationBuilder.DropTable(
                name: "doctor_slots",
                schema: "catalogue");

            migrationBuilder.DropTable(
                name: "doctors",
                schema: "catalogue");

            migrationBuilder.DropTable(
                name: "family_members",
                schema: "core");

            migrationBuilder.DropTable(
                name: "group_booking_members",
                schema: "booking");

            migrationBuilder.DropTable(
                name: "health_scores",
                schema: "health");

            migrationBuilder.DropTable(
                name: "home_sections",
                schema: "content");

            migrationBuilder.DropTable(
                name: "lifestyle_logs",
                schema: "health");

            migrationBuilder.DropTable(
                name: "membership_tiers",
                schema: "commerce");

            migrationBuilder.DropTable(
                name: "nav_items",
                schema: "content");

            migrationBuilder.DropTable(
                name: "notifications",
                schema: "comms");

            migrationBuilder.DropTable(
                name: "onboarding_slides",
                schema: "content");

            migrationBuilder.DropTable(
                name: "otp_requests",
                schema: "core");

            migrationBuilder.DropTable(
                name: "package_tests",
                schema: "catalogue");

            migrationBuilder.DropTable(
                name: "partner_commissions",
                schema: "admin");

            migrationBuilder.DropTable(
                name: "partners",
                schema: "admin");

            migrationBuilder.DropTable(
                name: "payments",
                schema: "commerce");

            migrationBuilder.DropTable(
                name: "quick_actions",
                schema: "content");

            migrationBuilder.DropTable(
                name: "referrals",
                schema: "commerce");

            migrationBuilder.DropTable(
                name: "refunds",
                schema: "commerce");

            migrationBuilder.DropTable(
                name: "reminders",
                schema: "health");

            migrationBuilder.DropTable(
                name: "report_parameters",
                schema: "reports");

            migrationBuilder.DropTable(
                name: "slots",
                schema: "booking");

            migrationBuilder.DropTable(
                name: "steps",
                schema: "health");

            migrationBuilder.DropTable(
                name: "subscriptions",
                schema: "booking");

            migrationBuilder.DropTable(
                name: "supplements",
                schema: "catalogue");

            migrationBuilder.DropTable(
                name: "support_messages",
                schema: "comms");

            migrationBuilder.DropTable(
                name: "symptom_checks",
                schema: "health");

            migrationBuilder.DropTable(
                name: "technicians",
                schema: "booking");

            migrationBuilder.DropTable(
                name: "test_faqs",
                schema: "catalogue");

            migrationBuilder.DropTable(
                name: "test_parameters",
                schema: "catalogue");

            migrationBuilder.DropTable(
                name: "test_reviews",
                schema: "catalogue");

            migrationBuilder.DropTable(
                name: "vitals",
                schema: "health");

            migrationBuilder.DropTable(
                name: "wallet_transactions",
                schema: "commerce");

            migrationBuilder.DropTable(
                name: "whatsapp_templates",
                schema: "comms");

            migrationBuilder.DropTable(
                name: "ai_sessions",
                schema: "comms");

            migrationBuilder.DropTable(
                name: "carts",
                schema: "commerce");

            migrationBuilder.DropTable(
                name: "specialties",
                schema: "catalogue");

            migrationBuilder.DropTable(
                name: "group_bookings",
                schema: "booking");

            migrationBuilder.DropTable(
                name: "packages",
                schema: "catalogue");

            migrationBuilder.DropTable(
                name: "bookings",
                schema: "booking");

            migrationBuilder.DropTable(
                name: "lab_reports",
                schema: "reports");

            migrationBuilder.DropTable(
                name: "support_tickets",
                schema: "comms");

            migrationBuilder.DropTable(
                name: "tests",
                schema: "catalogue");

            migrationBuilder.DropTable(
                name: "wallets",
                schema: "commerce");

            migrationBuilder.DropTable(
                name: "categories",
                schema: "catalogue");

            migrationBuilder.DropIndex(
                name: "IX_users_MembershipTierId",
                schema: "core",
                table: "users");

            migrationBuilder.DropIndex(
                name: "IX_users_Mobile",
                schema: "core",
                table: "users");

            migrationBuilder.DropIndex(
                name: "IX_users_ReferralCode",
                schema: "core",
                table: "users");

            migrationBuilder.DropIndex(
                name: "IX_refresh_tokens_TokenHash",
                schema: "core",
                table: "refresh_tokens");

            migrationBuilder.DropColumn(
                name: "AvatarUrl",
                schema: "core",
                table: "users");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                schema: "core",
                table: "users");

            migrationBuilder.DropColumn(
                name: "DateOfBirth",
                schema: "core",
                table: "users");

            migrationBuilder.DropColumn(
                name: "Email",
                schema: "core",
                table: "users");

            migrationBuilder.DropColumn(
                name: "Gender",
                schema: "core",
                table: "users");

            migrationBuilder.DropColumn(
                name: "IsActive",
                schema: "core",
                table: "users");

            migrationBuilder.DropColumn(
                name: "IsAdminPortalUser",
                schema: "core",
                table: "users");

            migrationBuilder.DropColumn(
                name: "IsDeleted",
                schema: "core",
                table: "users");

            migrationBuilder.DropColumn(
                name: "LastLoginAt",
                schema: "core",
                table: "users");

            migrationBuilder.DropColumn(
                name: "MembershipTierId",
                schema: "core",
                table: "users");

            migrationBuilder.DropColumn(
                name: "Mobile",
                schema: "core",
                table: "users");

            migrationBuilder.DropColumn(
                name: "Name",
                schema: "core",
                table: "users");

            migrationBuilder.DropColumn(
                name: "ReferralCode",
                schema: "core",
                table: "users");

            migrationBuilder.DropColumn(
                name: "ReferredByUserId",
                schema: "core",
                table: "users");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                schema: "core",
                table: "users");

            migrationBuilder.DropColumn(
                name: "DeviceId",
                schema: "core",
                table: "refresh_tokens");

            migrationBuilder.DropColumn(
                name: "ExpiresAt",
                schema: "core",
                table: "refresh_tokens");

            migrationBuilder.DropColumn(
                name: "ReplacedByTokenHash",
                schema: "core",
                table: "refresh_tokens");

            migrationBuilder.DropColumn(
                name: "RevokedAt",
                schema: "core",
                table: "refresh_tokens");

            migrationBuilder.DropColumn(
                name: "TokenHash",
                schema: "core",
                table: "refresh_tokens");
        }
    }
}
