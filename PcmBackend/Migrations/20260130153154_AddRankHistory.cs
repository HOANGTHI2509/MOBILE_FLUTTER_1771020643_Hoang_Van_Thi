using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace PcmBackend.Migrations
{
    /// <inheritdoc />
    public partial class AddRankHistory : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "643_RankHistory",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    MemberId = table.Column<int>(type: "int", nullable: false),
                    RankLevel = table.Column<double>(type: "float", nullable: false),
                    Reason = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    CreatedDate = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_643_RankHistory", x => x.Id);
                    table.ForeignKey(
                        name: "FK_643_RankHistory_643_Members_MemberId",
                        column: x => x.MemberId,
                        principalTable: "643_Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_643_RankHistory_MemberId",
                table: "643_RankHistory",
                column: "MemberId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "643_RankHistory");
        }
    }
}
