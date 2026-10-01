# Site do casamento

Flutter Web, API ASP.NET Core e PostgreSQL. A lista pública de presentes lê o catálogo da API; `/admin` permite administrar produtos e acompanhar presença e pagamentos.

## Configuração

Para ativar pagamentos reais, siga [Ativação do Asaas em produção](PRODUCAO_ASAAS.md).

1. Copie `.env.example` para `.env` e preencha os valores. Não publique `.env`.
2. Use `PUBLIC_BASE_URL` e `ALLOWED_ORIGIN` com a URL HTTPS pública do site. A porta `127.0.0.1:8080` do Compose deve ser publicada por um proxy com TLS. Encaminhe também `/api/` e mantenha o webhook acessível ao Asaas.
3. Configure `ASAAS_ENVIRONMENT=Sandbox` com uma chave Sandbox. Use `Production` apenas com a chave de produção correspondente. Cadastre no Asaas o webhook `https://seu-dominio/api/webhooks/asaas` com o mesmo token de `ASAAS_WEBHOOK_AUTH_TOKEN` e os eventos de checkout e pagamento necessários.
4. Defina `SUPERADMIN_EMAIL` e uma senha inicial forte em `SUPERADMIN_INITIAL_PASSWORD` antes do primeiro início. No primeiro acesso a `/admin`, troque a senha e configure o aplicativo autenticador. Guarde os códigos de recuperação. Após criar o usuário, a senha inicial pode ser removida do ambiente.
5. Execute `docker compose up --build`. As migrations são aplicadas pela API na inicialização. Os volumes `postgres_data`, `gift_images` e `protection_keys` preservam banco, fotos e sessões entre reinícios.

Para executar a API fora do Compose, forneça `ConnectionStrings__DefaultConnection`, `AllowedOrigin`, `SUPERADMIN_EMAIL`, `SUPERADMIN_INITIAL_PASSWORD` no primeiro início, `Asaas__ApiKey`, `Asaas__WebhookAuthToken` e `PublicBaseUrl` por variáveis de ambiente ou secret manager. Os arquivos `appsettings*.json` não contêm credenciais.

## Presentes e pagamentos

Em `/admin/produtos/novo`, informe o valor usado para gerar o checkout Asaas e o estoque disponível. O valor aparece na lista pública, no carrinho e no resumo; a quantidade continua restrita ao admin. O catálogo público recebe apenas `soldOut`. Quando o estoque chega a zero, o cartão público fica cinza e mostra **Presenteado**. O campo de estoque vazio significa sem limite; produtos cadastrados antes da migration começam sem limite até serem editados. O identificador da URL é gerado automaticamente se ficar vazio. O link de referência é opcional, fica no admin e não substitui o checkout Asaas.

Ao confirmar o carrinho, a API recalcula os valores a partir do banco, reserva o estoque e cria um checkout Asaas de 60 minutos para Pix ou cartão. O convidado vê o valor novamente na página segura do Asaas antes de pagar. O retorno ao site consulta o status do pedido, mas a confirmação financeira vem dos webhooks. Os eventos `CHECKOUT_CANCELED` e `CHECKOUT_EXPIRED` liberam a reserva. O webhook precisa estar ativo e acessível para que o estoque volte automaticamente após cancelamento ou expiração. Uma falha incerta ao criar o checkout mantém a reserva e requer conferência administrativa para evitar uma segunda cobrança.

No admin, a seção Pagamentos mostra os pedidos desde a geração do checkout, inclusive pendentes e confirmados apenas por eventos de checkout. Quando a cobrança real chega por webhook, ela substitui a entrada do pedido sem duplicar valores. A arrecadação confirmada soma `Confirmed` e `Received`; valores recebidos mostram somente `Received`, sem confundir confirmação com dinheiro disponível. Detalhes de taxas e método permanecem sem informação até chegar a cobrança. A sincronização com Asaas está disponível apenas para cobranças com ID real. Painel e financeiro atualizam a cada 30 segundos enquanto visíveis, ao voltar à aba e pelo botão Atualizar. Cadastre no Asaas os eventos de checkout `CHECKOUT_PAID`, `CHECKOUT_CANCELED`, `CHECKOUT_EXPIRED` e os eventos de pagamento usados para confirmação e conciliação.

Se uma entrega do webhook retornar **401**, confira o token de autenticação configurado no webhook do **Sandbox** e `ASAAS_WEBHOOK_AUTH_TOKEN` no ambiente publicado: devem ser iguais, e esse token não é a chave da API. O Compose o mapeia para `Asaas__WebhookAuthToken`. Recrie o serviço da API após alterar o ambiente; depois reative a fila se interrompida e reenvie os eventos rejeitados no Asaas. Não é necessário refazer a compra. HTTP 200 significa evento aceito para processamento; confira o histórico de eventos no financeiro para verificar processamento ou falha. Cobranças do Checkout podem ter `externalReference` nulo: a conciliação também usa `payment.checkoutSession`, validando a tentativa e o valor antes de atualizar o pedido.


Não é preciso cadastrar os presentes, criar links de pagamento ou gerar cobranças manualmente no Asaas: o site envia nome, quantidade e valor de cada item quando o convidado inicia o pagamento. Na conta Asaas, crie uma chave de API para o ambiente usado e configure um webhook ativo com URL `https://seu-dominio/api/webhooks/asaas`, token próprio de 32 a 255 caracteres (diferente da chave de API), versão 3 e eventos de checkout e pagamento. No `.env`, informe `ASAAS_API_KEY`, `ASAAS_WEBHOOK_AUTH_TOKEN`, `ASAAS_ENVIRONMENT` e `PUBLIC_BASE_URL`; o token deve ser igual ao cadastrado no webhook. Teste primeiro no Sandbox.

Chaves recentes do Asaas começam com `$aact_hmlg_` (Sandbox) ou `$aact_prod_` (produção). No `.env` usado pelo Docker Compose, coloque o valor completo entre aspas simples, por exemplo `ASAAS_API_KEY='$aact_hmlg_...'`, para preservar o `$` literal. Não duplique o `$` no `.env`. O `__` aparece apenas nos nomes `Asaas__ApiKey` e `Asaas__WebhookAuthToken` do `docker-compose.yml`, que mapeiam para a configuração .NET. Após alterar o `.env`, recrie o serviço da API para aplicar os novos valores. Se a criação do checkout retornar HTTP 502, consulte os logs da API pelo identificador da tentativa antes de repetir o pedido; o checkout anterior pode ter sido criado mesmo sem resposta recebida.

## Verificação

```sh
dotnet test backend/WeddingRsvp.Tests/WeddingRsvp.Tests.csproj
flutter test
flutter build web
```
