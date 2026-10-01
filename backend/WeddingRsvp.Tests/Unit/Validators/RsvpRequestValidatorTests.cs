using FluentValidation.TestHelper;
using WeddingRsvp.Api.Models;
using WeddingRsvp.Api.Validators;
using Xunit;

namespace WeddingRsvp.Tests.Unit.Validators;

/// <summary>
/// Testes do RsvpRequestValidator com o novo contrato:
/// IdentificacaoNoConvite, sem QtdAdultos (derivado do Admin), crianças 0-10.
/// </summary>
public class RsvpRequestValidatorTests
{
    private readonly RsvpRequestValidator _validator;

    public RsvpRequestValidatorTests()
    {
        _validator = new RsvpRequestValidator();
    }

    // ── IdentificacaoNoConvite ─────────────────────────────────────────────────

    [Theory]
    [InlineData("")]
    public void Identificacao_Vazia_DeveSerInvalido(string identificacao)
    {
        var model = CreateModel(identificacao: identificacao);
        var result = _validator.TestValidate(model);
        result.ShouldHaveValidationErrorFor(x => x.IdentificacaoNoConvite);
    }

    [Theory]
    [InlineData("Jorge e Amanda")]
    [InlineData("Antônio Souza")]
    [InlineData("Maria-José")]
    public void Identificacao_Valida_DevePassar(string identificacao)
    {
        var model = CreateModel(identificacao: identificacao);
        var result = _validator.TestValidate(model);
        result.ShouldNotHaveValidationErrorFor(x => x.IdentificacaoNoConvite);
    }

    [Theory]
    [InlineData("<script>alert('xss')</script>")]
    [InlineData("<b>nome</b>")]
    public void Identificacao_ComHTML_DeveSerInvalido(string identificacao)
    {
        var model = CreateModel(identificacao: identificacao);
        var result = _validator.TestValidate(model);
        result.ShouldHaveValidationErrorFor(x => x.IdentificacaoNoConvite);
    }

    // ── Email ─────────────────────────────────────────────────────────────────

    [Theory]
    [InlineData("naoeemail")]
    [InlineData("emailsemarroba.com")]
    [InlineData("")]
    public void Email_Invalido_DeveSerInvalido(string email)
    {
        var model = CreateModel(email: email);
        var result = _validator.TestValidate(model);
        result.ShouldHaveValidationErrorFor(x => x.Email);
    }

    [Fact]
    public void Email_Valido_DeveSerValido()
    {
        var model = CreateModel(email: "teste@example.com");
        var result = _validator.TestValidate(model);
        result.ShouldNotHaveValidationErrorFor(x => x.Email);
    }

    // ── Telefone ──────────────────────────────────────────────────────────────

    [Theory]
    [InlineData("abc")]
    [InlineData("123")]
    [InlineData("(11) 91234-567890")] // Longo demais
    public void Telefone_Invalido_DeveSerInvalido(string telefone)
    {
        var model = CreateModel(telefone: telefone);
        var result = _validator.TestValidate(model);
        result.ShouldHaveValidationErrorFor(x => x.Telefone);
    }

    [Theory]
    [InlineData("(11) 91234-5678")]
    [InlineData("11912345678")]
    [InlineData("11 912345678")]
    public void Telefone_FormatoValido_DeveSerValido(string telefone)
    {
        var model = CreateModel(telefone: telefone);
        var result = _validator.TestValidate(model);
        result.ShouldNotHaveValidationErrorFor(x => x.Telefone);
    }

    // ── QtdCriancas ───────────────────────────────────────────────────────────

    [Theory]
    [InlineData(-1)]
    [InlineData(11)] // Máximo é 10 conforme planejamento
    public void QtdCriancas_ForaDoRange_DeveSerInvalido(int qtd)
    {
        var model = CreateModel(qtdCriancas: qtd, vaiComparecer: true);
        var result = _validator.TestValidate(model);
        result.ShouldHaveValidationErrorFor(x => x.QtdCriancas);
    }

    [Theory]
    [InlineData(0)]
    [InlineData(1)]
    [InlineData(10)]
    public void QtdCriancas_DentroDoRange_DeveSerValido(int qtd)
    {
        var model = CreateModel(qtdCriancas: qtd, vaiComparecer: true);
        var result = _validator.TestValidate(model);
        result.ShouldNotHaveValidationErrorFor(x => x.QtdCriancas);
    }

    [Fact]
    public void Recusa_QtdCriancasDeveSer0()
    {
        var model = CreateModel(qtdCriancas: 1, vaiComparecer: false);
        var result = _validator.TestValidate(model);
        result.ShouldHaveValidationErrorFor(x => x.QtdCriancas);
    }

    // ── AceitouTermos ─────────────────────────────────────────────────────────

    [Fact]
    public void AceitouTermos_False_DeveSerInvalido()
    {
        var model = CreateModel(aceitouTermos: false);
        var result = _validator.TestValidate(model);
        result.ShouldHaveValidationErrorFor(x => x.AceitouTermos);
    }

    private RsvpRequest CreateModel(
        string identificacao = "Jorge e Amanda",
        string email = "teste@example.com",
        string telefone = "11987654321",
        bool vaiComparecer = true,
        int qtdCriancas = 0,
        bool aceitouTermos = true)
    {
        return new RsvpRequest(identificacao, email, telefone, vaiComparecer, qtdCriancas, aceitouTermos);
    }
}
