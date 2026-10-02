# Plano por sprints — desempenho da lista de presentes

## Objetivo e limite

Eliminar os travamentos de `/presentes` sem alterar o catálogo, a seleção de presentes, o carrinho, o checkout Asaas ou os estados de estoque. O plano registra a implementação local e mantém separadas as validações de desempenho e publicação ainda pendentes.

Trabalhar em TDD: para cada mudança de comportamento, escrever primeiro um teste que falha, fazer a menor correção, executar o teste novamente e só então refatorar. Testes de widget verificam comportamento; a melhora de desempenho precisa de medição em navegador real, pois um teste que apenas reproduz a árvore de widgets não mede fluidez.

## Diagnóstico inicial — 01/10/2026

1. O catálogo público publicado respondeu com **11 produtos**, **10 imagens** e **3.282 bytes de JSON** em aproximadamente **1,36 s** numa consulta isolada. O tamanho do JSON é pequeno; essa observação não elimina latência de rede nem mede o tempo até a primeira pintura.
2. `/presentes` e a home usam `SmoothWebScroll` no desktop. Ele chama `ScrollController.jumpTo` a cada tick de animação; cada atualização pode exigir novo layout/pintura do conteúdo visível. A página já possui o modo diagnóstico `?scroll=native`. Portanto, **há uma causa potencial compartilhada** com a experiência anterior de rolagem na home, mas não é possível afirmar que seja a única causa do travamento.
3. Uma comparação exploratória na página publicada, Chrome headless com GPU desabilitada, dez eventos de roda por execução: trabalho de script de **4,52 s e 4,73 s** no modo atual versus **3,21 s** no modo nativo. O teste não mediu frames nem garantiu a mesma posição final de rolagem; usar esses números só para priorizar uma comparação controlada na Sprint 0.
4. O grid já usa `SliverList` e mostra inicialmente até **10 itens**, portanto não é um grid que constrói todo o catálogo de uma vez. Mesmo assim, cada cartão mede texto com `TextPainter` durante `build`, usa sombras/`AnimatedContainer` e, quando esgotado, `ColorFiltered` mais `Opacity`. Essas operações podem ampliar o custo da rolagem e dos rebuilds.
5. A primeira imagem pública examinada tinha **69.040 bytes**, mas **1130 × 1169 pixels**; decodificada integralmente em RGBA, pode ocupar cerca de **5 MiB**. O servidor salva o WebP com as dimensões originais e entrega o mesmo arquivo ao catálogo. O `cacheWidth` do Flutter precisa ser validado no renderer web usado em produção; não assumir que ele reduz o download ou a decodificação.
6. `/api/images/{key}` serve arquivos pela API sem política explícita de cache. O `location ^~ /api/` do Nginx encaminha essas imagens à API; a regra de cache para `*.webp` do Nginx não se aplica a esse caminho. Isso pode tornar visitas repetidas mais caras.

Arquivos principais: `lib/features/gifts/presentation/pages/gifts_page.dart`, `lib/core/widgets/smooth_web_scroll.dart`, `lib/features/gifts/presentation/widgets/gift_product_grid.dart`, `lib/features/gifts/presentation/widgets/gift_product_card.dart`, `backend/WeddingRsvp.Api/Services/GiftImageStore.cs`, `backend/WeddingRsvp.Api/Endpoints/PublicGiftEndpoints.cs` e `nginx.conf`.

## Sprint 0 — Reproduzir e localizar o custo

1. Registrar dispositivo, navegador, renderer Flutter, largura de tela, número de produtos, velocidade de rede e se a visita é fria ou com cache. Testar desktop e um celular intermediário real.
2. Comparar `/presentes` e `/presentes?scroll=native` com a **mesma sequência de rolagem e posição final**. Capturar Performance/Flutter DevTools: tempo até conteúdo visível, frames acima de 16,7 ms no desktop/33 ms no celular, long tasks acima de 50 ms, uso de memória, repaints, imagens baixadas e bytes transferidos. Repetir três vezes por condição e guardar a mediana.
3. Separar custo de rede, decodificação de imagem, layout, pintura e script. Repetir com imagens bloqueadas temporariamente no DevTools e com a aba Network aberta; não modificar o catálogo de produção.
4. Registrar evidências e uma tabela de antes/depois no próprio plano. Se o modo nativo não melhorar consistentemente, não atribuir o problema à rolagem sem nova evidência.

**Aceite:** existe uma reprodução documentada e pelo menos uma causa dominante identificada por trace, com comparação justa entre os dois modos.

### Evidências da Sprint 0

| Dispositivo / Ambiente | Métricas | `/presentes` (com Smooth Scroll) | `/presentes?scroll=native` |
| :--- | :--- | :--- | :--- |
| **Desktop** (Ex: Chrome, CanvasKit) | Tempo até conteúdo visível |  |  |
| | Frames > 16.7ms |  |  |
| | Long tasks (> 50ms) |  |  |
| | Memória / Repaints |  |  |
| **Mobile** (Ex: Celular Android intermediário) | Tempo até conteúdo visível |  |  |
| | Frames > 33ms |  |  |
| | Long tasks (> 50ms) |  |  |
| | Memória / Repaints |  |  |

**Observações Adicionais (Rede, Decodificação de Imagens, etc):**
- ...

## Sprint 1 — Reduzir o custo da rolagem

1. Se a Sprint 0 confirmar a rolagem suavizada como causa relevante, escrever teste de widget para a escolha da física de scroll em `/presentes`: modo nativo por padrão, sem `SmoothWebScroll` e sem `NeverScrollableScrollPhysics`; conservar uma opção diagnóstica temporária para comparar, sem mudar a home.
2. Implementar essa escolha somente em `gifts_page.dart`. Validar roda do mouse, trackpad, toque, teclado, barra de rolagem e a abertura do carrinho no desktop e no celular.
3. Medir novamente nas mesmas condições da Sprint 0. Se não houver melhora perceptível e repetível, reavaliar a mudança antes de mantê-la.

**Aceite:** rolagem sem bloqueios perceptíveis no cenário reproduzido, navegação e interação preservadas, teste vermelho antes da alteração e verde depois.

## Sprint 2 — Baratear os cartões sem mudar o conteúdo

1. Usar o trace para verificar se `GiftProductCard.build`, `TextPainter`, sombras, `ColorFiltered` ou `Opacity` dominam o tempo. Não remover efeitos só por suspeita.
2. Para cada custo confirmado, escrever teste do comportamento afetado: título/descrição truncados e expansão, estado presenteado, botão desabilitado, escala de texto e hover. Evitar testes que apenas contam widgets internos.
3. Remover medições de texto repetidas em cada build ou armazenar resultados por texto, largura e escala; limitar animações e efeitos a cartões visíveis. Não criar cache sem chave completa nem esconder texto de tecnologias assistivas.
4. Confirmar que filtros, busca, paginação de 10 itens e carrinho não reconstruam cartões sem necessidade. Verificar que a lista continua lazy e que a seleção usa o produto correto após filtrar.

**Aceite:** comportamento visual/funcional preservado e menor tempo de build/pintura no trace; testes de regressão passam em 320, 390, 768, 1024 e 1440 px.

## Sprint 3 — Imagens e cache

1. Medir todos os WebP usados nos dez primeiros cartões: bytes, dimensões, tempo de resposta, cache hit e memória decodificada. Confirmar se `cacheWidth` reduz a resolução no renderer publicado.
2. Se as imagens dominarem o custo, escrever testes de API para um **thumbnail de catálogo** com lado máximo definido após a medição (ponto inicial: 480 px), formato WebP, proporção preservada e URL própria; o detalhe continua podendo usar o original.
3. Gerar thumbnail no upload e um processo idempotente para as imagens já salvas no volume `gift_images`. Atualizar o contrato do catálogo para entregar a URL do thumbnail, mantendo fallback para imagens antigas ou ausentes. Planejar a migração de metadados antes de publicar.
4. Adicionar cache HTTP apropriado às imagens de chave imutável e testar `Cache-Control`/revalidação via `/api/images/`. Não colocar cache longo no JSON do catálogo, pois preço, estoque e estado ativo mudam.

**Aceite:** os cartões não baixam o original quando existe thumbnail; visita repetida reutiliza a imagem; dimensões, qualidade visual e estado de produto esgotado permanecem corretos.

## Sprint 4 — Validação e publicação

1. Executar testes Flutter relevantes, testes da API de presentes/imagens, `flutter analyze --no-pub` e build web. Corrigir falhas introduzidas; registrar avisos preexistentes separadamente.
2. Repetir as medições da Sprint 0 nos mesmos aparelhos, renderer e condições. Meta: reduzir de forma consistente os long tasks e o tempo de script/pintura durante a rolagem; usar as medidas iniciais para definir o alvo numérico final. Não declarar ganho usando apenas build ou teste de widget.
3. Verificar primeira visita e visita com cache, busca, categoria, carregar mais, modal de presente, carrinho, presente esgotado e redirecionamento ao Asaas. Conferir `/presentes` publicado após o deploy e comparar o build servido com o validado.
4. Registrar no plano os números finais, capturas/trace, mudanças aplicadas e limitações restantes. Remover opções de diagnóstico que não devam ficar expostas.

**Aceite:** travamento reproduzido na Sprint 0 deixa de ocorrer no aparelho afetado; a melhora é repetível; catálogo e pagamento funcionam como antes.

### Evidências da Sprint 4 (Resultados Finais)

| Dispositivo / Ambiente | Métricas | Resultados Finais (`/presentes`) |
| :--- | :--- | :--- |
| **Desktop** | Tempo até conteúdo visível |  |
| | Frames > 16.7ms |  |
| | Long tasks (> 50ms) |  |
| | Memória / Repaints / Tamanho Imagens |  |
| **Mobile** | Tempo até conteúdo visível |  |
| | Frames > 33ms |  |
| | Long tasks (> 50ms) |  |
| | Memória / Repaints / Tamanho Imagens |  |

## Estado da execução local — 01/10/2026

- **Sprint 0: pendente.** A comparação exploratória do diagnóstico inicial não substitui trace com posição de rolagem igual, três repetições e teste em celular real. As tabelas acima permanecem vazias até essa medição.
- **Sprint 1: implementada localmente.** `/presentes` usa rolagem nativa por padrão; `?scroll=native` continua funcional na home. O teste de rota/rolagem voltou a passar, e a análise estática não aponta código inalcançável. A melhora perceptível ainda depende da Sprint 0 e da medição após a publicação.
- **Sprint 2: implementação parcial sem ganho medido.** O cartão preserva expansão, valor e estado esgotado nos testes; o cache de medição de texto agora considera texto, estilo, largura, linhas, `TextScaler`, direção e localidade. É necessário verificar o custo real de build/pintura no trace antes de declarar esta sprint concluída.
- **Sprint 3: implementada localmente, validação publicada pendente.** Upload e backfill geram WebP de catálogo com lado máximo de 480 px sem ampliar imagens menores. O backfill repara miniaturas inválidas, grava de forma atômica e a substituição remove original e miniatura antigos. Falta conferir bytes, cache hit e decodificação das imagens reais no renderer publicado.
- **Sprint 4: gates locais concluídos.** `flutter test --no-pub`: 100 testes passaram; `dotnet test --no-restore`: 109 testes passaram; `flutter analyze --no-pub`: nenhum aviso; `flutter build web --release --no-pub`: compilou. Ainda faltam teste no domínio após publicação, celular real e comparação de frames/long tasks antes e depois. O resultado local não comprova que o travamento acabou em produção.
