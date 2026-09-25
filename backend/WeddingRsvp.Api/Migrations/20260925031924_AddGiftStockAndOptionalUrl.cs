using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace WeddingRsvp.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddGiftStockAndOptionalUrl : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ExternalUrl",
                table: "gifts",
                type: "character varying(2048)",
                maxLength: 2048,
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "StockRemaining",
                table: "gifts",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "StockReleased",
                table: "gift_orders",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<int>(
                name: "ReservedQuantity",
                table: "gift_order_items",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddCheckConstraint(
                name: "CK_gifts_stock_nonnegative",
                table: "gifts",
                sql: "\"StockRemaining\" IS NULL OR \"StockRemaining\" >= 0");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropCheckConstraint(
                name: "CK_gifts_stock_nonnegative",
                table: "gifts");

            migrationBuilder.DropColumn(
                name: "ExternalUrl",
                table: "gifts");

            migrationBuilder.DropColumn(
                name: "StockRemaining",
                table: "gifts");

            migrationBuilder.DropColumn(
                name: "StockReleased",
                table: "gift_orders");

            migrationBuilder.DropColumn(
                name: "ReservedQuantity",
                table: "gift_order_items");
        }
    }
}
