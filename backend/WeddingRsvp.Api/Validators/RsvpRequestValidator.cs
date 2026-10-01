using FluentValidation;
using WeddingRsvp.Api.Models;

namespace WeddingRsvp.Api.Validators;

/// <summary>
/// Valida os dados de entrada do RSVP por QR code genérico.
/// O cliente informa identificação, contatos, presença e crianças.
/// Adultos são derivados do Admin — não validados aqui.
/// </summary>
public class RsvpRequestValidator : AbstractValidator<RsvpRequest>
{
    public RsvpRequestValidator()
    {
        // ── IdentificacaoNoConvite ─────────────────────────────────────────────
        // Aceita qualquer texto que possa aparecer em um convite impresso.
        // Rejeita apenas caracteres de controle e tags HTML (XSS).
        // A verificação semântica (se a linha existe) é feita na camada de negócio.
        RuleFor(x => x.IdentificacaoNoConvite)
            .NotEmpty().WithMessage("A identificação do convite é obrigatória.")
            .MaximumLength(200).WithMessage("Identificação deve ter no máximo 200 caracteres.")
            .Must(s => s is not null && !s.Any(char.IsControl) && !s.Contains('<') && !s.Contains('>'))
            .WithMessage("Identificação contém caracteres inválidos.");


        // ── Email ─────────────────────────────────────────────────────────────
        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("E-mail é obrigatório.")
            .MaximumLength(254).WithMessage("E-mail deve ter no máximo 254 caracteres.")
            .EmailAddress().WithMessage("Formato de e-mail inválido.");

        // ── Telefone ──────────────────────────────────────────────────────────
        RuleFor(x => x.Telefone)
            .NotEmpty().WithMessage("Telefone é obrigatório.")
            .MaximumLength(20).WithMessage("Telefone deve ter no máximo 20 caracteres.")
            .Matches(@"^\(?\d{2}\)?[\s\-]?\d{4,5}[\s\-]?\d{4}$")
            .WithMessage("Telefone inválido. Use o formato (11) 91234-5678.");

        // ── QtdCriancas ───────────────────────────────────────────────────────
        // Máximo 10 conforme planejamento; 0 quando recusa.
        RuleFor(x => x.QtdCriancas)
            .InclusiveBetween(0, 10)
            .WithMessage("Quantidade de crianças deve ser entre 0 e 10.")
            .When(x => x.VaiComparecer);

        RuleFor(x => x.QtdCriancas)
            .Equal(0)
            .WithMessage("Quantidade de crianças deve ser 0 quando não vai comparecer.")
            .When(x => !x.VaiComparecer);

        // ── AceitouTermos ─────────────────────────────────────────────────────
        RuleFor(x => x.AceitouTermos)
            .Equal(true)
            .WithMessage("É necessário aceitar os termos de uso.");
    }
}
