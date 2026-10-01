# Ativação do Asaas em produção

O backend usa `ASAAS_ENVIRONMENT` para escolher a API do Asaas. A publicação com pagamentos reais exige uma chave de API **de produção**, um webhook **de produção** e uma URL HTTPS pública. A conta, as chaves, os webhooks e os dados do Sandbox não migram automaticamente para produção.

## Antes de mudar o ambiente

1. Na conta Asaas de produção, conclua as validações da conta e confirme que a chave Pix está ativa. A chave Pix recebe o dinheiro; ela **não** substitui `ASAAS_API_KEY`.
2. Crie uma chave de API de produção no painel Asaas. Guarde-a no secret manager ou no `.env` **do servidor publicado**, nunca no código nem no frontend. A proteção de inicialização deste projeto exige o prefixo atual `$aact_prod_`.
3. Crie no Asaas de produção um webhook com URL `https://kleyoneliandra.com.br/api/webhooks/asaas`, versão 3, **envio Sequencial**, ativo, fila não interrompida e token próprio de 32 a 255 caracteres. Selecione `CHECKOUT_PAID`, `CHECKOUT_CANCELED`, `CHECKOUT_EXPIRED` e os eventos de pagamento usados na conciliação. O token configurado no painel deve ser exatamente o valor de `ASAAS_WEBHOOK_AUTH_TOKEN` no servidor.
4. Separe os dados financeiros de teste dos dados reais. Se a base atualmente publicada contém pedidos do Sandbox, não a utilize como histórico financeiro de produção sem uma migração deliberada: o painel soma pedidos de ambos os ambientes. Faça backup e defina como os presentes/estoque serão preparados na base real.
5. No `.env` do servidor, configure os valores abaixo, preservando a chave inteira entre aspas simples para que o `$` inicial não seja interpretado pelo Docker Compose:

   ```dotenv
   ASAAS_ENVIRONMENT=Production
   ASAAS_API_KEY='$aact_prod_...'
   ASAAS_WEBHOOK_AUTH_TOKEN='token-independente-cadastrado-no-webhook'
   PUBLIC_BASE_URL=https://kleyoneliandra.com.br
   ALLOWED_ORIGIN=https://kleyoneliandra.com.br
   ```

   Estes são **exemplos**, não credenciais. A aplicação agora rejeita ambiente inválido, chave sem o prefixo de produção atual, token de webhook inadequado e URLs locais/sem HTTPS em produção.

## Publicação e verificação

1. Recrie a API com o ambiente atualizado (`docker compose up -d --build --force-recreate api`). A variável `ASPNETCORE_ENVIRONMENT=Production` do Compose controla o .NET; quem muda o Asaas é `ASAAS_ENVIRONMENT=Production`.
2. Confirme que a API inicia saudável e que o webhook de produção alcança o endpoint público. Não registre nem publique os valores das credenciais ao conferir a configuração.
3. Crie pelo admin um presente temporário chamado, por exemplo, **Teste interno — não comprar**, por **R$ 5,00** e estoque **1**. O Asaas informa R$ 5,00 como mínimo por cobrança; R$ 1,00 pode ser recusado. Enquanto ativo, o item fica visível na lista pública: crie-o imediatamente antes do teste e desative-o depois.
4. Faça um pedido próprio desse item e pague via Pix; confira o retorno do Asaas, a entrega e o processamento do webhook, o status do pedido e os valores no financeiro. Um redirecionamento de sucesso sozinho não confirma pagamento.
5. Teste cartão e possíveis estornos/cancelamentos separadamente antes de abrir o fluxo aos convidados. Para testar parcelamento, use outro valor que comporte as parcelas mínimas e habilite a opção antes.

## Pix e parcelamento neste projeto

O site envia `billingTypes: [PIX, CREDIT_CARD]` e redireciona para o Checkout hospedado pelo Asaas. O Pix exibido nessa página é gerado para a cobrança; não é necessário colocar a chave Pix estática no site. A aparência exata de QR Code e Copia e Cola deve ser confirmada no checkout da conta de produção.

O checkout atual envia somente `chargeTypes: [DETACHED]`: **parcelamento ainda não está habilitado**. Para oferecer parcelas, é preciso definir a política de parcelas e taxas, enviar `INSTALLMENT` com os parâmetros correspondentes e validar a conciliação dos pagamentos parcelados antes de publicar essa opção.
