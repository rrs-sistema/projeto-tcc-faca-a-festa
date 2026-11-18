enum FiltroComercialEvento {
  todos,
  semCotacao,
  proximos90Dias,
  prioridadeAlta,
  organizadorRecorrente,
  followUp,
}

class FollowUpComercial {
  const FollowUpComercial({
    required this.marcado,
    this.em,
    this.por = '',
    this.nota,
    this.proximoContato,
  });

  final bool marcado;
  final DateTime? em;
  final String por;
  final String? nota;
  final DateTime? proximoContato;

  factory FollowUpComercial.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const FollowUpComercial(marcado: false);
    return FollowUpComercial(
      marcado: map['marcado'] == true,
      em: _asDate(map['em'] ?? map['em_']),
      por: (map['por'] ?? '').toString(),
      nota: (map['nota'] ?? '').toString().trim().isEmpty
          ? null
          : (map['nota'] ?? '').toString().trim(),
      proximoContato: _asDate(
          map['proximo_contato'] ?? map['proximoContato'] ?? map['proximo']),
    );
  }

  static DateTime? _asDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    try {
      // Timestamp do Firestore no client.
      final dynamic dyn = value;
      if (dyn.toDate is Function) return dyn.toDate() as DateTime;
    } catch (_) {}
    return null;
  }
}

class NudgeCotacao {
  const NudgeCotacao({
    this.em,
    this.por = '',
    this.mensagem = '',
    this.qtdFornecedores = 0,
  });

  final DateTime? em;
  final String por;
  final String mensagem;
  final int qtdFornecedores;

  bool get enviado => em != null || mensagem.trim().isNotEmpty;

  factory NudgeCotacao.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const NudgeCotacao();
    return NudgeCotacao(
      em: FollowUpComercial._asDate(map['em']),
      por: (map['por'] ?? '').toString(),
      mensagem: (map['mensagem'] ?? '').toString(),
      qtdFornecedores: () {
        final v = map['qtd_fornecedores'] ?? map['qtdFornecedores'] ?? 0;
        if (v is num) return v.toInt();
        return int.tryParse('$v') ?? 0;
      }(),
    );
  }
}

class HeatmapDemandaCelula {
  const HeatmapDemandaCelula({
    required this.cidade,
    required this.tipoNome,
    required this.quantidade,
    required this.semCotacao,
  });

  final String cidade;
  final String tipoNome;
  final int quantidade;
  final int semCotacao;
}

class FornecedorSugestaoAdmin {
  const FornecedorSugestaoAdmin({
    required this.idFornecedor,
    required this.nomeFornecedor,
    required this.score,
    this.nivel = '',
    this.nivelLabel = '',
    this.motivoPrincipal = '',
    this.categoriaPrincipal = '',
    this.mediaAvaliacoes = 0,
    this.totalAvaliacoes = 0,
    this.distanciaKm,
  });

  final String idFornecedor;
  final String nomeFornecedor;
  final double score;
  final String nivel;
  final String nivelLabel;
  final String motivoPrincipal;
  final String categoriaPrincipal;
  final double mediaAvaliacoes;
  final int totalAvaliacoes;
  final double? distanciaKm;

  factory FornecedorSugestaoAdmin.fromMap(Map<String, dynamic> map) {
    double? asDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v.replaceAll(',', '.'));
      return null;
    }

    int asInt(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return FornecedorSugestaoAdmin(
      idFornecedor:
          (map['idFornecedor'] ?? map['id_fornecedor'] ?? '').toString(),
      nomeFornecedor:
          (map['nomeFornecedor'] ?? map['nome_fornecedor'] ?? 'Fornecedor')
              .toString(),
      score: asDouble(map['score']) ?? 0,
      nivel: (map['nivel'] ?? '').toString(),
      nivelLabel: (map['nivelLabel'] ?? map['nivel_label'] ?? '').toString(),
      motivoPrincipal:
          (map['motivoPrincipal'] ?? map['motivo_principal'] ?? '').toString(),
      categoriaPrincipal:
          (map['categoriaPrincipal'] ?? map['categoria_principal'] ?? '')
              .toString(),
      mediaAvaliacoes: asDouble(
              map['mediaAvaliacoes'] ?? map['media_avaliacoes']) ??
          0,
      totalAvaliacoes:
          asInt(map['totalAvaliacoes'] ?? map['total_avaliacoes']),
      distanciaKm: asDouble(map['distanciaKm'] ?? map['distancia_km']),
    );
  }
}

class EventoAdmin {
  EventoAdmin({
    required this.id,
    required this.nome,
    required this.tipoNome,
    required this.organizador,
    this.cidade,
    this.uf,
    this.data,
    this.dataCadastro,
    this.aprovado = false,
    this.ativo = true,
    this.status = '',
    this.totalConvidados = 0,
    this.custoEstimado,
    this.totalCotacoes = 0,
    this.idUsuario = '',
    this.idTipoEvento = '',
    this.eventosDoOrganizador = 1,
    this.followUp = const FollowUpComercial(marcado: false),
    this.nudge = const NudgeCotacao(),
  });

  final String id;
  final String nome;
  final String tipoNome;
  final String organizador;
  final String? cidade;
  final String? uf;
  final bool aprovado;
  final bool ativo;
  final String status;
  final int totalConvidados;
  final DateTime? data;
  final DateTime? dataCadastro;
  final double? custoEstimado;
  final int totalCotacoes;
  final String idUsuario;
  final String idTipoEvento;
  final int eventosDoOrganizador;
  final FollowUpComercial followUp;
  final NudgeCotacao nudge;

  bool get emCurso {
    const ativos = {
      'rascunho',
      'planejamento',
      'confirmado',
      'emAndamento',
      'em_andamento',
    };
    if (status.isNotEmpty) return ativos.contains(status);
    return ativo &&
        (data == null ||
            !data!.isBefore(DateTime.now().subtract(const Duration(days: 1))));
  }

  bool get semCotacao => totalCotacoes <= 0;

  bool get organizadorRecorrente => eventosDoOrganizador >= 2;

  bool get temFollowUp => followUp.marcado;

  bool get temNudge => nudge.enviado;

  int? get diasAteEvento {
    final d = data;
    if (d == null) return null;
    final hoje = DateTime.now();
    final inicio = DateTime(hoje.year, hoje.month, hoje.day);
    final alvo = DateTime(d.year, d.month, d.day);
    return alvo.difference(inicio).inDays;
  }

  bool get nosProximos90Dias {
    final dias = diasAteEvento;
    return dias != null && dias >= 0 && dias <= 90;
  }

  bool nosProximosDias(int maxDias) {
    final dias = diasAteEvento;
    return dias != null && dias >= 0 && dias <= maxDias;
  }

  String get statusLabel {
    switch (status) {
      case 'rascunho':
        return 'Rascunho';
      case 'planejamento':
        return 'Em planejamento';
      case 'confirmado':
        return 'Confirmado';
      case 'emAndamento':
      case 'em_andamento':
        return 'Em andamento';
      case 'finalizado':
        return 'Finalizado';
      case 'adiado':
        return 'Adiado';
      case 'cancelado':
        return 'Cancelado';
      default:
        return aprovado ? 'Aprovado' : 'Em análise';
    }
  }

  String get faixaPublico {
    if (totalConvidados <= 0) return 'Público não informado';
    if (totalConvidados < 20) return 'Até 20 convidados';
    if (totalConvidados < 40) return '20–39 convidados';
    if (totalConvidados < 80) return '40–79 convidados';
    return '80+ convidados';
  }

  String get faixaTicketEstimada {
    if (custoEstimado != null && custoEstimado! > 0) {
      return _formatarMoeda(custoEstimado!);
    }
    if (totalConvidados <= 0) return 'Ticket a estimar';
    final tipo = tipoNome.toLowerCase();
    var perCapita = 80.0;
    if (tipo.contains('corporativ') || tipo.contains('confratern')) {
      perCapita = 120;
    } else if (tipo.contains('casamento')) {
      perCapita = 200;
    } else if (tipo.contains('formatura')) {
      perCapita = 100;
    } else if (tipo.contains('15') || tipo.contains('debutante')) {
      perCapita = 150;
    }
    return '~ ${_formatarMoeda(totalConvidados * perCapita)}';
  }

  static String _formatarMoeda(double valor) {
    final inteiro = valor.round();
    final texto = inteiro.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < texto.length; i++) {
      final restante = texto.length - i;
      buffer.write(texto[i]);
      if (restante > 1 && restante % 3 == 1) buffer.write('.');
    }
    return 'R\$ $buffer';
  }

  EventoAdmin copyWith({
    String? id,
    String? nome,
    String? tipoNome,
    String? organizador,
    String? cidade,
    String? uf,
    DateTime? data,
    DateTime? dataCadastro,
    bool? aprovado,
    bool? ativo,
    String? status,
    int? totalConvidados,
    double? custoEstimado,
    int? totalCotacoes,
    String? idUsuario,
    String? idTipoEvento,
    int? eventosDoOrganizador,
    FollowUpComercial? followUp,
    NudgeCotacao? nudge,
  }) {
    return EventoAdmin(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      tipoNome: tipoNome ?? this.tipoNome,
      organizador: organizador ?? this.organizador,
      cidade: cidade ?? this.cidade,
      uf: uf ?? this.uf,
      data: data ?? this.data,
      dataCadastro: dataCadastro ?? this.dataCadastro,
      aprovado: aprovado ?? this.aprovado,
      ativo: ativo ?? this.ativo,
      status: status ?? this.status,
      totalConvidados: totalConvidados ?? this.totalConvidados,
      custoEstimado: custoEstimado ?? this.custoEstimado,
      totalCotacoes: totalCotacoes ?? this.totalCotacoes,
      idUsuario: idUsuario ?? this.idUsuario,
      idTipoEvento: idTipoEvento ?? this.idTipoEvento,
      eventosDoOrganizador:
          eventosDoOrganizador ?? this.eventosDoOrganizador,
      followUp: followUp ?? this.followUp,
      nudge: nudge ?? this.nudge,
    );
  }
}
