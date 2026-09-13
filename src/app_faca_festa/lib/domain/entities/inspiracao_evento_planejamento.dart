class TarefaInspiracaoEvento {
  const TarefaInspiracaoEvento({
    required this.id,
    required this.eventoId,
    required this.userId,
    required this.inspiracaoId,
    required this.titulo,
    this.descricao = '',
    this.categoria = '',
    this.origem = '',
    this.concluida = false,
    this.ativo = true,
    this.deletado = false,
  });

  final String id;
  final String eventoId;
  final String userId;
  final String inspiracaoId;
  final String titulo;
  final String descricao;
  final String categoria;
  final String origem;
  final bool concluida;
  final bool ativo;
  final bool deletado;

  bool visivelPara({
    required String eventoId,
    required String userId,
  }) {
    return _documentoVisivel(
      ativo: ativo,
      deletado: deletado,
      eventoIdDocumento: this.eventoId,
      userIdDocumento: this.userId,
      eventoId: eventoId,
      userId: userId,
    );
  }

  bool pertenceAInspiracao(String inspiracaoId) {
    return _vinculoAtivoDaInspiracao(
      itemInspiracaoId: this.inspiracaoId,
      origem: origem,
      ativo: ativo,
      deletado: deletado,
      inspiracaoId: inspiracaoId,
    );
  }
}

class ItemOrcamentoInspiracaoEvento {
  const ItemOrcamentoInspiracaoEvento({
    required this.id,
    required this.eventoId,
    required this.userId,
    required this.inspiracaoId,
    required this.item,
    this.categoria = '',
    this.descricao = '',
    this.custoEstimado = 0,
    this.custoReal = 0,
    this.origem = '',
    this.ativo = true,
    this.deletado = false,
  });

  final String id;
  final String eventoId;
  final String userId;
  final String inspiracaoId;
  final String item;
  final String categoria;
  final String descricao;
  final double custoEstimado;
  final double custoReal;
  final String origem;
  final bool ativo;
  final bool deletado;

  double get valorOrcado => custoReal > 0 ? custoReal : custoEstimado;

  bool visivelPara({
    required String eventoId,
    required String userId,
  }) {
    return _documentoVisivel(
      ativo: ativo,
      deletado: deletado,
      eventoIdDocumento: this.eventoId,
      userIdDocumento: this.userId,
      eventoId: eventoId,
      userId: userId,
    );
  }

  bool pertenceAInspiracao(String inspiracaoId) {
    return _vinculoAtivoDaInspiracao(
      itemInspiracaoId: this.inspiracaoId,
      origem: origem,
      ativo: ativo,
      deletado: deletado,
      inspiracaoId: inspiracaoId,
    );
  }
}

bool _documentoVisivel({
  required bool ativo,
  required bool deletado,
  required String eventoIdDocumento,
  required String userIdDocumento,
  required String eventoId,
  required String userId,
}) {
  if (!ativo || deletado) return false;

  final mesmoEvento =
      eventoIdDocumento.isEmpty || eventoIdDocumento == eventoId;
  final mesmoUsuario = userIdDocumento.isEmpty || userIdDocumento == userId;
  return mesmoEvento && mesmoUsuario;
}

bool _vinculoAtivoDaInspiracao({
  required String itemInspiracaoId,
  required String origem,
  required bool ativo,
  required bool deletado,
  required String inspiracaoId,
}) {
  final id = inspiracaoId.trim();
  if (id.isEmpty) return false;
  if (itemInspiracaoId.trim() != id) return false;
  if (!ativo || deletado) return false;

  final origemNormalizada = origem.trim().toLowerCase();
  return origemNormalizada.isEmpty || origemNormalizada.contains('inspiracao');
}
