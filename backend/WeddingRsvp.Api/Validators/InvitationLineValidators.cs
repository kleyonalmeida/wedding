using FluentValidation;
using WeddingRsvp.Api.Models;

namespace WeddingRsvp.Api.Validators;

/// <summary>
/// Valida criação de linhas de convite pelo Admin.
/// </summary>
public class CreateInvitationLineRequestValidator : AbstractValidator<CreateInvitationLineRequest>
{
    public CreateInvitationLineRequestValidator()
    {
        RuleFor(x => x.IdentificacaoNoConvite)
            .NotEmpty().WithMessage("A identificação do convite é obrigatória.")
            .MaximumLength(200).WithMessage("Identificação deve ter no máximo 200 caracteres.")
            .Must(s => s is not null && !s.Any(char.IsControl) && !s.Contains('<') && !s.Contains('>'))
            .WithMessage("Identificação contém caracteres inválidos.");

        RuleFor(x => x.QuantidadeAdultos)
            .GreaterThanOrEqualTo(1)
            .WithMessage("Quantidade de adultos deve ser no mínimo 1.");
    }
}

/// <summary>
/// Valida edição de linhas de convite pelo Admin.
/// </summary>
public class UpdateInvitationLineRequestValidator : AbstractValidator<UpdateInvitationLineRequest>
{
    public UpdateInvitationLineRequestValidator()
    {
        RuleFor(x => x.Motivo)
            .NotEmpty().WithMessage("Motivo é obrigatório para auditoria.")
            .MaximumLength(500);

        When(x => x.QuantidadeAdultos.HasValue, () =>
        {
            RuleFor(x => x.QuantidadeAdultos!.Value)
                .GreaterThanOrEqualTo(1)
                .WithMessage("Quantidade de adultos deve ser no mínimo 1.");
        });
    }
}
