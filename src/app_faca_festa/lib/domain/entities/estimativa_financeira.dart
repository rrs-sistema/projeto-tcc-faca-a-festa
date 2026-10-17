import 'convidados_equivalentes.dart';
import 'perfil_festa.dart';

enum UnidadeEstimativa {
  unidade,
  cento,
  quilo,
  litro,
  garrafa,
  pacote,
}

extension UnidadeEstimativaExtension on UnidadeEstimativa {
  String get label {
    switch (this) {
      case UnidadeEstimativa.unidade:
        return 'un';
      case UnidadeEstimativa.cento:
        return 'cento';
      case UnidadeEstimativa.quilo:
        return 'kg';
      case UnidadeEstimativa.litro:
        return 'L';
      case UnidadeEstimativa.garrafa:
        return 'garrafa';
      case UnidadeEstimativa.pacote:
        return 'pacote';
    }
  }
}

class ItemEstimativaFinanceira {
  final String id;
  final String categoria;
  final String nome;
  final String tipoItem;
  final String publicoAlvo;
  final UnidadeEstimativa unidade;
  final double quantidadePorConvidadoEquivalente;
  final double valorUnitarioMedio;
  final bool selecionado;
  final Map<String, dynamic> premissas;

  const ItemEstimativaFinanceira({
    required this.id,
    required this.categoria,
    required this.nome,
    required this.tipoItem,
    required this.publicoAlvo,
    required this.unidade,
    required this.quantidadePorConvidadoEquivalente,
    required this.valorUnitarioMedio,
    this.selecionado = true,
    this.premissas = const {},
  });

  ItemEstimativaFinanceira copyWith({
    String? id,
    Map<String, dynamic>? premissas,
    String? categoria,
    String? nome,
    String? tipoItem,
    String? publicoAlvo,
    UnidadeEstimativa? unidade,
    double? quantidadePorConvidadoEquivalente,
    double? valorUnitarioMedio,
    bool? selecionado,
  }) {
    return ItemEstimativaFinanceira(
      id: id ?? this.id,
      premissas: premissas ?? this.premissas,
      categoria: categoria ?? this.categoria,
      nome: nome ?? this.nome,
      tipoItem: tipoItem ?? this.tipoItem,
      publicoAlvo: publicoAlvo ?? this.publicoAlvo,
      unidade: unidade ?? this.unidade,
      quantidadePorConvidadoEquivalente: quantidadePorConvidadoEquivalente ??
          this.quantidadePorConvidadoEquivalente,
      valorUnitarioMedio: valorUnitarioMedio ?? this.valorUnitarioMedio,
      selecionado: selecionado ?? this.selecionado,
    );
  }

  Map<String, dynamic> toPlanejamento() => {
        'id': id,
        'categoria': categoria,
        'nome': nome,
        'tipo': tipoItem,
        'publico': publicoAlvo,
        'unidade': unidade.name,
        'consumo': quantidadePorConvidadoEquivalente,
        'preco': valorUnitarioMedio,
        'selecionado': selecionado,
        'premissas': premissas,
      };

  factory ItemEstimativaFinanceira.fromPlanejamento(Map<String, dynamic> m) =>
      ItemEstimativaFinanceira(
          id: m['id'] as String,
          categoria: m['categoria'] as String,
          nome: m['nome'] as String,
          tipoItem: m['tipo'] as String,
          publicoAlvo: m['publico'] as String,
          unidade: UnidadeEstimativa.values
              .firstWhere((u) => u.name == m['unidade']),
          quantidadePorConvidadoEquivalente: (m['consumo'] as num).toDouble(),
          valorUnitarioMedio: (m['preco'] as num).toDouble(),
          selecionado: m['selecionado'] != false,
          premissas: Map<String, dynamic>.from(m['premissas'] as Map? ?? {}));

  double get rendimento => (premissas['rendimento'] as num?)?.toDouble() ?? 1;
  double get tamanhoEmbalagem =>
      (premissas['embalagem'] as num?)?.toDouble() ?? 0;
  double get fatorComposicao =>
      (premissas['fator_composicao'] as num?)?.toDouble() ?? 1;

  bool get descartavel =>
      tipoItem == 'descartavel' || categoria.toLowerCase().contains('descart');

  // Uma refeição não se repete só porque a festa dura mais horas.
  // A escala antiga fica disponível apenas como premissa explícita.
  bool get ajustarPorDuracao => premissas['ajustar_por_duracao'] == true;
  double get numeroServicos =>
      (premissas['numero_servicos'] as num?)?.toDouble() ?? 1;

  bool get dividirGrupo => premissas['dividir_grupo'] == true;
  double get pesoCrianca =>
      (premissas['peso_crianca'] as num?)?.toDouble() ?? .6;
  double get pesoBebe => (premissas['peso_bebe'] as num?)?.toDouble() ?? .2;
  double fatorPerfil(PerfilFesta perfil) =>
      descartavel || premissas['ajustar_por_perfil'] == false
          ? 1
          : perfil.multiplicadorQuantidade;

  double fatorDuracaoAplicado(int horas) =>
      descartavel || !ajustarPorDuracao ? 1 : _fatorDuracao(horas);

  ConvidadosEquivalentes publicoEfetivo(ConvidadosEquivalentes padrao) {
    final p = premissas['publico_refeicao'];
    if (p is! Map) return padrao;
    return ConvidadosEquivalentes(
        adultos: (p['adultos'] as num).toInt(),
        criancas: (p['criancas'] as num).toInt(),
        bebes: (p['bebes'] as num).toInt(),
        pesoAdulto: padrao.pesoAdulto,
        pesoCrianca: padrao.pesoCrianca,
        pesoBebe: padrao.pesoBebe);
  }

  double publicoEquivalente(ConvidadosEquivalentes convidados) {
    convidados = publicoEfetivo(convidados);
    return switch (publicoAlvo.toLowerCase()) {
      'adultos' =>
        convidados.adultos * (descartavel ? 1 : convidados.pesoAdulto),
      'criancas' || 'crianças' => convidados.criancas *
          (descartavel
              ? 1
              : (premissas['peso_crianca'] as num?)?.toDouble() ??
                  convidados.pesoCrianca),
      'bebes' || 'bebês' => convidados.bebes *
          (descartavel
              ? 1
              : (premissas['peso_bebe'] as num?)?.toDouble() ??
                  convidados.pesoBebe),
      _ => descartavel
          ? convidados.totalInformado.toDouble()
          : convidados.adultos * convidados.pesoAdulto +
              convidados.criancas *
                  ((premissas['peso_crianca'] as num?)?.toDouble() ??
                      convidados.pesoCrianca) +
              convidados.bebes *
                  ((premissas['peso_bebe'] as num?)?.toDouble() ??
                      convidados.pesoBebe),
    };
  }

  String get porcaoReferenciaFormatada {
    final medida = premissas['unidade_consumo'] ?? unidade.label;
    final valor = quantidadePorConvidadoEquivalente;
    if (medida == 'kg' || medida == 'L') {
      return '${(valor * 1000).toStringAsFixed(0)} ${medida == 'kg' ? 'g' : 'ml'}';
    }
    return '${valor.toStringAsFixed(2).replaceAll('.', ',')} $medida';
  }

  double calcularQuantidade({
    required ConvidadosEquivalentes convidados,
    required PerfilFesta perfil,
    int duracaoHoras = 4,
  }) {
    return publicoEquivalente(convidados) *
        quantidadePorConvidadoEquivalente *
        fatorPerfil(perfil) *
        fatorDuracaoAplicado(duracaoHoras) *
        numeroServicos *
        fatorComposicao /
        rendimento;
  }

  double calcularQuantidadeComMargem({
    required ConvidadosEquivalentes convidados,
    required PerfilFesta perfil,
    int duracaoHoras = 4,
    double? margemPersonalizada,
  }) {
    final margem = margemPersonalizada ?? perfil.margemSegurancaPadrao;
    final quantidadeBase = calcularQuantidade(
      convidados: convidados,
      perfil: perfil,
      duracaoHoras: duracaoHoras,
    );

    return quantidadeBase + (quantidadeBase * margem);
  }

  double calcularQuantidadeArredondada({
    required ConvidadosEquivalentes convidados,
    required PerfilFesta perfil,
    int duracaoHoras = 4,
    double? margemPersonalizada,
  }) {
    final quantidade = calcularQuantidadeComMargem(
      convidados: convidados,
      perfil: perfil,
      duracaoHoras: duracaoHoras,
      margemPersonalizada: margemPersonalizada,
    );
    final passo =
        unidade == UnidadeEstimativa.quilo || unidade == UnidadeEstimativa.litro
            ? 100.0
            : 1.0;
    final arredondada = (quantidade * passo - 1e-9).ceil() / passo;
    return tamanhoEmbalagem > 0
        ? (arredondada / tamanhoEmbalagem - 1e-9).ceil() * tamanhoEmbalagem
        : arredondada;
  }

  double calcularCusto({
    required ConvidadosEquivalentes convidados,
    required PerfilFesta perfil,
    int duracaoHoras = 4,
    double? margemPersonalizada,
  }) {
    if (!selecionado) return 0;

    final quantidade = calcularQuantidadeArredondada(
      convidados: convidados,
      perfil: perfil,
      duracaoHoras: duracaoHoras,
      margemPersonalizada: margemPersonalizada,
    );

    return quantidade * valorUnitarioMedio;
  }

  static double _fatorDuracao(int duracaoHoras) {
    if (duracaoHoras <= 2) return 0.85;
    if (duracaoHoras == 3) return 0.95;
    if (duracaoHoras == 4) return 1.00;
    if (duracaoHoras == 5) return 1.08;
    if (duracaoHoras == 6) return 1.15;
    return 1.25;
  }
}

class EstimativaFinanceira {
  final String? idEvento;
  final PerfilFesta perfil;
  final ConvidadosEquivalentes convidados;
  final List<ItemEstimativaFinanceira> itens;
  final DateTime dataSimulacao;
  final int duracaoHoras;
  final double? margemPersonalizada;

  const EstimativaFinanceira({
    this.idEvento,
    required this.perfil,
    required this.convidados,
    required this.itens,
    required this.dataSimulacao,
    this.duracaoHoras = 4,
    this.margemPersonalizada,
  });

  List<ItemEstimativaFinanceira> get itensSelecionados {
    return itens.where((item) => item.selecionado).toList();
  }

  double get custoTotal {
    return itensSelecionados.fold<double>(0, (total, item) {
      return total +
          item.calcularCusto(
            convidados: convidados,
            perfil: perfil,
            duracaoHoras: duracaoHoras,
            margemPersonalizada: margemPersonalizada,
          );
    });
  }

  int get totalItensSelecionados => itensSelecionados.length;

  bool get podeCalcular {
    return convidados.possuiConvidados && itensSelecionados.isNotEmpty;
  }
}
