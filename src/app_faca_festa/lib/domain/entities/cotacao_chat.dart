class CotacaoConversa {
  const CotacaoConversa({
    required this.idCotacao,
    required this.idFornecedor,
    required this.categoria,
    required this.idEvento,
    required this.nomeSolicitante,
    required this.dataSolicitacao,
    required this.ultimaMensagem,
    required this.ultimaMensagemEm,
    required this.naoLidas,
  });

  final String idCotacao;
  final String idFornecedor;
  final String categoria;
  final String idEvento;
  final String nomeSolicitante;
  final DateTime dataSolicitacao;
  final String ultimaMensagem;
  final DateTime? ultimaMensagemEm;
  final int naoLidas;
}

class CotacaoMensagem {
  const CotacaoMensagem({
    required this.idUsuario,
    required this.nomeUsuario,
    required this.mensagem,
    required this.enviadoEm,
    required this.lido,
    this.sistema = false,
  });

  final String idUsuario;
  final String nomeUsuario;
  final String mensagem;
  final DateTime enviadoEm;
  final bool lido;
  final bool sistema;

  bool get ehSistema => sistema || idUsuario == 'sistema';
}

class CotacaoServicoResumo {
  const CotacaoServicoResumo({
    required this.nome,
    required this.quantidade,
    required this.valorEstimado,
  });

  final String nome;
  final num quantidade;
  final num valorEstimado;
}

class CotacaoFornecedorResumo {
  const CotacaoFornecedorResumo({
    required this.idFornecedor,
    required this.status,
    required this.observacaoFornecedor,
    required this.prazoEntrega,
    required this.condicaoPagamento,
    required this.servicos,
    this.valorCotado,
  });

  final String idFornecedor;
  final String status;
  final String observacaoFornecedor;
  final DateTime? prazoEntrega;
  final String? condicaoPagamento;
  final List<CotacaoServicoResumo> servicos;
  final double? valorCotado;

  bool get temResposta {
    return observacaoFornecedor.trim().isNotEmpty ||
        prazoEntrega != null ||
        (condicaoPagamento?.trim().isNotEmpty ?? false) ||
        (valorCotado != null && valorCotado! > 0);
  }

  bool get chatAberto {
    final s = status.toLowerCase();
    return s != 'cancelada' &&
        s != 'cancelado' &&
        s != 'recusado' &&
        s != 'recusada' &&
        s != 'perdeucotacao';
  }
}
