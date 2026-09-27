import 'package:flutter/material.dart';

({String badge, String headline, String description, IconData icon})
    paymentReturnStatus(String status) => switch (status) {
          'Confirmed' => (
              badge: 'PAGAMENTO CONFIRMADO',
              headline: 'Obrigado por celebrar nosso amor',
              description:
                  'Seu pagamento foi confirmado. Agradecemos pelo carinho e por fazer parte desta celebração.',
              icon: Icons.verified
            ),
          'Received' => (
              badge: 'PAGAMENTO RECEBIDO',
              headline: 'Obrigado por celebrar nosso amor',
              description:
                  'Seu pagamento foi recebido. Agradecemos pelo carinho e por fazer parte desta celebração.',
              icon: Icons.verified
            ),
          'Pending' => (
              badge: 'CONFIRMAÇÃO PENDENTE',
              headline: 'Seu presente está aguardando confirmação',
              description:
                  'A confirmação pode levar alguns minutos. Atualize a situação para consultar o pagamento.',
              icon: Icons.schedule
            ),
          'Cancelled' => (
              badge: 'PAGAMENTO CANCELADO',
              headline: 'O pagamento foi cancelado',
              description:
                  'Este pagamento está cancelado. Fale com o noivo se precisar de ajuda.',
              icon: Icons.cancel_outlined
            ),
          'Overdue' => (
              badge: 'PAGAMENTO VENCIDO',
              headline: 'O prazo do pagamento venceu',
              description:
                  'O pagamento está vencido. Fale com o noivo para esclarecer a situação.',
              icon: Icons.event_busy
            ),
          'Refunded' => (
              badge: 'PAGAMENTO REEMBOLSADO',
              headline: 'O pagamento foi reembolsado',
              description:
                  'O pedido consta como reembolsado. Fale com o noivo se precisar de esclarecimentos.',
              icon: Icons.undo
            ),
          'Disputed' => (
              badge: 'PAGAMENTO EM CONTESTAÇÃO',
              headline: 'O pagamento está em contestação',
              description:
                  'A situação precisa de acompanhamento. Entre em contato diretamente com o noivo.',
              icon: Icons.info_outline
            ),
          _ => (
              badge: 'SITUAÇÃO EM VERIFICAÇÃO',
              headline: 'Estamos verificando a situação',
              description:
                  'Não há uma confirmação disponível para esta situação. Atualize a consulta ou fale com o noivo.',
              icon: Icons.info_outline
            ),
        };
