using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Bit2sky.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class EmailAndGoogleAuth : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<string>(
                name: "Mobile",
                schema: "core",
                table: "users",
                type: "character varying(20)",
                maxLength: 20,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "character varying(20)",
                oldMaxLength: 20);

            migrationBuilder.AlterColumn<string>(
                name: "Mobile",
                schema: "core",
                table: "otp_requests",
                type: "text",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "text");

            migrationBuilder.AddColumn<string>(
                name: "Email",
                schema: "core",
                table: "otp_requests",
                type: "text",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_users_Email",
                schema: "core",
                table: "users",
                column: "Email",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_users_Email",
                schema: "core",
                table: "users");

            migrationBuilder.DropColumn(
                name: "Email",
                schema: "core",
                table: "otp_requests");

            migrationBuilder.AlterColumn<string>(
                name: "Mobile",
                schema: "core",
                table: "users",
                type: "character varying(20)",
                maxLength: 20,
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "character varying(20)",
                oldMaxLength: 20,
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "Mobile",
                schema: "core",
                table: "otp_requests",
                type: "text",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "text",
                oldNullable: true);
        }
    }
}
