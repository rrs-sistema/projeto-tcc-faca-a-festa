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
  });

  final String idUsuario;
  final String nomeUsuario;
  final String mensagem;
  final DateTime enviadoEm;
  final bool lido;
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
  });

  final String idFornecedor;
  final String status;
  final String observacaoFornecedor;
  final DateTime? prazoEntrega;
  final String? condicaoPagamento;
  final List<CotacaoServicoResumo> servicos;

  bool get temResposta {
    return observacaoFornecedor.trim().isNotEmpty ||
        prazoEntrega != null ||
        (condicaoPagamento?.trim().isNotEmpty ?? false);
  }
}
