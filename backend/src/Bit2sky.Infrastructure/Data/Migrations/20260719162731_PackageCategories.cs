using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Bit2sky.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class PackageCategories : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "package_categories",
                schema: "catalogue",
                columns: table => new
                {
                    PackageId = table.Column<Guid>(type: "uuid", nullable: false),
                    CategoryId = table.Column<Guid>(type: "uuid", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_package_categories", x => new { x.PackageId, x.CategoryId });
                    table.ForeignKey(
                        name: "FK_package_categories_packages_PackageId",
                        column: x => x.PackageId,
                        principalSchema: "catalogue",
                        principalTable: "packages",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "package_categories",
                schema: "catalogue");
        }
    }
}
