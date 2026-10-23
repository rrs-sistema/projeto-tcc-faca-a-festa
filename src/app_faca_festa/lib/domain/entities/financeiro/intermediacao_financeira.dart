/// Dimensões operacionais da intermediação (Prompt 02).
/// Não são somáveis indiscriminadamente; não afirmam enquadramento contábil.
library;

enum NivelConfirmacaoRecebimento {
  declaracao,
  conferencia,
  fonteExterna;

  String get firestoreValue {
    switch (this) {
      case NivelConfirmacaoRecebimento.declaracao:
        return 'declaracao';
      case NivelConfirmacaoRecebimento.conferencia:
        return 'conferencia';
      case NivelConfirmacaoRecebimento.fonteExterna:
        return 'fonte_externa';
    }
  }

  String get rotulo {
    switch (this) {
      case NivelConfirmacaoRecebimento.declaracao:
        return 'Declaração';
      case NivelConfirmacaoRecebimento.conferencia:
        return 'Conferência manual';
      case NivelConfirmacaoRecebimento.fonteExterna:
        return 'Fonte externa';
    }
  }
}

enum EstadoRepasse {
  previsto,
  elegivelPendente,
  autorizado,
  emProcessamento,
  confirmado,
  falhou,
  cancelado;

  String get firestoreValue {
    switch (this) {
      case EstadoRepasse.previsto:
        return 'previsto';
      case EstadoRepasse.elegivelPendente:
        return 'elegivel_pendente';
      case EstadoRepasse.autorizado:
        return 'autorizado';
      case EstadoRepasse.emProcessamento:
        return 'em_processamento';
      case EstadoRepasse.confirmado:
        return 'confirmado';
      case EstadoRepasse.falhou:
        return 'falhou';
      case EstadoRepasse.cancelado:
        return 'cancelado';
    }
  }

  String get rotulo {
    switch (this) {
      case EstadoRepasse.previsto:
        return 'Previsto';
      case EstadoRepasse.elegivelPendente:
        return 'Elegibilidade pendente';
      case EstadoRepasse.autorizado:
        return 'Autorizado';
      case EstadoRepasse.emProcessamento:
        return 'Em processamento';
      case EstadoRepasse.confirmado:
        return 'Confirmado (conferência)';
      case EstadoRepasse.falhou:
        return 'Falhou';
      case EstadoRepasse.cancelado:
        return 'Cancelado';
    }
  }

  static EstadoRepasse fromString(String? v) {
    switch ((v ?? '').trim().toLowerCase()) {
      case 'autorizado':
        return EstadoRepasse.autorizado;
      case 'em_processamento':
        return EstadoRepasse.emProcessamento;
      case 'confirmado':
        return EstadoRepasse.confirmado;
      case 'falhou':
        return EstadoRepasse.falhou;
      case 'cancelado':
        return EstadoRepasse.cancelado;
      case 'elegivel_pendente':
        return EstadoRepasse.elegivelPendente;
      default:
        return EstadoRepasse.previsto;
    }
  }
}

enum ModoComissaoIntermediacao {
  descontadaFornecedor,
  adicionadaCliente;

  String get firestoreValue => this == ModoComissaoIntermediacao.adicionadaCliente
      ? 'adicionada_cliente'
      : 'descontada_fornecedor';
}

/// Direitos calculados — modo desconto não cria cobrança duplicada.
class DireitosContratoIntermediado {
  const DireitosContratoIntermediado({
    required this.comissaoPrevistaCentavos,
    required this.direitoFornecedorPrevistoCentavos,
    required this.precoClienteCentavos,
  });

  final int comissaoPrevistaCentavos;
  final int direitoFornecedorPrevistoCentavos;
  final int precoClienteCentavos;
}

class PosicaoContratoIntermediado {
  const PosicaoContratoIntermediado({
    required this.idContrato,
    required this.valorContratadoCentavos,
    required this.comissaoPrevistaCentavos,
    required this.direitoFornecedorPrevistoCentavos,
    required this.recebidoPlataformaAlocadoCentavos,
    required this.aReceberClienteCentavos,
    required this.previstoRepasseCentavos,
    required this.elegivelRepasseCentavos,
    required this.repassadoConfirmadoCentavos,
    required this.semAlocacaoNoPedidoCentavos,
    required this.politicaLiberacaoAtiva,
  });

  final String idContrato;
  final int valorContratadoCentavos;
  final int comissaoPrevistaCentavos;
  final int direitoFornecedorPrevistoCentavos;
  final int recebidoPlataformaAlocadoCentavos;
  final int aReceberClienteCentavos;
  final int previstoRepasseCentavos;
  final int elegivelRepasseCentavos;
  final int repassadoConfirmadoCentavos;
  final int semAlocacaoNoPedidoCentavos;
  final bool politicaLiberacaoAtiva;
}
