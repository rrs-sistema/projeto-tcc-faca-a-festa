part of 'calculadora_festa_controller.dart';

extension CalculadoraFestaProposta on CalculadoraFestaController {
  CriacaoCardapioInicial prepararCardapioInicial(
      DestinoPlanoEvento destino, CalculadoraFesta calculo, String titulo) {
    if (estimativaSemEvento.value ||
        usandoContextoHistorico.value ||
        calculo.idEvento != idEventoAtual.value) {
      throw StateError('Abra um evento salvo para criar o cardápio.');
    }
    return const CriacaoCardapioInicialService().preparar(
        destino: destino,
        calculo: calculo,
        usuario: _uidAtual ?? '',
        contexto: snapshotPlanejamento,
        titulo: titulo);
  }

  String get assinaturaProposta => jsonEncode({
        'contexto': contextoEvento.assinatura,
        'snapshot': snapshotPlanejamento,
        'evento': idEventoAtual.value,
        'perfil': {
          'tipo': perfilSelecionado.value.tipo.name,
          'quantidade': perfilSelecionado.value.multiplicadorQuantidade,
          'custo': perfilSelecionado.value.multiplicadorCusto,
          'reserva': perfilSelecionado.value.margemSegurancaPadrao,
        },
        'duracao': duracaoHoras.value,
        'margem': margemPersonalizada.value,
      });

  Map<String, String> get respostasProposta {
    for (final r in regrasManuais) {
      if (r.premissas['id_cardapio'] != idCardapioAtual) continue;
      final respostas = r.premissas['proposta_respostas'];
      if (respostas is Map) {
        return respostas.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    }
    return {};
  }

  PropostaRefeicao proporRefeicao({Map<String, String>? respostas}) {
    final config = const OperacaoCalculadoraService()
        .refeicao(Map<String, dynamic>.from(operacaoEvento), idCardapioAtual);
    final destinos = OperacaoCalculadoraService.mapa(config['destinos_itens']);
    String publico(String id) {
      final d = OperacaoCalculadoraService.mapa(destinos[id]);
      final grupos = List<String>.from(d['grupos'] as List? ?? [])..sort();
      return jsonEncode({
        'modo': d['modo'] ?? 'todos',
        'grupos': d['modo'] == 'grupos' ? grupos : <String>[]
      });
    }

    return const PropostaRefeicaoService().gerar(
        catalogo: catalogoParaPropostas,
        contexto: {
          if (config['servico'] != null) 'servico': config['servico'],
          if (config['ocorrencia'] is Map &&
              config['ocorrencia']['formato'] != 'nao_definido')
            'formato': config['ocorrencia']['formato'],
          if (config['ocorrencia'] is Map &&
              config['ocorrencia']['hora_local'] != null)
            'hora_local': config['ocorrencia']['hora_local'],
          if (config['ocorrencia'] is Map &&
              config['ocorrencia']['duracao_minutos'] != null)
            'duracao_minutos': config['ocorrencia']['duracao_minutos'],
        },
        comporRefeicao: escopoCardapioAtual == EscopoCardapio.refeicao ||
            escopoCardapioAtual == EscopoCardapio.naoDefinido,
        itens: itensCardapio.toList(),
        regras: regrasDisponiveis,
        respostas: respostas ?? respostasProposta,
        publicosDosItens: {
          for (final i in itensCardapio) i.idItem: publico(i.idItem)
        });
  }

  List<CalculadoraFestaItem> resultadosDaProposta(PropostaRefeicao proposta) {
    final p = publicoDaRefeicao(idCardapioAtual);
    final agora = DateTime.now();
    final atual = calculoAtual.value ??
        CalculadoraFesta(
            idCalculo: 'previa_proposta',
            idEvento: idEventoAtual.value,
            tipoEvento: tipoEventoAtual.value,
            baseCalculo: baseCalculo.value,
            totalAdultos: p.adultos,
            totalCriancas: p.criancas,
            totalBebes: p.bebes,
            duracaoHoras: duracaoHoras.value,
            dataCalculo: agora,
            dataAtualizacao: agora,
            perfilFesta: perfilSelecionado.value,
            margemPersonalizada: margemPersonalizada.value);
    return _service.calcularItens(
        calculo: calculoDaRefeicao(atual, idCardapioAtual).copyWith(
            perfilFesta: perfilSelecionado.value,
            duracaoHoras: duracaoHoras.value,
            margemPersonalizada: margemPersonalizada.value,
            limparMargemPersonalizada: margemPersonalizada.value == null),
        itensBase: const ComposicaoRefeicaoService()
            .compor(proposta.regras.map(regraDoPublico).toList()));
  }

  void usarProposta(PropostaRefeicao proposta, {required String assinatura}) {
    if (usandoContextoHistorico.value ||
        !operacaoCarregada.value ||
        erroOperacao.value.isNotEmpty ||
        assinatura != assinaturaProposta ||
        !cardapioDisponivel.value ||
        itensCardapio.isEmpty) {
      throw StateError('O planejamento mudou. Abra a proposta novamente.');
    }
    final novas = proposta.regras
        .where((r) => !proposta.preservados.contains(r.id))
        .toList();
    if (novas.isEmpty) return;
    final ids = novas.map((r) => r.id).toSet();
    if (novas.any((r) =>
        !r.quantidadePorConvidadoEquivalente.isFinite ||
        r.quantidadePorConvidadoEquivalente <= 0 ||
        r.premissas['id_cardapio'] != idCardapioAtual ||
        !itensCardapio
            .any((i) => i.idItem == r.premissas['id_item_cardapio']))) {
      throw StateError('A proposta contém um item incompatível.');
    }
    regrasManuais.removeWhere((r) => ids.contains(r.id));
    regrasManuais.addAll(novas.map((r) => r.copyWith(premissas: {
          ...r.premissas,
          'proposta_respostas': proposta.respostas,
          'revisada_pelo_organizador': true,
        })));
    revisarCardapio.value = true;
    _modoEscolhido = true;
    calcular();
  }
}
