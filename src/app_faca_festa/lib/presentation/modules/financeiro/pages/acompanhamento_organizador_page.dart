import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'package:app_faca_festa/core/utils/numeric_input.dart';
import 'package:app_faca_festa/domain/services/acompanhamento_partes_service.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/controllers/acompanhamento_partes_controller.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/widgets/abrir_mediacao_sheet.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/widgets/festa_app_bar.dart';

/// Acompanhamento do organizador: fornecedor → serviço → pagamento à plataforma.
class AcompanhamentoOrganizadorPage extends StatefulWidget {
  const AcompanhamentoOrganizadorPage({
    super.key,
    required this.controller,
    required this.themeController,
    required this.idEvento,
    this.nomeEvento,
  });

  final AcompanhamentoPartesController controller;
  final EventThemeController themeController;
  final String idEvento;
  final String? nomeEvento;

  @override
  State<AcompanhamentoOrganizadorPage> createState() =>
      _AcompanhamentoOrganizadorPageState();
}

class _AcompanhamentoOrganizadorPageState
    extends State<AcompanhamentoOrganizadorPage> {
  AcompanhamentoPartesController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      c.carregarOrganizador(widget.idEvento);
    });
  }

  String _reais(int centavos) => NumericInput.dinheiro(centavos / 100.0);

  String _rotuloNivel(String n) {
    switch (n) {
      case 'declarado':
        return 'Declarado · aguarda conferência';
      case 'conferido':
        return 'Conferido pela plataforma';
      case 'confirmado_fonte_externa':
        return 'Confirmado por fonte externa';
      default:
        return 'Ainda não informado';
    }
  }

  String _rotuloExecucao(String raw) {
    switch (raw.toLowerCase().trim()) {
      case 'nao_iniciado':
      case 'nao-iniciado':
        return 'Não iniciado';
      case 'em_andamento':
      case 'em-andamento':
        return 'Em andamento';
      case 'entrega_informada':
        return 'Entrega informada';
      case 'concluido':
      case 'concluído':
        return 'Concluído';
      case 'cancelado':
        return 'Cancelado';
      case '':
        return '—';
      default:
        return raw.replaceAll('_', ' ');
    }
  }

  Color _corNivel(String n, Color primary) {
    switch (n) {
      case 'declarado':
        return const Color(0xFFF59E0B);
      case 'conferido':
      case 'confirmado_fonte_externa':
        return const Color(0xFF10B981);
      default:
        return primary;
    }
  }

  Future<void> _declarar(VisaoOrganizadorContrato l) async {
    final primary = widget.themeController.primaryColor.value;
    final wide = MediaQuery.sizeOf(context).width >= 720;
    final int? centavos;
    if (wide) {
      centavos = await showDialog<int>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          final inset = MediaQuery.viewInsetsOf(ctx).bottom;
          final maxH = MediaQuery.sizeOf(ctx).height - inset - 40;
          return Padding(
            padding: EdgeInsets.only(bottom: inset),
            child: Dialog(
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 440, maxHeight: maxH),
                child: _DeclararPagamentoSheet(
                  primary: primary,
                  valorSugeridoCentavos: l.aPagarCentavos,
                  nomeServico: l.nomeServico,
                  onFechar: () => Navigator.of(ctx).pop(),
                  onConfirmar: (v) => Navigator.of(ctx).pop(v),
                ),
              ),
            ),
          );
        },
      );
    } else {
      centavos = await showModalBottomSheet<int>(
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
            padding: EdgeInsets.only(bottom: inset),
            child: _DeclararPagamentoSheet(
              primary: primary,
              valorSugeridoCentavos: l.aPagarCentavos,
              nomeServico: l.nomeServico,
              onFechar: () => Navigator.of(ctx).pop(),
              onConfirmar: (v) => Navigator.of(ctx).pop(v),
            ),
          );
        },
      );
    }
    if (!mounted || centavos == null || centavos <= 0) return;
    EasyLoading.show(status: 'Registrando declaração...');
    final ok = await c.declararPagamento(
      idOrcamento: l.idOrcamento,
      valorCentavos: centavos,
    );
    EasyLoading.dismiss();
    if (!mounted) return;
    Get.snackbar(
      ok ? 'Declaração registrada' : 'Não foi possível declarar',
      ok
          ? 'A plataforma vai conferir o pagamento informado.'
          : (c.erro.value.isNotEmpty
              ? c.erro.value
              : 'Tente novamente em instantes.'),
      backgroundColor: ok ? Colors.green.shade600 : Colors.redAccent,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> _abrirMediacao(VisaoOrganizadorContrato l) async {
    final primary = widget.themeController.primaryColor.value;
    final pedido = await showAbrirMediacaoSheet(
      context: context,
      primary: primary,
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
    final primary = widget.themeController.primaryColor.value;
    final nomeEvento = (widget.nomeEvento ?? '').trim();
    return Obx(() {
      final busy = c.carregando.value;
      final linhas = c.linhasOrg.toList();
      return Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        appBar: FestaAppBar(
          titulo: 'Pagamento à plataforma',
          themeController: widget.themeController,
          acoes: [
            IconButton(
              tooltip: 'Atualizar',
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: busy
                  ? null
                  : () => c.carregarOrganizador(widget.idEvento),
            ),
          ],
        ),
        body: busy && linhas.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  FestaPageInsets.belowAppBar,
                  16,
                  32,
                ),
                children: [
                  if (nomeEvento.isNotEmpty) ...[
                    Text(
                      nomeEvento,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    'Cada card é um fornecedor/serviço. Declare o valor pago '
                    'à plataforma Faça a Festa — não há cobrança automática.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      height: 1.4,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  if (c.aviso.value.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _avisoBox(
                      c.aviso.value,
                      const Color(0xFFF59E0B),
                      Icons.info_outline_rounded,
                    ),
                  ],
                  if (c.erro.value.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _avisoBox(
                      c.erro.value,
                      const Color(0xFFEF4444),
                      Icons.error_outline_rounded,
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (linhas.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 40, color: primary.withValues(alpha: 0.7)),
                          const SizedBox(height: 10),
                          Text(
                            'Nenhuma contratação neste evento',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Quando houver fornecedores contratados, eles aparecem aqui.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...linhas.map((l) => _card(l, primary)),
                ],
              ),
      );
    });
  }

  Widget _avisoBox(String texto, Color cor, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: cor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.35,
                color: const Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiMini(
    String label,
    String value,
    Color primary, {
    required String ajuda,
    bool destaque = false,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _mostrarAjudaKpi(label, ajuda),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            decoration: BoxDecoration(
              color: destaque
                  ? primary.withValues(alpha: 0.08)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: destaque
                    ? primary.withValues(alpha: 0.25)
                    : const Color(0xFFE5E7EB),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                          height: 1.2,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.help_outline_rounded,
                      size: 14,
                      color: primary.withValues(alpha: 0.75),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarAjudaKpi(String titulo, String texto) {
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
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  texto,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    height: 1.45,
                    color: const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 14),
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

  Widget _card(VisaoOrganizadorContrato l, Color primary) {
    final fornecedor = l.nomeFornecedor?.trim().isNotEmpty == true
        ? l.nomeFornecedor!
        : 'Fornecedor não identificado';
    final servico = l.nomeServico?.trim().isNotEmpty == true
        ? l.nomeServico!
        : 'Serviço';
    final corPag = _corNivel(l.nivelPagamento, primary);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            servico,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: const Color(0xFF111827),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.storefront_outlined,
                  size: 15, color: primary.withValues(alpha: 0.9)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  fornecedor,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chipStatus(_rotuloNivel(l.nivelPagamento), corPag),
              _chipStatus(
                'Execução · ${_rotuloExecucao(l.estadoExecucao)}',
                const Color(0xFF64748B),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _kpiMini(
                'Contratado',
                _reais(l.valorContratadoCentavos),
                primary,
                ajuda:
                    'Valor do serviço fechado com o fornecedor. '
                    'É a base do contrato intermediado pela plataforma.',
              ),
              const SizedBox(width: 8),
              _kpiMini(
                'A pagar',
                _reais(l.aPagarCentavos),
                primary,
                destaque: true,
                ajuda:
                    'Quanto ainda falta você pagar à plataforma Faça a Festa '
                    '(não é pagamento direto ao fornecedor). '
                    'Use “Declarar pagamento” após transferir.',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _kpiMini(
                'Confirmado',
                _reais(l.valorConfirmadoCentavos),
                primary,
                ajuda:
                    'Valor que a plataforma já conferiu/alocou. '
                    'Só a equipe confirma — a declaração sozinha não libera repasse.',
              ),
              const SizedBox(width: 8),
              _kpiMini(
                'Declarado',
                _reais(l.valorDeclaradoCentavos),
                primary,
                ajuda:
                    'Valor que VOCÊ (organizador) informou ter pago à plataforma. '
                    'Ainda aguarda conferência do administrador. '
                    'O fornecedor não recebe esse valor automaticamente — '
                    'ele só vê o repasse depois da confirmação.',
              ),
            ],
          ),
          if (l.statusRepasse != null && l.statusRepasse!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              l.statusRepasse!,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: const Color(0xFF64748B),
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Próximo passo',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.proximoPasso.rotulo,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    height: 1.35,
                    color: const Color(0xFF111827),
                  ),
                ),
                if (l.proximoPasso.responsavel != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Responsável: ${l.proximoPasso.responsavel}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
                if (l.proximoPasso.ehPendenciaConfiguracao) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Pendência de configuração — sem prazo prometido.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFFB45309),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: c.enviando.value ? null : () => _declarar(l),
              icon: const Icon(Icons.payments_outlined, size: 18),
              label: Text(
                l.valorDeclaradoCentavos > 0
                    ? 'Atualizar declaração'
                    : 'Declarar pagamento',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(48, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (l.estadoExecucao == 'entrega_informada') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: c.enviando.value
                        ? null
                        : () => c.aceitarOuContestar(l.idOrcamento,
                            contestar: false),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      minimumSize: const Size(48, 44),
                    ),
                    child: Text(
                      'Aceitar entrega',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: c.enviando.value
                        ? null
                        : () => c.aceitarOuContestar(
                              l.idOrcamento,
                              contestar: true,
                              motivo: 'Contestação do cliente',
                            ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(48, 44),
                    ),
                    child: Text(
                      'Contestar',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: c.enviando.value ? null : () => _abrirMediacao(l),
              icon: Icon(Icons.gavel_outlined, size: 18, color: primary),
              label: Text(
                'Abrir mediação',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipStatus(String label, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: cor,
        ),
      ),
    );
  }
}

class _DeclararPagamentoSheet extends StatefulWidget {
  const _DeclararPagamentoSheet({
    required this.primary,
    required this.valorSugeridoCentavos,
    required this.onFechar,
    required this.onConfirmar,
    this.nomeServico,
  });

  final Color primary;
  final int valorSugeridoCentavos;
  final String? nomeServico;
  final VoidCallback onFechar;
  final ValueChanged<int> onConfirmar;

  @override
  State<_DeclararPagamentoSheet> createState() =>
      _DeclararPagamentoSheetState();
}

class _DeclararPagamentoSheetState extends State<_DeclararPagamentoSheet> {
  late final TextEditingController _valorCtrl;
  final _valorFocus = FocusNode();
  String? _erro;

  @override
  void initState() {
    super.initState();
    final sugerido = widget.valorSugeridoCentavos > 0
        ? NumericInput.dinheiro(widget.valorSugeridoCentavos / 100.0)
        : '';
    _valorCtrl = TextEditingController(text: sugerido);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _valorFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _valorCtrl.dispose();
    _valorFocus.dispose();
    super.dispose();
  }

  int? _centavos() {
    final reais = NumericInput.parseMoeda(_valorCtrl.text);
    if (reais == null || !reais.isFinite || reais <= 0) return null;
    return (reais * 100).round();
  }

  void _confirmar() {
    final cent = _centavos();
    if (cent == null) {
      setState(() => _erro = 'Informe um valor válido em reais.');
      return;
    }
    widget.onConfirmar(cent);
  }

  @override
  Widget build(BuildContext context) {
    final servico = (widget.nomeServico ?? '').trim();
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
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
              'Declarar pagamento à plataforma',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111827),
              ),
            ),
            if (servico.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                servico,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Isto é só uma declaração — não confirma recebimento nem libera '
                'repasse. Não há cobrança automática (“Pagar agora”).',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  height: 1.35,
                  color: const Color(0xFF334155),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _valorCtrl,
              focusNode: _valorFocus,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done,
              inputFormatters: [NumericInput.moeda()],
              onSubmitted: (_) => _confirmar(),
              decoration: InputDecoration(
                labelText: 'Valor (R\$)',
                hintText: 'Ex: R\$ 3.150,00',
                errorText: _erro,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: widget.primary, width: 1.5),
                ),
              ),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              onChanged: (_) {
                if (_erro != null) setState(() => _erro = null);
              },
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _confirmar,
              style: FilledButton.styleFrom(
                backgroundColor: widget.primary,
                minimumSize: const Size(48, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Registrar declaração',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: widget.onFechar,
              child: Text(
                'Cancelar',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
