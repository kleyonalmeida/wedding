# Plano por sprints — tela de carregamento do casamento

## Objetivo

Mostrar imediatamente uma tela de boas-vindas no primeiro acesso ao site e removê-la automaticamente quando a página Flutter da rota solicitada estiver visível. A referência visual é o HTML fornecido, adaptado à identidade e ao conteúdo reais do projeto. Este documento é apenas o planejamento; não altera a aplicação.

## Sprint 1 — Estrutura e identidade visual

- Criar a tela inicial diretamente em `web/index.html`, com HTML e CSS essenciais no próprio arquivo para que apareça antes do carregamento do Flutter, sem Tailwind, ícones externos ou JavaScript de animação pesado.
- Reproduzir a composição principal da referência: fundo claro, ondas discretas, cartão central, nomes do casal, mensagens curtas e ornamentos leves; ajustar para telas pequenas e grandes.
- Usar no monograma o mesmo **“K&L”** do site, com Playfair Display, peso 600 e espaçamento visual equivalente ao cabeçalho em `lib/features/wedding/presentation/widgets/wedding_header.dart`. Prever fonte de sistema enquanto a fonte web carrega.
- Trocar “Salão Nobre” por **“Casa da Mangueira Eventos”**, nome já usado na seção de cerimônia. Manter a data **26.12.2026**. Revisar e eliminar textos fictícios da referência que não correspondam ao casamento.
- Remover o botão **“Adentrar Celebração”**, o controle **“Prelúdio Suave”** e a marca **“K • L — RSVP & Experiência Digital”**. Exibir **“Kleyon Almeida Dev”** no rodapé discreto da tela.

**Aceite:** a tela aparece antes da aplicação Flutter, sem depender de recursos externos para sua estrutura; textos, monograma e rodapé correspondem ao site e às alterações solicitadas.

## Sprint 2 — Carregamento e transição automática

- Substituir a barra horizontal por um **indicador circular** integrado ao visual do cartão. Usar animação indeterminada, sem porcentagem inventada: o site não expõe progresso real de download/renderização.
- Manter mensagens de preparação breves e acessíveis, respeitando a preferência do sistema por movimento reduzido.
- Integrar a remoção da tela ao evento de **primeiro quadro renderizado pelo Flutter**, com transição curta de opacidade. Não usar temporizador de progresso ou clique para liberar o site; parar animações e temporizadores da tela após removê-la.
- Garantir que uma rota aberta diretamente, como `/presentes`, `/pagamento/retorno` ou `/admin`, também seja exibida automaticamente quando estiver pronta, sem redirecionamento para a página inicial.
- Prever tratamento de falha de inicialização para evitar uma tela de carregamento infinita e oferecer recarga quando a aplicação realmente não conseguir iniciar.

**Aceite:** o conteúdo aparece por conta própria assim que o Flutter renderiza; nenhum atraso artificial é adicionado; nenhuma interação do visitante é necessária.

## Sprint 3 — Validação e ajustes finais

- Verificar visualmente o primeiro acesso em desktop e celular, inclusive em rede lenta, observando se há tela em branco antes da tela inicial ou sobreposição depois que o site aparece.
- Conferir o monograma lado a lado com o cabeçalho real, a leitura dos textos, o indicador circular e a ausência dos controles removidos.
- Testar acesso direto e atualização das rotas principais, além de falha de carregamento, navegação por teclado e preferência por movimento reduzido.
- Executar a análise/build web pertinentes e corrigir eventuais problemas introduzidos pela integração.

**Aceite:** a transição é automática e consistente nas rotas verificadas; a tela não atrapalha o uso nem permanece visível após o carregamento.
