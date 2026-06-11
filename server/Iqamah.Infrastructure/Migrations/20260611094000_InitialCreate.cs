using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Iqamah.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "PrayerLogs",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<int>(type: "integer", nullable: false),
                    PrayerName = table.Column<int>(type: "integer", nullable: false),
                    PrayerDate = table.Column<DateOnly>(type: "date", nullable: false),
                    IsOffered = table.Column<bool>(type: "boolean", nullable: false),
                    WaqtStatus = table.Column<int>(type: "integer", nullable: true),
                    MissedReason = table.Column<int>(type: "integer", nullable: true),
                    IsJamaah = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    IsTraveling = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    IsJummah = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    LoggedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PrayerLogs", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "QazaLogs",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    PrayerLogId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<int>(type: "integer", nullable: false),
                    PrayerName = table.Column<int>(type: "integer", nullable: false),
                    OriginalPrayerDate = table.Column<DateOnly>(type: "date", nullable: false),
                    State = table.Column<int>(type: "integer", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    FulfilledAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    TimeToResolution = table.Column<TimeSpan>(type: "interval", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_QazaLogs", x => x.Id);
                    table.ForeignKey(
                        name: "FK_QazaLogs_PrayerLogs_PrayerLogId",
                        column: x => x.PrayerLogId,
                        principalTable: "PrayerLogs",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_PrayerLogs_UserId_PrayerDate",
                table: "PrayerLogs",
                columns: new[] { "UserId", "PrayerDate" });

            migrationBuilder.CreateIndex(
                name: "IX_PrayerLogs_UserId_PrayerName_PrayerDate",
                table: "PrayerLogs",
                columns: new[] { "UserId", "PrayerName", "PrayerDate" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_QazaLogs_PrayerLogId",
                table: "QazaLogs",
                column: "PrayerLogId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_QazaLogs_UserId_PrayerName_State",
                table: "QazaLogs",
                columns: new[] { "UserId", "PrayerName", "State" });

            migrationBuilder.CreateIndex(
                name: "IX_QazaLogs_UserId_State",
                table: "QazaLogs",
                columns: new[] { "UserId", "State" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "QazaLogs");

            migrationBuilder.DropTable(
                name: "PrayerLogs");
        }
    }
}
