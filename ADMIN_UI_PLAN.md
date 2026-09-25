# Plano de evolução da interface administrativa em Flutter

## Objetivo e referência

Usar a linguagem visual do HTML incorporado em `dashboard_analysis.md` como referência para o **painel inteiro**. O HTML é um mockup estático de uma única página; a entrega será uma aplicação Flutter Web com uma rota e uma tela próprias para cada área administrativa. A API ASP.NET Core continua sendo a fonte dos dados e das permissões. Este documento é planejamento; não altera telas nem contratos.

Flutter Web continua sendo uma aplicação única no navegador em termos de hospedagem, mas a navegação e a manutenção serão organizadas em páginas, URLs e arquivos separados, sem um único widget reunindo todas as áreas.

Referências examinadas: `dashboard_analysis.md`, `lib/features/admin/presentation/admin_page.dart`, `lib/app.dart`, `lib/core/network/api_client.dart` e os grupos de endpoints `/api/admin/*`.

### Decisões de produto

1. O dashboard é uma **visão geral**; ações completas vivem nas telas de Produtos, Pagamentos, Presença, Logs, Configurações e Segurança.
2. Sidebar, cabeçalho, tipografia, cores, superfícies, cards, badges e espaçamento formam um sistema visual compartilhado. Cada área usa esses componentes com conteúdo e ações próprios.
3. Nenhum HTML, Tailwind, JavaScript, SVG demonstrativo, texto fictício ou lógica do mockup será copiado para o Flutter. Implementar widgets Flutter nativos e conectar somente dados reais da API.
4. A seção escrita de `dashboard_analysis.md` determina que o gráfico SVG seja removido, embora o HTML anexado ainda o contenha. O dashboard inicial não terá gráfico nem seletor de períodos sem API de série temporal.
5. Não exibir controles que prometam uma operação inexistente. Deltas diários, metas, notificações, mural, exportação RSVP, status de cotas e switches do mockup dependem de contratos/funcionalidades que não estão implementados.

## Estado atual e mudança estrutural

Hoje `admin_page.dart` concentra autenticação, navegação por `section`, formulários, chamadas HTTP e renderização genérica de listas em cerca de 600 linhas. `lib/app.dart` registra apenas `/admin`. Produtos têm ações próprias, enquanto Pagamentos, Presença, Logs e Configurações aparecem como cards genéricos. O tema global é compartilhado com o site público.

A evolução deve manter `/admin` como entrada de autenticação e substituir a troca de conteúdo por string por **rotas administrativas reais**. Um `AdminShell` compartilha sidebar e cabeçalho entre rotas, mas cada rota instancia uma página própria. O shell não guarda os estados de formulário ou paginação de todas as áreas. Autenticação, troca de senha inicial e MFA permanecem em telas de acesso/onboarding fora do conteúdo administrativo.

### Mapa de rotas proposto

| Rota Flutter Web | Tela | Papel |
| --- | --- | --- |
| `/admin` | Entrada/guard | Verifica sessão e direciona para onboarding ou `/admin/dashboard`. |
| `/admin/login`, `/admin/mfa`, `/admin/primeiro-acesso` | Acesso | Login, verificação/recovery e senha inicial/enroll. Sem shell administrativo. |
| `/admin/dashboard` | `AdminDashboardPage` | Resumo com links para telas de operação. |
| `/admin/produtos` | `AdminProductsPage` | Lista paginada, status, destaque, ordem e exclusão. |
| `/admin/produtos/novo`, `/admin/produtos/:id` | `AdminProductFormPage` | Criação/edição e foto, com URL própria para retorno/refresh. |
| `/admin/pagamentos`, `/admin/pagamentos/:id` | `AdminPaymentsPage`, `AdminPaymentDetailPage` | Lista, detalhe, eventos e sincronização manual. |
| `/admin/presenca`, `/admin/presenca/:id` | `AdminAttendancePage`, `AdminAttendanceDetailPage` | Busca/filtro/lista e edição auditada. |
| `/admin/logs`, `/admin/logs/:id` | `AdminAuditPage`, `AdminAuditDetailPage` | Histórico e detalhe somente leitura. |
| `/admin/configuracoes` | `AdminSettingsPage` | Estado das configurações existentes, respeitando o limite funcional descrito abaixo. |
| `/admin/seguranca` | `AdminSecurityPage` | Senha e sessões; MFA inicial continua no onboarding. |

Usar o roteamento Flutter já presente em `lib/app.dart` e a estratégia de URL por caminho já ativada em `lib/main.dart`. A rota selecionada determina o item ativo da sidebar, o título e o breadcrumb. Navegação, refresh direto em cada URL e voltar/avançar do navegador devem preservar o destino. A proteção visual da rota não substitui a policy `SuperAdmin` no servidor.

## Sistema visual Flutter

Criar `AdminTheme`/tokens **escopados ao admin**, preservando a aparência das páginas públicas. Aproveitar `google_fonts`, que já está no projeto, para Playfair Display nos títulos principais, Bodoni Moda nos títulos editoriais, Work Sans no corpo e Plus Jakarta Sans nos rótulos. Se houver falha de carregamento da fonte, usar fallback legível.

Tokens iniciais extraídos do HTML: `primary #6D5B4C`, `secondary #735C00`, `surface #FBF9F8`, `surfaceContainerLow #F6F3F2`, `surfaceContainer #F0EDED`, `surfaceContainerHigh #EAE8E7`, `onSurface #1B1C1C`, `onSurfaceVariant #4E453F`, `outlineVariant #D1C4BB`. Centralizar cores, raio, espaçamento e estilos em Dart; não repetir literais por página. Conferir contraste e estados de foco/erro antes de fixar a paleta final.

Componentes compartilhados:

- `AdminShell`: sidebar larga em desktop, navegação adaptada em telas menores, topbar, breadcrumb, área de conteúdo e logout.
- `AdminPageHeader`: título editorial, descrição curta e ações próprias da tela.
- `AdminMetricCard`, `AdminSectionCard`, `AdminStatusBadge`, `AdminEmptyState`, `AdminErrorState`, `AdminLoadingState` e paginação.
- Tabela responsiva com cabeçalhos, valores e ações acessíveis; em largura pequena, apresentar os mesmos dados em cards sem rolagem horizontal excessiva.
- Campos e diálogos consistentes para edição, confirmação de exclusão e ações financeiras.

Dimensionar pelo espaço disponível (`LayoutBuilder`), não por larguras rígidas do HTML: quatro cards em desktop, dois em tablet e um em celular; painel principal/coluna lateral somente quando couberem. Sidebar de aproximadamente 288 px no desktop é referência, não obrigação em viewport menor. Manter foco visível, rótulos sem depender apenas de ícone/cor, navegação por teclado e feedback de carregamento/erro.

## Contratos por tela

Os caminhos abaixo são os **endpoints existentes**, não uma proposta de novos endpoints. Cada tela terá repositório/modelos próprios para traduzir a resposta da API em dados tipados de apresentação. Valores financeiros vêm em centavos e são formatados em reais na UI; datas UTC são formatadas no fuso exibido ao administrador.

| Tela | Leitura existente | Ações existentes | Composição visual dedicada |
| --- | --- | --- | --- |
| Dashboard | `GET /api/admin/dashboard/summary`, `/activity?limit=...`, `/attendance?page=1&pageSize=...`, `/payments?page=1&pageSize=...` | Links para Produtos, Presença e Pagamentos | Banner editorial, cards de métricas, confirmações recentes, pagamentos recentes e atividade administrativa. |
| Produtos | `GET /api/admin/products?page=&pageSize=`, `GET /api/admin/products/{id}` | `POST/PUT/DELETE /api/admin/products`, `PATCH /{id}/status`, `PATCH /{id}/order`, `POST /{id}/images` | Lista/tabela de catálogo, formulário com prévia da foto, preço, categoria, ordem, status e destaque. |
| Pagamentos | `GET /api/admin/payments?page=&pageSize=`, `GET /{id}`, `GET /{id}/events` | `POST /{id}/sync` | Lista financeira com valor/status/remetente/data; detalhe com itens do pedido, linha do tempo de eventos e botão de sincronizar com confirmação/resultado. |
| Presença | `GET /api/admin/attendance?search=&vaiComparecer=&page=&pageSize=`, `GET /summary`, `GET /{id}` | `PATCH /{id}` com `motivo` obrigatório | Cards de resumo, busca/filtro, tabela de convidados e formulário de edição auditada. |
| Logs | `GET /api/admin/audit-logs?page=&pageSize=`, `GET /{id}` | Nenhuma | Lista cronológica, detalhe de uma ocorrência, paginação e apresentação legível de valores antigos/novos. |
| Configurações | `GET /api/admin/settings` | `PATCH /api/admin/settings` aceita pares chave/valor | Página de configurações existentes. A edição depende de definir chaves, validação e efeito real no backend; ver limite abaixo. |
| Segurança | `GET /api/admin/auth/me` | `POST /api/admin/security/password`, `POST /sessions/revoke` | Cards separados para senha, estado de MFA e revogação de sessões; confirmação para ações que encerram acesso. |
| Acesso/onboarding | `GET /api/admin/auth/csrf`, `/me` | `POST /login`, `/mfa/verify`, `/mfa/recovery`, `/logout`, `/security/mfa/enroll`, `/security/mfa/confirm`, `/security/password` | Fluxo de autenticação em etapas, fora do shell; recuperação e códigos tratados como dados sensíveis. |

### Dashboard: substituir os blocos demonstrativos por dados suportados

- **Presença confirmada:** `rsvps.confirmados` e `rsvps.totalPessoas` de `/dashboard/summary`. Se houver barra, explicitar que a proporção é entre respostas recebidas; não usar o total fictício de convidados do HTML.
- **Total recebido:** `payments.totalReceivedCents`; rótulo e descrição devem refletir exatamente a regra da API. Sem meta de arrecadação ou comparação com ontem, pois esses dados não existem.
- **Catálogo:** `products.ativos` substitui “itens adquiridos/cotas restantes”, que não são medidos pelo contrato atual. O cálculo atual de `products.total`/`inativos` inclui produtos removidos logicamente; não apresentar esses números como catálogo visível sem corrigir o contrato ou usar o `total` da listagem administrativa, que exclui os removidos.
- **Pagamentos:** `payments.pending`, `payments.confirmed`, `payments.cancelled` ou `orders.paidOrders`, com rótulos coerentes. Substitui o “Mural do Casal”, sem endpoint.
- **Lista inferior:** RSVP recente vem de `/attendance`; usar nome, adultos, crianças, status e data. A entidade `Rsvp` não tem “categoria”, portanto remover essa coluna do mockup.
- **Coluna lateral:** usar “Pagamentos recentes” da lista de pagamentos, sem fotos de presentes; o contrato de lista não inclui itens/imagens. Atividades vêm de `/dashboard/activity` e são logs administrativos, sem inventar eventos do gateway.
- **Atalhos:** “Novo produto” e “Ver presença/pagamentos” navegam às rotas reais. “Ver site” pode apontar para `/`. Exportação, notificação e filtros temporais só entram quando houver funcionalidade correspondente.

### Limites de contrato que o desenho deve respeitar

- A lista de pagamentos só aceita paginação; não desenhar filtros de status/período como se fossem filtros de servidor.
- A lista de logs só aceita paginação; busca e filtros globais exigiriam contrato próprio.
- A lista de produtos não traz URL da foto; a página de detalhe traz `images`. Evitar uma chamada de detalhe para cada linha apenas para desenhar miniaturas. Exibir miniatura no formulário/detalhe; avaliar um DTO de lista em fase separada se miniaturas forem requisito.
- `AppSettings` persiste pares arbitrários, mas não há consumidores implementados para “Lista ativa”, “RSVP liberado” ou “WhatsApp”. Não criar switches que gravem valores sem alterar o comportamento real do site. A tela pode mostrar o estado já existente; controles operacionais só depois de um contrato funcional explícito.
- Data do evento e contagem regressiva do HTML são inconsistentes e não vêm dos endpoints administrativos. Exibir somente se houver fonte única e válida; caso contrário, omitir esse bloco.
- O HTML contém valores estáticos, imagens externas e menção a outro gateway. Nenhum deles deve aparecer como dado de produção.

## Organização de código proposta

```text
lib/features/admin/
  data/
    admin_api.dart                 # cliente compartilhado; cookie e CSRF existentes
    models/                        # DTOs tipados por domínio
    repositories/                  # dashboard, products, payments, attendance, audit, settings, security
  presentation/
    auth/                          # login, MFA, recuperação e primeiro acesso
    shell/                         # navegação, cabeçalho, guard e layout responsivo
    theme/                         # tokens e estilos exclusivos do admin
    widgets/                       # cards, badges, tabela, estados e paginação
    dashboard/
    products/
    payments/
    attendance/
    audit/
    settings/
    security/
```

Cada página possui seu estado de consulta, filtros, paginação e formulários. Um controlador de sessão compartilhado carrega `/auth/me`, oferece o `ApiClient` com credenciais/CSRF, reage a `401` levando ao login e a `403` mostrando acesso negado ou onboarding conforme o contexto. A API continua aplicando autorização. Reusar o picker de imagem existente. Após mutações, atualizar apenas as consultas afetadas; preservar formulário e indicar separadamente se os dados do produto foram salvos mas o upload falhou.

## Sprints de execução

> Regra geral: cada sprint termina com **rotas funcionais e navegáveis** antes do próximo começar. O `admin_page.dart` vai sendo esvaziado gradualmente — somente entry point ao final da Sprint 5.

---

### Sprint 1 — Base visual, rotas e shell

**Objetivo:** montar o esqueleto que todas as demais sprints habitam. Ao final, navegar pelas rotas `/admin/*` já funciona, o fluxo de autenticação existente não regride e o `AdminShell` reflete a paleta e a tipografia do HTML de referência.

**Tarefas:**

| # | Tarefa |
|---|---|
| 1.1 | Criar `theme/admin_theme.dart` com tokens de cor, tipografia (Playfair Display, Bodoni Moda, Work Sans, Plus Jakarta Sans) e raio — sem literais espalhados por página |
| 1.2 | Criar `shell/admin_shell.dart`: sidebar 288 px, logo, 7 itens de navegação, data do evento via API (omitir se ausente), logout; topbar com breadcrumb calculado pela rota ativa |
| 1.3 | Criar `shell/admin_session_controller.dart`: carrega `/auth/me`, fornece `ApiClient` com CSRF, intercepta `401` → login, `403` → acesso negado |
| 1.4 | Registrar em `lib/app.dart` todas as rotas da tabela acima com guard de sessão |
| 1.5 | Extrair fluxo de autenticação de `admin_page.dart` para `auth/`: `AdminLoginPage`, `AdminMfaPage`, `AdminFirstAccessPage` — MFA, recovery e troca de senha obrigatória sem regressão |
| 1.6 | Criar widgets compartilhados: `AdminPageHeader`, `AdminEmptyState`, `AdminErrorState`, `AdminLoadingState` |
| 1.7 | `/admin/dashboard` exibe `AdminDashboardPage` placeholder (loading spinner real) via `AdminShell` |
| 1.8 | Testes: URL direta em cada rota, refresh mantém destino, `401` redireciona ao login, `403` não expõe conteúdo |

**Arquivos criados / alterados:**

```
lib/app.dart                                              ← novas rotas
lib/features/admin/presentation/
  theme/admin_theme.dart                                  ← NOVO
  shell/admin_shell.dart                                  ← NOVO
  shell/admin_session_controller.dart                     ← NOVO
  auth/admin_login_page.dart                              ← NOVO (extraído)
  auth/admin_mfa_page.dart                                ← NOVO (extraído)
  auth/admin_first_access_page.dart                       ← NOVO (extraído)
  widgets/admin_page_header.dart                          ← NOVO
  widgets/admin_state_widgets.dart                        ← NOVO
  dashboard/admin_dashboard_page.dart                     ← NOVO (placeholder)
  admin_page.dart                                         ← reduzido a entry point
```

**Critérios de aceite:**

- [ ] `flutter analyze` sem erros novos; build web sem warnings novos
- [ ] Sidebar exibe 7 itens com estado ativo correto por URL ativa
- [ ] Login → MFA → dashboard funciona end-to-end; troca de senha obrigatória no primeiro acesso
- [ ] Refresh em `/admin/pagamentos` mantém a tela correta (não cai em 404)
- [ ] Sessão expirada em qualquer rota admin leva ao login sem exibir dados administrativos

---

### Sprint 2 — Dashboard real

**Objetivo:** substituir o placeholder por um dashboard conectado aos endpoints existentes, sem nenhum número fictício.

**Tarefas:**

| # | Tarefa |
|---|---|
| 2.1 | `data/repositories/dashboard_repository.dart`: `GET /dashboard/summary` e `/activity?limit=10` |
| 2.2 | `widgets/admin_metric_card.dart`: ícone, rótulo, valor, barra de progresso opcional — alimentado por dados reais |
| 2.3 | Banner editorial com nome do casal e ações reais: "Novo produto" (→ `/admin/produtos/novo`), "Ver presença", "Ver pagamentos" — sem exportação ou notificação fictícia |
| 2.4 | 4 cards de métricas com dados de `summary`; sem campos sem contrato (meta, convidados pendentes, mural) |
| 2.5 | Confirmações recentes: `/attendance?page=1&pageSize=5` — nome, adultos, crianças, status, data; **sem coluna "categoria"** (campo inexistente em `Rsvp`) |
| 2.6 | Pagamentos recentes: `/payments?page=1&pageSize=3` — remetente, valor, status, data; sem foto |
| 2.7 | Atividades recentes: `/dashboard/activity` — logs administrativos reais |
| 2.8 | Category breakdown (Padrinhos/Familiares/Amigos): **omitir** — a API não segrega RSVPs por categoria |
| 2.9 | Estados loading / vazio / erro por seção independente |

**Arquivos criados / alterados:**

```
lib/features/admin/
  data/
    models/dashboard_summary.dart                         ← NOVO
    repositories/dashboard_repository.dart                ← NOVO
  presentation/
    dashboard/admin_dashboard_page.dart                   ← implementado
    widgets/admin_metric_card.dart                        ← NOVO
```

**Critérios de aceite:**

- [ ] Nenhum número, meta ou badge estático do HTML aparece como dado
- [ ] Cards exibem loading → valor real → erro com retry, independente por seção
- [ ] Lista de presença mostra estado vazio sem crash quando não há registros
- [ ] Links de ação navegam às rotas corretas

---

### Sprint 3 — Módulo Produtos

**Objetivo:** extrair e elevar a lógica de produtos do `admin_page.dart` atual para página própria no novo padrão visual.

**Tarefas:**

| # | Tarefa |
|---|---|
| 3.1 | `data/repositories/product_repository.dart`: list, get, post, put, delete, patch status, patch order, post image |
| 3.2 | `AdminProductsPage` (`/admin/produtos`): tabela paginada com nome, categoria, preço (centavos → R$), status, destaque e ações inline (ativar/desativar, destacar, editar, remover) |
| 3.3 | `AdminProductFormPage` (`/admin/produtos/novo` e `/admin/produtos/:id`): campos completos, picker de imagem reutilizado; feedback separado "produto salvo" e "upload falhou" |
| 3.4 | Diálogo de confirmação antes do `DELETE` |
| 3.5 | A lista **não faz `GET /{id}`** por linha; miniaturas só no formulário/detalhe |

**Arquivos criados / alterados:**

```
lib/features/admin/
  data/
    models/product.dart                                   ← NOVO
    repositories/product_repository.dart                  ← NOVO
  presentation/
    products/admin_products_page.dart                     ← NOVO
    products/admin_product_form_page.dart                 ← NOVO
  admin_page.dart                                         ← lógica de produto removida
```

**Critérios de aceite:**

- [ ] CRUD completo: criar, editar, ativar/desativar, destacar, remover
- [ ] Upload falha → erro visível sem reverter salvamento do produto
- [ ] Paginação e refresh de `/admin/produtos` mantêm página correta
- [ ] Formulário acessível via URL direta; voltar no browser preserva a lista

---

### Sprint 4 — Pagamentos e Presença

**Objetivo:** telas de lista e detalhe para as duas áreas operacionais críticas.

**Tarefas — Pagamentos:**

| # | Tarefa |
|---|---|
| 4A.1 | `data/repositories/payment_repository.dart`: list, get, get events, post sync |
| 4A.2 | `AdminPaymentsPage`: tabela com remetente, valor R$, método, status badge, data; paginação; **sem filtros de status/período** (contrato não suporta) |
| 4A.3 | `AdminPaymentDetailPage`: itens do pedido, linha do tempo de eventos, botão "Sincronizar com Asaas" com confirmação e exibição do resultado |
| 4A.4 | `widgets/admin_status_badge.dart` genérico (Pending, Confirmed, Received, Overdue, Cancelled…) |

**Tarefas — Presença:**

| # | Tarefa |
|---|---|
| 4B.1 | `data/repositories/attendance_repository.dart`: list (search, vaiComparecer, page), summary, get, patch |
| 4B.2 | `AdminAttendancePage`: cards de resumo de `/summary`; busca por nome/email; filtro confirmado/recusado; tabela paginada; **sem coluna categoria** |
| 4B.3 | `AdminAttendanceDetailPage`: dados do RSVP; edição com `motivo` obrigatório; confirmação antes de salvar |

**Arquivos criados / alterados:**

```
lib/features/admin/
  data/
    models/payment.dart, attendance.dart                  ← NOVOS
    repositories/payment_repository.dart                  ← NOVO
    repositories/attendance_repository.dart               ← NOVO
  presentation/
    payments/admin_payments_page.dart                     ← NOVO
    payments/admin_payment_detail_page.dart               ← NOVO
    attendance/admin_attendance_page.dart                 ← NOVO
    attendance/admin_attendance_detail_page.dart          ← NOVO
    widgets/admin_status_badge.dart                       ← NOVO
  admin_page.dart                                         ← seções Pagamentos e Presença removidas
```

**Critérios de aceite:**

- [ ] Sincronização exige confirmação e exibe resultado (sucesso, erro da API ou timeout)
- [ ] Edição de RSVP sem `motivo` é bloqueada no frontend e rejeitada no backend
- [ ] Busca e filtro de presença funcionam com debounce; vazio exibe estado, não crash
- [ ] Paginação e refresh de URL mantêm estado correto em ambas as telas

---

### Sprint 5 — Logs, Configurações e Segurança

**Objetivo:** fechar as três áreas restantes do menu com limites de contrato explícitos. Ao final desta sprint `admin_page.dart` contém apenas o entry point de sessão.

**Tarefas — Logs:**

| # | Tarefa |
|---|---|
| 5A.1 | `data/repositories/audit_repository.dart`: list (page), get |
| 5A.2 | `AdminAuditPage`: lista cronológica, paginação; **sem filtros** (contrato não suporta) |
| 5A.3 | `AdminAuditDetailPage`: `oldValues`/`newValues` legíveis; somente leitura |

**Tarefas — Configurações:**

| # | Tarefa |
|---|---|
| 5B.1 | `data/repositories/settings_repository.dart`: get, patch |
| 5B.2 | `AdminSettingsPage`: exibe chaves e valores existentes; edição inline; **nenhum switch** prometendo "Lista ativa" ou "RSVP liberado" sem consumidor real; aviso explícito sobre limitação |

**Tarefas — Segurança:**

| # | Tarefa |
|---|---|
| 5C.1 | `AdminSecurityPage`: card de senha (troca com confirmação), estado de MFA (somente leitura — enroll é onboarding), botão de revogar todas as sessões com aviso de logout imediato |

**Arquivos criados / alterados:**

```
lib/features/admin/
  data/
    models/audit_log.dart, app_setting.dart               ← NOVOS
    repositories/audit_repository.dart                    ← NOVO
    repositories/settings_repository.dart                 ← NOVO
  presentation/
    audit/admin_audit_page.dart                           ← NOVO
    audit/admin_audit_detail_page.dart                    ← NOVO
    settings/admin_settings_page.dart                     ← NOVO
    security/admin_security_page.dart                     ← NOVO
  admin_page.dart                                         ← esvaziado; somente entry point (< 50 linhas)
```

**Critérios de aceite:**

- [x] Logs: detalhe mostra todos os campos sem possibilidade de edição
- [x] Configurações: editar um par grava via `PATCH`; erro não limpa os demais campos
- [x] Segurança: revogar sessões faz logout imediato com aviso prévio
- [x] `admin_page.dart` com menos de 50 linhas ao final desta sprint

---

### Sprint 6 — Acabamento e qualidade

**Objetivo:** elevar a experiência ao padrão dos critérios de aceite antes de qualquer uso real em produção.

**Tarefas:**

| # | Tarefa |
|---|---|
| 6.1 | **Responsividade:** `LayoutBuilder` em cada página — 4 cards → 2 → 1; sidebar colapsável abaixo de ~960 px; tabelas viram cards empilhados abaixo de 600 px |
| 6.2 | **Acessibilidade:** `Semantics` em ícones de ação, foco visível em todos os interativos, rótulos sem depender só de cor |
| 6.3 | **Contraste:** auditar `AdminTheme` contra WCAG AA; ajustar se necessário |
| 6.4 | **Estados consistentes:** loading / empty / error / retry via widgets da Sprint 1 em todas as telas |
| 6.5 | **URLs e histórico:** voltar/avançar, refresh e abertura em nova aba funcionam em cada rota |
| 6.6 | **Revisão visual:** comparar cada seção ao HTML de referência lado a lado; alinhar tipografia, espaçamento e cores |
| 6.7 | **Testes Flutter:** widget tests de navegação/guard, mapeamento de dados (dashboard, produtos, presença), fluxo de auth completo |
| 6.8 | **Build web:** `flutter build web` sem erros; tema do site público inalterado |

**Critérios de aceite finais:**

- [x] Cada item da navegação abre uma URL própria e uma tela própria; refresh e histórico do navegador mantêm a tela correta
- [x] O shell e os componentes preservam a estética do exemplo em desktop e celular, sem afetar o tema do site público
- [x] Todas as métricas, listas e status exibidos vêm de endpoints existentes, com loading, vazio e erro distintos; nenhum número ou toggle demonstrativo aparece como dado real
- [x] Produtos, pagamentos, presença, logs, configurações e segurança usam os respectivos contratos; ações não suportadas não aparecem como botões funcionais
- [x] Login, MFA, logout, cookie e CSRF continuam funcionando em todas as rotas; um `401` não deixa dados administrativos visíveis
- [x] Testes de navegação/refresh, estados de tela, mapeamento de dados e fluxos críticos passam; build web e `flutter analyze` sem erros novos

---

## Mapa resumido dos sprints

```
Sprint 1  ──  Shell + Auth + Rotas + Tokens
Sprint 2  ──  Dashboard real (dados de API)
Sprint 3  ──  Produtos (CRUD completo + upload)
Sprint 4  ──  Pagamentos + Presença (lista, detalhe, ações)
Sprint 5  ──  Logs + Configurações + Segurança
Sprint 6  ──  Responsividade, acessibilidade, testes, build
```

Cada sprint depende da anterior estar concluída com `flutter analyze` limpo e testes verdes.
