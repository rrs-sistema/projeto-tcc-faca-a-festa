import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/core/utils/numeric_input.dart';
import 'package:app_faca_festa/domain/services/resumo_financeiro_fornecedor_service.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/controllers/financeiro_fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/sections/fornecedor_premium_layout.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/widgets/festa_app_bar.dart';

/// Financeiro privado do fornecedor — layout premium (consulta → síntese → lançamento).
class FinanceiroFornecedorPage extends StatefulWidget {
  const FinanceiroFornecedorPage({
    super.key,
    required this.controller,
    required this.themeController,
  });

  final FinanceiroFornecedorController controller;
  final EventThemeController themeController;

  @override
  State<FinanceiroFornecedorPage> createState() =>
      _FinanceiroFornecedorPageState();
}

class _FinanceiroFornecedorPageState extends State<FinanceiroFornecedorPage> {
  final _filtroEventoCtrl = TextEditingController();
  bool _filtrosAbertos = false;
  bool _pendenciasAbertas = false;
  bool _comoCalculadoAberto = false;
  bool _custoDetalheAberto = false;

  @override
  void initState() {
    super.initState();
    final id = widget.controller.filtroEventoId.value;
    if (id.isNotEmpty) _filtroEventoCtrl.text = id;
    // Garante skeleton já na 1ª frame (antes do post-frame iniciar).
    widget.controller.carregando.value = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.iniciar();
    });
  }

  @override
  void dispose() {
    _filtroEventoCtrl.dispose();
    super.dispose();
  }

  String _reais(double? v) {
    if (v == null) return '—';
    return NumericInput.dinheiro(v);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Obx(() {
      final r = c.resumo.value;
      return Scaffold(
        backgroundColor: FornecedorPremiumPalette.background,
        appBar: FestaAppBar(
          titulo: 'Financeiro',
          themeController: widget.themeController,
          acoes: [
            IconButton(
              tooltip: 'Atualizar',
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: c.enviando.value ? null : c.iniciar,
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final pad = FornecedorBreakpoints.padding(w).clamp(12.0, 20.0);
            final maxW = w >= 1280 ? 1100.0 : w;
            final loading = c.valoresEmCarga;
            // Enquanto carrega, sempre monta o shell com skeleton — nunca o empty.
            final display = r ??
                ResumoFinanceiroFornecedor(idFornecedor: c.idFornecedor);
            final mostrarEmpty = !loading &&
                r == null &&
                c.primeiraCargaConcluida.value;
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(pad, 12, pad, 24),
                  children: [
                    _cabecalho(c, w),
                    if (c.erro.value.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _bannerErro(c.erro.value),
                    ],
                    const SizedBox(height: 8),
                    _barraContextual(c, w),
                    if (mostrarEmpty)
                      PremiumEmptyState(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Sem resumo ainda',
                        message: c.autorizado
                            ? 'Quando houver contrato fechado ou lançamento, o resumo aparece aqui.'
                            : 'Sem autorização para o financeiro privado.',
                      )
                    else ...[
                      if (loading && r != null) ...[
                        const SizedBox(height: 8),
                        _bannerAtualizando(),
                      ],
                      const SizedBox(height: 10),
                      _situacaoAgora(c, display, loading: loading),
                      const SizedBox(height: 10),
                      _listaContratos(c, loading: loading),
                      const SizedBox(height: 10),
                      _painelResumo(display, w, loading: loading),
                      const SizedBox(height: 10),
                      _resultadoECaixa(display, w, loading: loading),
                      if (!loading && c.alertasAgrupados.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _alertas(c),
                      ],
                      if (!loading &&
                          (c.custos.isNotEmpty ||
                              c.movimentos.isNotEmpty)) ...[
                        const SizedBox(height: 10),
                        _lancamentos(c, w),
                      ],
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

  String _rotuloEventoCurto(String id) {
    if (id.isEmpty) return '—';
    if (id.length <= 12) return id;
    if (id.contains('-') && id.length >= 20) {
      return '${id.substring(0, 8)}…${id.substring(id.length - 4)}';
    }
    return '${id.substring(0, 10)}…';
  }

  Widget _cabecalho(FinanceiroFornecedorController c, double w) {
    final compact = FornecedorBreakpoints.phone(w);
    final intro = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seu financeiro privado · BRL',
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            color: FornecedorPremiumPalette.muted,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          'Repasse da plataforma e seus lançamentos manuais.',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: FornecedorPremiumPalette.softMuted,
            height: 1.3,
          ),
        ),
      ],
    );
    final acoes = PopupMenuButton<String>(
      enabled: !c.enviando.value,
      tooltip: 'Lançar',
      onSelected: (v) {
        if (v == 'custo') _abrirFormulario(custo: true);
        if (v == 'recebimento') _abrirFormulario(custo: false);
        if (v == 'comissao') _informarComissao();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'custo',
          child: Text('Lançar custo', style: GoogleFonts.poppins(fontSize: 13)),
        ),
        PopupMenuItem(
          value: 'recebimento',
          child: Text('Lançar recebimento próprio',
              style: GoogleFonts.poppins(fontSize: 13)),
        ),
        PopupMenuItem(
          value: 'comissao',
          child: Text('Informar comissão/taxas',
              style: GoogleFonts.poppins(fontSize: 13)),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: FornecedorPremiumPalette.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, size: 18, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              'Lançar',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
    if (compact) {
      return Row(
        children: [
          Expanded(child: intro),
          const SizedBox(width: 8),
          acoes,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: intro),
        const SizedBox(width: 12),
        acoes,
      ],
    );
  }

  Widget _situacaoAgora(
    FinanceiroFornecedorController c,
    ResumoFinanceiroFornecedor r, {
    bool loading = false,
  }) {
    final aReceber = r.aReceber;
    final String titulo;
    final String corpo;
    final Color cor;
    final IconData icone;
    if (loading) {
      titulo = 'Carregando valores…';
      corpo = 'Buscando contratos e repasses da plataforma.';
      cor = FornecedorPremiumPalette.primary;
      icone = Icons.hourglass_top_rounded;
    } else if (aReceber > 0.009) {
      titulo = 'Você tem ${_reais(aReceber)} a receber';
      corpo = r.recebido <= 0
          ? 'Contrato fechado — ainda sem repasse confirmado da plataforma.'
          : 'Parte já recebida. O restante aguarda repasse.';
      cor = FornecedorPremiumPalette.amber;
      icone = Icons.schedule_rounded;
    } else if (r.contratado > 0) {
      titulo = 'Nada pendente a receber';
      corpo = 'Contratos quitados na visão de repasse.';
      cor = FornecedorPremiumPalette.emerald;
      icone = Icons.check_circle_outline_rounded;
    } else {
      titulo = 'Sem contratos no filtro';
      corpo = 'Quando um organizador fechar com você, o valor aparece aqui.';
      cor = FornecedorPremiumPalette.indigo;
      icone = Icons.info_outline_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cor.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: loading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: cor,
                        ),
                      )
                    : Icon(icone, color: cor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Situação agora',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: FornecedorPremiumPalette.softMuted,
                      ),
                    ),
                    if (loading) ...[
                      const SizedBox(height: 6),
                      _valorSkeleton(width: 220, height: 18),
                      const SizedBox(height: 8),
                      _valorSkeleton(width: 280, height: 12),
                    ] else ...[
                      Text(
                        titulo,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: FornecedorPremiumPalette.text,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        corpo,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          height: 1.35,
                          color: FornecedorPremiumPalette.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (!loading) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Get.toNamed(
                  '/acompanhamento-fornecedor',
                  arguments: {'idFornecedor': c.idFornecedor},
                ),
                icon: const Icon(Icons.handshake_outlined, size: 18),
                label: Text(
                  'Ver contratos e repasse',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: FornecedorPremiumPalette.primary,
                  side: BorderSide(
                    color: FornecedorPremiumPalette.primary
                        .withValues(alpha: 0.35),
                  ),
                  minimumSize: const Size(48, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _listaContratos(
    FinanceiroFornecedorController c, {
    bool loading = false,
  }) {
    final lista = c.contratosListados;
    if (loading && lista.isEmpty) {
      return PremiumSectionShell(
        title: 'Seus contratos',
        subtitle: 'Carregando…',
        icon: Icons.receipt_long_outlined,
        color: FornecedorPremiumPalette.emerald,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          children: [
            for (var i = 0; i < 2; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _valorSkeleton(width: 160, height: 14),
                        const SizedBox(height: 6),
                        _valorSkeleton(width: 120, height: 11),
                      ],
                    ),
                  ),
                  _valorSkeleton(width: 88, height: 16),
                ],
              ),
            ],
          ],
        ),
      );
    }
    if (lista.isEmpty) {
      return PremiumSectionShell(
        title: 'Seus contratos',
        subtitle: 'Origem do valor a receber',
        icon: Icons.receipt_long_outlined,
        color: FornecedorPremiumPalette.emerald,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Text(
          'Nenhum contrato fechado neste filtro.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: FornecedorPremiumPalette.muted,
          ),
        ),
      );
    }

    return PremiumSectionShell(
      title: 'Seus contratos',
      subtitle: '${lista.length} contrato${lista.length == 1 ? '' : 's'}',
      icon: Icons.receipt_long_outlined,
      color: FornecedorPremiumPalette.emerald,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Column(
        children: [
          for (var i = 0; i < lista.length && i < 8; i++) ...[
            InkWell(
              onTap: () => Get.toNamed(
                '/acompanhamento-fornecedor',
                arguments: {'idFornecedor': c.idFornecedor},
              ),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (lista[i].nomeServico ??
                                    lista[i].categoria ??
                                    'Serviço')
                                .trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: FornecedorPremiumPalette.text,
                            ),
                          ),
                          Text(
                            _rotuloSituacaoContrato(lista[i]),
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              color: FornecedorPremiumPalette.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _reais(lista[i].valorContratado),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: FornecedorPremiumPalette.text,
                          ),
                        ),
                        if (lista[i].aReceber > 0.009)
                          Text(
                            'A receber ${_reais(lista[i].aReceber)}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: FornecedorPremiumPalette.amber,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded,
                        color: FornecedorPremiumPalette.softMuted),
                  ],
                ),
              ),
            ),
            if (i < lista.length - 1 && i < 7)
              const Divider(height: 1, color: FornecedorPremiumPalette.border),
          ],
        ],
      ),
    );
  }

  String _rotuloSituacaoContrato(VendaFornecedorFato v) {
    final s = (v.situacao ?? '').toLowerCase();
    if (s == 'recebido' || v.aReceber <= 0.009) return 'Repasse quitado';
    if (s == 'parcial' || v.recebidoConfirmado > 0) {
      return 'Repasse parcial';
    }
    return 'Aguardando repasse da plataforma';
  }

  Widget _barraContextual(FinanceiroFornecedorController c, double w) {
    final ids = c.eventosConhecidosIds;
    final selecionado = c.filtroEventoId.value;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: FornecedorPremiumPalette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FornecedorPremiumPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  selecionado.isEmpty
                      ? 'Mostrando todos os eventos'
                      : 'Filtro: ${_rotuloEventoCurto(selecionado)}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: FornecedorPremiumPalette.text,
                  ),
                ),
              ),
              IconButton(
                tooltip: _filtrosAbertos ? 'Fechar filtros' : 'Filtrar evento',
                onPressed: () =>
                    setState(() => _filtrosAbertos = !_filtrosAbertos),
                icon: Icon(
                  _filtrosAbertos
                      ? Icons.filter_alt_off_rounded
                      : Icons.filter_alt_outlined,
                  color: FornecedorPremiumPalette.primary,
                ),
              ),
            ],
          ),
          if (_filtrosAbertos) ...[
            if (ids.isNotEmpty) ...[
              const SizedBox(height: 4),
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        visualDensity: VisualDensity.compact,
                        label: Text('Todos',
                            style: GoogleFonts.poppins(fontSize: 11.5)),
                        selected: selecionado.isEmpty,
                        onSelected: (_) {
                          c.limparFiltroEvento();
                          _filtroEventoCtrl.clear();
                          c.iniciar();
                        },
                        selectedColor: FornecedorPremiumPalette.primary
                            .withValues(alpha: 0.12),
                        checkmarkColor: FornecedorPremiumPalette.primary,
                      ),
                    ),
                    ...ids.map(
                      (id) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          visualDensity: VisualDensity.compact,
                          label: Text(
                            _rotuloEventoCurto(id),
                            style: GoogleFonts.poppins(fontSize: 11.5),
                          ),
                          selected: selecionado == id,
                          onSelected: (_) {
                            c.aplicarFiltroEvento(id);
                            _filtroEventoCtrl.text = id;
                            c.iniciar();
                          },
                          selectedColor: FornecedorPremiumPalette.primary
                              .withValues(alpha: 0.12),
                          checkmarkColor: FornecedorPremiumPalette.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _filtroEventoCtrl,
                    decoration: InputDecoration(
                      hintText: 'ID do evento',
                      isDense: true,
                      filled: true,
                      fillColor: FornecedorPremiumPalette.surfaceAlt,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: FornecedorPremiumPalette.border),
                      ),
                    ),
                    style: GoogleFonts.poppins(fontSize: 13),
                    onSubmitted: (v) {
                      c.aplicarFiltroEvento(v);
                      c.iniciar();
                    },
                  ),
                ),
                const SizedBox(width: 6),
                FilledButton(
                  onPressed: () {
                    c.aplicarFiltroEvento(_filtroEventoCtrl.text);
                    c.iniciar();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: FornecedorPremiumPalette.primary,
                    minimumSize: const Size(40, 40),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(
                    'OK',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: 'Limpar',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    _filtroEventoCtrl.clear();
                    c.limparFiltroEvento();
                    c.iniciar();
                  },
                  icon: const Icon(Icons.clear_rounded, size: 20),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// A receber + métricas em um único bloco compacto.
  Widget _painelResumo(
    ResumoFinanceiroFornecedor r,
    double w, {
    bool loading = false,
  }) {
    final vencido = !loading && r.contasVencidas > 0;
    final largo = w >= 720;
    final metricas = [
      ('Fechado', _reais(r.contratado)),
      ('Já recebido', _reais(r.recebido)),
      ('Seus custos', _reais(r.custoDiretoPrevisto)),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: FornecedorPremiumPalette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FornecedorPremiumPalette.primary.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (largo)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 2,
                  child: _blocoAReceber(r, vencido, loading: loading),
                ),
                const SizedBox(width: 12),
                ...metricas.map(
                  (m) => Expanded(
                    child: _miniMetrica(m.$1, m.$2, loading: loading),
                  ),
                ),
              ],
            )
          else ...[
            _blocoAReceber(r, vencido, loading: loading),
            const SizedBox(height: 10),
            Row(
              children: metricas
                  .map((m) =>
                      Expanded(child: _miniMetrica(m.$1, m.$2, loading: loading)))
                  .toList(),
            ),
          ],
          if (!loading)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () =>
                    setState(() => _custoDetalheAberto = !_custoDetalheAberto),
                style: TextButton.styleFrom(
                  foregroundColor: FornecedorPremiumPalette.primary,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                child: Text(
                  _custoDetalheAberto ? 'Ocultar custos' : 'Detalhar custos',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          if (!loading && _custoDetalheAberto)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: FornecedorPremiumPalette.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _linhaValor('Realizado', _reais(r.custoRealizado)),
                  const SizedBox(height: 6),
                  _linhaValor(
                      'Restante previsto', _reais(r.custoRestantePrevisto)),
                  const SizedBox(height: 6),
                  _linhaValor(
                    'Previsto direto',
                    _reais(r.custoDiretoPrevisto),
                    destaque: true,
                  ),
                  if (!r.outrasDespesasAusentes) ...[
                    const SizedBox(height: 6),
                    _linhaValor(
                      'Outras despesas',
                      _reais(r.outrasDespesasInformadas),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _blocoAReceber(
    ResumoFinanceiroFornecedor r,
    bool vencido, {
    bool loading = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'A receber da plataforma',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: FornecedorPremiumPalette.muted,
          ),
        ),
        if (loading)
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 4),
            child: _valorSkeleton(width: 140, height: 26),
          )
        else
          Text(
            _reais(r.aReceber),
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: FornecedorPremiumPalette.text,
              height: 1.15,
            ),
          ),
        if (loading)
          _valorSkeleton(width: 200, height: 11)
        else
          Text(
            vencido
                ? 'Inclui ${_reais(r.contasVencidas)} vencido(s)'
                : 'Saldo de contratos ainda sem repasse',
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              color: vencido
                  ? FornecedorPremiumPalette.amber
                  : FornecedorPremiumPalette.muted,
            ),
          ),
      ],
    );
  }

  Widget _miniMetrica(String rotulo, String valor, {bool loading = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rotulo,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: FornecedorPremiumPalette.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (loading)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: _valorSkeleton(width: 72, height: 16),
            )
          else
            Text(
              valor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: FornecedorPremiumPalette.text,
              ),
            ),
        ],
      ),
    );
  }

  Widget _resultadoECaixa(
    ResumoFinanceiroFornecedor r,
    double w, {
    bool loading = false,
  }) {
    final sideBySide = w >= 768;
    final resultado = PremiumSectionShell(
      title: 'Quanto sobra (estimado)',
      subtitle: loading
          ? 'Calculando…'
          : r.completo
              ? 'Receita menos custos que você informou'
              : 'Ainda incompleto — faltam comissão ou custos',
      icon: Icons.insights_outlined,
      color: loading
          ? FornecedorPremiumPalette.primary
          : r.completo
              ? FornecedorPremiumPalette.emerald
              : FornecedorPremiumPalette.amber,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _linhaValor(
            'Previsto',
            _reais(r.resultadoDiretoPrevisto),
            destaque: true,
            loading: loading,
          ),
          const SizedBox(height: 8),
          _linhaValor(
            'Já realizado',
            _reais(r.resultadoDiretoRealizado),
            loading: loading,
          ),
          const SizedBox(height: 8),
          _linhaValor(
            'Quanto sobra após custos',
            r.margemContribuicao == null ? '—' : _reais(r.margemContribuicao),
            nota: 'Não é lucro líquido final',
            loading: loading,
          ),
          if (!loading && !r.completo) ...[
            const SizedBox(height: 10),
            if (!_pendenciasAbertas)
              TextButton.icon(
                onPressed: () => setState(() => _pendenciasAbertas = true),
                icon: const Icon(Icons.info_outline_rounded, size: 18),
                label: Text(
                  'Ver o que falta',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              )
            else ...[
              _pendenciasTexto(r),
              Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: () => _informarComissao(),
                    child: Text(
                      'Informar comissão',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _abrirFormulario(custo: true),
                    child: Text(
                      'Lançar custo',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _pendenciasAbertas = false),
                    child: Text(
                      'Ocultar',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
          if (!loading) ...[
            TextButton(
              onPressed: () =>
                  setState(() => _comoCalculadoAberto = !_comoCalculadoAberto),
              child: Text(
                _comoCalculadoAberto ? 'Ocultar cálculo' : 'Como é calculado',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: FornecedorPremiumPalette.primary,
                ),
              ),
            ),
            if (_comoCalculadoAberto)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FornecedorPremiumPalette.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Receita do contrato − seus custos diretos '
                  '(− comissão, taxas e tributos, se informados).',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: FornecedorPremiumPalette.muted,
                    height: 1.4,
                  ),
                ),
              ),
          ],
        ],
      ),
    );

    final temSaldoInicial = !loading && r.saldoInicialInformado != null;
    final caixaVazio =
        !loading && r.entradasCaixa <= 0 && r.saidasCaixa <= 0;
    final caixa = PremiumSectionShell(
      title: 'Movimentações que você registrou',
      subtitle: loading
          ? 'Carregando…'
          : temSaldoInicial
              ? 'Com saldo inicial informado'
              : 'Não é extrato bancário — só o que você lançou',
      icon: Icons.account_balance_outlined,
      color: FornecedorPremiumPalette.primary,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (caixaVazio)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Nenhum lançamento ainda. O repasse da plataforma aparece em '
                '“Ver contratos e repasse”. Use “Lançar” para custos ou '
                'recebimentos próprios.',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  height: 1.4,
                  color: FornecedorPremiumPalette.muted,
                ),
              ),
            ),
          _linhaValor('Entradas', _reais(r.entradasCaixa), loading: loading),
          const SizedBox(height: 8),
          _linhaValor('Saídas', _reais(r.saidasCaixa), loading: loading),
          const SizedBox(height: 8),
          _linhaValor(
            'Movimento líquido',
            _reais(r.movimentoLiquido),
            destaque: true,
            loading: loading,
          ),
          if (temSaldoInicial) ...[
            const SizedBox(height: 8),
            _linhaValor('Saldo final informado', _reais(r.saldoFinal)),
          ],
          if (!loading && r.adiantamentosCaixa > 0) ...[
            const SizedBox(height: 10),
            Text(
              'Adiantamentos: ${_reais(r.adiantamentosCaixa)} — '
              'não contam como receita realizada.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: FornecedorPremiumPalette.muted,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );

    if (!sideBySide) {
      return Column(children: [resultado, const SizedBox(height: 8), caixa]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: resultado),
        const SizedBox(width: 8),
        Expanded(child: caixa),
      ],
    );
  }

  Widget _pendenciasTexto(ResumoFinanceiroFornecedor r) {
    final itens = <String>[];
    if (r.comissaoInformada == null &&
        r.taxasInformadas == null &&
        r.tributosInformados == null) {
      itens.add('Comissão, taxas ou tributos ainda não informados');
    }
    if (r.outrasDespesasAusentes) {
      itens.add(
          'Outras despesas não informadas (ficam explícitas como ausentes)');
    }
    if (itens.isEmpty) {
      itens.add('Consulta incompleta — revise os componentes do resultado');
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FornecedorPremiumPalette.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: itens
            .map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: FornecedorPremiumPalette.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          color: FornecedorPremiumPalette.text,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _alertas(FinanceiroFornecedorController c) {
    final grupos = c.alertasAgrupados;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: FornecedorPremiumPalette.amber.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: FornecedorPremiumPalette.amber.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: FornecedorPremiumPalette.amber,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  grupos.length == 1
                      ? 'Para deixar o resultado completo'
                      : '${grupos.length} pendências',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: FornecedorPremiumPalette.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...grupos.map((g) {
            final humana = _mensagemAlertaHumana(g.mensagem);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                humana,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: FornecedorPremiumPalette.text,
                  height: 1.35,
                ),
              ),
            );
          }),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              FilledButton.tonal(
                onPressed: c.enviando.value ? null : _informarComissao,
                child: Text(
                  'Informar comissão',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
              OutlinedButton(
                onPressed:
                    c.enviando.value ? null : () => _abrirFormulario(custo: true),
                child: Text(
                  'Lançar custo',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _mensagemAlertaHumana(String msg) {
    final m = msg.toLowerCase();
    if (m.contains('comissão') || m.contains('comissao')) {
      return 'Informe comissão, taxas ou tributos para fechar o cálculo.';
    }
    if (m.contains('outras despesas')) {
      return 'Se tiver outras despesas, lance um custo — senão ficam como ausentes.';
    }
    return msg;
  }

  Future<void> _informarComissao() async {
    final c = widget.controller;
    final ctrl = TextEditingController(
      text: c.comissaoInformada.value == null
          ? ''
          : NumericInput.dinheiro(c.comissaoInformada.value!),
    );
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final inset = MediaQuery.viewInsetsOf(ctx).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + inset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Informar comissão / taxas',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Valor estimado que você desconta do resultado '
                '(não cria lançamento de caixa).',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: FornecedorPremiumPalette.muted,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: ctrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [NumericInput.moeda()],
                decoration: InputDecoration(
                  labelText: 'Valor (R\$)',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: FornecedorPremiumPalette.primary,
                  minimumSize: const Size(48, 46),
                ),
                child: Text(
                  'Aplicar no resultado',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        );
      },
    );
    final texto = ctrl.text;
    ctrl.dispose();
    if (ok != true) return;
    final v = NumericInput.parseMoeda(texto);
    if (v == null || v < 0) return;
    await c.informarDeducoes(comissao: v);
  }

  Widget _lancamentos(FinanceiroFornecedorController c, double w) {
    final wide = w >= 768;
    return PremiumSectionShell(
      title: 'Lançamentos recentes',
      subtitle: 'Custos e movimentos já registrados',
      icon: Icons.receipt_long_outlined,
      color: FornecedorPremiumPalette.primary,
      child: wide
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: FornecedorPremiumPalette.muted,
                ),
                dataTextStyle: GoogleFonts.poppins(fontSize: 12.5),
                columns: const [
                  DataColumn(label: Text('Tipo')),
                  DataColumn(label: Text('Evento')),
                  DataColumn(label: Text('Descrição')),
                  DataColumn(label: Text('Valor'), numeric: true),
                ],
                rows: [
                  ...c.custos.take(12).map(
                        (x) => DataRow(cells: [
                          const DataCell(Text('Custo')),
                          DataCell(Text(_rotuloEventoCurto(x.idEvento))),
                          DataCell(Text(x.tipo)),
                          DataCell(Text(_reais(x.incorrido))),
                        ]),
                      ),
                  ...c.movimentos.take(12).map(
                        (m) => DataRow(cells: [
                          DataCell(Text(m.entrada ? 'Entrada' : 'Saída')),
                          DataCell(Text(_rotuloEventoCurto(m.idEvento ?? ''))),
                          DataCell(Text(m.descricao ?? '—')),
                          DataCell(Text(_reais(m.valor))),
                        ]),
                      ),
                ],
              ),
            )
          : Column(
              children: [
                ...c.custos.take(8).map(
                      (x) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Custo · ${x.tipo}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          'Evento ${_rotuloEventoCurto(x.idEvento)}',
                          style: GoogleFonts.poppins(fontSize: 11.5),
                        ),
                        trailing: Text(
                          _reais(x.incorrido),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                ...c.movimentos.take(8).map(
                      (m) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          m.entrada ? 'Entrada' : 'Saída',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          m.descricao ??
                              'Evento ${_rotuloEventoCurto(m.idEvento ?? '')}',
                          style: GoogleFonts.poppins(fontSize: 11.5),
                        ),
                        trailing: Text(
                          _reais(m.valor),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
              ],
            ),
    );
  }

  Widget _linhaValor(
    String label,
    String valor, {
    bool destaque = false,
    String? nota,
    bool loading = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: FornecedorPremiumPalette.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (nota != null)
                Text(
                  nota,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: FornecedorPremiumPalette.softMuted,
                  ),
                ),
            ],
          ),
        ),
        if (loading)
          _valorSkeleton(
            width: destaque ? 110 : 88,
            height: destaque ? 24 : 18,
          )
        else
          Text(
            valor,
            style: GoogleFonts.poppins(
              fontSize: destaque ? 22 : 16,
              fontWeight: FontWeight.w800,
              color: FornecedorPremiumPalette.text,
            ),
          ),
      ],
    );
  }

  Widget _valorSkeleton({required double width, required double height}) {
    return _ValorPulse(width: width, height: height);
  }

  Widget _bannerAtualizando() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: FornecedorPremiumPalette.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Atualizando resumo da plataforma…',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: FornecedorPremiumPalette.primary,
                fontWeight: FontWeight.w500,
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

  Future<void> _abrirFormulario({required bool custo}) async {
    final c = widget.controller;
    final wide = MediaQuery.sizeOf(context).width >= 768;
    if (wide) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _FormularioLancamento(
              custo: custo,
              controller: c,
              eventoInicial: c.filtroEventoId.value,
              onFechar: () => Navigator.of(ctx).pop(),
            ),
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
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: _FormularioLancamento(
            custo: custo,
            controller: c,
            eventoInicial: c.filtroEventoId.value,
            onFechar: () => Navigator.of(ctx).pop(),
          ),
        ),
      );
    }
  }
}

class _ValorPulse extends StatefulWidget {
  const _ValorPulse({required this.width, required this.height});

  final double width;
  final double height;

  @override
  State<_ValorPulse> createState() => _ValorPulseState();
}

class _ValorPulseState extends State<_ValorPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = 0.08 + (_ctrl.value * 0.10);
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: FornecedorPremiumPalette.primary.withValues(alpha: t),
            borderRadius: BorderRadius.circular(6),
          ),
        );
      },
    );
  }
}

class _FormularioLancamento extends StatefulWidget {
  const _FormularioLancamento({
    required this.custo,
    required this.controller,
    required this.eventoInicial,
    required this.onFechar,
  });

  final bool custo;
  final FinanceiroFornecedorController controller;
  final String eventoInicial;
  final VoidCallback onFechar;

  @override
  State<_FormularioLancamento> createState() => _FormularioLancamentoState();
}

class _FormularioLancamentoState extends State<_FormularioLancamento> {
  late final TextEditingController _eventoCtrl;
  late final TextEditingController _valorCtrl;
  String? _erroEvento;
  String? _erroValor;
  final _valorFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _eventoCtrl = TextEditingController(text: widget.eventoInicial);
    _valorCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _eventoCtrl.dispose();
    _valorCtrl.dispose();
    _valorFocus.dispose();
    super.dispose();
  }

  int? _centavosDeReais() {
    final reais = NumericInput.parseMoeda(_valorCtrl.text);
    if (reais == null || !reais.isFinite || reais <= 0) return null;
    return (reais * 100).round();
  }

  bool _validar() {
    setState(() {
      _erroEvento = _eventoCtrl.text.trim().isEmpty ? 'Informe o evento' : null;
      _erroValor =
          _centavosDeReais() == null ? 'Informe um valor válido' : null;
    });
    return _erroEvento == null && _erroValor == null;
  }

  Future<void> _enviar({
    required bool estoqueConsumo,
    required bool adiantamento,
  }) async {
    if (!_validar()) return;
    if (widget.controller.enviando.value) return;
    final centavos = _centavosDeReais()!;
    final ev = _eventoCtrl.text.trim();
    final ok = widget.custo
        ? await widget.controller.registrarCustoManual(
            idEvento: ev,
            valorCentavos: centavos,
            tipo: 'material',
            origem: estoqueConsumo ? 'estoque_consumo' : 'manual',
            desembolsoCentavos: estoqueConsumo ? 0 : centavos,
          )
        : await widget.controller.registrarRecebimento(
            idEvento: ev,
            valorCentavos: centavos,
            tipo: adiantamento ? 'adiantamento' : 'recebimento',
            execucaoConfirmada: !adiantamento,
          );
    if (!mounted) return;
    if (ok) {
      widget.onFechar();
      Get.snackbar(
        widget.custo ? 'Custo' : 'Recebimento',
        widget.custo
            ? (estoqueConsumo
                ? 'Consumo de estoque registrado (sem nova saída de caixa).'
                : 'Custo com desembolso registrado.')
            : (adiantamento
                ? 'Adiantamento registrado (só caixa).'
                : 'Recebimento com execução registrado.'),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Obx(() {
        final busy = c.enviando.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.custo ? 'Lançar custo' : 'Registrar recebimento',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Cancelar',
                  onPressed: busy ? null : widget.onFechar,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            Text(
              widget.custo
                  ? 'Custo interno privado. Consumo de estoque não gera nova saída de caixa.'
                  : 'Confirmação própria do fornecedor — não copia pagamento do cliente.',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: FornecedorPremiumPalette.muted,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _eventoCtrl,
              enabled: !busy,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _valorFocus.requestFocus(),
              decoration: InputDecoration(
                labelText: 'Identificador do evento',
                errorText: _erroEvento,
                helperText: 'Obrigatório · permanece interno',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _valorCtrl,
              focusNode: _valorFocus,
              enabled: !busy,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [NumericInput.moeda()],
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Valor (R\$)',
                errorText: _erroValor,
                helperText: 'Enviado ao backend em centavos',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 16),
            if (widget.custo) ...[
              FilledButton(
                onPressed: busy
                    ? null
                    : () => _enviar(estoqueConsumo: false, adiantamento: false),
                style: FilledButton.styleFrom(
                  backgroundColor: FornecedorPremiumPalette.primary,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: busy
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Salvar custo com desembolso',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                      ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: busy
                    ? null
                    : () => _enviar(estoqueConsumo: true, adiantamento: false),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: Text(
                  'Consumo de estoque (sem saída de caixa)',
                  style: GoogleFonts.poppins(),
                ),
              ),
            ] else ...[
              FilledButton(
                onPressed: busy
                    ? null
                    : () => _enviar(estoqueConsumo: false, adiantamento: false),
                style: FilledButton.styleFrom(
                  backgroundColor: FornecedorPremiumPalette.primary,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: busy
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Recebimento com execução',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                      ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: busy
                    ? null
                    : () => _enviar(estoqueConsumo: false, adiantamento: true),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: Text(
                  'Adiantamento (só caixa)',
                  style: GoogleFonts.poppins(),
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: busy ? null : widget.onFechar,
              child: Text('Cancelar', style: GoogleFonts.poppins()),
            ),
          ],
        );
      }),
    );
  }
}
