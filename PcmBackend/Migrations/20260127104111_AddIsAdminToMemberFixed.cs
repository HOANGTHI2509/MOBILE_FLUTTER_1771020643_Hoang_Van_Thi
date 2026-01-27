using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace PcmBackend.Migrations
{
    /// <inheritdoc />
    public partial class AddIsAdminToMemberFixed : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Email",
                table: "643_Members",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<bool>(
                name: "IsAdmin",
                table: "643_Members",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.CreateIndex(
                name: "IX_643_WalletTransactions_MemberId",
                table: "643_WalletTransactions",
                column: "MemberId");

            migrationBuilder.AddForeignKey(
                name: "FK_643_WalletTransactions_643_Members_MemberId",
                table: "643_WalletTransactions",
                column: "MemberId",
                principalTable: "643_Members",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_643_WalletTransactions_643_Members_MemberId",
                table: "643_WalletTransactions");

            migrationBuilder.DropIndex(
                name: "IX_643_WalletTransactions_MemberId",
                table: "643_WalletTransactions");

            migrationBuilder.DropColumn(
                name: "Email",
                table: "643_Members");

            migrationBuilder.DropColumn(
                name: "IsAdmin",
                table: "643_Members");
        }
    }
}
