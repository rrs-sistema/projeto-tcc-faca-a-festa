/// Diagnóstico em memória. Não envia dados nem inclui identificadores no relatório.
class MedicaoUsoCalculadora {
  MedicaoUsoCalculadora({Duration Function()? relogio})
      : _relogio = relogio ?? _criarRelogio();
  static Duration Function() _criarRelogio() {
    final cronometro = Stopwatch()..start();
    return () => cronometro.elapsed;
  }

  final Duration Function() _relogio;
  Duration _ativo = Duration.zero;
  Duration? _ultimaAtividade;
  bool _visivel = true;
  static const limiteInatividade = Duration(seconds: 30);
  final Map<String, int> _resultados = {};
  int correcoes = 0;

  void _acumular() {
    final agora = _relogio();
    final ultima = _ultimaAtividade;
    if (_visivel && ultima != null) {
      final intervalo = agora - ultima;
      if (!intervalo.isNegative) {
        _ativo += intervalo > limiteInatividade ? limiteInatividade : intervalo;
      }
    }
    _ultimaAtividade = null;
  }

  /// Tempo de interação aproximado: pausa em segundo plano e após 30 s ociosos.
  void atividade() {
    _acumular();
    if (_visivel) _ultimaAtividade = _relogio();
  }

  void visibilidade(bool visivel) {
    _acumular();
    _visivel = visivel;
    if (visivel) _ultimaAtividade = _relogio();
  }

  Duration get tempoAtivo {
    final ultima = _ultimaAtividade;
    final intervalo =
        ultima == null || !_visivel ? Duration.zero : _relogio() - ultima;
    return _ativo +
        (intervalo.isNegative
            ? Duration.zero
            : intervalo > limiteInatividade
                ? limiteInatividade
                : intervalo);
  }

  void registrarResultado(String acao, {required bool sucesso}) {
    final chave = '${acao}_${sucesso ? 'sucesso' : 'falha'}';
    _resultados.update(chave, (n) => n + 1, ifAbsent: () => 1);
  }

  void registrarCorrecao() {
    correcoes++;
    atividade();
  }

  final Stopwatch _tempo = Stopwatch()..start();
  String? _sessao;
  void iniciarSessao(String chave) {
    if (_sessao == chave) return;
    _sessao = chave;
    listasAbertas = listasCopiadas = ajustes = consumosRegistrados = 0;
    segundosPrimeiraLista = pendenciasUltimaLista = null;
    _campos.clear();
    _decisoes.clear();
    _resultados.clear();
    correcoes = 0;
    _ativo = Duration.zero;
    _ultimaAtividade = _visivel ? _relogio() : null;
    _tempo
      ..reset()
      ..start();
  }

  int listasAbertas = 0,
      listasCopiadas = 0,
      ajustes = 0,
      consumosRegistrados = 0;
  int? segundosPrimeiraLista, pendenciasUltimaLista;
  final Set<String> _campos = {};
  final Map<String, int> _decisoes = {};
  int get camposDistintosEditados => _campos.length;
  int get decisoesRegistradas => _decisoes.values.fold(0, (s, n) => s + n);
  void registrarCampo(String chave) {
    _campos.add(chave);
    atividade();
  }

  void registrarDecisao(String acao) {
    atividade();
    _decisoes.update(acao, (n) => n + 1, ifAbsent: () => 1);
  }

  Map<String, dynamic> get resumo => {
        'campos_distintos_editados': camposDistintosEditados,
        'decisoes_registradas': decisoesRegistradas,
        'acoes': Map<String, int>.unmodifiable(_decisoes),
        'resultados': Map<String, int>.unmodifiable(_resultados),
        'correcoes': correcoes,
      };

  void abrirLista(int pendencias) {
    listasAbertas++;
    segundosPrimeiraLista ??= _tempo.elapsed.inSeconds;
    pendenciasUltimaLista = pendencias;
  }

  String relatorio({int? facilidade}) => [
        'Avaliação da sessão da calculadora',
        'Campos distintos editados: $camposDistintosEditados',
        'Decisões explícitas registradas: $decisoesRegistradas',
        'Correções de referências existentes: $correcoes',
        'Resultados das ações: $_resultados',
        'Tempo ativo aproximado: ${tempoAtivo.inSeconds} s (limite ocioso de 30 s)',
        'Listas abertas: $listasAbertas',
        'Listas copiadas: $listasCopiadas',
        'Ajustes de regras e cenários: $ajustes',
        'Registros de consumo salvos: $consumosRegistrados',
        'Tempo decorrido até a primeira lista: ${segundosPrimeiraLista ?? 'não aberta'} s',
        'Pendências na última lista: ${pendenciasUltimaLista ?? 'não aberta'}',
        if (facilidade != null) 'Facilidade informada: $facilidade de 5',
        'Contagem inicial de ações instrumentadas; não mede todas as intervenções nem comprova a meta de automação.',
        'Dados desta sessão, sem identificação. Tempo decorrido inclui pausas; não comprova eficiência nem redução de desperdício.'
      ].join('\n');
}
