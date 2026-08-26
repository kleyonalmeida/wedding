using FluentValidation;
using WeddingRsvp.Api.Models;

namespace WeddingRsvp.Api.Validators;

/// <summary>
/// Valida os dados de entrada do RSVP com regras estritas de segurança.
/// Rejeita payloads maliciosos ANTES de qualquer interação com o banco de dados.
/// </summary>
public class RsvpRequestValidator : AbstractValidator<RsvpRequest>
{
    public RsvpRequestValidator()
    {
        // ── Nome ──────────────────────────────────────────────────────────────
        // \p{L} cobre letras Unicode (inclui acentos: ã, ç, é, etc.)
        // Rejeita qualquer caractere especial, números, HTML ou SQL injection
        RuleFor(x => x.Nome)
            .NotEmpty().WithMessage("Nome é obrigatório.")
            .MaximumLength(100).WithMessage("Nome deve ter no máximo 100 caracteres.")
            .Matches(@"^[\p{L}\s]+$")
            .WithMessage("Nome deve conter apenas letras e espaços.");

        // ── Email ─────────────────────────────────────────────────────────────
        // RFC 5321 limita endereços a 254 caracteres no total
        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Email é obrigatório.")
            .MaximumLength(254).WithMessage("Email deve ter no máximo 254 caracteres.")
            .EmailAddress().WithMessage("Formato de e-mail inválido.");

        // ── Telefone ──────────────────────────────────────────────────────────
        // Aceita: (11) 91234-5678 | 11 91234-5678 | 11912345678 | (11)912345678
        // Suporta celular (9 dígitos) e fixo (8 dígitos)
        RuleFor(x => x.Telefone)
            .NotEmpty().WithMessage("Telefone é obrigatório.")
            .MaximumLength(20).WithMessage("Telefone deve ter no máximo 20 caracteres.")
            .Matches(@"^\(?\d{2}\)?[\s\-]?\d{4,5}[\s\-]?\d{4}$")
            .WithMessage("Telefone inválido. Use o formato (11) 91234-5678.");

        // ── QtdAdultos ────────────────────────────────────────────────────────
        // Mínimo 1: pelo menos o próprio convidado
        RuleFor(x => x.QtdAdultos)
            .InclusiveBetween(1, 20)
            .WithMessage("Quantidade de adultos deve ser entre 1 e 20.");

        // ── QtdCriancas ───────────────────────────────────────────────────────
        RuleFor(x => x.QtdCriancas)
            .InclusiveBetween(0, 15)
            .WithMessage("Quantidade de crianças deve ser entre 0 e 15.");

        // ── Observações ───────────────────────────────────────────────────────
        // Campo opcional — limita tamanho para evitar abuso de memória
        // Aceita texto livre, mas o campo é salvo como texto (não renderizado como HTML)
        RuleFor(x => x.Observacoes)
            .MaximumLength(500)
            .WithMessage("Observações deve ter no máximo 500 caracteres.")
            .When(x => x.Observacoes is not null);
    }
}
