part of '../pages/calculadora_festa_screen.dart';

extension _CalculadoraPlanejamento on _CalculadoraFestaScreenState {
  Future<void> _reutilizarReceita() async {
    final c = calculadoraController;
    if (!_podeAlterarPlanejamento()) return;
    final assinatura = jsonEncode(c.snapshotPlanejamento);
    try {
      final receitas = await c.consultarReceitasSalvas();
      if (!mounted || assinatura != jsonEncode(c.snapshotPlanejamento)) {
        return;
      }
      final opcoes = <(CardapioItem, ItemEstimativaFinanceira)>[
        for (final item in c.itensCardapio)
          for (final r in receitas)
            if (RevisaoCardapioService.normalizar(item.nome) ==
                    RevisaoCardapioService.normalizar(r.nome) &&
                (RevisaoCardapioService.unidade(item.unidade) ==
                        RevisaoCardapioService.unidade(r.unidade.label) ||
                    const RevisaoCardapioService().unidadeInicial(item)))
              (item, r)
      ];
      if (opcoes.isEmpty) {
        Get.snackbar('Nenhuma receita compatível salva',
            'Identifique sua receita na porção e salve a simulação. Receitas das suas últimas 100 simulações poderão ser reutilizadas; preços precisam ser atualizados.');
        return;
      }
      final escolha = await showDialog<int>(
          context: context,
          builder: (ctx) => AlertDialog(
                  title: const Text('Suas receitas salvas'),
                  content: SizedBox(
                      width: 440,
                      child: SingleChildScrollView(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Text(
                            'Escolha uma receita e confira porção, estado e rendimento. O preço anterior não será reaproveitado.'),
                        for (var i = 0; i < opcoes.length; i++)
                          ListTile(
                              title: Text(opcoes[i].$1.nome),
                              subtitle: Text(
                                  '${opcoes[i].$2.premissas['receita']} · ${opcoes[i].$2.porcaoReferenciaFormatada}'),
                              onTap: () => Navigator.pop(ctx, i))
                      ]))),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancelar'))
                  ]));
      if (!mounted ||
          escolha == null ||
          assinatura != jsonEncode(c.snapshotPlanejamento)) {
        return;
      }
      final (item, r) = opcoes[escolha];
      await _editarRegra(
          item: item,
          regra: r.copyWith(
              id: 'menu_${item.idCardapio}_${item.idItem}',
              nome: item.nome,
              publicoAlvo: item.publicoAlvo.name,
              tipoItem: item.tipo.name,
              premissas: {
                ...r.premissas,
                if (RevisaoCardapioService.unidade(item.unidade) !=
                    RevisaoCardapioService.unidade(r.unidade.label))
                  'unidade_original': item.unidade,
              }));
    } catch (_) {
      Get.snackbar('Receitas indisponíveis',
          'Não foi possível consultar as receitas privadas. A porção atual foi preservada.');
    }
  }

  Future<void> _editarRegra(
      {CardapioItem? item, ItemEstimativaFinanceira? regra}) async {
    UnidadeEstimativa? unidade;
    if (item != null) {
      for (final u in UnidadeEstimativa.values) {
        if (RevisaoCardapioService.unidade(u.label) ==
            RevisaoCardapioService.unidade(item.unidade)) {
          unidade = u;
        }
      }
      if (unidade == null) {
        Get.snackbar('Unidade não reconhecida',
            'Edite a unidade de ${item.nome} no cardápio antes de configurar o consumo.');
        return;
      }
    }
    final resultado = await showDialog<ItemEstimativaFinanceira>(
        context: context,
        builder: (_) => Theme(
            data: themeController.materialTheme,
            child: CalculadoraRegraManualDialog(
              inicial: regra,
              nome: item?.nome,
              id: item == null
                  ? regra?.id
                  : 'menu_${item.idCardapio}_${item.idItem}',
              unidade: unidade,
              publico: item?.publicoAlvo.name ?? 'todos',
              tipo: item?.tipo.name ?? 'outro',
            )));
    if (resultado != null && mounted) {
      calculadoraController.adicionarItemManual(resultado);
      calculadoraController.medicaoUso.ajustes++;
    }
  }

  String _identidadeCobertura(CardapioItem item) {
    final regra = const RevisaoCardapioService()
        .regraPara(item, calculadoraController.regrasDisponiveis);
    return RevisaoCardapioService.cobertura(item,
        medida: regra?.unidade.label ?? item.unidade);
  }

  Future<void> _revisarCoberturas() async {
    if (!_podeAlterarPlanejamento()) return;
    final c = calculadoraController;
    final itens = c.itensCardapio.toList();
    if (itens.isEmpty) {
      Get.snackbar('Selecione um cardápio',
          'Inclua os itens para associar a cobertura dos serviços.');
      return;
    }
    for (final gasto in c.compromissosOrcamento.toList()) {
      if (!mounted) return;
      final assinatura = jsonEncode(c.snapshotPlanejamento);
      final marcados = Set<String>.from(gasto['cobre_itens'] as List? ?? []);
      final legados = itens
          .map((i) => RevisaoCardapioService.identidade(
              i.nome,
              const RevisaoCardapioService()
                      .regraPara(i, c.regrasDisponiveis)
                      ?.unidade
                      .label ??
                  i.unidade,
              i.publicoAlvo.name))
          .toSet();
      final tinhaLegados = marcados.any(legados.contains);
      marcados.removeWhere(legados.contains);
      final escolha = await showDialog<List<String>>(
          context: context,
          builder: (ctx) => StatefulBuilder(
              builder: (ctx, atualizar) => Theme(
                  data: themeController.materialTheme,
                  child: _PlanejamentoDialog(
                    title: 'Cobertura do serviço',
                    icon: Icons.link_rounded,
                    primary: themeController.primaryColor.value,
                    confirmLabel: 'Salvar cobertura',
                    cancelLabel: 'Cancelar',
                    onCancel: () => Navigator.pop(ctx),
                    onConfirm: () => Navigator.pop(ctx, marcados.toList()),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('${gasto['descricao'] ?? 'Orçamento'}',
                              style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF172B21))),
                          const SizedBox(height: 6),
                          Text('Refeição: ${c.tituloCardapio}'),
                          if (tinhaLegados)
                            const Text(
                                'A cobertura antiga não identificava a refeição. Marque novamente os itens incluídos neste cardápio.'),
                          const Text(
                              'Selecione apenas os itens integralmente incluídos neste serviço.'),
                          const SizedBox(height: 12),
                          Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFF4F7F5),
                                  borderRadius: BorderRadius.circular(12)),
                              child: const Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.info_outline_rounded,
                                        size: 18, color: Color(0xFF526259)),
                                    SizedBox(width: 8),
                                    Expanded(
                                        child: Text(
                                            'O valor orçado será contado uma única vez. Esta seleção não confirma compra ou pagamento.',
                                            style: TextStyle(fontSize: 12))),
                                  ])),
                          const SizedBox(height: 12),
                          Text('${marcados.length} selecionado(s)',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          for (final item in itens)
                            CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                activeColor: themeController.primaryColor.value,
                                title: Text(item.nome,
                                    style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500)),
                                value: marcados
                                    .contains(_identidadeCobertura(item)),
                                onChanged: (v) => atualizar(() {
                                      final chave = _identidadeCobertura(item);
                                      if (v == true) {
                                        marcados.add(chave);
                                      } else {
                                        marcados.remove(chave);
                                      }
                                    })),
                        ]),
                  ))));
      if (!mounted || escolha == null) return;
      if (assinatura != jsonEncode(c.snapshotPlanejamento)) {
        Get.snackbar('Planejamento alterado',
            'Confira novamente a refeição antes de salvar a cobertura.');
        return;
      }
      try {
        await c.definirCobertura(gasto['id'] as String, escolha);
      } catch (_) {
        Get.snackbar('Não foi possível salvar',
            'Tente novamente ao consultar os serviços.');
        return;
      }
    }
  }

  Future<void> _abrirDetalhesItem(CalculadoraFestaItem resultado) async {
    final c = calculadoraController;
    final menu = const RevisaoCardapioService()
        .correspondente(resultado, c.itensCardapio);
    final prefixo = '${resultado.idCalculo}_';
    final id = resultado.idItemResultado.startsWith(prefixo)
        ? resultado.idItemResultado.substring(prefixo.length)
        : resultado.idItemResultado;
    ItemEstimativaFinanceira? regra;
    for (final r in c.regrasDisponiveis) {
      if (r.id == id) regra = r;
    }
    if (regra == null && menu != null) {
      regra =
          const RevisaoCardapioService().regraPara(menu, c.regrasDisponiveis);
    }
    final editar = await showDialog<String>(
        context: context,
        builder: (ctx) => Theme(
            data: themeController.materialTheme,
            child: Dialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: 560,
                    maxHeight: MediaQuery.sizeOf(ctx).height * .85),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                      child: Row(children: [
                        Expanded(
                            child: Text(resultado.nome,
                                style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700))),
                        IconButton(
                            tooltip: 'Fechar',
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close_rounded)),
                      ])),
                  const Divider(height: 1),
                  Flexible(
                      child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: DefaultTextStyle.merge(
                              style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.45,
                                  color: Color(0xFF475569)),
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                            color: themeController
                                                .primaryColor.value
                                                .withValues(alpha: .06),
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text('COMPRA SUGERIDA',
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      letterSpacing: 1,
                                                      fontWeight:
                                                          FontWeight.w700)),
                                              Text(
                                                  resultado.quantidadeFormatada,
                                                  style: TextStyle(
                                                      fontSize: 26,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: themeController
                                                          .primaryColor.value)),
                                              Text(resultado
                                                          .valorUnitarioMedio >
                                                      0
                                                  ? 'Custo: ${resultado.custoEstimadoFormatado}'
                                                  : 'Preço pendente · custo ainda incompleto.'),
                                            ])),
                                    const SizedBox(height: 12),
                                    if (menu != null &&
                                        menu.unidade != resultado.unidade)
                                      Text(
                                          'Unidade inicial ${menu.unidade}; proposta ${resultado.unidade}. Sem quantidade final para comparar.')
                                    else if (menu != null)
                                      Text(
                                          'Planejado: ${menu.quantidadeFinal} ${menu.unidade}. '
                                          'Diferença: ${(resultado.quantidade - menu.quantidadeFinal).toStringAsFixed(2)} ${resultado.unidade}.'),
                                    const SizedBox(height: 8),
                                    Theme(
                                        data: themeController.materialTheme
                                            .copyWith(
                                                dividerColor:
                                                    Colors.transparent),
                                        child: ExpansionTile(
                                            tilePadding: EdgeInsets.zero,
                                            expandedCrossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            title: const Text(
                                                'Como chegamos a este cálculo',
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                            children: [
                                              SelectableText(
                                                  resultado.regraAplicada,
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      height: 1.5))
                                            ])),
                                    if (regra != null) ...[
                                      const Divider(height: 16),
                                      TextButton.icon(
                                          style: TextButton.styleFrom(
                                              alignment: Alignment.centerLeft,
                                              minimumSize:
                                                  const Size.fromHeight(48),
                                              textStyle: GoogleFonts.poppins(
                                                  fontSize: 13)),
                                          onPressed: () =>
                                              Navigator.pop(ctx, 'consumo'),
                                          icon: const Icon(
                                              Icons.fact_check_outlined,
                                              size: 20),
                                          label: const Text(
                                              'Registrar consumo depois da festa')),
                                      TextButton.icon(
                                          style: TextButton.styleFrom(
                                              alignment: Alignment.centerLeft,
                                              minimumSize:
                                                  const Size.fromHeight(48),
                                              textStyle: GoogleFonts.poppins(
                                                  fontSize: 13)),
                                          onPressed: () =>
                                              Navigator.pop(ctx, 'historico'),
                                          icon: const Icon(Icons.history,
                                              size: 20),
                                          label: const Text(
                                              'Comparar com meu consumo anterior')),
                                    ],
                                  ])))),
                  if (regra != null) ...[
                    const Divider(height: 1),
                    Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                                style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(48)),
                                onPressed: () => Navigator.pop(ctx, 'editar'),
                                child: const Text('Ajustar porção ou preço')))),
                  ],
                ]),
              ),
            )));
    if (editar == 'editar' && mounted) {
      await _editarRegra(
          item: c.revisarCardapio.value ? menu : null, regra: regra);
    }
    if (editar == 'consumo' && mounted && regra != null) {
      await _registrarConsumo(regra);
    }
    if (editar == 'historico' && mounted && regra != null) {
      await _consultarConsumoAnterior(regra);
    }
  }

  Future<void> _registrarConsumo(ItemEstimativaFinanceira regra) async {
    final c = calculadoraController;
    if (!c.possuiEventoVinculado) {
      Get.snackbar(
          'Vincule um evento', 'Salve o evento antes de registrar o consumo.');
      return;
    }
    final efetiva = c.itensCalculados
        .where((i) => i.idItemResultado == '${i.idCalculo}_${regra.id}');
    if (efetiva.isNotEmpty) regra = c.regraDoResultado(efetiva.first) ?? regra;
    if (!['cru', 'seco', 'pronto'].contains(regra.premissas['estado']) ||
        !['principal', 'acompanhamento', 'bebida', 'outro']
            .contains(regra.premissas['papel_na_refeicao'])) {
      Get.snackbar('Defina o contexto do alimento',
          'Informe o estado e o papel na refeição antes de comparar o consumo.');
      await _editarRegra(regra: regra);
      return;
    }
    final assinaturaRegistro = jsonEncode(c.snapshotPlanejamento);
    final eventoRegistro = c.idEventoAtual.value;
    RegistroConsumoCalculadora? anterior;
    try {
      final registros = (await c.consultarConsumos())
          .where((r) =>
              r.idEvento == c.idEventoAtual.value &&
              r.regra.id == regra.id &&
              r.contexto ==
                  c.contextoConsumo(regra, duracaoObservada: r.duracaoHoras))
          .toList()
        ..sort((a, b) => b.dataRegistro.compareTo(a.dataRegistro));
      if (registros.isNotEmpty) anterior = registros.first;
    } catch (_) {/* Manual entry remains available when history cannot load. */}
    if (!mounted ||
        eventoRegistro != c.idEventoAtual.value ||
        assinaturaRegistro != jsonEncode(c.snapshotPlanejamento)) {
      return;
    }
    final salvo = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => CalculadoraConsumoDialog(
            idEvento: c.idEventoAtual.value,
            regra: regra,
            anterior: anterior,
            contexto: c.contextoConsumo,
            onSalvar: (registro) async {
              if (assinaturaRegistro != jsonEncode(c.snapshotPlanejamento) ||
                  c.usandoContextoHistorico.value) {
                throw StateError('O planejamento mudou.');
              }
              await c.registrarConsumo(registro);
            }));
    if (salvo == true) {
      Get.snackbar('Consumo registrado',
          'As quantidades observadas foram salvas separadamente da estimativa.');
    }
  }

  Future<void> _consultarConsumoAnterior(ItemEstimativaFinanceira regra) async {
    final c = calculadoraController;
    final efetiva = c.itensCalculados
        .where((i) => i.idItemResultado == '${i.idCalculo}_${regra.id}');
    if (efetiva.isNotEmpty) regra = c.regraDoResultado(efetiva.first) ?? regra;
    final receitaDefinida =
        regra.premissas['receita']?.toString().trim().isNotEmpty == true;
    final evento = c.idEventoAtual.value, contexto = c.contextoConsumo(regra);
    final dadosConsultados = jsonEncode(c.snapshotPlanejamento);
    try {
      final registros = await c.consultarConsumos();
      if (!mounted || evento != c.idEventoAtual.value) return;
      final destaFesta = registros
          .where((r) => r.idEvento == evento && r.regra.id == regra.id)
          .toList()
        ..sort((a, b) => b.dataRegistro.compareTo(a.dataRegistro));
      final medidaRegistrada = destaFesta.isEmpty
          ? ''
          : (destaFesta.first.regra.premissas['unidade_consumo'] ??
                  destaFesta.first.regra.unidade.label)
              .toString();
      final resumo = c.resumirConsumo(regra, registros);
      final medida = regra.premissas['unidade_consumo'] ?? regra.unidade.label;
      final mediana = resumo.mediana;
      final adotar = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
                  title: const Text('Seu histórico de consumo'),
                  content: SingleChildScrollView(
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        if (destaFesta.isNotEmpty) ...[
                          const Text(
                              'Último registro encontrado desta festa (fora da amostra):',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          Text(
                              'Receita: ${destaFesta.first.regra.premissas['receita']}. '
                              'Disponibilizado pronto: ${destaFesta.first.disponibilizado} $medidaRegistrada; '
                              'sobra: ${destaFesta.first.sobra} $medidaRegistrada; desperdício: ${destaFesta.first.desperdicio} $medidaRegistrada. '
                              '${destaFesta.first.faltou ? 'Houve falta.' : 'Sem falta informada.'}'),
                          const SizedBox(height: 12),
                        ],
                        if (!receitaDefinida)
                          const Text(
                              'Defina a identificação da receita na edição da porção para comparar com eventos anteriores.'),
                        Text(
                            '${resumo.amostras.length} evento(s) comparável(is), entre as 100 simulações com consumo mais recentemente registrado.'),
                        const Text(
                            'Compara receita, papel, estado, refeição, tipo de evento, duração, cardápio, serviços, pesos de público e proporção etária. A festa atual e simulações repetidas do mesmo evento não contam como novas amostras.'),
                        if (!resumo.podeAdotar)
                          const Text(
                              'A adoção exige ao menos 3 eventos comparáveis sem falta. Registros antigos sem a composição completa não são adotados automaticamente.'),
                        if (resumo.minimo != null && resumo.maximo != null)
                          Text(
                              'Porções observadas: ${resumo.minimo!.toStringAsFixed(3)} a ${resumo.maximo!.toStringAsFixed(3)} $medida. Faixa medida, sem garantia preditiva.'),
                        if (mediana != null)
                          Text(
                              'Mediana para preparo: ${mediana.toStringAsFixed(3)} $medida por adulto equivalente por serviço, antes da reserva. Base: disponibilizado menos sobra não servida, preservando o desperdício nos pratos.'),
                        Text(
                            'Critérios: últimos 365 dias; pelo menos 3 eventos distintos com data de consumo. ${resumo.antigos} antigo(s), ${resumo.semData} sem data e ${resumo.futuros} com data futura não usados.'),
                        if (resumo.atipicos > 0)
                          Text(
                              '${resumo.atipicos} valor(es) atípico(s): revise os registros antes de adotar a mediana. Nenhum valor foi corrigido automaticamente.'),
                        Text(
                            'Avaliação em ordem temporal: ${resumo.eventosAvaliados} evento(s), ${resumo.faltasAvaliadas} com falta. Cada previsão usa apenas eventos anteriores.'),
                        if (resumo.erroMedianoPercentual != null)
                          Text(
                              'Erro absoluto mediano retrospectivo da porção: ${resumo.erroMedianoPercentual!.toStringAsFixed(1)}%. Não representa probabilidade de falta.'),
                        if (resumo.eventosComFalta > 0)
                          Text(
                              '${resumo.eventosComFalta} evento(s) comparável(is) tiveram falta. A adoção automática da mediana está bloqueada; revise porções e causas.'),
                        if (mediana == null)
                          const Text(
                              'Sem medições compatíveis suficientes para calcular uma porção observada. Registre o consumo após os eventos; nenhum coeficiente será inventado.'),
                        const Text(
                            'A mediana descreve os registros consultados. Não é uma garantia de suficiência. Ao adotar, a reserva permanece; fatores genéricos de perfil e duração deixam de alterar esta porção.'),
                      ])),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Manter porção')),
                    if (resumo.podeAdotar)
                      FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Usar porção observada'))
                  ]));
      if (adotar == true &&
          mounted &&
          evento == c.idEventoAtual.value &&
          dadosConsultados == jsonEncode(c.snapshotPlanejamento) &&
          contexto == c.contextoConsumo(regra)) {
        c.adotarConsumoObservado(regra, resumo);
      }
    } catch (_) {
      Get.snackbar('Histórico indisponível',
          'Não foi possível consultar seus registros. Tente novamente; a porção atual foi preservada.');
    }
  }

  Future<void> _compararCenarioEconomico() async {
    final c = calculadoraController;
    final propostos = c.simularPerfil(PerfilFesta.economico());
    final precosCompletos = propostos.isNotEmpty &&
        propostos.every((i) => i.valorUnitarioMedio > 0) &&
        c.itensSemRegra.isEmpty &&
        c.regrasRejeitadas.isEmpty;
    final adotar = await showDialog<bool>(
        context: context,
        builder: (ctx) => Theme(
            data: themeController.materialTheme,
            child: _PlanejamentoDialog(
              title: 'Comparar porções e reserva',
              icon: Icons.compare_arrows_rounded,
              primary: themeController.primaryColor.value,
              confirmLabel: 'Usar cenário econômico',
              cancelLabel: 'Manter atual',
              onCancel: () => Navigator.pop(ctx),
              onConfirm: () => Navigator.pop(ctx, true),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: precosCompletos
                                ? const Color(0xFFF1F6F2)
                                : const Color(0xFFFFF7E8),
                            borderRadius: BorderRadius.circular(12)),
                        child: precosCompletos
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Text(
                                        'Estimativa atual: ${c.custoTotalEstimadoFormatado}'),
                                    const SizedBox(height: 4),
                                    Text(
                                        'Proposta: ${_money(propostos.fold<double>(0, (s, i) => s + i.custoEstimado))}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700)),
                                  ])
                            : const Text(
                                'Economia indisponível: faltam preços ou regras. Valores ausentes não representam custo zero.',
                                style: TextStyle(
                                    fontSize: 12, color: Color(0xFF80591A)))),
                    const SizedBox(height: 12),
                    const Text(
                        'Confira as porções antes de adotar. Esta simulação não comprova que haverá comida suficiente.',
                        style: TextStyle(fontSize: 12)),
                    Theme(
                        data: themeController.materialTheme
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            minTileHeight: 48,
                            title: const Text('O que muda neste cenário',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                            children: const [
                              Padding(
                                  padding: EdgeInsets.only(bottom: 12),
                                  child: Text(
                                      'A opção Econômico usa 5% de reserva. A redução de 10% só vale para itens que usam o ajuste do perfil. '
                                      'Referências contextuais e porções observadas mantêm sua base.',
                                      style: TextStyle(
                                          fontSize: 12, height: 1.45)))
                            ])),
                    for (final item in propostos) ...[
                      const Divider(height: 1, color: Color(0xFFE8EDF2)),
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(item.nome,
                                    style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF172B21))),
                                const SizedBox(height: 6),
                                Wrap(
                                    alignment: WrapAlignment.spaceBetween,
                                    spacing: 12,
                                    runSpacing: 6,
                                    children: [
                                      Text(
                                          'Proposta: ${item.quantidadeFormatada}',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: themeController
                                                  .primaryColor.value)),
                                      Text(
                                          item.valorUnitarioMedio > 0
                                              ? item.custoEstimadoFormatado
                                              : 'Preço pendente',
                                          style: const TextStyle(fontSize: 12)),
                                    ]),
                              ])),
                    ],
                  ]),
            )));
    if (adotar == true && mounted) {
      c.aplicarPerfilPlanejamento(PerfilFesta.economico());
    }
  }

  Widget _buildProximasAcoes(Color primary) {
    final c = calculadoraController;
    return _SectionCard(
        title: 'Próximas ações',
        icon: Icons.task_alt,
        primary: primary,
        child: TextButtonTheme(
            data: TextButtonThemeData(
                style: TextButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    foregroundColor: primary,
                    textStyle: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w500),
                    minimumSize: const Size.fromHeight(48),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 10))),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProximaDecisao(primary),
                  const SizedBox(height: 8),
                  ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text('Outras opções',
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      children: [
                        if (c.itensCardapio.isNotEmpty)
                          TextButton.icon(
                              onPressed: _reutilizarReceita,
                              icon: const Icon(Icons.menu_book_outlined),
                              label:
                                  const Text('Reutilizar uma receita salva')),
                        if (c.possuiResultado) ...[
                          TextButton.icon(
                              onPressed: () => _abrirListaCompras(evento: true),
                              icon: const Icon(Icons.shopping_cart_outlined),
                              label:
                                  const Text('Ver compras da festa inteira')),
                          TextButton.icon(
                              onPressed: _abrirAnaliseRefeicao,
                              icon: const Icon(Icons.restaurant_outlined),
                              label:
                                  const Text('Conferir a refeição completa')),
                          TextButton.icon(
                              onPressed: _ajustarAoLimite,
                              icon: const Icon(Icons.savings_outlined),
                              label: const Text('Planejar dentro do limite')),
                          TextButton.icon(
                              onPressed: _reduzirVariedade,
                              icon: const Icon(Icons.playlist_remove),
                              label: const Text('Simular menos variedade')),
                          TextButton.icon(
                              onPressed: _simularSubstituicao,
                              icon: const Icon(Icons.swap_horiz),
                              label:
                                  const Text('Simular troca de ingrediente')),
                          TextButton.icon(
                              onPressed: _revisarDepoisDaFesta,
                              icon: const Icon(Icons.fact_check_outlined),
                              label: const Text('Revisão depois da festa')),
                          TextButton.icon(
                              onPressed: _avaliarExperiencia,
                              icon: const Icon(Icons.rate_review_outlined),
                              label: const Text('Avaliar esta experiência')),
                          TextButton.icon(
                              onPressed: () async {
                                final item = await _selecionarItemCalibracao(
                                    'Calibrar porções para esta refeição');
                                if (item == null || !mounted) return;
                                final regra = c.regraDoResultado(item);
                                if (regra == null) return;
                                await _editarRegra(
                                    regra: regra,
                                    item: c.revisarCardapio.value
                                        ? const RevisaoCardapioService()
                                            .correspondente(
                                                item, c.itensCardapio)
                                        : null);
                              },
                              icon: const Icon(Icons.restaurant_menu),
                              label:
                                  const Text('Calibrar porções do cardápio')),
                          TextButton.icon(
                              onPressed: () async {
                                final item = await _selecionarItemCalibracao(
                                    'Qual item você mediu depois da festa?');
                                if (item == null || !mounted) return;
                                final regra = c.regraDoResultado(item);
                                if (regra != null) {
                                  await _registrarConsumo(regra);
                                }
                              },
                              icon: const Icon(Icons.fact_check_outlined),
                              label: const Text(
                                  'Registrar consumo, sobra e falta')),
                        ],
                        if (c.itensCalculados
                            .any((i) => i.valorUnitarioMedio <= 0))
                          TextButton.icon(
                              onPressed: () => _abrirDetalhesItem(
                                  c.itensCalculados.firstWhere(
                                      (i) => i.valorUnitarioMedio <= 0)),
                              icon: const Icon(Icons.payments_outlined),
                              label: const Text(
                                  'Informar o próximo preço pendente')),
                        if (c.compromissosOrcamento.isNotEmpty)
                          TextButton.icon(
                              onPressed: _revisarCoberturas,
                              icon: const Icon(Icons.link),
                              label: const Text(
                                  'Conferir cobertura dos serviços')),
                        if (c.possuiResultado)
                          TextButton.icon(
                              onPressed: _compararCenarioEconomico,
                              icon: const Icon(Icons.compare_arrows),
                              label: const Text('Comparar porções e reserva')),
                      ]),
                ])));
  }

  Future<CalculadoraFestaItem?> _selecionarItemCalibracao(String titulo) =>
      showModalBottomSheet<CalculadoraFestaItem>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          showDragHandle: true,
          builder: (ctx) => SafeArea(
              top: false,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(ctx).height * .7),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                      child: Row(children: [
                        Expanded(
                            child: Text(titulo,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700))),
                        IconButton(
                            tooltip: 'Fechar',
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close_rounded)),
                      ])),
                  const Divider(height: 1),
                  Flexible(
                      child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount:
                              calculadoraController.itensCalculados.length,
                          separatorBuilder: (_, __) => const Divider(
                              height: 1, indent: 16, endIndent: 16),
                          itemBuilder: (_, index) {
                            final i =
                                calculadoraController.itensCalculados[index];
                            return ListTile(
                                title: Text(i.nome,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                                subtitle: Text(i.quantidadeFormatada,
                                    style: const TextStyle(fontSize: 13)),
                                trailing:
                                    const Icon(Icons.chevron_right, size: 20),
                                onTap: () => Navigator.pop(ctx, i));
                          })),
                ]),
              )));

  Widget _buildDiagnostico(Color primary) {
    final c = calculadoraController;
    final d = c.diagnosticoPlanejamento;
    return CalculadoraDiagnosticoCard(
      diagnostico: d,
      primary: primary,
      cardapioDisponivel: c.cardapioDisponivel.value,
      revisando: c.revisarCardapio.value,
      carregando: c.carregandoItensBase.value,
      semCatalogo: c.origemItensCalculadora.value ==
          OrigemItensCalculadora.semConfiguracao,
      erroCatalogo: c.podeTentarCarregarBase ? c.erroItensBase.value : '',
      regrasRejeitadas: c.regrasRejeitadas.toList(),
      financeiroIncompleto: c.coberturaFinanceiraIncompleta,
      onInformarPessoas: _mostrarPessoas,
      onRevisar: () => c.alterarModoCardapio(true),
      onConfigurar: () => _editarRegra(item: d.semRegra.first),
      onAdicionar: () => _editarRegra(),
    );
  }

  Widget _buildPlanejamentoCard(Color primary) {
    final c = calculadoraController;
    final financeiro = c.contextoPlanejamento;
    return _SectionCard(
        title: 'Planejamento',
        icon: Icons.calculate_outlined,
        primary: primary,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Ajustes avançados do cálculo',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            children: [
              const Text('Como você quer planejar?',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155))),
              const SizedBox(height: 12),
              _ModoPlanejamento(
                  titulo: 'Estimar do zero',
                  descricao: 'Escolha os itens e as porções.',
                  icon: Icons.auto_awesome_outlined,
                  primary: primary,
                  selecionado: !c.revisarCardapio.value,
                  onTap: () => c.alterarModoCardapio(false)),
              const SizedBox(height: 8),
              _ModoPlanejamento(
                  titulo: 'Revisar meu cardápio',
                  descricao: c.cardapioDisponivel.value
                      ? 'Compare quantidades e ajuste porções.'
                      : 'Selecione um cardápio abaixo e aguarde os itens.',
                  icon: Icons.restaurant_menu_rounded,
                  primary: primary,
                  selecionado: c.revisarCardapio.value,
                  onTap: c.cardapioDisponivel.value
                      ? () => c.alterarModoCardapio(true)
                      : null),
              const SizedBox(height: 12),
              if (c.revisarCardapio.value) ...[
                for (final item in c.itensCardapio)
                  ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.nome,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      visualDensity: VisualDensity.compact,
                      subtitle: Text(const RevisaoCardapioService()
                                  .regraPara(item, c.regrasDisponiveis) ==
                              null
                          ? 'Definir porção'
                          : '${const RevisaoCardapioService().regraPara(item, c.regrasDisponiveis)!.porcaoReferenciaFormatada} / adulto equivalente / serviço'),
                      trailing: const Icon(Icons.edit_outlined, size: 20),
                      onTap: () => _editarRegra(
                          item: item,
                          regra: const RevisaoCardapioService()
                              .regraPara(item, c.regrasDisponiveis))),
              ] else ...[
                TextButton.icon(
                    onPressed: () => _editarRegra(),
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar item manual')),
                for (final regra in c.regrasManuais
                    .where((item) => !item.id.startsWith('menu_')))
                  ListTile(
                      title: Text(regra.nome),
                      trailing: const Icon(Icons.edit_outlined, size: 20),
                      onTap: () => _editarRegra(regra: regra)),
              ],
              const SizedBox(height: 12),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Resumo financeiro',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: Color(0xFF334155))),
              const SizedBox(height: 10),
              if (c.carregandoOrcamento.value) const LinearProgressIndicator(),
              if (c.erroOrcamento.value.isNotEmpty) ...[
                Text(c.erroOrcamento.value),
                TextButton(
                    onPressed: c.carregarContextoOrcamento,
                    child: const Text('Consultar gastos novamente')),
              ] else ...[
                _valorPlanejamento(
                    'Já orçado', financeiro['gastos_existentes'] as num),
                _valorPlanejamento(
                    'Contratado', financeiro['total_contratado'] as num),
                _valorPlanejamento('Pago', financeiro['total_pago'] as num),
                if (c.possuiResultado) ...[
                  _valorPlanejamento('Pagamentos pendentes',
                      c.resumoCompras.pagamentosPendentes),
                  if (c.resumoCompras.custoIndefinido)
                    const Text('Compras restantes: custo em conferência',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600))
                  else
                    _valorPlanejamento(
                        'Compras da festa${c.resumoCompras.completo ? '' : ' (parcial)'}',
                        c.resumoCompras.custoConhecido),
                  if (c.resumoCompras.saldoAposCompras != null)
                    _valorPlanejamento('Saldo após compras',
                        c.resumoCompras.saldoAposCompras!),
                  if (!c.resumoCompras.completo)
                    Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                            '${c.resumoCompras.quantidadesPendentes} quantidade(s) e ${c.resumoCompras.precosPendentes} preço(s) pendentes. '
                            '${c.resumoCompras.comprasSemRegistro > 0 ? '${c.resumoCompras.comprasSemRegistro} compra(s) sem custo vinculado no orçamento. ' : ''}'
                            '${c.resumoCompras.sobreposicao ? 'Há possível sobreposição com o orçamento. ' : ''}'
                            '${!c.resumoCompras.consultaCompleta ? 'A consulta financeira está incompleta. ' : ''}'
                            'O saldo consolidado só aparece quando essas conferências estiverem completas.',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF80591A)))),
                ],
              ],
            ]),
          ),
          if (c.compromissosOrcamento.isNotEmpty)
            TextButton.icon(
                onPressed: _conferirCustos,
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Conferir custos já orçados')),
          TextButton.icon(
              onPressed: _editarLimiteOrcamento,
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: Text(c.orcamentoDisponivel.value == null
                  ? 'Informar limite total da festa'
                  : 'Limite total: ${_money(c.orcamentoDisponivel.value!)}')),
        ]));
  }

  Widget _valorPlanejamento(String label, num valor) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: LayoutBuilder(builder: (context, constraints) {
        final ampliado = MediaQuery.textScalerOf(context).scale(14) > 19;
        final labelWidget = Text(label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF526259)));
        final valueWidget = Text(_money(valor),
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF172B21)));
        return ampliado
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [labelWidget, valueWidget])
            : Row(children: [
                Expanded(child: labelWidget),
                const SizedBox(width: 8),
                valueWidget
              ]);
      }));

  String _money(num valor) => _formatMoney(valor.toDouble());

  Future<void> _editarLimiteOrcamento() async {
    final resultado = await showDialog<double>(
        context: context,
        builder: (_) => CalculadoraLimiteOrcamentoDialog(
            valor: calculadoraController.orcamentoDisponivel.value));
    if (resultado != null && mounted) {
      try {
        await calculadoraController
            .salvarLimitePlanejamento(resultado < 0 ? null : resultado);
      } catch (_) {
        Get.snackbar('Limite não salvo',
            'Não foi possível atualizar o limite da festa. Tente novamente.');
      }
    }
  }

  Future<List<CalculadoraFestaItem>?> _revisarEnvioCardapio(
      List<CalculadoraFestaItem> resultados) async {
    final selecionados = resultados.map((item) => item.idItemResultado).toSet();
    final existentes = calculadoraController.itensCardapio.toList();
    return showModalBottomSheet<List<CalculadoraFestaItem>>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, atualizar) => SafeArea(
                    child: SizedBox(
                  height: MediaQuery.sizeOf(ctx).height * .75,
                  child: Column(children: [
                    const ListTile(
                        title: Text('Revisar sugestões para o cardápio'),
                        subtitle: Text(
                            'Atualiza apenas sugestões. Quantidades finais e confirmações serão preservadas. Novos itens ficam sem quantidade final até sua revisão.')),
                    Expanded(
                        child: ListView(
                            children: resultados.map((item) {
                      final atual = const RevisaoCardapioService()
                          .correspondente(item, existentes);
                      final diferenca =
                          item.quantidade - (atual?.quantidadeFinal ?? 0);
                      return CheckboxListTile(
                          value: selecionados.contains(item.idItemResultado),
                          title:
                              Text('${item.nome}: ${item.quantidadeFormatada}'),
                          subtitle: Text(atual != null &&
                                  atual.unidade != item.unidade
                              ? 'Item sem quantidade final: unidade proposta ${atual.unidade} → ${item.unidade}. Ao aplicar, ajusta a unidade e mantém a quantidade final em zero.'
                              : atual == null
                                  ? 'Novo item — quantidade final ainda não definida'
                                  : 'Planejado: ${atual.quantidadeFinal} ${atual.unidade}. ${diferenca > 0 ? 'Faltam' : diferenca < 0 ? 'Excesso de' : 'Sem ajuste:'} ${diferenca.abs().toStringAsFixed(2)} ${item.unidade}'),
                          onChanged: (marcado) => atualizar(() {
                                if (marcado == true) {
                                  selecionados.add(item.idItemResultado);
                                } else {
                                  selecionados.remove(item.idItemResultado);
                                }
                              }));
                    }).toList())),
                    Padding(
                        padding: const EdgeInsets.all(16),
                        child: FilledButton(
                            onPressed: selecionados.isEmpty
                                ? null
                                : () => Navigator.pop(
                                    ctx,
                                    resultados
                                        .where((item) => selecionados
                                            .contains(item.idItemResultado))
                                        .toList()),
                            child:
                                const Text('Aplicar sugestões selecionadas'))),
                  ]),
                ))));
  }
}
