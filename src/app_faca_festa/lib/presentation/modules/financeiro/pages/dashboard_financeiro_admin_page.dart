import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/core/utils/numeric_input.dart';
import 'package:app_faca_festa/domain/entities/financeiro/contratacao_identidade.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/controllers/dashboard_financeiro_admin_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/admin_theme.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/widgets/admin/admin_kit.dart';
import 'package:app_faca_festa/presentation/widgets/festa_app_bar.dart';

/// Visão financeira administrativa — síntese executiva, filtros compactos, eventos.
class DashboardFinanceiroAdminPage extends StatefulWidget {
  const DashboardFinanceiroAdminPage({
    super.key,
    required this.controller,
    required this.themeController,
  });

  final DashboardFinanceiroAdminController controller;
  final EventThemeController themeController;

  @override
  State<DashboardFinanceiroAdminPage> createState() =>
      _DashboardFinanceiroAdminPageState();
}

class _DashboardFinanceiroAdminPageState
    extends State<DashboardFinanceiroAdminPage> {
  final _fornecedorCtrl = TextEditingController();
  final _periodoInicioCtrl = TextEditingController();
  final _periodoFimCtrl = TextEditingController();
  bool _maisFiltros = false;

  DashboardFinanceiroAdminController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    if (c.filtroFornecedor.value.isNotEmpty) {
      _fornecedorCtrl.text = c.filtroFornecedor.value;
    }
    _periodoInicioCtrl.text = c.periodoInicio.value;
    _periodoFimCtrl.text = c.periodoFim.value;
    WidgetsBinding.instance.addPostFrameCallback((_) => c.carregar());
  }

  @override
  void dispose() {
    _fornecedorCtrl.dispose();
    _periodoInicioCtrl.dispose();
    _periodoFimCtrl.dispose();
    super.dispose();
  }

  String _reais(dynamic centavos) {
    final n = (centavos is num) ? centavos.toInt() : 0;
    return NumericInput.dinheiro(n / 100.0);
  }

  int _n(Map<String, dynamic> r, List<String> keys) {
    for (final k in keys) {
      final v = r[k];
      if (v is num) return v.toInt();
    }
    return 0;
  }

  Map<String, dynamic>? _comissaoMap(Map<String, dynamic> r) {
    final nested = r['comissao'];
    if (nested is Map) {
      return nested.map((k, v) => MapEntry(k.toString(), v));
    }
    return null;
  }

  int _comissaoCampo(Map<String, dynamic> r, List<String> flat, List<String> nested) {
    for (final k in flat) {
      final v = r[k];
      if (v is num) return v.toInt();
    }
    final m = _comissaoMap(r);
    if (m != null) {
      for (final k in nested) {
        final v = m[k];
        if (v is num) return v.toInt();
      }
    }
    return 0;
  }

  bool _comissaoConfigurada(Map<String, dynamic> r) {
    if (r['comissaoConfigurada'] == true || r['comissao_configurada'] == true) {
      return true;
    }
    final m = _comissaoMap(r);
    return m?['configurada'] == true;
  }

  String _rotuloEixo(String eixo) {
    switch (eixo) {
      case 'data_contratacao':
        return 'Recorte pela data da contratação';
      case 'data_evento':
      default:
        return 'Recorte pela data do evento';
    }
  }

  Future<void> _copiarCsv() async {
    if (c.filtrosPendentes.value) {
      Get.snackbar(
        'Copiar CSV',
        'Há filtros alterados e ainda não aplicados. Aplique-os ou limpe antes de copiar.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final csv = c.exportarCsv();
    if (csv.isEmpty) {
      Get.snackbar('Copiar CSV', 'Nada para copiar neste recorte.');
      return;
    }
    await Clipboard.setData(ClipboardData(text: csv));
    Get.snackbar(
      'Copiar CSV',
      'CSV copiado (mesmo recorte da consulta atual).',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final r = c.resumo.value;
      final err = c.erro.value;
      final aviso = c.aviso.value;
      final sync = c.sincronizado.value;
      final busy = c.carregando.value;
      final pendentes = c.filtrosPendentes.value;
      final loading = busy && r == null;
      // Lê eixo/filtros aqui para o Obx reagir a rascunhos.
      c.eixoTemporal.value;
      c.filtroEstado.value;
      return Scaffold(
        backgroundColor: AdminPalette.surface,
        appBar: FestaAppBar(
          titulo: 'Visão financeira',
          themeController: widget.themeController,
          acoes: [
            IconButton(
              tooltip: 'Copiar CSV',
              icon: const Icon(Icons.content_copy_rounded, color: Colors.white),
              onPressed: _copiarCsv,
            ),
            IconButton(
              tooltip: 'Atualizar',
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: busy ? null : c.carregar,
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
                        padding: EdgeInsets.fromLTRB(pad, FestaPageInsets.belowAppBar, pad, 32),
                        children: [
                          _cabecalho(
                            busy: busy,
                            sync: sync,
                            erro: err,
                            aviso: aviso,
                          ),
                          if (err.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _bannerErro(err),
                          ] else if (aviso.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _bannerAviso(aviso),
                          ],
                          const SizedBox(height: 14),
                          _barraFiltros(w, pendentes: pendentes, busy: busy),
                          if (r != null) ...[
                            const SizedBox(height: 16),
                            _heroReceita(r),
                            const SizedBox(height: 12),
                            _kpisExecutivos(r, w),
                            const SizedBox(height: 12),
                            _contagemRecorte(r),
                            if (c.consultaTruncada ||
                                c.qtdIdentidadeIncompleta > 0) ...[
                              const SizedBox(height: 12),
                              _avisosCompletude(),
                            ],
                            const SizedBox(height: 16),
                            // Evento primeiro (agregado) → contratação (linha a linha).
                            _secaoEventos(r, w, erro: err),
                            const SizedBox(height: 16),
                            _secaoContratacoes(w),
                          ] else if (err.isEmpty && !busy)
                            Padding(
                              padding: const EdgeInsets.only(top: 24),
                              child: AdminEmptyState(
                                icon: Icons.query_stats_outlined,
                                title: 'Sem consulta ainda',
                                message:
                                    'Escolha o período e toque em Aplicar filtros.',
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      );
    });
  }

  Widget _cabecalho({
    required bool busy,
    required bool sync,
    required String erro,
    required String aviso,
  }) {
    final cor = sync
        ? (aviso.isNotEmpty ? AdminPalette.warning : AdminPalette.success)
        : busy
            ? AdminPalette.warning
            : erro.isNotEmpty
                ? AdminPalette.danger
                : AdminPalette.muted;
    final status = busy
        ? 'Atualizando…'
        : sync
            ? (aviso.isNotEmpty
                ? 'Síntese local · ${_rotuloEixo(c.eixoAplicado)}'
                : 'Consulta sincronizada · ${_rotuloEixo(c.eixoAplicado)}')
            : erro.isNotEmpty
                ? 'Falha na consulta — não é lista vazia'
                : 'Aguardando consulta';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Movimento de contratos e receita própria da plataforma (comissões).',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AdminPalette.ink,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: cor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                busy
                    ? Icons.sync_rounded
                    : sync
                        ? Icons.verified_outlined
                        : Icons.info_outline_rounded,
                size: 15,
                color: cor,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  status,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bannerAviso(String texto) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminPalette.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminPalette.warning.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              color: AdminPalette.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AdminPalette.ink,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _barraFiltros(
    double w, {
    required bool pendentes,
    required bool busy,
  }) {
    final compact = w < 980;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: adminCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Recorte da consulta',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AdminPalette.ink,
                  ),
                ),
              ),
              if (pendentes)
                AdminStatusChip(
                  label: 'Alterações pendentes',
                  color: AdminPalette.warning,
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (compact) ...[
            _dropdownEixo(),
            const SizedBox(height: 10),
            _dropdownEstado(),
            const SizedBox(height: 10),
            _campoFornecedor(),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _dropdownEixo()),
                const SizedBox(width: 10),
                Expanded(flex: 2, child: _dropdownEstado()),
                const SizedBox(width: 10),
                Expanded(flex: 3, child: _campoFornecedor()),
              ],
            ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () => setState(() => _maisFiltros = !_maisFiltros),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    _maisFiltros
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 20,
                    color: AdminPalette.primary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _maisFiltros
                          ? 'Ocultar período'
                          : 'Definir período (início e fim)',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AdminPalette.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_maisFiltros) ...[
            if (compact) ...[
              _campoPeriodo(
                label: 'Início (AAAA-MM-DD)',
                controller: _periodoInicioCtrl,
                onChanged: (v) {
                  c.periodoInicio.value = v.trim();
                  c.marcarFiltroAlterado();
                },
              ),
              const SizedBox(height: 10),
              _campoPeriodo(
                label: 'Fim (AAAA-MM-DD)',
                controller: _periodoFimCtrl,
                onChanged: (v) {
                  c.periodoFim.value = v.trim();
                  c.marcarFiltroAlterado();
                },
              ),
            ] else
              Row(
                children: [
                  Expanded(
                    child: _campoPeriodo(
                      label: 'Início (AAAA-MM-DD)',
                      controller: _periodoInicioCtrl,
                      onChanged: (v) {
                        c.periodoInicio.value = v.trim();
                        c.marcarFiltroAlterado();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _campoPeriodo(
                      label: 'Fim (AAAA-MM-DD)',
                      controller: _periodoFimCtrl,
                      onChanged: (v) {
                        c.periodoFim.value = v.trim();
                        c.marcarFiltroAlterado();
                      },
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: busy ? null : c.carregar,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text(
                  'Aplicar filtros',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AdminPalette.primary,
                  minimumSize: const Size(48, 46),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
              ),
              TextButton(
                onPressed: () {
                  _fornecedorCtrl.clear();
                  _periodoInicioCtrl.clear();
                  _periodoFimCtrl.clear();
                  c.limparFiltros();
                  c.carregar();
                },
                child: Text(
                  'Limpar',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: AdminPalette.muted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dropdownEixo() {
    return DropdownButtonFormField<String>(
      value: c.eixoTemporal.value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Olhar por',
        helperText: _rotuloEixo(c.eixoTemporal.value),
        filled: true,
        fillColor: AdminPalette.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
      ),
      items: const [
        DropdownMenuItem(
          value: 'data_evento',
          child: Text('Data do evento', overflow: TextOverflow.ellipsis),
        ),
        DropdownMenuItem(
          value: 'data_contratacao',
          child: Text('Data da contratação', overflow: TextOverflow.ellipsis),
        ),
      ],
      onChanged: (v) {
        if (v == null) return;
        c.eixoTemporal.value = v;
        c.marcarFiltroAlterado();
      },
    );
  }

  Widget _campoFornecedor() {
    return TextField(
      controller: _fornecedorCtrl,
      decoration: InputDecoration(
        labelText: 'ID do fornecedor',
        hintText: 'Opcional',
        filled: true,
        fillColor: AdminPalette.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
      ),
      onChanged: (v) {
        c.filtroFornecedor.value = v.trim();
        c.marcarFiltroAlterado();
      },
    );
  }

  Widget _dropdownEstado() {
    return DropdownButtonFormField<String>(
      value: c.filtroEstado.value.isEmpty ? '' : c.filtroEstado.value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Situação',
        filled: true,
        fillColor: AdminPalette.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
      ),
      items: const [
        DropdownMenuItem(value: '', child: Text('Todos')),
        DropdownMenuItem(value: 'contratado', child: Text('Contratados')),
        DropdownMenuItem(value: 'oportunidade', child: Text('Oportunidades')),
      ],
      onChanged: (v) {
        c.filtroEstado.value = v ?? '';
        c.marcarFiltroAlterado();
      },
    );
  }

  Widget _campoPeriodo({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AdminPalette.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
      ),
      onChanged: onChanged,
    );
  }

  Widget _heroReceita(Map<String, dynamic> r) {
    final completo = r['completo'] == true;
    final receita = _n(r, [
      'receitaPlataformaCentavos',
      'receita_plataforma_centavos',
      'comissaoRecebidasCentavos',
      'comissao_recebidas_centavos',
    ]);
    final cfg = _comissaoConfigurada(r);
    final nota = !cfg
        ? 'Comissão não configurada — sem política/dados válidos.'
        : completo
            ? 'Comissões já recebidas neste recorte — receita própria da plataforma.'
            : 'Faltam informações para concluir todos os componentes.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: adminCardDecoration(highlighted: true),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AdminPalette.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: AdminPalette.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Receita própria da plataforma',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AdminPalette.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _reais(receita),
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AdminPalette.ink,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  nota,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: cfg && !completo
                        ? AdminPalette.warning
                        : AdminPalette.muted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpisExecutivos(Map<String, dynamic> r, double w) {
    final cols = w >= 1100 ? 3 : (w >= 720 ? 3 : 1);
    final volume = _n(r, [
      'volumeContratadoCentavos',
      'volume_contratado_centavos',
    ]);
    final gerada = _comissaoCampo(
      r,
      ['comissaoGeradasCentavos', 'comissao_geradas_centavos'],
      ['geradasCentavos', 'geradas_centavos'],
    );
    final aReceber = _comissaoCampo(
      r,
      ['comissaoAReceberCentavos', 'comissao_a_receber_centavos'],
      ['aReceberCentavos', 'a_receber_centavos'],
    );
    // Mantém string "Comissão recebida" no hero; KPIs = o que falta entender.
    final tiles = [
      _kpiTile(
        'Movimentado em contratos',
        _reais(volume),
        Icons.handshake_outlined,
        'Não é receita da plataforma',
      ),
      _kpiTile(
        'Comissão gerada',
        _reais(gerada),
        Icons.receipt_long_outlined,
        'Devida no recorte',
      ),
      _kpiTile(
        'Saldo de comissões',
        _reais(aReceber),
        Icons.schedule_outlined,
        'Ainda a receber',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Leitura do recorte',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AdminPalette.ink,
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, box) {
            const gap = 10.0;
            final tileW = cols == 1
                ? box.maxWidth
                : (box.maxWidth - gap * (cols - 1)) / cols;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: tiles
                  .map((t) => SizedBox(width: tileW, child: t))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _kpiTile(String label, String value, IconData icon, String? nota) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: adminCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AdminPalette.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AdminPalette.primary, size: 18),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AdminPalette.ink,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AdminPalette.ink,
            ),
          ),
          if (nota != null) ...[
            const SizedBox(height: 2),
            Text(
              nota,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                color: AdminPalette.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _contagemRecorte(Map<String, dynamic> r) {
    final partes = <String>[
      '${_n(r, ['qtdEventos', 'qtd_eventos'])} eventos',
      '${_n(r, ['qtdContratos', 'qtd_contratos'])} contratos',
      '${_n(r, ['qtdServicosDistintos', 'qtd_servicos_distintos'])} serviços',
      '${_n(r, ['qtdFornecedoresDistintos', 'qtd_fornecedores_distintos'])} fornecedores',
      '${_n(r, ['qtdOportunidades', 'qtd_oportunidades'])} oportunidades',
    ];
    return Text(
      'Neste recorte: ${partes.join(' · ')}',
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AdminPalette.muted,
        height: 1.35,
      ),
    );
  }

  String _rotuloEventoCurto(String id) {
    if (id.isEmpty) return 'Sem identificação';
    if (id.length <= 12) return id;
    // UUID: primeiros 8 + últimos 4 — legível sem parecer “hash cru”.
    if (id.contains('-') && id.length >= 20) {
      return '${id.substring(0, 8)}…${id.substring(id.length - 4)}';
    }
    return '${id.substring(0, 10)}…';
  }

  Color _corStatusEvento(String status) {
    final s = status.toLowerCase();
    if (s.contains('contrat')) return AdminPalette.success;
    if (s.contains('oportun') || s.contains('pend')) return AdminPalette.warning;
    if (s.contains('cancel') || s.contains('recus')) return AdminPalette.danger;
    return AdminPalette.muted;
  }

  Widget _secaoEventos(Map<String, dynamic> r, double w, {required String erro}) {
    final raw = r['linhasEvento'] ?? r['linhas_evento'];
    final linhas = raw is List
        ? raw.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Por evento',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AdminPalette.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Toque em um evento para ver saldo, comissão e as contratações vinculadas. '
          'Margens privadas do fornecedor não entram nesta visão.',
          style: GoogleFonts.poppins(fontSize: 12.5, color: AdminPalette.muted),
        ),
        const SizedBox(height: 12),
        if (linhas.isEmpty)
          AdminEmptyState(
            icon: Icons.event_busy_outlined,
            title: erro.isNotEmpty
                ? 'Consulta indisponível'
                : 'Nenhum evento neste recorte',
            message: erro.isNotEmpty
                ? 'A falha acima não significa ausência de registros.'
                : 'Ajuste o período ou limpe os filtros e consulte de novo.',
            actionLabel: 'Limpar filtros',
            onAction: () {
              _fornecedorCtrl.clear();
              _periodoInicioCtrl.clear();
              _periodoFimCtrl.clear();
              c.limparFiltros();
              c.carregar();
            },
          )
        else if (w >= 768)
          _tabelaEventos(linhas)
        else
          ...linhas.map(_cardEvento),
      ],
    );
  }

  Widget _celulaEvento(String id, {String? nome}) {
    final titulo = (nome != null && nome.trim().isNotEmpty)
        ? nome.trim()
        : _rotuloEventoCurto(id);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AdminPalette.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.celebration_outlined,
            size: 16,
            color: AdminPalette.primary,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                titulo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AdminPalette.ink,
                ),
              ),
              Text(
                nome != null && nome.trim().isNotEmpty
                    ? 'Evento'
                    : 'Referência do evento',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AdminPalette.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _abrirPainelDetalhe({
    required String titulo,
    required Widget detalhe,
    String? subtitulo,
    IconData icone = Icons.receipt_long_rounded,
  }) async {
    final wide = MediaQuery.sizeOf(context).width >= 768;
    Widget painel(VoidCallback fechar) {
      return ColoredBox(
        color: AdminPalette.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 10, 16),
              decoration: const BoxDecoration(
                gradient: AdminPalette.appBarGradient,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icone, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Colors.white,
                            height: 1.25,
                          ),
                        ),
                        if (subtitulo != null && subtitulo.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitulo,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: fechar,
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                child: detalhe,
              ),
            ),
          ],
        ),
      );
    }

    if (wide) {
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Fechar',
        barrierColor: Colors.black.withValues(alpha: 0.45),
        transitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (ctx, _, __) {
          return Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: AdminPalette.surface,
              elevation: 18,
              shadowColor: Colors.black38,
              shape: const RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.horizontal(left: Radius.circular(22)),
              ),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: MediaQuery.sizeOf(ctx).width.clamp(440.0, 560.0),
                height: double.infinity,
                child: SafeArea(
                  child: painel(() => Navigator.of(ctx).pop()),
                ),
              ),
            ),
          );
        },
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AdminPalette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SizedBox(
        height: MediaQuery.sizeOf(ctx).height * 0.9,
        child: painel(() => Navigator.of(ctx).pop()),
      ),
    );
  }

  /// Flexes compartilhados cabeçalho ↔ linha (não divergir).
  static const _flexEventos = [3, 2, 1, 2, 2, 2, 2];
  static const _alignEventos = [
    TextAlign.start,
    TextAlign.start,
    TextAlign.end,
    TextAlign.end,
    TextAlign.end,
    TextAlign.end,
    TextAlign.end,
  ];
  static const _flexContratacoes = [3, 2, 2, 2, 3];
  static const _alignContratacoes = [
    TextAlign.start,
    TextAlign.start,
    TextAlign.start,
    TextAlign.end,
    TextAlign.start,
  ];
  static const _larguraAcao = 88.0;

  Widget _tabelaEventos(List<Map<String, dynamic>> linhas) {
    return Container(
      decoration: adminCardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cabecalhoTabela(
            const [
              'Evento',
              'Situação',
              'Contratos',
              'Contratado',
              'Pago',
              'Saldo',
              'Comissão',
              '',
            ],
            flexes: _flexEventos,
            aligns: _alignEventos,
          ),
          ...linhas.asMap().entries.map((entry) {
            final i = entry.key;
            final l = entry.value;
            final id = (l['id_evento'] ?? l['idEvento'] ?? '').toString();
            final nome = (l['nome_evento'] ?? l['nomeEvento'])?.toString();
            final status = (l['status'] ?? '—').toString();
            final titulo = (nome != null && nome.trim().isNotEmpty)
                ? nome.trim()
                : _rotuloEventoCurto(id);
            final saldo =
                _n(l, const ['saldo_centavos', 'saldoCentavos']);
            return _linhaTabela(
              zebra: i.isOdd,
              onDetalhes: () => _abrirPainelDetalhe(
                titulo: titulo,
                subtitulo: 'Resumo financeiro do evento',
                icone: Icons.celebration_outlined,
                detalhe: _detalheEvento(l),
              ),
              resumo: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _celulaFlex(
                    flex: _flexEventos[0],
                    child: Tooltip(
                      message: 'Abrir resumo · toque longo copia o ID',
                      child: GestureDetector(
                        onLongPress: () async {
                          await Clipboard.setData(ClipboardData(text: id));
                          Get.snackbar(
                            'Evento',
                            'Referência completa copiada.',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                        child: _celulaEvento(id, nome: nome),
                      ),
                    ),
                  ),
                  _celulaFlex(
                    flex: _flexEventos[1],
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AdminStatusChip(
                        label: status,
                        color: _corStatusEvento(status),
                      ),
                    ),
                  ),
                  _celulaFlex(
                    flex: _flexEventos[2],
                    align: TextAlign.end,
                    child: Text(
                      '${l['qtd_contratos'] ?? l['qtdContratos'] ?? 0}',
                      textAlign: TextAlign.end,
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                  ),
                  _celulaFlex(
                    flex: _flexEventos[3],
                    align: TextAlign.end,
                    child: Text(
                      _reais(
                          l['contratado_centavos'] ?? l['contratadoCentavos']),
                      textAlign: TextAlign.end,
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                  ),
                  _celulaFlex(
                    flex: _flexEventos[4],
                    align: TextAlign.end,
                    child: Text(
                      _reais(l['pago_centavos'] ?? l['pagoCentavos']),
                      textAlign: TextAlign.end,
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                  ),
                  _celulaFlex(
                    flex: _flexEventos[5],
                    align: TextAlign.end,
                    child: Text(
                      _reais(l['saldo_centavos'] ?? l['saldoCentavos']),
                      textAlign: TextAlign.end,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: saldo > 0
                            ? AdminPalette.warning
                            : AdminPalette.ink,
                      ),
                    ),
                  ),
                  _celulaFlex(
                    flex: _flexEventos[6],
                    align: TextAlign.end,
                    child: Text(
                      _reais(l['comissao_centavos'] ?? l['comissaoCentavos']),
                      textAlign: TextAlign.end,
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                  ),
                  const SizedBox(
                    width: _larguraAcao,
                    child: _CelulaAbrirDetalhe(),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _cardEvento(Map<String, dynamic> l) {
    final id = (l['id_evento'] ?? l['idEvento'] ?? '').toString();
    final nome = (l['nome_evento'] ?? l['nomeEvento'])?.toString();
    final status = (l['status'] ?? '—').toString();
    final titulo = (nome != null && nome.trim().isNotEmpty)
        ? nome.trim()
        : _rotuloEventoCurto(id);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: adminCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _celulaEvento(id, nome: nome)),
              AdminStatusChip(
                label: status,
                color: _corStatusEvento(status),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Contratado ${_reais(l['contratado_centavos'] ?? l['contratadoCentavos'])}'
            ' · Saldo ${_reais(l['saldo_centavos'] ?? l['saldoCentavos'])}'
            ' · Comissão ${_reais(l['comissao_centavos'] ?? l['comissaoCentavos'])}',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AdminPalette.ink,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _abrirPainelDetalhe(
                titulo: titulo,
                subtitulo: 'Resumo financeiro do evento',
                icone: Icons.celebration_outlined,
                detalhe: _detalheEvento(l),
              ),
              icon: const Icon(Icons.chevron_right_rounded, size: 18),
              label: Text(
                'Abrir resumo',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: AdminPalette.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avisosCompletude() {
    return Column(
      children: [
        if (c.consultaTruncada)
          _bannerAviso(
            'Consulta limitada (paginação). “Sincronizado” não significa inventário total.',
          ),
        if (c.consultaTruncada && c.qtdIdentidadeIncompleta > 0)
          const SizedBox(height: 8),
        if (c.qtdIdentidadeIncompleta > 0)
          _bannerAviso(
            '${c.qtdIdentidadeIncompleta} contratação(ões) com identificação incompleta — '
            'revisão autorizada necessária; nomes não foram inventados.',
          ),
      ],
    );
  }

  Widget _secaoContratacoes(double w) {
    final linhas = c.linhasContratacao;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final compacto = constraints.maxWidth < 420;
            final titulo = Text(
              'Por contratação',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AdminPalette.ink,
              ),
            );
            final acao = TextButton.icon(
              onPressed: () => Get.toNamed('/admin/contratacoes-mediacao'),
              icon: const Icon(Icons.gavel_outlined, size: 18),
              label: Text(compacto ? 'Mediação' : 'Contratações e mediação'),
            );
            if (compacto) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [titulo, acao],
              );
            }
            return Row(
              children: [
                Expanded(child: titulo),
                Flexible(child: acao),
              ],
            );
          },
        ),
        const SizedBox(height: 4),
        Text(
          'Cada linha é um vínculo evento × fornecedor × serviço. '
          'Oportunidades ainda não contratadas não entram como serviço prestado.',
          style: GoogleFonts.poppins(fontSize: 12.5, color: AdminPalette.muted),
        ),
        const SizedBox(height: 12),
        if (linhas.isEmpty)
          AdminEmptyState(
            icon: Icons.handshake_outlined,
            title: 'Nenhuma contratação no recorte',
            message: 'Ajuste filtros ou aguarde novos aceites.',
          )
        else if (w >= 900)
          _tabelaContratacoes(linhas)
        else
          ...linhas.map(_cardContratacao),
      ],
    );
  }

  List<Widget> _chipsEstadoContratacao(LinhaContratacaoAdmin l) {
    final comercial = l.estadoComercial.trim();
    final jaOportunidade = comercial.toLowerCase().contains('oportun');
    return [
      AdminStatusChip(
        label: comercial.isEmpty ? '—' : comercial,
        color: _corStatusEvento(comercial),
      ),
      AdminStatusChip.neutral(l.estadoExecucao.rotulo),
      if (!l.contratado && !jaOportunidade)
        AdminStatusChip.warning(
          'Oportunidade',
          icon: Icons.info_outline_rounded,
        ),
      if (l.identidadeIncompleta)
        AdminStatusChip.warning(
          'ID pendente',
          icon: Icons.person_search_outlined,
        ),
    ];
  }

  Widget _tabelaContratacoes(List<LinhaContratacaoAdmin> linhas) {
    return Container(
      decoration: adminCardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cabecalhoTabela(
            const [
              'Evento',
              'Fornecedor',
              'Serviço',
              'Valor',
              'Situação',
              '',
            ],
            flexes: _flexContratacoes,
            aligns: _alignContratacoes,
          ),
          ...linhas.asMap().entries.map((entry) {
            final i = entry.key;
            final l = entry.value;
            final fornecedorPendente =
                l.rotuloFornecedor.toLowerCase().contains('pendente');
            return _linhaTabela(
              zebra: i.isOdd,
              onDetalhes: () => _abrirPainelDetalhe(
                titulo: l.rotuloServico,
                subtitulo: l.rotuloEvento,
                icone: Icons.handshake_outlined,
                detalhe: _detalheContratacao(l),
              ),
              resumo: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _celulaFlex(
                    flex: _flexContratacoes[0],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.rotuloEvento,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          l.rotuloContratante,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AdminPalette.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _celulaFlex(
                    flex: _flexContratacoes[1],
                    child: Text(
                      l.rotuloFornecedor,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: fornecedorPendente
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: fornecedorPendente
                            ? AdminPalette.warning
                            : AdminPalette.ink,
                      ),
                    ),
                  ),
                  _celulaFlex(
                    flex: _flexContratacoes[2],
                    child: Text(
                      l.rotuloServico,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                  ),
                  _celulaFlex(
                    flex: _flexContratacoes[3],
                    align: TextAlign.end,
                    child: Text(
                      l.contratado
                          ? _reais(l.valorContratadoCentavos)
                          : '—',
                      textAlign: TextAlign.end,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: l.contratado
                            ? AdminPalette.ink
                            : AdminPalette.muted,
                      ),
                    ),
                  ),
                  _celulaFlex(
                    flex: _flexContratacoes[4],
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: _chipsEstadoContratacao(l),
                    ),
                  ),
                  const SizedBox(
                    width: _larguraAcao,
                    child: _CelulaAbrirDetalhe(),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _celulaFlex({
    required int flex,
    required Widget child,
    TextAlign align = TextAlign.start,
  }) {
    return Expanded(
      flex: flex,
      child: align == TextAlign.end
          ? Align(alignment: Alignment.centerRight, child: child)
          : child,
    );
  }

  Widget _cabecalhoTabela(
    List<String> titulos, {
    required List<int> flexes,
    List<TextAlign>? aligns,
  }) {
    assert(
      flexes.length == titulos.length - 1,
      'flexes deve cobrir todas as colunas exceto a ação final',
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AdminPalette.primary.withValues(alpha: 0.04),
        border: Border(
          bottom: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < titulos.length; i++)
            if (i == titulos.length - 1)
              SizedBox(
                width: _larguraAcao,
                child: Text(
                  titulos[i],
                  textAlign: TextAlign.end,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: AdminPalette.muted,
                  ),
                ),
              )
            else
              Expanded(
                flex: flexes[i],
                child: Text(
                  titulos[i],
                  textAlign: aligns != null && i < aligns.length
                      ? aligns[i]
                      : TextAlign.start,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: AdminPalette.muted,
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _linhaTabela({
    required VoidCallback onDetalhes,
    required Widget resumo,
    bool zebra = false,
  }) {
    return Material(
      color: zebra
          ? AdminPalette.primary.withValues(alpha: 0.025)
          : Colors.transparent,
      child: InkWell(
        onTap: onDetalhes,
        hoverColor: AdminPalette.primary.withValues(alpha: 0.06),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
            ),
          ),
          child: resumo,
        ),
      ),
    );
  }

  Widget _cardContratacao(LinhaContratacaoAdmin l) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _abrirPainelDetalhe(
          titulo: l.rotuloServico,
          subtitulo: l.rotuloEvento,
          icone: Icons.handshake_outlined,
          detalhe: _detalheContratacao(l),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: adminCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.rotuloServico,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AdminPalette.ink,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AdminPalette.primary,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                l.rotuloEvento,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: AdminPalette.muted,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${l.rotuloFornecedor} · ${l.rotuloContratante}',
                style:
                    GoogleFonts.poppins(fontSize: 13, color: AdminPalette.ink),
              ),
              if (l.contratado) ...[
                const SizedBox(height: 4),
                Text(
                  _reais(l.valorContratadoCentavos),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AdminPalette.primary,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _chipsEstadoContratacao(l),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detalheContratacao(LinhaContratacaoAdmin l) {
    final oportunidade = !l.contratado;
    final corValor =
        oportunidade ? AdminPalette.warning : AdminPalette.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _painelSecao(
          titulo: 'Situação',
          icone: Icons.flag_outlined,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _chipsEstadoContratacao(l),
          ),
        ),
        const SizedBox(height: 12),
        _painelSecao(
          titulo: 'Valor',
          icone: Icons.payments_outlined,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: corValor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: corValor.withValues(alpha: 0.22)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  oportunidade ? 'Ainda sem contrato' : 'Contratado',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AdminPalette.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  oportunidade && l.valorContratadoCentavos <= 0
                      ? 'Sem valor'
                      : _reais(l.valorContratadoCentavos),
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: corValor,
                  ),
                ),
                if (oportunidade)
                  Text(
                    'Oportunidade — execução e cobrança ainda não iniciadas.',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: AdminPalette.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else if (l.pagoCentavos > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Pago ${_reais(l.pagoCentavos)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AdminPalette.success,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _painelSecao(
          titulo: 'Partes',
          icone: Icons.groups_outlined,
          child: Column(
            children: [
              if ((l.nomeOrganizador ?? '').trim().isNotEmpty &&
                  l.nomeOrganizador != l.rotuloContratante)
                _painelLinhaPessoa(
                  Icons.celebration_outlined,
                  'Organizador',
                  l.nomeOrganizador!,
                ),
              _painelLinhaPessoa(
                Icons.person_outline_rounded,
                'Contratante',
                l.rotuloContratante,
              ),
              if ((l.nomePagador ?? '').trim().isNotEmpty &&
                  l.nomePagador != l.rotuloContratante)
                _painelLinhaPessoa(
                  Icons.account_balance_wallet_outlined,
                  'Pagador',
                  l.nomePagador!,
                ),
              _painelLinhaPessoa(
                Icons.storefront_outlined,
                'Fornecedor',
                l.rotuloFornecedor,
                ultimo: true,
                destaque: l.rotuloFornecedor.toLowerCase().contains('pendente'),
              ),
            ],
          ),
        ),
        if (l.perfilAtualSeparado && l.nomeFornecedorAtual != null) ...[
          const SizedBox(height: 12),
          _painelAviso(
            'Perfil atual do fornecedor: ${l.nomeFornecedorAtual} '
            '(snapshot do aceite preservado).',
          ),
        ],
        const SizedBox(height: 12),
        _painelSecao(
          titulo: 'Serviço',
          icone: Icons.design_services_outlined,
          child: _painelLinhaPessoa(
            Icons.handyman_outlined,
            'Escopo',
            l.rotuloServico,
            ultimo: true,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              Get.back();
              Get.toNamed('/admin/contratacoes-mediacao');
            },
            style: FilledButton.styleFrom(
              backgroundColor: AdminPalette.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.gavel_outlined, size: 18),
            label: Text(
              'Abrir mediação e contratos',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _painelRodapeTecnico(l.idOrcamento),
      ],
    );
  }

  LinhaContratacaoAdmin? _encontrarLinhaContratacao(Map<String, dynamic> ct) {
    final idOrc =
        (ct['id_orcamento'] ?? ct['idOrcamento'] ?? '').toString().trim();
    final idCt =
        (ct['id_contrato'] ?? ct['idContrato'] ?? '').toString().trim();
    final serv =
        (ct['nome_servico'] ?? ct['nomeServico'] ?? '').toString().trim();
    for (final linha in c.linhasContratacao) {
      if (idOrc.isNotEmpty && linha.idOrcamento == idOrc) return linha;
      if (idCt.isNotEmpty && linha.idContrato == idCt) return linha;
    }
    if (serv.isNotEmpty) {
      final idEvt =
          (ct['id_evento'] ?? ct['idEvento'] ?? '').toString().trim();
      for (final linha in c.linhasContratacao) {
        final mesmoEvento = idEvt.isEmpty || linha.idEvento == idEvt;
        if (mesmoEvento &&
            linha.rotuloServico.toLowerCase() == serv.toLowerCase()) {
          return linha;
        }
      }
    }
    return null;
  }

  Future<void> _abrirContratacaoDeEvento(Map<String, dynamic> ct) async {
    final linha = _encontrarLinhaContratacao(ct);
    if (linha == null) {
      Get.snackbar(
        'Contratação',
        'Não foi possível abrir o detalhe desta linha no recorte atual.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    Get.back();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    await _abrirPainelDetalhe(
      titulo: linha.rotuloServico,
      subtitulo: linha.rotuloEvento,
      icone: Icons.handshake_outlined,
      detalhe: _detalheContratacao(linha),
    );
  }

  Widget _detalheEvento(Map<String, dynamic> l) {
    final id = (l['id_evento'] ?? l['idEvento'] ?? '').toString();
    final nomeOrg = (l['nome_organizador'] ?? l['nomeOrganizador'])?.toString();
    final incompleto = l['pagamento_incompleto'] == true ||
        l['pagamentoIncompleto'] == true;
    final status = (l['status'] ?? '—').toString();
    final contratado =
        _n(l, const ['contratado_centavos', 'contratadoCentavos']);
    final pago = _n(l, const ['pago_centavos', 'pagoCentavos']);
    final saldo = _n(l, const ['saldo_centavos', 'saldoCentavos']);
    final comissao = _n(l, const ['comissao_centavos', 'comissaoCentavos']);
    final pctPago =
        contratado > 0 ? (pago / contratado).clamp(0.0, 1.0) : 0.0;
    final rawContratos = l['contratacoes'] ?? l['contratos'];
    final contratos = rawContratos is List
        ? rawContratos
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (nomeOrg != null && nomeOrg.isNotEmpty) ...[
          _painelLinhaPessoa(
            Icons.person_outline_rounded,
            'Organizador',
            nomeOrg,
            ultimo: true,
          ),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AdminStatusChip(
              label: status,
              color: _corStatusEvento(status),
            ),
            AdminSummaryChip(
              label: 'Serviços',
              value: '${l['qtd_servicos'] ?? l['qtdServicos'] ?? 0}',
              color: AdminPalette.primary,
              icon: Icons.category_outlined,
            ),
            AdminSummaryChip(
              label: 'Contratos',
              value: '${l['qtd_contratos'] ?? l['qtdContratos'] ?? 0}',
              color: AdminPalette.primary,
              icon: Icons.description_outlined,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _painelSecao(
          titulo: 'Leitura rápida',
          icone: Icons.account_balance_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _kpiMini(
                      'Contratado',
                      _reais(contratado),
                      AdminPalette.ink,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _kpiMini(
                      'Pago',
                      _reais(pago),
                      AdminPalette.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _kpiMini(
                      'Saldo a receber',
                      _reais(saldo),
                      saldo > 0 ? AdminPalette.warning : AdminPalette.muted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _kpiMini(
                      'Comissão',
                      _reais(comissao),
                      AdminPalette.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                contratado > 0
                    ? 'Recebido ${(pctPago * 100).round()}% do valor contratado'
                    : 'Sem valor contratado neste evento',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AdminPalette.muted,
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: contratado > 0 ? pctPago : 0,
                  minHeight: 8,
                  backgroundColor: AdminPalette.border,
                  color: pctPago >= 1
                      ? AdminPalette.success
                      : AdminPalette.primary,
                ),
              ),
            ],
          ),
        ),
        if (contratos.isNotEmpty) ...[
          const SizedBox(height: 12),
          _painelSecao(
            titulo: 'Contratações deste evento',
            icone: Icons.handshake_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Toque em uma linha para abrir o detalhe da contratação.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AdminPalette.muted,
                  ),
                ),
                const SizedBox(height: 10),
                for (var i = 0; i < contratos.length; i++)
                  _painelCardContratacaoEvento(
                    contratos[i],
                    ultimo: i == contratos.length - 1,
                    idEvento: id,
                  ),
              ],
            ),
          ),
        ],
        if (incompleto) ...[
          const SizedBox(height: 12),
          _painelAviso('Pagamento incompleto neste evento.'),
        ],
        const SizedBox(height: 14),
        _painelRodapeTecnico(id),
        const SizedBox(height: 8),
        Text(
          'Sem acesso a margens ou custos privados do fornecedor.',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AdminPalette.muted,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _kpiMini(String label, String valor, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AdminPalette.muted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _painelSecao({
    required String titulo,
    required IconData icone,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminPalette.border),
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
          Row(
            children: [
              Icon(icone, size: 18, color: AdminPalette.primary),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: AdminPalette.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _painelLinhaPessoa(
    IconData icon,
    String label,
    String value, {
    bool ultimo = false,
    bool destaque = false,
  }) {
    final cor = destaque ? AdminPalette.warning : AdminPalette.primary;
    return Container(
      margin: EdgeInsets.only(bottom: ultimo ? 0 : 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: destaque
            ? AdminPalette.warning.withValues(alpha: 0.08)
            : AdminPalette.surface,
        borderRadius: BorderRadius.circular(12),
        border: destaque
            ? Border.all(color: AdminPalette.warning.withValues(alpha: 0.25))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: cor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AdminPalette.muted,
                  ),
                ),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: destaque ? AdminPalette.warning : AdminPalette.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _painelCardContratacaoEvento(
    Map<String, dynamic> ct, {
    required bool ultimo,
    String idEvento = '',
  }) {
    final forn =
        (ct['nome_fornecedor'] ?? ct['nomeFornecedor'] ?? '—').toString();
    final serv = (ct['nome_servico'] ?? ct['nomeServico'] ?? '—').toString();
    final est =
        (ct['estado_comercial'] ?? ct['estadoComercial'] ?? '—').toString();
    final execRaw =
        (ct['estado_execucao_rotulo'] ?? ct['estadoExecucaoRotulo'] ??
                ct['estado_execucao'] ??
                ct['estadoExecucao'] ??
                '—')
            .toString();
    final exec = execRaw.contains('_')
        ? EstadoExecucaoContrato.fromString(execRaw).rotulo
        : execRaw;
    final pend = ct['identidade_incompleta'] == true ||
        ct['identidadeIncompleta'] == true;
    final valor = _n(ct, const [
      'valor_contratado_centavos',
      'valorContratadoCentavos',
      'contratado_centavos',
      'contratadoCentavos',
    ]);
    final contratado = ct['contratado'] == true ||
        est.toLowerCase().contains('contrat');
    final payload = {
      ...ct,
      if (idEvento.isNotEmpty) 'id_evento': idEvento,
    };
    final temDrill = _encontrarLinhaContratacao(payload) != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: temDrill ? () => _abrirContratacaoDeEvento(payload) : null,
        child: Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: ultimo ? 0 : 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AdminPalette.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: temDrill
                  ? AdminPalette.primary.withValues(alpha: 0.22)
                  : AdminPalette.border,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      serv,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AdminPalette.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      forn,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: forn.toLowerCase().contains('pendente')
                            ? AdminPalette.warning
                            : AdminPalette.muted,
                        fontWeight: forn.toLowerCase().contains('pendente')
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                    if (contratado && valor > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        _reais(valor),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AdminPalette.primary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        AdminStatusChip(
                          label: est,
                          color: _corStatusEvento(est),
                        ),
                        if (!est.toLowerCase().contains(exec.toLowerCase()) &&
                            exec != '—')
                          AdminStatusChip.neutral(exec),
                        if (pend)
                          AdminStatusChip.warning(
                            'ID pendente',
                            icon: Icons.person_search_outlined,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (temDrill)
                const Padding(
                  padding: EdgeInsets.only(left: 6, top: 2),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: AdminPalette.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _painelAviso(String texto) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminPalette.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AdminPalette.warning.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 18, color: AdminPalette.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AdminPalette.warning,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _painelRodapeTecnico(String id) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminPalette.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.tag_rounded, size: 16, color: AdminPalette.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              id,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                color: AdminPalette.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: id));
              Get.snackbar(
                'Copiado',
                'Referência técnica copiada.',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: Text(
              'Copiar',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: AdminPalette.primary,
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
        color: AdminPalette.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminPalette.danger.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
}

class _CelulaAbrirDetalhe extends StatelessWidget {
  const _CelulaAbrirDetalhe();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'Abrir',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: AdminPalette.primary,
            fontSize: 12.5,
          ),
        ),
        const SizedBox(width: 2),
        const Icon(
          Icons.chevron_right_rounded,
          size: 18,
          color: AdminPalette.primary,
        ),
      ],
    );
  }
}
