# Planejamento de integração Asaas

Data: 08/09/2026. Status: planejamento; nenhuma sprint executada por este documento.

## 1. Objetivo e dor que será resolvida

Permitir que convidados escolham presentes no site, paguem por Pix ou cartão e que os noivos acompanhem o resultado e as mensagens sem conferir pagamentos manualmente no WhatsApp.

Hoje, o Flutter possui catálogo fictício, carrinho e formulário. `checkout_dialog.dart` apenas abre o WhatsApp e limpa o carrinho. A API ASP.NET Core tem RSVP e autenticação administrativa; o PostgreSQL não registra presentes, pedidos ou pagamentos. Portanto, escolher um presente hoje não gera uma cobrança nem comprova recebimento.

| Dor atual | Entrega planejada |
| --- | --- |
| Finalização depende de conversa manual | Checkout hospedado do Asaas vinculado a um pedido |
| Preços existem apenas no navegador | Catálogo no backend e total calculado pelo servidor |
| Não se sabe quem pagou e qual mensagem enviou | Pedido com itens, remetente, mensagem e histórico de pagamento |
| Retorno ao site pode ser confundido com pagamento | Confirmação financeira por webhook autenticado |
| Clique duplo ou falha de rede pode duplicar cobrança | Idempotência persistida e tratamento de resultado incerto |
| Carrinho desaparece antes de confirmar pagamento | Persistência local e recuperação da jornada |
| Não existe visão administrativa financeira | Consulta protegida de pedidos e valores confirmados/disponíveis |

Premissa de produto a validar na sprint 0: presentes são contribuições financeiras aos noivos, sem entrega física. Se forem produtos físicos, revisar estoque, entrega e cancelamento antes de implementar. Escopo inicial: BRL, Pix e cartão à vista, um recebedor, sem assinatura, split, parcelamento ou formulário próprio de cartão. Estorno operacional inicialmente pelo painel Asaas, com atualização no site por eventos/conciliação.

## 2. Regras obrigatórias de execução

1. **TDD sempre antes do código de implementação.** Para cada comportamento, escrever o teste, executá-lo e comprovar falha pela ausência do comportamento (RED); implementar o mínimo para passar (GREEN); refatorar mantendo os testes verdes (REFACTOR).
2. Não escrever toda a funcionalidade para só depois criar testes. Contratos mínimos podem ser declarados para compilar o teste; sua implementação deve vir depois do RED.
3. Alterações em configuração, Docker, migrations e scripts também precisam de uma verificação executável definida antes da mudança. Texto documental usa revisão de consistência; não exige teste artificial.
4. **A sprint N+1 só pode começar após todos os testes e builds da sprint N passarem sem erros no mesmo estado do código.** Isso inclui regressão acumulada do frontend, backend e imagens Docker.
5. Falha preexistente, teste ignorado para esconder problema, falta de dependência, indisponibilidade do ambiente ou teste não executado não equivalem a aprovação. Corrigir ou deixar a sprint bloqueada, registrando a causa.
6. Não avançar com “corrigiremos depois”. Não iniciar arquivos de implementação da próxima sprint durante o bloqueio. Cadastro e coleta de dados externos podem continuar, sem antecipar implementação.
7. Testes automatizados comuns não devem depender do Asaas real. Usar respostas simuladas e PostgreSQL de teste isolado. Homologação Sandbox é uma etapa adicional, nunca substitui os testes.
8. Não usar EF InMemory para comprovar transações, índices únicos ou concorrência: testar essas garantias com PostgreSQL real isolado.
9. Não versionar chave Asaas, token do webhook, dados reais de cartão ou dados pessoais de convidados. Nunca colocar credenciais no Flutter, nas URLs ou nos logs.
10. Preservar alterações já existentes na árvore de trabalho. Este plano não autoriza desfazê-las.

### Evidência obrigatória de encerramento

Criar `docs/asaas/evidencias/sprint-NN.md` ao encerrar cada sprint, de 00 a 07, com a estrutura:

```markdown
# Sprint NN — evidências
## Escopo entregue
## Estado validado
Commit ou identificação reproduzível do diff, data e versões das ferramentas.
## TDD
Caso | comando RED | falha esperada observada | comando GREEN | resultado
## Gate acumulado
Comando | código de saída | resumo | localização do log sanitizado
## Aceite específico da sprint
## Pendências e bloqueios
## Decisão
APROVADA ou BLOQUEADA, com justificativa.
```

O RED não pode ser somente falha de rede, SDK ausente ou erro de sintaxe. Depois de qualquer alteração relevante, executar novamente o gate sobre o estado final.

### Gate acumulado, executado da raiz

```bash
dotnet restore backend/WeddingRsvp.Tests/WeddingRsvp.Tests.csproj
dotnet build backend/WeddingRsvp.Tests/WeddingRsvp.Tests.csproj -c Release --no-restore
dotnet test backend/WeddingRsvp.Tests/WeddingRsvp.Tests.csproj -c Release --no-build
dotnet publish backend/WeddingRsvp.Api/WeddingRsvp.Api.csproj -c Release --no-restore -o /tmp/wedding-asaas-publish
flutter pub get
flutter analyze
flutter test
flutter build web --release
docker compose build api web
```

Todos devem sair com código 0, sem erros; testes de aceite obrigatórios não podem estar pulados. A partir da sprint 1, o teste .NET deverá iniciar seu PostgreSQL isolado via Testcontainers, exigindo Docker disponível. A partir da sprint 6, incluir também a suíte de navegador descrita nela. Comandos e dependências devem ser fixados na sprint 0 e refletidos no CI. Builds/testes completos serão executados nas sprints de implementação; a criação deste documento não afirma que passaram.

## 3. Arquitetura e contratos internos

```text
Flutter → POST /api/gift-orders → PostgreSQL: pedido + tentativa
                                  ↓
                            Asaas: checkout
                                  ↓
Flutter ← URL validada ← ID do checkout persistido
   ↓
Checkout hospedado → retorno ao site → consulta do pedido na nossa API
Asaas → webhook → caixa de eventos persistida → processamento → pedido atualizado
Admin autenticado → consulta financeira na nossa API
```

### 3.1. Ponto exato de entrada no carrinho e resumo existentes

Revisão do código: carrinho e resumo já estão implementados e serão reaproveitados. A parte nova começa na ação final do resumo. Não criar outro carrinho, outro resumo ou uma segunda coleta de nome/mensagem.

| Etapa existente | Arquivo e ponto de entrada | Mudança planejada |
| --- | --- | --- |
| Botão PRESENTEAR adiciona item e abre carrinho | `lib/features/gifts/presentation/widgets/gift_product_grid.dart`, `_handleGiftPressed` | Manter inclusão do item e abertura de `CartDialog`. |
| Botão flutuante abre o mesmo carrinho | `lib/features/gifts/presentation/pages/gifts_page.dart`, `FloatingActionButton.extended.onPressed` | Manter acesso ao carrinho compartilhado. |
| Botão Finalizar compra abre resumo | `lib/features/gifts/presentation/widgets/cart_dialog.dart`, `onCheckout` | Continuar abrindo `CheckoutDialog`; ainda não criar cobrança aqui. |
| Resumo mostra itens, total, nome e mensagem | `lib/features/gifts/presentation/widgets/checkout_dialog.dart`, `_buildSummarySection` e `_buildFormSection` | Reaproveitar apresentação e formulário, adaptando valores para centavos. |
| Botão Concluir compra executa `_submit` | `lib/features/gifts/presentation/widgets/checkout_dialog.dart`, `_buildFooter` | Renomear para **Ir para pagamento**. Este é o ponto que passará a chamar o controller e nossa API. |
| Voltar para o carrinho | `CheckoutDialog.onBack`, fornecido pelos dois pontos de abertura | Hoje apenas fecha o resumo. Ajustar os dois callbacks para reabrir o carrinho existente, preservando itens, nome e mensagem durante a jornada. |

O `_submit` atual monta texto, abre `wa.me` e limpa o carrinho. Substituir esse trecho por `CheckoutController.submit()`, responsável por persistir a tentativa local, chamar `PaymentRepository.createOrder()` e tratar o resultado. Esses nomes de métodos passam a fazer parte do contrato da sprint 4.

### 3.2. Onde o convidado escolhe o método e informa os dados

**Decisão deste plano: escolha de Pix/cartão e dados de cobrança ficam na página hospedada do Asaas, aberta depois do resumo atual.** O nosso site coleta apenas nome de quem presenteia e mensagem aos noivos. O nome da mensagem não deve ser presumido como nome legal do titular do pagamento.

Não haverá `payment_method_page.dart` nem formulário de cartão no Flutter neste escopo. O backend habilita Pix e cartão no checkout e deixa o Asaas solicitar os dados do pagador. A documentação permite criar o checkout sem `customer`/`customerData`, para coleta no próprio checkout. Campos efetivamente exigidos, como identificação, contato e dados do titular, deverão ser conferidos no Sandbox; não fixar obrigatoriedade de CPF/endereço no nosso resumo sem essa validação. Fonte: [Asaas Checkout — métodos e dados do cliente](https://docs.asaas.com/docs/introdu%C3%A7%C3%A3o-1).

```text
NOSSO SITE                         NOSSA API                    ASAAS
Carrinho existente
  → Finalizar compra
Resumo existente + nome/mensagem
  → Ir para pagamento
  → CheckoutController.submit()
  → PaymentRepository.createOrder()
                       → POST /api/gift-orders
                         valida itens/total
                         grava pedido/tentativa
                         cria checkout --------------------→ API Asaas
                         persiste ID/URL ←------------------ ID
  ← orderId + checkoutUrl
  → salva vínculo local e abre URL ------------------------→ Página Asaas
                                                            escolhe Pix/cartão
                                                            informa dados
                                                            efetua pagamento
                         webhook ←-------------------------- resultado
                         valida evento e atualiza pedido
Retorno /pagamento/retorno
  → GET /api/gift-orders/{id}
  ← situação financeira registrada
  → exibe pendente, pago ou falha
```

O retorno do navegador pode ocorrer antes ou depois do webhook. O desenho representa responsabilidades, não uma garantia da ordem desses dois acontecimentos.

### 3.3. Criar checkout, processar pagamento e confirmar são etapas distintas

1. **Ao clicar em Ir para pagamento:** nossa API valida o pedido e solicita a criação do checkout. Receber ID/URL significa apenas que existe uma sessão para pagar. Não significa pagamento aprovado.
2. **Na página Asaas:** o provedor coleta os dados, apresenta o meio escolhido e processa o pagamento. Dados de cartão não passam por `PaymentRepository` ou pela nossa API neste modelo.
3. **Pelo webhook:** o Asaas notifica nossa API; ela autentica, correlaciona checkout/cobrança/pedido, consulta detalhes externos se necessário e grava a situação financeira. Nenhum endpoint público permite ao Flutter definir `Paid`.
4. **Na página de retorno:** Flutter consulta nossa API com o token do pedido. Se o evento ainda não chegou, mostra “Aguardando confirmação do pagamento”; não exibe sucesso com base em parâmetros de URL.

Abrir a URL somente após persistir ID/token/chave localmente. Se a URL não abrir, oferecer **Abrir pagamento** reutilizando a mesma sessão. Se a API retornar 202, mostrar “Preparando pagamento”, consultar o pedido e só habilitar abertura quando houver URL. Se o preço oficial divergir do resumo, exigir nova revisão do convidado antes do redirecionamento; nunca prosseguir silenciosamente com outro total. Preservar carrinho e mensagem em falha; limpar somente os itens correspondentes ao pedido confirmado pela API.

Se futuramente a escolha do método e o formulário precisarem ficar dentro do site, revisar o escopo antes da implementação: isso exige outra decisão de integração e contratos/testes próprios. O plano atual entrega a próxima etapa após o resumo através do checkout hospedado.

### Convenções para os arquivos

- Caminhos nas tabelas abaixo são relativos à raiz, mesmo quando agrupados por prefixo.
- Backend: namespace `WeddingRsvp.Api.<pasta>`; uma classe/record/enum público principal por arquivo, nullable habilitado, dependências por construtor e `CancellationToken` nos métodos assíncronos.
- Testes .NET: namespace `WeddingRsvp.Tests.<pasta>`, xUnit, Arrange/Act/Assert; nome `Metodo_Cenario_ResultadoEsperado`.
- Flutter: arquivos `snake_case.dart`, modelos imutáveis com `fromJson`/`toJson` quando houver transporte ou persistência; controllers recebem interfaces no construtor.
- Testes Flutter espelham o caminho em `lib/`, substituindo-o por `test/` e usando sufixo `_test.dart`.
- Alterar arquivos existentes listados, sem criar cópias paralelas. Só criar os arquivos de cada sprint quando chegar nela e após o teste correspondente.

### Modelo persistido proposto

Todos os valores monetários internos são `long`/`bigint` em centavos; Flutter usa `int`. Converter para `decimal` em reais somente no adaptador Asaas. Datas em UTC. Fixar limites de quantidade e total nos validadores, com operações aritméticas verificadas contra overflow.

| Arquivo em `backend/WeddingRsvp.Api/Entities/` | Estrutura mínima |
| --- | --- |
| `Gift.cs` | `Id: Guid`, `Name: string(150)`, `Description: string(1000)`, `ImageUrl: string(2048)`, `Category: string(100)`, `PriceCents: long`, `Active: bool`, `CreatedAtUtc`, `UpdatedAtUtc` |
| `GiftOrder.cs` | `Id: Guid`, `SenderName: string(100)`, `Message: string(1000)?`, `Currency: string(3)=BRL`, `TotalCents: long`, `Status: OrderStatus`, `AccessTokenHash: string(64)`, `CreatedAtUtc`, `UpdatedAtUtc`, `Version: long` para concorrência |
| `GiftOrderItem.cs` | `Id: Guid`, `OrderId: Guid`, `GiftId: Guid`, `NameSnapshot: string(150)`, `UnitPriceCents: long`, `Quantity: int`; FK para pedido e presente |
| `PaymentAttempt.cs` | `Id: Guid`, `OrderId: Guid`, `IdempotencyKey: Guid` único, `RequestHash: string(64)`, `ProviderCheckoutId: string(100)?` único quando preenchido, `CheckoutUrl: string(2048)?`, `Status: PaymentAttemptStatus`, `ExpiresAtUtc?`, `CreatedAtUtc`, `UpdatedAtUtc`, `Version: long` |
| `PaymentRecord.cs` | `Id: Guid`, `OrderId: Guid`, `AttemptId: Guid`, `ProviderPaymentId: string(100)` único, `GrossCents: long`, `NetCents: long?`, `RefundedCents: long`, `Status: PaymentStatus`, `ConfirmedAtUtc?`, `ReceivedAtUtc?`, `UpdatedAtUtc` |
| `WebhookEvent.cs` | `Id: Guid`, `ProviderEventId: string(150)` único, `EventType: string(100)`, `ProviderObjectId: string(100)?`, `PayloadJson: string`, `Status: WebhookProcessingStatus`, `Attempts: int`, `ReceivedAtUtc`, `ProcessedAtUtc?`, `NextAttemptAtUtc?`, `LastErrorCode: string(100)?` |

Aplicar restrições de valores não negativos, quantidades positivas, moeda BRL, FKs e índices no PostgreSQL. Evitar exclusão em cascata de registros financeiros. O payload de webhook pode conter dados pessoais: acesso restrito, logs sem corpo e prazo de retenção definido antes de produção.

Enums em `backend/WeddingRsvp.Api/Payments/`:

- `OrderStatus.cs`: `Pending`, `Paid`, `Expired`, `Canceled`, `PartiallyRefunded`, `Refunded`, `Disputed`.
- `PaymentAttemptStatus.cs`: `Creating`, `Pending`, `CreationUnknown`, `Failed`, `Paid`, `Expired`, `Canceled`.
- `PaymentStatus.cs`: `Pending`, `Confirmed`, `Received`, `PartiallyRefunded`, `Refunded`, `Disputed`.
- `WebhookProcessingStatus.cs`: `Pending`, `Processing`, `Processed`, `Retry`, `Failed`.

Transições devem ser validadas; evento atrasado de expiração não pode apagar um pagamento confirmado. `Confirmed` não significa saldo disponível; esse dado vem da situação financeira da cobrança. Um pedido pode ter mais de uma tentativa; impedir nova tentativa enquanto a anterior estiver ativa ou com resultado incerto. Pagamento tardio exige conciliação, nunca perda do registro.

### Contratos HTTP da aplicação

Estes são contratos propostos para nossa API, não cópias do contrato externo Asaas.

| Endpoint | Contrato e acesso |
| --- | --- |
| `GET /api/gifts` | Público; lista `{id,name,description,imageUrl,category,priceCents,active}`. Filtros existentes podem operar localmente sobre essa lista inicialmente. |
| `POST /api/gift-orders` | Público com limite por cliente; recebe o JSON abaixo; usa `X-Order-Token` gerado no navegador com fonte criptográfica e persistido antes da chamada. |
| `GET /api/gift-orders/{id}` | Exige `X-Order-Token`; retorna somente `{orderId,status,totalCents,currency,checkoutUrl,expiresAtUtc}`. Sem dados de outros convidados. |
| `POST /api/webhooks/asaas` | Sem JWT administrativo; valida token específico do Asaas e persiste o evento antes de responder 2xx. |
| `GET /api/admin/gift-orders` | JWT administrativo existente; paginação, filtro por status e intervalo de datas; lista de pedidos e totais. |
| `GET /api/admin/gift-orders/{id}` | JWT; itens, remetente, mensagem, tentativas e registros financeiros, sem segredos. |

```json
{
  "idempotencyKey": "UUID-gerado-uma-vez-por-tentativa",
  "senderName": "Convidado",
  "message": "Felicidades!",
  "items": [{ "giftId": "UUID-do-presente", "quantity": 1 }]
}
```

Resposta de criação: `{orderId,status,totalCents,currency,checkoutUrl,expiresAtUtc}`. `checkoutUrl` pode ser nula enquanto a criação é resolvida. Retornar 201 para nova criação concluída, 200 para repetição equivalente e 202 para processamento/resultado incerto; 400 para validação, 409 para mesma chave com conteúdo diferente e 429 para limite de chamadas. Erros externos definitivos devem ser traduzidos sem vazar payloads/segredos.

`X-Order-Token`: pelo menos 32 bytes aleatórios codificados em base64url; guardar apenas SHA-256 no banco. Vincular a primeira criação ao hash e exigir o mesmo token em repetições. Não transportar token em query string. Não usar UUID do pedido como autorização. Configurar CORS para esse header se frontend e API estiverem em origens diferentes.

## 4. Sprint 0 — pré-requisitos, cadastro e baseline

**Dor:** iniciar integração sobre builds quebrados ou conta inadequada impede validar as entregas seguintes.

### Ações externas

1. Criar conta em `https://www.asaas.com/` no nome do recebedor; completar validação documental/cadastral.
2. Confirmar com atendimento a aceitação de contribuições/presentes de casamento e registrar a resposta sem documentos pessoais no repositório.
3. Conferir taxas efetivas, fim de promoção, prazos de recebimento, regras de cartão e estorno. Decidir quem absorve as taxas; proposta inicial: noivos recebem o líquido.
4. Criar conta separada em `https://sandbox.asaas.com/`; gerar chave pela interface web de Integrações com usuário administrador.
5. Definir domínio público HTTPS e ambiente de homologação. Não cadastrar webhook para localhost inacessível ao Asaas.
6. Validar catálogo real, textos que explicam contribuição sem entrega, política de dados e prazo de retenção.

### Arquivos e ordem

| Ação | Caminho | Estrutura/responsabilidade |
| --- | --- | --- |
| Criar primeiro | `docs/asaas/pre-requisitos.md` | Seções: recebedor; elegibilidade; meios; taxas/prazos; domínio; ambiente; retenção; pendências; responsáveis. Sem credenciais. |
| Criar | `scripts/verify-asaas-sprint.sh` | Bash com `set -euo pipefail`; executar o gate em ordem, parar na primeira falha, sem imprimir `.env` e sem ignorar códigos de saída. Testar parada por comando simulado com erro antes de implementar o script. |
| Criar | `.github/workflows/asaas-quality.yml` | Jobs de backend/PostgreSQL, Flutter e Docker; versões fixadas; gate final dependente de todos; rodar em PR/push, sem secrets reais de pagamento. |
| Alterar se necessário | `backend/WeddingRsvp.Api/WeddingRsvp.Api.csproj`, `backend/WeddingRsvp.Tests/WeddingRsvp.Tests.csproj`, `Dockerfile`, `backend/Dockerfile`, `pubspec.yaml` | Corrigir somente incompatibilidades comprovadas pelo baseline. Há versões EF diferentes entre API e testes; validar compatibilidade em vez de presumir funcionamento. |
| Criar ao encerrar | `docs/asaas/evidencias/sprint-00.md` | Template de evidências definido acima. |

**Testes antes das correções:** executar suítes existentes; para defeito comportamental, adicionar regressão antes da correção. Validar falha do script ao simular um comando malsucedido e sucesso quando todos passam.

**Aceite:** gate completo verde, ambiente reproduzível, Sandbox acessível e decisões de produto registradas. Cadastro produtivo pendente pode continuar em paralelo, mas bloqueia a sprint 7; dúvidas que alterem o modelo de negócio bloqueiam a sprint 1.

## 5. Sprint 1 — catálogo oficial e persistência de pedidos

**Dor:** preços manipuláveis no navegador e ausência de histórico persistente.

### Criar primeiro os testes

Prefixo `backend/WeddingRsvp.Tests/`:

| Arquivo | Casos obrigatórios |
| --- | --- |
| `Fixtures/PostgresFixture.cs` | Container PostgreSQL 17 isolado; migrations; reset entre casos; nunca acessar conexão de produção. |
| `Fixtures/PaymentApiFactory.cs` | `WebApplicationFactory<Program>` com banco isolado e configuração de teste por instância. |
| `Integration/GiftCatalogTests.cs` | Só listar ativos; valores em centavos; contrato estável. |
| `Integration/PaymentPersistenceTests.cs` | FKs, índices únicos, dinheiro inválido, rollback e preservação de RSVP. |

### Depois implementar

| Ação | Caminho | Estrutura/responsabilidade |
| --- | --- | --- |
| Criar | `backend/WeddingRsvp.Api/Entities/{Gift,GiftOrder,GiftOrderItem,PaymentAttempt,PaymentRecord,WebhookEvent}.cs` | Um arquivo para cada entidade da seção 3, com os campos ali definidos. |
| Criar | `backend/WeddingRsvp.Api/Payments/{OrderStatus,PaymentAttemptStatus,PaymentStatus,WebhookProcessingStatus}.cs` | Um arquivo por enum da seção 3. |
| Criar | `backend/WeddingRsvp.Api/Data/Configurations/{Gift,GiftOrder,GiftOrderItem,PaymentAttempt,PaymentRecord,WebhookEvent}Configuration.cs` | Uma classe `IEntityTypeConfiguration<T>` por entidade; tipos, limites, índices e constraints. |
| Criar | `backend/WeddingRsvp.Api/Data/GiftCatalogSeed.cs` | IDs estáveis, catálogo real aprovado; carga idempotente, sem sobrescrever preço alterado em produção. |
| Criar | `backend/WeddingRsvp.Api/Models/GiftResponse.cs` | Record do contrato público de catálogo. |
| Criar | `backend/WeddingRsvp.Api/Endpoints/GiftEndpoints.cs` | `MapGiftEndpoints`; GET com projeção para DTO. |
| Alterar | `backend/WeddingRsvp.Api/Data/AppDbContext.cs` | Adicionar DbSets e aplicar configurações mantendo RSVP. |
| Alterar | `backend/WeddingRsvp.Api/Program.cs` | Registrar catálogo; permitir substituição isolada de banco em testes, evitando flag estática compartilhada para as novas suítes. |
| Alterar | `backend/WeddingRsvp.Tests/WeddingRsvp.Tests.csproj` | Adicionar Testcontainers PostgreSQL em versão compatível fixada. |
| Gerar | `backend/WeddingRsvp.Api/Migrations/<timestamp>_AddGiftPayments.cs` e `.Designer.cs` | Migration gerada pelo EF após testar expectativa do schema; timestamp é gerado, não literal. Atualizar `AppDbContextModelSnapshot.cs`. |

Notação `{A,B}.cs` significa criar `A.cs` e `B.cs`, não um arquivo com chaves no nome.

**Aceite:** schema aplicado em banco vazio e atualizado a partir do schema RSVP; preços oficiais consultáveis; constraints comprovadas no PostgreSQL; gate acumulado verde e `docs/asaas/evidencias/sprint-01.md` aprovado.

## 6. Sprint 2 — criação de checkout no backend

**Dor:** não existe cobrança real vinculada à escolha do convidado.

### Testes primeiro

Prefixo `backend/WeddingRsvp.Tests/`:

- `Unit/Payments/GiftOrderServiceTests.cs`: total pelo catálogo, quantidades inválidas, presente inativo, nome vazio, mensagem longa, overflow, token inválido e duplicidade.
- `Unit/Payments/AsaasCheckoutClientTests.cs`: headers, BRL decimal correto, ID retornado, URL do checkout por ambiente, erro HTTP, timeout e resposta malformada.
- `Unit/Payments/AsaasOptionsTests.cs`: desabilitado sem chave; habilitado exige configuração válida; impedir mistura de ambientes.
- `Integration/GiftOrderEndpointsTests.cs`: 201/200/202/400/409/429, token de consulta e concorrência real com mesma chave.
- `Fakes/AsaasHttpMessageHandler.cs`: respostas programadas, captura sanitizada de requests e contagem de chamadas, sem rede externa.

### Arquivos de implementação

Prefixo `backend/WeddingRsvp.Api/`:

| Arquivo novo | Estrutura/responsabilidade |
| --- | --- |
| `Options/AsaasOptions.cs` | `Enabled`, `Environment`, `BaseUrl`, `ApiKey`, `WebhookToken`, `PublicSiteUrl`, `CheckoutMinutesToExpire`, `TimeoutSeconds`; validação na inicialização quando habilitado. |
| `Payments/IAsaasCheckoutClient.cs` | Contrato assíncrono de criação/consulta suportada pelo provedor, recebendo modelo interno e `CancellationToken`. |
| `Payments/AsaasCheckoutClient.cs` | Cliente HTTP tipado; traduz contratos internos para externos, autenticação, timeout e erros; sem regra de pedido. |
| `Payments/AsaasCheckoutRequest.cs` | DTO externo com itens, tipos de cobrança e callbacks conforme documentação validada. |
| `Payments/AsaasCheckoutResponse.cs` | DTO externo mínimo; ID obrigatório. Não presumir que criação retorne URL pronta. |
| `Payments/AsaasProviderException.cs` | Erro normalizado com código seguro e indicação de resultado incerto; sem credenciais/corpo bruto. |
| `Payments/IGiftOrderService.cs` | Métodos `CreateAsync` e `GetStatusAsync` com DTOs internos. |
| `Payments/GiftOrderService.cs` | Valida catálogo, calcula total, grava pedido/tentativa, chama adaptador e persiste resultado. |
| `Payments/OrderAccessTokenService.cs` | Validação do formato e tamanho, hash e comparação segura do token. |
| `Models/CreateGiftOrderRequest.cs` | Record com `IdempotencyKey`, `SenderName`, `Message`, lista de `GiftOrderItemRequest`. |
| `Models/GiftOrderItemRequest.cs` | Record com `GiftId` e `Quantity`. |
| `Models/GiftOrderResponse.cs` | Record da resposta de criação/consulta definida na seção 3. |
| `Validators/CreateGiftOrderRequestValidator.cs` | FluentValidation dos limites e itens repetidos, com política explícita de rejeição. |
| `Endpoints/GiftOrderEndpoints.cs` | Mapear POST/GET, token e rate limit; delegar negócio ao serviço. |

Alterar `Program.cs` para DI, options e política por cliente. O limitador atual não deve ser copiado presumindo particionamento por IP: configurar particionamento e proxies confiáveis explicitamente. Alterar `.env.example`, `docker-compose.yml` e `backend/WeddingRsvp.Api/appsettings.json` com configuração abaixo; adicionar apenas exemplos vazios de segredos.

```dotenv
Asaas__Enabled=false
Asaas__Environment=Sandbox
Asaas__BaseUrl=https://api-sandbox.asaas.com/v3/
Asaas__ApiKey=
Asaas__WebhookToken=
Asaas__PublicSiteUrl=https://homologacao.seu-dominio.com
Asaas__CheckoutMinutesToExpire=60
Asaas__TimeoutSeconds=20
```

O Compose existente injeta `.env` no serviço API; usar esses nomes .NET diretamente e documentar o escopo. Garantir que segredo não seja incluído no contexto/imagem de frontend. Produção usa `https://api.asaas.com/v3/`. Enviar `access_token` e User-Agent próprio. Fonte: [autenticação Asaas](https://docs.asaas.com/docs/authentication).

**Regra crítica:** índice único e hash do request impedem repetição local, mas não garantem idempotência do provedor. Persistir tentativa antes da chamada externa; não manter transação SQL aberta durante HTTP. Se houver timeout após possível criação, marcar `CreationUnknown`, não repetir POST automaticamente. Resolver por referência/consulta suportada ou conferência operacional antes de permitir nova criação. Não presumir header de idempotência externo sem suporte documentado.

**Aceite:** checkout simulado vinculado ao pedido, total inviolável e repetição concorrente sem chamadas duplicadas; caminho incerto comprovado; gate verde e `docs/asaas/evidencias/sprint-02.md` aprovado. Interface pública de pagamento ainda desabilitada.

## 7. Sprint 3 — webhooks e confirmação confiável

**Dor:** marcar presente como pago incorretamente ou perder confirmação quando o convidado fecha a página.

### Testes primeiro

Prefixo `backend/WeddingRsvp.Tests/`:

- `Unit/Payments/PaymentStateMachineTests.cs`: pagamento, expiração, cancelamento, recebimento, estorno parcial/total, disputa e evento atrasado.
- `Integration/AsaasWebhookEndpointsTests.cs`: token ausente/incorreto, evento válido, corpo inválido, limite de tamanho, evento repetido, tipo desconhecido e falha de banco antes do ACK.
- `Integration/WebhookProcessingTests.cs`: concorrência, reinício após persistência, retry, evento antes do vínculo local, identificador/valor/moeda divergente e erro persistente.
- `Fixtures/Asaas/checkout-paid.json`, `payment-received.json`, `payment-refunded.json`: payloads de exemplo oficiais sanitizados; validar campos/eventos atuais antes de fixar fixtures.

### Arquivos de implementação

Prefixo `backend/WeddingRsvp.Api/`:

| Arquivo novo | Estrutura/responsabilidade |
| --- | --- |
| `Models/AsaasWebhookEnvelope.cs` | ID, tipo e objetos necessários; tolerar campos adicionais. |
| `Endpoints/AsaasWebhookEndpoints.cs` | Validar `asaas-access-token`, limitar corpo, persistir inbox com unicidade e responder 2xx só após commit. Duplicata persistida retorna 2xx. |
| `Payments/AsaasWebhookProcessor.cs` | Correlacionar evento/checkout/cobrança/pedido e aplicar resultado transacionalmente. |
| `Payments/PaymentStateMachine.cs` | Transições internas e projeção da situação do pedido; não confiar na ordem de chegada. |
| `Payments/AsaasPaymentClient.cs` | Consultas de cobranças documentadas para validar detalhes financeiros quando evento não trouxer os dados suficientes. |
| `Payments/IAsaasPaymentClient.cs` | Interface para consulta de situação e dados financeiros, substituível em teste. |
| `Workers/AsaasWebhookWorker.cs` | Buscar eventos pendentes com claim/lease recuperável, processar, retry com atraso e marcar falha após limite. |

Alterar `Program.cs` para registrar endpoint e worker; completar `WebhookEvent`/configuração se o mecanismo de lease exigir `LockedUntilUtc` e `LockedBy`, gerando migration própria `<timestamp>_AddWebhookProcessingLease.cs` e `.Designer.cs` e atualizando snapshot.

Criar `docs/asaas/eventos.md` com tabela: evento externo, objeto/ID de correlação, consulta complementar, transição interna, duplicidade, exemplo sanitizado. Cobrir eventos de checkout e cobrança: pagar checkout não é o mesmo que liquidar saldo. Validar mapeamento de estorno/disputa com a referência vigente.

### Configuração externa nesta sprint

Publicar endpoint de homologação HTTPS; em Integrações cadastrar webhook e token exclusivo, diferente da chave API. Selecionar os eventos efetivamente tratados e testar recebimento/logs. O Asaas envia o token no header `asaas-access-token`; validá-lo antes do processamento. Fonte: [configuração de webhook](https://docs.asaas.com/docs/criar-novo-webhook-pela-aplicacao-web).

**Aceite:** apenas eventos autenticados e conciliados alteram finanças; duplicidade não dobra valores; falha transitória não perde evento; pagamento tardio é tratado; gate verde e `docs/asaas/evidencias/sprint-03.md` aprovado.

## 8. Sprint 4 — jornada Flutter integrada

**Dor:** convidado continua indo ao WhatsApp, perde o carrinho e não acompanha a conclusão.

### Testes primeiro

Prefixo `test/`:

- `features/gifts/data/repositories/gift_repository_test.dart`: catálogo HTTP, conversão de centavos e falhas.
- `features/gifts/data/repositories/payment_repository_test.dart`: contrato, token, idempotência e timeout.
- `features/gifts/presentation/controllers/checkout_controller_test.dart`: submissão única, retomada, consulta limitada e estados de erro/pendência/pago.
- `features/gifts/presentation/controllers/cart_controller_test.dart`: persistência, cálculo inteiro e limpeza apenas do carrinho correspondente ao pedido pago.
- `features/gifts/presentation/widgets/checkout_dialog_test.dart`: resumo existente preservado; Ir para pagamento chama criação somente após validação; carregamento, falha ao abrir checkout e repetição reutilizando sessão; preservação de nome/mensagem ao voltar; revisão obrigatória se total oficial mudar.
- `features/gifts/presentation/widgets/gift_product_grid_test.dart`: entrada pelo PRESENTEAR abre carrinho e resumo sem criar cobrança antecipadamente; Voltar reabre carrinho.
- `features/gifts/presentation/pages/gifts_page_test.dart`: entrada pelo botão flutuante segue o mesmo fluxo, com a mesma instância de carrinho, controller e dados do formulário.
- `features/gifts/presentation/pages/payment_return_page_test.dart`: query de sucesso falsa não confirma pagamento; cancelamento conserva itens; falta de token não expõe pedido.

### Arquivos de implementação

| Ação | Caminho | Estrutura/responsabilidade |
| --- | --- | --- |
| Criar | `lib/core/network/api_client.dart` | Cliente HTTP injetável; base URL, JSON, headers e erros normalizados. |
| Criar | `lib/features/gifts/data/models/payment_order.dart` | Modelo do contrato de pedido: ID, status, centavos, URL e expiração. |
| Criar | `lib/features/gifts/data/repositories/payment_repository.dart` | Criar/consultar pedido; mesma chave/token nas repetições; sem chamar Asaas diretamente. |
| Criar | `lib/features/gifts/data/storage/checkout_storage.dart` | Persistir ID, chave, token, snapshot e data por pedido; restauração e remoção controlada. Evitar persistir mensagem/dados pessoais sem necessidade. |
| Criar | `lib/features/gifts/presentation/controllers/checkout_controller.dart` | Método `submit()`; nome/mensagem preservados durante navegação; estados `idle`, `submitting`, `reviewRequired`, `preparingPayment`, `awaitingPayment`, `paid`, `failed`, `expired`, `canceled`; recursos injetáveis e descarte de timers. `reviewRequired` impede redirecionar se total oficial divergir; `preparingPayment` trata 202 sem URL. |
| Criar | `lib/features/gifts/presentation/pages/payment_return_page.dart` | Ler ID da rota, recuperar token local e consultar API; renderizar pendência/sucesso/erro; nunca confiar no callback financeiro. |
| Alterar | `lib/features/gifts/data/models/gift_product.dart` | Substituir preços financeiros `double` por centavos; adaptar contrato e apresentação existente. |
| Alterar | `lib/features/gifts/data/repositories/gift_repository.dart` | Remover mocks e carregar catálogo da API. |
| Alterar | `lib/features/gifts/presentation/controllers/gift_catalog_controller.dart` | Injeção de repository, carregamento/erro e filtros compatíveis. |
| Alterar | `lib/features/gifts/presentation/controllers/cart_controller.dart` | Total inteiro e armazenamento; preservar itens novos adicionados após criação de pedido. |
| Alterar | `lib/features/gifts/presentation/widgets/checkout_dialog.dart` | Manter resumo/formulário; `_submit` delega a `CheckoutController.submit()`; botão Ir para pagamento substitui Concluir compra; abrir URL recebida, bloquear clique duplo e permitir reabrir sessão em falha. Método e dados de cobrança serão coletados no Asaas, conforme seção 3.2. |
| Alterar | `lib/features/gifts/presentation/widgets/cart_dialog.dart`, `gift_product_card.dart`, `gift_product_grid.dart` | Ajustar dinheiro, remoção de parcelas fictícias e passagem de dependências. Os três ficam na mesma pasta `widgets/`. |
| Alterar | `lib/features/gifts/presentation/pages/gifts_page.dart`, `lib/app.dart` | Composição dos serviços e rota `/pagamento/retorno?orderId=...`. |
| Alterar | `pubspec.yaml`, `pubspec.lock` | Adicionar cliente HTTP e armazenamento compatíveis com Flutter Web, versões fixadas no lockfile. |

Consulta no retorno deve chamar nossa API por tempo limitado, com intervalo e parada ao desmontar a página; não fazer polling contínuo ao Asaas. Fechar o navegador não impede confirmação pelo webhook. Se o armazenamento local for perdido, mostrar orientação sem revelar dados; suporte consulta pelo painel autenticado.

**Aceite:** ambas as entradas existentes (PRESENTEAR e botão flutuante) → carrinho → resumo → Ir para pagamento → Asaas → retorno funcionam; carrinho e resumo reaproveitados; Voltar reabre carrinho sem perder formulário; criação ocorre apenas na ação final do resumo; escolha de método/dados acontece no Asaas e é homologada na sprint 6; nenhum sucesso financeiro antes da confirmação da API; nenhum segredo Asaas no bundle; testes antigos adaptados a contratos reais; gate verde e `docs/asaas/evidencias/sprint-04.md` aprovado.

## 9. Sprint 5 — acompanhamento administrativo e conciliação

**Dor:** noivos não têm uma visão confiável de contribuições, mensagens e saldo, nem recuperação de eventos perdidos.

### Testes primeiro

- `backend/WeddingRsvp.Tests/Integration/AdminGiftOrderEndpointsTests.cs`: sem JWT recebe 401, paginação, filtros, detalhe e nenhum segredo nas respostas.
- `backend/WeddingRsvp.Tests/Integration/PaymentReconciliationTests.cs`: evento perdido, tentativa incerta, estorno, pagamento tardio e divergência; não recriar checkout automaticamente.
- `test/features/admin/presentation/pages/admin_gift_orders_page_test.dart`: login, sessão expirada, lista, detalhe, filtros e valores distintos confirmado/disponível.

### Arquivos de implementação

| Arquivo novo | Estrutura/responsabilidade |
| --- | --- |
| `backend/WeddingRsvp.Api/Endpoints/AdminGiftOrderEndpoints.cs` | Grupo protegido pela autenticação administrativa existente. |
| `backend/WeddingRsvp.Api/Models/AdminGiftOrderResponse.cs` | DTO de lista/detalhe com itens, mensagem, datas e situação financeira; nenhuma chave ou token. |
| `backend/WeddingRsvp.Api/Models/AdminGiftOrderQuery.cs` | Página, tamanho máximo, status e intervalo de datas validados. |
| `backend/WeddingRsvp.Api/Payments/PaymentReconciliationService.cs` | Consultar casos pendentes conhecidos com limites e aplicar a mesma máquina de estados. |
| `backend/WeddingRsvp.Api/Workers/PaymentReconciliationWorker.cs` | Agendamento com exclusão concorrente, atraso e observabilidade; casos não resolvíveis vão para ação operacional. |
| `lib/features/admin/data/repositories/admin_gift_order_repository.dart` | Login pelo endpoint existente e consultas com Bearer; sessão em memória, encerrada em 401. |
| `lib/features/admin/data/models/admin_gift_order.dart` | DTO de lista/detalhe, centavos e datas. |
| `lib/features/admin/presentation/controllers/admin_gift_orders_controller.dart` | Sessão, listagem paginada, detalhe, filtros e carregamento/erro. |
| `lib/features/admin/presentation/pages/admin_login_page.dart` | Formulário de acesso sem credenciais fixas. |
| `lib/features/admin/presentation/pages/admin_gift_orders_page.dart` | Lista, detalhe, mensagens e totais conforme situação financeira. |
| `docs/asaas/operacao.md` | Diagnóstico de webhook, filas, resultado incerto, conciliação, estorno pelo painel e monitoramento; sem comandos financeiros automáticos. |

Alterar `Program.cs` e `lib/app.dart` para registros e rotas `/admin/login` e `/admin/presentes`. Acrescentar testes de controller/repository em caminhos espelhados antes de implementá-los.

**Aceite:** API bloqueia acesso não autenticado independentemente da rota Flutter; distinguir total pago, estornado e líquido recebido conhecido, sem chamar isso de saldo bancário atual; conciliação recupera casos demonstráveis; gate verde e `docs/asaas/evidencias/sprint-05.md` aprovado.

## 10. Sprint 6 — homologação completa e resiliência

**Dor:** testes isolados não demonstram funcionamento conjunto no navegador, proxy, banco e provedor.

### Testes e arquivos a criar antes das correções

| Caminho | Estrutura/responsabilidade |
| --- | --- |
| `e2e/package.json`, `e2e/package-lock.json` | Dependência Playwright fixada e script `test`; somente infraestrutura de testes. |
| `e2e/playwright.config.ts` | Base URL de homologação local isolada, timeout, captura em falha e execução serial quando necessário. |
| `e2e/tests/gift-payment.spec.ts` | Catálogo → carrinho → API real de teste → checkout simulado → webhook → retorno confirmado. |
| `e2e/tests/gift-payment-recovery.spec.ts` | Refresh, cancelamento, consulta sem token, clique duplo e atraso de confirmação. |
| `backend/WeddingRsvp.Tests/Integration/PaymentFailureRecoveryTests.cs` | Reinício entre etapas, concorrência de eventos e queda de banco sem perda silenciosa. |
| `docker-compose.e2e.yml` | Stack isolada com PostgreSQL descartável e simulador HTTP Asaas; modo de teste restrito à stack, nunca habilitado por endpoint público de produção. |
| `e2e/fixtures/asaas-mappings.json` | Respostas e eventos fictícios para simulador, sem credenciais reais. |
| `docs/asaas/homologacao.md` | Cenário, passos, resultado esperado, resultado observado, ID Sandbox sanitizado, data e evidência. |

Adaptar configuração Playwright/Compose para iniciar os serviços e aguardar healthchecks; todos os fluxos do navegador devem alcançar backend e PostgreSQL reais de teste. Caso automação visual do Flutter exija semântica acessível, implementar com teste anterior; não substituir silenciosamente E2E por mocks de toda a API.

Acrescentar ao gate, com stack E2E isolada saudável:

```bash
npm ci --prefix e2e
npm exec --prefix e2e -- playwright install --with-deps chromium
npm run test --prefix e2e
```

Atualizar `scripts/verify-asaas-sprint.sh` e workflow para subir/derrubar somente a stack E2E, inclusive em falha. Registrar os comandos definitivos de Compose e disponibilidade do simulador em `docs/asaas/homologacao.md`.

### Homologação Sandbox adicional

- Partir do resumo existente e verificar, na página real Sandbox do Asaas, escolha de Pix/cartão, dados solicitados e apresentação do valor correto. Registrar campos obrigatórios observados e comportamento de navegação em `docs/asaas/homologacao.md`.
- Pix e cartão aprovados, cartão recusado quando simulação suportar, checkout cancelado/expirado.
- Callback recebido antes do webhook e navegador fechado antes do retorno.
- Reenvio do mesmo evento e recuperação após indisponibilidade temporária.
- Estorno/disputa: testar no Sandbox se suportado; caso contrário, fixture oficial e procedimento operacional documentado, sem declarar que houve teste real.
- URL de retorno e webhook acessíveis por HTTPS; nenhum token em URL/log.
- Confirmar campos/eventos reais do Asaas e registrar ajustes por TDD antes de mudar adaptadores.

**Aceite:** gate acumulado, E2E e homologação obrigatória concluídos; divergências resolvidas; `docs/asaas/evidencias/sprint-06.md` aprovado. Ausência de credenciais/ambiente mantém esta sprint bloqueada, sem simular aprovação.

## 11. Sprint 7 — preparação e ativação de produção

**Dor:** integração funciona em teste, mas precisa receber valores com rastreabilidade e recuperação operacional.

### Arquivos e verificações

| Ação | Caminho | Estrutura/responsabilidade |
| --- | --- | --- |
| Testar primeiro | `backend/WeddingRsvp.Tests/Integration/PaymentProductionConfigurationTests.cs` | Habilitação sem segredo falha; host/ambiente incompatível falha; desabilitar novos checkouts mantém processamento de pagamentos existentes. |
| Criar | `docs/asaas/producao.md` | Checklist de publicação, responsáveis, configuração sem valores secretos, backup, migração, teste controlado, monitoramento e rollback. |
| Alterar conforme testes | `.env.example`, `docker-compose.yml`, `nginx.conf`, `Program.cs`, `Options/AsaasOptions.cs` | Configuração final, encaminhamento de headers e separação entre suspender novas cobranças e manter workers/webhooks. |
| Alterar | `README.md` | Link para este plano, pré-requisitos, comandos de validação e operação. |
| Criar ao encerrar | `docs/asaas/evidencias/sprint-07.md` | Gate final, homologação, publicação e verificação financeira; status real. |

### Passos externos e de publicação

1. Conta e modalidade aprovadas; taxas/prazos confirmados; credenciais produtivas geradas no ambiente correto.
2. Configurar secrets no servidor, domínio HTTPS, callbacks e webhook produtivo com token próprio.
3. Fazer backup do PostgreSQL e validar restauração em ambiente isolado antes da migration produtiva.
4. Executar gate completo sobre a versão candidata e publicar com criação de checkout inicialmente desabilitada.
5. Validar healthchecks, migrations, webhook, monitoramento e acesso administrativo.
6. Habilitar novas cobranças após decisão do responsável. Uma transação real controlada depende de autorização específica do titular; este planejamento não executa nem autoriza movimentação financeira.
7. Conferir pedido, evento, situação no Asaas e valor líquido/prazo; registrar evidência sem dados pessoais sensíveis.
8. Monitorar falhas HTTP, idade da fila, eventos em erro, tentativas incertas e divergências financeiras.

**Rollback:** suspender novas criações, manter webhook e processamento dos pedidos existentes, restaurar versão compatível com schema e preservar registros financeiros. Nunca apagar pedidos/migrations para “resolver” divergência; restauração de banco exige conciliação com movimentos ocorridos após backup.

**Aceite:** gate final verde; produção configurada; observabilidade e recuperação comprovadas; validação financeira autorizada concluída. Se ainda não houver autorização para transação real, registrar “pronto para ativação/validação”, sem declarar integração produtiva integralmente validada.

## 12. Ordem de execução e controle

| Sprint | Resultado | Dependência | Status inicial |
| --- | --- | --- | --- |
| 0 | Baseline, conta e decisões | Nenhuma | Não iniciada |
| 1 | Catálogo e banco | Gate 0 aprovado | Bloqueada pela 0 |
| 2 | Pedido e checkout backend | Gate 1 aprovado | Bloqueada pela 1 |
| 3 | Confirmação por webhook | Gate 2 aprovado | Bloqueada pela 2 |
| 4 | Jornada Flutter | Gate 3 aprovado | Bloqueada pela 3 |
| 5 | Administração e conciliação | Gate 4 aprovado | Bloqueada pela 4 |
| 6 | E2E e homologação | Gate 5 aprovado | Bloqueada pela 5 |
| 7 | Ativação produtiva | Gate 6 e cadastro aprovados | Bloqueada pela 6 |

Sprints são incrementos de entrega, não estimativas de calendário. Definir duração somente após baseline e resposta do cadastro. Se algum contrato precisar mudar, atualizar este plano, escrever o teste de regressão antes do código e revalidar a sprint atual; não usar a revisão para dispensar gates.

## 13. Referências e pontos a reconfirmar

- [Introdução ao Asaas Checkout](https://docs.asaas.com/docs/introdu%C3%A7%C3%A3o-1): criação, identificação, retorno e eventos. O contrato externo vigente deve ser conferido na sprint 2 e na homologação; usar checkout hospedado e associar o ID ao pedido local.
- [Autenticação e ambientes](https://docs.asaas.com/docs/authentication): chaves e URLs distintas para Sandbox/produção.
- [Cadastro de webhook pela interface web](https://docs.asaas.com/docs/criar-novo-webhook-pela-aplicacao-web): URL e autenticação das notificações.
- [Taxas Asaas](https://www.asaas.com/precos-e-taxas): consultar condições efetivas da conta antes da ativação; não codificar tarifas promocionais.
- [Cadastro de conta](https://central.ajuda.asaas.com/hc/pt-br/articles/31406336360987-Como-criar-minha-conta-no-Asaas): concluir validação do recebedor.

As referências técnicas principais foram consultadas durante a elaboração. Elegibilidade específica para presentes de casamento, dados exigidos na conta, condições financeiras e disponibilidade de simulações devem ser confirmadas com o Asaas. O plano descreve a estrutura interna desejada e não substitui essa validação.
