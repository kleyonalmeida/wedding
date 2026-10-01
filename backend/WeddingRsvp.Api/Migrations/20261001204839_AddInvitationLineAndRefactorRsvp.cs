using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace WeddingRsvp.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddInvitationLineAndRefactorRsvp : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "ix_rsvps_email",
                table: "rsvps");

            migrationBuilder.DropColumn(
                name: "Nome",
                table: "rsvps");

            migrationBuilder.DropColumn(
                name: "Observacoes",
                table: "rsvps");

            migrationBuilder.AddColumn<bool>(
                name: "AceitouTermos",
                table: "rsvps",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "IdentificacaoNoConvite",
                table: "rsvps",
                type: "character varying(200)",
                maxLength: 200,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<Guid>(
                name: "InvitationLineId",
                table: "rsvps",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.CreateTable(
                name: "invitation_lines",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    IdentificacaoNoConvite = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    IdentificacaoNormalizada = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    QuantidadeAdultos = table.Column<int>(type: "integer", nullable: false),
                    Ativo = table.Column<bool>(type: "boolean", nullable: false),
                    CriadoEm = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "NOW()"),
                    AtualizadoEm = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_invitation_lines", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "ix_rsvps_invitation_line_id",
                table: "rsvps",
                column: "InvitationLineId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_invitation_lines_normalized",
                table: "invitation_lines",
                column: "IdentificacaoNormalizada",
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_rsvps_invitation_lines_InvitationLineId",
                table: "rsvps",
                column: "InvitationLineId",
                principalTable: "invitation_lines",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_rsvps_invitation_lines_InvitationLineId",
                table: "rsvps");

            migrationBuilder.DropTable(
                name: "invitation_lines");

            migrationBuilder.DropIndex(
                name: "ix_rsvps_invitation_line_id",
                table: "rsvps");

            migrationBuilder.DropColumn(
                name: "AceitouTermos",
                table: "rsvps");

            migrationBuilder.DropColumn(
                name: "IdentificacaoNoConvite",
                table: "rsvps");

            migrationBuilder.DropColumn(
                name: "InvitationLineId",
                table: "rsvps");

            migrationBuilder.AddColumn<string>(
                name: "Observacoes",
                table: "rsvps",
                type: "character varying(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Nome",
                table: "rsvps",
                type: "character varying(100)",
                maxLength: 100,
                nullable: false,
                defaultValue: "");

            migrationBuilder.CreateIndex(
                name: "ix_rsvps_email",
                table: "rsvps",
                column: "Email",
                unique: true);
        }
    }
}
