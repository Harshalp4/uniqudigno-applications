using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Bit2sky.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class InitialRbacAndSecurity : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.EnsureSchema(
                name: "admin");

            migrationBuilder.EnsureSchema(
                name: "core");

            migrationBuilder.CreateTable(
                name: "permissions",
                schema: "admin",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Code = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Module = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Action = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    Description = table.Column<string>(type: "text", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_permissions", x => x.Id);
                    table.CheckConstraint("ck_permissions_action", "\"Action\" IN ('view','create','update','delete','export','approve','assign','manage','broadcast')");
                });

            migrationBuilder.CreateTable(
                name: "roles",
                schema: "admin",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Description = table.Column<string>(type: "text", nullable: true),
                    IsSystem = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()"),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_roles", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "users",
                schema: "core",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    OtpLockoutUntil = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    OtpAttemptCount = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    Admin2faSecret = table.Column<string>(type: "text", nullable: true),
                    Admin2faEnabled = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    Admin2faBackupCodes = table.Column<List<string>>(type: "text[]", nullable: false),
                    LastIpAddress = table.Column<string>(type: "character varying(45)", maxLength: 45, nullable: true),
                    FailedLoginCount = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    LoginLockedUntil = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    PasswordHash = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    PasswordChangedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    PiiEncrypted = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_users", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "role_permissions",
                schema: "admin",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    RoleId = table.Column<Guid>(type: "uuid", nullable: false),
                    PermissionId = table.Column<Guid>(type: "uuid", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_role_permissions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_role_permissions_permissions_PermissionId",
                        column: x => x.PermissionId,
                        principalSchema: "admin",
                        principalTable: "permissions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_role_permissions_roles_RoleId",
                        column: x => x.RoleId,
                        principalSchema: "admin",
                        principalTable: "roles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "refresh_tokens",
                schema: "core",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    TokenFamily = table.Column<Guid>(type: "uuid", nullable: false),
                    IsTheftDetected = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    ReusedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_refresh_tokens", x => x.Id);
                    table.ForeignKey(
                        name: "FK_refresh_tokens_users_UserId",
                        column: x => x.UserId,
                        principalSchema: "core",
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "security_events",
                schema: "core",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    event_type = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: true),
                    IpAddress = table.Column<string>(type: "character varying(45)", maxLength: 45, nullable: true),
                    UserAgent = table.Column<string>(type: "text", nullable: true),
                    Details = table.Column<string>(type: "jsonb", nullable: true),
                    Severity = table.Column<string>(type: "character varying(10)", maxLength: 10, nullable: false),
                    Resolved = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    ResolvedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    ResolvedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_security_events", x => x.Id);
                    table.CheckConstraint("ck_security_events_event_type", "event_type IN ('otp_max_attempts','token_reuse_detected','login_locked','admin_new_ip','bulk_download_detected','rate_limit_blocked','jwt_reuse_detected','permission_escalation_attempt','ssrf_attempt','invalid_file_upload')");
                    table.CheckConstraint("ck_security_events_severity", "\"Severity\" IN ('low','medium','high','critical')");
                    table.ForeignKey(
                        name: "FK_security_events_users_ResolvedBy",
                        column: x => x.ResolvedBy,
                        principalSchema: "core",
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_security_events_users_UserId",
                        column: x => x.UserId,
                        principalSchema: "core",
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "user_roles",
                schema: "admin",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    RoleId = table.Column<Guid>(type: "uuid", nullable: false),
                    AssignedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    AssignedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_user_roles", x => x.Id);
                    table.ForeignKey(
                        name: "FK_user_roles_roles_RoleId",
                        column: x => x.RoleId,
                        principalSchema: "admin",
                        principalTable: "roles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_user_roles_users_AssignedBy",
                        column: x => x.AssignedBy,
                        principalSchema: "core",
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_user_roles_users_UserId",
                        column: x => x.UserId,
                        principalSchema: "core",
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_permissions_Code",
                schema: "admin",
                table: "permissions",
                column: "Code",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_refresh_tokens_TokenFamily",
                schema: "core",
                table: "refresh_tokens",
                column: "TokenFamily");

            migrationBuilder.CreateIndex(
                name: "IX_refresh_tokens_UserId",
                schema: "core",
                table: "refresh_tokens",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_role_permissions_PermissionId",
                schema: "admin",
                table: "role_permissions",
                column: "PermissionId");

            migrationBuilder.CreateIndex(
                name: "IX_role_permissions_RoleId_PermissionId",
                schema: "admin",
                table: "role_permissions",
                columns: new[] { "RoleId", "PermissionId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_roles_Name",
                schema: "admin",
                table: "roles",
                column: "Name",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "idx_security_events_type",
                schema: "core",
                table: "security_events",
                columns: new[] { "event_type", "Severity", "CreatedAt" },
                descending: new[] { false, false, true });

            migrationBuilder.CreateIndex(
                name: "IX_security_events_ResolvedBy",
                schema: "core",
                table: "security_events",
                column: "ResolvedBy");

            migrationBuilder.CreateIndex(
                name: "IX_security_events_UserId",
                schema: "core",
                table: "security_events",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_user_roles_AssignedBy",
                schema: "admin",
                table: "user_roles",
                column: "AssignedBy");

            migrationBuilder.CreateIndex(
                name: "IX_user_roles_RoleId",
                schema: "admin",
                table: "user_roles",
                column: "RoleId");

            migrationBuilder.CreateIndex(
                name: "IX_user_roles_UserId_RoleId",
                schema: "admin",
                table: "user_roles",
                columns: new[] { "UserId", "RoleId" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "refresh_tokens",
                schema: "core");

            migrationBuilder.DropTable(
                name: "role_permissions",
                schema: "admin");

            migrationBuilder.DropTable(
                name: "security_events",
                schema: "core");

            migrationBuilder.DropTable(
                name: "user_roles",
                schema: "admin");

            migrationBuilder.DropTable(
                name: "permissions",
                schema: "admin");

            migrationBuilder.DropTable(
                name: "roles",
                schema: "admin");

            migrationBuilder.DropTable(
                name: "users",
                schema: "core");
        }
    }
}
