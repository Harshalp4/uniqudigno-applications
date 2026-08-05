using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Bit2sky.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddBookingPatientSnapshot : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateOnly>(
                name: "PatientDateOfBirth",
                schema: "booking",
                table: "bookings",
                type: "date",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PatientGender",
                schema: "booking",
                table: "bookings",
                type: "character varying(40)",
                maxLength: 40,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PatientName",
                schema: "booking",
                table: "bookings",
                type: "text",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "PatientDateOfBirth",
                schema: "booking",
                table: "bookings");

            migrationBuilder.DropColumn(
                name: "PatientGender",
                schema: "booking",
                table: "bookings");

            migrationBuilder.DropColumn(
                name: "PatientName",
                schema: "booking",
                table: "bookings");
        }
    }
}
