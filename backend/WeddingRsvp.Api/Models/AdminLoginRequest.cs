namespace WeddingRsvp.Api.Models;

/// <summary>
/// DTO de entrada para autenticação do administrador.
/// </summary>
public record AdminLoginRequest(string Username, string Password);
