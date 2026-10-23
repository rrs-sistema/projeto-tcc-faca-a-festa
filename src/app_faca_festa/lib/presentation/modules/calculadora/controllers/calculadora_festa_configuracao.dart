part of 'calculadora_festa_controller.dart';

extension CalculadoraFestaConfiguracao on CalculadoraFestaController {
  String? get alertaVerbaAlimentacao => verbaAlimentacao.value != null &&
          orcamentoDisponivel.value != null &&
          verbaAlimentacao.value! > orcamentoDisponivel.value!
      ? 'A verba alimentar confirmada supera o limite atual do evento. Revise a verba; os registros de compra e pagamento foram preservados.'
      : null;
  Map<String, dynamic> get escolhasConfiguracao => {
        'base': valorBasePublico(baseCalculo.value),
        'base_confirmada': true,
        if (baseCalculo.value == BaseCalculoFesta.manual)
          'publico': {
            'adultos': totalAdultos.value,
            'criancas': totalCriancas.value,
            'bebes': totalBebes.value
          },
        'duracao': duracaoHoras.value,
        'perfil': perfilSelecionado.value.tipo.name,
        'margem': margemPersonalizada.value,
        'verba_alimentacao': verbaAlimentacao.value,
      };
  ConfirmacaoConfiguracaoCalculadora prepararConfirmacaoConfiguracao(
          Map<String, dynamic> alteracoes,
          {String? id}) =>
      ConfirmacaoConfiguracaoCalculadora(
          id: id ?? const Uuid().v4(),
          idEvento: idEventoAtual.value,
          idUsuario: _uidAtual,
          revisaoEsperada: (operacaoEvento['revisao'] as num? ?? 0).toInt(),
          alteracoes: alteracoes);

  Future<void> confirmarConfiguracao(
      ConfirmacaoConfiguracaoCalculadora comando) async {
    if (comando.idEvento != null && comando.idEvento != idEventoAtual.value ||
        comando.idUsuario != null && comando.idUsuario != _uidAtual) {
      throw StateError('A confirmação pertence a outra sessão ou evento.');
    }
    if (usandoContextoHistorico.value) {
      throw StateError('Volte ao planejamento atual antes de confirmar.');
    }
    final cfg = {
      ...OperacaoCalculadoraService.mapa(
          operacaoEvento['configuracao_planejamento']),
      ...comando.alteracoes
    };
    const OperacaoCalculadoraService().validarConfiguracaoPublico(cfg);
    final base = basePublicoDoValor(cfg['base']);
    if (base != null &&
        base != BaseCalculoFesta.manual &&
        comando.alteracoes.containsKey('base') &&
        publicoDaBase(base).idades == null) {
      throw StateError(
          'Consulte a fonte e confira as idades antes de confirmar.');
    }
    final verba = cfg['verba_alimentacao'];
    if (verba is num &&
        orcamentoDisponivel.value != null &&
        verba > orcamentoDisponivel.value!) {
      throw ArgumentError('A verba deve caber no limite total do evento.');
    }
    final evento = idEventoAtual.value,
        usuario = _uidAtual,
        geracao = _versaoPreparacao;
    final localAntes = assinaturaExecucao(escolhasConfiguracao);
    estadoConfiguracao.value = EstadoConfirmacaoConfiguracao.pendente;
    mensagemConfiguracao.value = 'Guardando as escolhas…';
    try {
      if (possuiEventoVinculado) {
        await alterarOperacao(comando.toAcao());
      }
      if (usuario != _uidAtual ||
          evento != idEventoAtual.value ||
          geracao != _versaoPreparacao ||
          usandoContextoHistorico.value) {
        return;
      }
      if (localAntes != assinaturaExecucao(escolhasConfiguracao) &&
          _camposConfiguracaoEditados.isNotEmpty) {
        estadoConfiguracao.value = EstadoConfirmacaoConfiguracao.conflito;
        mensagemConfiguracao.value =
            'As escolhas foram guardadas, mas sua nova edição local foi preservada. Revise antes de confirmar novamente.';
        return;
      }
      final dados = possuiEventoVinculado
          ? OperacaoCalculadoraService.mapa(
              operacaoEvento['configuracao_planejamento'])
          : cfg;
      if (comando.alteracoes.entries.any((e) =>
          assinaturaExecucao(dados[e.key]) != assinaturaExecucao(e.value))) {
        throw StateError(
            'As escolhas mudaram em outro acesso após a confirmação. Seus valores foram mantidos para revisão.');
      }
      restaurarEscolhasConfiguracao(dados, forcar: true);
      await _restauracaoCatalogo;
      if (usuario != _uidAtual ||
          evento != idEventoAtual.value ||
          geracao != _versaoPreparacao ||
          usandoContextoHistorico.value) {
        return;
      }
      estadoConfiguracao.value = EstadoConfirmacaoConfiguracao.confirmada;
      mensagemConfiguracao.value = possuiEventoVinculado
          ? 'Escolhas confirmadas no evento.'
          : 'Escolhas aplicadas à estimativa.';
      calcular();
    } catch (e) {
      if (usuario == _uidAtual &&
          evento == idEventoAtual.value &&
          geracao == _versaoPreparacao &&
          !usandoContextoHistorico.value) {
        estadoConfiguracao.value =
            e is StateError && e.message.toString().contains('outro acesso')
                ? EstadoConfirmacaoConfiguracao.conflito
                : EstadoConfirmacaoConfiguracao.falhou;
        mensagemConfiguracao.value = e is StateError
            ? e.message.toString()
            : 'Não foi possível confirmar. Seus valores foram mantidos; tente novamente.';
      }
      rethrow;
    }
  }

  void marcarEdicaoConfiguracao(String campo) {
    _camposConfiguracaoEditados.add(campo);
    estadoConfiguracao.value = EstadoConfirmacaoConfiguracao.editando;
    mensagemConfiguracao.value =
        'Edição local. Confirme para guardar no evento.';
  }

  void restaurarEscolhasConfiguracao(Map<String, dynamic> cfg,
      {bool forcar = false}) {
    if (usandoContextoHistorico.value) return;
    const OperacaoCalculadoraService().validarConfiguracaoPublico(cfg);
    if (forcar) {
      _baseLocalAlterada = false;
      _politicaPublicoRecebida = '';
    }
    sincronizarPoliticaPublico(cfg, forcar: forcar);
    final perfilAnterior = perfilSelecionado.value.tipo;
    final local = escolhasConfiguracao;
    for (final k in ['duracao', 'perfil', 'margem', 'verba_alimentacao']) {
      if (!cfg.containsKey(k)) continue;
      if (!forcar &&
          _configuracaoConfirmada.containsKey(k) &&
          assinaturaExecucao(cfg[k]) ==
              assinaturaExecucao(_configuracaoConfirmada[k])) {
        continue;
      }
      if (!forcar &&
          _camposConfiguracaoEditados.contains(k) &&
          assinaturaExecucao(cfg[k]) != assinaturaExecucao(local[k])) {
        if (assinaturaExecucao(cfg[k]) !=
            assinaturaExecucao(_configuracaoConfirmada[k])) {
          estadoConfiguracao.value = EstadoConfirmacaoConfiguracao.conflito;
          mensagemConfiguracao.value =
              'O planejamento mudou em outro acesso. Sua edição foi preservada. Confira as escolhas atuais antes de tentar novamente.';
        }
        continue;
      }
      switch (k) {
        case 'duracao':
          duracaoHoras.value = cfg[k];
        case 'perfil':
          perfilSelecionado.value = switch (cfg[k]) {
            'economico' => PerfilFesta.economico(),
            'premium' => PerfilFesta.premium(),
            _ => PerfilFesta.padrao()
          };
        case 'margem':
          margemPersonalizada.value = (cfg[k] as num?)?.toDouble();
        case 'verba_alimentacao':
          verbaAlimentacao.value = (cfg[k] as num?)?.toDouble();
      }
    }
    _configuracaoConfirmada = Map.of(cfg);
    if (perfilAnterior != perfilSelecionado.value.tipo) {
      _restauracaoCatalogo = carregarItensBasePorTipoEvento();
    }
    if (forcar) {
      _camposConfiguracaoEditados.clear();
    }
  }
}
