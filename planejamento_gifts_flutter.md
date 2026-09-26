# Planejamento da nova área de presentes em Flutter

Revisado em 26/09/2026 a partir do código do repositório. Este documento planeja a implementação; não declara as sprints executadas nem a fidelidade visual já validada.

## Objetivo e limites

Converter o **HTML incorporado ao final deste documento** em uma página Flutter funcional, responsiva e eficiente. `gift.html`, na raiz, é outra referência: o catálogo antigo com painel lateral e imagens de produtos em `contain`. Não deve orientar a nova composição.

Regras obrigatórias do pedido:

- Usar `K&L` na identificação visual do casal, seguindo as outras páginas. Não importar os nomes por extenso do header/footer da referência nem criar nova assinatura com eles no corpo ou no modal.
- Preservar `WeddingHeader`, seus estilos atuais nesta rota, menus, ações, alternância de tema e comportamento responsivo. Manter HOME, O CASAL, RECEPÇÃO, LISTA DE PRESENTES e PRESENÇA, inclusive o menu lateral atual.
- Preservar `WeddingFooter` integralmente. Hoje ele tem o monograma `K&L` e o copyright `© 2026 Kleyon & Liandra. Feito com amor.`; essa linha permanece porque o footer foi explicitamente definido como inalterado.
- Preservar `/presentes`, `/pagamento/retorno`, navegação e integração de pagamento existentes. As mudanças de layout ficam na área de presentes.
- Produtos, preços, disponibilidade e mensagens vêm dos contratos reais. Textos, imagens, chave PIX e produtos do HTML são exemplos, não dados de produção.

## Diagnóstico confirmado no código

| Área / arquivo | Situação atual | Consequência para a conversão |
|---|---|---|
| `lib/features/gifts/presentation/pages/gifts_page.dart` | `Scaffold`, drawer, header sobreposto em `Stack`, `TexturedBackground`, `Scrollbar` e `CustomScrollView`; reserva superior de 120 px. Abaixo, um `Row` com filtro de 256 px e catálogo. | Recompor apenas o conteúdo; manter um único scroll vertical e o espaço necessário para o header. |
| `GiftsPage` / scroll | Desktop web usa `resolveWebScrollMode()`, scroll nativo ou `WebSmoothScroll`; breakpoint local de 900 px. Listener atual atualiza `_isScrolled`, mas o header recebe `isScrolled: true`. | Preservar os modos de scroll. Remover listener/estado redundante nesta página quando não houver consumidor, sem alterar o header compartilhado. |
| `gift_product_grid.dart` | Retorna `Column` com `GridView.builder(shrinkWrap: true)` não rolável; colunas de 1 a 4, gap 24 px e altura fixa 370 px; botão carregar mais. | **Não é um sliver.** Substituir por grid lazy no scroll principal; não encaixar o widget atual diretamente dentro de `SliverPadding`. |
| `gift_product_card.dart` | Imagem de 170 px, padding 16, `BoxFit.contain`, hover com escala e deslocamento, preço e botão; indisponível em cinza. Já configura `cacheWidth`. | Novo card precisa de capa, categoria, descrição, preço sugerido, CTA e rodapé. Altura de 370 px não acomoda o novo conteúdo. |
| `data/models/gift_product.dart` | Já possui `category`, `imageUrl`, `priceCents`, `available`, `isBestSeller`; não possui descrição nem modalidade de valor livre. | Adicionar descrição ao mapeamento; não recriar categoria. Valor livre exige contrato adicional. |
| `backend/WeddingRsvp.Api/Endpoints/PublicGiftEndpoints.cs` | `/api/gifts` já fornece `shortDescription`, `description`, categoria, preço, `soldOut` e imagem primária relativa; ordena por `DisplayOrder`. | Aproveitar o contrato existente para descrições e capas. Categorias reais são strings, sem garantia dos quatro códigos da referência. |
| `data/repositories/gift_repository.dart` | Busca o catálogo inteiro para produtos, contagem e categorias; filtra/pagina localmente; prioriza `featured`. | Inicialização bem-sucedida pode fazer três GETs; carregar mais faz outros dois. Centralizar snapshot e derivar resultados sem repetir downloads. |
| `gift_catalog_controller.dart` | `ChangeNotifier`, página de 10 itens, categorias múltiplas e sem busca; `isLoading` impede novo refresh durante carregamento. | Categoria exclusiva e busca combinadas; proteger contra resposta antiga, perda de alterações durante loading e notificações após dispose. |
| `gift_filter_panel.dart` / `gift_filter_sheet.dart` | Filtros atuais de ocasiões/categorias; repositório aplica apenas categorias. | Retirar painel/sheet da nova rota; não preservar controles sem efeito como filtros adicionais. |
| `cart_dialog.dart`, `checkout_dialog.dart`, `payment_repository.dart` | Carrinho/FAB, resumo, nome obrigatório e mensagem já implementados. Pedido envia `giftId`/`quantity`, nome, mensagem e chave de idempotência; abre checkout Asaas. | Adaptar a apresentação do checkout ao modal de dedicatória, reaproveitando envio e validações; evitar dois formulários sucessivos para os mesmos dados. |
| `backend/.../Models/GiftOrderRequest.cs` e `Endpoints/GiftOrderEndpoints.cs` | Nome até 100 e mensagem até 500 caracteres; servidor calcula preço a partir do catálogo e reserva estoque. Não recebe valor livre. | Modal não pode simular contribuição personalizada usando preço arbitrário no cliente. |
| `lib/core/theme` / `pubspec.yaml` | Playfair Display e Plus Jakarta Sans via `google_fonts`; card cita Bodoni por nome, sem registro local em `pubspec`. Paleta global difere da referência. | Declarar/carregar as fontes de fato e criar tokens locais de presentes; não mudar tema global para alcançar o HTML. |

A análise acima é estática, baseada nos arquivos. Comparação por screenshots e medições de desempenho são entregas da execução, não verificações já realizadas.

## Contrato visual para Flutter

A referência define uma coluna central com hero, filtros/busca, grid, contribuição personalizada, fechamento e footer. Não há sidebar na nova tela.

| Elemento | Conversão prevista |
|---|---|
| Container | Largura máxima 1200 px, centralizado; margens laterais 20 px em telas pequenas e 32 px em maiores. Reservar altura do header atual + respiro, sem sobreposição. |
| Hero | Cartão de largura máxima 896 px; padding 32/56 px, fundo claro, raio 8 px, sombra discreta e dois florais de linha. Label “Com Muito Amor & Gratidão”, título “Lista de Presentes & Memórias”, parágrafo de gratidão e três badges. |
| Tipografia | Playfair para hero/títulos/cards; Bodoni Moda para fechamento; Work Sans para corpo; Plus Jakarta Sans para labels. Hero 48/56 px no desktop, 32/40 px no mobile; fechamento 36/44; título de card 24 px; corpo 16/28 e descrição 14 px. |
| Cores locais | Primária `#6d5b4c`, secundária `#735c00`, superfície `#fbf9f8`, cartão `#ffffff`, superfície baixa `#f6f3f2`, texto secundário `#4e453f`; respeitar tema escuro com equivalentes legíveis. Não substituir `AppColors.primary` global. |
| Filtros | Cinco pills da referência com seleção exclusiva. Usar `Wrap`, como o HTML, permitindo múltiplas linhas; busca de até 288 px à direita somente quando houver espaço, abaixo e com largura disponível no mobile. Não forçar scroll horizontal nem um `Row` que estoure. |
| Grid | 1 coluna abaixo de 768 px, 2 de 768 a 1023, 3 a partir de 1024, gap 32 px. Calcular com a largura útil e acomodar margens. Limite de três colunas mesmo em monitor amplo. Esses breakpoints do conteúdo não alteram os do header. |
| Card | Capa de 256 px (`h-64` do HTML), `BoxFit.cover` sem padding interno; badge no topo a 16 px; corpo com padding 24/28 px; título à esquerda, descrição, linha “Presente sugerido”/preço, botão com `redeem` e texto “Presentear os Noivos”, rodapé com ícone de recado. |
| Valor livre | Mesmo card, label “Contribuição”, valor “Valor Livre”, botão “Contribuir com Amor” e rodapé “Com dedicatória pessoal”; condicionado à modalidade suportada pelo servidor. |
| Contribuição | Cartão com gradiente suave, padding 32/48 px; duas colunas em proporção 7:5 a partir de 1024 px, uma abaixo. Chave selecionável/copiável, CTA de recado e painel com passos 01–03. |
| Fechamento | Ícone `auto_stories`, título “Memórias que duram para sempre” e agradecimento, largura máxima 672 px. |
| Modal | Largura máxima 512 px, margens mínimas 16 px, padding 24/32 px; cabeçalho com item/valor, nome/família, mensagem e valor apenas quando livre, ações Voltar/Confirmar Presente. Conteúdo rolável com teclado aberto; foco, Escape e fechamento acessíveis. |
| Ritmo vertical | Hero e grid/contribuição com separação de 64 px; filtro com 40 px; fechamento com padding vertical 24 px. Ajustar o respiro anterior ao footer sem copiar o footer HTML. |

Altura dos cards deve ser calculada por breakpoint e escala de texto, reservando linhas para título/descrição e rodapé. Não usar `IntrinsicHeight` no grid. Em texto ampliado, reduzir colunas se necessário e aumentar a altura; o CTA não pode ser cortado. A truncagem de descrições extensas deve oferecer acesso ao texto completo no modal.

## Decisões de implementação

1. **Referência:** HTML ao final é o desenho alvo; aplicar as exceções de identidade/header/footer acima. Não reproduzir o JavaScript: busca e categoria precisam atuar juntas, ao contrário dos handlers independentes do protótipo.
2. **Filtros:** retirar sidebar e sheet da composição de `/presentes`; verificar usos antes de excluir arquivos. Manter categorias desconhecidas visíveis em “Todas”, sem converter dados silenciosamente.
3. **Categorias:** definir mapa entre valores reais do catálogo e `luademel`, `lar`, `momentos`, `cotas`. Cada código tem label visual separado. Categoria `cotas` não implica automaticamente preço livre. Cadastrar/ajustar conteúdo é uma tarefa explícita, sem migração presumida.
4. **Checkout:** o CTA de produto abre o formulário de dedicatória adaptado de `CheckoutDialog`. Entrada direta usa seleção explícita do produto; entrada pelo carrinho mantém os itens existentes e seu resumo. Não adicionar silenciosamente ao carrinho e pagar outros itens junto. Preservar FAB/carrinho como caminho secundário, com a mesma lógica de checkout. Centralizar abertura dos diálogos atualmente duplicada em página e grid.
5. **Pagamento:** manter Asaas, validação de URL, idempotência, estoque, tratamento de 409/502 e página de retorno. “Confirmar Presente” inicia pagamento; sucesso não pode ser inferido de um alerta ou da abertura do checkout.
6. **PIX:** a chave `amor@kleyoneliandra.com.br` é exemplo. Usar configuração pública validada para chave/beneficiário, sem segredos. Transferência direta não é automaticamente conciliada pelo checkout nem comprova pagamento ao copiar a chave. O CTA de contribuição personalizada deve criar pedido real com dedicatória pelo fluxo integrado.
7. **Entrega completa:** valor livre e PIX configurado têm dependências reais. Sem elas, entregar os produtos de preço fixo com os componentes dependentes ocultos e registrar entrega parcial; não declarar toda a referência concluída.

## Sprints e critérios de aceite

Sprints sequenciais, organizadas por entregas verificáveis. A duração depende da disponibilidade de conteúdo e da integração de contribuição livre; não foi estimada sem essas informações.

### Sprint 0 — Referência verificável e contratos

**Objetivo:** fixar medidas e dados antes de construir componentes.

- Extrair uma cópia executável do HTML incorporado para comparar em navegador, sem CDN/JavaScript virar dependência do app Flutter.
- Capturar referência e tela atual em 390, 768, 1024 e 1440 px; separar visualmente o corpo dos elementos compartilhados preservados.
- Inventariar categorias, descrições, capas, disponibilidade e ordenação reais. Definir mapa de categorias e o conteúdo ausente, incluindo textos que mencionem nomes completos na referência.
- Registrar configuração pública necessária ao PIX e desenhar contrato de contribuição livre: modalidade do item, valor em centavos, limites, validação, pedido, gateway e retorno.
- Capturar baseline de rede, tempo de carregamento e scroll com catálogo pequeno e fixture de pelo menos 100 itens.

**Aceite:** screenshots/medidas arquivados, mapa de dados definido e dependências listadas. Sem inventar produtos, chave PIX ou recursos do backend.

### Sprint 1 — Catálogo e estado eficientes

**Arquivos:** modelo/filtro/repositório/controller de gifts; testes correspondentes.

- Mapear `shortDescription` e `description` já disponíveis, mantendo compatibilidade com registros vazios; título/badge permanecem informados mesmo sem descrição.
- Resolver URLs relativas e absolutas corretamente; manter placeholder para capa ausente ou inválida.
- Compartilhar uma requisição de catálogo em andamento e guardar snapshot na instância do repositório/controller. Derivar categorias, contagem, filtro e páginas do mesmo snapshot.
- Categoria exclusiva + busca por nome/descrição, com normalização de caixa/acentos e debounce de aproximadamente 250 ms. Toda alteração reinicia página e recalcula contagem/`hasMore`.
- Aplicar seleção antes de paginar; ordenação determinística. Preservar destaque atual, com ordem recebida da API como desempate.
- Garantir que a última busca/seleção prevaleça mesmo durante loading; cancelar timers, proteger notificações após dispose e distinguir loading inicial, incremental e refresh.
- Invalidar snapshot em refresh explícito, conflito de estoque e retorno de pagamento. Conectar invalidação ao ciclo real da página, sem polling contínuo.
- Preservar itens carregados em erro de “carregar mais”, com retry visível; detectar fim pelo total filtrado, evitando página vazia extra quando total é múltiplo de 10.

**Aceite:** uma requisição compartilhada na abertura bem-sucedida; busca, filtros e carregar mais locais não repetem GET. Testes cobrem combinação de filtros, races, contagem/paginação, erros e invalidação. Paginação remota fica para crescimento comprovado do catálogo, não é uma capacidade atual da API.

### Sprint 2 — Estrutura responsiva e seções estáticas

**Arquivos:** `gifts_page.dart`; novos `gifts_hero_section.dart`, `gifts_category_chips.dart`, `gifts_closing_section.dart` e tokens locais de gifts.

- Introduzir container central e composição de slivers descrita abaixo; tirar `Row`/sidebar sticky e sheet desta rota.
- Criar hero, florais estáticos com `CustomPainter` e badges em `Wrap`; não adicionar pacote SVG para dois desenhos simples.
- Implementar pills/busca conectados ao controller, sem alterar navegação compartilhada.
- Configurar as quatro famílias/pesos usados. Preferir fontes empacotadas e declaradas no `pubspec.yaml`, evitando carregamento dependente de rede e fallback visual inesperado.
- Criar fechamento e reservar o local da contribuição, que só aparece funcional após a sprint 5.
- Preservar textura existente inicialmente; medir antes de introduzir outra textura global. Animação de entrada curta e única, respeitando preferência por movimento reduzido.

**Aceite:** hierarquia, margens, cores e fontes conferidas nas quatro larguras; header/footer atuais sem mudanças; nenhum overflow ou scroll vertical aninhado. Alteração de busca não reconstrói hero/footer.

### Sprint 3 — Grid lazy e cards fiéis

**Arquivos:** `gift_product_grid.dart`, `gift_product_card.dart`, `gift_price.dart` e testes existentes.

- Converter grid para `SliverGrid` com `SliverChildBuilderDelegate`, indexação/keys por ID; estados e carregar mais em slivers separados. Adaptar consumidores/testes à nova API.
- Implementar 1/2/3 colunas, capa 256 px, categoria, descrição e novos CTAs/rodapé. Definir altura por largura/escala de texto após comparação; abandonar 370 px.
- Dimensionar imagem pela largura renderizada e DPR com limite razoável, preservando a otimização existente. Verificar efeito de `cacheWidth` no renderer web usado; thumbnails no servidor podem ser necessários para reduzir bytes reais.
- Placeholder estável sem spinner animado por card; carregamento/erro não alteram geometria. Zoom de 1,05 somente na área da imagem, com clipping local.
- Preservar estado indisponível em cinza, label PRESENTEADO e ação desativada. Medir `ColorFiltered`/opacidade antes de mudar o efeito; atualizar teste estrutural se a implementação mudar, mantendo teste comportamental.
- Badge com fundo sólido ou semitransparente; não criar `BackdropFilter` em cada card. Sombra discreta e animação localizada, sem animar dimensões do grid.

**Aceite:** cards comparados ao HTML, CTA inteiro em 390 px e texto ampliado; estoque/preços corretos. Com 100 itens, construção segue viewport/cache do sliver em vez de layout do catálogo inteiro.

### Sprint 4 — Dedicatória e checkout de preço fixo

**Arquivos:** `checkout_dialog.dart`, `cart_dialog.dart`, página/grid e coordenação compartilhada do fluxo dentro de gifts.

- Adaptar visual do checkout existente ao modal “Presentear com Amor”. Extrair componente de formulário apenas se útil; não duplicar envio em um novo modal independente.
- Abrir por item ou por carrinho com resumo coerente. Nome obrigatório até 100 caracteres, mensagem até 500; preservar dados em erro e impedir duplo envio enquanto processa.
- Oferecer Voltar coerente com a origem: fecha para catálogo na entrada direta, retorna ao carrinho na entrada pelo carrinho.
- Preservar tratamento de indisponibilidade, falha de gateway, tentativas e abertura segura do checkout. Idempotência deve acompanhar a mesma tentativa; alterações de payload exigem verificar o contrato, não reutilizar cegamente uma chave.
- Garantir acessibilidade, foco, teclado, scroll do modal e feedback de envio. Confirmar o estado efetivo somente pelo fluxo existente de retorno/backend.

**Aceite:** escolher item → dedicatória → pedido real → checkout → retorno funciona em ambiente de teste. Carrinho de vários itens mantém soma/quantidades; nenhum formulário duplicado e nenhum pagamento simulado.

### Sprint 5 — Contribuição livre e seção PIX

**Dependência:** contrato da sprint 0 e fluxo fixo da sprint 4. Esta sprint inclui backend; não é apenas um widget.

- Implementar modalidade explícita de contribuição e valor informado em centavos no contrato/modelo. Validar limites e elegibilidade no servidor; preços fixos continuam definidos pelo catálogo.
- Integrar valor livre a snapshots/totais, gateway, idempotência, mensagens e retorno. Atualizar administração/cadastro se necessário para configurar a modalidade sem depender do nome da categoria.
- Expor apenas configuração pública necessária ao PIX. Criar `gifts_pix_section.dart` com chave real, beneficiário, cópia via `Clipboard.setData` e feedback de sucesso/erro; quebra de chave longa sem overflow.
- Habilitar card “Cota de Afeto” e CTA “Enviar Recado com Presente” no mesmo checkout de contribuição livre. Não representar valor livre como produto de preço zero ou mutação do preço no Flutter.
- Explicar no conteúdo o caráter simbólico dos presentes e o caminho de contribuição; texto sobre livro/experiências deve corresponder ao que será entregue. Definir se haverá registro separado de recado para PIX direto; isso não existe no contrato atual e, se necessário, requer endpoint próprio.

**Aceite:** contribuição personalizada paga em ambiente de teste, valor validado pelo servidor e dedicatória registrada; cópia da chave não produz status pago. Sem configuração válida, componente dependente não oferece ação falsa. Regressões de produtos fixos/estoque verificadas.

### Sprint 6 — Validação visual, funcional e desempenho

- Comparar screenshots com a referência do corpo nas quatro larguras, usando dados/imagens controlados. Revisar hero, wraps, capas, alturas, tipografia, espaços, seção PIX, fechamento e modal.
- Validar 320 px, limites 767/768 e 1023/1024, header em seu breakpoint próprio, texto em 200%, tema escuro, toque, mouse, Tab/Enter/Escape e teclado mobile.
- Testar carregamento, catálogo vazio, busca sem resultados, imagem quebrada, categoria desconhecida, erro inicial/incremental, esgotamento, 409/502, retry e retorno de pagamento.
- Executar `flutter analyze`, testes Flutter pertinentes e build web release. Se backend mudar, executar testes .NET de pedidos, estoque e pagamento, com casos de contribuição livre.
- Medir scroll nativo e smooth com o mesmo cenário da baseline em release/profile apropriado ao alvo. Registrar dispositivo, navegador, renderer, número de itens, requests/bytes, frames e memória.
- Usar orçamento de 16,7 ms por frame para alvo de 60 Hz como referência de medição; investigar picos repetidos e regressões, sem prometer FPS sem evidência. Comparar amostras repetidas com cache frio/quente.

**Aceite:** evidências visuais e funcionais anexadas, verificações concluídas, nenhuma regressão material frente à baseline; divergências e dependências remanescentes explícitas. A conversão só está concluída após esses critérios, não após criar os widgets.

## Composição técnica prevista

```text
Scaffold
├── drawer: WeddingSideMenu atual
├── FAB: carrinho atual, caminho secundário
└── Stack
    ├── TexturedBackground + Scrollbar + modo de scroll atual
    │   └── CustomScrollView (único scroll vertical)
    │       ├── SliverToBoxAdapter: reserva do header + respiro
    │       ├── SliverToBoxAdapter: hero centralizado (máx. 896 px)
    │       ├── SliverToBoxAdapter: filtros/busca (máx. 1200 px)
    │       ├── SliverToBoxAdapter: estado inicial/vazio/erro, quando aplicável
    │       ├── SliverPadding: margens + centralização calculadas
    │       │   └── SliverGrid: builder lazy de cards
    │       ├── SliverToBoxAdapter: loading incremental/retry/carregar mais
    │       ├── SliverToBoxAdapter: contribuição/PIX (quando habilitada)
    │       ├── SliverToBoxAdapter: fechamento + respiro
    │       └── SliverToBoxAdapter: WeddingFooter atual, largura total
    └── WeddingHeader atual sobreposto
```

Usar `SliverLayoutBuilder` ou constraints equivalentes para calcular margens e largura útil do grid; não envolver um grid lazy em `Column`/`shrinkWrap`. Rebuilds devem acompanhar apenas filtros, resultados ou carrinho. Aplicar `const` nas seções estáticas e `RepaintBoundary` somente quando a medição mostrar benefício; evitar fronteiras, precache de todo o catálogo e efeitos caros por padrão.

As escolhas de construção lazy, rebuilds locais e redução de camadas/medidas intrínsecas seguem as [boas práticas oficiais de desempenho do Flutter](https://docs.flutter.dev/perf/best-practices). Os números de baseline e os ganhos específicos deste projeto ainda precisam ser medidos.

## Controle de conclusão

- [ ] Sprint 0: referência, baseline e contratos definidos.
- [ ] Sprint 1: snapshot único, busca combinada e estado robusto.
- [ ] Sprint 2: corpo responsivo, fontes e seções estáticas.
- [ ] Sprint 3: grid lazy e cards completos.
- [ ] Sprint 4: dedicatória integrada ao pagamento fixo existente.
- [ ] Sprint 5: valor livre real e PIX configurado.
- [ ] Sprint 6: evidências visuais, testes e medições aprovados.
- [ ] `K&L`, menus/header e footer preservados conforme o pedido.

## HTML original de referência

Preservado abaixo para consulta e extração na sprint 0. Suas identidades, header/footer, chave PIX, dados fictícios e handlers de demonstração não sobrepõem as regras e contratos deste planejamento.

```html
<!DOCTYPE html>

<html class="light" lang="en"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>Kleyon &amp; Liandra - Gift Registry</title>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com" rel="preconnect"/>
<link crossorigin="" href="https://fonts.gstatic.com" rel="preconnect"/>
<link href="https://fonts.googleapis.com/css2?family=Bodoni+Moda:ital,opsz,wght@0,6..96,400..900;1,6..96,400..900&amp;family=Playfair+Display:ital,wght@0,400..900;1,400..900&amp;family=Plus+Jakarta+Sans:ital,wght@0,200..800;1,200..800&amp;family=Work+Sans:ital,wght@0,100..900;1,100..900&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<script id="tailwind-config">
        tailwind.config = {
            darkMode: "class",
            theme: {
                extend: {
                    "colors": {
                        "inverse-surface": "#303030",
                        "secondary-fixed-dim": "#e9c349",
                        "outline-variant": "#d1c4bb",
                        "surface-bright": "#fbf9f8",
                        "background": "#fbf9f8",
                        "secondary-fixed": "#ffe088",
                        "on-secondary-fixed-variant": "#574500",
                        "surface-container-highest": "#e4e2e1",
                        "inverse-on-surface": "#f3f0f0",
                        "on-background": "#1b1c1c",
                        "on-primary-container": "#48392c",
                        "surface-dim": "#dcd9d9",
                        "outline": "#80756e",
                        "tertiary-container": "#a8a6a3",
                        "on-error-container": "#93000a",
                        "on-tertiary-container": "#3c3c39",
                        "primary-fixed": "#f7decb",
                        "on-secondary-fixed": "#241a00",
                        "tertiary-fixed": "#e5e2de",
                        "surface-container": "#f0eded",
                        "surface-container-low": "#f6f3f2",
                        "secondary-container": "#fed65b",
                        "surface-container-lowest": "#ffffff",
                        "primary-container": "#b8a291",
                        "surface-variant": "#e4e2e1",
                        "tertiary": "#5f5e5b",
                        "on-tertiary": "#ffffff",
                        "on-surface-variant": "#4e453f",
                        "error-container": "#ffdad6",
                        "primary-fixed-dim": "#dac2b0",
                        "on-primary": "#ffffff",
                        "surface-tint": "#6d5b4c",
                        "on-primary-fixed": "#26190e",
                        "on-tertiary-fixed-variant": "#474744",
                        "on-secondary-container": "#745c00",
                        "on-surface": "#1b1c1c",
                        "surface": "#fbf9f8",
                        "on-error": "#ffffff",
                        "surface-container-high": "#eae8e7",
                        "error": "#ba1a1a",
                        "on-tertiary-fixed": "#1c1c1a",
                        "tertiary-fixed-dim": "#c8c6c2",
                        "on-primary-fixed-variant": "#544436",
                        "inverse-primary": "#dac2b0",
                        "secondary": "#735c00",
                        "primary": "#6d5b4c",
                        "on-secondary": "#ffffff"
                    },
                    "borderRadius": {
                        "DEFAULT": "0.125rem",
                        "lg": "0.25rem",
                        "xl": "0.5rem",
                        "full": "0.75rem"
                    },
                    "spacing": {
                        "section-padding": "80px",
                        "margin-mobile": "20px",
                        "unit-base": "8px",
                        "container-max": "1200px",
                        "gutter": "24px"
                    },
                    "fontFamily": {
                        "label-caps": ["Plus Jakarta Sans"],
                        "headline-lg": ["Playfair Display"],
                        "body-md": ["Work Sans"],
                        "headline-lg-mobile": ["Playfair Display"],
                        "section-title": ["Bodoni Moda"]
                    },
                    "fontSize": {
                        "label-caps": ["12px", { "lineHeight": "16px", "letterSpacing": "0.15em", "fontWeight": "600" }],
                        "headline-lg": ["48px", { "lineHeight": "56px", "letterSpacing": "-0.02em", "fontWeight": "700" }],
                        "body-md": ["16px", { "lineHeight": "28px", "fontWeight": "400" }],
                        "headline-lg-mobile": ["32px", { "lineHeight": "40px", "fontWeight": "700" }],
                        "section-title": ["36px", { "lineHeight": "44px", "fontWeight": "400" }]
                    }
                }
            }
        }
    </script>
<style>
        .texture-bg {
            background-image: url("data:image/svg+xml,%3Csvg width='100' height='100' viewBox='0 0 100 100' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath d='M0 50 Q 25 25 50 50 T 100 50' fill='none' stroke='%23d1c4bb' stroke-width='0.5' stroke-dasharray='5,5' opacity='0.2'/%3E%3C/svg%3E");
            background-repeat: repeat;
        }
        .custom-scrollbar::-webkit-scrollbar {
            width: 4px;
        }
        .custom-scrollbar::-webkit-scrollbar-track {
            background: transparent;
        }
        .custom-scrollbar::-webkit-scrollbar-thumb {
            background: #d1c4bb;
            border-radius: 4px;
        }
    </style>
<meta content="web_dashboard" name="shell-type"/></head>
<body class="bg-background text-on-background font-body-md antialiased texture-bg min-h-screen flex flex-col">
<!-- TopNavBar -->
<nav class="bg-surface/90 backdrop-blur-md text-primary font-label-caps text-label-caps fixed top-0 w-full z-50 border-b border-outline-variant/30 flex justify-between items-center px-8 py-4 max-w-container-max mx-auto transition-all ease-in-out duration-300">
<div class="font-headline-lg text-headline-lg-mobile text-primary">Kleyon &amp; Liandra</div>
<div class="hidden md:flex space-x-6">
<a class="text-on-surface-variant hover:text-primary transition-colors hover:text-secondary duration-300" href="#">Home</a>
<a class="text-on-surface-variant hover:text-primary transition-colors hover:text-secondary duration-300" href="#">Our Story</a>
<a class="text-on-surface-variant hover:text-primary transition-colors hover:text-secondary duration-300" href="#">Wedding Party</a>
<a class="text-on-surface-variant hover:text-primary transition-colors hover:text-secondary duration-300" href="#">Ceremony</a>
<a class="text-on-surface-variant hover:text-primary transition-colors hover:text-secondary duration-300" href="#">RSVP</a>
<a class="text-secondary border-b border-secondary pb-1 hover:text-secondary duration-300" href="#">Gift Registry</a>
</div>
<button class="hidden md:block bg-primary text-on-primary px-6 py-2 uppercase tracking-wider hover:bg-primary-container transition-colors">RSVP</button>
<button class="md:hidden text-primary">
<span class="material-symbols-outlined">menu</span>
</button>
</nav>
<main class="flex-grow pt-24 pb-section-padding px-4 md:px-8 max-w-container-max mx-auto w-full flex flex-col lg:flex-row gap-8"><div class="flex flex-col w-full">
<!-- Introductory Romance Card & Gratitude -->
<section class="relative w-full mb-16">
<div class="relative overflow-hidden rounded-xl bg-surface-container-lowest shadow-sm p-8 md:p-14 text-center max-w-4xl mx-auto">
<!-- Subtle Decorative Floral Line Illustration Background -->
<div class="absolute -top-12 -right-12 w-48 h-48 opacity-10 pointer-events-none text-primary">
<svg fill="none" stroke="currentColor" stroke-width="1.5" viewbox="0 0 200 200">
<path d="M40 160 C 60 110, 110 90, 160 50 C 130 90, 110 140, 70 170 Z"></path>
<path d="M100 100 C 120 70, 150 70, 170 90 C 150 110, 120 120, 100 100 Z"></path>
<path d="M70 130 C 50 110, 50 80, 80 80 C 90 100, 85 120, 70 130 Z"></path>
</svg>
</div>
<div class="absolute -bottom-10 -left-10 w-44 h-44 opacity-10 pointer-events-none text-secondary">
<svg fill="none" stroke="currentColor" stroke-width="1.5" viewbox="0 0 200 200">
<path d="M30 140 C 70 130, 90 90, 130 40 C 110 80, 90 120, 60 150 Z"></path>
<path d="M90 90 C 110 70, 140 80, 150 100 C 130 110, 110 110, 90 90 Z"></path>
</svg>
</div>
<div class="inline-flex items-center gap-2 mb-4">
<span class="w-8 h-px bg-secondary/50"></span>
<span class="font-label-caps text-label-caps text-secondary uppercase tracking-widest">Com Muito Amor &amp; Gratidão</span>
<span class="w-8 h-px bg-secondary/50"></span>
</div>
<h1 class="font-headline-lg text-headline-lg text-primary mb-6">
        Lista de Presentes &amp; Memórias
      </h1>
<p class="font-body-md text-body-md text-on-surface-variant max-w-2xl mx-auto leading-relaxed mb-8">
        A sua presença na celebração da nossa união é o maior presente que poderíamos receber. Caso deseje nos homenagear de forma especial, preparamos com carinho esta lista de experiências e mimos que transformarão o início da nossa jornada em memórias inesquecíveis.
      </p>
<div class="flex flex-wrap justify-center items-center gap-6 pt-4 text-left">
<div class="flex items-center gap-3 bg-surface-container-low px-5 py-3 rounded-lg">
<span class="material-symbols-outlined text-secondary text-2xl">favorite</span>
<div>
<div class="font-label-caps text-[11px] text-secondary">EXPERIÊNCIAS REAIS</div>
<div class="font-body-md text-sm text-on-surface">Momentos da lua de mel e afeto</div>
</div>
</div>
<div class="flex items-center gap-3 bg-surface-container-low px-5 py-3 rounded-lg">
<span class="material-symbols-outlined text-primary text-2xl">volunteer_activism</span>
<div>
<div class="font-label-caps text-[11px] text-primary">CONTRIBUIÇÃO AFETIVA</div>
<div class="font-body-md text-sm text-on-surface">Seguro, simples e com dedicatória</div>
</div>
</div>
<div class="flex items-center gap-3 bg-surface-container-low px-5 py-3 rounded-lg">
<span class="material-symbols-outlined text-on-surface-variant text-2xl">mail</span>
<div>
<div class="font-label-caps text-[11px] text-on-surface-variant">RECADO AOS NOIVOS</div>
<div class="font-body-md text-sm text-on-surface">Mensagens guardadas no nosso livro</div>
</div>
</div>
</div>
</div>
</section>
<!-- Filter & Search Section -->
<section class="w-full mb-10">
<div class="flex flex-col md:flex-row items-center justify-between gap-6 pb-6">
<!-- Category Tabs -->
<div class="flex flex-wrap items-center gap-2" id="filter-container">
<button class="filter-btn active-filter px-5 py-2.5 rounded-full font-label-caps text-label-caps transition-all duration-300 bg-primary text-on-primary shadow-sm" onclick="filterRegistry('all', this)">
          Todas as Lembranças
        </button>
<button class="filter-btn px-5 py-2.5 rounded-full font-label-caps text-label-caps transition-all duration-300 bg-surface-container-lowest text-on-surface-variant hover:text-primary hover:bg-surface-container-low" onclick="filterRegistry('luademel', this)">
          Lua de Mel &amp; Experiências
        </button>
<button class="filter-btn px-5 py-2.5 rounded-full font-label-caps text-label-caps transition-all duration-300 bg-surface-container-lowest text-on-surface-variant hover:text-primary hover:bg-surface-container-low" onclick="filterRegistry('lar', this)">
          Nosso Novo Lar
        </button>
<button class="filter-btn px-5 py-2.5 rounded-full font-label-caps text-label-caps transition-all duration-300 bg-surface-container-lowest text-on-surface-variant hover:text-primary hover:bg-surface-container-low" onclick="filterRegistry('momentos', this)">
          Jantares &amp; Momentos
        </button>
<button class="filter-btn px-5 py-2.5 rounded-full font-label-caps text-label-caps transition-all duration-300 bg-surface-container-lowest text-on-surface-variant hover:text-primary hover:bg-surface-container-low" onclick="filterRegistry('cotas', this)">
          Cotas Flexíveis
        </button>
</div>
<!-- Live Search / Filter Input -->
<div class="relative w-full md:w-72">
<span class="material-symbols-outlined absolute left-3.5 top-1/2 -translate-y-1/2 text-tertiary text-lg">search</span>
<input class="w-full pl-10 pr-4 py-2.5 bg-surface-container-lowest rounded-full font-body-md text-sm text-on-surface placeholder:text-outline focus:outline-none focus:ring-1 focus:ring-secondary/40 shadow-sm" id="registry-search" oninput="handleSearch(this.value)" placeholder="Buscar lembrança ou cota..." type="text"/>
</div>
</div>
</section>
<!-- Gift Registry Grid -->
<section class="w-full mb-16">
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8" id="registry-grid">
<!-- Card 1 -->
<article class="registry-item flex flex-col bg-surface-container-lowest rounded-xl overflow-hidden shadow-sm hover:shadow-md transition-all duration-300 group" data-category="luademel">
<div class="relative h-64 overflow-hidden bg-surface-container">
<img class="w-full h-full object-cover transition-transform duration-700 group-hover:scale-105" data-alt="Romantic wooden gondola gliding smoothly through a tranquil Venetian canal in warm afternoon golden hour light, historical weathered Italian facades and soft rippling emerald water reflecting the serene sunset." src="https://lh3.googleusercontent.com/aida-public/AB6AXuACGZBIYqSsQTww-R1ZQmfwBekZg8UVZNWsXBZCmrm574Cyh5YwdoN3okMkCi5CvV5y33_ZKyvf8DjDwVmQrnN0nYpa920WUcMxibAKkinad6bw9PKKQL1_KhOitK0lOZvWWGbkz_Shpl2QnRqYaOU0gIL-iTznuaF2ae4h_NXYng4sG4LgF_6_LaT3HewBavG3vQ8bbOyAR3C7F5MoDRc3eDpjTRpIdXD_pCBUgktMXkNz-bwa_jkI"/>
<div class="absolute top-4 left-4 bg-surface-container-lowest/90 backdrop-blur-md px-3 py-1 rounded-sm font-label-caps text-[11px] text-secondary tracking-widest uppercase">
            Lua de Mel
          </div>
</div>
<div class="p-6 md:p-7 flex flex-col flex-grow">
<h3 class="font-headline-lg text-2xl text-primary mb-2.5">
            Passeio de Gôndola ao Pôr do Sol
          </h3>
<p class="font-body-md text-sm text-on-surface-variant leading-relaxed mb-6 flex-grow">
            Um dos sonhos de infância da Liandra: navegar pelas águas calmas de Veneza enquanto o sol colore os palacetes seculares.
          </p>
<div class="pt-4 flex flex-col gap-4">
<div class="flex items-baseline justify-between">
<span class="font-label-caps text-xs text-tertiary uppercase tracking-wider">Presente sugerido</span>
<span class="font-headline-lg text-xl text-primary font-bold">R$ 280</span>
</div>
<button class="w-full py-3 px-4 bg-primary text-on-primary font-label-caps text-label-caps tracking-widest uppercase rounded-lg hover:bg-primary-container transition-colors flex items-center justify-center gap-2 group-hover:bg-primary-container" onclick="openGiftModal('Passeio de Gôndola ao Pôr do Sol', 'R$ 280')">
<span class="material-symbols-outlined text-base">redeem</span>
<span>Presentear os Noivos</span>
</button>
<div class="flex items-center justify-center gap-1.5 text-xs text-tertiary">
<span class="material-symbols-outlined text-xs text-secondary">chat_bubble</span>
<span>Inclui cartão de felicitações</span>
</div>
</div>
</div>
</article>
<!-- Card 2 -->
<article class="registry-item flex flex-col bg-surface-container-lowest rounded-xl overflow-hidden shadow-sm hover:shadow-md transition-all duration-300 group" data-category="momentos">
<div class="relative h-64 overflow-hidden bg-surface-container">
<img class="w-full h-full object-cover transition-transform duration-700 group-hover:scale-105" data-alt="Intimate candlelit French dinner table on a Parisian cobblestone balcony overlooking distant soft city lights, fine linen cloth, elegant crystal glasses, and gentle floral centerpiece in warm taupe and amber tones." src="https://lh3.googleusercontent.com/aida-public/AB6AXuBcmd_j9FjxJn9HlOpMPxbLhylodwNaNQEUdfPinmzDzsa9upcfsjc_E7TELkFaQDPkdvSadARCFK7bZHvE_WCEpQwXfpXkIVi-6EvSztdY41_vFnXvvjPop7wNC8vPVAhhtXgTSTY_FuS0Y7yEuR1432ioWAjupaF3ilXurXex99RKMS0kOLoxKiWnPn1upGa91K-JSOFDcs_HK2vWTjbzV7CXEkUtrYaa40GdjD83688UJA1t5lgG"/>
<div class="absolute top-4 left-4 bg-surface-container-lowest/90 backdrop-blur-md px-3 py-1 rounded-sm font-label-caps text-[11px] text-secondary tracking-widest uppercase">
            Jantares &amp; Momentos
          </div>
</div>
<div class="p-6 md:p-7 flex flex-col flex-grow">
<h3 class="font-headline-lg text-2xl text-primary mb-2.5">
            Jantar à Luz de Velas em Paris
          </h3>
<p class="font-body-md text-sm text-on-surface-variant leading-relaxed mb-6 flex-grow">
            Uma noite inesquecível para degustar os sabores clássicos e brindar ao nosso casamento na Cidade Luz.
          </p>
<div class="pt-4 flex flex-col gap-4">
<div class="flex items-baseline justify-between">
<span class="font-label-caps text-xs text-tertiary uppercase tracking-wider">Presente sugerido</span>
<span class="font-headline-lg text-xl text-primary font-bold">R$ 420</span>
</div>
<button class="w-full py-3 px-4 bg-primary text-on-primary font-label-caps text-label-caps tracking-widest uppercase rounded-lg hover:bg-primary-container transition-colors flex items-center justify-center gap-2 group-hover:bg-primary-container" onclick="openGiftModal('Jantar à Luz de Velas em Paris', 'R$ 420')">
<span class="material-symbols-outlined text-base">redeem</span>
<span>Presentear os Noivos</span>
</button>
<div class="flex items-center justify-center gap-1.5 text-xs text-tertiary">
<span class="material-symbols-outlined text-xs text-secondary">chat_bubble</span>
<span>Inclui cartão de felicitações</span>
</div>
</div>
</div>
</article>
<!-- Card 3 -->
<article class="registry-item flex flex-col bg-surface-container-lowest rounded-xl overflow-hidden shadow-sm hover:shadow-md transition-all duration-300 group" data-category="lar">
<div class="relative h-64 overflow-hidden bg-surface-container">
<img class="w-full h-full object-cover transition-transform duration-700 group-hover:scale-105" data-alt="Artisanal ceramic tableware dinner plates in soothing beige and soft cream stoneware laid on an airy light wood dining table with fresh eucalyptus and natural linen textures." src="https://lh3.googleusercontent.com/aida-public/AB6AXuBmNxujXBysMGKFl0Rhh3sl402a1lyM4BL_svkhdsSA568IPmMxl4SBArHXE5aB8h7uqlCVX-4v78oBn483yOkb3_oF9p2f6wfIwTkatpmMQX13xi07roFFwMjoIiE7QUMXKbnxMF8hL5-mnRBXgo2IyyS6VXszEt65gLmNpp2Ukn7QWeKd4qNklYFeCXFzj88YsesAzTqvp4QWZ_WTlgwJY9Isx5WShTPwhYtiMFeR-LCnY9Nove2A"/>
<div class="absolute top-4 left-4 bg-surface-container-lowest/90 backdrop-blur-md px-3 py-1 rounded-sm font-label-caps text-[11px] text-secondary tracking-widest uppercase">
            Nosso Novo Lar
          </div>
</div>
<div class="p-6 md:p-7 flex flex-col flex-grow">
<h3 class="font-headline-lg text-2xl text-primary mb-2.5">
            Aparelho de Jantar para Receber
          </h3>
<p class="font-body-md text-sm text-on-surface-variant leading-relaxed mb-6 flex-grow">
            Para acolher amigos e família com mesa posta, afeto e conversas longas em nossa nova casa.
          </p>
<div class="pt-4 flex flex-col gap-4">
<div class="flex items-baseline justify-between">
<span class="font-label-caps text-xs text-tertiary uppercase tracking-wider">Presente sugerido</span>
<span class="font-headline-lg text-xl text-primary font-bold">R$ 360</span>
</div>
<button class="w-full py-3 px-4 bg-primary text-on-primary font-label-caps text-label-caps tracking-widest uppercase rounded-lg hover:bg-primary-container transition-colors flex items-center justify-center gap-2 group-hover:bg-primary-container" onclick="openGiftModal('Aparelho de Jantar para Receber', 'R$ 360')">
<span class="material-symbols-outlined text-base">redeem</span>
<span>Presentear os Noivos</span>
</button>
<div class="flex items-center justify-center gap-1.5 text-xs text-tertiary">
<span class="material-symbols-outlined text-xs text-secondary">chat_bubble</span>
<span>Inclui cartão de felicitações</span>
</div>
</div>
</div>
</article>
<!-- Card 4 -->
<article class="registry-item flex flex-col bg-surface-container-lowest rounded-xl overflow-hidden shadow-sm hover:shadow-md transition-all duration-300 group" data-category="lar">
<div class="relative h-64 overflow-hidden bg-surface-container">
<img class="w-full h-full object-cover transition-transform duration-700 group-hover:scale-105" data-alt="Sunlit morning kitchen scene with a premium minimalist stainless steel espresso machine pouring rich crema coffee into handmade cream ceramic cups with soft steam rising." src="https://lh3.googleusercontent.com/aida-public/AB6AXuDvUQ0ib6lrek55YCj2NALHX8f14aNHpwT7qSLOJpWv_-63N22WlNqpaoSMLAqJgnkVqOZS4J1cNG4ylOIiC33Y8HF7UWfo9a1wrIbX6ERS_QD8H0WSVibMrxAg1wZdgtiifuMxA-RufkTWbnUJb8DL5wcHyWtTadgAEN1MFWirV-AfRjjq_bP7p34iWxpUtwOn0W4x9Y2v7uiYuBhy-uYYynU3mfJfONsyT951VZJ9LbSOreMGWUFm"/>
<div class="absolute top-4 left-4 bg-surface-container-lowest/90 backdrop-blur-md px-3 py-1 rounded-sm font-label-caps text-[11px] text-secondary tracking-widest uppercase">
            Nosso Novo Lar
          </div>
</div>
<div class="p-6 md:p-7 flex flex-col flex-grow">
<h3 class="font-headline-lg text-2xl text-primary mb-2.5">
            Cafeteira para as Nossas Manhãs
          </h3>
<p class="font-body-md text-sm text-on-surface-variant leading-relaxed mb-6 flex-grow">
            Para começarmos cada dia lado a lado com café fresco, desacelerando o tempo antes da rotina.
          </p>
<div class="pt-4 flex flex-col gap-4">
<div class="flex items-baseline justify-between">
<span class="font-label-caps text-xs text-tertiary uppercase tracking-wider">Presente sugerido</span>
<span class="font-headline-lg text-xl text-primary font-bold">R$ 220</span>
</div>
<button class="w-full py-3 px-4 bg-primary text-on-primary font-label-caps text-label-caps tracking-widest uppercase rounded-lg hover:bg-primary-container transition-colors flex items-center justify-center gap-2 group-hover:bg-primary-container" onclick="openGiftModal('Cafeteira para as Nossas Manhãs', 'R$ 220')">
<span class="material-symbols-outlined text-base">redeem</span>
<span>Presentear os Noivos</span>
</button>
<div class="flex items-center justify-center gap-1.5 text-xs text-tertiary">
<span class="material-symbols-outlined text-xs text-secondary">chat_bubble</span>
<span>Inclui cartão de felicitações</span>
</div>
</div>
</div>
</article>
<!-- Card 5 -->
<article class="registry-item flex flex-col bg-surface-container-lowest rounded-xl overflow-hidden shadow-sm hover:shadow-md transition-all duration-300 group" data-category="luademel">
<div class="relative h-64 overflow-hidden bg-surface-container">
<img class="w-full h-full object-cover transition-transform duration-700 group-hover:scale-105" data-alt="Scenic cliffside coastal view overlooking the azure Mediterranean sea at sunset with two elegant champagne flutes clinking gently, soft golden glow reflecting off peaceful gentle waves." src="https://lh3.googleusercontent.com/aida-public/AB6AXuBw0Ow91iypXGv_sDZiv-t3wyjgHGIrXxxBBTWH5unNKL9UWWkYx7b0cLio1gZxzL5eT9kLTvhvfFLjSDAwQS64rwCIbyTweLIeeizjYCNMxz4rDbfNPD2934wip6hGY_cEyYZdlqYKctqdruKOi6rIwrxRuA7Wkax9A7pjpAVu0HvTNXVn7LPc22OVRBqKpCJQ5PK-KUAaDQRqRefXd4Xf5dISN3wHESfgJTJuFCg_U4iGbRmWZXcV"/>
<div class="absolute top-4 left-4 bg-surface-container-lowest/90 backdrop-blur-md px-3 py-1 rounded-sm font-label-caps text-[11px] text-secondary tracking-widest uppercase">
            Lua de Mel
          </div>
</div>
<div class="p-6 md:p-7 flex flex-col flex-grow">
<h3 class="font-headline-lg text-2xl text-primary mb-2.5">
            Primeiro Brinde à Beira-Mar
          </h3>
<p class="font-body-md text-sm text-on-surface-variant leading-relaxed mb-6 flex-grow">
            Celebrando as primeiras horas como recém-casados diante da infinitude do mar e do horizonte.
          </p>
<div class="pt-4 flex flex-col gap-4">
<div class="flex items-baseline justify-between">
<span class="font-label-caps text-xs text-tertiary uppercase tracking-wider">Presente sugerido</span>
<span class="font-headline-lg text-xl text-primary font-bold">R$ 190</span>
</div>
<button class="w-full py-3 px-4 bg-primary text-on-primary font-label-caps text-label-caps tracking-widest uppercase rounded-lg hover:bg-primary-container transition-colors flex items-center justify-center gap-2 group-hover:bg-primary-container" onclick="openGiftModal('Primeiro Brinde à Beira-Mar', 'R$ 190')">
<span class="material-symbols-outlined text-base">redeem</span>
<span>Presentear os Noivos</span>
</button>
<div class="flex items-center justify-center gap-1.5 text-xs text-tertiary">
<span class="material-symbols-outlined text-xs text-secondary">chat_bubble</span>
<span>Inclui cartão de felicitações</span>
</div>
</div>
</div>
</article>
<!-- Card 6 -->
<article class="registry-item flex flex-col bg-surface-container-lowest rounded-xl overflow-hidden shadow-sm hover:shadow-md transition-all duration-300 group" data-category="cotas">
<div class="relative h-64 overflow-hidden bg-surface-container">
<img class="w-full h-full object-cover transition-transform duration-700 group-hover:scale-105" data-alt="Delicate artistic photograph of fine handwritten wedding invitation letter with wax seal, soft linen fabric, dried olive branch and quiet warm natural light." src="https://lh3.googleusercontent.com/aida-public/AB6AXuDi3-gOBBk-RF3RqGlzLYw-Df2ZG_c5tyZ5Mvy5RD8RMSpAJ-TkJjimEjnIICaBXjQ4jrCKeap2LlPxPFm0hURHAE3U2GUVdiQjuD-V0Z3-XJUVMp0854LEFXRD9IaeUK6kQBS9ZS8H_azCtuTrvq1y0chgY3ezT_ZpuiTDREVLhe08FBWdCmWuAKQrom7WXOgkE_puka18SaVRn21IjNY3Mx0CUqWWYgm-GtChpNOQjmipyMHjTFBU"/>
<div class="absolute top-4 left-4 bg-surface-container-lowest/90 backdrop-blur-md px-3 py-1 rounded-sm font-label-caps text-[11px] text-secondary tracking-widest uppercase">
            Cotas Flexíveis
          </div>
</div>
<div class="p-6 md:p-7 flex flex-col flex-grow">
<h3 class="font-headline-lg text-2xl text-primary mb-2.5">
            Cota de Afeto: Escolha Livre
          </h3>
<p class="font-body-md text-sm text-on-surface-variant leading-relaxed mb-6 flex-grow">
            Sua contribuição com valor totalmente aberto para nos apoiar nos detalhes espontâneos do nosso início.
          </p>
<div class="pt-4 flex flex-col gap-4">
<div class="flex items-baseline justify-between">
<span class="font-label-caps text-xs text-tertiary uppercase tracking-wider">Contribuição</span>
<span class="font-headline-lg text-xl text-primary font-bold">Valor Livre</span>
</div>
<button class="w-full py-3 px-4 bg-primary text-on-primary font-label-caps text-label-caps tracking-widest uppercase rounded-lg hover:bg-primary-container transition-colors flex items-center justify-center gap-2 group-hover:bg-primary-container" onclick="openGiftModal('Cota de Afeto: Escolha Livre', 'Valor Livre')">
<span class="material-symbols-outlined text-base">redeem</span>
<span>Contribuir com Amor</span>
</button>
<div class="flex items-center justify-center gap-1.5 text-xs text-tertiary">
<span class="material-symbols-outlined text-xs text-secondary">chat_bubble</span>
<span>Com dedicatória pessoal</span>
</div>
</div>
</div>
</article>
</div>
</section>
<!-- Interactive Custom Contribution Card & PIX Section -->
<section class="w-full mb-16">
<div class="relative overflow-hidden rounded-xl bg-gradient-to-r from-surface-container to-surface-container-low p-8 md:p-12 shadow-sm">
<div class="grid grid-cols-1 lg:grid-cols-12 gap-8 items-center">
<div class="lg:col-span-7 flex flex-col gap-4">
<div class="inline-flex items-center gap-2">
<span class="material-symbols-outlined text-secondary text-sm">arrow_back_ios_new</span>
<span class="font-label-caps text-label-caps text-secondary uppercase tracking-widest">Contribuição Afetiva Personalizada</span>
</div>
<h2 class="font-headline-lg text-3xl md:text-4xl text-primary">
            Deseja presentear com um valor personalizado?
          </h2>
<p class="font-body-md text-body-md text-on-surface-variant leading-relaxed">
            "O amor não se mede pelo que se tem, mas pelo que se compartilha com quem se ama." 
            Você pode realizar uma transferência carinhosa direta via chave PIX dos noivos ou escolher a quantia que seu coração desejar.
          </p>
<div class="flex flex-wrap items-center gap-4 mt-2">
<div class="bg-surface-container-lowest px-4 py-3 rounded-lg flex items-center gap-3 shadow-xs">
<span class="material-symbols-outlined text-secondary">qr_code_2</span>
<div>
<div class="font-label-caps text-[11px] text-tertiary">CHAVE PIX (CASAMENTO)</div>
<div class="font-body-md font-semibold text-primary select-all" id="pix-key-val">amor@kleyoneliandra.com.br</div>
</div>
<button class="ml-2 text-primary hover:text-secondary p-1" onclick="copyPixKey()" title="Copiar Chave PIX">
<span class="material-symbols-outlined text-lg" id="copy-icon">content_copy</span>
</button>
</div>
<button class="bg-primary text-on-primary px-6 py-3.5 rounded-lg font-label-caps text-label-caps tracking-widest uppercase hover:bg-primary-container transition-colors flex items-center gap-2" onclick="openGiftModal('Presente Personalizado', 'Personalizado')">
<span class="material-symbols-outlined text-base">edit_note</span>
<span>Enviar Recado com Presente</span>
</button>
</div>
</div>
<div class="lg:col-span-5 bg-surface-container-lowest p-6 rounded-xl shadow-xs">
<div class="flex items-center gap-3 mb-4">
<div class="w-10 h-10 rounded-full bg-secondary-fixed/50 flex items-center justify-center text-on-secondary-fixed">
<span class="material-symbols-outlined text-xl">verified</span>
</div>
<div>
<h4 class="font-headline-lg text-lg text-primary">Como funciona este carinho?</h4>
<p class="text-xs text-on-surface-variant font-body-md">Transparência e significado</p>
</div>
</div>
<div class="space-y-3.5 text-sm font-body-md text-on-surface-variant">
<div class="flex gap-3">
<span class="text-secondary font-bold font-headline-lg">01.</span>
<span>Você escolhe um momento simbólico ou valor à vontade.</span>
</div>
<div class="flex gap-3">
<span class="text-secondary font-bold font-headline-lg">02.</span>
<span>Deixa uma mensagem sincera que será impressa em nosso livro de votos.</span>
</div>
<div class="flex gap-3">
<span class="text-secondary font-bold font-headline-lg">03.</span>
<span>Sua homenagem se reverte em momentos autênticos vividos a dois.</span>
</div>
</div>
</div>
</div>
</div>
</section>
<!-- FAQ / Gentle Assurance -->
<section class="w-full text-center py-6">
<div class="max-w-2xl mx-auto flex flex-col items-center gap-3">
<span class="material-symbols-outlined text-primary text-3xl">auto_stories</span>
<h3 class="font-section-title text-section-title text-primary">Memórias que duram para sempre</h3>
<p class="font-body-md text-sm text-on-surface-variant">
        Agradecemos profundamente por sonhar este novo capítulo ao nosso lado. Cada gesto de carinho ilumina ainda mais o caminho até o nosso "Sim".
      </p>
</div>
</section>
<!-- Graceful Gift & Dedication Modal -->
<div class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-inverse-surface/40 backdrop-blur-sm hidden opacity-0 transition-opacity duration-300" id="gift-modal">
<div class="bg-surface-container-lowest max-w-lg w-full rounded-xl shadow-xl overflow-hidden transform scale-95 transition-transform duration-300 relative" id="modal-box">
<!-- Modal Header -->
<div class="p-6 md:p-8 bg-surface-container-low flex justify-between items-start">
<div>
<span class="font-label-caps text-label-caps text-secondary uppercase tracking-widest block mb-1">Presentear com Amor</span>
<h3 class="font-headline-lg text-2xl text-primary" id="modal-item-title">Item Selecionado</h3>
<p class="text-sm font-body-md text-on-surface-variant mt-0.5" id="modal-item-value">Sugerido: R$ 0,00</p>
</div>
<button class="text-tertiary hover:text-primary p-1" onclick="closeGiftModal()">
<span class="material-symbols-outlined">close</span>
</button>
</div>
<!-- Modal Form -->
<form class="p-6 md:p-8 flex flex-col gap-5" onsubmit="handleSendGift(event)">
<div>
<label class="font-label-caps text-label-caps text-primary uppercase block mb-1.5">Seu Nome / Família</label>
<input class="w-full px-4 py-2.5 bg-surface-container-low rounded-lg font-body-md text-sm text-on-surface focus:outline-none focus:ring-1 focus:ring-secondary/50" placeholder="Ex: Tio Carlos e Família" required="" type="text"/>
</div>
<div class="hidden" id="custom-amount-field">
<label class="font-label-caps text-label-caps text-primary uppercase block mb-1.5">Valor da Contribuição (R$)</label>
<input class="w-full px-4 py-2.5 bg-surface-container-low rounded-lg font-body-md text-sm text-on-surface focus:outline-none focus:ring-1 focus:ring-secondary/50" placeholder="Ex: 250" type="number"/>
</div>
<div>
<label class="font-label-caps text-label-caps text-primary uppercase block mb-1.5">Sua Mensagem aos Noivos</label>
<textarea class="w-full px-4 py-2.5 bg-surface-container-low rounded-lg font-body-md text-sm text-on-surface focus:outline-none focus:ring-1 focus:ring-secondary/50 resize-none" placeholder="Escreva algumas palavras doces para aquecer nossos corações..." rows="3"></textarea>
</div>
<div class="bg-surface-container-low p-4 rounded-lg flex items-center justify-between text-xs text-on-surface-variant">
<span class="flex items-center gap-1.5">
<span class="material-symbols-outlined text-secondary text-sm">lock</span>
            Ambiente seguro e afetivo
          </span>
<span class="font-semibold text-primary">PIX ou Cartão</span>
</div>
<div class="flex items-center justify-end gap-3 pt-2">
<button class="px-5 py-2.5 text-on-surface-variant font-label-caps text-label-caps uppercase hover:text-primary transition-colors" onclick="closeGiftModal()" type="button">
            Voltar
          </button>
<button class="px-6 py-2.5 bg-primary text-on-primary font-label-caps text-label-caps uppercase rounded-lg hover:bg-primary-container transition-colors flex items-center gap-2" type="submit">
<span class="material-symbols-outlined text-base">send</span>
<span>Confirmar Presente</span>
</button>
</div>
</form>
</div>
</div>
<script>
    // Live category filter
    function filterRegistry(category, btnElement) {
      const items = document.querySelectorAll('.registry-item');
      const buttons = document.querySelectorAll('.filter-btn');

      buttons.forEach(btn => {
        btn.classList.remove('bg-primary', 'text-on-primary');
        btn.classList.add('bg-surface-container-lowest', 'text-on-surface-variant');
      });

      btnElement.classList.remove('bg-surface-container-lowest', 'text-on-surface-variant');
      btnElement.classList.add('bg-primary', 'text-on-primary');

      items.forEach(item => {
        if (category === 'all' || item.getAttribute('data-category') === category) {
          item.style.display = 'flex';
        } else {
          item.style.display = 'none';
        }
      });
    }

    // Search filter
    function handleSearch(keyword) {
      const term = keyword.toLowerCase();
      const items = document.querySelectorAll('.registry-item');
      items.forEach(item => {
        const title = item.querySelector('h3').textContent.toLowerCase();
        const desc = item.querySelector('p').textContent.toLowerCase();
        if (title.includes(term) || desc.includes(term)) {
          item.style.display = 'flex';
        } else {
          item.style.display = 'none';
        }
      });
    }

    // Modal behavior
    function openGiftModal(title, value) {
      const modal = document.getElementById('gift-modal');
      const modalBox = document.getElementById('modal-box');
      const titleElem = document.getElementById('modal-item-title');
      const valElem = document.getElementById('modal-item-value');
      const customField = document.getElementById('custom-amount-field');

      titleElem.textContent = title;
      valElem.textContent = value === 'Valor Livre' || value === 'Personalizado' ? 'Valor a definir por você' : 'Contribuição: ' + value;

      if (value === 'Valor Livre' || value === 'Personalizado') {
        customField.classList.remove('hidden');
      } else {
        customField.classList.add('hidden');
      }

      modal.classList.remove('hidden');
      setTimeout(() => {
        modal.classList.remove('opacity-0');
        modalBox.classList.remove('scale-95');
        modalBox.classList.add('scale-100');
      }, 10);
    }

    function closeGiftModal() {
      const modal = document.getElementById('gift-modal');
      const modalBox = document.getElementById('modal-box');

      modal.classList.add('opacity-0');
      modalBox.classList.remove('scale-100');
      modalBox.classList.add('scale-95');

      setTimeout(() => {
        modal.classList.add('hidden');
      }, 300);
    }

    function handleSendGift(e) {
      e.preventDefault();
      alert('Obrigado de todo o coração por fazer parte da nossa história! Em instantes você receberá os detalhes para completar o carinho.');
      closeGiftModal();
    }

    // PIX copy helper
    function copyPixKey() {
      const pixKey = document.getElementById('pix-key-val').textContent;
      navigator.clipboard.writeText(pixKey).then(() => {
        const icon = document.getElementById('copy-icon');
        icon.textContent = 'check';
        setTimeout(() => {
          icon.textContent = 'content_copy';
        }, 2000);
      });
    }
  </script>
</div></main>
<!-- Footer -->
<footer class="bg-surface-container-highest text-on-surface-variant font-body-md text-body-md w-full py-20 border-t border-secondary-fixed flex flex-col items-center justify-center space-y-8 px-margin-mobile text-center">
<div class="font-section-title text-section-title text-primary">Kleyon &amp; Liandra</div>
<div class="flex space-x-6">
<a class="text-on-surface-variant hover:text-secondary opacity-80 hover:opacity-100 transition-opacity" href="#">Privacy Policy</a>
<a class="text-on-surface-variant hover:text-secondary opacity-80 hover:opacity-100 transition-opacity" href="#">Contact Us</a>
<a class="text-on-surface-variant hover:text-secondary opacity-80 hover:opacity-100 transition-opacity" href="#">Guest Info</a>
</div>
<p class="text-sm">© 2024 Kleyon &amp; Liandra. Crafted with love.</p>
</footer>
</body></html>
```
