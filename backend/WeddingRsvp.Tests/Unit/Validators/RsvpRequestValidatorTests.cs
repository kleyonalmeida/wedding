using FluentValidation.TestHelper;
using WeddingRsvp.Api.Models;
using WeddingRsvp.Api.Validators;
using Xunit;

namespace WeddingRsvp.Tests.Unit.Validators;

public class RsvpRequestValidatorTests
{
    private readonly RsvpRequestValidator _validator;

    public RsvpRequestValidatorTests()
    {
        _validator = new RsvpRequestValidator();
    }

    [Theory]
    [InlineData("")]
    [InlineData(null)]
    public void Nome_Vazio_DeveSerInvalido(string nome)
    {
        var model = CreateModel(nome: nome);
        var result = _validator.TestValidate(model);
        result.ShouldHaveValidationErrorFor(x => x.Nome);
    }

    [Theory]
    [InlineData("Ana Lima")]
    [InlineData("João Conceição")]
    public void Nome_SomenteLetras_DeveSerValido(string nome)
    {
        var model = CreateModel(nome: nome);
        var result = _validator.TestValidate(model);
        result.ShouldNotHaveValidationErrorFor(x => x.Nome);
    }

    [Theory]
    [InlineData("Ana123")]
    [InlineData("Ana!")]
    [InlineData("<script>alert('1')</script>")]
    public void Nome_CaracteresInvalidos_DeveSerInvalido(string nome)
    {
        var model = CreateModel(nome: nome);
        var result = _validator.TestValidate(model);
        result.ShouldHaveValidationErrorFor(x => x.Nome);
    }

    [Fact]
    public void Nome_MuitoLongo_DeveSerInvalido()
    {
        var model = CreateModel(nome: new string('a', 101));
        var result = _validator.TestValidate(model);
        result.ShouldHaveValidationErrorFor(x => x.Nome);
    }

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

    [Theory]
    [InlineData(0)]
    [InlineData(21)]
    public void QtdAdultos_ForaDoRange_DeveSerInvalido(int qtd)
    {
        var model = CreateModel(qtdAdultos: qtd);
        var result = _validator.TestValidate(model);
        result.ShouldHaveValidationErrorFor(x => x.QtdAdultos);
    }

    [Theory]
    [InlineData(-1)]
    [InlineData(16)]
    public void QtdCriancas_ForaDoRange_DeveSerInvalido(int qtd)
    {
        var model = CreateModel(qtdCriancas: qtd);
        var result = _validator.TestValidate(model);
        result.ShouldHaveValidationErrorFor(x => x.QtdCriancas);
    }

    [Fact]
    public void Observacoes_Nula_DeveSerValida()
    {
        var model = CreateModel(observacoes: null);
        var result = _validator.TestValidate(model);
        result.ShouldNotHaveValidationErrorFor(x => x.Observacoes);
    }

    [Fact]
    public void Observacoes_MuitoLonga_DeveSerInvalida()
    {
        var model = CreateModel(observacoes: new string('a', 501));
        var result = _validator.TestValidate(model);
        result.ShouldHaveValidationErrorFor(x => x.Observacoes);
    }

    private RsvpRequest CreateModel(
        string nome = "Teste Silva",
        string email = "teste@example.com",
        string telefone = "11987654321",
        bool vaiComparecer = true,
        int qtdAdultos = 2,
        int qtdCriancas = 0,
        string? observacoes = null)
    {
        return new RsvpRequest(nome, email, telefone, vaiComparecer, qtdAdultos, qtdCriancas, observacoes);
    }
}
