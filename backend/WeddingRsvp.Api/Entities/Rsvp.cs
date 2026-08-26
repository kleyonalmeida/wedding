namespace WeddingRsvp.Api.Entities;

/// <summary>
/// Entidade que representa a confirmação de presença de um convidado.
/// </summary>
public class Rsvp
{
    /// <summary>Identificador único gerado pelo servidor (não sequencial para evitar IDOR).</summary>
    public Guid Id { get; set; }

    /// <summary>Nome completo do convidado — apenas letras e espaços.</summary>
    public string Nome { get; set; } = string.Empty;

    /// <summary>E-mail válido — usado como identificador único para evitar duplicatas.</summary>
    public string Email { get; set; } = string.Empty;

    /// <summary>Telefone em formato brasileiro.</summary>
    public string Telefone { get; set; } = string.Empty;

    /// <summary>Indica se o convidado confirmou presença.</summary>
    public bool VaiComparecer { get; set; }

    /// <summary>Quantidade de adultos (mínimo 1 se confirmado).</summary>
    public int QtdAdultos { get; set; }

    /// <summary>Quantidade de crianças (pode ser zero).</summary>
    public int QtdCriancas { get; set; }

    /// <summary>Observações opcionais — texto livre sanitizado.</summary>
    public string? Observacoes { get; set; }

    /// <summary>Timestamp UTC de criação — gerado pelo servidor, nunca pelo cliente.</summary>
    public DateTimeOffset CriadoEm { get; set; }
}
