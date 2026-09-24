# Site do casamento

Flutter Web, API ASP.NET Core e PostgreSQL. A lista pública de presentes lê o catálogo da API; `/admin` permite administrar produtos e acompanhar presença e pagamentos.

## Configuração

1. Copie `.env.example` para `.env` e preencha os valores. Não publique `.env`.
2. Use `PUBLIC_BASE_URL` e `ALLOWED_ORIGIN` com a URL HTTPS pública do site. A porta `127.0.0.1:8080` do Compose deve ser publicada por um proxy com TLS. Encaminhe também `/api/` e mantenha o webhook acessível ao Asaas.
3. Configure `ASAAS_ENVIRONMENT=Sandbox` com uma chave Sandbox. Use `Production` apenas com a chave de produção correspondente. Cadastre no Asaas o webhook `https://seu-dominio/api/webhooks/asaas` com o mesmo token de `ASAAS_WEBHOOK_AUTH_TOKEN` e os eventos de checkout e pagamento necessários.
4. Defina `SUPERADMIN_EMAIL` e uma senha inicial forte em `SUPERADMIN_INITIAL_PASSWORD` antes do primeiro início. No primeiro acesso a `/admin`, troque a senha e configure o aplicativo autenticador. Guarde os códigos de recuperação. Após criar o usuário, a senha inicial pode ser removida do ambiente.
5. Execute `docker compose up --build`. As migrations são aplicadas pela API na inicialização. Os volumes `postgres_data`, `gift_images` e `protection_keys` preservam banco, fotos e sessões entre reinícios.

Para executar a API fora do Compose, forneça `ConnectionStrings__DefaultConnection`, `AllowedOrigin`, `SUPERADMIN_EMAIL`, `SUPERADMIN_INITIAL_PASSWORD` no primeiro início, `Asaas__ApiKey`, `Asaas__WebhookAuthToken` e `PublicBaseUrl` por variáveis de ambiente ou secret manager. Os arquivos `appsettings*.json` não contêm credenciais.

## Verificação

```sh
dotnet test backend/WeddingRsvp.Tests/WeddingRsvp.Tests.csproj
flutter test
flutter build web
```
