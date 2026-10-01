namespace WeddingRsvp.Api.Models;

/// <summary>
/// DTO de entrada para confirmação de presença via QR code genérico.
/// O cliente informa a identificação exata do convite, presença e crianças.
/// A quantidade de adultos é derivada do Admin — o cliente não informa.
/// </summary>
public record RsvpRequest(
    /// <summary>Identificação exatamente como impressa no convite. Exemplo: "Jorge e Amanda".</summary>
    string IdentificacaoNoConvite,
    /// <summary>E-mail de contato.</summary>
    string Email,
    /// <summary>Telefone em formato brasileiro.</summary>
    string Telefone,
    /// <summary>Confirma ou recusa presença.</summary>
    bool VaiComparecer,
    /// <summary>Quantidade de crianças (0–10). Só válido quando VaiComparecer = true.</summary>
    int QtdCriancas,
    /// <summary>O convidado aceitou os termos de uso.</summary>
    bool AceitouTermos
);
