/// Snapshot comercial no aceite — não concede autorização; não é perfil atual.
class SnapshotIdentidadeComercial {
  const SnapshotIdentidadeComercial({
    required this.idEvento,
    required this.origem,
    required this.capturadoEm,
    this.nomeEvento,
    this.idOrganizador,
    this.nomeOrganizador,
    this.idContratante,
    this.nomeContratante,
    this.idPagador,
    this.nomePagador,
    this.idFornecedor,
    this.nomeFornecedor,
    this.idServico,
    this.nomeServico,
    this.descricaoEscopo,
    this.quantidade,
    this.unidade,
    this.valorCentavos,
    this.idOperadorAcompanhamento,
  });

  final String idEvento;
  final String origem;
  final String capturadoEm;
  final String? nomeEvento;
  final String? idOrganizador;
  final String? nomeOrganizador;
  final String? idContratante;
  final String? nomeContratante;
  final String? idPagador;
  final String? nomePagador;
  final String? idFornecedor;
  final String? nomeFornecedor;
  final String? idServico;
  final String? nomeServico;
  final String? descricaoEscopo;
  final num? quantidade;
  final String? unidade;
  final int? valorCentavos;
  final String? idOperadorAcompanhamento;

  factory SnapshotIdentidadeComercial.fromMap(Map<String, dynamic> map) {
    return SnapshotIdentidadeComercial(
      idEvento: (map['id_evento'] ?? '').toString(),
      origem: (map['origem'] ?? '').toString(),
      capturadoEm: (map['capturado_em'] ?? '').toString(),
      nomeEvento: map['nome_evento']?.toString(),
      idOrganizador: map['id_organizador']?.toString(),
      nomeOrganizador: map['nome_organizador']?.toString(),
      idContratante: map['id_contratante']?.toString(),
      nomeContratante: map['nome_contratante']?.toString(),
      idPagador: map['id_pagador']?.toString(),
      nomePagador: map['nome_pagador']?.toString(),
      idFornecedor: map['id_fornecedor']?.toString(),
      nomeFornecedor: map['nome_fornecedor']?.toString(),
      idServico: map['id_servico']?.toString(),
      nomeServico: map['nome_servico']?.toString(),
      descricaoEscopo: map['descricao_escopo']?.toString(),
      quantidade: map['quantidade'] as num?,
      unidade: map['unidade']?.toString(),
      valorCentavos: (map['valor_centavos'] as num?)?.toInt(),
      idOperadorAcompanhamento:
          map['id_operador_acompanhamento']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'schema': 1,
        'origem': origem,
        'capturado_em': capturadoEm,
        'id_evento': idEvento,
        'nome_evento': nomeEvento,
        'id_organizador': idOrganizador,
        'nome_organizador': nomeOrganizador,
        'id_contratante': idContratante,
        'nome_contratante': nomeContratante,
        'id_pagador': idPagador,
        'nome_pagador': nomePagador,
        'id_fornecedor': idFornecedor,
        'nome_fornecedor': nomeFornecedor,
        'id_servico': idServico,
        'nome_servico': nomeServico,
        'descricao_escopo': descricaoEscopo,
        'quantidade': quantidade,
        'unidade': unidade,
        'valor_centavos': valorCentavos,
        'id_operador_acompanhamento': idOperadorAcompanhamento,
      };
}

enum EstadoExecucaoContrato {
  naoIniciado,
  agendado,
  emExecucao,
  entregaInformada,
  aceito,
  contestado,
  canceladoExecucao;

  String get firestoreValue {
    switch (this) {
      case EstadoExecucaoContrato.naoIniciado:
        return 'nao_iniciado';
      case EstadoExecucaoContrato.agendado:
        return 'agendado';
      case EstadoExecucaoContrato.emExecucao:
        return 'em_execucao';
      case EstadoExecucaoContrato.entregaInformada:
        return 'entrega_informada';
      case EstadoExecucaoContrato.aceito:
        return 'aceito';
      case EstadoExecucaoContrato.contestado:
        return 'contestado';
      case EstadoExecucaoContrato.canceladoExecucao:
        return 'cancelado_execucao';
    }
  }

  String get rotulo {
    switch (this) {
      case EstadoExecucaoContrato.naoIniciado:
        return 'Execução não iniciada';
      case EstadoExecucaoContrato.agendado:
        return 'Agendado';
      case EstadoExecucaoContrato.emExecucao:
        return 'Em execução';
      case EstadoExecucaoContrato.entregaInformada:
        return 'Entrega informada';
      case EstadoExecucaoContrato.aceito:
        return 'Aceito';
      case EstadoExecucaoContrato.contestado:
        return 'Contestado';
      case EstadoExecucaoContrato.canceladoExecucao:
        return 'Execução cancelada';
    }
  }

  static EstadoExecucaoContrato fromString(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'agendado':
        return EstadoExecucaoContrato.agendado;
      case 'em_execucao':
        return EstadoExecucaoContrato.emExecucao;
      case 'entrega_informada':
        return EstadoExecucaoContrato.entregaInformada;
      case 'aceito':
        return EstadoExecucaoContrato.aceito;
      case 'contestado':
        return EstadoExecucaoContrato.contestado;
      case 'cancelado_execucao':
        return EstadoExecucaoContrato.canceladoExecucao;
      default:
        return EstadoExecucaoContrato.naoIniciado;
    }
  }
}

/// Linha administrativa: uma contratação (orçamento/contrato) identificada.
class LinhaContratacaoAdmin {
  const LinhaContratacaoAdmin({
    required this.idContrato,
    required this.idOrcamento,
    required this.idEvento,
    required this.contratado,
    required this.estadoComercial,
    required this.estadoExecucao,
    this.nomeEvento,
    this.nomeOrganizador,
    this.nomeContratante,
    this.nomePagador,
    this.nomeFornecedor,
    this.nomeServico,
    this.valorContratadoCentavos = 0,
    this.pagoCentavos = 0,
    this.pendenciasIdentificacao = const [],
    this.identidadeIncompleta = false,
    this.perfilAtualSeparado = false,
    this.nomeFornecedorAtual,
    this.snapshotAceite,
  });

  final String idContrato;
  final String idOrcamento;
  final String idEvento;
  final String? nomeEvento;
  final String? nomeOrganizador;
  final String? nomeContratante;
  final String? nomePagador;
  final String? nomeFornecedor;
  final String? nomeServico;
  final bool contratado;
  final String estadoComercial;
  final EstadoExecucaoContrato estadoExecucao;
  final int valorContratadoCentavos;
  final int pagoCentavos;
  final List<String> pendenciasIdentificacao;
  final bool identidadeIncompleta;
  final bool perfilAtualSeparado;
  final String? nomeFornecedorAtual;
  final SnapshotIdentidadeComercial? snapshotAceite;

  String get rotuloEvento =>
      (nomeEvento != null && nomeEvento!.trim().isNotEmpty)
          ? nomeEvento!.trim()
          : 'Evento sem nome';

  String get rotuloContratante =>
      (nomeContratante != null && nomeContratante!.trim().isNotEmpty)
          ? nomeContratante!.trim()
          : 'Contratante pendente';

  String get rotuloFornecedor =>
      (nomeFornecedor != null && nomeFornecedor!.trim().isNotEmpty)
          ? nomeFornecedor!.trim()
          : 'Fornecedor pendente';

  String get rotuloServico =>
      (nomeServico != null && nomeServico!.trim().isNotEmpty)
          ? nomeServico!.trim()
          : 'Serviço pendente';

  String get rotuloEstadoCombinado {
    final exec = estadoExecucao == EstadoExecucaoContrato.naoIniciado
        ? 'execução ainda não confirmada'
        : estadoExecucao.rotulo.toLowerCase();
    return '$estadoComercial; $exec';
  }

  factory LinhaContratacaoAdmin.fromMap(Map<String, dynamic> map) {
    final snapRaw = map['snapshot_aceite'] ?? map['snapshotAceite'];
    return LinhaContratacaoAdmin(
      idContrato:
          (map['id_contrato'] ?? map['idContrato'] ?? map['id_orcamento'] ?? '')
              .toString(),
      idOrcamento:
          (map['id_orcamento'] ?? map['idOrcamento'] ?? '').toString(),
      idEvento: (map['id_evento'] ?? map['idEvento'] ?? '').toString(),
      nomeEvento: (map['nome_evento'] ?? map['nomeEvento'])?.toString(),
      nomeOrganizador:
          (map['nome_organizador'] ?? map['nomeOrganizador'])?.toString(),
      nomeContratante:
          (map['nome_contratante'] ?? map['nomeContratante'])?.toString(),
      nomePagador: (map['nome_pagador'] ?? map['nomePagador'])?.toString(),
      nomeFornecedor:
          (map['nome_fornecedor'] ?? map['nomeFornecedor'])?.toString(),
      nomeServico: (map['nome_servico'] ?? map['nomeServico'])?.toString(),
      contratado: map['contratado'] == true,
      estadoComercial:
          (map['estado_comercial'] ?? map['estadoComercial'] ?? '—').toString(),
      estadoExecucao: EstadoExecucaoContrato.fromString(
        (map['estado_execucao'] ?? map['estadoExecucao'])?.toString(),
      ),
      valorContratadoCentavos:
          (map['valor_contratado_centavos'] as num?)?.toInt() ??
              (map['valorContratadoCentavos'] as num?)?.toInt() ??
              0,
      pagoCentavos: (map['pago_centavos'] as num?)?.toInt() ??
          (map['pagoCentavos'] as num?)?.toInt() ??
          0,
      pendenciasIdentificacao: ((map['pendencias_identificacao'] ??
                  map['pendenciasIdentificacao']) as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      identidadeIncompleta: map['identidade_incompleta'] == true ||
          map['identidadeIncompleta'] == true,
      perfilAtualSeparado: map['perfil_atual_separado'] == true ||
          map['perfilAtualSeparado'] == true,
      nomeFornecedorAtual:
          (map['nome_fornecedor_atual'] ?? map['nomeFornecedorAtual'])
              ?.toString(),
      snapshotAceite: snapRaw is Map
          ? SnapshotIdentidadeComercial.fromMap(
              Map<String, dynamic>.from(snapRaw))
          : null,
    );
  }
}
