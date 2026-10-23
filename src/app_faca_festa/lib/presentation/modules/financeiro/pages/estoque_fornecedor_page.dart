import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/core/utils/numeric_input.dart';
import 'package:app_faca_festa/domain/entities/financeiro/item_estoque_fornecedor.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/controllers/estoque_fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/sections/fornecedor_premium_layout.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/widgets/festa_app_bar.dart';

/// Estoque empresarial do fornecedor — consultar primeiro; cadastrar/movimentar sob demanda.
class EstoqueFornecedorPage extends StatefulWidget {
  const EstoqueFornecedorPage({
    super.key,
    required this.controller,
    required this.themeController,
  });

  final EstoqueFornecedorController controller;
  final EventThemeController themeController;

  @override
  State<EstoqueFornecedorPage> createState() => _EstoqueFornecedorPageState();
}

class _EstoqueFornecedorPageState extends State<EstoqueFornecedorPage> {
  final _buscaCtrl = TextEditingController();
  final _novoItemFocus = FocusNode();

  EstoqueFornecedorController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => c.iniciar());
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    _novoItemFocus.dispose();
    super.dispose();
  }

  String _rotuloNatureza(NaturezaItemEstoque n) {
    switch (n) {
      case NaturezaItemEstoque.consumivel:
        return 'Consumível';
      case NaturezaItemEstoque.reutilizavel:
        return 'Reutilizável';
      case NaturezaItemEstoque.locadoTerceiro:
        return 'Locado';
    }
  }

  String _rotuloStatus(StatusFisicoItemEstoque s) {
    switch (s) {
      case StatusFisicoItemEstoque.disponivel:
        return 'Disponível';
      case StatusFisicoItemEstoque.manutencao:
        return 'Manutenção';
      case StatusFisicoItemEstoque.vencido:
        return 'Vencido';
      case StatusFisicoItemEstoque.inativo:
        return 'Inativo';
    }
  }

  String _custoLegivel(ItemEstoqueFornecedor item) {
    if (item.financeiroIncompleto) return '—';
    final centavos = item.natureza == NaturezaItemEstoque.reutilizavel &&
            item.custoUsoCentavos > 0
        ? item.custoUsoCentavos
        : item.custoMedioUnitarioCentavos;
    if (centavos <= 0) return '—';
    return NumericInput.dinheiro(centavos / 100.0);
  }

  Future<void> _abrirPainel({
    required Widget Function(BuildContext ctx, VoidCallback fechar) builder,
    required Object? returnFocus,
  }) async {
    final wide = MediaQuery.sizeOf(context).width >= 768;
    if (wide) {
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Fechar',
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (ctx, _, __) {
          return Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: FornecedorPremiumPalette.surface,
              elevation: 12,
              shadowColor: Colors.black26,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
              ),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: MediaQuery.sizeOf(ctx).width.clamp(380, 460),
                height: double.infinity,
                child: SafeArea(
                  child: builder(ctx, () => Navigator.of(ctx).pop()),
                ),
              ),
            ),
          );
        },
      );
    } else {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: FornecedorPremiumPalette.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: SizedBox(
            height: MediaQuery.sizeOf(ctx).height * 0.9,
            child: builder(ctx, () => Navigator.of(ctx).pop()),
          ),
        ),
      );
    }
    if (returnFocus is FocusNode && mounted) {
      returnFocus.requestFocus();
    }
  }

  Future<void> _abrirCadastro() async {
    await _abrirPainel(
      returnFocus: _novoItemFocus,
      builder: (ctx, fechar) => _PainelCadastroItem(
        controller: c,
        onCancelar: fechar,
        onSalvo: fechar,
      ),
    );
  }

  Future<void> _abrirDetalhe(ItemEstoqueFornecedor item) async {
    await _abrirPainel(
      returnFocus: null,
      builder: (ctx, fechar) => _PainelDetalheItem(
        controller: c,
        itemId: item.idItem,
        onFechar: fechar,
        rotuloNatureza: _rotuloNatureza,
        rotuloStatus: _rotuloStatus,
        custoLegivel: _custoLegivel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final busy = c.carregando.value;
      final err = c.erro.value;
      final filtro = c.filtroNatureza.value;
      c.buscaTexto.value;
      c.enviando.value;
      final lista = c.itensFiltrados;
      final contagens = c.contagemCadastrosPorTipo();
      final alertas = c.alertasAgrupados;
      final loading = busy && c.itens.isEmpty;

      return Scaffold(
        backgroundColor: FornecedorPremiumPalette.background,
        appBar: FestaAppBar(
          titulo: 'Estoque interno',
          themeController: widget.themeController,
          acoes: [
            IconButton(
              tooltip: 'Atualizar',
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: busy ? null : c.iniciar,
            ),
          ],
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final pad = FornecedorBreakpoints.padding(w);
                  final maxW = w >= 1280 ? 1400.0 : w;
                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxW),
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(pad, FestaPageInsets.belowAppBar, pad, 32),
                        children: [
                          _cabecalho(w, vazio: c.itens.isEmpty),
                          if (err.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _bannerErro(err),
                          ],
                          if (c.itens.isEmpty) ...[
                            const SizedBox(height: 16),
                            _vazioInicial(),
                          ] else ...[
                            const SizedBox(height: 14),
                            _barraBuscaEAcao(w),
                            const SizedBox(height: 14),
                            _sintese(contagens, w),
                            if (alertas.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _alertas(alertas),
                            ],
                            const SizedBox(height: 14),
                            _filtros(filtro, contagens),
                            const SizedBox(height: 14),
                            if (lista.isEmpty)
                              _vazioFiltro()
                            else if (w >= 768)
                              _tabela(lista)
                            else
                              ...lista.map(_cardMobile),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
      );
    });
  }

  Widget _cabecalho(double w, {required bool vazio}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estoque interno',
          style: GoogleFonts.poppins(
            fontSize: w < 520 ? 20 : 24,
            fontWeight: FontWeight.w800,
            color: FornecedorPremiumPalette.text,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          vazio
              ? 'Aqui você controla quantidade, reserva e consumo de materiais. '
                  'O que você vende com preço fica no Catálogo (Serviços e Produtos) — são cadastros diferentes.'
              : 'Materiais e equipamentos da empresa: disponibilidade, reserva e consumo. '
                  'Não é o catálogo de venda — preços de oferta ficam em Serviços e Produtos.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: FornecedorPremiumPalette.muted,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _barraBuscaEAcao(double w) {
    final compact = w < 640;
    final busca = TextField(
      controller: _buscaCtrl,
      onChanged: (v) => c.buscaTexto.value = v,
      decoration: InputDecoration(
        hintText: 'Buscar por nome',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: FornecedorPremiumPalette.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: FornecedorPremiumPalette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: FornecedorPremiumPalette.border),
        ),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      style: GoogleFonts.poppins(fontSize: 14),
    );
    final cta = FilledButton.icon(
      focusNode: _novoItemFocus,
      onPressed: _abrirCadastro,
      style: FilledButton.styleFrom(
        backgroundColor: FornecedorPremiumPalette.primary,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      icon: const Icon(Icons.add_rounded, size: 20),
      label: Text(
        'Novo item',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
      ),
    );
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          busca,
          const SizedBox(height: 10),
          Align(alignment: Alignment.centerLeft, child: cta),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: busca),
        const SizedBox(width: 12),
        cta,
      ],
    );
  }

  Widget _sintese(Map<String, int> contagens, double w) {
    return PremiumSectionShell(
      title: 'Síntese',
      subtitle: 'Cadastros por tipo — não soma quantidades físicas distintas.',
      icon: Icons.inventory_2_outlined,
      color: FornecedorPremiumPalette.indigo,
      child: ResponsiveWrapGrid(
        maxColumns: 4,
        minTileWidth: 160,
        children: [
          PremiumMetricTile(
            label: 'Cadastros',
            value: '${contagens['total'] ?? 0}',
            subtitle: 'Itens no estoque',
            icon: Icons.list_alt_rounded,
            color: FornecedorPremiumPalette.indigo,
          ),
          PremiumMetricTile(
            label: 'Consumíveis',
            value: '${contagens['consumivel'] ?? 0}',
            subtitle: 'Cadastros',
            icon: Icons.local_drink_outlined,
            color: FornecedorPremiumPalette.sky,
          ),
          PremiumMetricTile(
            label: 'Reutilizáveis',
            value: '${contagens['reutilizavel'] ?? 0}',
            subtitle: 'Cadastros',
            icon: Icons.chair_outlined,
            color: FornecedorPremiumPalette.emerald,
          ),
          PremiumMetricTile(
            label: 'Locados',
            value: '${contagens['locado_terceiro'] ?? 0}',
            subtitle: 'Cadastros',
            icon: Icons.storefront_outlined,
            color: FornecedorPremiumPalette.amber,
          ),
        ],
      ),
    );
  }

  Widget _alertas(List<AlertaEstoqueAgrupado> alertas) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FornecedorPremiumPalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FornecedorPremiumPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Atenções',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: FornecedorPremiumPalette.text,
            ),
          ),
          const SizedBox(height: 8),
          ...alertas.take(6).map((a) {
            final cor = a.severidade == 'erro'
                ? FornecedorPremiumPalette.rose
                : FornecedorPremiumPalette.amber;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    a.severidade == 'erro'
                        ? Icons.error_outline
                        : Icons.warning_amber_rounded,
                    size: 18,
                    color: cor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      a.quantidade > 1
                          ? '${a.mensagem} (${a.quantidade})'
                          : a.mensagem,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: cor,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _filtros(String selecionado, Map<String, int> contagens) {
    final opcoes = [
      ('', 'Todos', contagens['total'] ?? 0),
      ('consumivel', 'Consumíveis', contagens['consumivel'] ?? 0),
      ('reutilizavel', 'Reutilizáveis', contagens['reutilizavel'] ?? 0),
      ('locado_terceiro', 'Locados', contagens['locado_terceiro'] ?? 0),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final e in opcoes)
          FilterChip(
            selected: selecionado == e.$1,
            showCheckmark: false,
            label: Text(
              '${e.$2} · ${e.$3}',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            selectedColor:
                FornecedorPremiumPalette.primary.withValues(alpha: 0.15),
            side: BorderSide(
              color: selecionado == e.$1
                  ? FornecedorPremiumPalette.primary
                  : FornecedorPremiumPalette.border,
            ),
            onSelected: (_) => c.filtroNatureza.value = e.$1,
          ),
      ],
    );
  }

  Widget _vazioInicial() {
    return Column(
      children: [
        const PremiumEmptyState(
          icon: Icons.warehouse_outlined,
          title: 'Nenhum material cadastrado',
          message:
              'Cadastre cadeiras, tecido, equipamento etc. para controlar quantidade e custo interno. '
              'Decoração e serviços com preço de venda continuam no Catálogo.',
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _abrirCadastro,
          style: FilledButton.styleFrom(
            backgroundColor: FornecedorPremiumPalette.primary,
            minimumSize: const Size(48, 48),
          ),
          icon: const Icon(Icons.add_rounded),
          label: Text(
            'Cadastrar material no estoque',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _vazioFiltro() {
    return Column(
      children: [
        const PremiumEmptyState(
          icon: Icons.search_off_rounded,
          title: 'Nenhum item neste filtro',
          message: 'Ajuste a busca ou o tipo para ver outros cadastros.',
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            _buscaCtrl.clear();
            c.limparFiltros();
          },
          child: Text(
            'Limpar filtros',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: FornecedorPremiumPalette.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _tabela(List<ItemEstoqueFornecedor> lista) {
    return Container(
      decoration: BoxDecoration(
        color: FornecedorPremiumPalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FornecedorPremiumPalette.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: FornecedorPremiumPalette.muted,
          ),
          dataTextStyle: GoogleFonts.poppins(
            fontSize: 13,
            color: FornecedorPremiumPalette.text,
          ),
          columns: const [
            DataColumn(label: Text('Nome')),
            DataColumn(label: Text('Tipo')),
            DataColumn(label: Text('Livre'), numeric: true),
            DataColumn(label: Text('Reservado'), numeric: true),
            DataColumn(label: Text('Em uso'), numeric: true),
            DataColumn(label: Text('Custo')),
            DataColumn(label: Text('')),
          ],
          rows: lista.map((item) {
            return DataRow(cells: [
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item.nome,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    if (item.status != StatusFisicoItemEstoque.disponivel)
                      Text(
                        _rotuloStatus(item.status),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: FornecedorPremiumPalette.amber,
                        ),
                      ),
                  ],
                ),
              ),
              DataCell(Text(_rotuloNatureza(item.natureza))),
              DataCell(Text('${item.quantidadeDisponivelLivre} ${item.unidade}')),
              DataCell(Text('${item.quantidadeReservada}')),
              DataCell(Text('${item.quantidadeEmUso}')),
              DataCell(
                Text(
                  item.financeiroIncompleto
                      ? 'Incompleto'
                      : _custoLegivel(item),
                ),
              ),
              DataCell(
                TextButton(
                  onPressed: () => _abrirDetalhe(item),
                  child: Text(
                    'Detalhes',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: FornecedorPremiumPalette.primary,
                    ),
                  ),
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _cardMobile(ItemEstoqueFornecedor item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FornecedorPremiumPalette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FornecedorPremiumPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.nome,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: FornecedorPremiumPalette.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_rotuloNatureza(item.natureza)} · '
            'livre ${item.quantidadeDisponivelLivre} ${item.unidade}',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: FornecedorPremiumPalette.muted,
            ),
          ),
          Text(
            item.financeiroIncompleto
                ? 'Custo incompleto'
                : 'Custo ${_custoLegivel(item)}',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: item.financeiroIncompleto
                  ? FornecedorPremiumPalette.amber
                  : FornecedorPremiumPalette.text,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _abrirDetalhe(item),
              child: Text(
                'Detalhes',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: FornecedorPremiumPalette.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bannerErro(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FornecedorPremiumPalette.rose.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FornecedorPremiumPalette.rose.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: FornecedorPremiumPalette.rose),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: FornecedorPremiumPalette.rose,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PainelCadastroItem extends StatefulWidget {
  const _PainelCadastroItem({
    required this.controller,
    required this.onCancelar,
    required this.onSalvo,
  });

  final EstoqueFornecedorController controller;
  final VoidCallback onCancelar;
  final VoidCallback onSalvo;

  @override
  State<_PainelCadastroItem> createState() => _PainelCadastroItemState();
}

class _PainelCadastroItemState extends State<_PainelCadastroItem> {
  final _nomeCtrl = TextEditingController();
  final _qtdCtrl = TextEditingController();
  final _custoCtrl = TextEditingController();
  final _unidadeCtrl = TextEditingController(text: 'un');
  final _montagemCtrl = TextEditingController();
  final _desmontagemCtrl = TextEditingController();
  String _natureza = 'consumivel';
  String? _erroNome;
  String? _erroQtd;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _qtdCtrl.dispose();
    _custoCtrl.dispose();
    _unidadeCtrl.dispose();
    _montagemCtrl.dispose();
    _desmontagemCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final nome = _nomeCtrl.text.trim();
    final qtd = int.tryParse(_qtdCtrl.text.trim());
    setState(() {
      _erroNome = nome.isEmpty ? 'Informe o nome.' : null;
      _erroQtd = (qtd == null || qtd < 0) ? 'Quantidade inválida.' : null;
    });
    if (_erroNome != null || _erroQtd != null) return;

    final reais = double.tryParse(
          _custoCtrl.text.trim().replaceAll(',', '.'),
        ) ??
        0;
    final centavos = (reais * 100).round();
    final montagem = int.tryParse(_montagemCtrl.text.trim()) ?? 0;
    final desmontagem = int.tryParse(_desmontagemCtrl.text.trim()) ?? 0;

    await widget.controller.cadastrarItem(
      nome: nome,
      natureza: _natureza,
      quantidade: qtd!,
      custoUnitarioCentavos: centavos,
      custoUsoCentavos: _natureza == 'reutilizavel' ? centavos : 0,
      montagemMinutos: _natureza == 'reutilizavel' ? montagem : 0,
      desmontagemMinutos: _natureza == 'reutilizavel' ? desmontagem : 0,
      unidade: _unidadeCtrl.text.trim().isEmpty ? 'un' : _unidadeCtrl.text.trim(),
    );
    if (widget.controller.erro.value.isEmpty) {
      widget.onSalvo();
    }
  }

  InputDecoration _campo(String label, IconData icon,
      {String? hint, String? errorText}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: errorText,
      prefixIcon: Icon(icon, size: 20, color: FornecedorPremiumPalette.primary),
      filled: true,
      fillColor: FornecedorPremiumPalette.surfaceAlt,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: FornecedorPremiumPalette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
            color: FornecedorPremiumPalette.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: FornecedorPremiumPalette.rose),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: FornecedorPremiumPalette.rose, width: 2),
      ),
    );
  }

  Widget _secao(String titulo, String descricao, List<Widget> filhos) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: FornecedorPremiumPalette.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            descricao,
            style: GoogleFonts.poppins(
              fontSize: 12,
              height: 1.4,
              color: FornecedorPremiumPalette.muted,
            ),
          ),
          const SizedBox(height: 12),
          ...filhos,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.escape): _DismissIntent(),
      },
      child: Actions(
        actions: {
          _DismissIntent: CallbackAction<_DismissIntent>(
            onInvoke: (_) {
              widget.onCancelar();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      color: FornecedorPremiumPalette.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Novo item',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: FornecedorPremiumPalette.text,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fechar',
                      onPressed: widget.onCancelar,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: FornecedorPremiumPalette.border),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: FornecedorPremiumPalette.primary
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 18,
                              color: FornecedorPremiumPalette.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Cadastre materiais e equipamentos da empresa. Quantidade e custo podem ser ajustados depois.',
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  height: 1.4,
                                  color: FornecedorPremiumPalette.text,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _secao(
                        'O que é o item?',
                        'Identifique o material e como ele é usado no estoque.',
                        [
                          TextField(
                            controller: _nomeCtrl,
                            decoration: _campo(
                              'Nome',
                              Icons.edit_outlined,
                              hint: 'Ex.: Cadeira Tiffany',
                              errorText: _erroNome,
                            ),
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.sentences,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _natureza,
                            isExpanded: true,
                            decoration: _campo('Tipo', Icons.category_outlined),
                            items: const [
                              DropdownMenuItem(
                                  value: 'consumivel',
                                  child: Text('Consumível')),
                              DropdownMenuItem(
                                  value: 'reutilizavel',
                                  child: Text('Reutilizável')),
                              DropdownMenuItem(
                                  value: 'locado_terceiro',
                                  child: Text('Locado de terceiro')),
                            ],
                            onChanged: (v) =>
                                setState(() => _natureza = v ?? 'consumivel'),
                          ),
                        ],
                      ),
                      _secao(
                        'Quantidade e custo',
                        'Informe o estoque inicial e o valor de referência.',
                        [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _qtdCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: _campo(
                                    'Quantidade',
                                    Icons.pin_outlined,
                                    hint: 'Ex.: 10',
                                    errorText: _erroQtd,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _unidadeCtrl,
                                  decoration: _campo(
                                    'Unidade',
                                    Icons.straighten_outlined,
                                    hint: 'un, kg…',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _custoCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: _campo(
                              _natureza == 'reutilizavel'
                                  ? 'Custo por uso (R\$)'
                                  : 'Custo unitário (R\$)',
                              Icons.payments_outlined,
                              hint: 'Ex.: 5,00',
                            ),
                          ),
                        ],
                      ),
                      if (_natureza == 'reutilizavel')
                        _secao(
                          'Tempos de reserva',
                          'Opcionais. Ampliam o intervalo da reserva no evento.',
                          [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _montagemCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: _campo(
                                      'Montagem (min)',
                                      Icons.build_outlined,
                                      hint: '0',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _desmontagemCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: _campo(
                                      'Desmontagem (min)',
                                      Icons.handyman_outlined,
                                      hint: '0',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                decoration: const BoxDecoration(
                  color: FornecedorPremiumPalette.surface,
                  border: Border(
                    top: BorderSide(color: FornecedorPremiumPalette.border),
                  ),
                ),
                child: Obx(() {
                  final enviando = widget.controller.enviando.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: enviando ? null : _salvar,
                          style: FilledButton.styleFrom(
                            backgroundColor: FornecedorPremiumPalette.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: enviando
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_rounded),
                          label: Text(
                            enviando ? 'Salvando…' : 'Salvar item',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: enviando ? null : widget.onCancelar,
                        style: TextButton.styleFrom(
                          foregroundColor: FornecedorPremiumPalette.primary,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: Text(
                          'Cancelar',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
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
  }
}

class _DismissIntent extends Intent {
  const _DismissIntent();
}

class _PainelDetalheItem extends StatefulWidget {
  const _PainelDetalheItem({
    required this.controller,
    required this.itemId,
    required this.onFechar,
    required this.rotuloNatureza,
    required this.rotuloStatus,
    required this.custoLegivel,
  });

  final EstoqueFornecedorController controller;
  final String itemId;
  final VoidCallback onFechar;
  final String Function(NaturezaItemEstoque) rotuloNatureza;
  final String Function(StatusFisicoItemEstoque) rotuloStatus;
  final String Function(ItemEstoqueFornecedor) custoLegivel;

  @override
  State<_PainelDetalheItem> createState() => _PainelDetalheItemState();
}

class _PainelDetalheItemState extends State<_PainelDetalheItem> {
  final _eventoCtrl = TextEditingController();
  final _qtdCtrl = TextEditingController(text: '1');
  final _inicioCtrl = TextEditingController();
  final _fimCtrl = TextEditingController();
  String _modo = 'consulta'; // consulta | reservar | consumir

  @override
  void initState() {
    super.initState();
    final agora = DateTime.now();
    _inicioCtrl.text = agora.toIso8601String().substring(0, 16);
    _fimCtrl.text =
        agora.add(const Duration(hours: 4)).toIso8601String().substring(0, 16);
  }

  @override
  void dispose() {
    _eventoCtrl.dispose();
    _qtdCtrl.dispose();
    _inicioCtrl.dispose();
    _fimCtrl.dispose();
    super.dispose();
  }

  ItemEstoqueFornecedor? get _item {
    try {
      return widget.controller.itens
          .firstWhere((i) => i.idItem == widget.itemId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _confirmarReserva() async {
    final item = _item;
    if (item == null) return;
    final ev = _eventoCtrl.text.trim();
    final qtd = int.tryParse(_qtdCtrl.text.trim()) ?? 0;
    if (ev.isEmpty || qtd <= 0) {
      Get.snackbar('Reserva', 'Informe evento e quantidade.');
      return;
    }
    final inicio = DateTime.tryParse(_inicioCtrl.text.trim());
    final fim = DateTime.tryParse(_fimCtrl.text.trim());
    if (inicio == null || fim == null || !fim.isAfter(inicio)) {
      Get.snackbar('Reserva', 'Informe intervalo válido (início e fim).');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirmar reserva', style: GoogleFonts.poppins()),
        content: Text(
          'Reserva $qtd ${item.unidade} de “${item.nome}” para o evento informado. '
          'Não altera pagamento nem consome o estoque.',
          style: GoogleFonts.poppins(fontSize: 13, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reservar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final id = await widget.controller.reservar(
      idItem: item.idItem,
      idEvento: ev,
      quantidade: qtd,
      inicio: inicio,
      fim: fim,
    );
    if (id != null && mounted) {
      Get.snackbar('Reserva', 'Reserva registrada.');
      setState(() => _modo = 'consulta');
    }
  }

  Future<void> _confirmarConsumo() async {
    final item = _item;
    if (item == null) return;
    final ev = _eventoCtrl.text.trim();
    final qtd = int.tryParse(_qtdCtrl.text.trim()) ?? 0;
    if (ev.isEmpty || qtd <= 0) {
      Get.snackbar('Consumo', 'Informe evento e quantidade.');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirmar consumo', style: GoogleFonts.poppins()),
        content: Text(
          'Consumir $qtd ${item.unidade} de “${item.nome}” atribui custo ao evento '
          '(origem estoque — sem desembolso de caixa). Não é pagamento.',
          style: GoogleFonts.poppins(fontSize: 13, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Consumir'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final res = await widget.controller.consumir(
      idItem: item.idItem,
      idEvento: ev,
      quantidade: qtd,
    );
    if (res != null && mounted) {
      final custo = (res['custoAtribuidoCentavos'] as num?)?.toInt() ?? 0;
      Get.snackbar(
        'Consumo',
        'Custo atribuído ${NumericInput.dinheiro(custo / 100.0)} '
            '(não é pagamento).',
      );
      setState(() => _modo = 'consulta');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      widget.controller.itens.length;
      widget.controller.enviando.value;
      final item = _item;
      if (item == null) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text('Item indisponível', style: GoogleFonts.poppins()),
              TextButton(onPressed: widget.onFechar, child: const Text('Fechar')),
            ],
          ),
        );
      }

      return Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.escape): _DismissIntent(),
        },
        child: Actions(
          actions: {
            _DismissIntent: CallbackAction<_DismissIntent>(
              onInvoke: (_) {
                if (_modo != 'consulta') {
                  setState(() => _modo = 'consulta');
                } else {
                  widget.onFechar();
                }
                return null;
              },
            ),
          },
          child: Focus(
            autofocus: true,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.nome,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Fechar',
                        onPressed: widget.onFechar,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  Text(
                    '${widget.rotuloNatureza(item.natureza)} · '
                    '${widget.rotuloStatus(item.status)} · ${item.unidade}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: FornecedorPremiumPalette.muted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _linha('Total', '${item.quantidadeTotal} ${item.unidade}'),
                  _linha('Livre',
                      '${item.quantidadeDisponivelLivre} ${item.unidade}'),
                  _linha('Reservado', '${item.quantidadeReservada}'),
                  _linha('Em uso', '${item.quantidadeEmUso}'),
                  _linha(
                    item.financeiroIncompleto ? 'Custo' : 'Custo unitário',
                    item.financeiroIncompleto
                        ? 'Incompleto — disponibilidade física ok'
                        : widget.custoLegivel(item),
                  ),
                  const SizedBox(height: 16),
                  if (_modo == 'consulta') ...[
                    Text(
                      'Movimentações',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () => setState(() => _modo = 'reservar'),
                      style: FilledButton.styleFrom(
                        backgroundColor: FornecedorPremiumPalette.primary,
                        minimumSize: const Size(48, 48),
                      ),
                      icon: const Icon(Icons.event_available_outlined),
                      label: Text(
                        'Reservar',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _modo = 'consumir'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      icon: const Icon(Icons.inventory_outlined),
                      label: Text(
                        'Consumir (atribui custo)',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Devolução, manutenção e histórico exigem comandos '
                      'ainda não expostos nesta tela.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: FornecedorPremiumPalette.softMuted,
                        height: 1.35,
                      ),
                    ),
                  ] else ...[
                    Text(
                      _modo == 'reservar'
                          ? 'Nova reserva'
                          : 'Consumo de estoque',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _modo == 'reservar'
                          ? 'Segura quantidade no intervalo. Não é consumo nem pagamento.'
                          : 'Reduz estoque e atribui custo ao evento. Não é pagamento.',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: FornecedorPremiumPalette.muted,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _eventoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Evento (identificador)',
                        helperText:
                            'Sem catálogo de nomes autorizado nesta visão.',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _qtdCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Quantidade (${item.unidade})',
                      ),
                    ),
                    if (_modo == 'reservar') ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: _inicioCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Início (ISO local)',
                          hintText: 'AAAA-MM-DDTHH:MM',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _fimCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Fim (ISO local)',
                          hintText: 'AAAA-MM-DDTHH:MM',
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.controller.enviando.value
                                ? null
                                : () => setState(() => _modo = 'consulta'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(48, 48),
                            ),
                            child: Text('Cancelar',
                                style: GoogleFonts.poppins()),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: widget.controller.enviando.value
                                ? null
                                : (_modo == 'reservar'
                                    ? _confirmarReserva
                                    : _confirmarConsumo),
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  FornecedorPremiumPalette.primary,
                              minimumSize: const Size(48, 48),
                            ),
                            child: Text(
                              _modo == 'reservar' ? 'Reservar' : 'Consumir',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _linha(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              k,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: FornecedorPremiumPalette.muted,
              ),
            ),
          ),
          Text(
            v,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: FornecedorPremiumPalette.text,
            ),
          ),
        ],
      ),
    );
  }
}
