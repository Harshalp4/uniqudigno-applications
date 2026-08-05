using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Bit2sky.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class ArticleLanguage : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Language",
                schema: "content",
                table: "articles",
                type: "text",
                nullable: false,
                defaultValue: "en");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Language",
                schema: "content",
                table: "articles");
        }
    }
}
