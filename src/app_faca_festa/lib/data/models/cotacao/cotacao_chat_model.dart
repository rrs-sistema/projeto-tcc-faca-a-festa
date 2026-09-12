import 'package:app_faca_festa/domain/entities/cotacao_chat.dart';

export 'package:app_faca_festa/domain/entities/cotacao_chat.dart'
    show
        CotacaoConversa,
        CotacaoFornecedorResumo,
        CotacaoMensagem,
        CotacaoServicoResumo;

class CotacaoConversaModel extends CotacaoConversa {
  const CotacaoConversaModel({
    required super.idCotacao,
    required super.idFornecedor,
    required super.categoria,
    required super.idEvento,
    required super.nomeSolicitante,
    required super.dataSolicitacao,
    required super.ultimaMensagem,
    required super.ultimaMensagemEm,
    required super.naoLidas,
  });
}

class CotacaoMensagemModel extends CotacaoMensagem {
  const CotacaoMensagemModel({
    required super.idUsuario,
    required super.nomeUsuario,
    required super.mensagem,
    required super.enviadoEm,
    required super.lido,
  });
}

class CotacaoServicoResumoModel extends CotacaoServicoResumo {
  const CotacaoServicoResumoModel({
    required super.nome,
    required super.quantidade,
    required super.valorEstimado,
  });
}

class CotacaoFornecedorResumoModel extends CotacaoFornecedorResumo {
  const CotacaoFornecedorResumoModel({
    required super.idFornecedor,
    required super.status,
    required super.observacaoFornecedor,
    required super.prazoEntrega,
    required super.condicaoPagamento,
    required List<CotacaoServicoResumoModel> super.servicos,
  });
}
