using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Bit2sky.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class BannerSubtitleCta : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "CtaLabel",
                schema: "content",
                table: "banners",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Subtitle",
                schema: "content",
                table: "banners",
                type: "text",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "CtaLabel",
                schema: "content",
                table: "banners");

            migrationBuilder.DropColumn(
                name: "Subtitle",
                schema: "content",
                table: "banners");
        }
    }
}
