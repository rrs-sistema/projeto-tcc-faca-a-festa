/// Cronômetro observado: o tempo do aplicativo não é deduzido de cliques.
class ObservacaoAutonomiaCalculadora {
  ObservacaoAutonomiaCalculadora(
      {required this.dados, required Duration Function() relogio})
      : _relogio = relogio,
        _acumulado = Duration(seconds: dados['segundos_ativos'] as int? ?? 0);
  final Map<String, dynamic> dados;
  final Duration Function() _relogio;
  Duration _acumulado;
  Duration? _inicio;
  bool get ativa => _inicio != null;
  void retomar() {
    _inicio ??= _relogio();
  }

  void pausar() {
    final inicio = _inicio;
    if (inicio != null) {
      final intervalo = _relogio() - inicio;
      if (!intervalo.isNegative) _acumulado += intervalo;
      _inicio = null;
    }
  }

  void contar(String tipo) {
    if (!ativa) {
      throw StateError('Retome a observação antes de contar uma ação.');
    }
    if (!['intervencoes', 'correcoes', 'erros'].contains(tipo)) {
      throw ArgumentError('Ação desconhecida.');
    }
    dados[tipo] = (dados[tipo] as int? ?? 0) + 1;
    if (tipo == 'correcoes') {
      dados['intervencoes'] = (dados['intervencoes'] as int? ?? 0) + 1;
    }
  }

  Map<String, dynamic> checkpoint() {
    final intervalo = _inicio == null ? Duration.zero : _relogio() - _inicio!;
    return {
      ...dados,
      'segundos_ativos':
          (_acumulado + (intervalo.isNegative ? Duration.zero : intervalo))
              .inSeconds,
      'cronometro_ativo': ativa,
      'estado_observacao': 'em_andamento'
    };
  }
}
