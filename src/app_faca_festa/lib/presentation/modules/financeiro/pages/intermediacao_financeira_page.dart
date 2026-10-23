import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/core/utils/numeric_input.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/controllers/intermediacao_financeira_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/admin_theme.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/widgets/admin/admin_kit.dart';
import 'package:app_faca_festa/presentation/widgets/festa_app_bar.dart';

/// Fluxo: consultar evento → registrar recebimento → alocar → conferir repasse.
/// Sem banco integrado; confirmação manual é conferência, não transferência.
class IntermediacaoFinanceiraPage extends StatefulWidget {
  const IntermediacaoFinanceiraPage({
    super.key,
    required this.controller,
    required this.themeController,
  });

  final IntermediacaoFinanceiraController controller;
  final EventThemeController themeController;

  @override
  State<IntermediacaoFinanceiraPage> createState() =>
      _IntermediacaoFinanceiraPageState();
}

class _IntermediacaoFinanceiraPageState
    extends State<IntermediacaoFinanceiraPage> {
  final _eventoCtrl = TextEditingController();
  final _valorRecCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _recIdCtrl = TextEditingController();
  final _orcCtrl = TextEditingController();
  final _contratoCtrl = TextEditingController();
  final _valorAlocCtrl = TextEditingController();
  bool _contratoDistinto = false;
  bool _simAberta = false;

  IntermediacaoFinanceiraController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map) {
      final ev = (args['idEvento'] ?? args['id_evento'] ?? '').toString().trim();
      final orc =
          (args['idOrcamento'] ?? args['id_orcamento'] ?? '').toString().trim();
      final contrato =
          (args['idContrato'] ?? args['id_contrato'] ?? '').toString().trim();
      if (ev.isNotEmpty) {
        _eventoCtrl.text = ev;
        c.idEvento.value = ev;
      }
      if (orc.isNotEmpty) _orcCtrl.text = orc;
      if (contrato.isNotEmpty && contrato != orc) {
        _contratoDistinto = true;
        _contratoCtrl.text = contrato;
      }
      if (ev.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          c.carregarExtrato(ev);
        });
      }
    }
  }

  @override
  void dispose() {
    _eventoCtrl.dispose();
    _valorRecCtrl.dispose();
    _refCtrl.dispose();
    _recIdCtrl.dispose();
    _orcCtrl.dispose();
    _contratoCtrl.dispose();
    _valorAlocCtrl.dispose();
    super.dispose();
  }

  String _reais(dynamic centavos) {
    final n = (centavos is num) ? centavos.toInt() : 0;
    return NumericInput.dinheiro(n / 100.0);
  }

  String _idCurto(String id) {
    if (id.isEmpty) return '—';
    if (id.length <= 14) return id;
    if (id.contains('-') && id.length >= 20) {
      return '${id.substring(0, 8)}…${id.substring(id.length - 4)}';
    }
    return '${id.substring(0, 12)}…';
  }

  int? _centavosDeCampo(TextEditingController ctrl) {
    final t = ctrl.text.trim().replaceAll('.', '').replaceAll(',', '.');
    final v = double.tryParse(t);
    if (v == null || !v.isFinite || v < 0) return null;
    return (v * 100).round();
  }

  void _usarRecebimento(Map<String, dynamic> m, {bool avisar = true}) {
    final id = (m['id'] ?? m['id_recebimento'] ?? '').toString();
    final alocado = (m['alocado_centavos'] is num)
        ? (m['alocado_centavos'] as num).toInt()
        : 0;
    final valor = (m['valor_centavos'] is num)
        ? (m['valor_centavos'] as num).toInt()
        : 0;
    final restante = (valor - alocado).clamp(0, valor);
    setState(() {
      _recIdCtrl.text = id;
      if (restante > 0) {
        _valorAlocCtrl.text = (restante / 100.0).toStringAsFixed(2);
      }
    });
    if (avisar) {
      Get.snackbar(
        'Alocação',
        'Recebimento selecionado. Informe o contrato e confirme.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _copiarId(String id) async {
    await Clipboard.setData(ClipboardData(text: id));
    Get.snackbar(
      'Copiado',
      'Referência completa na área de transferência.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final busy = c.carregando.value;
      final err = c.erro.value;
      final aviso = c.aviso.value;
      final ext = c.extrato.value;
      final sim = c.simulacao.value;
      c.enviando.value;
      return Scaffold(
        backgroundColor: AdminPalette.surface,
        appBar: FestaAppBar(
          titulo: 'Intermediação',
          themeController: widget.themeController,
          acoes: [
            IconButton(
              tooltip: 'Simular cenário de aceite',
              icon: const Icon(Icons.science_outlined, color: Colors.white),
              onPressed: () {
                c.simularCenarioAceite();
                setState(() => _simAberta = true);
              },
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final pad = w >= 1100 ? 28.0 : (w >= 720 ? 20.0 : 16.0);
            final maxW = w >= 1280 ? 960.0 : w;
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    pad,
                    FestaPageInsets.belowAppBar,
                    pad,
                    32,
                  ),
                  children: [
                    Text(
                      'Cliente → plataforma → fornecedor',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AdminPalette.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sem banco integrado. Confirmar repasse é conferência manual — '
                      'não move dinheiro automaticamente.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AdminPalette.muted,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _passosVisuais(),
                    const SizedBox(height: 16),
                    _painelConsulta(busy),
                    if (err.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _banner(err, AdminPalette.danger),
                    ],
                    if (aviso.isNotEmpty && ext == null) ...[
                      const SizedBox(height: 12),
                      _banner(aviso, AdminPalette.warning),
                    ],
                    if (ext != null) ...[
                      const SizedBox(height: 12),
                      _painelPolitica(ext),
                    ],
                    if (sim != null && _simAberta) ...[
                      const SizedBox(height: 14),
                      _painelSimulacao(sim),
                    ],
                    if (ext == null && err.isEmpty) ...[
                      const SizedBox(height: 24),
                      const AdminEmptyState(
                        icon: Icons.account_balance_outlined,
                        title: 'Consulte um evento',
                        message:
                            'Informe a referência do evento para ver recebimentos, '
                            'alocações e repasses deste fluxo.',
                      ),
                    ],
                    if (ext != null) ...[
                      const SizedBox(height: 16),
                      _sintese(ext),
                      const SizedBox(height: 14),
                      _listaRecebimentos(ext),
                      const SizedBox(height: 14),
                      _listaRepasses(ext),
                      const SizedBox(height: 16),
                      _painelRecebimento(),
                      const SizedBox(height: 12),
                      _painelAlocacao(),
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

  Widget _passosVisuais() {
    const passos = [
      ('1', 'Consultar'),
      ('2', 'Receber'),
      ('3', 'Alocar'),
      ('4', 'Repassar'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: passos
          .map(
            (p) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AdminPalette.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AdminPalette.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      p.$1,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    p.$2,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AdminPalette.ink,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _secaoTitulo(String passo, String titulo, {String? nota}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AdminPalette.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            passo,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AdminPalette.primary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AdminPalette.ink,
                ),
              ),
              if (nota != null)
                Text(
                  nota,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AdminPalette.muted,
                    height: 1.3,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _campo({
    required String label,
    String? hint,
    String? helper,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      filled: true,
      fillColor: AdminPalette.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      isDense: true,
    );
  }

  Widget _painelConsulta(bool busy) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: adminCardDecoration(highlighted: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _secaoTitulo(
            '1',
            'Consultar evento',
            nota: 'Tudo abaixo depende deste recorte.',
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, box) {
              final stack = box.maxWidth < 520;
              final campo = TextField(
                controller: _eventoCtrl,
                decoration: _campo(
                  label: 'Referência do evento',
                  hint: 'ID do evento',
                ),
                onSubmitted: busy
                    ? null
                    : (_) => c.carregarExtrato(_eventoCtrl.text.trim()),
              );
              final botao = FilledButton.icon(
                onPressed: busy
                    ? null
                    : () => c.carregarExtrato(_eventoCtrl.text.trim()),
                icon: busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.search_rounded, size: 18),
                label: Text(
                  'Consultar',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AdminPalette.primary,
                  minimumSize: Size(stack ? double.infinity : 48, 48),
                ),
              );
              if (stack) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [campo, const SizedBox(height: 10), botao],
                );
              }
              return Row(
                children: [
                  Expanded(child: campo),
                  const SizedBox(width: 10),
                  botao,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _painelSimulacao(Map<String, dynamic> sim) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: adminCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Simulação de política (exemplo)',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AdminPalette.ink,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Fechar',
                onPressed: () => setState(() => _simAberta = false),
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
            ],
          ),
          Text(
            'Contrato R\$ 10.000 → fornecedor ${_reais(sim['direito_fornecedor_centavos'])}, '
            'comissão ${_reais(sim['comissao_centavos'])}.\n'
            'Com R\$ 4.000 recebidos: a receber ${_reais(sim['a_receber_apos_4000_centavos'])}; '
            'elegível sem política ${_reais(sim['elegivel_sem_politica'])}; '
            'com teto R\$ 3.000 → ${_reais(sim['elegivel_com_teto_3000'])}.\n'
            'Autorizar ≠ confirmado.',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: AdminPalette.muted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sintese(Map<String, dynamic> ext) {
    final s = ext['sintese'];
    if (s is! Map) return const SizedBox.shrink();
    final itens = [
      ('Recebido', _reais(s['recebido_plataforma_centavos']), Icons.payments_outlined),
      ('Alocado', _reais(s['alocado_centavos']), Icons.link_rounded),
      ('Sem alocação', _reais(s['sem_alocacao_centavos']), Icons.hourglass_empty_rounded),
      ('Repassado', _reais(s['repassado_confirmado_centavos']), Icons.south_west_rounded),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Neste evento',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AdminPalette.ink,
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, box) {
            final cols = box.maxWidth >= 720 ? 4 : (box.maxWidth >= 480 ? 2 : 1);
            const gap = 10.0;
            final tileW = cols == 1
                ? box.maxWidth
                : (box.maxWidth - gap * (cols - 1)) / cols;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: itens
                  .map(
                    (e) => SizedBox(
                      width: tileW,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        decoration: adminCardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(e.$3, size: 18, color: AdminPalette.primary),
                            const SizedBox(height: 8),
                            Text(
                              e.$2,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: AdminPalette.ink,
                              ),
                            ),
                            Text(
                              e.$1,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AdminPalette.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _listaRecebimentos(Map<String, dynamic> ext) {
    final raw = ext['recebimentos'];
    final lista = raw is List ? raw : const [];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: adminCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recebimentos',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Toque em “Usar na alocação” para preencher o passo 3.',
            style: GoogleFonts.poppins(fontSize: 12, color: AdminPalette.muted),
          ),
          const SizedBox(height: 10),
          if (lista.isEmpty)
            Text(
              'Nenhum recebimento neste evento. Use o passo 2 abaixo.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AdminPalette.muted,
              ),
            )
          else
            ...lista.map((e) {
              final m = Map<String, dynamic>.from(e as Map);
              final id = (m['id'] ?? m['id_recebimento'] ?? '').toString();
              final selecionado = _recIdCtrl.text == id;
              final alocado = (m['alocado_centavos'] is num)
                  ? (m['alocado_centavos'] as num).toInt()
                  : 0;
              final valor = (m['valor_centavos'] is num)
                  ? (m['valor_centavos'] as num).toInt()
                  : 0;
              final restante = (valor - alocado).clamp(0, valor);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selecionado
                      ? AdminPalette.primary.withValues(alpha: 0.06)
                      : AdminPalette.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selecionado
                        ? AdminPalette.primary.withValues(alpha: 0.35)
                        : AdminPalette.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _reais(valor),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: AdminPalette.ink,
                            ),
                          ),
                        ),
                        AdminStatusChip(
                          label: (m['nivel_confirmacao'] ?? 'conferência')
                              .toString(),
                          color: AdminPalette.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Alocado ${_reais(alocado)} · Disponível ${_reais(restante)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: AdminPalette.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    InkWell(
                      onTap: () => _copiarId(id),
                      child: Text(
                        'ID ${_idCurto(id)}',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: AdminPalette.muted,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: restante <= 0
                            ? null
                            : () => _usarRecebimento(m),
                        child: Text(
                          selecionado ? 'Selecionado' : 'Usar na alocação',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: restante <= 0
                                ? AdminPalette.muted
                                : AdminPalette.primary,
                          ),
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

  Map<String, dynamic>? _politicaAtiva(Map<String, dynamic> ext) {
    final p = ext['politica_liberacao'];
    if (p is Map && p['ativa'] == true) return Map<String, dynamic>.from(p);
    return null;
  }

  Widget _painelPolitica(Map<String, dynamic> ext) {
    final pol = _politicaAtiva(ext);
    final ativa = pol != null;
    final parcial = pol?['permiteRepasseParcial'] == true;
    final teto = pol?['tetoParcialCentavos'];
    final cor = ativa ? AdminPalette.success : AdminPalette.warning;
    final descricao = !ativa
        ? 'Inativa — nenhum repasse pode ser autorizado. Ative para liberar o passo 4.'
        : parcial
            ? (teto is num
                ? 'Ativa — repasse parcial permitido, até ${_reais(teto)} por vez.'
                : 'Ativa — repasse parcial permitido conforme o valor alocado.')
            : 'Ativa — repasse só quando o contrato estiver 100% alocado.';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            ativa ? Icons.verified_outlined : Icons.lock_outline_rounded,
            color: cor,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Política de liberação de repasse',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: AdminPalette.ink,
                  ),
                ),
                Text(
                  descricao,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: AdminPalette.muted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: c.enviando.value ? null : () => _editarPolitica(pol),
            child: Text(
              ativa ? 'Editar' : 'Ativar',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: AdminPalette.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editarPolitica(Map<String, dynamic>? pol) async {
    var ativa = pol == null ? true : pol['ativa'] == true;
    var parcial = pol?['permiteRepasseParcial'] == true;
    final teto = pol?['tetoParcialCentavos'];
    final tetoCtrl = TextEditingController(
      text: teto is num ? NumericInput.dinheiro(teto / 100.0) : '',
    );
    final salvar = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(
            'Política de liberação',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: ativa,
                  onChanged: (v) => setD(() => ativa = v),
                  title: Text('Política ativa',
                      style: GoogleFonts.poppins(fontSize: 14)),
                  subtitle: Text(
                    'Sem política ativa, nenhum repasse é autorizado.',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: parcial,
                  onChanged: ativa ? (v) => setD(() => parcial = v) : null,
                  title: Text('Permitir repasse parcial',
                      style: GoogleFonts.poppins(fontSize: 14)),
                  subtitle: Text(
                    'Desligado: só repassa com o contrato 100% alocado.',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ),
                if (ativa && parcial)
                  TextField(
                    controller: tetoCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [NumericInput.moeda()],
                    decoration: _campo(
                      label: 'Teto por repasse (R\$) — opcional',
                      hint: 'Vazio = sem teto',
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Cancelar', style: GoogleFonts.poppins()),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AdminPalette.primary,
              ),
              child: Text(
                'Salvar',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
    final tetoReais = NumericInput.parseMoeda(tetoCtrl.text);
    tetoCtrl.dispose();
    if (salvar != true) return;
    final ok = await c.salvarPolitica(
      ativa: ativa,
      permiteParcial: parcial,
      tetoParcialCentavos:
          tetoReais != null && tetoReais > 0 ? (tetoReais * 100).round() : null,
    );
    if (ok && mounted) {
      Get.snackbar(
        'Política',
        ativa ? 'Política ativa salva.' : 'Política desativada.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Widget _contratoRepasse(Map<String, dynamic> m) {
    final elegivel = (m['elegivel_centavos'] is num)
        ? (m['elegivel_centavos'] as num).toInt()
        : 0;
    final motivo = (m['motivo_bloqueio'] ?? '').toString();
    final semFornecedor = (m['id_fornecedor'] ?? '').toString().isEmpty;
    final podeAutorizar =
        elegivel > 0 && !semFornecedor && !c.enviando.value;
    final declarado = (m['pagamento_declarado_centavos'] is num)
        ? (m['pagamento_declarado_centavos'] as num).toInt()
        : 0;
    final linhas = [
      ('Contratado', _reais(m['valor_contratado_centavos'])),
      ('Direito do fornecedor', _reais(m['direito_fornecedor_centavos'])),
      ('Alocado', _reais(m['alocado_centavos'])),
      ('Autorizado', _reais(m['repasse_autorizado_centavos'])),
      ('Repassado', _reais(m['repasse_confirmado_centavos'])),
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminPalette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  (m['nome_servico'] ?? 'Serviço contratado').toString(),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AdminPalette.ink,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _orcCtrl.text = (m['id_orcamento'] ?? '').toString();
                    final idContrato = (m['id_contrato'] ?? '').toString();
                    _contratoDistinto = idContrato.isNotEmpty &&
                        idContrato != _orcCtrl.text;
                    _contratoCtrl.text = _contratoDistinto ? idContrato : '';
                  });
                  Get.snackbar(
                    'Alocação',
                    'Contrato preenchido no passo 3.',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
                child: Text(
                  'Usar na alocação',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: AdminPalette.primary,
                  ),
                ),
              ),
            ],
          ),
          if (declarado > 0)
            Text(
              'Organizador declarou ${_reais(declarado)} pago',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AdminPalette.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: linhas
                .map(
                  (l) => Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${l.$1} ',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AdminPalette.muted,
                          ),
                        ),
                        TextSpan(
                          text: l.$2,
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AdminPalette.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          if (podeAutorizar)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  final estado = await c.prepararRepasse(m);
                  if (estado != null && mounted) {
                    Get.snackbar(
                      'Repasse',
                      estado == 'autorizado'
                          ? 'Autorizado. Confirme abaixo após transferir ao fornecedor.'
                          : 'Repasse registrado como "$estado".',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  }
                },
                icon: const Icon(Icons.verified_outlined, size: 18),
                label: Text(
                  'Autorizar repasse de ${_reais(elegivel)}',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AdminPalette.primary,
                  minimumSize: const Size(48, 44),
                ),
              ),
            )
          else
            Text(
              semFornecedor
                  ? 'Contrato sem fornecedor vinculado.'
                  : motivo.isNotEmpty
                      ? motivo
                      : 'Nada elegível para repasse agora.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AdminPalette.muted,
                height: 1.3,
              ),
            ),
        ],
      ),
    );
  }

  Widget _listaRepasses(Map<String, dynamic> ext) {
    final raw = ext['repasses'];
    final lista = raw is List ? raw : const [];
    final rawContratos = ext['contratos'];
    final contratos = rawContratos is List ? rawContratos : const [];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: adminCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _secaoTitulo(
            '4',
            'Repasses',
            nota: 'Autorizado ainda não é transferido. Confirmar = conferência.',
          ),
          const SizedBox(height: 12),
          Text(
            'Contratos do evento',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AdminPalette.ink,
            ),
          ),
          const SizedBox(height: 8),
          if (contratos.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Nenhum contrato fechado neste evento.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AdminPalette.muted,
                ),
              ),
            )
          else
            ...contratos.map(
              (e) => _contratoRepasse(Map<String, dynamic>.from(e as Map)),
            ),
          const SizedBox(height: 4),
          Text(
            'Repasses registrados',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AdminPalette.ink,
            ),
          ),
          const SizedBox(height: 8),
          if (lista.isEmpty)
            Text(
              'Nenhum repasse preparado neste evento.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AdminPalette.muted,
              ),
            )
          else
            ...lista.map((e) {
              final m = Map<String, dynamic>.from(e as Map);
              final id = (m['id'] ?? m['id_repasse'] ?? '').toString();
              final estado = (m['estado'] ?? '—').toString();
              final podeConfirmar =
                  estado == 'autorizado' || estado == 'em_processamento';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AdminPalette.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _reais(m['valor_centavos']),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AdminStatusChip(
                            label: estado,
                            color: estado == 'confirmado'
                                ? AdminPalette.success
                                : AdminPalette.warning,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _idCurto(id),
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              color: AdminPalette.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (podeConfirmar)
                      FilledButton(
                        onPressed: c.enviando.value
                            ? null
                            : () async {
                                final ok = await c.confirmarRepasse(id);
                                if (ok && mounted) {
                                  Get.snackbar(
                                    'Repasse',
                                    'Confirmado por conferência manual.',
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                }
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: AdminPalette.primary,
                          minimumSize: const Size(48, 40),
                        ),
                        child: Text(
                          'Confirmar',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
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

  Widget _painelRecebimento() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: adminCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _secaoTitulo(
            '2',
            'Registrar recebimento',
            nota: 'Conferência de valor na plataforma — ainda não destina ao fornecedor.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _valorRecCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _campo(label: 'Valor (R\$)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _refCtrl,
            decoration: _campo(
              label: 'Referência externa (opcional)',
              hint: 'Ex.: comprovante, PIX',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: c.enviando.value
                ? null
                : () async {
                    final cent = _centavosDeCampo(_valorRecCtrl);
                    if (cent == null) {
                      Get.snackbar('Recebimento', 'Informe um valor válido.');
                      return;
                    }
                    if (_eventoCtrl.text.trim().isEmpty) {
                      Get.snackbar('Recebimento', 'Consulte o evento no passo 1.');
                      return;
                    }
                    c.idEvento.value = _eventoCtrl.text.trim();
                    final ok = await c.registrarRecebimento(
                      valorCentavos: cent,
                      referencia: _refCtrl.text.trim().isEmpty
                          ? null
                          : _refCtrl.text.trim(),
                    );
                    if (ok && mounted) {
                      _valorRecCtrl.clear();
                      _refCtrl.clear();
                      final lista = c.extrato.value?['recebimentos'];
                      if (lista is List && lista.isNotEmpty) {
                        final m = Map<String, dynamic>.from(lista.last as Map);
                        _usarRecebimento(m, avisar: false);
                      }
                      Get.snackbar(
                        'Recebimento',
                        'Registrado e pronto para alocar ao contrato.',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    }
                  },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(
              'Registrar recebimento',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AdminPalette.primary,
              minimumSize: const Size(48, 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _painelAlocacao() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: adminCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _secaoTitulo(
            '3',
            'Alocar a um contrato',
            nota: 'Sem rateio automático. Escolha o recebimento na lista acima.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _recIdCtrl,
            decoration: _campo(
              label: 'Recebimento selecionado',
              hint: 'Toque em “Usar na alocação” ou cole o ID',
              helper: _recIdCtrl.text.isEmpty
                  ? 'Preferível selecionar na lista acima'
                  : 'ID ${_idCurto(_recIdCtrl.text)}',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _orcCtrl,
            decoration: _campo(
              label: 'ID do orçamento / contrato',
              hint: 'Destino comercial',
            ),
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () =>
                setState(() => _contratoDistinto = !_contratoDistinto),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    _contratoDistinto
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 20,
                    color: AdminPalette.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _contratoDistinto
                        ? 'Ocultar ID de contrato distinto'
                        : 'Contrato com ID diferente do orçamento',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                      color: AdminPalette.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_contratoDistinto) ...[
            TextField(
              controller: _contratoCtrl,
              decoration: _campo(
                label: 'ID do contrato',
                hint: 'Só se for diferente do orçamento',
              ),
            ),
            const SizedBox(height: 10),
          ],
          TextField(
            controller: _valorAlocCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _campo(label: 'Valor a alocar (R\$)'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: c.enviando.value
                ? null
                : () async {
                    final cent = _centavosDeCampo(_valorAlocCtrl);
                    final orc = _orcCtrl.text.trim();
                    final rec = _recIdCtrl.text.trim();
                    if (cent == null || orc.isEmpty || rec.isEmpty) {
                      Get.snackbar(
                        'Alocação',
                        'Selecione um recebimento, informe o contrato e o valor.',
                      );
                      return;
                    }
                    final contrato = _contratoCtrl.text.trim().isEmpty
                        ? orc
                        : _contratoCtrl.text.trim();
                    final ok = await c.alocarManual(
                      idRecebimento: rec,
                      idOrcamento: orc,
                      idContrato: contrato,
                      valorCentavos: cent,
                    );
                    if (ok && mounted) {
                      _valorAlocCtrl.clear();
                      Get.snackbar(
                        'Alocação',
                        'Registrada. Não implica repasse automático.',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    }
                  },
            icon: const Icon(Icons.link_rounded, size: 18),
            label: Text(
              'Alocar ao contrato',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AdminPalette.primary,
              minimumSize: const Size(48, 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _banner(String msg, Color cor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            cor == AdminPalette.danger
                ? Icons.error_outline_rounded
                : Icons.info_outline_rounded,
            color: cor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: GoogleFonts.poppins(fontSize: 13, color: AdminPalette.ink),
            ),
          ),
        ],
      ),
    );
  }
}
