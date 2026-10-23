import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:app_faca_festa/core/utils/biblioteca.dart';
import 'package:app_faca_festa/domain/services/previsao_financeira_gerente_service.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/controllers/financeiro_gerente_controller.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/pages/financeiro_gerente_detalhe_page.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/widgets/festa_app_bar.dart';

/// Financeiro do organizador (eventos próprios) — lista premium.
class FinanceiroGerenteListPage extends StatefulWidget {
  const FinanceiroGerenteListPage({
    super.key,
    required this.controller,
    required this.themeController,
  });

  final FinanceiroGerenteController controller;
  final EventThemeController themeController;

  @override
  State<FinanceiroGerenteListPage> createState() =>
      _FinanceiroGerenteListPageState();
}

class _FinanceiroGerenteListPageState extends State<FinanceiroGerenteListPage> {
  final _fmt = DateFormat('dd/MM/yyyy');
  final _buscaCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  FinanceiroGerenteController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    if (c.filtroBusca.value.isNotEmpty) {
      _buscaCtrl.text = c.filtroBusca.value;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => c.iniciar());
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  String _reais(double? v) {
    if (v == null) return '—';
    return 'R\$ ${Biblioteca.formatarValorDecimal(v)}';
  }

  void _limparFiltrosUi() {
    _buscaCtrl.clear();
    c.limparFiltros();
  }

  Future<void> _abrirPainelFiltros(Color primary) async {
    var estado = c.filtroEstadoComercial.value;
    DateTime? ini = c.periodoInicio.value;
    DateTime? fim = c.periodoFim.value;
    final aplicado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                20 + MediaQuery.viewInsetsOf(ctx).bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Filtros',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Cancelar',
                          onPressed: () => Navigator.pop(ctx, false),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    Text(
                      'Filtra eventos que contêm ao menos um item no estado escolhido. '
                      'Não é filtro de cada pagamento isolado.',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: Colors.black54,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Situação comercial (nos itens)',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final e in [
                          ('', 'Todos'),
                          ('contratado', 'Com item contratado'),
                          ('aberto', 'Com item aberto'),
                          ('cancelado', 'Com item cancelado'),
                        ])
                          ChoiceChip(
                            label: Text(e.$2,
                                style: GoogleFonts.poppins(fontSize: 12)),
                            selected: estado == e.$1,
                            selectedColor: primary.withValues(alpha: 0.18),
                            onSelected: (_) => setLocal(() => estado = e.$1),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Período (pela referência temporal selecionada)',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final d = await showDatePicker(
                                context: ctx,
                                initialDate: ini ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (d != null) setLocal(() => ini = d);
                            },
                            child: Text(
                              ini == null ? 'Início' : _fmt.format(ini!),
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final d = await showDatePicker(
                                context: ctx,
                                initialDate: fim ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (d != null) setLocal(() => fim = d);
                            },
                            child: Text(
                              fim == null ? 'Fim' : _fmt.format(fim!),
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (ini != null || fim != null)
                      TextButton(
                        onPressed: () => setLocal(() {
                          ini = null;
                          fim = null;
                        }),
                        child: Text('Limpar período',
                            style: GoogleFonts.poppins()),
                      ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: primary,
                        minimumSize: const Size(48, 48),
                      ),
                      child: Text(
                        'Aplicar filtros',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text('Cancelar', style: GoogleFonts.poppins()),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (aplicado == true) {
      c.filtroEstadoComercial.value = estado;
      c.periodoInicio.value = ini;
      c.periodoFim.value = fim;
    }
  }

  Future<void> _abrirDetalhe(PrevisaoFinanceiraGerente p) async {
    c.abrirDetalhe(p.idEvento);
    await Get.to(
      () => FinanceiroGerenteDetalhePage(
        controller: c,
        themeController: widget.themeController,
        idEvento: p.idEvento,
      ),
    );
    if (!mounted) return;
    if (_buscaCtrl.text != c.filtroBusca.value) {
      _buscaCtrl.text = c.filtroBusca.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final primary = widget.themeController.primaryColor.value;
      final surface = widget.themeController.surfaceColor.value;
      final busy = c.carregando.value;
      final err = c.erro.value;
      c.filtroBusca.value;
      c.filtroEstadoComercial.value;
      c.eixoTemporal.value;
      c.periodoInicio.value;
      c.periodoFim.value;
      final lista = c.previsoesFiltradas;
      final loading = busy && c.previsoes.isEmpty;

      return Scaffold(
        backgroundColor: surface.withValues(alpha: 0.35),
        appBar: FestaAppBar(
          titulo: 'Financeiro',
          themeController: widget.themeController,
          acoes: [
            if (c.temFiltrosAtivos)
              IconButton(
                tooltip: 'Limpar filtros',
                icon: const Icon(Icons.filter_alt_off_outlined,
                    color: Colors.white),
                onPressed: _limparFiltrosUi,
              ),
            IconButton(
              tooltip: 'Filtros',
              icon: const Icon(Icons.tune_rounded, color: Colors.white),
              onPressed: () => _abrirPainelFiltros(primary),
            ),
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
                  final pad = w >= 1100 ? 28.0 : (w >= 720 ? 20.0 : 16.0);
                  final maxW = w >= 1280 ? 1400.0 : w;
                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxW),
                      child: ListView(
                        controller: _scrollCtrl,
                        padding: EdgeInsets.fromLTRB(pad, FestaPageInsets.belowAppBar, pad, 32),
                        children: [
                          _cabecalho(w, primary),
                          // Banner só com consulta já encerrada e sem lista —
                          // evita o flash "erro → dados" do stream vs carga pontual.
                          if (err.isNotEmpty &&
                              !busy &&
                              c.previsoes.isEmpty) ...[
                            const SizedBox(height: 10),
                            _bannerErro(err, primary),
                          ],
                          const SizedBox(height: 14),
                          _busca(primary),
                          const SizedBox(height: 12),
                          _eixoTemporal(primary),
                          if (c.mostrarContadores) ...[
                            const SizedBox(height: 12),
                            _contadores(primary),
                          ],
                          const SizedBox(height: 16),
                          if (c.previsoes.isEmpty && err.isEmpty)
                            _vazioSemEventos(primary)
                          else if (lista.isEmpty && err.isEmpty)
                            _vazioFiltro(primary)
                          else if (lista.isEmpty && err.isNotEmpty)
                            const SizedBox.shrink()
                          else if (w >= 900)
                            _tabela(lista, primary)
                          else
                            ...lista.map((p) => _cardEvento(p, primary)),
                        ],
                      ),
                    ),
                  );
                },
              ),
      );
    });
  }

  Widget _cabecalho(double w, Color primary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Financeiro dos meus eventos',
          style: GoogleFonts.poppins(
            fontSize: w < 520 ? 22 : 26,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Contratado, pago e previsão dos eventos que você organiza.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: const Color(0xFF64748B),
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _busca(Color primary) {
    return TextField(
      controller: _buscaCtrl,
      onChanged: (v) => c.filtroBusca.value = v,
      decoration: InputDecoration(
        hintText: 'Buscar pelo nome do evento',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary.withValues(alpha: 0.2)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      style: GoogleFonts.poppins(fontSize: 14),
    );
  }

  Widget _eixoTemporal(Color primary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Referência temporal',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<EixoTemporalFinanceiro>(
            segments: const [
              ButtonSegment(
                value: EixoTemporalFinanceiro.mesEvento,
                label: Text('Data do evento'),
                icon: Icon(Icons.event_outlined, size: 16),
              ),
              ButtonSegment(
                value: EixoTemporalFinanceiro.mesPagamento,
                label: Text('Ref. pagamento'),
                icon: Icon(Icons.payments_outlined, size: 16),
              ),
            ],
            selected: {c.eixoTemporal.value},
            onSelectionChanged: (s) {
              if (s.isEmpty) return;
              c.eixoTemporal.value = s.first;
            },
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return primary;
                return const Color(0xFF64748B);
              }),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            c.ajudaEixoTemporal,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF64748B),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _contadores(Color primary) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chipCount('Eventos', '${c.totalEventos}', primary),
        _chipCount('Contratos', '${c.totalContratos}', primary),
        _chipCount('Itens/serviços', '${c.totalItensServico}', primary),
        _chipCount('Fornecedores', '${c.totalFornecedores}', primary),
      ],
    );
  }

  Widget _chipCount(String label, String value, Color primary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: primary.withValues(alpha: 0.2)),
      ),
      child: Text.rich(
        TextSpan(
          style: GoogleFonts.poppins(fontSize: 12),
          children: [
            TextSpan(
              text: '$value ',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: primary,
              ),
            ),
            TextSpan(
              text: label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vazioSemEventos(Color primary) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(Icons.celebration_outlined, size: 36, color: primary),
          const SizedBox(height: 10),
          Text(
            'Nenhum evento cadastrado',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Quando você tiver eventos ativos, o financeiro deles aparece aqui.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF64748B),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _vazioFiltro(Color primary) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 36, color: primary),
          const SizedBox(height: 10),
          Text(
            'Nenhum resultado neste filtro',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _limparFiltrosUi,
            child: Text(
              'Limpar filtros',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardEvento(PrevisaoFinanceiraGerente p, Color primary) {
    final aviso = !p.completo
        ? 'Projeção parcial'
        : (p.cabeNoLimite == false ? 'Acima do limite' : null);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.nomeEvento,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            p.dataEvento != null
                ? _fmt.format(p.dataEvento!)
                : 'Data não informada',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Contratado ${_reais(p.contratado)} · '
            'Pago ${_reais(p.pagoLiquido)} · '
            'Saldo a pagar ${_reais(p.saldoContratado)}',
            style: GoogleFonts.poppins(fontSize: 13, height: 1.35),
          ),
          if (aviso != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.orange.shade800,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    aviso == 'Projeção parcial'
                        ? 'Projeção parcial — não afirma que cabe no orçamento.'
                        : 'Previsão acima do limite confirmado.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _abrirDetalhe(p),
              child: Text(
                'Ver financeiro',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabela(List<PrevisaoFinanceiraGerente> lista, Color primary) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.12)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: const Color(0xFF64748B),
          ),
          dataTextStyle: GoogleFonts.poppins(fontSize: 13),
          columns: const [
            DataColumn(label: Text('Evento')),
            DataColumn(label: Text('Data')),
            DataColumn(label: Text('Contratado'), numeric: true),
            DataColumn(label: Text('Pago'), numeric: true),
            DataColumn(label: Text('Saldo'), numeric: true),
            DataColumn(label: Text('Previsão'), numeric: true),
            DataColumn(label: Text('')),
          ],
          rows: lista.map((p) {
            return DataRow(cells: [
              DataCell(Text(p.nomeEvento)),
              DataCell(Text(
                  p.dataEvento != null ? _fmt.format(p.dataEvento!) : '—')),
              DataCell(Text(_reais(p.contratado))),
              DataCell(Text(_reais(p.pagoLiquido))),
              DataCell(Text(_reais(p.saldoContratado))),
              DataCell(Text(_reais(p.custoFinalPrevisto))),
              DataCell(
                TextButton(
                  onPressed: () => _abrirDetalhe(p),
                  child: Text(
                    'Ver financeiro',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: primary,
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

  Widget _bannerErro(String msg, Color primary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  msg,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.red.shade700,
                    height: 1.3,
                  ),
                ),
                TextButton(
                  onPressed: c.iniciar,
                  child: Text(
                    'Tentar novamente',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
