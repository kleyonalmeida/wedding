namespace WeddingRsvp.Api.Entities;

/// <summary>
/// Linha de convite cadastrada pelo Admin.
/// Representa exatamente o texto impresso no convite — "Jorge e Amanda" é uma única linha.
/// A quantidade de adultos é definida pelo Admin; o cliente não pode alterá-la.
/// </summary>
public class InvitationLine
{
    /// <summary>Identificador único (não sequencial para evitar IDOR).</summary>
    public Guid Id { get; set; }

    /// <summary>
    /// Identificação exatamente como impressa no convite.
    /// Exemplo: "Jorge e Amanda", "Antônio Souza", "Família Rodrigues".
    /// </summary>
    public string IdentificacaoNoConvite { get; set; } = string.Empty;

    /// <summary>
    /// Identificação normalizada para comparação (NFC, sem espaços nas pontas).
    /// Índice único — impede duas linhas ativas com a mesma grafia.
    /// </summary>
    public string IdentificacaoNormalizada { get; set; } = string.Empty;

    /// <summary>
    /// Quantidade de adultos representados por esta linha (mínimo 1).
    /// Definida pelo Admin; a API usa este valor, não o informado pelo cliente.
    /// </summary>
    public int QuantidadeAdultos { get; set; }

    /// <summary>
    /// Quantidade limite de crianças representadas por esta linha (0 ou mais).
    /// Definida pelo Admin.
    /// </summary>
    public int QuantidadeCriancas { get; set; }

    /// <summary>Se false, a linha não aceita novas respostas.</summary>
    public bool Ativo { get; set; } = true;

    /// <summary>Timestamp UTC de criação.</summary>
    public DateTimeOffset CriadoEm { get; set; }

    /// <summary>Timestamp UTC da última atualização.</summary>
    public DateTimeOffset? AtualizadoEm { get; set; }

    /// <summary>RSVP vinculado a esta linha (no máximo um ativo).</summary>
    public Rsvp? Rsvp { get; set; }
}
