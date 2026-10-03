namespace WeddingRsvp.Api.Models;

/// <summary>
/// DTO para cadastrar uma nova linha de convite.
/// </summary>
public record CreateInvitationLineRequest(
    /// <summary>Identificação exatamente como será impressa no convite.</summary>
    string IdentificacaoNoConvite,
    /// <summary>Quantidade de adultos representados (mínimo 1).</summary>
    int QuantidadeAdultos,
    /// <summary>Quantidade de crianças permitidas para esta linha.</summary>
    int QuantidadeCriancas = 0
);

/// <summary>
/// DTO para editar uma linha de convite existente.
/// </summary>
public record UpdateInvitationLineRequest(
    /// <summary>Nova identificação do convite.</summary>
    string? IdentificacaoNoConvite,
    /// <summary>Nova quantidade de adultos.</summary>
    int? QuantidadeAdultos,
    /// <summary>Nova quantidade de crianças permitidas.</summary>
    int? QuantidadeCriancas,
    /// <summary>Estado ativo/inativo.</summary>
    bool? Ativo,
    /// <summary>Motivo da edição (obrigatório para auditoria).</summary>
    string Motivo
);
