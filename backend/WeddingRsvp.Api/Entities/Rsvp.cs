namespace WeddingRsvp.Api.Entities;

/// <summary>
/// Entidade que representa a confirmação de presença vinculada a uma linha de convite.
/// </summary>
public class Rsvp
{
    /// <summary>Identificador único gerado pelo servidor (não sequencial para evitar IDOR).</summary>
    public Guid Id { get; set; }

    /// <summary>
    /// Identificação digitada pelo convidado exatamente como está no convite.
    /// Exemplo: "Jorge e Amanda". Nunca separar em pessoas individuais.
    /// </summary>
    public string IdentificacaoNoConvite { get; set; } = string.Empty;

    /// <summary>FK para a linha de convite cadastrada pelo Admin.</summary>
    public Guid InvitationLineId { get; set; }

    /// <summary>Navegação para a linha de convite.</summary>
    public InvitationLine? InvitationLine { get; set; }

    /// <summary>E-mail de contato — não é mais a chave de unicidade.</summary>
    public string Email { get; set; } = string.Empty;

    /// <summary>Telefone em formato brasileiro.</summary>
    public string Telefone { get; set; } = string.Empty;

    /// <summary>Indica se a linha confirmou presença.</summary>
    public bool VaiComparecer { get; set; }

    /// <summary>
    /// Quantidade de adultos — derivada de InvitationLine.QuantidadeAdultos se VaiComparecer = true,
    /// ou zero se recusou. O cliente não informa este valor.
    /// </summary>
    public int QtdAdultos { get; set; }

    /// <summary>
    /// Quantidade de crianças declarada pelo convidado (0–10).
    /// Só relevante quando VaiComparecer = true.
    /// </summary>
    public int QtdCriancas { get; set; }

    /// <summary>O convidado aceitou os termos de uso.</summary>
    public bool AceitouTermos { get; set; }

    /// <summary>Timestamp UTC de criação — gerado pelo servidor, nunca pelo cliente.</summary>
    public DateTimeOffset CriadoEm { get; set; }

}
