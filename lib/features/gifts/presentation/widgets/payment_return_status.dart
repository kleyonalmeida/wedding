import 'package:flutter/material.dart';

({String badge, String headline, String description, IconData icon})
    paymentReturnStatus(String status) => switch (status) {
          'Confirmed' => (
              badge: 'PRESENTE CONFIRMADO COM SUCESSO',
              headline: 'Obrigado por celebrar nosso amor',
              description:
                  'Recebemos a notificação do seu presente com imensa alegria e profunda gratidão. Seu gesto torna a realização do nosso sonho em uma memória eterna e inesquecível.',
              icon: Icons.verified
            ),
          'Received' => (
              badge: 'PRESENTE CONFIRMADO COM SUCESSO',
              headline: 'Obrigado por celebrar nosso amor',
              description:
                  'Recebemos a notificação do seu presente com imensa alegria e profunda gratidão. Seu gesto torna a realização do nosso sonho em uma memória eterna e inesquecível.',
              icon: Icons.verified
            ),
          'Pending' => (
              badge: 'CONFIRMAÇÃO PENDENTE',
              headline: 'Seu presente está aguardando confirmação',
              description:
                  'A confirmação pode levar alguns minutos. Atualize a situação para consultar a contribuição.',
              icon: Icons.schedule
            ),
          'Cancelled' => (
              badge: 'PRESENTE CANCELADO',
              headline: 'A contribuição foi cancelada',
              description:
                  'Esta contribuição está cancelada. Fale com os noivos se precisar de ajuda.',
              icon: Icons.cancel_outlined
            ),
          'Overdue' => (
              badge: 'PRAZO EXPIRADO',
              headline: 'O prazo da contribuição expirou',
              description:
                  'O prazo expirou. Fale com os noivos para esclarecer a situação.',
              icon: Icons.event_busy
            ),
          'Refunded' => (
              badge: 'PRESENTE REEMBOLSADO',
              headline: 'A contribuição foi reembolsada',
              description:
                  'A contribuição consta como reembolsada. Fale com os noivos se precisar de esclarecimentos.',
              icon: Icons.undo
            ),
          'Disputed' => (
              badge: 'PRESENTE EM CONTESTAÇÃO',
              headline: 'A contribuição está em contestação',
              description:
                  'A situação precisa de acompanhamento. Entre em contato diretamente com os noivos.',
              icon: Icons.info_outline
            ),
          _ => (
              badge: 'SITUAÇÃO EM VERIFICAÇÃO',
              headline: 'Estamos verificando a situação',
              description:
                  'Não há uma confirmação disponível para esta situação. Atualize a consulta ou fale com os noivos.',
              icon: Icons.info_outline
            ),
        };
