part of '../pages/calculadora_festa_screen.dart';

extension _CalculadoraFestaCompras on _CalculadoraFestaScreenState {
  ItemListaCompras? get _pendenciaCompra {
    final itens = calculadoraController.listaCompras;
    for (final situacao in [
      SituacaoCompra.planejarIngredientes,
      SituacaoCompra.revisarPorcao,
      SituacaoCompra.revisarDisponibilidade,
      SituacaoCompra.revisarServico,
      SituacaoCompra.informarDisponibilidade
    ]) {
      for (final item in itens) {
        if (item.situacao == situacao) return item;
      }
    }
    return null;
  }

  Widget _buildProximaDecisao(Color primary) {
    final c = calculadoraController;
    final semRegra = c.itensSemRegra;
    final pendencia = _pendenciaCompra;
    final refeicaoPendente = c.analiseRefeicao.precisaRevisar;
    final faltaPreco = c.resumoCompras.precosPendentes > 0;
    final excedeLimite = (c.resumoCompras.saldoAposCompras ?? 0) < 0;
    final depois = _eventoEncerrado && !c.usandoContextoHistorico.value;
    final revisada = OperacaoCalculadoraService.mapa(
        OperacaoCalculadoraService.mapa(c.operacaoEvento['revisao_pos_evento'])[c.idCardapioAtual])['status'] == 'concluida';
    final texto = depois
        ? (revisada
            ? 'Revisão desta refeição concluída. Você pode corrigir os resultados ou acrescentar medições. Despesas pendentes continuam no orçamento.'
            : 'A festa já passou. Conte o que sobrou ou faltou; medições de quantidades são opcionais.')
        : semRegra.isNotEmpty
            ? 'Defina a porção de ${semRegra.first.nome} para incluir este item no cálculo.'
            : pendencia != null
                ? '${pendencia.resultado.nome}: ${pendencia.orientacao}'
                : refeicaoPendente
                    ? 'Confira a composição da refeição e como os alimentos serão consumidos em conjunto.'
                    : faltaPreco
                        ? 'As quantidades estão organizadas. Informe os preços que faltam para avaliar os gastos.'
                        : excedeLimite
                            ? 'O planejamento excede o limite informado. Compare as opções antes de comprar.'
                            : 'Confira sua lista de compras antes de sair para comprar.';
    return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: primary.withValues(alpha: .05),
            borderRadius: BorderRadius.circular(12)),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('O que resolver agora',
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(texto,
              style: GoogleFonts.poppins(
                  fontSize: 12, height: 1.45, color: const Color(0xFF475569))),
          Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  onPressed: () async {
                    if (depois) {
                      await _revisarDepoisDaFesta();
                    } else if (semRegra.isNotEmpty) {
                      await _editarRegra(item: semRegra.first);
                    } else if (pendencia != null) {
                      await _resolverCompra(pendencia);
                    } else if (refeicaoPendente) {
                      await _abrirAnaliseRefeicao();
                    } else if (faltaPreco) {
                      await _abrirListaCompras(evento: true);
                    } else if (excedeLimite) {
                      await _ajustarAoLimite();
                    } else {
                      await _abrirListaCompras();
                    }
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text(
                      depois
                          ? 'Revisar depois da festa'
                          : semRegra.isNotEmpty
                              ? 'Definir porção'
                              : pendencia?.titulo ??
                                  (refeicaoPendente
                                      ? 'Conferir refeição completa'
                                      : excedeLimite
                                          ? 'Rever limite e compras'
                                          : 'Conferir planejamento'),
                      style: GoogleFonts.poppins(
                          fontSize: 12, fontWeight: FontWeight.w600)))),
        ]));
  }

  Future<void> _resolverCompra(ItemListaCompras item) async {
    final c = calculadoraController;
    if (c.usandoContextoHistorico.value) {
      Get.snackbar('Simulação salva',
          'Atualize os dados da festa antes de registrar compras ou alterar serviços.');
      return;
    }
    switch (item.situacao) {
      case SituacaoCompra.planejarIngredientes:
        if (c.usandoContextoHistorico.value || c.estimativaSemEvento.value) {
          Get.snackbar('Atualize o evento',
              'Abra o planejamento atual do evento para organizar a execução.');
          return;
        }
        await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (_) => Theme(
                data: themeController.materialTheme,
                child: CalculadoraExecucaoDialog(controller: c)));
        return;
      case SituacaoCompra.revisarPorcao:
        await _editarRegra(
            regra: item.regra,
            item: c.revisarCardapio.value ? item.cardapio : null);
      case SituacaoCompra.revisarServico:
        Get.snackbar('Confira o serviço no Orçamento',
            'Verifique a contratação ou corrija quais itens estão incluídos.');
        await _revisarCoberturas();
      default:
        final menu = item.cardapio;
        if (menu == null) {
          Get.snackbar('Vincule ao cardápio',
              'Use Revisar e aplicar para vincular o item antes de registrar o que já tem.');
          return;
        }
        final assinatura = jsonEncode(c.snapshotPlanejamento);
        await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) => Theme(
                data: themeController.materialTheme,
                child: DisponibilidadeCardapioDialog(
                    item: menu,
                    unidade: item.resultado.unidade,
                    estado:
                        item.regra?.premissas['estado_compra']?.toString() ??
                            item.regra?.premissas['estado']?.toString(),
                    onSalvar: (registro) async {
                      if (c.usandoContextoHistorico.value ||
                          assinatura != jsonEncode(c.snapshotPlanejamento)) {
                        throw StateError('O planejamento mudou.');
                      }
                      final atuais = cardapioController
                          .itensDoCardapio(menu.idCardapio)
                          .where((i) => i.idItem == menu.idItem);
                      if (atuais.length != 1 ||
                          atuais.single.nome != menu.nome ||
                          atuais.single.publicoAlvo != menu.publicoAlvo) {
                        throw StateError('O item mudou.');
                      }
                      await cardapioController.atualizarItem(menu.idCardapio,
                          atuais.single.copyWith(disponibilidade: registro));
                    })));
    }
  }

  String _textoListaCompras({bool evento = false}) {
    final c = calculadoraController;
    final linhas = <String>[
      'Lista de compras — ${evento ? 'Festa inteira' : c.tituloCardapio}',
      if (evento)
        'Público específico por refeição quando configurado; demais refeições usam o público da festa. Estoque descontado pelas reservas centrais.',
      if (c.usandoContextoHistorico.value)
        'SIMULAÇÃO SALVA — atualize antes de comprar.',
      if (c.erroOrcamento.value.isNotEmpty ||
          c.carregandoOrcamento.value ||
          c.coberturaFinanceiraIncompleta)
        'Lista preliminar: confira a cobertura dos serviços.',
      'Quantidades de planejamento; confira as porções e a disponibilidade.',
      ...c.analiseRefeicao.pendencias.map((p) => 'Conferir refeição: $p'),
      ...c.pendenciasAlimentaresEvento.map((p) => 'Conferir alimentação: $p')
    ];
    for (final item in evento ? c.listaComprasEvento : c.listaCompras) {
      linhas.add(
          '${evento ? '${c.titulosCardapiosEvento[item.cardapio?.idCardapio] ?? item.cardapio?.idCardapio ?? c.tituloCardapio} · ' : ''}${item.resultado.nome}: ${item.titulo}'
          '${item.falta == null ? '' : ' — ${item.quantidade(item.falta!)}'}'
          '${item.embalagens == null || item.embalagens == 0 ? '' : ' (${item.embalagens} embalagem(ns))'}.'
          '${item.servicos.isEmpty ? '' : ' ${item.servicos.join(', ')}.'}'
          '${item.precisaConferir ? ' ${item.orientacao}' : ''}');
    }
    for (final item in evento ? c.itensSemRegraEvento : c.itensSemRegra) {
      linhas
          .add('${item.nome}: definir porção; quantidade ainda não calculada.');
    }
    return linhas.join('\n');
  }

  Future<void> _abrirListaCompras({bool evento = false}) async {
    final c = calculadoraController;
    c.medicaoUso.abrirLista(
        c.listaCompras.where((i) => i.precisaConferir).length +
            c.itensSemRegra.length);
    final escolha = await showDialog<Object>(
        context: context,
        builder: (ctx) => Theme(
            data: themeController.materialTheme,
            child: Obx(() {
              final lista = evento ? c.listaComprasEvento : c.listaCompras;
              final semRegra = evento ? c.itensSemRegraEvento : c.itensSemRegra;
              final pendentes = lista.where((i) => i.precisaConferir).length +
                  semRegra.length;
              return _PlanejamentoDialog(
                  title: evento
                      ? 'Compras da festa inteira'
                      : 'Sua lista de compras',
                  icon: Icons.shopping_bag_outlined,
                  primary: themeController.primaryColor.value,
                  confirmLabel: 'Copiar lista',
                  cancelLabel: 'Voltar',
                  onCancel: () => Navigator.pop(ctx),
                  onConfirm: () async {
                    await Clipboard.setData(ClipboardData(
                        text: _textoListaCompras(evento: evento)));
                    c.medicaoUso.listasCopiadas++;
                    if (ctx.mounted) Navigator.pop(ctx);
                    Get.snackbar('Lista copiada',
                        'As pendências também foram incluídas para você conferir.');
                  },
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                            lista.any(
                                    (i) => i.situacao == SituacaoCompra.comprar)
                                ? '${lista.where((i) => i.situacao == SituacaoCompra.comprar).length} para comprar · $pendentes para conferir'
                                : pendentes > 0
                                    ? '$pendentes itens precisam de conferência'
                                    : 'Sem compra pendente nos itens calculados',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        const Text(
                            'Planejado, comprado e incluído em serviço são informações diferentes. Só descontamos o que foi registrado para esta refeição.',
                            style: TextStyle(fontSize: 12)),
                        if (evento)
                          const Text(
                              'Cada refeição usa seu público específico, ou herda o público da festa. As reservas centrais impedem destinar o mesmo saldo duas vezes.'),
                        if (evento && !c.consultaCardapiosCompleta.value)
                          const Text(
                              'Ainda há cardápios em carregamento. Não conclua compras antes da conferência.'),
                        if (c.usandoContextoHistorico.value)
                          const Text(
                              'Simulação salva: atualize os dados da festa antes de comprar.',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF80591A))),
                        if (c.erroOrcamento.value.isNotEmpty ||
                            c.carregandoOrcamento.value ||
                            c.coberturaFinanceiraIncompleta)
                          const Text(
                              'Lista preliminar: confira também a cobertura dos serviços.',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF80591A))),
                        for (final aviso in c.pendenciasAlimentaresEvento)
                          Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(aviso,
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFF80591A)))),
                        if (c.analiseRefeicao.precisaRevisar) ...[
                          const SizedBox(height: 8),
                          const Text(
                              'A composição da refeição também precisa de conferência.',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF80591A))),
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, 'refeicao'),
                              child: const Text('Conferir refeição completa')),
                        ],
                        const SizedBox(height: 12),
                        for (final item in lista) ...[
                          const Divider(height: 1),
                          Padding(
                              key: ValueKey(
                                  'lista_compra_${item.resultado.nome}'),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (evento)
                                      Text(
                                          c.titulosCardapiosEvento[
                                                  item.cardapio?.idCardapio] ??
                                              item.cardapio?.idCardapio ??
                                              c.tituloCardapio,
                                          style: const TextStyle(fontSize: 12)),
                                    Text(item.resultado.nome,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700)),
                                    Text(item.base,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF526259))),
                                    const SizedBox(height: 6),
                                    Text(
                                        '${item.titulo}${item.falta == null ? '' : ': ${item.quantidade(item.falta!)}'}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: item.precisaConferir
                                                ? const Color(0xFF80591A)
                                                : themeController
                                                    .primaryColor.value)),
                                    if (item.embalagens != null &&
                                        item.embalagens! > 0)
                                      Text(
                                          '${item.embalagens} embalagem(ns) de ${item.quantidade(item.regra!.tamanhoEmbalagem)}'),
                                    if (item.preparo != null &&
                                        !item.precisaConferir &&
                                        item.situacao !=
                                            SituacaoCompra.incluido)
                                      Text(
                                          '${item.estadoPreparo == 'pronto' ? 'Para servir' : 'Base do preparo (${item.estadoPreparo})'}: ${item.quantidade(item.preparo!)}',
                                          style: const TextStyle(fontSize: 12)),
                                    Text(
                                        '${item.precisaConferir ? 'Referência calculada (a conferir)' : 'Compra total estimada'}: ${item.resultado.quantidadeFormatada}',
                                        style: const TextStyle(fontSize: 12)),
                                    if ([
                                          SituacaoCompra.comprar,
                                          SituacaoCompra.disponivel
                                        ].contains(item.situacao) &&
                                        item.cardapio?.disponibilidade !=
                                            null &&
                                        ![
                                          SituacaoCompra.revisarDisponibilidade,
                                          SituacaoCompra.incluido
                                        ].contains(item.situacao))
                                      Text(
                                          'Comprado: ${item.quantidade(item.cardapio!.disponibilidade!.comprado)} · estoque central por destino na tela de reservas.',
                                          style: const TextStyle(fontSize: 12)),
                                    if (item.falta != null && item.falta! > 0)
                                      Text(
                                          item.resultado.valorUnitarioMedio > 0
                                              ? 'Compra pendente estimada: ${_money(item.falta! * item.resultado.valorUnitarioMedio)}'
                                              : 'Informe o preço para estimar esta compra.',
                                          style: const TextStyle(fontSize: 12)),
                                    if (item.servicos.isNotEmpty)
                                      Text(item.servicos.join(', ')),
                                    Text(item.orientacao,
                                        style: const TextStyle(fontSize: 12)),
                                    Align(
                                        alignment: Alignment.centerLeft,
                                        child: TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, item),
                                            child: Text(
                                                item.precisaConferir
                                                    ? 'Resolver pendência'
                                                    : 'Atualizar o que já tenho',
                                                style: const TextStyle(
                                                    fontSize: 12)))),
                                  ])),
                        ],
                        for (final item in semRegra)
                          ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(item.nome),
                              subtitle:
                                  const Text('Definir porção para calcular'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.pop(ctx, item)),
                      ]));
            })));
    if (!mounted) return;
    if (escolha == 'refeicao') await _abrirAnaliseRefeicao();
    if (escolha is ItemListaCompras) {
      final id = escolha.cardapio?.idCardapio;
      if (id != null &&
          id != idCardapioSelecionado.value &&
          !c.usandoContextoHistorico.value) {
        idCardapioSelecionado.value = id;
        _sincronizarCardapio();
      }
      await _resolverCompra(escolha);
    }
    if (escolha is CardapioItem) {
      if (!c.usandoContextoHistorico.value) {
        idCardapioSelecionado.value = escolha.idCardapio;
        _sincronizarCardapio();
      }
      await _editarRegra(item: escolha);
    }
  }
}
