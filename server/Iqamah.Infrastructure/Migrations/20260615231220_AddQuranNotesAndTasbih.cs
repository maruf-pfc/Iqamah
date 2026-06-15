using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Iqamah.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddQuranNotesAndTasbih : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "HasTasbih",
                table: "PrayerLogs",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "QuranNotes",
                table: "PrayerLogs",
                type: "character varying(500)",
                maxLength: 500,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "HasTasbih",
                table: "PrayerLogs");

            migrationBuilder.DropColumn(
                name: "QuranNotes",
                table: "PrayerLogs");
        }
    }
}
