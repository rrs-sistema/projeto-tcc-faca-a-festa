import 'analise_calculadora_ia_model.dart';
import 'calculadora_festa_model.dart';

class SimulacaoCalculadoraFestaModel {
  final String id;
  final String? idEvento;
  final String? idUsuario;
  final String? nomeEvento;
  final String tipoEvento;
  final String perfilFesta;
  final String baseCalculo;
  final int adultos;
  final int criancas;
  final int bebes;
  final double convidadosEquivalentes;
  final double custoEstimado;
  final double? orcamentoDisponivel;
  final int duracaoHoras;
  final StatusSimulacaoCalculadora statusSimulacao;
  final bool convertidoEmOrcamento;
  final DateTime? dataConversaoOrcamento;
  final DateTime dataCriacao;
  final DateTime dataAtualizacao;
  final AnaliseCalculadoraIAModel? analiseIA;

  const SimulacaoCalculadoraFestaModel({
    required this.id,
    this.idEvento,
    this.idUsuario,
    this.nomeEvento,
    required this.tipoEvento,
    required this.perfilFesta,
    this.baseCalculo = 'todosConvidados',
    required this.adultos,
    required this.criancas,
    required this.bebes,
    required this.convidadosEquivalentes,
    required this.custoEstimado,
    this.orcamentoDisponivel,
    this.duracaoHoras = 4,
    this.statusSimulacao = StatusSimulacaoCalculadora.rascunho,
    this.convertidoEmOrcamento = false,
    this.dataConversaoOrcamento,
    required this.dataCriacao,
    DateTime? dataAtualizacao,
    this.analiseIA,
  }) : dataAtualizacao = dataAtualizacao ?? dataCriacao;

  factory SimulacaoCalculadoraFestaModel.fromCalculo(
    CalculadoraFestaModel calculo,
  ) {
    return SimulacaoCalculadoraFestaModel(
      id: calculo.idCalculo,
      idEvento: calculo.idEvento,
      idUsuario: calculo.idUsuario,
      nomeEvento: calculo.nomeEvento,
      tipoEvento: calculo.tipoEvento,
      perfilFesta: calculo.perfilFesta.nome,
      baseCalculo: calculo.baseCalculo.name,
      adultos: calculo.totalAdultos,
      criancas: calculo.totalCriancas,
      bebes: calculo.totalBebes,
      convidadosEquivalentes: calculo.convidadosEquivalentes.totalEquivalente,
      custoEstimado: calculo.custoTotalEstimado,
      orcamentoDisponivel: calculo.orcamentoDisponivel,
      duracaoHoras: calculo.duracaoHoras,
      statusSimulacao: calculo.statusSimulacao,
      convertidoEmOrcamento: calculo.convertidaEmOrcamento,
      dataConversaoOrcamento: calculo.dataConversaoOrcamento,
      dataCriacao: calculo.dataCalculo,
      dataAtualizacao: calculo.dataAtualizacao,
      analiseIA: calculo.analiseIA,
    );
  }

  int get totalConvidados => adultos + criancas + bebes;

  bool get possuiAnaliseIA => analiseIA != null;

  double get diferencaOrcamento {
    final orcamento = orcamentoDisponivel;
    if (orcamento == null || orcamento <= 0) return 0;
    return custoEstimado - orcamento;
  }

  bool get acimaDoOrcamento => diferencaOrcamento > 0;

  bool get convertidaEmOrcamento {
    return convertidoEmOrcamento ||
        statusSimulacao == StatusSimulacaoCalculadora.convertidaOrcamento;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_calculo': id,
      'id_evento': idEvento,
      'id_usuario': idUsuario,
      'nome_evento': nomeEvento,
      'tipo_evento': tipoEvento,
      'perfil_festa': perfilFesta,
      'base_calculo': baseCalculo,
      'adultos': adultos,
      'criancas': criancas,
      'bebes': bebes,
      'total_convidados': totalConvidados,
      'convidados_equivalentes': convidadosEquivalentes,
      'custo_estimado': custoEstimado,
      'custo_total_estimado': custoEstimado,
      'orcamento_disponivel': orcamentoDisponivel,
      'diferenca_orcamento': diferencaOrcamento,
      'duracao_horas': duracaoHoras,
      'status_simulacao': statusSimulacao.value,
      'status_simulacao_label': statusSimulacao.label,
      'convertido_em_orcamento': convertidaEmOrcamento,
      'data_conversao_orcamento': dataConversaoOrcamento?.toIso8601String(),
      'data_criacao': dataCriacao.toIso8601String(),
      'data_atualizacao': dataAtualizacao.toIso8601String(),
      if (analiseIA != null) 'analise_ia': analiseIA!.toMap(),
    };
  }

  factory SimulacaoCalculadoraFestaModel.fromMap(Map<String, dynamic> map) {
    final analiseMap = _asMap(
      map['analise_ia'] ??
          map['analise_ia_generativa'] ??
          map['analiseIA'] ??
          map['analysis'],
    );

    final status = StatusSimulacaoCalculadoraExtension.fromString(
      map['status_simulacao']?.toString(),
    );

    final convertido = _asBool(map['convertido_em_orcamento']) ||
        status == StatusSimulacaoCalculadora.convertidaOrcamento;

    return SimulacaoCalculadoraFestaModel(
      id: map['id']?.toString() ?? map['id_calculo']?.toString() ?? '',
      idEvento: _nullableString(map['id_evento']),
      idUsuario: _nullableString(map['id_usuario']),
      nomeEvento: _nullableString(map['nome_evento']),
      tipoEvento: map['tipo_evento']?.toString() ?? 'Evento',
      perfilFesta: _resolverPerfilFesta(map['perfil_festa']),
      baseCalculo: map['base_calculo']?.toString() ?? 'todosConvidados',
      adultos: _asInt(map['adultos'] ?? map['total_adultos']),
      criancas: _asInt(map['criancas'] ?? map['total_criancas']),
      bebes: _asInt(map['bebes'] ?? map['total_bebes']),
      convidadosEquivalentes: _asDouble(
        map['convidados_equivalentes'] ?? map['total_equivalente'],
      ),
      custoEstimado: _asDouble(
        map['custo_estimado'] ?? map['custo_total_estimado'],
      ),
      orcamentoDisponivel: _asNullableDouble(map['orcamento_disponivel']),
      duracaoHoras: _asInt(map['duracao_horas'], fallback: 4),
      statusSimulacao: status,
      convertidoEmOrcamento: convertido,
      dataConversaoOrcamento: _asDate(map['data_conversao_orcamento']),
      dataCriacao:
          _asDate(map['data_criacao'] ?? map['data_calculo']) ?? DateTime.now(),
      dataAtualizacao: _asDate(map['data_atualizacao']),
      analiseIA: analiseMap != null
          ? AnaliseCalculadoraIAModel.fromMap(analiseMap)
          : null,
    );
  }

  static String _resolverPerfilFesta(dynamic value) {
    if (value is Map) {
      return value['nome']?.toString() ?? value['tipo']?.toString() ?? 'Padrão';
    }

    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') return 'Padrão';
    return text;
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

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
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
