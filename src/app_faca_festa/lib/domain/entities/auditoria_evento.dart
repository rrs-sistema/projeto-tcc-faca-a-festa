class AuditoriaMudanca {
  const AuditoriaMudanca({
    required this.campo,
    this.de = '',
    this.para = '',
  });

  final String campo;
  final String de;
  final String para;

  Map<String, dynamic> toMap() => {
        'campo': campo,
        'de': de,
        'para': para,
      };

  factory AuditoriaMudanca.fromMap(Map<String, dynamic> map) {
    return AuditoriaMudanca(
      campo: (map['campo'] ?? '').toString(),
      de: (map['de'] ?? '').toString(),
      para: (map['para'] ?? '').toString(),
    );
  }
}

class AuditoriaEvento {
  const AuditoriaEvento({
    required this.id,
    required this.acao,
    required this.area,
    required this.nivel,
    required this.resumo,
    this.entidadeTipo,
    this.entidadeId,
    this.entidadeNome,
    this.idFornecedor,
    this.idEvento,
    this.idServico,
    this.idCotacao,
    this.idOrcamento,
    this.atorUid,
    this.atorNome,
    this.atorEmail,
    this.atorTipo,
    this.atorAuthType,
    this.mudancas = const [],
    this.detalhe,
    this.visivelFornecedor = false,
    this.plataforma,
    this.rota,
    this.origem,
    this.operacao,
    this.documentPath,
    this.sourceEventId,
    this.algoritmoHash,
    this.hashIntegridade,
    this.criadoEm,
  });

  final String id;
  final String acao;
  final String area;
  final String nivel;
  final String resumo;
  final String? entidadeTipo;
  final String? entidadeId;
  final String? entidadeNome;
  final String? idFornecedor;
  final String? idEvento;
  final String? idServico;
  final String? idCotacao;
  final String? idOrcamento;
  final String? atorUid;
  final String? atorNome;
  final String? atorEmail;
  final String? atorTipo;
  final String? atorAuthType;
  final List<AuditoriaMudanca> mudancas;
  final Map<String, dynamic>? detalhe;
  final bool visivelFornecedor;
  final String? plataforma;
  final String? rota;
  final String? origem;
  final String? operacao;
  final String? documentPath;
  final String? sourceEventId;
  final String? algoritmoHash;
  final String? hashIntegridade;
  final DateTime? criadoEm;

  bool get ocorreuHoje {
    final data = criadoEm;
    if (data == null) return false;
    final agora = DateTime.now();
    return data.year == agora.year &&
        data.month == agora.month &&
        data.day == agora.day;
  }
}

class AuditoriaPagina {
  const AuditoriaPagina({
    required this.eventos,
    this.proximoCursorCriadoEm,
    this.temMais = false,
  });

  final List<AuditoriaEvento> eventos;
  final DateTime? proximoCursorCriadoEm;
  final bool temMais;
}

class AuditoriaConsulta {
  const AuditoriaConsulta({
    required this.escopoAdmin,
    this.idFornecedor,
    this.area,
    this.acao,
    this.origem,
    this.nivel,
    this.criadoDe,
    this.criadoAte,
    this.cursorCriadoEm,
    this.incluirSnapshots = true,
    this.limite = 150,
  });

  final bool escopoAdmin;
  final String? idFornecedor;
  final String? area;
  final String? acao;
  final String? origem;
  final String? nivel;
  final DateTime? criadoDe;
  final DateTime? criadoAte;
  final DateTime? cursorCriadoEm;
  final bool incluirSnapshots;
  final int limite;
}

class RegistroAuditoria {
  const RegistroAuditoria({
    required this.acao,
    required this.resumo,
    this.entidadeTipo,
    this.entidadeId,
    this.entidadeNome,
    this.idFornecedor,
    this.idEvento,
    this.idServico,
    this.idCotacao,
    this.idOrcamento,
    this.mudancas = const [],
    this.detalhe,
    this.plataforma,
    this.rota,
  });

  final String acao;
  final String resumo;
  final String? entidadeTipo;
  final String? entidadeId;
  final String? entidadeNome;
  final String? idFornecedor;
  final String? idEvento;
  final String? idServico;
  final String? idCotacao;
  final String? idOrcamento;
  final List<AuditoriaMudanca> mudancas;
  final Map<String, dynamic>? detalhe;
  final String? plataforma;
  final String? rota;
}

class RegistroFalhaLogin {
  const RegistroFalhaLogin({
    required this.email,
    required this.codigo,
    this.metodo = 'senha',
    this.plataforma,
    this.rota,
  });

  final String email;
  final String codigo;
  final String metodo;
  final String? plataforma;
  final String? rota;
}
