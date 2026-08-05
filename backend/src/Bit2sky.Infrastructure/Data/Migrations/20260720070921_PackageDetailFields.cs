using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Bit2sky.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class PackageDetailFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "FaqJson",
                schema: "catalogue",
                table: "packages",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "FastingHours",
                schema: "catalogue",
                table: "packages",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Preparation",
                schema: "catalogue",
                table: "packages",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "RecommendedFor",
                schema: "catalogue",
                table: "packages",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "SampleType",
                schema: "catalogue",
                table: "packages",
                type: "text",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "FaqJson",
                schema: "catalogue",
                table: "packages");

            migrationBuilder.DropColumn(
                name: "FastingHours",
                schema: "catalogue",
                table: "packages");

            migrationBuilder.DropColumn(
                name: "Preparation",
                schema: "catalogue",
                table: "packages");

            migrationBuilder.DropColumn(
                name: "RecommendedFor",
                schema: "catalogue",
                table: "packages");

            migrationBuilder.DropColumn(
                name: "SampleType",
                schema: "catalogue",
                table: "packages");
        }
    }
}
