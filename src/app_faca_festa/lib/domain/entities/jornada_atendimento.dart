import 'cotacao.dart';

String estadoComercialCotacao(Cotacao c) {
  if (c.estadoComercial != null) return c.estadoComercial!;
  return switch (c.status) {
    StatusCotacao.concluida => 'ganho',
    StatusCotacao.cancelada => 'cancelado',
    StatusCotacao.recusado => 'recusado',
    StatusCotacao.perdeuCotacao => 'perdido',
    StatusCotacao.respondida || StatusCotacao.parcial => 'proposta_enviada',
    _ => 'nova_solicitacao'
  };
}

bool entregaAceitaCotacao(Cotacao c) => c.estadoExecucao == 'aceito';
