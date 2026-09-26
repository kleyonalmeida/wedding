# Planejamento da refatoração de pós-compra em Flutter

Revisado em 26/09/2026 com base na implementação Flutter, nas rotas, no gateway e na API deste repositório. O objetivo é **substituir a apresentação atual** de `/pagamento/retorno` pelo desenho editorial do HTML ao final, mantendo a consulta real do pedido. Este documento não representa implementação ou validação visual já concluída.

## Regras de identidade e escopo

- Usar `K&L` no monograma do corpo e na identidade visual compartilhada. Não copiar os nomes por extenso da referência para títulos ou assinaturas da nova tela.
- Reutilizar `WeddingHeader` e `WeddingSideMenu` existentes, sem modificar componentes, menus, estilos ou comportamento responsivo. Manter HOME, O CASAL, RECEPÇÃO, LISTA DE PRESENTES, PRESENÇA e alternância de tema; conectar navegação a `/` e `/presentes` conforme as páginas existentes.
- Reutilizar `WeddingFooter` integralmente. Ele exibe `K&L` e `© 2026 Kleyon & Liandra. Feito com amor.`; o copyright permanece porque o footer foi definido como inalterado.
- A página atual de retorno tem apenas `AppBar`; **não tem o header nem o footer compartilhados**. A refatoração precisa integrá-los, não apenas mudar o título da AppBar. A nova composição substitui a AppBar local.
- Preservar rota e callback `/pagamento/retorno?id=<id>#token=<token>`. Não converter token para query de navegação, nem tratar retorno do gateway como prova de pagamento.
- Aplicar as adaptações já descritas no planejamento original: retirar “Confirmação de Homenagem”, “Baixar Comprovante” e toda a seção “Memória Afetiva”; substituir Cerimonial Privé por contato diretamente com o noivo; manter Voltar ao Início e Ver Outros Presentes.
- O HTML incorporado é a referência de **pós-compra**. `gift.html` é uma referência estática de catálogo, não o shell do Flutter. O bootstrap real está em `web/index.html`. Nenhum desses dois arquivos precisa ser reestilizado para implementar esta tela Flutter.

## Diagnóstico da construção atual

| Arquivo / área | O que existe hoje | Implicação |
|---|---|---|
| `lib/features/gifts/presentation/pages/payment_return_page.dart` | `StatefulWidget` recebe `orderId`, cria `ApiClient`, consulta uma vez em `initState`, guarda apenas uma string `status` e descarta o restante da resposta. | Separar dados tipados, estado da consulta e apresentação; detalhes não podem ser montados a partir da string. |
| Layout atual | `Scaffold` com fundo fixo claro, AppBar transparente, `Center` → padding 32 → `Column`; ícone de presente, título, status e um botão. Sem scroll. | Substituir por corpo editorial rolável. O layout atual não comporta recibo, mensagem, ajuda e footer em celulares. |
| Estado atual | Confirmed/Received viram confirmado; Refunded/Cancelled/Overdue têm texto único; todo o restante vira pendente. Exceções viram erro genérico. | Distinguir reembolso, contestação, situação desconhecida, link inválido e falha transitória; não reduzi-los a quatro estados ambíguos. |
| Token atual | `Uri.splitQueryString(Uri.base.fragment)['token']`; falta de ID/token evita consulta. | Extrair/parsing com tratamento de fragmento inválido e token vazio; preservar token durante refresh/atualizações da rota. |
| Ciclo de vida | Resposta verifica `mounted`, cliente é fechado no dispose; não há retry, timer, controller ou `didUpdateWidget`. | Adicionar retry e proteger respostas concorrentes; tratar mudança de pedido no mesmo State quando aplicável. |
| `lib/app_router.dart` | Router parser conserva path/query, não fragmento; delegate passa somente ID à página. | Verificar em navegador que restauração/normalização da rota não perde `#token`. Se precisar, ajustar passagem explícita da credencial em memória, sem espalhá-la em URLs ou mudar outras rotas. |
| `backend/.../Payments/AsaasPaymentGateway.cs` | successUrl/cancelUrl/expiredUrl são a mesma rota, com ID na query e token no fragmento. | O destino não identifica sucesso/cancelamento: status sempre vem da API. |
| `backend/.../Endpoints/GiftOrderEndpoints.cs` | GET protegido por hash de token retorna somente `id`, `status`, `checkoutUrl`. | O card editorial exige ampliar o DTO; `giftName`, `productName`, `amount`, `paymentMethod` e `dedicationMessage` presumidos no plano anterior não existem nessa resposta. |
| `Entities/GiftOrder.cs`, `GiftOrderItem.cs` | Pedido tem nome, mensagem, total em centavos, moeda, data; itens têm nome/preço snapshots e quantidade. | Renderizar snapshots do pedido, não consultar catálogo para reconstruir compras antigas. Suportar vários itens. |
| `Entities/Payment.cs` | Possui `BillingType`, timestamps de confirmação/recebimento e status do pagamento. | Meio de pagamento e data podem ser projetados quando existirem; não presumir PIX nem usar hora do navegador. |
| `Tests/Integration/GiftOrderEndpointsTests.cs` | Teste atual exige que GET não exponha `totalCents`, inclusive para token correto. | A ampliação é uma alteração deliberada do contrato, com atualização desse teste e cobertura de autorização para detalhes. |
| Fontes e tema | `AppTextStyles` oferece Playfair, Plus Jakarta Sans e Great Vibes; referência usa também Bodoni e Work Sans, cores locais diferentes. | Compartilhar tokens/fontes com a nova área de presentes quando disponíveis; não alterar cores globais/header/footer. |

A análise foi feita no código; screenshots, execução do fluxo e medições são entregas das sprints abaixo.

## Contrato de dados necessário

Ampliar a consulta autenticada pelo token existente com um DTO explícito. Manter campos atuais compatíveis; os nomes a seguir são a proposta a implementar e testar, não campos já disponíveis:

| Campo proposto | Fonte / regra |
|---|---|
| `id`, `status` | Pedido existente. Usar ID real como código; não inventar `#KL-849204`. Uma forma curta de exibição pode acompanhar cópia do ID integral. |
| `totalCents`, `currency` | `GiftOrder.TotalCents`/Currency; usar centavos inteiros e formatador existente `formatGiftPrice` para BRL. Não confundir total bruto com repasse líquido. |
| `items[]` | `giftId`, `name`, `unitPriceCents`, `quantity` a partir dos snapshots. Total de linha = unitário × quantidade. |
| `senderName`, `message` | Valores registrados no pedido; mensagem omitida visualmente quando vazia. Não adicionar assinatura fictícia. |
| `createdAtUtc` | Data do pedido, label “Pedido criado em”. |
| `paymentMethod` | `BillingType` do pagamento pertinente, nullable; mapear códigos reais para labels. Ausência → “Ainda não informado”, nunca fallback PIX. |
| `confirmedAtUtc`, `receivedAtUtc` | Datas reais quando disponíveis; label “Pagamento confirmado em” ou “Pagamento recebido em” conforme o campo exibido. |
| `checkoutUrl` | Campo existente, sem adicionar CTA de novo pagamento a esta estilização. |

Definir qual pagamento é pertinente quando houver várias tentativas, reconciliando com status do pedido, sem selecionar um pagamento antigo por conveniência. Não expor identificadores internos do gateway, hash/token, valores líquidos ou dados administrativos no DTO.

A referência mostra thumbnail, mas não há snapshot de imagem no item. Para evitar inventar capa ou depender do catálogo atual, a primeira entrega usa ícone de presente no espaço de 64 px. Thumbnail real é melhoria opcional: requer contrato explícito de imagem histórica/indisponível, placeholder e política para produto removido; não é bloqueio para o corpo editorial.

Não chamar a data do pedido de data do pagamento. Não chamar pagamento confirmado de “repasse aprovado e notificado”: o contrato atual não comprova repasse aos noivos nem envio de notificação.

## Estados e conteúdo verdadeiro

Separar estado de carregamento/consulta do status financeiro. Se houver dados válidos e uma atualização falhar, preservar detalhes e indicar falha de atualização, sem transformar status financeiro em “não concluído”.

| Situação | Badge / headline previstos | Detalhes / ações |
|---|---|---|
| Carregando sem dados | “Consultando seu presente” | Placeholder estático do card ou um único indicador; sem selo de sucesso. |
| Confirmed | “PAGAMENTO CONFIRMADO” / “Obrigado por celebrar nosso amor” | Ícone `verified`, gratidão, resumo e mensagem reais. Não afirmar recebimento final/repasse. |
| Received | “PAGAMENTO RECEBIDO” / “Obrigado por celebrar nosso amor” | Mesmo desenho de sucesso, texto de recebimento compatível com servidor. |
| Pending | “CONFIRMAÇÃO PENDENTE” / “Seu presente está aguardando confirmação” | Ícone de espera, detalhes disponíveis, botão “Atualizar situação” e ajuda. |
| Cancelled | “PAGAMENTO CANCELADO” | Detalhes conhecidos, ajuda e navegação. |
| Overdue | “PAGAMENTO VENCIDO” | Informar vencimento; não inferir cancelamento ou oferecer cobrança nova automaticamente. |
| Refunded | “PAGAMENTO REEMBOLSADO” | Texto de reembolso; não dizer apenas “não concluído”. |
| Disputed | “PAGAMENTO EM CONTESTAÇÃO” | Estado de atenção e contato com noivo. |
| UnknownNeedsReview / status novo | “SITUAÇÃO EM VERIFICAÇÃO” | Fallback neutro; nunca sucesso ou pendência presumida. |
| ID/token ausente, vazio ou malformado | “LINK INCOMPLETO OU INVÁLIDO” | Não fazer GET inútil; ajuda e navegação, sem dados de pedido. |
| 401/404 | “NÃO FOI POSSÍVEL ACESSAR ESTE PEDIDO” | Sem revelar detalhes; não afirmar que token expirou, pois a API atual não define expiração. |
| Falha de rede / 5xx / resposta inválida | “CONSULTA INDISPONÍVEL” | Retry explícito, ajuda e navegação; não declarar falha do pagamento. |

Badge comunica status financeiro; a remoção da overline “Confirmação de Homenagem” não remove esse badge. Ícones/cores auxiliam o texto, sem depender somente de cor. Bloco de ajuda permanece discreto também no sucesso, como na referência, com conteúdo adequado à situação.

## Medidas e composição fiel ao HTML

| Elemento | Flutter previsto |
|---|---|
| Shell | Header compartilhado sobreposto e sólido, usando o padrão atual de `/presentes`; drawer existente; footer compartilhado no final do scroll com largura total. Sem AppBar extra. |
| Área principal | Fundo `#fbf9f8` no claro, margens 20 px, container central máximo 820 px. Reserva do header + respiro de 48 px no mobile / 80 px a partir de 768 px. |
| Topo | `K&L` em Playfair, itálico, 24 px e tracking discreto; título “Retorno do Pagamento” 32/40 px no mobile e 48/56 no desktop; texto de apoio 16/28 px, máximo 448 px. Separação do card 40 px. |
| Cartão editorial | Fundo branco, raio 8 px, sombra leve, padding 32 px mobile / 56 px desktop; acabamento interno com gradiente sutil a 8/12 px da borda. Não confundir esse acabamento com contorno forte. |
| Selo | Círculo externo 80 px, interno 64 px, ícone 30/32 px; gradiente claro, sombra pequena. Badge abaixo, label 12/16 px, tracking, ponto estático. |
| Gratidão/status | Headline central 32/40 ou 48/56 px; texto 16/28 px, largura até 512 px; separação 40 px antes dos detalhes. Ajustar textos por estado. |
| Resumo do pedido | Fundo `#f6f3f2`, padding 24/32 px, raio 4 px. Cabeçalho tonal com ícone de 64 px, item/itens e total; coluna no mobile, linha quando houver espaço. Nome em Bodoni 20/24 px, total Playfair 24/30 px. |
| Metadados | **Quatro campos** da referência: código, forma, data, situação do pagamento; 2 colunas no mobile e 4 a partir de 768 px quando couberem; gap 24 px. Uma coluna em largura/texto ampliado que exija. Não usar o grid de três campos do plano anterior. |
| Dedicatória | Caixa clara com quote, label e texto itálico 14/16 px; padding 20 px, separação 32 px. Conteúdo integral com quebra de linha, sem altura fixa ou ellipsis. |
| Ajuda | Fundo tonal, padding 16/20 px, ícone info em círculo de 36 px, texto e “Falar no WhatsApp”; coluna mobile/linha desktop conforme constraints. |
| Ações | Apenas Voltar ao Início e Ver Outros Presentes, gap 16 px, padding 32×14 px; preenchido primário e secundário tonal como HTML, borda de foco acessível. Largura inteira abaixo de 640 px, `Wrap` quando útil. |
| Paleta | Tokens locais: primary `#6d5b4c`, secondary `#735c00`, text `#1b1c1c`, muted `#4e453f`, low `#f6f3f2`, high `#eae8e7`; equivalentes legíveis no escuro. Não sobrescrever `AppColors` global. |
| Fontes | Playfair Display, Bodoni Moda, Work Sans e Plus Jakarta Sans, apenas pesos utilizados. Declarar fontes locais ou reutilizar a configuração real entregue no plano de gifts, sem confiar apenas em `fontFamily` não registrada. |
| Efeitos | Glows estáticos por gradientes locais suaves; reproduzir a percepção visual sem dois `blur-3xl` em áreas enormes. Comparação visual define ajustes. |

Pedidos com vários itens exibem lista de nomes/quantidades/preços dentro do resumo e total do pedido; não escolher só o primeiro item. Preferir bloco de altura natural para poucos itens e lista lazy de slivers para pedidos grandes, evitando scroll vertical interno e medidas intrínsecas.

## Sprints de execução

Sprints são etapas sequenciais de entrega e validação, sem prazo arbitrário. Fontes/tokens podem ser reutilizados do planejamento de presentes, mas a pós-compra deve poder ser entregue sem depender da implantação de valor livre.

### Sprint 0 — Referência e inventário de contratos

- Extrair HTML incorporado para referência executável e criar variante com as remoções/`K&L` exigidos. Não alterar `gift.html` nem o bootstrap para esse propósito.
- Capturar tela atual e referência em 390, 768, 1024 e 1440 px; documentar medidas do corpo e inserir header/footer atuais na composição alvo.
- Montar fixtures de estados, pedido com um/vários itens e mensagem vazia/longa.
- Definir DTO protegido, seleção do pagamento pertinente, rótulos de data e conteúdo de ajuda. Confirmar configuração pública de WhatsApp do noivo; nenhum número foi localizado nos componentes analisados.
- Registrar baseline de carregamento, número de requests, bytes e scroll antes da mudança.

**Aceite:** referência adaptada, fixtures e contrato definidos; campos ausentes ou opcionais explícitos. Nenhuma chave, contato, forma ou data fictícia tratada como real.

### Sprint 1 — API protegida e modelo de retorno

**Arquivos:** endpoint de pedidos, DTOs de resposta, testes de integração; novos `payment_return_order.dart` e `payment_return_repository.dart` em gifts.

- Ampliar GET com os campos definidos acima, mantendo a checagem de token antes de retornar dados. Usar projeção/consulta sem rastreamento e evitar N+1 por item/pagamento.
- Modelar resposta no Dart com parser validado, campos opcionais e status desconhecido seguro. Injetar API/repositório para permitir testes sem rede real.
- Usar snapshots e totais em centavos; não adicionar GET por produto, nem consultar diretamente o gateway a cada visita para montar a tela.
- Atualizar o teste que exige ausência de `totalCents`: com token correto retorna detalhes permitidos; sem token ou com token de outro pedido não retorna detalhes.
- Manter compatibilidade com a página atual até sua substituição. Registrar data de pagamento e meio como opcionais; ausência não deve impedir leitura do pedido.

**Aceite:** contrato testado com um/vários itens, token correto/incorreto/ausente, mensagem opcional e pagamento ausente. Nomes/preços antigos continuam válidos mesmo após edição/remoção do catálogo.

### Sprint 2 — Estado, credencial e atualização robustos

**Arquivos:** novo `payment_return_controller.dart`, página, repositório; router somente se necessário para preservar fragmento/ciclo de vida.

- Implementar estados da tabela; substituir string solta por dados + estado da consulta.
- Capturar token do fragmento com parsing seguro e validar ID/credencial antes do GET; testar callback real, reload, deep link e restauração de rota. Token permanece privado em memória e não aparece em UI, analytics ou mensagens de contato.
- Implementar “Atualizar situação” para pendente e retry para falha transitória. Uma requisição por vez, sem disparo em `build`; última consulta válida prevalece.
- Manter dados anteriores quando refresh falhar. Proteger respostas após dispose/troca de pedido; descartar credencial/dados da página anterior.
- Usar atualização manual como entrega inicial. Se necessário depois, polling apenas em Pending, limitado, pausado quando aba/app estiver oculto e encerrado em estado final/dispose; não criar polling infinito para efeito visual.
- Não mudar idempotência/criação de pedido ou transformar retry de consulta em nova cobrança.

**Aceite:** testes de estados/races/retry, link incompleto e token inválido; navegador preserva retorno autenticado. Cancel/expired callback nunca exibe sucesso sem status confirmado da API.

### Sprint 3 — Shell e corpo editorial responsivo

**Arquivos:** página e novos widgets locais `payment_return_heading.dart`, `payment_return_status_card.dart`, `payment_order_summary.dart`; tokens/fontes compartilháveis da área de gifts.

- Substituir a AppBar e a `Column` central sem scroll por `Stack` com header e `CustomScrollView` com conteúdo/rodapé.
- Integrar header/drawer atuais e callbacks de navegação, sem alterar labels/estilos dos componentes compartilhados. Incluir footer atual no final do scroll.
- Implementar monograma, título/apoio, card editorial, selo/badge e textos por estado com medidas acima.
- Montar resumo com lista de itens, total, quatro metadados e dedicatória opcional; usar placeholders honestos para dados ainda não disponíveis.
- Reproduzir gradientes/acabamento e sombras discretas, respeitando tema escuro. Nenhuma imagem externa fictícia do HTML será dependência de produção.

**Aceite:** layout comparado nas quatro larguras, com header/footer originais e corpo novo. Nenhum overflow, sobreposição do header ou footer preso dentro do cartão; todos os estados continuam navegáveis.

### Sprint 4 — Ajuda, ações e movimento acessível

**Arquivos:** widgets `payment_return_help.dart`, `payment_return_actions.dart`, página/controller e configuração pública de contato se necessária.

- Trocar texto de Cerimonial Privé por contato diretamente com o noivo. Exibir WhatsApp somente com destino configurado e válido; sem destino, manter orientação textual sem botão falso.
- Abrir contato usando `url_launcher` já disponível, com feedback se não abrir. Mensagem sugerida pode conter ID do pedido, nunca token, URL autenticada ou dedicatória privada.
- Conectar Voltar ao Início → `/` e Ver Outros Presentes → `/presentes` via `AppNavigation`. Verificar histórico no Router atual: `AppNavigation.replace` usa `Router.neglect`, portanto seu nome não comprova sozinho o comportamento de substituição da entrada do navegador.
- Retirar comprovante/download e galeria afetiva de toda a composição. Não implementar print/download como parte desta refatoração.
- Animação única curta de entrada de aproximadamente 300–500 ms, fade/slide leve, sem reaplicar em cada refresh. Respeitar movimento reduzido; badge sem pulse infinito. Não esperar rede para mostrar navegação ou feedback de carregamento.
- Garantir foco visível, Tab/Enter, semântica de status com anúncio apenas quando mudar, alvos de toque e conteúdo legível em 200% de texto.

**Aceite:** ações funcionam por mouse/toque/teclado; ajuda abre contato real e não divulga token. Preferência por movimento reduzido respeitada; tela continua utilizável se consulta ou WhatsApp falharem.

### Sprint 5 — Fidelidade, regressão e desempenho

- Comparar screenshots do corpo adaptado nas quatro larguras com fixtures iguais às da sprint 0; registrar diferenças de fontes, espaçamento, selo, card, metadados e botões.
- Verificar também 320 px, limites 639/640 e 767/768, textos longos, pedido com vários itens, tema escuro, zoom/texto ampliado e comportamento do header em seu breakpoint próprio.
- Cobrir Confirmed/Received/Pending, cancelado/vencido/reembolsado/contestado/desconhecido, erro de rede/5xx, 401/404, JSON inválido e reload/deep link com fragmento.
- Executar `flutter analyze`, testes de controller/widgets/navegação pertinentes e build web release; executar testes .NET de pedidos e gateway/callback após ampliação do contrato.
- Validar em ambiente de teste a sequência checkout → callback → consulta → pendência/atualização → confirmação real por webhook. Chegada à URL não confirma pagamento.
- Medir requests, bytes, tempo até feedback/detalhes, scroll/frames e memória no mesmo dispositivo/navegador/renderer da baseline, com cache frio/quente. Não medir fluidez apenas em debug.

**Aceite:** referências visuais e resultados arquivados; fluxo autenticado e estados corretos, nenhuma regressão material de layout/navegação/desempenho. Implantação não é etapa automática deste planejamento; sua preparação depende da conclusão dos critérios.

## Arquitetura prevista

```text
PaymentReturnPage
├── controller: dados tipados + estado de consulta + retry/refresh
├── Scaffold.drawer: WeddingSideMenu atual
└── Stack
    ├── Scrollbar + CustomScrollView (único scroll vertical)
    │   ├── reserva superior para header
    │   ├── heading central (K&L + título + apoio)
    │   ├── cartão editorial (largura máxima 820 px)
    │   │   ├── status/selo/headline e descrição
    │   │   ├── resumo dos itens + total
    │   │   ├── metadados reais + dedicatória opcional
    │   │   ├── ajuda / WhatsApp quando configurado
    │   │   └── duas ações de navegação
    │   ├── respiro final
    │   └── WeddingFooter atual, largura total
    └── WeddingHeader atual
```

Para pedidos grandes, separar itens em slivers lazy com decoração contínua equivalente ao card. Não envolver listas longas em `shrinkWrap` apenas para caber no cartão. Usar altura natural nas seções curtas; não inserir `Expanded` em `Column` dentro de scroll sem constraints finitas, como sugeria o plano antigo.

## Otimizações e restrições técnicas

- Uma consulta protegida ao pedido fornece detalhes e status; refresh é explícito, sem GETs por item ou busca do catálogo inteiro.
- Rebuilds localizados para estado/detalhes; header/footer e decoração estática não devem reconstruir por animação ou timer. Usar `const` quando possível.
- Evitar blur de grandes superfícies, pulse contínuo, `IntrinsicHeight` em listas e camadas extras por padrão. `RepaintBoundary` só quando a medição mostrar benefício.
- Não usar hora atual do JavaScript para data do pedido. Datas vêm em UTC da API e são formatadas para o usuário com rótulo/fuso coerentes; não chamar uma data arbitrária de “Hoje”.
- Fontes declaradas e apenas pesos necessários; se thumbnail real for adicionada depois, limitar decode pelo tamanho de 64 px × DPR e verificar comportamento do renderer web, com fallback estável.
- Preservar scroll nativo inicialmente nesta página curta; só adicionar smooth scroll por necessidade medida e alinhamento explícito com o app. Não adicionar dependência para animações simples.
- Meta de medição: referência de 16,7 ms por frame para 60 Hz, investigar picos repetidos e comparar baseline. Não prometer FPS ou fidelidade garantidos antes da validação.

Construção lazy, rebuilds locais e redução de efeitos/medidas custosos seguem as [boas práticas oficiais do Flutter](https://docs.flutter.dev/perf/best-practices), também usadas no planejamento da área de presentes.

## Checklist de conclusão

- [ ] Sprint 0: referência adaptada, fixtures, contrato e baseline.
- [ ] Sprint 1: DTO protegido e modelo tipado, testes de autorização atualizados.
- [ ] Sprint 2: estados verdadeiros, token preservado, retry e ciclo de vida.
- [ ] Sprint 3: shell compartilhado e novo corpo editorial.
- [ ] Sprint 4: ajuda real, duas ações e acessibilidade.
- [ ] Sprint 5: screenshots, fluxo integrado, testes e desempenho validados.
- [ ] `K&L`, menus/header e footer preservados.
- [ ] Sem overline de homenagem, download de comprovante ou galeria afetiva.
- [ ] Sem valores, forma de pagamento, datas, notificações ou contato fictícios.

## HTML original de referência

Preservado integralmente para consulta. As remoções e adaptações descritas neste planejamento prevalecem sobre o original; seus dados de exemplo e script de horário não são implementação de produção.

```html
<!DOCTYPE html>

<html lang="en"><head><meta charset="utf-8"/><meta content="width=device-width, initial-scale=1.0" name="viewport"/><meta content="web_blank" name="shell-type"/><title>Kleyon &amp; Liandra</title><link href="https://fonts.googleapis.com" rel="preconnect"/><link crossorigin="" href="https://fonts.gstatic.com" rel="preconnect"/><link href="https://fonts.googleapis.com/css2?family=Bodoni+Moda:ital,opsz,wght@0,6..96,400..900;1,6..96,400..900&amp;family=Playfair+Display:ital,wght@0,400..900;1,400..900&amp;family=Plus+Jakarta+Sans:wght@400;500;600;700&amp;family=Work+Sans:wght@300;400;500;600&amp;display=swap" rel="stylesheet"/><link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@24,400,0,0" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/><style>@layer base{html,body{margin:0;padding:0;}body{overscroll-behavior:none;}main>:first-child{margin-top:0!important;}main>:last-child{margin-bottom:0!important;}}::-webkit-scrollbar{display:none;}</style><script src="https://cdn.tailwindcss.com"></script><script id="tailwind-config">tailwind.config={darkMode:"class",theme:{extend:{colors:{"on-surface":"#1b1c1c","primary-fixed-dim":"#dac2b0","surface-variant":"#e4e2e1","surface-container-high":"#eae8e7","background":"#fbf9f8","on-tertiary-fixed-variant":"#474744","on-primary-fixed":"#26190e","surface-dim":"#dcd9d9","inverse-primary":"#dac2b0","on-primary-fixed-variant":"#544436","primary-fixed":"#f7decb","surface-container":"#f0eded","inverse-on-surface":"#f3f0f0","outline":"#80756e","secondary-container":"#fed65b","primary":"#6d5b4c","on-tertiary":"#ffffff","surface-tint":"#6d5b4c","surface-bright":"#fbf9f8","on-secondary-fixed-variant":"#574500","on-tertiary-fixed":"#1c1c1a","outline-variant":"#d1c4bb","on-secondary":"#ffffff","tertiary-fixed-dim":"#c8c6c2","secondary-fixed-dim":"#e9c349","primary-container":"#b8a291","tertiary-fixed":"#e5e2de","tertiary":"#5f5e5b","on-error-container":"#93000a","error-container":"#ffdad6","error":"#ba1a1a","on-secondary-fixed":"#241a00","surface":"#fbf9f8","on-primary-container":"#48392c","on-tertiary-container":"#3c3c39","on-secondary-container":"#745c00","secondary":"#735c00","surface-container-lowest":"#ffffff","on-error":"#ffffff","tertiary-container":"#a8a6a3","on-background":"#1b1c1c","on-surface-variant":"#4e453f","secondary-fixed":"#ffe088","on-primary":"#ffffff","surface-container-highest":"#e4e2e1","inverse-surface":"#303030","surface-container-low":"#f6f3f2"},borderRadius:{"DEFAULT":"0.125rem","lg":"0.25rem","xl":"0.5rem","full":"0.75rem"},spacing:{"container-max":"1200px","unit-base":"8px","gutter":"24px","margin-mobile":"20px","section-padding":"80px"},fontFamily:{"headline-lg-mobile":["Playfair Display"],"label-caps":["Plus Jakarta Sans"],"section-title":["Bodoni Moda"],"body-md":["Work Sans"],"headline-lg":["Playfair Display"]},fontSize:{"headline-lg-mobile":["32px",{lineHeight:"40px",fontWeight:"700"}],"label-caps":["12px",{lineHeight:"16px",letterSpacing:"0.15em",fontWeight:"600"}],"section-title":["36px",{lineHeight:"44px",fontWeight:"400"}],"body-md":["16px",{lineHeight:"28px",fontWeight:"400"}],"headline-lg":["48px",{lineHeight:"56px",letterSpacing:"-0.02em",fontWeight:"700"}]}}}}</script></head><body class="bg-surface font-body-md text-on-surface antialiased"><main class="w-full min-h-screen bg-surface flex flex-col justify-center items-center px-margin-mobile"><div class="flex flex-col w-full items-center justify-center py-12 md:py-20 relative overflow-hidden">
<!-- Subtle Ambient Glows -->
<div class="absolute -top-32 left-1/2 -translate-x-1/2 w-[700px] h-[500px] bg-gradient-to-b from-primary-fixed/40 via-surface-container/30 to-transparent blur-3xl pointer-events-none rounded-full"></div>
<div class="absolute bottom-0 right-1/4 w-[500px] h-[400px] bg-secondary-fixed/15 blur-3xl pointer-events-none rounded-full"></div>
<!-- Main Editorial Container -->
<div class="relative w-full max-w-[820px] mx-auto z-10 flex flex-col items-center">
<!-- Top Monogram & Overline -->
<div class="flex flex-col items-center text-center mb-10 space-y-3">
<div class="inline-flex items-center justify-center space-x-3 px-4 py-1.5 rounded-full bg-surface-container-low shadow-sm">
<span class="w-1.5 h-1.5 rounded-full bg-secondary"></span>
<span class="font-label-caps text-label-caps text-on-surface-variant uppercase tracking-[0.25em]">Confirmação de Homenagem</span>
<span class="w-1.5 h-1.5 rounded-full bg-secondary"></span>
</div>
<p class="font-section-title text-section-title italic text-primary">Kleyon &amp; Liandra</p>
<h1 class="font-headline-lg text-headline-lg text-on-surface tracking-tight mt-1">
        Retorno do Pagamento
      </h1>
<p class="font-body-md text-body-md text-on-surface-variant max-w-md text-center font-light">
        A celebração da nossa união ganha ainda mais encanto com o seu carinho e presença.
      </p>
</div>
<!-- Editorial Certificate / Receipt Card -->
<div class="w-full bg-surface-container-lowest rounded-xl shadow-xl shadow-primary/5 p-8 md:p-14 relative flex flex-col">
<!-- Inner Subtle Border Tint Accent -->
<div class="absolute inset-2 md:inset-3 rounded-lg pointer-events-none bg-gradient-to-b from-primary-fixed/20 via-transparent to-primary-fixed/10 opacity-70"></div>
<!-- Golden Seal / Status Icon Area -->
<div class="relative z-10 flex flex-col items-center text-center mb-10">
<!-- Floating Crest Icon -->
<div class="relative mb-5 flex items-center justify-center">
<div class="w-20 h-20 rounded-full bg-gradient-to-tr from-surface-container-high via-surface-container-lowest to-primary-fixed flex items-center justify-center shadow-md">
<div class="w-16 h-16 rounded-full bg-surface-container-lowest flex items-center justify-center shadow-inner">
<span class="material-symbols-outlined text-secondary text-3xl" style="font-variation-settings: 'FILL' 1;">
                verified
              </span>
</div>
</div>
<!-- Tiny Star Accent -->
<span class="absolute -top-1 -right-1 text-secondary material-symbols-outlined text-sm">arrow_back_ios_new</span>
</div>
<!-- Status Badge -->
<div class="inline-flex items-center gap-2 bg-surface-container-low px-4 py-1 rounded-full mb-3 shadow-sm">
<span class="w-2 h-2 rounded-full bg-secondary animate-pulse"></span>
<span class="font-label-caps text-label-caps tracking-widest text-on-surface font-semibold uppercase">
            Presente Confirmado com Sucesso
          </span>
</div>
<h2 class="font-headline-lg-mobile md:font-headline-lg text-headline-lg-mobile md:text-headline-lg text-on-surface tracking-tight max-w-lg leading-tight mt-1">
          Obrigado por celebrar nosso amor
        </h2>
<p class="font-body-md text-body-md text-on-surface-variant max-w-lg mt-3 font-light text-center leading-relaxed">
          Recebemos a notificação do seu presente com imensa alegria e profunda gratidão. Seu gesto torna a realização do nosso sonho em uma memória eterna e inesquecível.
        </p>
</div>
<!-- Gift Details Card (Stationery Style) -->
<div class="relative z-10 w-full bg-surface-container-low rounded-lg p-6 md:p-8 mb-8 shadow-sm">
<!-- Header of Receipt -->
<div class="flex flex-col md:flex-row md:items-center justify-between pb-6 mb-6 gap-4 bg-surface-container-high/40 p-4 rounded-lg">
<div class="flex items-center gap-4">
<!-- Gift Item Photo/Thumbnail -->
<div class="relative w-16 h-16 rounded-lg overflow-hidden bg-surface-container flex-shrink-0 shadow-sm">
<img class="w-full h-full object-cover" data-alt="Exquisite luxury gourmet gift box tied with natural silk taupe ribbon, filled with artisanal champagne, vintage porcelain cups, and floral accents in a warm editorial light." src="https://lh3.googleusercontent.com/aida-public/AB6AXuBsg0Q47VDVzvP-IPs4ABAFRwWqwW6YSavWNbYYeGa6ojAv__PpUiUzXp4-GQPGN8_eGZKnywW9pfxSaom925Tnf7nzTHhp9UbbcRGwCXlSjuwvavMqtu677vZQPiC3YpuhayakgV_y5ItCqEnfauIKO65W0bvwZd_M6hveaGF6Bq5v9WLI6TT14ILuHVDihj4txxYy2LTcpbIuqWPVxKxAWOPAXSIkfqtuNWupXOIK-5TWmxQAZVlk"/>
</div>
<div>
<span class="font-label-caps text-label-caps text-on-surface-variant uppercase tracking-wider block">Item Escolhido</span>
<h3 class="font-section-title text-xl md:text-2xl text-on-surface font-medium">Cota Lua de Mel: Paris &amp; Costa Amalfitana</h3>
</div>
</div>
<div class="flex md:flex-col items-baseline md:items-end justify-between">
<span class="font-label-caps text-label-caps text-on-surface-variant uppercase tracking-wider">Valor Contribuído</span>
<span class="font-headline-lg-mobile text-2xl md:text-3xl text-primary font-bold">R$ 480,00</span>
</div>
</div>
<!-- Key-Value Metadata Grid -->
<div class="grid grid-cols-2 md:grid-cols-4 gap-6 text-left pt-2">
<div>
<span class="font-label-caps text-label-caps text-on-surface-variant uppercase block mb-1">Código do Pedido</span>
<p class="font-body-md text-sm font-semibold tracking-wider text-on-surface font-mono">#KL-849204</p>
</div>
<div>
<span class="font-label-caps text-label-caps text-on-surface-variant uppercase block mb-1">Forma de Pagamento</span>
<p class="font-body-md text-sm font-medium text-on-surface flex items-center gap-1.5">
<span class="material-symbols-outlined text-base text-secondary">check_circle</span>
              PIX Instantâneo
            </p>
</div>
<div>
<span class="font-label-caps text-label-caps text-on-surface-variant uppercase block mb-1">Data &amp; Horário</span>
<p class="font-body-md text-sm text-on-surface" id="current-timestamp">Hoje às 15:42</p>
</div>
<div>
<span class="font-label-caps text-label-caps text-on-surface-variant uppercase block mb-1">Status do Repasse</span>
<p class="font-body-md text-sm font-medium text-secondary">Aprovado e Notificado</p>
</div>
</div>
<!-- Personal Dedication Quote Box -->
<div class="mt-8 pt-6 bg-surface-container-lowest/80 rounded-lg p-5 relative">
<div class="flex items-start gap-3">
<span class="material-symbols-outlined text-secondary text-2xl flex-shrink-0 mt-0.5">format_quote</span>
<div class="space-y-1">
<span class="font-label-caps text-label-caps text-on-surface-variant uppercase tracking-widest block">Mensagem enviada aos noivos:</span>
<p class="font-body-md text-on-surface italic text-sm md:text-base leading-relaxed">
                “Que o amor, a paciência e a cumplicidade guiem cada novo amanhecer de vocês. Estamos radiantes por fazer parte desta história tão linda. Com todo carinho, Mariana &amp; Stefan.”
              </p>
</div>
</div>
</div>
</div>
<!-- Elegantly Subdued Assistance & Context Callout (Inspired by reference note) -->
<div class="relative z-10 w-full bg-surface-container-high/50 rounded-lg p-4 md:p-5 flex flex-col md:flex-row items-center justify-between gap-4 mb-8">
<div class="flex items-center gap-3 text-left">
<div class="w-9 h-9 rounded-full bg-surface-container-lowest flex items-center justify-center flex-shrink-0 text-primary">
<span class="material-symbols-outlined text-lg">info</span>
</div>
<div>
<p class="font-body-md text-xs md:text-sm text-on-surface font-medium">Precisa consultar a situação ou atualizar o comprovante?</p>
<p class="font-body-md text-xs text-on-surface-variant">Caso tenha retornado por um link expirado ou precise de suporte, contate o Cerimonial Privé.</p>
</div>
</div>
<a class="inline-flex items-center gap-1.5 px-3 py-1.5 bg-surface-container-lowest text-on-surface rounded-full text-xs font-label-caps tracking-widest uppercase hover:bg-surface-variant transition-colors whitespace-nowrap shadow-sm" href="#contato">
<span>Falar no WhatsApp</span>
<span class="material-symbols-outlined text-xs">arrow_outward</span>
</a>
</div>
<!-- Action Buttons Grid -->
<div class="relative z-10 flex flex-col sm:flex-row items-center justify-center gap-4 w-full pt-2">
<a class="w-full sm:w-auto text-center px-8 py-3.5 rounded-full bg-primary text-on-primary font-label-caps text-label-caps uppercase tracking-widest hover:opacity-90 shadow-md transition-all" href="/">
          Voltar ao Início
        </a>
<a class="w-full sm:w-auto text-center px-8 py-3.5 rounded-full bg-surface-container-low text-on-surface font-label-caps text-label-caps uppercase tracking-widest hover:bg-surface-variant transition-all" href="/presentes">
          Ver Outros Presentes
        </a>
<button class="w-full sm:w-auto inline-flex items-center justify-center gap-2 px-6 py-3.5 rounded-full text-on-surface-variant hover:text-on-surface font-label-caps text-label-caps uppercase tracking-widest transition-colors" onclick="window.print()">
<span class="material-symbols-outlined text-base">download</span>
<span>Baixar Comprovante</span>
</button>
</div>
</div>
<!-- Editorial Inspiration Reference Visual Section (Subtle Footer Gallery) -->
<div class="mt-16 w-full flex flex-col items-center">
<div class="flex items-center justify-center gap-4 w-full mb-6">
<div class="h-px bg-surface-container-high flex-1"></div>
<span class="font-label-caps text-label-caps text-on-surface-variant uppercase tracking-[0.2em]">Memória Afetiva</span>
<div class="h-px bg-surface-container-high flex-1"></div>
</div>
<div class="grid grid-cols-1 md:grid-cols-2 gap-6 w-full">
<!-- Card 1: Warm Couple Moment -->
<div class="relative bg-surface-container-lowest rounded-xl overflow-hidden shadow-sm p-4 flex items-center gap-4">
<div class="w-24 h-24 rounded-lg overflow-hidden flex-shrink-0">
<img class="w-full h-full object-cover" data-alt="Refined candid portrait of Kleyon and Liandra walking together on an intimate coastal terrace, golden hour sunlight, soft focus, sophisticated editorial aesthetic." src="https://lh3.googleusercontent.com/aida-public/AB6AXuBVCqvcIw5RmO-OSQ5987_iqkLTCrCKJR9mzlKjJiHtL-1tine_17ti0JhphYC1Qy0RZXQd2FB5pmyXsjnCMw3O7Yxhc7VBASiDNDzdNcW3Cj8nNyiVyfdDBLGjp4t-oTFg6PxflYjir7nuUfkEzYjLRCnoptLRqhpk4r4dBbIj3PerSUT_sQHvBFPp9L1fExkDPSfINGJZbjIVoRhbEol8Su-3EDEoWKAWB24mVIp0wbN5L7BKM_x2"/>
</div>
<div class="flex flex-col">
<span class="font-label-caps text-label-caps text-secondary uppercase tracking-widest">O Grande Dia</span>
<h4 class="font-section-title text-lg text-on-surface">Celebração de Casamento</h4>
<p class="font-body-md text-xs text-on-surface-variant mt-1 font-light">
              24 de Outubro • Cerimônia &amp; Recepção
            </p>
</div>
</div>
<!-- Card 2: Visual Link to Reference Document Context -->
<div class="relative bg-surface-container-lowest rounded-xl overflow-hidden shadow-sm p-4 flex items-center gap-4">
<div class="w-24 h-24 rounded-lg overflow-hidden flex-shrink-0 bg-surface-container">
<img class="w-full h-full object-cover" src="https://lh3.googleusercontent.com/aida-public/AB6AXuAMqicLC8jmryJO8xbodF-bEx1Q7F_E4N66Dd7W7fXYe-97hV4iEFZS7Q9fwMymnNGh7KtunYLgXvSUaraqoQ1ipQRvMDov8FNXd3FnhYf-GMGRDHu1pwkoVQ9uFe6vurNsjKNuQz0AOq9E-YZr8vZ1A9YxtgPUhXo-Wh2IR66AhwSy6X6-IbdEeHwBR7YYtjtxmQb6TTJrZfOmbdK5ij4nTD4IxDviL58J9j1IK2rARRBKrAjBpaq-AmuS1Qq1V2RR1g"/>
</div>
<div class="flex flex-col">
<span class="font-label-caps text-label-caps text-on-surface-variant uppercase tracking-widest">Protocolo Digital</span>
<h4 class="font-section-title text-lg text-on-surface">Registro no Cerimonial</h4>
<p class="font-body-md text-xs text-on-surface-variant mt-1 font-light">
              Presente autenticado eletronicamente.
            </p>
</div>
</div>
</div>
<!-- Gentle Micro-quote Footer -->
<p class="font-section-title italic text-sm text-on-surface-variant text-center mt-10">
        “O amor não se mede pelo que se tem, mas pelo que se compartilha com quem se ama.”
      </p>
<span class="font-label-caps text-[10px] tracking-widest text-on-surface-variant/70 uppercase mt-2">
        Kleyon &amp; Liandra • Lista de Presentes &amp; Experiências
      </span>
</div>
</div>
</div>
<script>
  // Simple micro-interaction for dynamic receipt time formatting
  (function updateTime() {
    const timeElem = document.getElementById('current-timestamp');
    if (!timeElem) return;
    const now = new Date();
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    timeElem.textContent = `Hoje às ${hours}:${minutes}`;
  })();
</script></main></body></html>
```
