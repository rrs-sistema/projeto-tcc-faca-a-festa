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
  bool _filtrosAbertos = false;
  bool _pendenciasAbertas = false;
  bool _comoCalculadoAberto = false;
  bool _custoDetalheAberto = false;

  @override
  void initState() {
    super.initState();
    // Garante skeleton já na 1ª frame (antes do post-frame iniciar).
    widget.controller.carregando.value = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.iniciar();
    });
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
      final loading = c.valoresEmCarga;
      final erro = c.erro.value;
      final temPendente = c.recebimentoPendente.value != null;
      final temRecebimentos = c.recebimentos.isNotEmpty;
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
            // Enquanto carrega, sempre monta o shell com skeleton — nunca o empty.
            final display =
                r ?? ResumoFinanceiroFornecedor(idFornecedor: c.idFornecedor);
            final mostrarEmpty =
                !loading && r == null && c.primeiraCargaConcluida.value;
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(pad, 12, pad, 24),
                  children: [
                    _cabecalho(c, w),
                    if (c.custoPendente.value != null)
                      ListTile(
                          title: const Text('Custo com envio pendente'),
                          trailing: TextButton(
                              onPressed: c.enviando.value
                                  ? null
                                  : c.retomarCustoPendente,
                              child: const Text('Retomar custo original'))),
                    Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                            onPressed: () =>
                                Get.toNamed('/fornecedor/planejamento'),
                            icon: const Icon(Icons.insights),
                            label: const Text(
                                'Planejar recebimentos e despesas'))),
                    if (temPendente) ...[
                      const SizedBox(height: 8),
                      Card(
                          child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                        'Recebimento com resultado desconhecido. A mesma operação será conciliada antes de qualquer novo lançamento.'),
                                    TextButton(
                                        onPressed: c.enviando.value
                                            ? null
                                            : c.retomarRecebimentoPendente,
                                        child: const Text(
                                            'Retomar recebimento pendente')),
                                  ]))),
                    ],
                    if (erro.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _bannerErro(erro),
                      if (c.diagnosticoConsulta.value != null)
                        ExpansionTile(
                          title: const Text('Detalhes da consulta'),
                          children: [
                            ListTile(
                                title: Text(
                                    'Código: ${c.diagnosticoConsulta.value!.codigo}'),
                                subtitle:
                                    Text(c.diagnosticoConsulta.value!.detalhe))
                          ],
                        ),
                    ],
                    const SizedBox(height: 8),
                    _barraContextual(c, w),
                    if (mostrarEmpty)
                      PremiumEmptyState(
                        icon: Icons.account_balance_wallet_outlined,
                        title: c.erro.value.isNotEmpty
                            ? 'Consulta indisponível'
                            : 'Sem resumo ainda',
                        message: c.autorizado
                            ? 'Atualize para consultar os valores. Dados indisponíveis não são apresentados como zero.'
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
                      if (!loading && temRecebimentos) _recebimentosProprios(c),
                      const SizedBox(height: 10),
                      _painelResumo(display, w, loading: loading),
                      const SizedBox(height: 10),
                      _resultadoECaixa(display, w, loading: loading),
                      if (!loading && c.alertasAgrupados.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _alertas(c),
                      ],
                      if (!loading &&
                          (c.custos.isNotEmpty || c.movimentos.isNotEmpty)) ...[
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

  String _rotuloEventoCurto(String id) =>
      id.isEmpty ? '—' : widget.controller.nomeEvento(id);

  Widget _cabecalho(FinanceiroFornecedorController c, double w) {
    final compact = FornecedorBreakpoints.phone(w);
    final intro = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seu dinheiro · valores em reais',
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            color: FornecedorPremiumPalette.muted,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          'Acompanhe contratos, recebimentos e despesas do seu negócio.',
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
      tooltip: 'Registrar despesa ou recebimento',
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
          child: Text('Configurar componentes privados',
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
              'Registrar',
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
    } else if (r.creditoExcedente > 0) {
      titulo = 'Crédito excedente: ${_reais(r.creditoExcedente)}';
      corpo =
          'Concilie a destinação do excedente; não é receita de uma nova contratação.';
      cor = FornecedorPremiumPalette.indigo;
      icone = Icons.info_outline;
    } else if (aReceber > 0.009) {
      titulo = 'Você tem ${_reais(aReceber)} a receber';
      corpo = r.recebido <= 0
          ? 'Saldo contratual após os registros disponíveis.'
          : 'Saldo contratual após recebimentos próprios e repasses registrados.';
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

  Future<Map<String, dynamic>?> _pedirEstorno(
      RecebimentoCaixaFato r, FinanceiroFornecedorController c) async {
    final estornos =
        c.recebimentos.where((e) => e.estorno && e.referencia == r.id).toList();
    final somados = estornos.fold<int>(0, (s, e) => s + e.valorCentavos);
    final restante = r.valorCentavos -
        (r.estornadoCentavos > somados ? r.estornadoCentavos : somados);
    final valor =
        TextEditingController(text: NumericInput.dinheiro(restante / 100));
    final restantes = {
      for (final a in r.alocacoes.entries)
        a.key: a.value -
            estornos.fold<int>(0, (s, e) => s + (e.alocacoes[a.key] ?? 0))
    };
    final livres = restante - restantes.values.fold<int>(0, (s, v) => s + v);
    final campos = {
      for (final a in restantes.entries.where((a) => a.value > 0))
        a.key: TextEditingController(text: NumericInput.dinheiro(a.value / 100))
    };
    String? erro;
    int centavos(String texto) =>
        ((NumericInput.parseMoeda(texto) ?? 0) * 100).round();
    final rota = DialogRoute<Map<String, dynamic>>(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, atualizar) => AlertDialog(
                  title: const Text('Registrar estorno'),
                  content: SingleChildScrollView(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text(
                        'Saída declarada vinculada ao original. Não executa transferência bancária. Para estorno parcial, informe as alocações que serão revertidas.'),
                    const SizedBox(height: 12),
                    TextField(
                        controller: valor,
                        inputFormatters: [NumericInput.moeda()],
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                            labelText: 'Valor do estorno')),
                    for (final a in campos.entries)
                      TextField(
                          controller: a.value,
                          inputFormatters: [NumericInput.moeda()],
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                              labelText:
                                  'Reverter ${c.contratosListados.where((v) => v.id == a.key).map((v) => v.nomeServico ?? 'contratação').firstOrNull ?? 'contratação'}')),
                    if (livres > 0)
                      Text(
                          'Parcela não alocada disponível: ${_reais(livres / 100)}'),
                    if (erro != null)
                      Text(erro!, style: const TextStyle(color: Colors.red)),
                  ])),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Voltar')),
                    TextButton(
                        onPressed: () {
                          final total = centavos(valor.text);
                          final alocacoes = campos.entries
                              .map((a) => <String, dynamic>{
                                    'idContrato': a.key,
                                    'valorCentavos': centavos(a.value.text)
                                  })
                              .where((a) => (a['valorCentavos'] as int) > 0)
                              .toList();
                          final soma = alocacoes.fold<int>(
                              0, (s, a) => s + (a['valorCentavos'] as int));
                          if (total <= 0 ||
                              total > restante ||
                              soma > total ||
                              total - soma > livres ||
                              alocacoes.any((a) =>
                                  (a['valorCentavos'] as int) >
                                  (restantes[a['idContrato']] ?? 0))) {
                            atualizar(() => erro =
                                'Confira o valor e as alocações ainda disponíveis no original.');
                            return;
                          }
                          Navigator.pop(ctx,
                              {'valorCentavos': total, 'alocacoes': alocacoes});
                        },
                        child: const Text('Confirmar estorno'))
                  ],
                )));
    try {
      return await Navigator.of(context).push(rota);
    } finally {
      // O resultado chega antes do fim da animação de saída do diálogo.
      await rota.completed;
      valor.dispose();
      for (final campo in campos.values) {
        campo.dispose();
      }
    }
  }

  Widget _recebimentosProprios(FinanceiroFornecedorController c) {
    final fatos = c.recebimentos
        .where((r) =>
            c.filtroEventoId.value.isEmpty ||
            r.idEvento == c.filtroEventoId.value)
        .toList();
    return PremiumSectionShell(
        title: 'Recebimentos próprios',
        subtitle: 'Registros declarados; não são confirmação bancária',
        icon: Icons.receipt_long_outlined,
        color: FornecedorPremiumPalette.indigo,
        child: Column(
            children: fatos
                .map((r) => ListTile(
                      title: Text(r.repasseLegado
                          ? 'Repasse legado: aguarda conciliação'
                          : r.estorno
                              ? 'Estorno registrado'
                              : r.adiantamento
                                  ? 'Adiantamento sem entrega presumida'
                                  : 'Recebimento externo declarado'),
                      subtitle: Text(
                          '${_reais(r.valorCentavos / 100)} · ${r.alocacoes.isEmpty ? 'Não alocado' : 'Alocação por contratação'}'),
                      trailing: !r.repasseLegado &&
                              !r.estorno &&
                              r.estornadoCentavos < r.valorCentavos
                          ? TextButton(
                              onPressed: c.enviando.value
                                  ? null
                                  : () async {
                                      final pedido = await _pedirEstorno(r, c);
                                      if (pedido != null) {
                                        await c.registrarRecebimento(
                                            idEvento: r.idEvento,
                                            valorCentavos:
                                                pedido['valorCentavos'] as int,
                                            tipo: 'estorno',
                                            referenciaRecebimento: r.id,
                                            alocacoes: (pedido['alocacoes']
                                                    as List)
                                                .cast<Map<String, dynamic>>());
                                      }
                                    },
                              child: const Text('Estornar'))
                          : null,
                    ))
                .toList()));
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
            if (i > 0) const SizedBox(height: 10),
            _cartaoContrato(c, lista[i]),
          ],
        ],
      ),
    );
  }

  Widget _cartaoContrato(
      FinanceiroFornecedorController c, VendaFornecedorFato v) {
    const recebido = Color(0xFF047857);
    const pendente = Color(0xFF92400E);
    final titulo = (v.nomeServico ?? v.categoria ?? '').trim();
    final idOrcamento = v.idOrcamento?.trim() ?? '';
    final situacao = _rotuloSituacaoContrato(v);
    final cancelado = v.situacao?.toLowerCase() == 'cancelado';
    final saldo = v.aReceber;
    final corSituacao = cancelado
        ? FornecedorPremiumPalette.muted
        : saldo < -0.009
            ? FornecedorPremiumPalette.primary
            : saldo > 0.009
                ? pendente
                : recebido;
    final tema = Theme.of(context).textTheme;

    return Material(
      color: FornecedorPremiumPalette.surfaceAlt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: FornecedorPremiumPalette.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Get.toNamed(
          '/acompanhamento-fornecedor',
          arguments: {
            'idFornecedor': c.idFornecedor,
            if (idOrcamento.isNotEmpty) 'idOrcamento': idOrcamento,
          },
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(titulo.isEmpty ? 'Serviço' : titulo,
                        style: tema.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: FornecedorPremiumPalette.text)),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded,
                      color: FornecedorPremiumPalette.muted),
                ],
              ),
              const SizedBox(height: 5),
              Text(situacao,
                  style: tema.labelMedium?.copyWith(
                      color: corSituacao, fontWeight: FontWeight.w700)),
              const Divider(height: 22, color: FornecedorPremiumPalette.border),
              ResponsiveWrapGrid(
                minTileWidth: 124,
                maxColumns: 4,
                children: [
                  if (v.recebidoConfirmado > 0)
                    _miniMetrica(
                      v.repasseConfirmado == v.recebidoConfirmado
                          ? 'Repasse recebido'
                          : 'Já recebido',
                      _reais(v.recebidoConfirmado),
                      corValor: recebido,
                    ),
                  if (saldo > 0.009)
                    _miniMetrica('A receber', _reais(saldo),
                        corValor: pendente),
                  if (saldo < -0.009)
                    _miniMetrica('Crédito excedente', _reais(-saldo)),
                  _miniMetrica('Valor líquido', _reais(v.liquidoPrevisto)),
                  _miniMetrica('Valor bruto', _reais(v.valorContratado)),
                  if (v.comissao != null)
                    _miniMetrica('Comissão', _reais(v.comissao)),
                  if (v.repasseAutorizado > 0)
                    _miniMetrica(
                        'Repasse autorizado', _reais(v.repasseAutorizado)),
                  if (v.repasseConfirmado > 0 &&
                      v.repasseConfirmado != v.recebidoConfirmado)
                    _miniMetrica(
                        'Repasse recebido', _reais(v.repasseConfirmado)),
                  if (v.recebimentoProprioDeclarado > 0)
                    _miniMetrica('Recebimento próprio declarado',
                        _reais(v.recebimentoProprioDeclarado)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _rotuloSituacaoContrato(VendaFornecedorFato v) {
    final s = (v.situacao ?? '').toLowerCase();
    if (s == 'cancelado') return 'Cancelado — histórico preservado';
    if (v.aReceber < -0.009) return 'Crédito excedente — conciliar destinação';
    if (s == 'recebido' || v.aReceber <= 0.009) {
      return v.repasseConfirmado > 0 ? 'Repasse quitado' : 'Saldo quitado';
    }
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
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const ValueKey('filtro-evento-financeiro'),
              value: selecionado,
              isExpanded: true,
              menuMaxHeight: 360,
              decoration: InputDecoration(
                labelText: 'Evento',
                prefixIcon: const Icon(Icons.event_outlined),
                filled: true,
                fillColor: FornecedorPremiumPalette.surfaceAlt,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              items: [
                const DropdownMenuItem(
                    value: '', child: Text('Todos os eventos')),
                for (final id in ids)
                  DropdownMenuItem(
                      value: id,
                      child: Text(c.nomeEvento(id),
                          maxLines: 2, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: c.valoresEmCarga
                  ? null
                  : (id) {
                      c.aplicarFiltroEvento(id);
                      c.iniciar();
                    },
            ),
            const SizedBox(height: 8),
            Text('Selecione um evento para atualizar os valores.',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: FornecedorPremiumPalette.muted)),
            if (selecionado.isNotEmpty)
              TextButton.icon(
                onPressed: c.valoresEmCarga
                    ? null
                    : () {
                        c.limparFiltroEvento();
                        c.iniciar();
                      },
                icon: const Icon(Icons.clear_rounded, size: 18),
                label: const Text('Limpar filtro'),
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
    final metricas = [
      ('Total contratado', _reais(r.contratado)),
      ('Comissão contratada', _reais(r.comissaoContratada)),
      ('Valor após descontos', _reais(r.liquidoPrevisto)),
      ('Repasse liberado', _reais(r.repasseAutorizado)),
      ('Seus custos', _reais(r.custoDiretoPrevisto)),
      ('Recebido acima do previsto', _reais(r.creditoExcedente)),
      ('Recebido sem contrato definido', _reais(r.recebimentoNaoAlocado)),
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
          ResponsiveWrapGrid(
            minTileWidth: 230,
            maxColumns: 2,
            spacing: 16,
            children: [
              _blocoAReceber(r, vencido, loading: loading),
              _miniMetrica('Já recebido', _reais(r.recebido),
                  loading: loading,
                  corValor: const Color(0xFF047857),
                  tamanhoValor: 22),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, box) {
            final colunas = box.maxWidth >= 720 ? 3 : 2;
            final largura = (box.maxWidth - 12 * (colunas - 1)) / colunas;
            return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: metricas
                    .map((m) => SizedBox(
                        width: largura,
                        child: _miniMetrica(m.$1, m.$2, loading: loading)))
                    .toList());
          }),
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

  Widget _miniMetrica(
    String rotulo,
    String valor, {
    bool loading = false,
    Color? corValor,
    double tamanhoValor = 15,
  }) {
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
              style: GoogleFonts.poppins(
                fontSize: tamanhoValor,
                fontWeight: FontWeight.w800,
                color: corValor ?? FornecedorPremiumPalette.text,
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
                      'Configurar componentes privados',
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
    final caixaVazio = !loading && r.entradasCaixa <= 0 && r.saidasCaixa <= 0;
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
                  'Configurar componentes privados',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: c.enviando.value
                    ? null
                    : () => _abrirFormulario(custo: true),
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
    await Get.toNamed('/fornecedor/planejamento');
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
  String? _contrato;
  bool _dividir = false;
  String? _erroAlocacao;
  final _alocacoes = <String, TextEditingController>{};
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
    for (final c in _alocacoes.values) {
      c.dispose();
    }
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
      _erroEvento = _eventoCtrl.text.trim().isEmpty
          ? 'Informe o evento'
          : (!widget.custo && !_dividir && _contrato == null
              ? 'Selecione a contratação'
              : null);
      _erroValor =
          _centavosDeReais() == null ? 'Informe um valor válido' : null;
    });
    final alocadas = _alocacoesParaEnvio();
    final soma =
        alocadas.fold<int>(0, (s, a) => s + (a['valorCentavos'] as int));
    setState(() => _erroAlocacao =
        !widget.custo && _dividir && soma > (_centavosDeReais() ?? 0)
            ? 'As alocações excedem o recebimento.'
            : null);
    return _erroEvento == null && _erroValor == null && _erroAlocacao == null;
  }

  List<Map<String, dynamic>> _alocacoesParaEnvio() {
    final contratos = widget.controller.contratosListados.where((v) =>
        v.idEvento == _eventoCtrl.text.trim() && v.situacao != 'cancelado');
    return contratos
        .map((v) => {
              'idContrato': v.id,
              'valorCentavos':
                  ((NumericInput.parseMoeda(_alocacoes[v.id]?.text ?? '') ??
                              0) *
                          100)
                      .round()
            })
        .where((a) => (a['valorCentavos'] as int) > 0)
        .toList();
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
            idOrcamento: _dividir ? null : _contrato,
            alocacoes: _dividir ? _alocacoesParaEnvio() : null,
            valorCentavos: centavos,
            tipo: adiantamento ? 'adiantamento' : 'recebimento',
            execucaoConfirmada: false,
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
                ? 'Adiantamento próprio declarado.'
                : 'Recebimento externo declarado. A entrega não é presumida.'),
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
                  : 'Declaração própria — não confirma banco nem execução do serviço.',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: FornecedorPremiumPalette.muted,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            if (!widget.custo) ...[
              CheckboxListTile(
                  value: _dividir,
                  onChanged: busy
                      ? null
                      : (v) => setState(() => _dividir = v ?? false),
                  title: const Text('Distribuir entre contratos'),
                  subtitle: const Text(
                      'O valor não distribuído permanece não alocado.')),
              if (!_dividir)
                DropdownButtonFormField<String>(
                  value: _contrato,
                  isExpanded: true,
                  decoration: const InputDecoration(
                      labelText: 'Contratação do recebimento'),
                  items: c.contratosListados
                      .where((v) => v.situacao != 'cancelado')
                      .map((v) => DropdownMenuItem(
                          value: v.id,
                          child: Text(v.nomeServico ?? 'Serviço contratado')))
                      .toList(),
                  onChanged: busy
                      ? null
                      : (id) => setState(() {
                            _contrato = id;
                            _eventoCtrl.text = c.contratosListados
                                .firstWhere((v) => v.id == id)
                                .idEvento;
                          }),
                ),
              const SizedBox(height: 12),
              const Text(
                  'Declaração própria, separada dos repasses confirmados pela plataforma.'),
            ],
            TextField(
              controller: _eventoCtrl,
              onChanged: (_) => setState(() {}),
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
            if (!widget.custo && _dividir) ...[
              for (final v in c.contratosListados.where((v) =>
                  v.idEvento == _eventoCtrl.text.trim() &&
                  v.situacao != 'cancelado'))
                Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextField(
                        controller: _alocacoes.putIfAbsent(
                            v.id, () => TextEditingController()),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [NumericInput.moeda()],
                        decoration: InputDecoration(
                            labelText: v.nomeServico ?? 'Serviço contratado',
                            prefixText: 'R\$ '))),
              if (_erroAlocacao != null)
                Text(_erroAlocacao!, style: const TextStyle(color: Colors.red)),
            ],
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
                        'Registrar recebimento externo',
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
