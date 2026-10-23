import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/core/utils/numeric_input.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/controllers/comissao_plataforma_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/sections/fornecedor_premium_layout.dart';
import 'package:app_faca_festa/presentation/modules/tema/admin_theme.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/widgets/festa_app_bar.dart';
import '../widgets/comissao_detalhe.dart';
import '../widgets/comissao_modal.dart';

/// Comissões da plataforma — admin (petróleo) e pagador (índigo), mesma rota.
class ComissaoPlataformaPage extends StatefulWidget {
  const ComissaoPlataformaPage({
    super.key,
    required this.controller,
    required this.themeController,
  });

  final ComissaoPlataformaController controller;
  final EventThemeController themeController;

  @override
  State<ComissaoPlataformaPage> createState() => _ComissaoPlataformaPageState();
}

class _ComissaoPlataformaPageState extends State<ComissaoPlataformaPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _simPctCtrl = TextEditingController();
  final _simBaseCtrl = TextEditingController();
  final _simForm = GlobalKey<FormState>();

  ComissaoPlataformaController get c => widget.controller;
  bool get _admin => c.isAdmin;

  Color get _accent =>
      _admin ? AdminPalette.primary : FornecedorPremiumPalette.primary;
  Color get _bg =>
      _admin ? AdminPalette.surface : FornecedorPremiumPalette.background;
  Color get _ink => _admin ? AdminPalette.ink : FornecedorPremiumPalette.text;
  Color get _muted =>
      _admin ? AdminPalette.muted : FornecedorPremiumPalette.muted;
  Color get _border =>
      _admin ? AdminPalette.border : FornecedorPremiumPalette.border;
  Color get _card =>
      _admin ? AdminPalette.card : FornecedorPremiumPalette.surface;

  @override
  void initState() {
    super.initState();
    // Pagador não usa abas; mantém controller mínimo só se admin.
    _tabs = TabController(length: _admin ? 3 : 1, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => c.carregar());
  }

  @override
  void dispose() {
    _tabs.dispose();
    _simPctCtrl.dispose();
    _simBaseCtrl.dispose();
    super.dispose();
  }

  String _reaisCentavos(int centavos) =>
      NumericInput.dinheiro(centavos / 100.0);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading =
          c.carregando.value && c.obrigacoes.isEmpty && c.politicas.isEmpty;
      final err = c.erro.value;
      c.enviando.value;
      c.simulacaoTexto.value;
      return Scaffold(
        backgroundColor: _bg,
        appBar: FestaAppBar(
          titulo: _admin ? 'Comissões' : 'Minhas comissões',
          themeController: widget.themeController,
          acoes: [
            IconButton(
              tooltip: 'Atualizar',
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed:
                  c.enviando.value || c.carregando.value ? null : c.carregar,
            ),
          ],
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final pad = (w >= 1100
                      ? 28.0
                      : w >= 720
                          ? 20.0
                          : 16.0);
                  final maxW = _admin ? 1400.0 : 1240.0;
                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxW),
                      child: _admin
                          ? _layoutAdmin(pad, w.clamp(0, maxW), err)
                          : _layoutPagador(pad, w.clamp(0, maxW), err),
                    ),
                  );
                },
              ),
      );
    });
  }

  /// Extrato em primeiro plano; simulador como ação secundária (sem abas de gestão).
  Widget _layoutPagador(double pad, double w, String err) {
    return ListView(
      padding: EdgeInsets.fromLTRB(pad, FestaPageInsets.belowAppBar, pad, 32),
      children: [
        _cabecalho(w),
        if (err.isNotEmpty) ...[
          const SizedBox(height: 12),
          _bannerErro(err),
        ],
        if (c.carregando.value) ...[
          const SizedBox(height: 12),
          LinearProgressIndicator(color: _accent, minHeight: 2),
        ],
        const SizedBox(height: 24),
        if (err.isEmpty || c.obrigacoes.isNotEmpty) _resumoPagador(),
        const SizedBox(height: 28),
        Row(children: [
          Text('Extrato',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, fontSize: 20, color: _ink)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: _accent.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(8)),
            child: Text('${c.obrigacoes.length}',
                style: GoogleFonts.poppins(
                    color: _accent, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 6),
        Text('Consulte os valores e a situação de cada cobrança.',
            style: GoogleFonts.poppins(fontSize: 13, color: _muted)),
        const SizedBox(height: 16),
        if (c.obrigacoes.isEmpty && err.isNotEmpty)
          _vazio(
              icon: Icons.cloud_off_outlined,
              titulo: 'Extrato indisponível',
              mensagem:
                  'Não foi possível carregar as cobranças. Use Atualizar para tentar novamente.')
        else if (c.obrigacoes.isEmpty)
          _vazio(
            icon: Icons.inbox_outlined,
            titulo: 'Nenhuma comissão encontrada',
            mensagem:
                'Quando houver comissões nos seus contratos, elas aparecerão aqui.',
          )
        else if (w >= 900 && MediaQuery.textScalerOf(context).scale(1) <= 1.3)
          _tabelaCobrancas()
        else
          ...c.obrigacoes.map(_cardCobranca),
      ],
    );
  }

  Widget _layoutAdmin(double pad, double w, String err) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverToBoxAdapter(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding:
                  EdgeInsets.fromLTRB(pad, FestaPageInsets.belowAppBar, pad, 0),
              child: _cabecalho(w),
            ),
            if (err.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(pad, 12, pad, 0),
                child: _bannerErro(err),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(pad, 14, pad, 0),
              child: _sintese(w),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(pad, 12, pad, 0),
              child: TabBar(
                isScrollable: MediaQuery.textScalerOf(context).scale(1) > 1.3,
                controller: _tabs,
                labelColor: _accent,
                unselectedLabelColor: _muted,
                indicatorColor: _accent,
                labelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: 'Cobranças'),
                  Tab(text: 'Políticas'),
                  Tab(text: 'Simulador'),
                ],
              ),
            ),
          ],
        )),
      ],
      body: TabBarView(
        controller: _tabs,
        children: [
          _abaCobrancas(pad, w),
          _abaPoliticas(pad, w),
          _abaSimulador(pad, w),
        ],
      ),
    );
  }

  Widget _cabecalho(double w) {
    final compact = w < 560;
    final titulo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_admin) ...[
          Text('FINANCEIRO · COMISSÕES',
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  letterSpacing: 1.3,
                  fontWeight: FontWeight.w600,
                  color: _accent)),
          const SizedBox(height: 8),
        ],
        Text(
          _admin ? 'Comissões' : 'Minhas comissões',
          style: GoogleFonts.poppins(
            fontSize: compact ? 22 : 26,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _admin
              ? 'Acompanhe cobranças e regras de comissão da plataforma'
              : 'Acompanhe seus valores e os pagamentos registrados pela plataforma.',
          style: GoogleFonts.poppins(fontSize: 13, color: _muted, height: 1.3),
        ),
      ],
    );
    final acao = _admin
        ? FilledButton.icon(
            onPressed: c.enviando.value ? null : _abrirNovaPolitica,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(
              'Nova política',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, fontSize: 13),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              iconColor: Colors.white,
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          )
        : OutlinedButton.icon(
            onPressed: _abrirSimuladorPagador,
            icon: const Icon(Icons.calculate_outlined, size: 18),
            label: Text(
              'Simular comissão',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _accent,
              iconColor: _accent,
              side: BorderSide(color: _accent.withValues(alpha: 0.45)),
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          );
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [titulo, const SizedBox(height: 12), acao],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titulo),
        const SizedBox(width: 12),
        acao,
      ],
    );
  }

  Widget _resumoPagador() {
    final saldo = c.totalAReceberCentavos;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      LayoutBuilder(builder: (context, box) {
        final horizontal = box.maxWidth >= 760 &&
            MediaQuery.textScalerOf(context).scale(1) <= 1.3;
        final principal = Container(
          key: const ValueKey('comissoes-saldo'),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF312E81), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.account_balance_wallet_outlined,
                color: Colors.white, size: 24),
            const SizedBox(height: 18),
            Text(saldo < 0 ? 'Saldo em crédito' : 'Saldo das comissões',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
            const SizedBox(height: 6),
            Text(_reaisCentavos(saldo),
                style: GoogleFonts.poppins(
                    fontSize: 32,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 12),
            Text('Referente às cobranças deste extrato',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: const Color(0xFFE0E7FF))),
          ]),
        );
        final secundarios = Column(children: [
          _kpi('Comissões geradas', _reaisCentavos(c.totalGeradoCentavos),
              Icons.receipt_long_outlined),
          const SizedBox(height: 12),
          _kpi('Pagamentos registrados',
              _reaisCentavos(c.totalRecebidoCentavos), Icons.payments_outlined),
        ]);
        if (!horizontal) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [principal, const SizedBox(height: 12), secundarios]);
        }
        return Row(children: [
          Expanded(flex: 5, child: principal),
          const SizedBox(width: 16),
          Expanded(flex: 4, child: secundarios)
        ]);
      }),
      if (c.qtdVencidas > 0) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: AdminPalette.danger.withValues(alpha: .06),
              borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.error_outline,
                color: AdminPalette.danger, size: 20),
            const SizedBox(width: 10),
            Expanded(
                child: Text(
                    c.qtdVencidas == 1
                        ? '1 cobrança vencida neste extrato'
                        : '${c.qtdVencidas} cobranças vencidas neste extrato',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: AdminPalette.danger)))
          ]),
        ),
      ],
    ]);
  }

  Widget _sintese(double w) {
    final geradoLabel = _admin ? 'Gerado' : 'Total gerado';
    final recebidoLabel = _admin ? 'Recebido' : 'Pagamentos';
    final saldoLabel = _admin ? 'A receber' : 'Saldo';
    final tiles = [
      _kpi(geradoLabel, _reaisCentavos(c.totalGeradoCentavos),
          Icons.receipt_long),
      _kpi(recebidoLabel, _reaisCentavos(c.totalRecebidoCentavos),
          Icons.payments),
      _kpi(saldoLabel, _reaisCentavos(c.totalAReceberCentavos), Icons.schedule),
    ];
    final vencidas = c.qtdVencidas;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _admin
              ? 'Síntese do extrato carregado'
              : 'Síntese do seu extrato carregado',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _muted,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, box) {
            final cols =
                box.maxWidth >= 900 ? 3 : (box.maxWidth >= 520 ? 3 : 1);
            final gap = 10.0;
            final tileW = cols == 1
                ? box.maxWidth
                : (box.maxWidth - gap * (cols - 1)) / cols;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children:
                  tiles.map((t) => SizedBox(width: tileW, child: t)).toList(),
            );
          },
        ),
        if (vencidas > 0) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  size: 18, color: AdminPalette.danger),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  vencidas == 1
                      ? '1 cobrança vencida neste extrato'
                      : '$vencidas cobranças vencidas neste extrato',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AdminPalette.danger,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _kpi(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Icon(icon, color: _accent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _abaCobrancas(double pad, double w) {
    return ListView(
      padding: EdgeInsets.fromLTRB(pad, 14, pad, 28),
      children: [
        if (c.obrigacoes.isEmpty)
          _vazio(
            icon: Icons.inbox_outlined,
            titulo: 'Nenhuma cobrança',
            mensagem: 'Quando houver obrigações geradas, elas aparecem aqui.',
          )
        else if (w >= 768)
          _tabelaCobrancas()
        else
          ...c.obrigacoes.map(_cardCobranca),
      ],
    );
  }

  String _refCobranca(Map<String, dynamic> o) {
    final nome = (o['nome_evento'] ?? o['nomeEvento'] ?? '').toString().trim();
    if (nome.isNotEmpty) return nome;
    final id = o['id_obrigacao']?.toString() ?? o['id']?.toString() ?? '';
    final evento = (o['id_evento'] ?? o['idEvento'] ?? '').toString();
    final contrato = (o['id_contrato'] ?? o['idContrato'] ?? '').toString();
    if (evento.isNotEmpty) return 'Evento · ${_curto(evento)}';
    if (contrato.isNotEmpty) return 'Contrato · ${_curto(contrato)}';
    return 'Cobrança · ${_curto(id)}';
  }

  String _taxaAplicada(Map<String, dynamic> o) {
    final bps = ComissaoPlataformaController.percentualBpsAplicadoDe(o);
    if (bps == null) return '—';
    return '${(bps / 100).toStringAsFixed(bps % 100 == 0 ? 0 : 2).replaceAll('.', ',')}%';
  }

  Widget _tabelaCobrancas() {
    return LayoutBuilder(builder: (context, box) {
      return Container(
        key: const ValueKey('comissoes-tabela'),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border)),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: box.maxWidth),
            child: DataTable(
              headingRowColor: WidgetStatePropertyAll(_bg),
              headingRowHeight: 54,
              dataRowMinHeight: 76,
              dataRowMaxHeight: 96,
              horizontalMargin: 24,
              columnSpacing: 24,
              dividerThickness: .6,
              headingTextStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, fontSize: 12, color: _muted),
              dataTextStyle: GoogleFonts.poppins(fontSize: 13, color: _ink),
              columns: [
                const DataColumn(label: Text('Referência')),
                if (_admin) const DataColumn(label: Text('Pagador')),
                const DataColumn(label: Text('Taxa aplicada')),
                const DataColumn(label: Text('Comissão'), numeric: true),
                const DataColumn(label: Text('Saldo'), numeric: true),
                const DataColumn(label: Text('Situação')),
                const DataColumn(label: Text('Detalhes')),
              ],
              rows: c.obrigacoes
                  .map((o) => DataRow(cells: [
                        DataCell(SizedBox(
                            width: 200,
                            child: Text(_refCobranca(o),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)))),
                        if (_admin)
                          DataCell(Text(
                              _curto((o['id_pagador'] ?? '—').toString()))),
                        DataCell(Text(_taxaAplicada(o))),
                        DataCell(Text(_reaisCentavos(
                            ComissaoPlataformaController.valorOriginalDe(o)))),
                        DataCell(Text(
                            _reaisCentavos(
                                ComissaoPlataformaController.saldoDe(o)),
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _ink))),
                        DataCell(ComissaoStatus(
                            status: o['status']?.toString(), pagador: !_admin)),
                        DataCell(_botaoDetalhes(o)),
                      ]))
                  .toList(),
            ),
          ),
        ),
      );
    });
  }

  Widget _botaoDetalhes(Map<String, dynamic> o) => TextButton.icon(
        onPressed: () => _abrirDetalheCobranca(o),
        style: TextButton.styleFrom(
            foregroundColor: _accent,
            iconColor: _accent,
            minimumSize: const Size(48, 48)),
        iconAlignment: IconAlignment.end,
        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
        label: const Text('Ver detalhes'),
      );

  Widget _cardCobranca(Map<String, dynamic> o) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_refCobranca(o),
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, fontSize: 15, color: _ink)),
        const SizedBox(height: 10),
        ComissaoStatus(status: o['status']?.toString(), pagador: !_admin),
        const SizedBox(height: 18),
        Text('Saldo da cobrança',
            style: GoogleFonts.poppins(fontSize: 12, color: _muted)),
        const SizedBox(height: 4),
        Text(_reaisCentavos(ComissaoPlataformaController.saldoDe(o)),
            style: GoogleFonts.poppins(
                fontSize: 24, fontWeight: FontWeight.w700, color: _ink)),
        const SizedBox(height: 8),
        Text(
            'Comissão: ${_reaisCentavos(ComissaoPlataformaController.valorOriginalDe(o))}',
            style: GoogleFonts.poppins(fontSize: 13, color: _muted)),
        Text('Taxa aplicada: ${_taxaAplicada(o)}',
            style: GoogleFonts.poppins(fontSize: 13, color: _muted)),
        const SizedBox(height: 12),
        const Divider(height: 1),
        Align(alignment: Alignment.centerRight, child: _botaoDetalhes(o)),
      ]),
    );
  }

  Widget _abaPoliticas(double pad, double w) {
    return ListView(
      padding: EdgeInsets.fromLTRB(pad, 14, pad, 28),
      children: [
        Text(
          'Regra de comissão — percentual e vigência aplicados às novas contratações elegíveis.',
          style: GoogleFonts.poppins(fontSize: 13, color: _muted, height: 1.35),
        ),
        const SizedBox(height: 6),
        Text(
          'Não há edição in-place: para mudar o percentual, crie outra política e ative-a. '
          'Cobranças já geradas mantêm a regra da época.',
          style:
              GoogleFonts.poppins(fontSize: 12.5, color: _muted, height: 1.35),
        ),
        const SizedBox(height: 12),
        if (c.politicas.isEmpty)
          _vazio(
            icon: Icons.rule_folder_outlined,
            titulo: 'Nenhuma política',
            mensagem: 'Use “Nova política” para salvar uma regra inativa.',
          )
        else
          ...c.politicas.map(_tilePolitica),
      ],
    );
  }

  Widget _tilePolitica(Map<String, dynamic> p) {
    final id = p['id_politica']?.toString() ?? p['id']?.toString() ?? '';
    final bps = (p['percentual_bps'] as num?)?.toInt();
    final ativa = p['ativa'] == true;
    final versao = p['versao'] ?? 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bps == null
                      ? 'Política incompleta (percentual ausente)'
                      : '${(bps / 100).toStringAsFixed(2)}% · versão $versao',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (ativa ? AdminPalette.success : _muted)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    ativa ? 'Ativa' : 'Inativa',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: ativa ? AdminPalette.success : _muted,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pagador ${(p['pagador'] ?? '—')} · '
                  'base serviços contratados · gatilho contratação',
                  style: GoogleFonts.poppins(fontSize: 12, color: _muted),
                ),
              ],
            ),
          ),
          if (_admin && !ativa)
            FilledButton(
              onPressed:
                  c.enviando.value ? null : () => _confirmarAtivacao(id, p),
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                minimumSize: const Size(88, 44),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Ativar',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _abaSimulador(double pad, double w) {
    return ListView(
      padding: EdgeInsets.fromLTRB(pad, 14, pad, 28),
      children: [_painelSimulador(w)],
    );
  }

  Future<void> _abrirSimuladorPagador() async {
    c.simulacaoTexto.value = '';
    c.simulacaoValorCentavos.value = 0;
    await mostrarComissaoModal(
      context: context,
      builder: (ctx) => ComissaoModal(
        titulo: 'Simular comissão',
        subtitulo: 'Uma estimativa separada do seu extrato',
        icone: Icons.calculate_outlined,
        accent: _accent,
        child: LayoutBuilder(
            builder: (context, box) => Obx(() {
                  c.simulacaoTexto.value;
                  return _painelSimulador(box.maxWidth);
                })),
      ),
    );
  }

  Widget _painelSimulador(double w) {
    final sideBySide =
        w >= 560 && MediaQuery.textScalerOf(context).scale(1) <= 1.3;
    return Form(
        key: _simForm,
        child: Container(
          padding: _admin ? const EdgeInsets.all(16) : EdgeInsets.zero,
          decoration: _admin
              ? BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_admin)
                Text(
                  'Simular comissão',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: _ink,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                'Informe o valor da contratação e a taxa que deseja comparar. A simulação não altera seu extrato.',
                style: GoogleFonts.poppins(fontSize: 12.5, color: _muted),
              ),
              const SizedBox(height: 14),
              if (sideBySide)
                Row(
                  children: [
                    Expanded(
                      child: _campoSim(_simPctCtrl, 'Taxa %', hint: 'Ex.: 5'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _campoSim(_simBaseCtrl, 'Base (R\$)',
                          hint: 'Ex.: 10000'),
                    ),
                  ],
                )
              else ...[
                _campoSim(_simPctCtrl, 'Taxa %', hint: 'Ex.: 5'),
                const SizedBox(height: 10),
                _campoSim(_simBaseCtrl, 'Base (R\$)', hint: 'Ex.: 10000'),
              ],
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () {
                  if (!(_simForm.currentState?.validate() ?? false)) return;
                  final pct = double.tryParse(
                        _simPctCtrl.text.trim().replaceAll(',', '.'),
                      ) ??
                      0;
                  final base = NumericInput.parseMoeda(_simBaseCtrl.text) ??
                      double.tryParse(
                        _simBaseCtrl.text.trim().replaceAll(',', '.'),
                      ) ??
                      0;
                  c.simularLocal(
                    percentualBps: (pct * 100).round(),
                    baseCentavos: (base * 100).round(),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(48, 48),
                ),
                child: Text(
                  'Calcular comissão',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
              ),
              if (c.simulacaoTexto.value.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _reaisCentavos(c.simulacaoValorCentavos.value),
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c.simulacaoTexto.value,
                        style: GoogleFonts.poppins(fontSize: 13, color: _ink),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Esta simulação não gera cobrança.',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: _accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ));
  }

  Widget _campoSim(TextEditingController ctrl, String label, {String? hint}) {
    return TextFormField(
      controller: ctrl,
      validator: (raw) {
        final taxa = ctrl == _simPctCtrl;
        final value = taxa
            ? double.tryParse((raw ?? '').trim().replaceAll(',', '.'))
            : NumericInput.parseMoeda(raw ?? '');
        if (value == null ||
            !value.isFinite ||
            value < 0 ||
            (taxa && value > 100)) {
          return taxa
              ? 'Informe uma taxa de 0 a 100%.'
              : 'Informe um valor válido.';
        }
        return null;
      },
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction:
          ctrl == _simPctCtrl ? TextInputAction.next : TextInputAction.done,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorMaxLines: 3,
        filled: true,
        fillColor: _bg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      style: GoogleFonts.poppins(fontSize: 14),
    );
  }

  Widget _vazio({
    required IconData icon,
    required String titulo,
    required String mensagem,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: _accent),
          const SizedBox(height: 10),
          Text(
            titulo,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: _ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            mensagem,
            textAlign: TextAlign.center,
            style:
                GoogleFonts.poppins(fontSize: 13, color: _muted, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _bannerErro(String msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminPalette.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminPalette.danger.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AdminPalette.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AdminPalette.danger,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _curto(String id) {
    if (id.length <= 14) return id;
    return '${id.substring(0, 10)}…';
  }

  Future<void> _abrirNovaPolitica() async {
    final pctCtrl = TextEditingController(text: '5');
    final wide = MediaQuery.sizeOf(context).width >= 768;
    Future<void> salvar(BuildContext ctx) async {
      final pct =
          double.tryParse(pctCtrl.text.trim().replaceAll(',', '.')) ?? 0;
      final bps = (pct * 100).round();
      final ok = await c.salvarPoliticaInativa(percentualBps: bps);
      if (!ctx.mounted) return;
      if (ok) {
        Navigator.of(ctx).pop();
        Get.snackbar(
          'Política',
          'Salva inativa — ative somente após aprovação comercial.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }

    final form = Builder(
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Obx(() {
          final busy = c.enviando.value;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Nova política',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cancelar',
                    onPressed: busy ? null : () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Text(
                'Regra de comissão. Será salva inativa até ativação explícita.',
                style: GoogleFonts.poppins(fontSize: 13, color: _muted),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: pctCtrl,
                enabled: !busy,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Percentual % (0–100; zero válido)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Resumo: percentual informado · estado inativo · '
                'base serviços contratados · pagador fornecedor.',
                style: GoogleFonts.poppins(fontSize: 12, color: _muted),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: busy ? null : () => salvar(ctx),
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  minimumSize: const Size(48, 48),
                ),
                child: busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Salvar política inativa',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                      ),
              ),
              TextButton(
                onPressed: busy ? null : () => Navigator.of(ctx).pop(),
                child: Text('Cancelar', style: GoogleFonts.poppins()),
              ),
            ],
          );
        }),
      ),
    );

    if (wide) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: form,
          ),
        ),
      );
    } else {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: form,
        ),
      );
    }
    pctCtrl.dispose();
  }

  Future<void> _confirmarAtivacao(
    String id,
    Map<String, dynamic> p,
  ) async {
    final bps = (p['percentual_bps'] as num?)?.toInt();
    final pct = bps == null ? '—' : '${(bps / 100).toStringAsFixed(2)}%';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Ativar política?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'A regra $pct passará a valer para novas contratações elegíveis. '
          'Obrigações já geradas preservam o percentual aplicado na época.',
          style: GoogleFonts.poppins(fontSize: 13.5, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: _accent),
            child: const Text('Ativar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final sucesso = await c.ativar(id);
      if (sucesso) {
        Get.snackbar(
          'Política',
          'Ativada. Cobranças anteriores não são recalculadas.',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else if (c.erro.value.isNotEmpty) {
        Get.snackbar(
          'Não foi possível ativar',
          c.erro.value,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  Future<void> _abrirDetalheCobranca(Map<String, dynamic> o) async {
    await mostrarComissaoModal(
      context: context,
      builder: (_) =>
          ComissaoDetalhe(controller: c, obrigacao: o, accent: _accent),
    );
  }
}
