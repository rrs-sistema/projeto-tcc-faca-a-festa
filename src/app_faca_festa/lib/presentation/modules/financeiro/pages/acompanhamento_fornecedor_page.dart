import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/core/utils/numeric_input.dart';
import 'package:app_faca_festa/domain/entities/financeiro/contratacao_identidade.dart';
import 'package:app_faca_festa/domain/services/acompanhamento_partes_service.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/controllers/acompanhamento_partes_controller.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/widgets/abrir_mediacao_sheet.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/sections/fornecedor_premium_layout.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/widgets/festa_app_bar.dart';

/// Acompanhamento do fornecedor: contratos intermediados (sem caixa do cliente).
class AcompanhamentoFornecedorPage extends StatefulWidget {
  const AcompanhamentoFornecedorPage({
    super.key,
    required this.controller,
    required this.themeController,
    required this.idFornecedor,
  });

  final AcompanhamentoPartesController controller;
  final EventThemeController themeController;
  final String idFornecedor;

  @override
  State<AcompanhamentoFornecedorPage> createState() =>
      _AcompanhamentoFornecedorPageState();
}

class _AcompanhamentoFornecedorPageState
    extends State<AcompanhamentoFornecedorPage> {
  AcompanhamentoPartesController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      c.carregarFornecedor(widget.idFornecedor);
    });
  }

  String _reais(int centavos) => NumericInput.dinheiro(centavos / 100.0);

  String _rotuloExecucao(String raw) {
    switch (raw.toLowerCase().trim()) {
      case 'em_andamento':
      case 'em-andamento':
        return 'Em andamento';
      case 'concluido':
      case 'concluído':
        return 'Concluído';
      case 'cancelado':
        return 'Cancelado';
      case '':
        return 'Execução não iniciada';
      default:
        return EstadoExecucaoContrato.fromString(raw).rotulo;
    }
  }

  String _rotuloPendencia(String raw) {
    switch (raw.toLowerCase().trim()) {
      case 'aguardando_recebimento_plataforma':
        return 'Aguardando pagamento do cliente na plataforma';
      case 'politica_liberacao_pendente':
        return 'Liberação de repasse ainda não liberada';
      case 'execucao_contestada':
        return 'Execução contestada';
      case 'aguardando_aceite_cliente':
        return 'Aguardando aceite do cliente';
      case 'caso_mediacao_aberto':
        return 'Mediação em andamento';
      case 'repasse_pendente':
        return 'Repasse pendente';
      case 'financeiro_cliente':
        return 'Pagamento do cliente pendente';
      default:
        return raw.replaceAll('_', ' ');
    }
  }

  Future<void> _abrirMediacao(VisaoFornecedorContrato l) async {
    final pedido = await showAbrirMediacaoSheet(
      context: context,
      primary: FornecedorPremiumPalette.primary,
      tituloServico: l.nomeServico,
    );
    if (!mounted || pedido == null) return;

    EasyLoading.show(status: 'Abrindo mediação...');
    final ok = await c.abrirCaso(
      l.idOrcamento,
      pedido.motivo,
      descricao: pedido.descricao,
    );
    EasyLoading.dismiss();
    if (!mounted) return;
    Get.snackbar(
      ok ? 'Mediação aberta' : 'Não foi possível abrir',
      ok
          ? 'A equipe da plataforma vai analisar o caso.'
          : (c.erro.value.isNotEmpty
              ? c.erro.value
              : 'Tente novamente em instantes.'),
      backgroundColor: ok ? Colors.green.shade600 : Colors.redAccent,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final busy = c.carregando.value;
      final linhas = c.linhasForn.toList();
      final aviso = c.aviso.value.trim();
      final erro = c.erro.value.trim();

      return Scaffold(
        backgroundColor: FornecedorPremiumPalette.background,
        appBar: FestaAppBar(
          titulo: 'Contratos intermediados',
          themeController: widget.themeController,
          acoes: [
            IconButton(
              tooltip: 'Atualizar',
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: busy
                  ? null
                  : () => c.carregarFornecedor(widget.idFornecedor),
            ),
          ],
        ),
        body: busy && linhas.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  final pad = constraints.maxWidth >= 900 ? 28.0 : 16.0;
                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                          pad,
                          FestaPageInsets.belowAppBar,
                          pad,
                          32,
                        ),
                        children: [
                          const _InfoBanner(
                            icon: Icons.account_balance_outlined,
                            color: FornecedorPremiumPalette.indigo,
                            title: 'Como funciona o repasse',
                            body:
                                'O cliente paga à plataforma. Isso não entra no seu caixa. '
                                'Você recebe pelo repasse da Faça a Festa — sem botão “Sacar”.',
                          ),
                          if (aviso.isNotEmpty && !_avisoRedundante(aviso)) ...[
                            const SizedBox(height: 10),
                            _InfoBanner(
                              icon: Icons.info_outline_rounded,
                              color: FornecedorPremiumPalette.amber,
                              title: 'Aviso da plataforma',
                              body: aviso,
                              soft: true,
                            ),
                          ],
                          if (erro.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _InfoBanner(
                              icon: Icons.error_outline_rounded,
                              color: FornecedorPremiumPalette.rose,
                              title: 'Não foi possível carregar',
                              body: erro,
                              soft: true,
                            ),
                          ],
                          const SizedBox(height: 18),
                          if (linhas.isEmpty)
                            const _EmptyContratos()
                          else ...[
                            Text(
                              '${linhas.length} contrato${linhas.length == 1 ? '' : 's'} · valores previstos (não são saldo bancário)',
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: FornecedorPremiumPalette.muted,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...linhas.map(_card),
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

  bool _avisoRedundante(String aviso) {
    final a = aviso.toLowerCase();
    return a.contains('não entram como caixa') ||
        a.contains('nao entram como caixa') ||
        a.contains('sem botão sacar') ||
        a.contains('sem botao sacar') ||
        a.contains('repasse da plataforma é origem');
  }

  Widget _card(VisaoFornecedorContrato l) {
    final evento = l.nomeEvento?.trim().isNotEmpty == true
        ? l.nomeEvento!
        : 'Evento';
    final contratante = l.nomeContratante?.trim().isNotEmpty == true
        ? l.nomeContratante!
        : '—';
    final servico = l.nomeServico?.trim().isNotEmpty == true
        ? l.nomeServico!
        : 'Serviço';
    final podeEntregar = c.dominio.podeInformarEntrega(l.estadoExecucao);
    final saldo = l.saldoPrevistoRepasseCentavos;
    final liquido = l.direitoLiquidoCentavos;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: FornecedorPremiumPalette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: FornecedorPremiumPalette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: FornecedorPremiumPalette.emerald
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.handshake_rounded,
                        color: FornecedorPremiumPalette.emerald,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            servico,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w800,
                              fontSize: 15.5,
                              color: FornecedorPremiumPalette.text,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            evento,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: FornecedorPremiumPalette.muted,
                            ),
                          ),
                          Text(
                            'Contratante · $contratante',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: FornecedorPremiumPalette.softMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    PremiumPill(
                      text: _rotuloExecucao(l.estadoExecucao),
                      color: FornecedorPremiumPalette.sky,
                      icon: Icons.timeline_rounded,
                    ),
                    if (l.pendencias.isNotEmpty)
                      PremiumPill(
                        text:
                            '${l.pendencias.length} pendência${l.pendencias.length == 1 ? '' : 's'}',
                        color: FornecedorPremiumPalette.amber,
                        icon: Icons.warning_amber_rounded,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Hero: o que o fornecedor quer saber primeiro.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _HeroRepasse(
              titulo: 'A receber (previsto)',
              valor: _reais(saldo > 0 ? saldo : liquido),
              subtitulo: saldo > 0
                  ? 'Saldo ainda previsto de repasse'
                  : 'Líquido após comissão prevista',
              onAjuda: () => _ValorAjuda.mostrar(
                context,
                'A receber (previsto)',
                'Estimativa do que a plataforma pode repassar a você. '
                    'Não é saldo bancário nem garantia de prazo.',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LayoutBuilder(
              builder: (context, box) {
                final duas = box.maxWidth >= 420;
                final kpis = [
                  _KpiTile(
                    label: 'Contratado',
                    valor: _reais(l.valorContratadoCentavos),
                    ajuda:
                        'Valor do serviço fechado com o organizador. '
                        'Base do contrato — ainda não é dinheiro no seu caixa.',
                  ),
                  _KpiTile(
                    label: 'Comissão',
                    valor: _reais(l.comissaoPrevistaCentavos),
                    hint: l.comissaoJaDescontadaDoRepasse
                        ? 'já no cálculo do repasse'
                        : null,
                    ajuda:
                        'Parte estimada da plataforma. '
                        'Pode já estar descontada do cálculo de repasse.',
                  ),
                  _KpiTile(
                    label: 'Líquido',
                    valor: _reais(l.direitoLiquidoCentavos),
                    destaque: true,
                    ajuda:
                        'Quanto você deve receber após a comissão prevista '
                        '(estimativa).',
                  ),
                  _KpiTile(
                    label: 'Na plataforma',
                    valor: _reais(l.alocadoPlataformaCentavos),
                    hint: l.trataAlocadoComoCaixaProprio
                        ? null
                        : 'não é seu caixa',
                    ajuda:
                        'Valor pago/alocado pelo cliente na plataforma. '
                        'Só o repasse confirmado conta como recebimento seu.',
                  ),
                  _KpiTile(
                    label: 'Já repassado',
                    valor: _reais(l.repasseConfirmadoCentavos),
                    ajuda:
                        'Valor que a plataforma já confirmou ter repassado a você.',
                  ),
                ];

                if (!duas) {
                  return Column(
                    children: [
                      for (var i = 0; i < kpis.length; i++) ...[
                        if (i > 0) const SizedBox(height: 8),
                        kpis[i],
                      ],
                    ],
                  );
                }

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: kpis[0]),
                        const SizedBox(width: 8),
                        Expanded(child: kpis[1]),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: kpis[2]),
                        const SizedBox(width: 8),
                        Expanded(child: kpis[3]),
                      ],
                    ),
                    const SizedBox(height: 8),
                    kpis[4],
                  ],
                );
              },
            ),
          ),
          if (l.pendencias.isNotEmpty) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _PendenciasBlock(
                itens: l.pendencias.map(_rotuloPendencia).toList(),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ProximoPassoBlock(
              rotulo: l.proximoPasso.rotulo,
              configuracaoPendente: l.proximoPasso.ehPendenciaConfiguracao,
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                if (podeEntregar)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: c.enviando.value
                          ? null
                          : () => c.informarEntrega(l.idOrcamento),
                      icon: const Icon(Icons.local_shipping_outlined, size: 18),
                      label: Text(
                        'Informar entrega',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: FornecedorPremiumPalette.emerald,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(48, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                if (podeEntregar) const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed:
                        c.enviando.value ? null : () => _abrirMediacao(l),
                    icon: const Icon(Icons.support_agent_rounded, size: 18),
                    label: Text(
                      'Abrir mediação',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: FornecedorPremiumPalette.primary,
                      minimumSize: const Size(48, 48),
                      side: BorderSide(
                        color: FornecedorPremiumPalette.primary
                            .withValues(alpha: 0.35),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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

class _HeroRepasse extends StatelessWidget {
  const _HeroRepasse({
    required this.titulo,
    required this.valor,
    required this.subtitulo,
    required this.onAjuda,
  });

  final String titulo;
  final String valor;
  final String subtitulo;
  final VoidCallback onAjuda;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onAjuda,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                FornecedorPremiumPalette.emerald.withValues(alpha: 0.14),
                FornecedorPremiumPalette.emerald.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: FornecedorPremiumPalette.emerald.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          titulo,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: FornecedorPremiumPalette.muted,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.help_outline_rounded,
                          size: 14,
                          color: FornecedorPremiumPalette.softMuted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      valor,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: FornecedorPremiumPalette.emerald,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: FornecedorPremiumPalette.softMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.payments_outlined,
                  color: FornecedorPremiumPalette.emerald,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.label,
    required this.valor,
    this.hint,
    this.ajuda,
    this.destaque = false,
  });

  final String label;
  final String valor;
  final String? hint;
  final String? ajuda;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final cor = destaque
        ? FornecedorPremiumPalette.emerald
        : FornecedorPremiumPalette.text;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: ajuda == null
            ? null
            : () => _ValorAjuda.mostrar(context, label, ajuda!),
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: FornecedorPremiumPalette.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: destaque
                  ? FornecedorPremiumPalette.emerald.withValues(alpha: 0.25)
                  : FornecedorPremiumPalette.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: FornecedorPremiumPalette.muted,
                      ),
                    ),
                  ),
                  if (ajuda != null)
                    const Icon(
                      Icons.help_outline_rounded,
                      size: 13,
                      color: FornecedorPremiumPalette.softMuted,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                valor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: destaque ? 16 : 15,
                  fontWeight: FontWeight.w800,
                  color: cor,
                ),
              ),
              if (hint != null) ...[
                const SizedBox(height: 2),
                Text(
                  hint!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    color: FornecedorPremiumPalette.softMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PendenciasBlock extends StatelessWidget {
  const _PendenciasBlock({required this.itens});

  final List<String> itens;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FornecedorPremiumPalette.amber.withValues(alpha: 0.08),
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
                Icons.flag_outlined,
                size: 16,
                color: FornecedorPremiumPalette.amber,
              ),
              const SizedBox(width: 6),
              Text(
                'O que ainda falta',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: FornecedorPremiumPalette.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final item in itens)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: Icon(
                      Icons.circle,
                      size: 6,
                      color: FornecedorPremiumPalette.amber,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: FornecedorPremiumPalette.text,
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

class _ProximoPassoBlock extends StatelessWidget {
  const _ProximoPassoBlock({
    required this.rotulo,
    required this.configuracaoPendente,
  });

  final String rotulo;
  final bool configuracaoPendente;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FornecedorPremiumPalette.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: FornecedorPremiumPalette.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Próximo passo',
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: FornecedorPremiumPalette.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            rotulo,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              height: 1.35,
              color: FornecedorPremiumPalette.text,
            ),
          ),
          if (configuracaoPendente) ...[
            const SizedBox(height: 6),
            Text(
              'Configuração pendente na plataforma — sem prazo prometido.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: FornecedorPremiumPalette.amber,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ValorAjuda {
  static void mostrar(BuildContext context, String titulo, String texto) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Text(
                  titulo,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  texto,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    height: 1.45,
                    color: FornecedorPremiumPalette.muted,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Entendi',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    this.soft = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final bool soft;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: soft
            ? color.withValues(alpha: 0.08)
            : FornecedorPremiumPalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        boxShadow: soft
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: FornecedorPremiumPalette.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    height: 1.4,
                    color: FornecedorPremiumPalette.muted,
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

class _EmptyContratos extends StatelessWidget {
  const _EmptyContratos();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      decoration: BoxDecoration(
        color: FornecedorPremiumPalette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: FornecedorPremiumPalette.border),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: FornecedorPremiumPalette.indigo.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.handshake_outlined,
              size: 34,
              color: FornecedorPremiumPalette.indigo,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum contrato ainda',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: FornecedorPremiumPalette.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Quando um organizador fechar negócio com você, '
            'o contrato intermediado aparece aqui com valores e próximo passo.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.45,
              color: FornecedorPremiumPalette.muted,
            ),
          ),
        ],
      ),
    );
  }
}
