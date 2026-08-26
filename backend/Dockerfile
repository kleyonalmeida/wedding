# ════════════════════════════════════════════════════════════════════════════
# STAGE 1 — BUILD
# Usa a imagem SDK completa apenas para compilar e publicar.
# Resultado: binários otimizados prontos para produção.
# ════════════════════════════════════════════════════════════════════════════
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copia apenas o .csproj primeiro para aproveitar cache de layers do Docker.
# As dependências só são re-baixadas se o .csproj mudar.
COPY WeddingRsvp.Api/WeddingRsvp.Api.csproj WeddingRsvp.Api/
RUN dotnet restore WeddingRsvp.Api/WeddingRsvp.Api.csproj --no-cache

# Copia o restante do código-fonte e publica
COPY WeddingRsvp.Api/ WeddingRsvp.Api/
WORKDIR /src/WeddingRsvp.Api
RUN dotnet publish -c Release -o /app/publish \
    --no-restore \
    --no-self-contained

# ════════════════════════════════════════════════════════════════════════════
# STAGE 2 — RUNTIME
# Imagem mínima de runtime (~200MB vs ~800MB do SDK).
# Não contém compilador, ferramentas de build ou código-fonte.
# ════════════════════════════════════════════════════════════════════════════
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app

# Cria usuário não-root para reduzir superfície de ataque.
# O processo da API não rodará como root mesmo dentro do container.
RUN groupadd -r appgroup \
 && useradd -r -g appgroup -s /sbin/nologin appuser


# Copia os artefatos publicados do stage de build
COPY --from=build /app/publish .

# Transfere propriedade dos arquivos para o usuário não-root
RUN chown -R appuser:appgroup /app

USER appuser

# Porta HTTP interna — o Nginx externo fará o proxy e o TLS
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production

ENTRYPOINT ["dotnet", "WeddingRsvp.Api.dll"]
