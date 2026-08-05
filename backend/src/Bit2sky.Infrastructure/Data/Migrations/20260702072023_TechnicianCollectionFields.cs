using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Bit2sky.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class TechnicianCollectionFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "CollectionPhotoUrl",
                schema: "booking",
                table: "bookings",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "SampleBarcode",
                schema: "booking",
                table: "bookings",
                type: "text",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "CollectionPhotoUrl",
                schema: "booking",
                table: "bookings");

            migrationBuilder.DropColumn(
                name: "SampleBarcode",
                schema: "booking",
                table: "bookings");
        }
    }
}
