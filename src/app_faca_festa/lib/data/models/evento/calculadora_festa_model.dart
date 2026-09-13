import 'analise_calculadora_ia_model.dart';
import 'convidados_equivalentes_model.dart';
import 'perfil_festa_model.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa.dart';
import 'package:app_faca_festa/domain/entities/analise_calculadora_ia.dart';
import 'package:app_faca_festa/domain/entities/perfil_festa.dart';


extension BaseCalculoFestaModelExtension on BaseCalculoFesta {
  static BaseCalculoFesta fromString(String? value) {
    final normalized = value?.trim().toLowerCase() ?? '';

    return BaseCalculoFesta.values.firstWhere(
      (item) => item.name.toLowerCase() == normalized,
      orElse: () => BaseCalculoFesta.todosConvidados,
    );
  }
}

extension StatusSimulacaoCalculadoraModelExtension
    on StatusSimulacaoCalculadora {
  static StatusSimulacaoCalculadora fromString(String? value) {
    final normalized = value?.trim().toLowerCase() ?? '';

    if (normalized == 'convertida_orcamento' ||
        normalized == 'convertidaemorcamento' ||
        normalized == 'convertida em orçamento' ||
        normalized == 'convertida em orcamento') {
      return StatusSimulacaoCalculadora.convertidaOrcamento;
    }

    return StatusSimulacaoCalculadora.values.firstWhere(
      (item) =>
          item.name.toLowerCase() == normalized || item.value == normalized,
      orElse: () => StatusSimulacaoCalculadora.rascunho,
    );
  }
}

class CalculadoraFestaModel extends CalculadoraFesta {
  const CalculadoraFestaModel({
    required super.idCalculo,
    required super.idEvento,
    required super.tipoEvento,
    required super.baseCalculo,
    required super.totalAdultos,
    required super.totalCriancas,
    required super.totalBebes,
    required super.duracaoHoras,
    required super.dataCalculo,
    required super.dataAtualizacao,
    super.perfilFesta = const PerfilFestaModel(
      tipo: TipoPerfilFesta.padrao,
      nome: 'Padrão',
      descricao: 'Estimativa equilibrada para a maioria dos eventos.',
      multiplicadorQuantidade: 1.00,
      multiplicadorCusto: 1.00,
      margemSegurancaPadrao: 0.10,
    ),
    super.margemPersonalizada,
    super.custoTotalEstimado = 0,
    super.idUsuario,
    super.nomeEvento,
    super.orcamentoDisponivel,
    super.statusSimulacao = StatusSimulacaoCalculadora.rascunho,
    super.convertidoEmOrcamento = false,
    super.dataConversaoOrcamento,
    super.analiseIA,
  });

  factory CalculadoraFestaModel.fromEntity(CalculadoraFesta entity) {
    if (entity is CalculadoraFestaModel) return entity;

    return CalculadoraFestaModel(
      idCalculo: entity.idCalculo,
      idEvento: entity.idEvento,
      tipoEvento: entity.tipoEvento,
      baseCalculo: entity.baseCalculo,
      totalAdultos: entity.totalAdultos,
      totalCriancas: entity.totalCriancas,
      totalBebes: entity.totalBebes,
      duracaoHoras: entity.duracaoHoras,
      dataCalculo: entity.dataCalculo,
      dataAtualizacao: entity.dataAtualizacao,
      perfilFesta: PerfilFestaModel.fromEntity(entity.perfilFesta),
      margemPersonalizada: entity.margemPersonalizada,
      custoTotalEstimado: entity.custoTotalEstimado,
      idUsuario: entity.idUsuario,
      nomeEvento: entity.nomeEvento,
      orcamentoDisponivel: entity.orcamentoDisponivel,
      statusSimulacao: entity.statusSimulacao,
      convertidoEmOrcamento: entity.convertidoEmOrcamento,
      dataConversaoOrcamento: entity.dataConversaoOrcamento,
      analiseIA: entity.analiseIA == null
          ? null
          : AnaliseCalculadoraIAModel.fromEntity(entity.analiseIA!),
    );
  }

  @override
  CalculadoraFestaModel copyWith({
    String? idCalculo,
    String? idEvento,
    String? tipoEvento,
    BaseCalculoFesta? baseCalculo,
    int? totalAdultos,
    int? totalCriancas,
    int? totalBebes,
    int? duracaoHoras,
    DateTime? dataCalculo,
    DateTime? dataAtualizacao,
    PerfilFesta? perfilFesta,
    double? margemPersonalizada,
    bool limparMargemPersonalizada = false,
    double? custoTotalEstimado,
    String? idUsuario,
    bool limparIdUsuario = false,
    String? nomeEvento,
    bool limparNomeEvento = false,
    double? orcamentoDisponivel,
    bool limparOrcamentoDisponivel = false,
    StatusSimulacaoCalculadora? statusSimulacao,
    bool? convertidoEmOrcamento,
    DateTime? dataConversaoOrcamento,
    bool limparDataConversaoOrcamento = false,
    AnaliseCalculadoraIA? analiseIA,
    bool limparAnaliseIA = false,
  }) {
    return CalculadoraFestaModel(
      idCalculo: idCalculo ?? this.idCalculo,
      idEvento: idEvento ?? this.idEvento,
      tipoEvento: tipoEvento ?? this.tipoEvento,
      baseCalculo: baseCalculo ?? this.baseCalculo,
      totalAdultos: totalAdultos ?? this.totalAdultos,
      totalCriancas: totalCriancas ?? this.totalCriancas,
      totalBebes: totalBebes ?? this.totalBebes,
      duracaoHoras: duracaoHoras ?? this.duracaoHoras,
      dataCalculo: dataCalculo ?? this.dataCalculo,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
      perfilFesta: perfilFesta == null
          ? PerfilFestaModel.fromEntity(this.perfilFesta)
          : PerfilFestaModel.fromEntity(perfilFesta),
      margemPersonalizada: limparMargemPersonalizada
          ? null
          : (margemPersonalizada ?? this.margemPersonalizada),
      custoTotalEstimado: custoTotalEstimado ?? this.custoTotalEstimado,
      idUsuario: limparIdUsuario ? null : (idUsuario ?? this.idUsuario),
      nomeEvento: limparNomeEvento ? null : (nomeEvento ?? this.nomeEvento),
      orcamentoDisponivel: limparOrcamentoDisponivel
          ? null
          : (orcamentoDisponivel ?? this.orcamentoDisponivel),
      statusSimulacao: statusSimulacao ?? this.statusSimulacao,
      convertidoEmOrcamento:
          convertidoEmOrcamento ?? this.convertidoEmOrcamento,
      dataConversaoOrcamento: limparDataConversaoOrcamento
          ? null
          : (dataConversaoOrcamento ?? this.dataConversaoOrcamento),
      analiseIA: limparAnaliseIA
          ? null
          : (analiseIA == null
              ? (this.analiseIA == null
                  ? null
                  : AnaliseCalculadoraIAModel.fromEntity(this.analiseIA!))
              : AnaliseCalculadoraIAModel.fromEntity(analiseIA)),
    );
  }

  Map<String, dynamic> toMap() {
    final convidadosEquivalentesModel =
        ConvidadosEquivalentesModel.fromEntity(convidadosEquivalentes);
    final perfilFestaModel = PerfilFestaModel.fromEntity(perfilFesta);
    final analiseIAModel = analiseIA == null
        ? null
        : AnaliseCalculadoraIAModel.fromEntity(analiseIA!);

    return {
      'id_calculo': idCalculo,
      'id_evento': idEvento,
      'tipo_evento': tipoEvento,
      'base_calculo': baseCalculo.name,
      'base_calculo_label': baseCalculo.label,
      'total_adultos': totalAdultos,
      'total_criancas': totalCriancas,
      'total_bebes': totalBebes,
      'total_convidados': totalConvidados,
      'convidados_equivalentes': convidadosEquivalentesModel.toMap(),
      'total_equivalente': convidadosEquivalentesModel.totalEquivalente,
      'total_equivalente_arredondado':
          convidadosEquivalentesModel.totalEquivalenteArredondado,
      'duracao_horas': duracaoHoras,
      'perfil_festa': perfilFestaModel.toMap(),
      'margem_personalizada': margemPersonalizada,
      'custo_total_estimado': custoTotalEstimado,
      'orcamento_disponivel': orcamentoDisponivel,
      'id_usuario': idUsuario,
      'nome_evento': nomeEvento,
      'status_simulacao': statusSimulacao.value,
      'status_simulacao_label': statusSimulacao.label,
      'convertido_em_orcamento': convertidaEmOrcamento,
      'data_conversao_orcamento': dataConversaoOrcamento?.toIso8601String(),
      'data_calculo': dataCalculo.toIso8601String(),
      'data_atualizacao': dataAtualizacao.toIso8601String(),
      if (analiseIAModel != null) 'analise_ia': analiseIAModel.toMap(),
      if (analiseIAModel != null) 'fonte_analise_ia': analiseIAModel.fonte,
      if (analiseIAModel != null)
        'data_analise_ia': analiseIAModel.dataAnalise.toIso8601String(),
    };
  }

  factory CalculadoraFestaModel.fromMap(Map<String, dynamic> map) {
    final perfilMap = _asMap(map['perfil_festa']);

    final analiseMap = _asMap(
      map['analise_ia'] ??
          map['analise_ia_generativa'] ??
          map['analiseIA'] ??
          map['analysis'],
    );

    final adultos = _asInt(map['total_adultos'] ?? map['adultos']);
    final criancas = _asInt(map['total_criancas'] ?? map['criancas']);
    final bebes = _asInt(map['total_bebes'] ?? map['bebes']);
    final totalPorTipo = adultos + criancas + bebes;
    final totalLegado =
        _asInt(map['total_convidados'] ?? map['total_informado']);

    // Compatibilidade com cálculos/eventos antigos que só tinham total_convidados.
    final adultosNormalizados =
        totalPorTipo == 0 && totalLegado > 0 ? totalLegado : adultos;

    final status = StatusSimulacaoCalculadoraModelExtension.fromString(
      map['status_simulacao']?.toString(),
    );

    final convertido = _asBool(map['convertido_em_orcamento']) ||
        status == StatusSimulacaoCalculadora.convertidaOrcamento;

    return CalculadoraFestaModel(
      idCalculo: map['id_calculo']?.toString() ?? map['id']?.toString() ?? '',
      idEvento: map['id_evento']?.toString() ?? '',
      tipoEvento: map['tipo_evento']?.toString() ?? 'Evento',
      baseCalculo: BaseCalculoFestaModelExtension.fromString(
        map['base_calculo']?.toString(),
      ),
      totalAdultos: adultosNormalizados,
      totalCriancas: criancas,
      totalBebes: bebes,
      duracaoHoras: _asInt(map['duracao_horas'], fallback: 4),
      dataCalculo:
          _asDate(map['data_calculo'] ?? map['data_criacao']) ?? DateTime.now(),
      dataAtualizacao: _asDate(map['data_atualizacao']) ??
          _asDate(map['data_calculo'] ?? map['data_criacao']) ??
          DateTime.now(),
      perfilFesta: perfilMap != null
          ? PerfilFestaModel.fromMap(perfilMap)
          : PerfilFestaModel.padrao(),
      margemPersonalizada: _asNullableDouble(map['margem_personalizada']),
      custoTotalEstimado:
          _asDouble(map['custo_total_estimado'] ?? map['custo_estimado']),
      idUsuario: _nullableString(map['id_usuario']),
      nomeEvento: _nullableString(map['nome_evento']),
      orcamentoDisponivel: _asNullableDouble(map['orcamento_disponivel']),
      statusSimulacao: status,
      convertidoEmOrcamento: convertido,
      dataConversaoOrcamento: _asDate(map['data_conversao_orcamento']),
      analiseIA: analiseMap != null
          ? AnaliseCalculadoraIAModel.fromMap(analiseMap)
          : null,
    );
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') return null;
    return text;
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static double _asDouble(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ??
        fallback;
  }

  static double? _asNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.'));
  }

  static bool _asBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    final normalized = value?.toString().trim().toLowerCase();

    if (normalized == 'true' || normalized == '1' || normalized == 'sim') {
      return true;
    }
    if (normalized == 'false' ||
        normalized == '0' ||
        normalized == 'nao' ||
        normalized == 'não') {
      return false;
    }

    return fallback;
  }

  static DateTime? _asDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;

    try {
      final dynamic dynamicValue = value;
      final converted = dynamicValue.toDate();
      if (converted is DateTime) return converted;
    } catch (_) {
      // Ignora e tenta parsear como texto.
    }

    return DateTime.tryParse(value.toString());
  }
}
