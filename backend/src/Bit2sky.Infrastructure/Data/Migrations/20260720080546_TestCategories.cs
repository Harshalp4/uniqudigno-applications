using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Bit2sky.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class TestCategories : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "test_categories",
                schema: "catalogue",
                columns: table => new
                {
                    TestId = table.Column<Guid>(type: "uuid", nullable: false),
                    CategoryId = table.Column<Guid>(type: "uuid", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_test_categories", x => new { x.TestId, x.CategoryId });
                    table.ForeignKey(
                        name: "FK_test_categories_tests_TestId",
                        column: x => x.TestId,
                        principalSchema: "catalogue",
                        principalTable: "tests",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "test_categories",
                schema: "catalogue");
        }
    }
}
