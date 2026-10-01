# Plano por sprints — RSVP por QR code genérico

## Decisão atual sobre o cadastro

- O Admin cadastra **uma linha por identificação escrita no convite**. Exemplo: `Jorge e Amanda` é **um único registro**, não dois convidados vinculados nem um adulto com acompanhante.
- Em cada linha, o Admin informa a identificação exata, a **quantidade de adultos que ela representa** e se está ativa. Para `Jorge e Amanda`, cadastrar `QuantidadeAdultos = 2`. **Não inferir a quantidade pela palavra “e”**: ela é um dado explícito do Admin.
- **Não cadastrar nomes de crianças.** No formulário, perguntar se a linha confirmada levará crianças e, em caso positivo, pedir somente a quantidade. O limite planejado é **0 a 10 crianças por resposta**; não existe cota individual de crianças cadastrada no Admin.
- A confirmação ou recusa vale para **a linha inteira**. `Jorge e Amanda` confirmada contabiliza os dois adultos; `Jorge e Amanda` recusada contabiliza zero presentes. O sistema não distingue qual dos dois compareceu. Caso seja necessário confirmar apenas Jorge ou apenas Amanda, eles precisam estar em linhas separadas antes da resposta ou a exceção precisa ser resolvida pelo Admin.
- Cada linha pode ter **uma resposta ativa**. O QR code é igual para todos e não identifica a linha; quem preenche digita a identificação inteira exatamente como está no convite.
- Não criar tabela de pessoas individuais, grupos internos ou vínculos entre linhas para esse fluxo. A própria linha representa o conjunto que será acompanhado no Admin.

## Objetivo e navegação

- Todos os convites usam o mesmo QR code, apontando para `https://kleyoneliandra.com.br/confirmar-presenca`, sem parâmetros de convidado.
- Essa rota mostra uma **página de aviso** inspirada no cartão da tela de carregamento. Ela permanece até o clique em **“ENTENDI, CONFIRMAR PRESENÇA”**, que leva a `/confirmar-presenca/formulario`. Não há tempo de redirecionamento.
- O formulário fica em **página própria** e sai completamente da home. Os botões de presença da home levam ao aviso. O carregamento global de `web/index.html` continua automático e é independente da página de aviso.
- As duas URLs acima são **rotas públicas do Flutter**. `POST /api/rsvp` continua sendo o endpoint de envio; não criar endpoint ou QR individual por convite.
- Texto base do aviso: **“Digite a identificação exatamente como está escrita no convite, inclusive quando houver dois nomes na mesma linha. A resposta valerá para todos os adultos dessa linha. Se forem levar crianças, informe a quantidade. Somente identificações cadastradas podem confirmar presença.”**

## Referência visual da página própria

- Usar o HTML enviado como **referência de layout** para a página Flutter: introdução editorial, cartões de data/local, cartão de resposta com faixa superior, etapas visuais, assistência, frase final e `WeddingFooter` atual. Não copiar Tailwind CDN, `onsubmit`, links `#`, dados falsos nem sucesso simulado.
- Remover FAQ, restrições alimentares, mensagem aos noivos e o rodapé proposto no HTML. O formulário terá apenas identificação do convite, contatos, presença, crianças condicionais e envio, além de campos obrigatórios já existentes que continuem pertinentes, como aceite de termos.
- Mostrar **Casa da Mangueira Eventos, Feira de Santana/BA**, em **26/12/2026 às 15h30**. Corrigir `WeddingConstants`, que ainda registra 16h00. Não usar local, horário, dress code ou protocolo inventados.
- Manter o bloco de assistência. O número de WhatsApp será informado depois: até lá, mostrar orientação de contato **sem botão/link falso**. Quando o número existir, habilitar **“Falar no WhatsApp”** via `url_launcher` e tratar falha ao abrir. Não prometer envio de QR ou protocolo por WhatsApp/e-mail sem essa funcionalidade.

## Estado atual confirmado no repositório

- O formulário atual está em `lib/features/wedding/presentation/widgets/rsvp_section.dart` e é montado em `WeddingPage`; os links da home rolam até ele. `lib/app_router.dart` não possui as rotas novas.
- O Admin em `/admin/presenca` gerencia **respostas já enviadas**, mas não cadastra previamente identificações de convites. `POST /api/rsvp` aceita qualquer nome sintaticamente válido, impede e-mail duplicado e recebe contagens de adultos/crianças do cliente. Ainda não verifica uma lista cadastrada.
- O formulário atual oferece adultos 1–4, crianças 0–3 e campo de observações. A API exige e-mail/telefone, mas a interface não deixa essa obrigatoriedade clara. O Nginx já tem fallback de SPA; o acesso direto às novas URLs deve ser testado no domínio publicado.

## Regras de validação e mensagens

1. O Admin cadastra `IdentificacaoNoConvite`, `IdentificacaoNormalizada`, `QuantidadeAdultos >= 1`, `Ativo` e datas. A identificação deve corresponder à linha impressa, inclusive `e`, acentos e grafia. A comparação remove somente espaços nas pontas, normaliza Unicode NFC e **ignora diferença entre maiúsculas e minúsculas**: `Jorge e Amanda` aceita `jorge e amanda`. Não aproxima nomes nem troca acentos ou espaços internos. Impedir linhas duplicadas após essa normalização. Homônimos indistinguíveis exigem outra forma de identificação antes de distribuírem o QR.
2. No envio, consultar o cadastro **somente após clicar em “CONFIRMAR PRESENÇA”**. Não consultar a cada tecla nem criar API pública de busca. A API identifica a linha digitada, verifica se está ativa e se já respondeu, e usa `QuantidadeAdultos` do Admin. O cliente **não fornece nem altera a quantidade de adultos**.
3. Se a resposta for **Sim**, `QtdAdultos` gravada = `QuantidadeAdultos` da linha. Perguntar **“Levarão crianças?”**; se Não, `QtdCriancas = 0`; se Sim, mostrar seletor **1 a 10** e gravar o número escolhido. Não pedir nomes de crianças. Validar 0–10 também na API, inclusive em chamada direta.
4. Se a resposta for **Não**, esconder a pergunta sobre crianças e gravar `QtdAdultos = 0`, `QtdCriancas = 0`. Uma resposta representa a linha inteira. Ao alternar Sim/Não, dados ocultos não entram no envio.
5. Nova tentativa para uma linha já respondida mostra aviso específico e não cria outra resposta. Correções ficam no Admin, com histórico preservado. Rever a unicidade atual por e-mail para que ela não impeça linhas diferentes que compartilhem contato; a chave de duplicidade é a linha cadastrada.
6. Identificação inexistente ou inativa não grava RSVP. A API retorna código de negócio estável, por exemplo `INVITATION_NOT_FOUND`, sem listar identificações cadastradas. O frontend abre modal com o texto digitado: **“Verificamos que {identificacaoDigitada} não consta em nossa lista de convidados para o casamento. Confira no convite a forma exata como os nomes estão escritos. Se a identificação foi digitada corretamente e este aviso continua aparecendo, lamentamos o transtorno, mas ela não consta em nossa lista. Pedimos que não insista em novas tentativas. Se desejar esclarecimentos, entre em contato com o noivo ou com a noiva.”** O botão para voltar preserva os campos e foca a identificação.
7. Sucesso com presença: **“Agradecemos por confirmar a presença de {identificacaoDigitada}. Será uma alegria celebrar com vocês!”** Ajustar concordância para uma linha de um adulto sem tentar separar nomes compostos por texto. Sucesso com recusa: **“Sabemos que a data é um pouco complicada devido às festividades, mas agradecemos o tempo que dedicou para nos responder aqui. Sinta-se à vontade para apreciar o site, ver as fotos e, se quiser, visitar nossa área de presentes.”**
8. Renderizar identificações como texto em widgets Flutter, nunca como HTML; limitar comprimento e caracteres de controle. Tornar modal e mensagens acessíveis por teclado e leitor de tela. A página de aviso é orientação visual; a API continua validando mesmo quando alguém acessa o formulário diretamente.

## Regra de TDD para todas as sprints

Em cada sprint: **(1) escrever testes do comportamento esperado, (2) executá-los e observar a falha correta, (3) implementar o mínimo necessário, (4) executar os testes novamente, (5) refatorar mantendo os testes verdes**. Testar comportamento observável, não apenas presença de strings no código. Não iniciar a sprint seguinte com testes da anterior falhando.

## Sprint 1 — Cadastro das linhas e validação na API

**Testes primeiro (.NET):**

- Admin autorizado cadastra `Jorge e Amanda` como **uma linha** com 2 adultos; cadastro com zero adultos, identificação duplicada ou identificações inválidas falha. Testar edição, desativação e tentativa de alterar linha que já tem resposta, preservando a integridade e o histórico.
- `POST /api/rsvp` aceita a identificação exata `Jorge e Amanda` com presença e **0, 1 e 10 crianças**; grava 2 adultos em todos os casos e a quantidade de crianças escolhida. Não aceita 11 crianças, mesmo por chamada direta. Outra linha com 1 adulto grava 1 adulto sem depender de análise do texto.
- Recusa de `Jorge e Amanda` grava zero adultos e zero crianças. Identificação desconhecida, inativa ou já respondida não grava nova resposta; erros usam códigos distintos. Submissões concorrentes para a mesma linha resultam em apenas uma resposta ativa.
- E-mail/telefone compartilhado entre linhas diferentes não bloqueia a segunda linha. Nomes reais com acentos e, se constarem nos convites, hífen/apóstrofo são aceitos tanto no Admin como no formulário/API. Verificar que a API não expõe a lista de linhas cadastradas.
- Totais do Admin exibem **linhas pendentes, confirmadas e recusadas**, adultos confirmados pela quantidade cadastrada e crianças confirmadas pela quantidade declarada. Alterar uma resposta administrativamente atualiza esses totais sem perder o vínculo da linha.

**Implementação após testes vermelhos:**

1. Criar tabela de linhas de convite com identificador exato/normalizado, quantidade de adultos, estado ativo e datas; índice único adequado. Não criar registros individuais para Jorge e Amanda. Criar migration sem povoar produção com dados fictícios.
2. Criar tela e endpoints autenticados no Admin para cadastrar, listar, editar e desativar linhas. Mostrar identificação, quantidade de adultos e estado da resposta. Impedir edição destrutiva de linhas já respondidas sem fluxo de correção explícito.
3. Atualizar o DTO público de `POST /api/rsvp`: identificação digitada, presença, quantidade de crianças quando cabível e contatos/aceite necessários; **remover contagem de adultos e observações do novo payload**. A API consulta uma linha, deriva adultos, valida crianças, vincula a resposta à linha e impede duplicidade por transação/restrição única.
4. Adaptar as telas e totais existentes do Admin ao vínculo por linha. Como não há RSVPs antigos no banco, remover os campos legados da migração e do modelo. Rever a regra atual de e-mail duplicado.
5. Alinhar validação de comprimento/caracteres no Admin, frontend e `RsvpRequestValidator`; manter consultas parametrizadas e limitação de taxa do endpoint.

**Aceite:** uma linha composta como `Jorge e Amanda` é cadastrada e respondida como unidade; 2 adultos vêm do Admin, crianças vêm do seletor, nomes não cadastrados e respostas duplicadas não são gravados.

## Sprint 2 — Rotas públicas e página de aviso

**Testes primeiro (Flutter):**

- Abrir `/confirmar-presenca` diretamente mostra o aviso, sem formulário e sem redirecionamento automático após passagem de tempo.
- Somente o botão de avanço leva a `/confirmar-presenca/formulario`; testar toque, teclado, leitor de tela, refresh, Voltar e acesso direto pelo QR.
- Links de presença da home levam ao aviso; o formulário deixa de aparecer na página inicial. O aviso explica que **uma linha composta confirma todos os adultos nela escritos**.

**Implementação após testes vermelhos:**

1. Adicionar as duas rotas em `lib/app_router.dart`, com constantes únicas. Criar aviso Flutter inspirado nas cores, monograma `K&L` e ornamentos da tela de carregamento atual, sem barra de progresso nem temporizador nessa página.
2. Criar botão de avanço explícito. Mudar cabeçalho/menu/home para apontarem ao aviso. Retirar `RsvpSection` da home e remover âncoras/rolagem que só serviam ao formulário embutido.

**Aceite:** o QR genérico abre o aviso, o clique abre o formulário dedicado e a home não mantém outro formulário.

## Sprint 3 — Formulário dedicado e integração

**Testes primeiro (Flutter + API falsa):**

- Página própria mostra **“Identificação como está no convite”** com exemplo `Jorge e Amanda`, contatos exigidos, presença Sim/Não e prazo. Não mostra “Terá acompanhante?”, seletor de adultos, campos de nomes adicionais, nomes de crianças, observações, FAQ ou restrições alimentares.
- Presença Sim mostra **“Levarão crianças?”**; Não envia zero, Sim exige quantidade de 1–10. Recusa esconde a pergunta e envia zero crianças. Alternância entre estados não envia dados ocultos.
- A API é chamada **uma vez no clique de confirmar**, nunca durante digitação/abertura da tela. O payload não inclui quantidade de adultos nem tenta dividir `Jorge e Amanda` em pessoas separadas.
- `INVITATION_NOT_FOUND` abre o modal com o texto digitado; fechá-lo preserva os dados e foca o campo. Linha já respondida recebe aviso específico. Sucesso mostra a mensagem correspondente à presença ou recusa. Erro de rede não apaga dados e permite nova tentativa; botão fica desabilitado durante envio.
- Cartões mostram **15h30** e **Casa da Mangueira Eventos**; usar a frase final e o rodapé existente. Assistência não abre link falso enquanto o número do WhatsApp não existir. Acesso direto ao formulário passa primeiro pelo aviso nesta sessão; isso é apenas UX, não autorização da API.

**Implementação após testes vermelhos:**

1. Reutilizar/refatorar `RsvpSection` numa página própria. Criar campo único de identificação, manter apenas contatos/termos necessários e presença; remover lógica de adultos acompanhantes, nomes individuais e observações.
2. Implementar pergunta e seletor de crianças condicionais; validar localmente 0–10, e-mail, telefone e identificação. Atualizar `RsvpData`/`RsvpRepository` junto com testes e mapear erros de negócio sem perder campos.
3. Criar modal e mensagens de sucesso com texto seguro e acessível. Evitar resposta assíncrona atualizar widget descartado; impedir reenvio após sucesso.
4. Aplicar visual da referência ao Flutter, corrigir horário em `WeddingConstants` e ligar a passagem aviso → formulário apenas ao botão.

**Aceite:** `Jorge e Amanda` confirma ou recusa como uma única linha; o formulário pergunta somente se levarão crianças e quantas; a home não contém o formulário.

## Sprint 4 — QR code, publicação e validação final

**Testes primeiro:**

- Criar teste que decodifica o QR e exige **exatamente** `https://kleyoneliandra.com.br/confirmar-presenca`, sem parâmetros; executá-lo antes de gerar o arquivo para confirmar a falha esperada.
- Preparar roteiro de navegador para acesso direto, refresh, tela de carregamento, aviso estático e formulário em celular e desktop. Incluir linha com 1 adulto, `Jorge e Amanda` com 2 adultos, crianças 0/1/10/11, recusa, identificação desconhecida, duplicidade, falha de rede, mensagem de sucesso e totais do Admin.

**Entrega após testes vermelhos:**

1. Gerar **um QR estático** com margem adequada à impressão e executar o teste de decodificação até passar.
2. Rodar `flutter test`, `flutter analyze`, `flutter build web --release` e testes .NET de RSVP/Admin; registrar falhas relacionadas à mudança e distinguir avisos anteriores.
3. Confirmar HTTPS, fallback de SPA e `POST /api/rsvp` no domínio publicado. Executar roteiro no navegador e escanear o QR em pelo menos um Android e um iPhone.
4. Cadastrar as **linhas reais dos convites** no Admin, revisar identificação exata e quantidade de adultos contra a impressão e só então distribuir o QR. Quando o número de assistência for informado, configurar e testar o botão de WhatsApp antes de publicá-lo.

**Aceite:** o QR abre o aviso; apenas o clique avança; a API aceita somente uma linha cadastrada e ativa, contabiliza os adultos definidos no Admin e as crianças declaradas no formulário. O Admin mostra quais linhas confirmaram, recusaram ou ainda estão pendentes.
