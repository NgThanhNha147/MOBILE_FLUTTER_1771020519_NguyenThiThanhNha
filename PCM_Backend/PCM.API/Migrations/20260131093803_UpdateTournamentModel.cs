using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace PCM.API.Migrations
{
    /// <inheritdoc />
    public partial class UpdateTournamentModel : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "CreatorId",
                table: "519_Tournaments",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Description",
                table: "519_Tournaments",
                type: "varchar(500)",
                maxLength: 500,
                nullable: true)
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.AddColumn<int>(
                name: "MaxParticipants",
                table: "519_Tournaments",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "Type",
                table: "519_Tournaments",
                type: "int",
                nullable: false,
                defaultValue: 0);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "CreatorId",
                table: "519_Tournaments");

            migrationBuilder.DropColumn(
                name: "Description",
                table: "519_Tournaments");

            migrationBuilder.DropColumn(
                name: "MaxParticipants",
                table: "519_Tournaments");

            migrationBuilder.DropColumn(
                name: "Type",
                table: "519_Tournaments");
        }
    }
}
