using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace PcmBackend.Migrations
{
    /// <inheritdoc />
    public partial class UpdateSchema643 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "643_Courts",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    Description = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    PricePerHour = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_643_Courts", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "643_News",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Title = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Content = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    IsPinned = table.Column<bool>(type: "bit", nullable: false),
                    CreatedDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    ImageUrl = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_643_News", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "643_Notifications",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ReceiverId = table.Column<int>(type: "int", nullable: false),
                    Message = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Type = table.Column<int>(type: "int", nullable: false),
                    LinkUrl = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    IsRead = table.Column<bool>(type: "bit", nullable: false),
                    CreatedDate = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_643_Notifications", x => x.Id);
                    table.ForeignKey(
                        name: "FK_643_Notifications_643_Members_ReceiverId",
                        column: x => x.ReceiverId,
                        principalTable: "643_Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "643_Tournaments",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    StartDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    EndDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Format = table.Column<int>(type: "int", nullable: false),
                    EntryFee = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false),
                    PrizePool = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false),
                    Status = table.Column<int>(type: "int", nullable: false),
                    Settings = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_643_Tournaments", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "643_TransactionCategories",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Type = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_643_TransactionCategories", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "643_Bookings",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    CourtId = table.Column<int>(type: "int", nullable: false),
                    MemberId = table.Column<int>(type: "int", nullable: false),
                    StartTime = table.Column<DateTime>(type: "datetime2", nullable: false),
                    EndTime = table.Column<DateTime>(type: "datetime2", nullable: false),
                    TotalPrice = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false),
                    TransactionId = table.Column<int>(type: "int", nullable: true),
                    IsRecurring = table.Column<bool>(type: "bit", nullable: false),
                    RecurrenceRule = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    ParentBookingId = table.Column<int>(type: "int", nullable: true),
                    Status = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_643_Bookings", x => x.Id);
                    table.ForeignKey(
                        name: "FK_643_Bookings_643_Courts_CourtId",
                        column: x => x.CourtId,
                        principalTable: "643_Courts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_643_Bookings_643_Members_MemberId",
                        column: x => x.MemberId,
                        principalTable: "643_Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_643_Bookings_643_WalletTransactions_TransactionId",
                        column: x => x.TransactionId,
                        principalTable: "643_WalletTransactions",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "643_Matches",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    TournamentId = table.Column<int>(type: "int", nullable: true),
                    RoundName = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Date = table.Column<DateTime>(type: "datetime2", nullable: false),
                    StartTime = table.Column<TimeSpan>(type: "time", nullable: false),
                    Team1_Player1Id = table.Column<int>(type: "int", nullable: true),
                    Team1_Player2Id = table.Column<int>(type: "int", nullable: true),
                    Team2_Player1Id = table.Column<int>(type: "int", nullable: true),
                    Team2_Player2Id = table.Column<int>(type: "int", nullable: true),
                    Score1 = table.Column<int>(type: "int", nullable: false),
                    Score2 = table.Column<int>(type: "int", nullable: false),
                    Details = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    WinningSide = table.Column<int>(type: "int", nullable: false),
                    IsRanked = table.Column<bool>(type: "bit", nullable: false),
                    Status = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_643_Matches", x => x.Id);
                    table.ForeignKey(
                        name: "FK_643_Matches_643_Tournaments_TournamentId",
                        column: x => x.TournamentId,
                        principalTable: "643_Tournaments",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "643_TournamentParticipants",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    TournamentId = table.Column<int>(type: "int", nullable: false),
                    MemberId = table.Column<int>(type: "int", nullable: false),
                    TeamName = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    PaymentStatus = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_643_TournamentParticipants", x => x.Id);
                    table.ForeignKey(
                        name: "FK_643_TournamentParticipants_643_Members_MemberId",
                        column: x => x.MemberId,
                        principalTable: "643_Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_643_TournamentParticipants_643_Tournaments_TournamentId",
                        column: x => x.TournamentId,
                        principalTable: "643_Tournaments",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_643_Bookings_CourtId",
                table: "643_Bookings",
                column: "CourtId");

            migrationBuilder.CreateIndex(
                name: "IX_643_Bookings_MemberId",
                table: "643_Bookings",
                column: "MemberId");

            migrationBuilder.CreateIndex(
                name: "IX_643_Bookings_TransactionId",
                table: "643_Bookings",
                column: "TransactionId");

            migrationBuilder.CreateIndex(
                name: "IX_643_Matches_TournamentId",
                table: "643_Matches",
                column: "TournamentId");

            migrationBuilder.CreateIndex(
                name: "IX_643_Notifications_ReceiverId",
                table: "643_Notifications",
                column: "ReceiverId");

            migrationBuilder.CreateIndex(
                name: "IX_643_TournamentParticipants_MemberId",
                table: "643_TournamentParticipants",
                column: "MemberId");

            migrationBuilder.CreateIndex(
                name: "IX_643_TournamentParticipants_TournamentId",
                table: "643_TournamentParticipants",
                column: "TournamentId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "643_Bookings");

            migrationBuilder.DropTable(
                name: "643_Matches");

            migrationBuilder.DropTable(
                name: "643_News");

            migrationBuilder.DropTable(
                name: "643_Notifications");

            migrationBuilder.DropTable(
                name: "643_TournamentParticipants");

            migrationBuilder.DropTable(
                name: "643_TransactionCategories");

            migrationBuilder.DropTable(
                name: "643_Courts");

            migrationBuilder.DropTable(
                name: "643_Tournaments");
        }
    }
}
