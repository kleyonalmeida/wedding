# Plano de migração do `front.html` para Flutter

## 1. Objetivo

Migrar a página de casamento existente em `front.html` para uma aplicação Flutter mobile first, preservando:

- a ordem das seções;
- a posição relativa dos elementos;
- os textos, cores, tipografia, imagens e proporções visuais;
- o comportamento de rolagem em página única;
- as interações já existentes: navegação, alteração do cabeçalho, contagem regressiva e formulário de confirmação.

A migração deve trocar a implementação HTML/Tailwind/JavaScript por widgets Flutter nativos. Não é recomendável incorporar o HTML em um `WebView`, pois isso manteria as limitações atuais e reduziria os benefícios de fluidez, acessibilidade e manutenção esperados com Flutter.

## 2. Diagnóstico do arquivo atual

O arquivo possui 307 linhas e concentra marcação, aparência e comportamento em um único documento. Embora seja descrito como HTML e CSS puro, ele também depende de:

- Tailwind CSS carregado por CDN;
- Google Fonts carregadas pela internet;
- JavaScript para o cabeçalho e o contador;
- imagens hospedadas externamente no Google;
- Google Maps incorporado por `iframe`.

### 2.1. Estrutura visual atual

A página deve continuar nesta ordem:

1. Cabeçalho fixo (`Header`)
   - monograma `K&L` à esquerda;
   - menu de navegação no desktop;
   - botão `PRESENÇA` à direita;
   - transparente e branco sobre o hero no topo;
   - fundo branco, texto escuro, sombra e menor altura após 100 px de rolagem.
2. Hero (`home`)
   - ocupa toda a altura da tela;
   - imagem de fundo com overlay escuro;
   - “Save the date”, nomes, data, divisor dourado e versículo centralizados.
3. Boas-vindas
   - fundo branco com textura suave;
   - texto institucional centralizado, em caixa alta e com espaçamento amplo.
4. Contagem regressiva
   - fundo taupe;
   - título cursivo;
   - quatro cartões para dias, horas, minutos e segundos.
5. O casal (`casal`)
   - título;
   - duas fotos circulares, nomes e coração entre elas;
   - chamada e texto da história.
6. Padrinhos (`padrinhos`)
   - fundo branco texturizado;
   - título e subtítulo;
   - grade de quatro fotos circulares.
7. Cerimônia (`recepcao`)
   - imagem do local;
   - cartões de data/horário e localização;
   - mapa incorporado.
8. Confirmação de presença (`rsvp`)
   - cartão elevado sobre fundo texturizado;
   - campos pessoais, presença, quantidades, observações e consentimentos;
   - botão de envio.
9. Rodapé
   - monograma e direitos autorais.

### 2.2. Identidade visual a preservar

| Elemento | Valor atual | Representação no Flutter |
|---|---:|---|
| Cor primária | `#B8A291` | `AppColors.primary` |
| Cor secundária | `#D4AF37` | `AppColors.secondary` |
| Texto escuro | `#333333` | `AppColors.dark` |
| Superfície | `#FBF9F8` | `AppColors.surface` |
| Títulos clássicos | Playfair Display | `AppTextStyles.serif` |
| Texto cursivo | Great Vibes | `AppTextStyles.cursive` |
| Texto geral | Work Sans | tema global |

As transparências usadas no HTML (`text-dark/70`, `primary/20`, por exemplo) devem ser reproduzidas com `withValues(alpha: ...)`, centralizadas no tema para evitar variações acidentais.

### 2.3. Pontos incompletos ou frágeis encontrados

Esses pontos devem ser decididos durante a migração, sem mudar silenciosamente o conteúdo:

- o menu contém `LISTA DE PRESENTES`, mas não existe uma seção com `id="lista"`;
- o item de menu diz “RECEPÇÃO”, porém aponta para uma seção intitulada “Cerimônia”;
- o formulário não possui `action`, validação ou persistência;
- os radios atuais não definem valores distintos;
- o contador pode exibir números negativos depois de 26/12/2026 às 16:00;
- o botão do formulário pode submeter/recarregar a página no navegador, mas não existe tratamento do envio;
- o menu fica oculto no mobile e não há menu alternativo;
- efeitos baseados em `hover` não têm equivalente direto em telas touch;
- fontes, textura e todas as fotos dependem da rede;
- o mapa em `iframe` não possui equivalente nativo direto em Flutter mobile.

## 3. Estratégia técnica

### 3.1. Escopo recomendado da primeira versão

Criar inicialmente um aplicativo Flutter com uma única tela rolável, fiel ao site, preparado para Android e iOS. A mesma composição também poderá funcionar no Flutter Web, mas o critério principal de layout e interação será mobile.

A raiz da tela deve usar `Scaffold` com um `Stack`:

- camada inferior: `CustomScrollView` ou `SingleChildScrollView` com todas as seções;
- camada superior: cabeçalho fixo controlado pela posição de rolagem;
- `SafeArea` aplicado ao cabeçalho para respeitar notch e barra de status.

`CustomScrollView` é preferível porque permite composição eficiente com slivers e futuras otimizações. Como a tela possui poucos elementos, ambas as opções são válidas; não se deve usar listas internas roláveis dentro da rolagem principal.

### 3.2. Organização sugerida do projeto

```text
lib/
  main.dart
  app.dart
  core/
    theme/
      app_colors.dart
      app_text_styles.dart
      app_theme.dart
    constants/
      wedding_constants.dart
  features/
    wedding/
      data/
        models/
          godparent.dart
          rsvp_data.dart
        repositories/
          rsvp_repository.dart
      presentation/
        pages/
          wedding_page.dart
        controllers/
          countdown_controller.dart
          rsvp_controller.dart
        widgets/
          wedding_header.dart
          hero_section.dart
          welcome_section.dart
          countdown_section.dart
          couple_section.dart
          godparents_section.dart
          ceremony_section.dart
          rsvp_section.dart
          wedding_footer.dart
          section_title.dart
          textured_background.dart
assets/
  images/
    hero.webp
    texture.webp
    couple/
    godparents/
    ceremony/
  fonts/
```

O projeto pode começar sem uma biblioteca de gerenciamento de estado. `StatefulWidget`, `ValueNotifier` e `Form` cobrem o comportamento atual com menor complexidade. Uma solução como Riverpod ou Bloc só deve ser introduzida quando houver estado compartilhado, integração remota mais complexa ou testes que justifiquem essa dependência.

### 3.3. Dependências previstas

Manter o conjunto pequeno e validar as versões estáveis no momento da implementação:

- `url_launcher`: abrir rota/local no aplicativo de mapas;
- `intl`: formatação de datas e horários, se necessário;
- `flutter_svg`: somente se a textura ou novos ornamentos forem armazenados em SVG;
- `google_maps_flutter`: opcional, caso seja obrigatório manter o mapa interativo dentro do app;
- `google_fonts`: opcional durante prototipação; para produção, é preferível empacotar as fontes em `assets/fonts`.

Não é necessária uma dependência específica para o contador, navegação por seções, formulários ou animações básicas.

## 4. Correspondência HTML para Flutter

| Implementação atual | Implementação Flutter |
|---|---|
| `body` vertical | `CustomScrollView`/`SliverList` |
| `header position: fixed` | widget sobreposto em `Stack` |
| âncoras `#home`, `#casal` etc. | `GlobalKey` + `Scrollable.ensureVisible` |
| `h-screen` | altura do `MediaQuery`/`SliverToBoxAdapter` |
| `flex`, `grid` | `Row`, `Column`, `Wrap` e `GridView` não rolável |
| breakpoints `md:` | `LayoutBuilder` com breakpoints centralizados |
| imagem de fundo | `DecoratedBox`/`Image` com `BoxFit.cover` |
| overlay gradiente | `DecoratedBox` com `LinearGradient` |
| círculos com `overflow-hidden` | `ClipOval` |
| sombras Tailwind | `BoxShadow` |
| `iframe` do mapa | mapa nativo ou cartão que abre Maps |
| campos HTML | `TextFormField`, radios, dropdowns e checkboxes |
| `setInterval` | `Timer.periodic` descartado em `dispose` |
| efeitos `hover` | animações de toque/foco; hover apenas em web/desktop |

## 5. Plano de implementação por fases

### Fase 0 — decisões antes de codificar

1. Confirmar Android/iOS como plataformas mínimas e se Flutter Web também faz parte da entrega.
2. Definir o destino real do RSVP: API própria, Firebase, Supabase, planilha/automação ou apenas simulação local.
3. Decidir entre mapa embutido e botão “Abrir no mapa”. Para mobile, o botão externo costuma ser mais leve e útil; mapa embutido exige chaves e configuração por plataforma.
4. Definir o conteúdo da Lista de Presentes ou remover temporariamente o item de navegação.
5. Confirmar se “Recepção” e “Cerimônia” são a mesma seção.
6. Obter os arquivos originais/licenciados das imagens. Não depender permanentemente das URLs atuais.

**Critério de conclusão:** decisões registradas e todos os assets necessários disponíveis.

### Fase 1 — criação da base Flutter

1. Criar o projeto com identificadores de pacote definitivos.
2. Habilitar apenas as plataformas acordadas.
3. Configurar lint e formatação.
4. Registrar imagens e fontes no `pubspec.yaml`.
5. Criar tema com cores, estilos de texto, formatos de botão, inputs e cartões.
6. Definir constantes de largura máxima, espaçamentos e breakpoints.

Sugestão de breakpoints, mantendo a intenção dos `md:` atuais:

- compacto: `< 600 px`;
- intermediário: `600–899 px`;
- amplo: `>= 900 px`.

No mobile, partir de padding horizontal de 20–24 px e áreas tocáveis mínimas de 48 px.

**Critério de conclusão:** app abre em Android/iOS, carrega as três famílias tipográficas e exibe uma tela-base com as cores corretas.

### Fase 2 — shell, rolagem e cabeçalho

1. Criar `WeddingPage` e seu `ScrollController`.
2. Adicionar uma `GlobalKey` para cada seção navegável.
3. Montar todas as seções na ordem original.
4. Sobrepor `WeddingHeader` à rolagem.
5. Alterar progressivamente cor, altura, sombra e fundo do cabeçalho de acordo com o offset.
6. Implementar rolagem animada para as seções com `Scrollable.ensureVisible`.
7. Em telas compactas, manter monograma e botão `PRESENÇA`; se todos os itens precisarem estar acessíveis, adicionar menu lateral ou modal sem deslocar os elementos principais.
8. Compensar a altura do cabeçalho ao navegar, evitando que o título da seção fique encoberto.

**Critério de conclusão:** navegação funciona, cabeçalho não salta visualmente e nenhuma seção fica escondida sob ele.

### Fase 3 — reprodução das seções estáticas

#### Hero

- usar altura igual à viewport, incluindo tratamento correto de `SafeArea`;
- `Image.asset(..., fit: BoxFit.cover)` ocupando todo o fundo;
- overlay vertical equivalente a preto com opacidade aproximada de 30% a 50%;
- conteúdo centralizado e limitado em largura;
- substituir o `hover:scale` por uma animação de entrada lenta e discreta, se desejado, sem alterar a composição.

#### Boas-vindas

- criar `TexturedBackground` reutilizável;
- aplicar a textura com baixa opacidade sem tornar todo o conteúdo transparente;
- preservar caixa alta, altura de linha e espaçamento de letras.

#### O casal

- mobile: fotos e coração em `Column`, como ocorre hoje;
- telas maiores: `Row` centralizada;
- recortar fotos com `ClipOval`, borda branca e sombra;
- remover o grayscale dependente de hover no mobile ou definir uma animação acionada por toque somente se ela tiver valor real.

#### Padrinhos

- representar cada pessoa com um modelo `Godparent` (`name`, `role`, `imagePath`);
- construir a grade a partir de dados, evitando quatro blocos duplicados;
- duas colunas no mobile e quatro nas telas amplas;
- usar `childAspectRatio`/dimensões responsivas para impedir overflow em aparelhos estreitos.

#### Cerimônia

- mobile: imagem acima dos cartões;
- telas amplas: imagem e informações lado a lado;
- conservar cantos arredondados, sombras e hierarquia dos textos;
- reservar proporção fixa para a imagem para evitar mudança de layout durante o carregamento.

#### Rodapé

- manter altura, fundo, monograma e legenda centralizados.

**Critério de conclusão:** comparação visual lado a lado confirma ordem, alinhamento, cores e hierarquia equivalentes ao HTML.

### Fase 4 — contagem regressiva

1. Criar `CountdownController` ou widget stateful isolado.
2. Armazenar a data como `DateTime(2026, 12, 26, 16)` no fuso esperado.
3. Atualizar uma vez por segundo com `Timer.periodic`.
4. Calcular dias, horas, minutos e segundos a partir de uma única diferença de tempo.
5. Formatar cada valor com dois dígitos, mantendo dias com mais de dois dígitos quando necessário.
6. Cancelar o timer no `dispose`.
7. Pausar/recalcular corretamente após o app voltar do background.
8. Ao chegar a zero, cancelar o timer e exibir `00` em todos os cartões ou uma mensagem definida pelo casal; nunca mostrar negativos.

Para evitar ambiguidade de fuso, documentar que o evento ocorre em `America/Sao_Paulo`. Como `DateTime` não carrega um identificador IANA por si só, avaliar uma biblioteca de timezone caso o app seja usado por convidados em outros fusos e a precisão absoluta seja necessária.

**Critério de conclusão:** testes cobrem mais de 24 horas restantes, menos de 24 horas, virada de minuto, zero e data passada.

### Fase 5 — formulário RSVP

1. Criar `Form` com `GlobalKey<FormState>`.
2. Manter controladores somente para campos que precisem ser lidos e descartá-los corretamente.
3. Modelar os dados em `RsvpData`:
   - nome completo;
   - comparecimento (`sim`/`não`);
   - adultos;
   - crianças;
   - e-mail;
   - telefone;
   - mensagem;
   - aceite dos termos;
   - aceite de atualizações.
4. Reproduzir os campos na mesma ordem do HTML.
5. No mobile, permitir que os seletores de adultos e crianças se reorganizem verticalmente em larguras muito pequenas.
6. Configurar tipos de teclado, `textInputAction`, autofill e navegação entre campos.
7. Validar nome, presença, e-mail, telefone e aceite obrigatório dos termos.
8. Se a pessoa não comparecer, definir a regra para zerar/desabilitar quantidades.
9. Aplicar máscara de telefone sem impedir números internacionais, caso haja convidados fora do Brasil.
10. Criar `RsvpRepository` para separar interface e mecanismo de envio.
11. Durante o envio, desabilitar o botão e mostrar progresso.
12. Tratar sucesso, erro, timeout e tentativa duplicada com mensagens acessíveis.
13. Não armazenar dados pessoais em logs.

Se o backend ainda não estiver definido, implementar primeiro um repositório fake claramente marcado. A tela não deve apresentar sucesso definitivo se os dados não foram persistidos.

**Critério de conclusão:** validações funcionam, envio não duplica, estados de carregamento/erro/sucesso são visíveis e o teclado não encobre o campo ativo.

### Fase 6 — mapa e integrações externas

Opção recomendada para a primeira versão mobile:

1. substituir o `iframe` por um preview estático/cartão com endereço;
2. adicionar ação para abrir coordenadas/endereço pelo `url_launcher`;
3. oferecer fallback copiável se nenhum aplicativo de mapas estiver disponível.

Se o requisito for mapa embutido:

1. usar `google_maps_flutter`;
2. criar e restringir chaves por plataforma e assinatura;
3. configurar Android Manifest e iOS Runner;
4. adicionar marcador, câmera inicial e controles mínimos;
5. validar termos, cobrança e política de privacidade.

**Critério de conclusão:** endereço abre corretamente em dispositivo físico Android e iOS e existe fallback em caso de falha.

### Fase 7 — assets e desempenho

1. Baixar imagens autorizadas para `assets/images`.
2. Converter fotos grandes para WebP/AVIF quando suportado pelo pipeline, mantendo resolução adequada à maior densidade de tela esperada.
3. Gerar variantes ou usar `cacheWidth` para evitar decodificar imagens muito maiores que sua exibição.
4. Empacotar fontes para evitar variação visual e dependência de rede.
5. Pré-carregar somente a imagem crítica do hero.
6. Evitar `IntrinsicHeight`, blur excessivo e sombras muito amplas em listas.
7. Usar `const` sempre que possível e isolar o rebuild de um segundo do contador à própria seção.
8. Medir em modo profile, não apenas debug.

**Critério de conclusão:** rolagem permanece fluida em aparelho intermediário, sem picos perceptíveis causados por imagens ou rebuilds globais.

### Fase 8 — responsividade e acessibilidade

Validar pelo menos larguras de 320, 360, 390, 412, 600, 768 e 1024 px, além de orientação horizontal.

Checklist:

- nenhum overflow amarelo/preto;
- textos continuam legíveis com escala de fonte em 1,3 e 2,0;
- contraste suficiente, especialmente textos com opacidade baixa;
- alvos de toque com pelo menos 48 × 48 px;
- `Semantics` para imagens, contador, controles e ações;
- ordem de foco equivalente à ordem visual;
- campos têm rótulos persistentes, não somente placeholders;
- suporte a teclado e leitor de tela;
- conteúdo não fica atrás de notch, barra do sistema ou teclado;
- animações respeitam redução de movimento quando aplicável.

**Critério de conclusão:** testes manuais com TalkBack/VoiceOver e escalas de fonte não revelam bloqueios de uso.

### Fase 9 — testes e homologação

#### Testes unitários

- cálculo e formatação do contador;
- comportamento após a data do evento;
- validações e serialização de `RsvpData`;
- sucesso e falha do repositório de RSVP.

#### Testes de widget

- ordem e presença das seções;
- estados do cabeçalho antes/depois da rolagem;
- navegação por cada item do menu;
- layouts compacto e amplo;
- validações e loading do RSVP.

#### Golden tests

- hero;
- contador;
- casal;
- padrinhos;
- cerimônia;
- RSVP;
- tela completa em uma ou duas larguras de referência.

#### Testes de integração

- abrir app, rolar e navegar entre seções;
- preencher e enviar confirmação;
- simular erro de rede e repetir;
- abrir o mapa;
- suspender e retomar o app verificando o contador.

#### Homologação visual

Capturar o HTML e o Flutter nas mesmas larguras e comparar:

- posição e ordem;
- largura máxima do conteúdo;
- espaçamentos verticais;
- tamanhos e pesos tipográficos;
- recortes das imagens;
- cores, opacidades, raios e sombras.

Não buscar igualdade rígida de pixels entre motores de renderização diferentes; o objetivo é equivalência perceptiva e preservação da estrutura.

## 6. Estratégia de entrega

Uma sequência segura de entregas é:

1. fundação, tema e assets;
2. página estática fiel ao HTML;
3. cabeçalho e navegação;
4. contador;
5. formulário com repositório fake;
6. backend real e mapa;
7. acessibilidade, otimização e testes finais;
8. builds assinados e distribuição interna para homologação.

Cada etapa deve gerar uma versão executável. Isso permite validar aparência e conteúdo antes de acoplar persistência e serviços externos.

## 7. Critérios gerais de aceite

A migração estará concluída quando:

- todas as seções acordadas estiverem presentes e na ordem original;
- a composição mobile reproduzir o HTML sem overflow;
- tablet/desktop adotarem as disposições em linha e grade atuais;
- cabeçalho e navegação por seções funcionarem;
- contador estiver correto, inclusive após background e data encerrada;
- RSVP validar e persistir dados com feedback de estado;
- localização puder ser aberta com fallback;
- fontes e imagens críticas não dependerem das URLs provisórias;
- testes automatizados essenciais estiverem aprovados;
- desempenho e acessibilidade forem validados em dispositivos reais;
- Android e iOS tiverem builds reproduzíveis e configurações de produção documentadas.

## 8. Riscos e decisões que não devem ser adiadas

| Risco | Impacto | Mitigação |
|---|---|---|
| URLs externas deixarem de funcionar | imagens desaparecem | armazenar assets autorizados no app/CDN controlada |
| Backend do RSVP indefinido | confirmação falsa ou perda de dados | definir contrato e persistência antes da publicação |
| Dados pessoais sem política adequada | risco de privacidade/LGPD | coletar o mínimo, proteger transporte/armazenamento e informar finalidade |
| Mapa nativo sem chaves restritas | custo e abuso da API | restringir chaves por pacote, assinatura e plataforma |
| Fontes remotas | primeira abertura inconsistente | empacotar fontes no aplicativo |
| Layout copiado com medidas fixas | overflow em aparelhos pequenos | usar constraints e breakpoints, preservando proporções |
| Timer reconstruindo a página toda | perda de fluidez | isolar atualização no widget do contador |
| Conteúdo divergente no menu | navegação quebrada | resolver Lista de Presentes e Recepção/Cerimônia antes da homologação |

## 9. Resultado arquitetural esperado

Ao final, a aparência continua sendo a mesma página de casamento, mas cada responsabilidade fica isolada:

- widgets cuidam da apresentação de cada seção;
- tema centraliza a identidade visual;
- modelos representam padrinhos e RSVP;
- controller local cuida do contador e estado do formulário;
- repository abstrai o envio dos dados;
- assets locais garantem consistência visual;
- testes protegem o comportamento e a responsividade.

Essa estrutura preserva fielmente o que já foi construído e cria uma base adequada para evoluções futuras, como lista de presentes, notificações, galeria, autenticação de convidados ou painel administrativo, sem misturar essas expansões com a primeira migração.
