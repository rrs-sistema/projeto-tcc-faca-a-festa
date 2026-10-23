part of 'calculadora_festa_controller.dart';

extension CalculadoraFestaPersonalizacao on CalculadoraFestaController {
  ConfirmacaoConfiguracaoCalculadora prepararComandosTexto(
      List<ComandoTextoCalculadora> comandos, String assinatura) {
    if (usandoContextoHistorico.value ||
        assinatura != assinaturaProposta ||
        comandos.isEmpty ||
        comandos.length > 8 ||
        comandos
                .map((c) => c.tipo == 'base' ? 'publico' : c.tipo)
                .toSet()
                .length !=
            comandos.length) {
      throw StateError('O planejamento mudou. Prepare os ajustes novamente.');
    }
    final patch = <String, dynamic>{};
    for (final c in comandos) {
      final v = c.valores;
      switch (c.tipo) {
        case 'publico':
          patch.addAll({
            'publico': {
              'adultos': v['adultos'],
              'criancas': v['criancas'],
              'bebes': v['bebes']
            },
            'base': 'manual',
            'base_confirmada': true
          });
        case 'base':
          final base =
              v['base'] == 'nao recusados' ? 'nao_recusados' : v['base'];
          if (!['previstos', 'todos', 'confirmados', 'nao_recusados']
              .contains(base)) {
            throw StateError('Fonte inválida.');
          }
          patch.addAll({'base': base, 'base_confirmada': true});
        case 'duracao':
          patch['duracao'] = v['horas'];
        case 'perfil':
          patch['perfil'] = v['perfil'];
        case 'margem':
          patch['margem'] = v['margem'];
        case 'verba':
          patch['verba_alimentacao'] = v['valor'];
        default:
          throw StateError('Ação indisponível.');
      }
    }
    final ConfirmacaoConfiguracaoCalculadora comando;
    try {
      comando = prepararConfirmacaoConfiguracao(patch);
    } catch (_) {
      throw StateError('Confira os valores do planejamento.');
    }
    medicaoUso.registrarDecisao('ajustes_por_texto');
    return comando;
  }

  Future<void> aplicarComandosTexto(
          List<ComandoTextoCalculadora> comandos, String assinatura) =>
      confirmarConfiguracao(prepararComandosTexto(comandos, assinatura));

  static const _memoria = MemoriaCalculadoraService();
  String contextoMemoria(String id, Iterable<CardapioItem> itens) =>
      _memoria.contexto(
          tipo: tipoEventoAtual.value,
          refeicao: titulosCardapiosEvento[id] ?? tituloCardapio,
          duracao: duracaoHoras.value,
          escopo: (escoposCardapiosEvento[id] ??
                  (id == idCardapioAtual
                      ? escopoCardapioAtual
                      : EscopoCardapio.naoDefinido))
              .name,
          servico: const OperacaoCalculadoraService()
                  .refeicao(Map.of(operacaoEvento), id)['servico']
                  ?.toString() ??
              'refeicao',
          itens: itens.map((i) => i.nome));

  Future<void> carregarPreferencias() async {
    final repo = _repository;
    if (repo is! MemoriaCalculadoraRepository) return;
    final uid = _uidAtual;
    if (uid == null) return;
    final memorias =
        await (repo as MemoriaCalculadoraRepository).lerMemoriaCalculadora();
    if (_uidAtual != uid) return;
    _donoMemoria = uid;
    _memoriasReceitas.assignAll(memorias);
    calcular();
  }

  List<Map<String, dynamic>> get preferenciasPrivadas =>
      _memoriasReceitas.isEmpty
          ? []
          : (_donoMemoria == _uidAtual ? _memoriasReceitas.toList() : []);

  List<ItemEstimativaFinanceira> get regrasDaMemoria {
    if (usandoContextoHistorico.value) return [];
    final saida = <ItemEstimativaFinanceira>[];
    final menus = {...cardapiosEvento, idCardapioAtual: itensCardapio.toList()};
    for (final e in menus.entries) {
      final config = const OperacaoCalculadoraService()
          .refeicao(Map.of(operacaoEvento), e.key);
      if (OperacaoCalculadoraService.lista(config['grupos']).isNotEmpty ||
          OperacaoCalculadoraService.mapa(config['destinos_itens'])
              .isNotEmpty) {
        continue;
      }
      final contexto = contextoMemoria(e.key, e.value);
      for (final item in e.value) {
        for (final memoria in preferenciasPrivadas) {
          final regra = _memoria.recuperar(memoria,
              contexto: contexto,
              nome: item.nome,
              id: 'menu_${e.key}_${item.idItem}',
              cardapio: e.key,
              item: item.idItem,
              publico: item.publicoAlvo.name,
              unidade: item.unidade);
          if (regra != null) {
            saida.add(regra.copyWith(premissas: {
              ...regra.premissas,
              'id_evento': idEventoAtual.value
            }));
            break;
          }
        }
      }
    }
    return saida;
  }

  Future<void> guardarPreferencia(ItemEstimativaFinanceira regra) async {
    if (usandoContextoHistorico.value || !possuiEventoVinculado) {
      throw StateError('Abra o planejamento atual de um evento salvo.');
    }
    final config = const OperacaoCalculadoraService()
        .refeicao(Map.of(operacaoEvento), idCardapioAtual);
    if (OperacaoCalculadoraService.lista(config['grupos']).isNotEmpty ||
        OperacaoCalculadoraService.mapa(config['destinos_itens']).isNotEmpty) {
      throw StateError(
          'Receitas para grupos específicos precisam ser conferidas em cada evento.');
    }
    final nova = _memoria.guardar(
        regra, contextoMemoria(idCardapioAtual, itensCardapio));
    final anteriores = preferenciasPrivadas;
    final atualizadas = anteriores
        .where((m) =>
            m['contexto'] != nova['contexto'] || m['nome'] != nova['nome'])
        .toList()
      ..add(nova);
    await _gravarPreferencias(atualizadas, anteriores);
  }

  Future<void> esquecerPreferencias() =>
      _gravarPreferencias([], preferenciasPrivadas);

  Future<void> _gravarPreferencias(List<Map<String, dynamic>> novas,
      List<Map<String, dynamic>> anteriores) async {
    final repo = _repository, uid = _uidAtual;
    if (repo is! MemoriaCalculadoraRepository || uid == null) {
      throw StateError('A memória privada está indisponível.');
    }
    await (repo as MemoriaCalculadoraRepository)
        .gravarMemoriaCalculadora(novas, anteriores: anteriores);
    if (uid == _uidAtual) {
      _donoMemoria = uid;
      _memoriasReceitas.assignAll(novas);
      calcular();
    }
  }
}
