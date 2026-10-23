/// Mediação operacional por contratação (Prompt 03).
library;

enum EstadoCasoMediacao {
  aberto,
  emAnalise,
  aguardandoPartes,
  emDecisao,
  fechado,
  canceladoCaso;

  String get firestoreValue {
    switch (this) {
      case EstadoCasoMediacao.aberto:
        return 'aberto';
      case EstadoCasoMediacao.emAnalise:
        return 'em_analise';
      case EstadoCasoMediacao.aguardandoPartes:
        return 'aguardando_partes';
      case EstadoCasoMediacao.emDecisao:
        return 'em_decisao';
      case EstadoCasoMediacao.fechado:
        return 'fechado';
      case EstadoCasoMediacao.canceladoCaso:
        return 'cancelado_caso';
    }
  }

  String get rotulo {
    switch (this) {
      case EstadoCasoMediacao.aberto:
        return 'Aberto';
      case EstadoCasoMediacao.emAnalise:
        return 'Em análise';
      case EstadoCasoMediacao.aguardandoPartes:
        return 'Aguardando partes';
      case EstadoCasoMediacao.emDecisao:
        return 'Em decisão';
      case EstadoCasoMediacao.fechado:
        return 'Fechado';
      case EstadoCasoMediacao.canceladoCaso:
        return 'Caso cancelado';
    }
  }

  static EstadoCasoMediacao fromString(String? v) {
    switch ((v ?? '').toLowerCase()) {
      case 'em_analise':
        return EstadoCasoMediacao.emAnalise;
      case 'aguardando_partes':
        return EstadoCasoMediacao.aguardandoPartes;
      case 'em_decisao':
        return EstadoCasoMediacao.emDecisao;
      case 'fechado':
        return EstadoCasoMediacao.fechado;
      case 'cancelado_caso':
        return EstadoCasoMediacao.canceladoCaso;
      default:
        return EstadoCasoMediacao.aberto;
    }
  }
}

enum VisibilidadeRegistroMediacao { interna, compartilhavel }

enum CapacidadeMediacao {
  consultaComercial,
  notasInternas,
  decisaoMediacao,
  autorizacaoFinanceira;

  static CapacidadeMediacao? fromString(String v) {
    switch (v) {
      case 'consulta_comercial':
        return CapacidadeMediacao.consultaComercial;
      case 'notas_internas':
        return CapacidadeMediacao.notasInternas;
      case 'decisao_mediacao':
        return CapacidadeMediacao.decisaoMediacao;
      case 'autorizacao_financeira':
        return CapacidadeMediacao.autorizacaoFinanceira;
      default:
        return null;
    }
  }
}

class DimensoesFinanceirasContrato {
  const DimensoesFinanceirasContrato({
    required this.valorContratadoCentavos,
    required this.recebidoClienteAlocadoCentavos,
    required this.aReceberClienteCentavos,
    required this.repassadoConfirmadoCentavos,
    required this.pendenteRepasseCentavos,
    this.remuneracaoAppPrevistaCentavos = 0,
  });

  final int valorContratadoCentavos;
  final int recebidoClienteAlocadoCentavos;
  final int aReceberClienteCentavos;
  final int repassadoConfirmadoCentavos;
  final int pendenteRepasseCentavos;
  final int remuneracaoAppPrevistaCentavos;
}

class LinhaCentralContratacao {
  const LinhaCentralContratacao({
    required this.idContrato,
    required this.idOrcamento,
    required this.idEvento,
    required this.valorContratadoCentavos,
    required this.recebidoClienteCentavos,
    required this.repassadoCentavos,
    required this.aReceberClienteCentavos,
    required this.pendenteRepasseCentavos,
    required this.estadoComercial,
    required this.estadoExecucao,
    required this.casoAberto,
    required this.pendencias,
    required this.identidadeIncompleta,
    this.nomeEvento,
    this.dataEvento,
    this.nomeContratante,
    this.nomeFornecedor,
    this.nomeServico,
    this.escopoCurto,
    this.idCasoAberto,
    this.nomeOrganizador,
    this.nomePagador,
  });

  final String idContrato;
  final String idOrcamento;
  final String idEvento;
  final String? nomeEvento;
  final String? dataEvento;
  final String? nomeContratante;
  final String? nomeFornecedor;
  final String? nomeServico;
  final String? escopoCurto;
  final String? nomeOrganizador;
  final String? nomePagador;
  final int valorContratadoCentavos;
  final int recebidoClienteCentavos;
  final int repassadoCentavos;
  final int aReceberClienteCentavos;
  final int pendenteRepasseCentavos;
  final String estadoComercial;
  final String estadoExecucao;
  final bool casoAberto;
  final String? idCasoAberto;
  final List<String> pendencias;
  final bool identidadeIncompleta;

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
          : (escopoCurto != null && escopoCurto!.trim().isNotEmpty)
              ? escopoCurto!.trim()
              : 'Serviço pendente';

  factory LinhaCentralContratacao.fromMap(Map<String, dynamic> m) {
    int cent(dynamic v) => (v is num) ? v.toInt() : 0;
    final pend = m['pendencias'];
    return LinhaCentralContratacao(
      idContrato: (m['idContrato'] ?? m['id_contrato'] ?? '').toString(),
      idOrcamento: (m['idOrcamento'] ?? m['id_orcamento'] ?? '').toString(),
      idEvento: (m['idEvento'] ?? m['id_evento'] ?? '').toString(),
      nomeEvento: (m['nomeEvento'] ?? m['nome_evento'])?.toString(),
      dataEvento: (m['dataEvento'] ?? m['data_evento'])?.toString(),
      nomeContratante:
          (m['nomeContratante'] ?? m['nome_contratante'])?.toString(),
      nomeFornecedor:
          (m['nomeFornecedor'] ?? m['nome_fornecedor'])?.toString(),
      nomeServico: (m['nomeServico'] ?? m['nome_servico'])?.toString(),
      escopoCurto: (m['escopoCurto'] ?? m['escopo_curto'])?.toString(),
      nomeOrganizador:
          (m['nomeOrganizador'] ?? m['nome_organizador'])?.toString(),
      nomePagador: (m['nomePagador'] ?? m['nome_pagador'])?.toString(),
      valorContratadoCentavos: cent(
          m['valorContratadoCentavos'] ?? m['valor_contratado_centavos']),
      recebidoClienteCentavos: cent(
          m['recebidoClienteCentavos'] ?? m['recebido_cliente_centavos']),
      repassadoCentavos:
          cent(m['repassadoCentavos'] ?? m['repassado_centavos']),
      aReceberClienteCentavos: cent(
          m['aReceberClienteCentavos'] ?? m['a_receber_cliente_centavos']),
      pendenteRepasseCentavos: cent(
          m['pendenteRepasseCentavos'] ?? m['pendente_repasse_centavos']),
      estadoComercial:
          (m['estadoComercial'] ?? m['estado_comercial'] ?? '').toString(),
      estadoExecucao:
          (m['estadoExecucao'] ?? m['estado_execucao'] ?? '').toString(),
      casoAberto: m['casoAberto'] == true || m['caso_aberto'] == true,
      idCasoAberto: (m['idCasoAberto'] ?? m['id_caso_aberto'])?.toString(),
      pendencias: pend is List
          ? pend.map((e) => e.toString()).toList()
          : const <String>[],
      identidadeIncompleta: m['identidadeIncompleta'] == true ||
          m['identidade_incompleta'] == true,
    );
  }
}

class RegistroMediacaoView {
  const RegistroMediacaoView({
    required this.id,
    required this.tipo,
    required this.visibilidade,
    required this.texto,
    required this.autorId,
    required this.criadoEm,
    required this.efeitoFinanceiroExecutado,
  });

  final String id;
  final String tipo;
  final VisibilidadeRegistroMediacao visibilidade;
  final String texto;
  final String autorId;
  final String criadoEm;
  final bool efeitoFinanceiroExecutado;

  factory RegistroMediacaoView.fromMap(Map<String, dynamic> m) {
    final vis = (m['visibilidade'] ?? '').toString() == 'compartilhavel'
        ? VisibilidadeRegistroMediacao.compartilhavel
        : VisibilidadeRegistroMediacao.interna;
    return RegistroMediacaoView(
      id: (m['id'] ?? '').toString(),
      tipo: (m['tipo'] ?? '').toString(),
      visibilidade: vis,
      texto: (m['texto'] ?? '').toString(),
      autorId: (m['autorId'] ?? m['autor_id'] ?? '').toString(),
      criadoEm: (m['criadoEm'] ?? m['criado_em'] ?? '').toString(),
      efeitoFinanceiroExecutado:
          m['efeitoFinanceiroExecutado'] == true ||
              m['efeito_financeiro_executado'] == true,
    );
  }
}
