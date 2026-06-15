using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Iqamah.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddIsHomeToPrayerLog : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "IsHome",
                table: "PrayerLogs",
                type: "boolean",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IsHome",
                table: "PrayerLogs");
        }
    }
}
