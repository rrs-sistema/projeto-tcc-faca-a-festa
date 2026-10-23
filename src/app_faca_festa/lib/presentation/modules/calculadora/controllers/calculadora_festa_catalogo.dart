part of 'calculadora_festa_controller.dart';

extension CalculadoraFestaCatalogo on CalculadoraFestaController {
  // Adaptadores anteriores mantêm a contingência local identificada. O
  // repositório de produção sempre implementa o catálogo publicado.
  CatalogoContextual? get catalogoParaPropostas =>
      _itensBaseRepository is CatalogoContextualRepository
          ? catalogoContextual.value
          : null;
  Map<String, dynamic> contextoReferenciaPara(String id) {
    final cfg =
        const OperacaoCalculadoraService().refeicao(Map.of(operacaoEvento), id);
    final o = OperacaoCalculadoraService.mapa(cfg['ocorrencia']);
    return {
      if (cfg['servico'] != null) 'servico': cfg['servico'],
      if (o['formato'] != null && o['formato'] != 'nao_definido')
        'formato': o['formato'],
      if (o['hora_local'] != null) 'hora_local': o['hora_local'],
      if (o['duracao_minutos'] != null) 'duracao_minutos': o['duracao_minutos']
    };
  }

  Future<void> atualizarCatalogoContextual() async {
    if (usandoContextoHistorico.value) return;
    final consulta = ++_consultaCatalogo,
        geracao = _versaoPreparacao,
        usuario = _uidAtual,
        evento = idEventoAtual.value;
    final repo = _itensBaseRepository;
    carregandoCatalogo.value = true;
    final anterior = catalogoContextual.value;
    bool atual() =>
        consulta == _consultaCatalogo &&
        geracao == _versaoPreparacao &&
        usuario == _uidAtual &&
        evento == idEventoAtual.value &&
        !usandoContextoHistorico.value;
    try {
      if (repo is! CatalogoContextualRepository) {
        if (atual()) catalogoContextual.value = CatalogoContextual.indisponivel;
        return;
      }
      final novo = await (repo as CatalogoContextualRepository)
          .carregarCatalogoContextual();
      if (atual()) catalogoContextual.value = novo;
    } catch (_) {
      if (atual()) {
        catalogoContextual.value = anterior.referencias.isEmpty
            ? CatalogoContextual.indisponivel
            : CatalogoContextual(anterior.referencias,
                estado: 'contingencia',
                aviso:
                    'Catálogo fora do ar. Contingência com versões já consultadas: ${anterior.referencias.map((r) => r.chave).join(', ')}. Novas versões exigem atualização e revisão.');
      }
    } finally {
      if (consulta == _consultaCatalogo) carregandoCatalogo.value = false;
    }
  }
}
