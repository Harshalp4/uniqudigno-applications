using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Bit2sky.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class TechnicianLoginCredentials : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "EmployeeId",
                schema: "booking",
                table: "technicians",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "FailedLoginCount",
                schema: "booking",
                table: "technicians",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "LastLoginAt",
                schema: "booking",
                table: "technicians",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "LoginLockedUntil",
                schema: "booking",
                table: "technicians",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PasswordHash",
                schema: "booking",
                table: "technicians",
                type: "text",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_technicians_EmployeeId",
                schema: "booking",
                table: "technicians",
                column: "EmployeeId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_technicians_UserId",
                schema: "booking",
                table: "technicians",
                column: "UserId");

            migrationBuilder.AddForeignKey(
                name: "FK_technicians_users_UserId",
                schema: "booking",
                table: "technicians",
                column: "UserId",
                principalSchema: "core",
                principalTable: "users",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_technicians_users_UserId",
                schema: "booking",
                table: "technicians");

            migrationBuilder.DropIndex(
                name: "IX_technicians_EmployeeId",
                schema: "booking",
                table: "technicians");

            migrationBuilder.DropIndex(
                name: "IX_technicians_UserId",
                schema: "booking",
                table: "technicians");

            migrationBuilder.DropColumn(
                name: "EmployeeId",
                schema: "booking",
                table: "technicians");

            migrationBuilder.DropColumn(
                name: "FailedLoginCount",
                schema: "booking",
                table: "technicians");

            migrationBuilder.DropColumn(
                name: "LastLoginAt",
                schema: "booking",
                table: "technicians");

            migrationBuilder.DropColumn(
                name: "LoginLockedUntil",
                schema: "booking",
                table: "technicians");

            migrationBuilder.DropColumn(
                name: "PasswordHash",
                schema: "booking",
                table: "technicians");
        }
    }
}
