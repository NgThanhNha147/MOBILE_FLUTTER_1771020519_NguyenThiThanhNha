using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace PCM.API.Migrations
{
    /// <inheritdoc />
    public partial class AddHoldSlotAndRecurringBooking : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "HoldExpiresAt",
                table: "519_Bookings",
                type: "datetime(6)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "HoldExpiresAt",
                table: "519_Bookings");
        }
    }
}
