import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:app_faca_festa/core/utils/numeric_input.dart';
import 'package:app_faca_festa/domain/entities/orcamento_admin.dart';
import 'package:app_faca_festa/presentation/modules/admin/controllers/orcamentos_admin_controller.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/widgets/financeiro_contexto.dart';
import 'package:app_faca_festa/presentation/modules/tema/admin_theme.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/widgets/admin/admin_kit.dart';

class OrcamentosAdminListScreen extends StatefulWidget {
  const OrcamentosAdminListScreen(
      {super.key, required this.controller, required this.themeController});
  final OrcamentosAdminController controller;
  final EventThemeController themeController;
  @override
  State<OrcamentosAdminListScreen> createState() =>
      _OrcamentosAdminListScreenState();
}

class _OrcamentosAdminListScreenState extends State<OrcamentosAdminListScreen> {
  final _busca = TextEditingController();
  String _negociacao = '';
  String _pagamento = '';
  OrcamentosAdminController get c => widget.controller;
  String _moeda(int centavos) => NumericInput.dinheiro(centavos / 100);
  String _contagem(int n, String singular, String plural) =>
      '$n ${n == 1 ? singular : plural}';

  @override
  void initState() {
    super.initState();
    _busca.text = c.busca.value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && c.orcamentos.isEmpty) {
        c.carregarOrcamentosComEventoDetalhes();
      }
    });
  }

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  bool _incluido(OrcamentoAdmin o) {
    final status = o.status.trim().toLowerCase();
    final negociacao = _negociacao.isEmpty || status == _negociacao;
    final pagamento = _pagamento.isEmpty ||
        (_pagamento == 'saldo' && !o.cancelado && o.saldoCentavos > 0) ||
        (_pagamento == 'sem_saldo' && !o.cancelado && o.saldoCentavos == 0);
    return negociacao && pagamento;
  }

  @override
  Widget build(BuildContext context) => Theme(
        data: widget.themeController.adminThemeData,
        child: Scaffold(
          backgroundColor: AdminPalette.surface,
          appBar: AdminBackAppBar(
              title: 'Orçamentos',
              subtitle: 'Planejamento e acompanhamento por evento',
              actions: [
                IconButton(
                    tooltip: 'Atualizar orçamentos',
                    icon:
                        const Icon(Icons.refresh_rounded, color: Colors.white),
                    onPressed: c.carregarOrcamentosComEventoDetalhes),
              ]),
          body: LayoutBuilder(
              builder: (context, box) => Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1440),
                      child: Obx(() {
                        final todos = c.orcamentos.toList();
                        final grupos = GrupoOrcamentosAdmin.agrupar(todos);
                        final visiveis = c.orcamentosFiltrados
                            .where(_incluido)
                            .map((o) => o.id)
                            .toSet();
                        final resultados = grupos
                            .where((g) =>
                                g.itens.any((o) => visiveis.contains(o.id)))
                            .toList();
                        return RefreshIndicator(
                          onRefresh: c.carregarOrcamentosComEventoDetalhes,
                          child: ListView(
                              padding:
                                  EdgeInsets.all(box.maxWidth < 600 ? 16 : 28),
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                Text('Controle dos orçamentos',
                                    style: TextStyle(
                                        fontSize: box.maxWidth < 600 ? 22 : 28,
                                        fontWeight: FontWeight.w800,
                                        color: AdminPalette.ink)),
                                const SizedBox(height: 6),
                                const Text(
                                    'Compare o planejamento do evento com os itens e os pagamentos registrados.',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: AdminPalette.muted)),
                                const SizedBox(height: 20),
                                const FinanceiroAjuda(
                                    titulo: 'Como interpretar os valores',
                                    itens: {
                                      'Planejamento do evento':
                                          'Limite de gastos definido no cadastro do evento. Cada evento é identificado separadamente, mesmo quando os nomes são iguais.',
                                      'Estimativa dos itens':
                                          'Soma dos valores previstos nos itens ativos, inclusive os que ainda estão em negociação. Itens cancelados ficam fora dos resumos.',
                                      'Registrado nos gastos':
                                          'Pagamentos informados nos detalhes dos gastos. Não comprovam recebimento pela plataforma, entrega do serviço ou repasse ao fornecedor.',
                                      'Saldo previsto':
                                          'Diferença entre a estimativa e os pagamentos de cada item. Não representa automaticamente uma dívida contratual.',
                                      'Planejamento e filtros':
                                          'A comparação com o planejamento usa todos os itens ativos do evento. Os filtros abaixo alteram apenas a lista de itens exibida.',
                                    }),
                                const SizedBox(height: 20),
                                if (c.carregando.value)
                                  const LinearProgressIndicator(),
                                if (c.erro.value.isNotEmpty) ...[
                                  AdminEmptyState(
                                      icon: Icons.cloud_off_outlined,
                                      title: 'Orçamentos indisponíveis',
                                      message:
                                          'Não foi possível carregar os dados. Tente atualizar a consulta.',
                                      actionLabel: 'Tentar novamente',
                                      onAction: c
                                          .carregarOrcamentosComEventoDetalhes),
                                ] else if (!c.carregando.value ||
                                    todos.isNotEmpty) ...[
                                  _resumo(todos, grupos.length),
                                  const SizedBox(height: 24),
                                  _filtros(),
                                  const SizedBox(height: 20),
                                  Text(
                                      '${_contagem(resultados.length, 'evento', 'eventos')} · ${_contagem(visiveis.length, 'item', 'itens')} na lista',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          color: AdminPalette.muted)),
                                  const SizedBox(height: 12),
                                  if (resultados.isEmpty)
                                    AdminEmptyState(
                                        icon: Icons.request_quote_outlined,
                                        title: todos.isEmpty
                                            ? 'Nenhum orçamento cadastrado'
                                            : 'Nenhum item nesta busca',
                                        message: todos.isEmpty
                                            ? 'Os itens aparecerão aqui quando forem cadastrados nos eventos.'
                                            : 'Altere a busca ou limpe os filtros para ver outros itens.',
                                        actionLabel: todos.isEmpty
                                            ? null
                                            : 'Limpar filtros',
                                        onAction:
                                            todos.isEmpty ? null : _limpar),
                                  for (final grupo in resultados)
                                    _evento(
                                        grupo,
                                        grupo.itens
                                            .where(
                                                (o) => visiveis.contains(o.id))
                                            .toList()),
                                ],
                              ]),
                        );
                      }),
                    ),
                  )),
        ),
      );

  void _limpar() {
    setState(() {
      _negociacao = '';
      _pagamento = '';
    });
    _busca.clear();
    c.busca.value = '';
  }

  Widget _grade(List<Widget> itens, {double minimo = 240}) =>
      LayoutBuilder(builder: (context, box) {
        final escala = MediaQuery.textScalerOf(context).scale(1);
        final colunas = escala > 1.3
            ? 1
            : (box.maxWidth / minimo).floor().clamp(1, itens.length);
        final largura = (box.maxWidth - 12 * (colunas - 1)) / colunas;
        return Wrap(
            spacing: 12,
            runSpacing: 12,
            children:
                itens.map((w) => SizedBox(width: largura, child: w)).toList());
      });

  Widget _resumo(List<OrcamentoAdmin> todos, int eventos) {
    final ativos = todos.where((o) => !o.cancelado);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Visão geral · ${_contagem(eventos, 'evento', 'eventos')}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      const Text(
          'Todos os itens ativos carregados. Os filtros alteram a lista abaixo.',
          style: TextStyle(color: AdminPalette.muted, fontSize: 13)),
      const SizedBox(height: 12),
      _grade([
        _indicador(
            'Estimativa dos itens',
            ativos.fold<int>(0, (s, o) => s + o.estimadoCentavos),
            Icons.receipt_long_outlined),
        _indicador(
            'Registrado nos gastos',
            ativos.fold<int>(0, (s, o) => s + o.pagoCentavos),
            Icons.payments_outlined),
        _indicador(
            'Saldo previsto dos itens',
            ativos.fold<int>(0, (s, o) => s + o.saldoCentavos),
            Icons.schedule_outlined),
      ], minimo: 300),
    ]);
  }

  Widget _indicador(String titulo, int centavos, IconData icone) => Container(
        padding: const EdgeInsets.all(20),
        decoration: adminCardDecoration(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icone, color: AdminPalette.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
                child: Text(titulo,
                    style: const TextStyle(
                        fontSize: 14, color: AdminPalette.muted)))
          ]),
          const SizedBox(height: 12),
          Text(_moeda(centavos),
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AdminPalette.ink)),
        ]),
      );

  Widget _filtros() => Container(
        padding: const EdgeInsets.all(16),
        decoration: adminCardDecoration(),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
              controller: _busca,
              onChanged: (v) => c.busca.value = v,
              decoration: InputDecoration(
                  labelText: 'Buscar na lista',
                  hintText: 'Evento, item, cidade ou negociação',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                      tooltip: 'Limpar busca',
                      onPressed: () {
                        _busca.clear();
                        c.busca.value = '';
                      },
                      icon: const Icon(Icons.close_rounded)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 14),
          _grade([
            DropdownButtonFormField<String>(
                value: _negociacao,
                isExpanded: true,
                decoration: const InputDecoration(
                    labelText: 'Negociação', border: OutlineInputBorder()),
                items: [
                  for (final entrada in {
                    '': 'Todas as situações',
                    'pendente': 'Pendente',
                    'em negociação': 'Em negociação',
                    'fechado': 'Fechado',
                    'cancelado': 'Cancelado'
                  }.entries)
                    DropdownMenuItem(
                        value: entrada.key, child: Text(entrada.value))
                ],
                onChanged: (v) => setState(() => _negociacao = v ?? '')),
            DropdownButtonFormField<String>(
                value: _pagamento,
                isExpanded: true,
                decoration: const InputDecoration(
                    labelText: 'Saldo dos itens', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: '', child: Text('Todos os itens')),
                  DropdownMenuItem(
                      value: 'saldo', child: Text('Com saldo previsto')),
                  DropdownMenuItem(
                      value: 'sem_saldo', child: Text('Sem saldo previsto'))
                ],
                onChanged: (v) => setState(() => _pagamento = v ?? '')),
          ], minimo: 330),
          Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                  onPressed: _limpar,
                  icon: const Icon(Icons.filter_alt_off_outlined),
                  label: const Text('Limpar filtros'))),
        ]),
      );

  Widget _evento(GrupoOrcamentosAdmin g, List<OrcamentoAdmin> visiveis) {
    final e = g.evento;
    return Container(
      key: ValueKey(g.chave),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: adminCardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        LayoutBuilder(builder: (context, box) {
          final identidade =
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.eventoNome,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(_identificacaoEvento(e),
                style:
                    const TextStyle(fontSize: 13, color: AdminPalette.muted)),
            const SizedBox(height: 6),
            Text(_contagemItens(visiveis.length, g.itens.length),
                style:
                    const TextStyle(fontSize: 13, color: AdminPalette.muted)),
          ]);
          final botao = OutlinedButton.icon(
              key: ValueKey('ver-itens-${g.chave}'),
              onPressed: () => _abrirItens(context, g, visiveis),
              icon: const Icon(Icons.list_alt_rounded),
              label: const Text('Ver itens'));
          if (box.maxWidth < 650 ||
              MediaQuery.textScalerOf(context).scale(1) > 1.3) {
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [identidade, const SizedBox(height: 12), botao]);
          }
          return Row(children: [
            Expanded(child: identidade),
            const SizedBox(width: 16),
            botao
          ]);
        }),
        if (e.idEvento.isEmpty ||
            e.eventoNome == 'Evento não identificado') ...[
          const SizedBox(height: 12),
          const Text(
              'Identificação incompleta: confira o vínculo com o evento. Este grupo não foi unido a outros eventos pelo nome.',
              style: TextStyle(color: AdminPalette.warning, fontSize: 13)),
        ],
        const SizedBox(height: 20),
        _grade([
          _valor(
              'Planejamento do evento',
              g.planejadoCentavos > 0
                  ? _moeda(g.planejadoCentavos)
                  : 'Não definido'),
          _valor('Estimativa dos itens ativos', _moeda(g.estimadoCentavos)),
          _valor('Saldo previsto dos itens', _moeda(g.saldoCentavos)),
        ]),
        const SizedBox(height: 16),
        _planejamento(g),
      ]),
    );
  }

  String _identificacaoEvento(OrcamentoAdmin evento) => [
        evento.tipoEvento,
        evento.cidade,
        evento.dataEvento == null
            ? 'Data não informada'
            : DateFormat('dd/MM/yyyy').format(evento.dataEvento!),
      ].where((v) => v.isNotEmpty && v != '-').join(' · ');

  String _contagemItens(int visiveis, int total) => visiveis == total
      ? _contagem(total, 'item', 'itens')
      : '$visiveis de ${_contagem(total, 'item', 'itens')} · filtros ativos';

  Future<void> _abrirItens(BuildContext context, GrupoOrcamentosAdmin grupo,
          List<OrcamentoAdmin> itens) =>
      showDialog<void>(
        context: context,
        builder: (ctx) {
          final compacto = MediaQuery.sizeOf(ctx).width < 600;
          final margem = compacto ? 12.0 : 24.0;
          final espacamento = compacto ? 16.0 : 24.0;
          return Dialog(
            backgroundColor: AdminPalette.card,
            surfaceTintColor: Colors.transparent,
            insetPadding: EdgeInsets.all(margem),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 760),
              child: SizedBox(
                width: 1280,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(espacamento, 8, 8, 8),
                      child: Row(children: [
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: const Text('Itens do orçamento',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Fechar itens do orçamento',
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ]),
                    ),
                    const Divider(height: 1),
                    Flexible(
                      child: LayoutBuilder(builder: (context, box) {
                        final usarTabela = box.maxWidth - 2 * espacamento >=
                                1150 &&
                            MediaQuery.textScalerOf(context).scale(1) <= 1.3;
                        return CustomScrollView(
                          primary: false,
                          shrinkWrap: true,
                          slivers: [
                            SliverPadding(
                              padding: EdgeInsets.all(espacamento),
                              sliver: SliverToBoxAdapter(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(grupo.evento.eventoNome,
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 4),
                                    Text(_identificacaoEvento(grupo.evento),
                                        style: const TextStyle(
                                            color: AdminPalette.muted)),
                                    const SizedBox(height: 8),
                                    Text(_contagemItens(
                                        itens.length, grupo.itens.length)),
                                  ],
                                ),
                              ),
                            ),
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                  espacamento, 0, espacamento, espacamento),
                              sliver: usarTabela
                                  ? SliverToBoxAdapter(child: _tabela(itens))
                                  : SliverList.builder(
                                      itemCount: itens.length,
                                      itemBuilder: (_, i) => _item(itens[i]),
                                    ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

  Widget _planejamento(GrupoOrcamentosAdmin g) {
    final percentual = g.percentualPlanejado;
    final excedido = percentual != null && percentual > 100;
    final cor = percentual == null
        ? AdminPalette.muted
        : excedido
            ? AdminPalette.danger
            : percentual >= 100
                ? AdminPalette.warning
                : AdminPalette.success;
    final titulo = percentual == null
        ? 'Planejamento não definido'
        : excedido
            ? 'Acima do planejado'
            : percentual >= 100
                ? 'Limite atingido'
                : 'Dentro do planejado';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: cor.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: 10, runSpacing: 6, children: [
          Text(titulo,
              style: TextStyle(
                  color: cor, fontWeight: FontWeight.w700, fontSize: 14)),
          if (percentual != null)
            Text(
                '${percentual.toStringAsFixed(1).replaceAll('.', ',')}% do planejamento',
                style: const TextStyle(fontSize: 14)),
        ]),
        if (percentual != null) ...[
          const SizedBox(height: 10),
          LinearProgressIndicator(
              value: (percentual / 100).clamp(0, 1),
              color: cor,
              backgroundColor: cor.withValues(alpha: .12),
              minHeight: 6,
              borderRadius: BorderRadius.circular(6)),
        ],
        const SizedBox(height: 8),
        Text(
            percentual == null
                ? 'Defina o limite no cadastro do evento para comparar os valores.'
                : excedido
                    ? 'Excedente de ${_moeda(g.excedenteCentavos)}. Considere revisar os itens ou o planejamento.'
                    : 'Comparação com todos os itens ativos do evento, inclusive os que estão em negociação.',
            style: const TextStyle(fontSize: 13, color: AdminPalette.muted)),
      ]),
    );
  }

  Widget _valor(String rotulo, String valor) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(rotulo,
            style: const TextStyle(fontSize: 13, color: AdminPalette.muted)),
        const SizedBox(height: 5),
        Text(valor,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AdminPalette.ink)),
      ]);

  Widget _etiqueta({required String texto, required Color color}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
            color: color.withValues(alpha: .08),
            border: Border.all(color: color.withValues(alpha: .2)),
            borderRadius: BorderRadius.circular(8)),
        child: Text(texto,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      );

  Widget _situacao(OrcamentoAdmin o) =>
      Wrap(spacing: 6, runSpacing: 6, children: [
        _etiqueta(
            texto: 'Negociação: ${o.status}',
            color: o.cancelado ? AdminPalette.muted : AdminPalette.primary),
        if (!o.cancelado)
          _etiqueta(
              texto: o.saldoCentavos == 0
                  ? 'Sem saldo previsto'
                  : 'Com saldo previsto',
              color: o.saldoCentavos == 0
                  ? AdminPalette.success
                  : AdminPalette.warning),
      ]);

  Widget _item(OrcamentoAdmin o) => Container(
        key: ValueKey('item-${o.id}'),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AdminPalette.surface,
            borderRadius: BorderRadius.circular(12)),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(o.categoria,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 10),
          _situacao(o),
          const SizedBox(height: 16),
          _grade([
            _valor('Estimativa', _moeda(o.estimadoCentavos)),
            _valor('Registrado nos gastos', _moeda(o.pagoCentavos)),
            _valor('Saldo previsto', _moeda(o.saldoCentavos))
          ], minimo: 210),
          Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                  onPressed: () => _detalhe(o),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Ver detalhes'))),
        ]),
      );

  Widget _tabela(List<OrcamentoAdmin> itens) => DataTable(
        columnSpacing: 20,
        horizontalMargin: 8,
        headingTextStyle: const TextStyle(
            fontSize: 13,
            color: AdminPalette.muted,
            fontWeight: FontWeight.w600),
        dataRowMinHeight: 64,
        dataRowMaxHeight: 88,
        columns: const [
          DataColumn(label: Text('Item / descrição')),
          DataColumn(label: Text('Estimativa'), numeric: true),
          DataColumn(label: Text('Registrado nos gastos'), numeric: true),
          DataColumn(label: Text('Saldo previsto'), numeric: true),
          DataColumn(label: Text('Situações')),
          DataColumn(label: Text('Detalhes'))
        ],
        rows: itens
            .map((o) => DataRow(cells: [
                  DataCell(SizedBox(
                      width: 220,
                      child: Text(o.categoria,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)))),
                  DataCell(Text(_moeda(o.estimadoCentavos))),
                  DataCell(Text(_moeda(o.pagoCentavos))),
                  DataCell(Text(_moeda(o.saldoCentavos),
                      style: const TextStyle(fontWeight: FontWeight.w700))),
                  DataCell(SizedBox(width: 200, child: _situacao(o))),
                  DataCell(TextButton(
                      onPressed: () => _detalhe(o),
                      child: const Text('Ver detalhes'))),
                ]))
            .toList(),
      );

  Future<void> _detalhe(OrcamentoAdmin o) => showDialog<void>(
      context: context,
      builder: (ctx) => Theme(
          data: widget.themeController.adminThemeData,
          child: AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            scrollable: true,
            title: Text(o.categoria,
                style: const TextStyle(
                    fontSize: 20, height: 1.25, fontWeight: FontWeight.w700)),
            content: SizedBox(
                width: 520,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(o.eventoNome,
                          style: const TextStyle(
                              fontSize: 15, color: AdminPalette.muted)),
                      const SizedBox(height: 16),
                      _situacao(o),
                      const SizedBox(height: 20),
                      _valor('Estimativa do item', _moeda(o.estimadoCentavos)),
                      const SizedBox(height: 16),
                      _valor('Pagamentos registrados nos gastos',
                          _moeda(o.pagoCentavos)),
                      const SizedBox(height: 16),
                      _valor('Saldo previsto do item', _moeda(o.saldoCentavos)),
                      const SizedBox(height: 20),
                      const Text(
                          'Esta consulta mostra registros dos gastos. Recebimentos da plataforma, comissão e repasses devem ser conferidos no financeiro.',
                          style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: AdminPalette.muted)),
                      ExpansionTile(
                          title: const Text('Referências para conferência'),
                          children: [
                            SelectableText('Orçamento: ${o.id}'),
                            if (o.idEvento.isNotEmpty)
                              SelectableText('Evento: ${o.idEvento}')
                          ]),
                    ])),
            actions: [
              TextButton(
                  onPressed: () => Clipboard.setData(ClipboardData(text: o.id)),
                  child: const Text('Copiar referência')),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Voltar aos itens',
                      textAlign: TextAlign.center))
            ],
          )));
}
