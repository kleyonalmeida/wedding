using FluentValidation;

namespace WeddingRsvp.Api.Filters;

/// <summary>
/// Filtro genérico de validação para Minimal APIs.
/// Intercepta a requisição ANTES do handler, valida o DTO com FluentValidation
/// e retorna 400 com os erros detalhados caso inválido.
/// </summary>
/// <typeparam name="T">Tipo do DTO a ser validado.</typeparam>
public class ValidationFilter<T> : IEndpointFilter
{
    private readonly IValidator<T> _validator;

    public ValidationFilter(IValidator<T> validator)
    {
        _validator = validator;
    }

    public async ValueTask<object?> InvokeAsync(
        EndpointFilterInvocationContext context,
        EndpointFilterDelegate next)
    {
        // Tenta encontrar o argumento do tipo T na lista de argumentos do endpoint
        var argument = context.Arguments.OfType<T>().FirstOrDefault();

        if (argument is null)
        {
            return Results.BadRequest(new
            {
                errors = new[] { "Payload ausente ou com formato inválido." }
            });
        }

        var result = await _validator.ValidateAsync(argument);

        if (!result.IsValid)
        {
            // Agrupa erros por campo para uma resposta amigável ao frontend
            var errors = result.Errors
                .GroupBy(e => e.PropertyName)
                .ToDictionary(
                    g => g.Key,
                    g => g.Select(e => e.ErrorMessage).ToArray());

            // Retorna 400 com o formato padrão ProblemDetails (RFC 7807)
            return Results.ValidationProblem(errors);
        }

        return await next(context);
    }
}
