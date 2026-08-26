namespace WeddingRsvp.Api.Models;

/// <summary>
/// DTO de entrada para confirmação de presença.
/// Desacoplado da entidade Rsvp para prevenir Over-Posting Attacks:
/// o cliente não pode injetar campos como Id, CriadoEm, etc.
/// </summary>
public record RsvpRequest(
    string Nome,
    string Email,
    string Telefone,
    bool VaiComparecer,
    int QtdAdultos,
    int QtdCriancas,
    string? Observacoes
);
