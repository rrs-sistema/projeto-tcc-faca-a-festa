import 'package:app_faca_festa/domain/entities/financeiro/valor_monetario.dart';

/// Pagador da comissão — escolha comercial explícita (ainda pendente de aprovação).
enum PagadorComissao {
  fornecedor,
  organizador,
  plataformaAbsorve;

  String get valor {
    switch (this) {
      case PagadorComissao.fornecedor:
        return 'fornecedor';
      case PagadorComissao.organizador:
        return 'organizador';
      case PagadorComissao.plataformaAbsorve:
        return 'plataforma_absorve';
    }
  }

  static PagadorComissao fromString(String? v) {
    switch (v) {
      case 'organizador':
        return PagadorComissao.organizador;
      case 'plataforma_absorve':
        return PagadorComissao.plataformaAbsorve;
      default:
        return PagadorComissao.fornecedor;
    }
  }
}

enum BaseElegivelComissao {
  /// Serviços efetivamente contratados pela plataforma (preferencial).
  servicosContratadosPlataforma,

  /// Exige autorização comercial explícita — não usar por padrão.
  limiteGlobalCliente;

  String get valor {
    switch (this) {
      case BaseElegivelComissao.servicosContratadosPlataforma:
        return 'servicos_contratados_plataforma';
      case BaseElegivelComissao.limiteGlobalCliente:
        return 'limite_global_cliente';
    }
  }

  static BaseElegivelComissao fromString(String? v) {
    if (v == 'limite_global_cliente') {
      return BaseElegivelComissao.limiteGlobalCliente;
    }
    return BaseElegivelComissao.servicosContratadosPlataforma;
  }
}

enum GatilhoGeracaoComissao {
  contratacaoConfirmada,
  eventoRealizado,
  manual;

  String get valor {
    switch (this) {
      case GatilhoGeracaoComissao.contratacaoConfirmada:
        return 'contratacao_confirmada';
      case GatilhoGeracaoComissao.eventoRealizado:
        return 'evento_realizado';
      case GatilhoGeracaoComissao.manual:
        return 'manual';
    }
  }

  static GatilhoGeracaoComissao fromString(String? v) {
    switch (v) {
      case 'evento_realizado':
        return GatilhoGeracaoComissao.eventoRealizado;
      case 'manual':
        return GatilhoGeracaoComissao.manual;
      default:
        return GatilhoGeracaoComissao.contratacaoConfirmada;
    }
  }
}

enum ReversaoComissao {
  proporcional,
  nenhuma,
  manual;

  String get valor {
    switch (this) {
      case ReversaoComissao.proporcional:
        return 'proporcional';
      case ReversaoComissao.nenhuma:
        return 'nenhuma';
      case ReversaoComissao.manual:
        return 'manual';
    }
  }

  static ReversaoComissao fromString(String? v) {
    switch (v) {
      case 'nenhuma':
        return ReversaoComissao.nenhuma;
      case 'manual':
        return ReversaoComissao.manual;
      default:
        return ReversaoComissao.proporcional;
    }
  }
}

/// Estados operacionais — sem inferir reconhecimento contábil formal.
enum StatusObrigacaoComissao {
  previsao,
  gerada,
  aVencer,
  vencida,
  recebida,
  estornada;

  String get valor {
    switch (this) {
      case StatusObrigacaoComissao.previsao:
        return 'previsao';
      case StatusObrigacaoComissao.gerada:
        return 'gerada';
      case StatusObrigacaoComissao.aVencer:
        return 'a_vencer';
      case StatusObrigacaoComissao.vencida:
        return 'vencida';
      case StatusObrigacaoComissao.recebida:
        return 'recebida';
      case StatusObrigacaoComissao.estornada:
        return 'estornada';
    }
  }

  static StatusObrigacaoComissao fromString(String? v) {
    switch (v) {
      case 'previsao':
        return StatusObrigacaoComissao.previsao;
      case 'a_vencer':
        return StatusObrigacaoComissao.aVencer;
      case 'vencida':
        return StatusObrigacaoComissao.vencida;
      case 'recebida':
        return StatusObrigacaoComissao.recebida;
      case 'estornada':
        return StatusObrigacaoComissao.estornada;
      default:
        return StatusObrigacaoComissao.gerada;
    }
  }
}

/// Política de comissão da plataforma.
/// Novas políticas ficam inativas por padrão.
/// Percentual em basis points: 500 = 5,00%. Zero (0) é válido e ≠ ausente.
class PoliticaComissaoPlataforma {
  const PoliticaComissaoPlataforma({
    required this.id,
    required this.versao,
    required this.percentualBps,
    required this.baseElegivel,
    required this.pagador,
    required this.gatilho,
    required this.reversao,
    required this.ativa,
    this.vigenciaInicio,
    this.vigenciaFim,
    this.diasVencimentoAposGeracao = 30,
    this.completa = true,
    this.autorId,
    this.observacoesComerciais,
  });

  final String id;
  final int versao;

  /// Basis points 0–10000 (0%–100%). Null no mapa = configuração ausente.
  final int percentualBps;
  final BaseElegivelComissao baseElegivel;
  final PagadorComissao pagador;
  final GatilhoGeracaoComissao gatilho;
  final ReversaoComissao reversao;
  final bool ativa;
  final DateTime? vigenciaInicio;
  final DateTime? vigenciaFim;
  final int diasVencimentoAposGeracao;
  final bool completa;
  final String? autorId;
  final String? observacoesComerciais;

  bool get percentualZeroValido => percentualBps == 0;

  Map<String, dynamic> toMap() => {
        'schema': 1,
        'id_politica': id,
        'versao': versao,
        'percentual_bps': percentualBps,
        'base_elegivel': baseElegivel.valor,
        'pagador': pagador.valor,
        'gatilho_geracao': gatilho.valor,
        'reversao': reversao.valor,
        'ativa': ativa,
        'vigencia_inicio': vigenciaInicio?.toIso8601String(),
        'vigencia_fim': vigenciaFim?.toIso8601String(),
        'dias_vencimento_apos_geracao': diasVencimentoAposGeracao,
        'completa': completa,
        'autor_id': autorId,
        'observacoes_comerciais': observacoesComerciais,
        'perspectiva': 'plataforma',
      };

  /// Snapshot imutável aplicado à obrigação (mudança global não recalcula).
  Map<String, dynamic> snapshotImutavel() => {
        'id_politica': id,
        'versao': versao,
        'percentual_bps': percentualBps,
        'base_elegivel': baseElegivel.valor,
        'pagador': pagador.valor,
        'gatilho_geracao': gatilho.valor,
        'reversao': reversao.valor,
        'dias_vencimento_apos_geracao': diasVencimentoAposGeracao,
      };

  factory PoliticaComissaoPlataforma.fromMap(Map<String, dynamic> map) {
    return PoliticaComissaoPlataforma(
      id: map['id_politica']?.toString() ?? map['id']?.toString() ?? '',
      versao: (map['versao'] as num?)?.toInt() ?? 1,
      percentualBps: (map['percentual_bps'] as num?)?.toInt() ?? 0,
      baseElegivel:
          BaseElegivelComissao.fromString(map['base_elegivel']?.toString()),
      pagador: PagadorComissao.fromString(map['pagador']?.toString()),
      gatilho:
          GatilhoGeracaoComissao.fromString(map['gatilho_geracao']?.toString()),
      reversao: ReversaoComissao.fromString(map['reversao']?.toString()),
      ativa: map['ativa'] == true,
      vigenciaInicio: _parseDate(map['vigencia_inicio']),
      vigenciaFim: _parseDate(map['vigencia_fim']),
      diasVencimentoAposGeracao:
          (map['dias_vencimento_apos_geracao'] as num?)?.toInt() ?? 30,
      completa: map['completa'] != false,
      autorId: map['autor_id']?.toString(),
      observacoesComerciais: map['observacoes_comerciais']?.toString(),
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }
}

class ObrigacaoComissaoPlataforma {
  const ObrigacaoComissaoPlataforma({
    required this.id,
    required this.idEvento,
    required this.idContrato,
    required this.baseElegivelCentavos,
    required this.valorOriginalCentavos,
    required this.valorAjustesCentavos,
    required this.valorLiquidadoCentavos,
    required this.status,
    required this.politicaAplicada,
    this.idPagador,
    this.idFornecedor,
  });

  final String id;
  final String idEvento;
  final String idContrato;
  final int baseElegivelCentavos;
  final int valorOriginalCentavos;

  /// Ajustes negativos (crédito/reembolso) ou positivos (aditivo).
  final int valorAjustesCentavos;
  final int valorLiquidadoCentavos;
  final StatusObrigacaoComissao status;
  final Map<String, dynamic> politicaAplicada;
  final String? idPagador;
  final String? idFornecedor;

  /// Saldo sem clamp — pode ser crédito se liquidação/excesso.
  int get saldoCentavos =>
      valorOriginalCentavos + valorAjustesCentavos - valorLiquidadoCentavos;

  Map<String, dynamic> toMap() => {
        'schema': 1,
        'id_obrigacao': id,
        'id_evento': idEvento,
        'id_contrato': idContrato,
        'id_pagador': idPagador,
        'id_fornecedor': idFornecedor,
        'base_elegivel': ValorMonetario.centavos(
          baseElegivelCentavos.clamp(0, ValorMonetario.limiteCentavos),
        ).toMap(),
        'valor_original': ValorMonetario.centavos(
          valorOriginalCentavos.clamp(0, ValorMonetario.limiteCentavos),
        ).toMap(),
        'valor_ajustes_centavos': valorAjustesCentavos,
        'valor_liquidado': ValorMonetario.centavos(
          valorLiquidadoCentavos.clamp(0, ValorMonetario.limiteCentavos),
        ).toMap(),
        'saldo_centavos': saldoCentavos,
        'status': status.valor,
        'politica_aplicada': politicaAplicada,
        'perspectiva': 'plataforma_comissao',
      };
}
