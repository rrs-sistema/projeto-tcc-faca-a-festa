part of '../pages/calculadora_festa_screen.dart';

extension _CalculadoraFestaDecisoes on _CalculadoraFestaScreenState {
  bool get _eventoEncerrado {
    final evento = eventoController.eventoAtualEntidade;
    if (evento == null ||
        evento.status == StatusEvento.cancelado ||
        evento.status == StatusEvento.adiado) {
      return false;
    }
    final fim = evento.dataFim ?? evento.data;
    final hoje = DateTime.now();
    return evento.status == StatusEvento.finalizado ||
        DateTime(fim.year, fim.month, fim.day)
            .isBefore(DateTime(hoje.year, hoje.month, hoje.day));
  }

  bool _podeAlterarPlanejamento() {
    if (calculadoraController.usandoContextoHistorico.value) {
      Get.snackbar('Simulação salva',
          'Atualize os dados atuais antes de alterar o cardápio.');
      return false;
    }
    return true;
  }

  Future<void> _abrirAnaliseRefeicao() async {
    final c = calculadoraController,
        analise = calculadoraController.analiseRefeicao;
    final revisar = await showDialog<bool>(
        context: context,
        builder: (ctx) => Theme(
            data: themeController.materialTheme,
            child: _PlanejamentoDialog(
                title: 'Sua refeição por inteiro',
                icon: Icons.restaurant_outlined,
                primary: themeController.primaryColor.value,
                confirmLabel: 'Revisar um item',
                cancelLabel: 'Voltar',
                onCancel: () => Navigator.pop(ctx),
                onConfirm: () => Navigator.pop(ctx, true),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                          '${analise.principais} principal(is) · ${analise.acompanhamentos} acompanhamento(s) · ${analise.bebidas} bebida(s)',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      if (analise.pendencias.isEmpty)
                        const Text(
                            'Nenhuma inconsistência foi identificada nos papéis configurados.'),
                      for (final ponto in analise.pendencias)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(ponto)),
                      for (final item in c.itensSemRegra)
                        Text('${item.nome}: ainda sem porção configurada.'),
                      const Text(
                          'A análise usa o que você informou. Não certifica suficiência, equilíbrio nutricional ou atendimento a restrições alimentares.',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF80591A))),
                    ]))));
    if (revisar != true || !mounted) return;
    if (c.itensSemRegra.isNotEmpty) {
      await _editarRegra(item: c.itensSemRegra.first);
      return;
    }
    final resultado =
        await _selecionarItemCalibracao('Qual item quer revisar?');
    if (resultado != null && mounted) {
      await _editarRegra(
          regra: c.regraDoResultado(resultado),
          item: c.revisarCardapio.value
              ? const RevisaoCardapioService()
                  .correspondente(resultado, c.itensCardapio)
              : null);
    }
  }

  Future<void> _conferirCustos() async {
    final c = calculadoraController;
    if (!_podeAlterarPlanejamento()) return;
    if (c.compromissosOrcamento.isEmpty) {
      Get.snackbar('Nenhum valor orçado',
          'Registre os gastos já realizados em Orçamento para conciliá-los com as compras.');
      return;
    }
    for (final gasto in c.compromissosOrcamento.toList()) {
      if (!mounted) return;
      var modo = (gasto['conferencia_financeira'] ?? 'revisar').toString();
      final assinatura = jsonEncode(c.snapshotPlanejamento);
      final aceitar = await showDialog<bool>(
          context: context,
          builder: (ctx) => StatefulBuilder(
              builder: (ctx, atualizar) => Theme(
                  data: themeController.materialTheme,
                  child: _PlanejamentoDialog(
                      title: 'Conferir custo já orçado',
                      icon: Icons.receipt_long_outlined,
                      primary: themeController.primaryColor.value,
                      confirmLabel: 'Salvar conferência',
                      cancelLabel: 'Cancelar',
                      onCancel: () => Navigator.pop(ctx),
                      onConfirm: () => Navigator.pop(ctx, true),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                                '${gasto['descricao']} · ${_money(gasto['valor'] as num)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            const Text(
                                'Classifique o valor desta linha. Não alteramos preços, pagamentos ou a contratação.',
                                style: TextStyle(fontSize: 12)),
                            for (final e in {
                              'revisar':
                                  'Ainda preciso conferir o que este valor inclui',
                              'realizado':
                                  'Este valor corresponde apenas a despesas já realizadas; não inclui futuras compras da lista',
                              if ((gasto['cobre_itens'] as List? ?? []).isEmpty)
                                'sem_itens':
                                    'Este valor não corresponde a itens do cardápio (ex.: espaço ou decoração)'
                            }.entries)
                              RadioListTile<String>(
                                  contentPadding: EdgeInsets.zero,
                                  value: e.key,
                                  groupValue: modo,
                                  onChanged: (v) => atualizar(() => modo = v!),
                                  title: Text(e.value,
                                      style: const TextStyle(fontSize: 13))),
                            const Text(
                                'Se o orçamento inclui compras futuras, mantenha a conferência pendente. Para evitar dupla contagem, o saldo continuará em aberto até os valores serem separados no Orçamento.',
                                style: TextStyle(fontSize: 12)),
                          ])))));
      if (aceitar != true || !mounted) return;
      if (assinatura != jsonEncode(c.snapshotPlanejamento)) {
        Get.snackbar('Valores alterados', 'Confira novamente antes de salvar.');
        return;
      }
      try {
        await c.conferirCusto(gasto, modo);
      } catch (_) {
        Get.snackbar(
            'Não foi possível salvar', 'Confira a conexão e tente novamente.');
        return;
      }
    }
  }

  Future<void> _ajustarAoLimite() async {
    final c = calculadoraController;
    if (!_podeAlterarPlanejamento()) return;
    if (c.orcamentoDisponivel.value == null) {
      await _editarLimiteOrcamento();
      if (!mounted || c.orcamentoDisponivel.value == null) return;
    }
    final assinatura = jsonEncode(c.snapshotPlanejamento);
    final atual = c.resumoCompras;
    var reserva = c.margemEmUso > .05 ? .05 : c.margemEmUso;
    var salvando = false;
    String? erro;
    final adotar = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(builder: (ctx, atualizar) {
              final resultados = c.simularReserva(reserva);
              final proposto = const ResumoComprasService().calcular(
                  itens: c.listaComprasEventoComResultados(resultados),
                  compromissos: c.compromissosOrcamento.toList(),
                  semRegra: c.itensSemRegraEvento.length,
                  consultaCompleta: atual.consultaCompleta,
                  limite: c.orcamentoDisponivel.value);
              final saldo = proposto.saldoAposCompras;
              return Theme(
                  data: themeController.materialTheme,
                  child: _PlanejamentoDialog(
                      title: 'Planejar dentro do limite',
                      icon: Icons.savings_outlined,
                      primary: themeController.primaryColor.value,
                      confirmLabel: 'Usar esta reserva',
                      cancelLabel: 'Manter atual',
                      onCancel: () {
                        if (!salvando) Navigator.pop(ctx);
                      },
                      onConfirm: () async {
                        if (salvando) return;
                        atualizar(() {
                          salvando = true;
                          erro = null;
                        });
                        try {
                          if (assinatura !=
                              jsonEncode(c.snapshotPlanejamento)) {
                            throw StateError(
                                'O planejamento mudou. Revise o cenário.');
                          }
                          await c.confirmarConfiguracao(c
                              .prepararConfirmacaoConfiguracao(
                                  {'margem': reserva}));
                          if (ctx.mounted) Navigator.pop(ctx, true);
                        } catch (e) {
                          if (ctx.mounted) {
                            atualizar(() => erro = e is StateError
                                ? e.message.toString()
                                : 'Não foi possível guardar a reserva. Seus valores foram mantidos.');
                          }
                        } finally {
                          if (ctx.mounted) atualizar(() => salvando = false);
                        }
                      },
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (erro != null)
                              Text(erro!,
                                  style: const TextStyle(color: Colors.red)),
                            if (salvando) const Text('Guardando reserva…'),
                            Text(
                                'Limite: ${_money(c.orcamentoDisponivel.value!)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            const Text(
                                'A reserva muda neste cardápio. A comparação financeira preserva as outras refeições cadastradas e os gastos consultados. Despesas não informadas permanecem fora da projeção.',
                                style: TextStyle(fontSize: 12)),
                            Text(atual.custoIndefinido
                                ? 'Compras restantes: custo em conferência'
                                : 'Compras restantes conhecidas: ${_money(atual.custoConhecido)}'),
                            Text(proposto.custoIndefinido
                                ? 'Proposta: custo em conferência'
                                : 'Proposta conhecida: ${_money(proposto.custoConhecido)}'),
                            if (saldo != null)
                              Text(saldo >= 0
                                  ? 'Saldo projetado: ${_money(saldo)}'
                                  : 'Ainda excede o limite em ${_money(-saldo)}'),
                            if (saldo == null)
                              const Text(
                                  'Não é possível afirmar que cabe no limite: confira quantidades, preços e possíveis sobreposições com o orçamento.',
                                  style: TextStyle(color: Color(0xFF80591A))),
                            const SizedBox(height: 12),
                            Text('Reserva extra: ${(reserva * 100).round()}%'),
                            Slider(
                                value: reserva.clamp(0, .3),
                                min: 0,
                                max: .3,
                                divisions: 30,
                                label: '${(reserva * 100).round()}%',
                                onChanged: salvando
                                    ? null
                                    : (v) => atualizar(() => reserva = v)),
                            const Text(
                                'Este cenário preserva a porção base e muda somente a reserva. Diminuir a reserva aumenta o risco de falta; não garante comida suficiente.',
                                style: TextStyle(fontSize: 12)),
                            for (final i in resultados)
                              ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(i.nome),
                                  trailing: Text(i.quantidadeFormatada)),
                          ])));
            }));
    if (adotar == true && mounted) {
      c.medicaoUso.ajustes++;
    }
  }

  bool _itemTemCompromisso(ItemListaCompras item) {
    final d = item.cardapio?.disponibilidade;
    final chave = RevisaoCardapioService.identidade(item.resultado.nome,
        item.resultado.unidade, item.resultado.publicoAlvo);
    return (d != null && (d.comprado > 0 || d.estoque > 0)) ||
        item.cardapio?.confirmado == true ||
        (item.cardapio?.quantidadeFinal ?? 0) > 0 ||
        calculadoraController.compromissosOrcamento.any((g) =>
            g['identidade'] == chave ||
            ((g['cobre_itens'] as List? ?? []).contains(chave) ||
                (g['cobre_itens'] as List? ?? []).contains(
                    RevisaoCardapioService.coberturaResultado(
                        item.resultado))));
  }

  Future<void> _simularSubstituicao() async {
    final c = calculadoraController;
    if (!_podeAlterarPlanejamento()) return;
    final resultado =
        await _selecionarItemCalibracao('Qual ingrediente quer substituir?');
    if (resultado == null || !mounted) return;
    final item = c.listaCompras.firstWhere(
        (i) => i.resultado.idItemResultado == resultado.idItemResultado);
    final original = item.regra;
    if (original == null || _itemTemCompromisso(item)) {
      Get.snackbar('Confira o planejamento',
          'Este item já tem disponibilidade, confirmação ou orçamento vinculado. Revise esses registros antes de trocar.');
      return;
    }
    final assinatura = jsonEncode(c.snapshotPlanejamento);
    // All numeric inputs for the new food must be consciously supplied.
    final alternativa = await showDialog<ItemEstimativaFinanceira>(
        context: context,
        builder: (_) => Theme(
            data: themeController.materialTheme,
            child: CalculadoraRegraManualDialog(
                catalogo: c.catalogoContextual.value,
                contextoReferencia: c.contextoReferenciaPara(c.idCardapioAtual),
                inicial: original.copyWith(
                    nome: '',
                    selecionado: true,
                    quantidadePorConvidadoEquivalente: 0,
                    valorUnitarioMedio: 0,
                    premissas: {
                      'papel_na_refeicao':
                          original.premissas['papel_na_refeicao'],
                      'estado': 'não informado',
                      'grupo': original.premissas['grupo'] ?? '',
                      'dividir_grupo': original.dividirGrupo,
                      'participacao': original.premissas['participacao'] ?? 1,
                      'numero_servicos': original.numeroServicos,
                      'ajustar_por_perfil': false,
                      'fonte': 'Alternativa informada pelo organizador',
                      'origem': 'alternativa_organizador'
                    }))));
    if (alternativa == null || !mounted || c.calculoAtual.value == null) return;
    try {
      final cenario = const CenarioAlternativaService().simular(
          calculo: c.calculoAtual.value!,
          regras: c.itensParaCalculo,
          original: original,
          alternativa: alternativa);
      final novo = cenario.resultados
          .firstWhere((i) => i.idItemResultado == resultado.idItemResultado);
      final confirmar = await showDialog<bool>(
          context: context,
          builder: (ctx) => Theme(
              data: themeController.materialTheme,
              child: _PlanejamentoDialog(
                  title: 'Revisar substituição',
                  icon: Icons.swap_horiz,
                  primary: themeController.primaryColor.value,
                  confirmLabel: 'Aplicar substituição',
                  cancelLabel: 'Manter atual',
                  onCancel: () => Navigator.pop(ctx),
                  onConfirm: () => Navigator.pop(ctx, true),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('${original.nome} → ${alternativa.nome}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        Text(
                            'Antes: ${resultado.quantidadeFormatada} · ${resultado.valorUnitarioMedio > 0 ? resultado.custoEstimadoFormatado : 'preço pendente'}'),
                        Text(
                            'Alternativa: ${novo.quantidadeFormatada} · ${novo.custoEstimadoFormatado}'),
                        if (cenario.variacao != null)
                          Text(cenario.variacao! >= 0
                              ? 'Diferença estimada dos itens: menos ${_money(cenario.variacao!)}'
                              : 'Diferença estimada dos itens: mais ${_money(-cenario.variacao!)}'),
                        if (cenario.variacao == null)
                          const Text(
                              'Economia total indisponível: faltam preços no planejamento.'),
                        const SizedBox(height: 12),
                        const Text(
                            'Você definiu a porção e o preço da alternativa. Confira gosto, preparo e restrições alimentares. O orçamento existente não será alterado e esta comparação não garante suficiência.'),
                        if (c.revisarCardapio.value)
                          const Text(
                              'O nome e a sugestão do item serão atualizados no cardápio; a quantidade final precisará ser definida novamente. Use Salvar para guardar a porção e o preço desta simulação.'),
                      ]))));
      if (confirmar != true || !mounted) return;
      if (assinatura != jsonEncode(c.snapshotPlanejamento) ||
          !_podeAlterarPlanejamento()) {
        throw StateError('O planejamento mudou.');
      }
      if (c.revisarCardapio.value && item.cardapio != null) {
        final menu = item.cardapio!;
        await cardapioController.atualizarItem(
            menu.idCardapio,
            menu.copyWith(
                nome: alternativa.nome,
                unidade: alternativa.unidade.label,
                quantidadeSugerida: novo.quantidade,
                quantidadeFinal: 0,
                confirmado: false));
      }
      if (!mounted || c.idEventoAtual.value != item.resultado.idEvento) return;
      c.adicionarItemManual(cenario.alternativa);
      c.medicaoUso.ajustes++;
    } catch (_) {
      Get.snackbar('Não foi possível aplicar',
          'Confira se a alternativa mantém o papel e o público do item, tem porção e preço válidos e não duplica outro alimento.');
    }
  }

  Future<void> _reduzirVariedade() async {
    final c = calculadoraController;
    if (!_podeAlterarPlanejamento()) return;
    final resultado =
        await _selecionarItemCalibracao('Qual alternativa quer retirar?');
    if (resultado == null || !mounted || c.calculoAtual.value == null) return;
    final item = c.listaCompras.firstWhere(
        (i) => i.resultado.idItemResultado == resultado.idItemResultado);
    final regra = item.regra;
    final grupo = regra?.premissas['grupo'];
    final pares = c.itensParaCalculo
        .where((r) =>
            r.id != regra?.id &&
            r.selecionado &&
            r.dividirGrupo &&
            r.premissas['grupo'] == grupo &&
            r.publicoAlvo == regra?.publicoAlvo &&
            r.premissas['papel_na_refeicao'] ==
                regra?.premissas['papel_na_refeicao'])
        .toList();
    if (regra == null ||
        !['principal', 'acompanhamento', 'bebida', 'outro']
            .contains(regra.premissas['papel_na_refeicao']) ||
        !regra.dividirGrupo ||
        grupo == null ||
        grupo.toString().isEmpty ||
        pares.isEmpty ||
        _itemTemCompromisso(item)) {
      Get.snackbar('Defina as alternativas primeiro',
          'A retirada só é permitida em um grupo de alternativas declarado, com outra opção do mesmo papel e público, sem compra, confirmação ou orçamento para este item.');
      return;
    }
    final assinatura = jsonEncode(c.snapshotPlanejamento);
    final propostos = const CenarioAlternativaService().simularRetirada(
        calculo: c.calculoAtual.value!,
        regras: c.itensParaCalculo,
        id: regra.id);
    final completo = [...c.itensCalculados, ...propostos]
        .every((i) => i.valorUnitarioMedio > 0);
    final economia = completo
        ? c.itensCalculados.fold<double>(0, (s, i) => s + i.custoEstimado) -
            propostos.fold<double>(0, (s, i) => s + i.custoEstimado)
        : null;
    final aceitar = await showDialog<bool>(
        context: context,
        builder: (ctx) => Theme(
            data: themeController.materialTheme,
            child: _PlanejamentoDialog(
                title: 'Menos variedade, porções revistas',
                icon: Icons.playlist_remove,
                primary: themeController.primaryColor.value,
                confirmLabel: 'Retirar item e recalcular',
                cancelLabel: 'Manter atual',
                onConfirm: () => Navigator.pop(ctx, true),
                onCancel: () => Navigator.pop(ctx),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Retirar: ${regra.nome}',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(
                          'Continuam neste papel: ${pares.map((r) => r.nome).join(', ')}. A participação das alternativas restantes será recalculada.'),
                      if (economia != null)
                        Text(
                            'Variação estimada: ${_money(economia)} de economia (valor negativo indica aumento).'),
                      if (economia == null)
                        const Text(
                            'Economia desconhecida: há preços pendentes.'),
                      for (final r in propostos)
                        ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(r.nome),
                            subtitle: Text(r.quantidadeFormatada)),
                      const Text(
                          'Confira as porções. Se você confirmar, o item será retirado do cardápio atual. Nenhuma compra ou despesa será cancelada automaticamente.',
                          style: TextStyle(fontSize: 12)),
                    ]))));
    if (aceitar == true && mounted) {
      if (assinatura != jsonEncode(c.snapshotPlanejamento)) {
        Get.snackbar(
            'Planejamento alterado', 'Revise novamente antes de retirar.');
        return;
      }
      try {
        if (c.revisarCardapio.value && item.cardapio != null) {
          await cardapioController.excluirItem(
              item.cardapio!.idCardapio, item.cardapio!.idItem);
        } else {
          c.adicionarItemManual(regra.copyWith(selecionado: false));
        }
        c.medicaoUso.ajustes++;
      } catch (_) {
        Get.snackbar('Não foi possível retirar',
            'O item permanece pendente de conferência. Atualize o cardápio antes de tentar novamente.');
      }
    }
  }

  Future<void> _revisarDepoisDaFesta() async {
    final c = calculadoraController;
    if (!_podeAlterarPlanejamento()) return;
    if (!c.possuiEventoVinculado) {
      Get.snackbar(
          'Vincule um evento', 'Salve o evento antes de registrar a revisão.');
      return;
    }
    if (!_eventoEncerrado) {
      Get.snackbar('Depois da festa',
          'A revisão fica disponível após a realização do evento.');
      return;
    }
    await showDialog<void>(
        context: context,
        builder: (_) => Theme(
            data: themeController.materialTheme,
            child: CalculadoraRevisaoPosEventoDialog(
                controller: c,
                onMedir: (id) async {
                  final item =
                      c.itensCardapio.firstWhereOrNull((i) => i.idItem == id);
                  if (item == null || !mounted) return;
                  final regra = const RevisaoCardapioService()
                      .regraPara(item, c.regrasDisponiveis);
                  if (regra != null) await _registrarConsumo(regra);
                })));
  }

  Future<void> _avaliarExperiencia() async {
    int? facilidade;
    final copiar = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, atualizar) => Theme(
                data: themeController.materialTheme,
                child: _PlanejamentoDialog(
                    title: 'Avaliar esta experiência',
                    icon: Icons.rate_review_outlined,
                    primary: themeController.primaryColor.value,
                    confirmLabel: 'Copiar avaliação',
                    cancelLabel: 'Voltar',
                    onConfirm: () => Navigator.pop(ctx, true),
                    onCancel: () => Navigator.pop(ctx),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                              'Como foi organizar o planejamento? 1 = difícil, 5 = fácil.'),
                          Row(children: [
                            for (var nota = 1; nota <= 5; nota++)
                              Expanded(
                                  child: Padding(
                                      padding: const EdgeInsets.all(2),
                                      child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                              minimumSize: const Size(48, 48),
                                              padding: EdgeInsets.zero,
                                              backgroundColor: facilidade ==
                                                      nota
                                                  ? themeController
                                                      .primaryColor.value
                                                      .withValues(alpha: .12)
                                                  : null),
                                          onPressed: () => atualizar(
                                              () => facilidade = nota),
                                          child: Text('$nota'))))
                          ]),
                          Text(
                              facilidade == null
                                  ? 'Avaliação opcional: selecione uma nota.'
                                  : 'Sua avaliação: $facilidade de 5',
                              style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 12),
                          Text(calculadoraController.medicaoUso.relatorio()),
                          const Text(
                              'Dados somente desta sessão em memória. Você decide se quer copiar e compartilhar; nada é enviado automaticamente.',
                              style: TextStyle(fontSize: 12)),
                        ])))));
    if (copiar == true) {
      await Clipboard.setData(ClipboardData(
          text: calculadoraController.medicaoUso
              .relatorio(facilidade: facilidade)));
    }
  }
}
