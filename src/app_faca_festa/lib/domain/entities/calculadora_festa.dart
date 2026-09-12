import 'analise_calculadora_ia.dart';
import 'convidados_equivalentes.dart';
import 'perfil_festa.dart';

enum BaseCalculoFesta {
  todosConvidados,
  apenasConfirmados,
  manual,
}

extension BaseCalculoFestaExtension on BaseCalculoFesta {
  String get label {
    switch (this) {
      case BaseCalculoFesta.todosConvidados:
        return 'Todos';
      case BaseCalculoFesta.apenasConfirmados:
        return 'Confirmados';
      case BaseCalculoFesta.manual:
        return 'Manual';
    }
  }
}

enum StatusSimulacaoCalculadora {
  rascunho,
  aprovada,
  convertidaOrcamento,
  cancelada,
}

extension StatusSimulacaoCalculadoraExtension on StatusSimulacaoCalculadora {
  String get value {
    switch (this) {
      case StatusSimulacaoCalculadora.rascunho:
        return 'rascunho';
      case StatusSimulacaoCalculadora.aprovada:
        return 'aprovada';
      case StatusSimulacaoCalculadora.convertidaOrcamento:
        return 'convertida_orcamento';
      case StatusSimulacaoCalculadora.cancelada:
        return 'cancelada';
    }
  }

  String get label {
    switch (this) {
      case StatusSimulacaoCalculadora.rascunho:
        return 'Rascunho';
      case StatusSimulacaoCalculadora.aprovada:
        return 'Aprovada';
      case StatusSimulacaoCalculadora.convertidaOrcamento:
        return 'Convertida em orçamento';
      case StatusSimulacaoCalculadora.cancelada:
        return 'Cancelada';
    }
  }
}

class CalculadoraFesta {
  final String idCalculo;
  final String idEvento;
  final String tipoEvento;
  final BaseCalculoFesta baseCalculo;
  final int totalAdultos;
  final int totalCriancas;
  final int totalBebes;
  final int duracaoHoras;
  final DateTime dataCalculo;
  final DateTime dataAtualizacao;
  final PerfilFesta perfilFesta;
  final double? margemPersonalizada;
  final double custoTotalEstimado;
  final String? idUsuario;
  final String? nomeEvento;
  final double? orcamentoDisponivel;
  final StatusSimulacaoCalculadora statusSimulacao;
  final bool convertidoEmOrcamento;
  final DateTime? dataConversaoOrcamento;
  final AnaliseCalculadoraIA? analiseIA;

  const CalculadoraFesta({
    required this.idCalculo,
    required this.idEvento,
    required this.tipoEvento,
    required this.baseCalculo,
    required this.totalAdultos,
    required this.totalCriancas,
    required this.totalBebes,
    required this.duracaoHoras,
    required this.dataCalculo,
    required this.dataAtualizacao,
    required this.perfilFesta,
    this.margemPersonalizada,
    this.custoTotalEstimado = 0,
    this.idUsuario,
    this.nomeEvento,
    this.orcamentoDisponivel,
    this.statusSimulacao = StatusSimulacaoCalculadora.rascunho,
    this.convertidoEmOrcamento = false,
    this.dataConversaoOrcamento,
    this.analiseIA,
  });

  int get totalConvidados => totalAdultos + totalCriancas + totalBebes;

  bool get possuiAnaliseIA => analiseIA != null;

  String get fonteAnaliseIALabel => analiseIA?.fonteLabel ?? 'Sem análise';

  bool get aprovada => statusSimulacao == StatusSimulacaoCalculadora.aprovada;

  bool get convertidaEmOrcamento {
    return convertidoEmOrcamento ||
        statusSimulacao == StatusSimulacaoCalculadora.convertidaOrcamento;
  }

  ConvidadosEquivalentes get convidadosEquivalentes {
    return ConvidadosEquivalentes(
      adultos: totalAdultos,
      criancas: totalCriancas,
      bebes: totalBebes,
    );
  }

  CalculadoraFesta copyWith({
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
    return CalculadoraFesta(
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
      perfilFesta: perfilFesta ?? this.perfilFesta,
      margemPersonalizada: limparMargemPersonalizada
          ? null
          : margemPersonalizada ?? this.margemPersonalizada,
      custoTotalEstimado: custoTotalEstimado ?? this.custoTotalEstimado,
      idUsuario: limparIdUsuario ? null : idUsuario ?? this.idUsuario,
      nomeEvento: limparNomeEvento ? null : nomeEvento ?? this.nomeEvento,
      orcamentoDisponivel: limparOrcamentoDisponivel
          ? null
          : orcamentoDisponivel ?? this.orcamentoDisponivel,
      statusSimulacao: statusSimulacao ?? this.statusSimulacao,
      convertidoEmOrcamento:
          convertidoEmOrcamento ?? this.convertidoEmOrcamento,
      dataConversaoOrcamento: limparDataConversaoOrcamento
          ? null
          : dataConversaoOrcamento ?? this.dataConversaoOrcamento,
      analiseIA: limparAnaliseIA ? null : analiseIA ?? this.analiseIA,
    );
  }
}
