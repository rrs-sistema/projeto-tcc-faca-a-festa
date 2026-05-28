import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import './../../../controllers/inspiracao_controller.dart';
import './../../../controllers/tema/event_theme_controller.dart';
import './../../../data/models/evento/inspiracao_model.dart';

class MinhasReferenciasEventoScreen extends StatefulWidget {
  final String eventoId;
  final String userId;

  const MinhasReferenciasEventoScreen({
    super.key,
    required this.eventoId,
    required this.userId,
  });

  @override
  State<MinhasReferenciasEventoScreen> createState() => _MinhasReferenciasEventoScreenState();
}

class _MinhasReferenciasEventoScreenState extends State<MinhasReferenciasEventoScreen> {
  final InspiracaoController controller = Get.isRegistered<InspiracaoController>()
      ? Get.find<InspiracaoController>()
      : Get.put(InspiracaoController());

  final EventThemeController themeController = Get.find<EventThemeController>();
  final RxString filtroStatus = 'todos'.obs;

  static const List<String> statusOptions = [
    'todos',
    'salva',
    'em_analise',
    'orcar',
    'aprovada',
    'contratada',
    'executada',
    'descartada',
  ];

  static const List<String> prioridadeOptions = [
    'baixa',
    'media',
    'alta',
    'essencial',
  ];

  @override
  void initState() {
    super.initState();
    controller.configurarContextoEvento(
      eventoId: widget.eventoId,
      userId: widget.userId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = themeController.primaryColor.value;
    final gradient = themeController.gradient.value;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Obx(() {
        final referencias = _referenciasFiltradas();

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              collapsedHeight: kToolbarHeight,
              pinned: true,
              elevation: 0,
              backgroundColor: primary,
              foregroundColor: Colors.white,
              title: Text(
                'Minhas Referências',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: gradient,
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final availableHeight = constraints.maxHeight;

                        if (availableHeight <= 120) {
                          return const SizedBox.shrink();
                        }

                        return ClipRect(
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width - 40,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.bottomLeft,
                                  child: SizedBox(
                                    width: MediaQuery.of(context).size.width - 40,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Painel de decisões do evento',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.playfairDisplay(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Gerencie as ideias salvas, status, prioridades, checklist e orçamento ligados às suas inspirações.',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: Colors.white.withValues(
                                              alpha: 0.88,
                                            ),
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _resumoCards(primary),
            ),
            SliverToBoxAdapter(
              child: _filtrosStatus(primary),
            ),
            if (controller.loadingReferencias.value)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (referencias.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _emptyState(primary),
              )
            else
              SliverList.builder(
                itemCount: referencias.length,
                itemBuilder: (context, index) {
                  return _referenciaCard(
                    referencias[index],
                    primary,
                  );
                },
              ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 32),
            ),
          ],
        );
      }),
    );
  }

  List<ReferenciaEventoModel> _referenciasFiltradas() {
    final status = filtroStatus.value;

    final refs = controller.referenciasEvento.where((ref) {
      return ref.ativo && !ref.deletado;
    }).toList();

    if (status == 'todos') return refs;

    return refs.where((ref) => ref.status == status).toList();
  }

  Widget _resumoCards(Color primary) {
    return Obx(() {
      final refsAtivas = controller.referenciasEvento.where((r) => r.ativo && !r.deletado).toList();
      final total = refsAtivas.length;
      final favoritas = refsAtivas.where((r) => r.favorito).length;
      final aprovadas = refsAtivas.where((r) => r.status == 'aprovada').length;
      final orcar = refsAtivas.where((r) => r.status == 'orcar').length;

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            Expanded(
                child: _miniResumo(
                    'Referências', total.toString(), Icons.collections_bookmark_rounded, primary)),
            const SizedBox(width: 10),
            Expanded(
                child: _miniResumo(
                    'Favoritas', favoritas.toString(), Icons.star_rounded, Colors.amber.shade700)),
            const SizedBox(width: 10),
            Expanded(
                child: _miniResumo('Aprovadas', aprovadas.toString(), Icons.verified_rounded,
                    Colors.green.shade700)),
            const SizedBox(width: 10),
            Expanded(
                child: _miniResumo('A orçar', orcar.toString(), Icons.request_quote_rounded,
                    Colors.orange.shade700)),
          ],
        ),
      );
    });
  }

  Widget _miniResumo(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E293B),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _filtrosStatus(Color primary) {
    return Obx(() {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: statusOptions.map((status) {
            final selected = filtroStatus.value == status;

            return GestureDetector(
              onTap: () => filtroStatus.value = status,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? primary : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected ? primary : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  _labelStatus(status),
                  style: GoogleFonts.poppins(
                    color: selected ? Colors.white : Colors.grey.shade800,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  Widget _referenciaCard(ReferenciaEventoModel ref, Color primary) {
    final totalTarefas = controller.totalTarefasPorInspiracao(ref.inspiracaoId);
    final concluidas = controller.tarefasConcluidasPorInspiracao(ref.inspiracaoId);
    final totalOrcamentos = controller.totalOrcamentosPorInspiracao(ref.inspiracaoId);
    final valorOrcado = controller.valorOrcadoPorInspiracao(ref.inspiracaoId);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: Stack(
              children: [
                _imagemReferencia(ref.imagemUrl),
                Positioned(
                  top: 12,
                  left: 12,
                  child: _chip(ref.categoria, primary, light: true),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        ref.favorito ? Icons.star_rounded : Icons.star_border_rounded,
                        color: ref.favorito ? Colors.amber : Colors.white,
                      ),
                      onPressed: () {
                        controller.atualizarReferenciaPlanejamento(
                          referenciaId: ref.id,
                          favorito: !ref.favorito,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ref.titulo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF172033),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Editar referência',
                      icon: Icon(Icons.tune_rounded, color: primary),
                      onPressed: () => _abrirEditorReferencia(ref, primary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(_labelStatus(ref.status), _corStatus(ref.status)),
                    _chip('Prioridade: ${_labelPrioridade(ref.prioridade)}',
                        _corPrioridade(ref.prioridade)),
                    if (ref.anotacao.trim().isNotEmpty) _chip('Com anotação', Colors.indigo),
                  ],
                ),
                if (ref.anotacao.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      ref.anotacao,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _infoBox(
                        icon: Icons.checklist_rounded,
                        label: 'Checklist',
                        value: totalTarefas == 0 ? 'Nenhum' : '$concluidas/$totalTarefas tarefas',
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _infoBox(
                        icon: Icons.account_balance_wallet_rounded,
                        label: 'Orçamento',
                        value: totalOrcamentos == 0 ? 'Nenhum' : _formatCurrency(valorOrcado),
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _gerarBriefing(ref),
                        icon: const Icon(Icons.description_outlined, size: 18),
                        label: const Text('Briefing'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primary,
                          side: BorderSide(color: primary.withValues(alpha: 0.35)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      onPressed: () => _confirmarRemocao(ref, primary),
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: Colors.red.shade700,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagemReferencia(String url) {
    if (url.trim().isEmpty) {
      return Container(
        height: 185,
        width: double.infinity,
        color: Colors.grey.shade100,
        alignment: Alignment.center,
        child: Icon(Icons.image_not_supported_rounded, color: Colors.grey.shade400, size: 46),
      );
    }

    return Image.network(
      url,
      height: 185,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: 185,
        width: double.infinity,
        color: Colors.grey.shade100,
        alignment: Alignment.center,
        child: Icon(Icons.broken_image_rounded, color: Colors.grey.shade400, size: 46),
      ),
    );
  }

  Widget _chip(String label, Color color, {bool light = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: light ? Colors.white.withValues(alpha: 0.92) : color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _infoBox({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600)),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF172033),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(Color primary) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.collections_bookmark_outlined, color: primary, size: 42),
          ),
          const SizedBox(height: 18),
          Text(
            'Nenhuma referência encontrada',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF172033),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Salve ideias na tela Ideias e Inspirações para montar o painel visual do evento.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _abrirEditorReferencia(ReferenciaEventoModel ref, Color primary) {
    final statusSelecionado = ref.status.obs;
    final prioridadeSelecionada = ref.prioridade.obs;
    String anotacaoAtual = ref.anotacao;

    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Editar referência',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF172033),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  ref.titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Status',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Obx(
                  () => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: statusOptions.where((s) => s != 'todos').map((status) {
                      final selected = statusSelecionado.value == status;

                      return ChoiceChip(
                        selected: selected,
                        label: Text(_labelStatus(status)),
                        onSelected: (_) => statusSelecionado.value = status,
                        selectedColor: primary.withValues(alpha: 0.18),
                        labelStyle: GoogleFonts.poppins(
                          color: selected ? primary : Colors.grey.shade800,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Prioridade',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Obx(
                  () => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: prioridadeOptions.map((prioridade) {
                      final selected = prioridadeSelecionada.value == prioridade;

                      return ChoiceChip(
                        selected: selected,
                        label: Text(_labelPrioridade(prioridade)),
                        onSelected: (_) => prioridadeSelecionada.value = prioridade,
                        selectedColor: primary.withValues(alpha: 0.18),
                        labelStyle: GoogleFonts.poppins(
                          color: selected ? primary : Colors.grey.shade800,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Anotação do organizador',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: anotacaoAtual,
                  minLines: 3,
                  maxLines: 5,
                  onChanged: (value) => anotacaoAtual = value,
                  decoration: InputDecoration(
                    hintText: 'Ex.: gostei dessa ideia, mas quero trocar as cores...',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      FocusScope.of(Get.context!).unfocus();

                      await controller.atualizarReferenciaPlanejamento(
                        referenciaId: ref.id,
                        status: statusSelecionado.value,
                        prioridade: prioridadeSelecionada.value,
                        anotacao: anotacaoAtual.trim(),
                      );

                      if (Get.isBottomSheetOpen == true) {
                        Get.back();
                      }
                    },
                    icon: const Icon(
                      Icons.save_rounded,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Salvar alterações',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _confirmarRemocao(ReferenciaEventoModel ref, Color primary) async {
    var removerPlanejamento = false;

    final totalTarefas = controller.totalTarefasPorInspiracao(ref.inspiracaoId);
    final totalOrcamentos = controller.totalOrcamentosPorInspiracao(ref.inspiracaoId);
    final possuiPlanejamentoVinculado = totalTarefas > 0 || totalOrcamentos > 0;

    await Get.dialog<void>(
      StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: Text(
              'Remover referência?',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Essa referência será marcada como descartada e não aparecerá mais na lista principal.',
                  style: GoogleFonts.poppins(fontSize: 13.5, height: 1.35),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.shade100),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.orange.shade800, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          possuiPlanejamentoVinculado
                              ? 'Existem $totalTarefas tarefa(s) e $totalOrcamentos item(ns) de orçamento ligados a essa referência. Por padrão, eles serão mantidos.'
                              : 'Nenhuma tarefa ou orçamento vinculado será removido.',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            height: 1.35,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (possuiPlanejamentoVinculado) ...[
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: removerPlanejamento,
                    activeColor: Colors.red.shade600,
                    title: Text(
                      'Também descartar checklist e orçamento vinculados',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      'Use somente se essa ideia realmente não será mais usada no evento.',
                      style: GoogleFonts.poppins(fontSize: 11.5),
                    ),
                    onChanged: (value) {
                      setStateDialog(() {
                        removerPlanejamento = value ?? false;
                      });
                    },
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: Get.back,
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Get.back();

                  await controller.removerReferenciaDoEvento(
                    ref.id,
                    removerPlanejamentoVinculado: removerPlanejamento,
                    motivo: 'removida_pelo_organizador',
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
                child: const Text(
                  'Remover',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _gerarBriefing(ReferenciaEventoModel ref) async {
    final primary = themeController.primaryColor.value;
    final texto = _montarTextoBriefing(ref);

    await Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: const BoxDecoration(
            color: Color(0xFFF7F8FA),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.description_outlined,
                        color: primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Briefing para fornecedor',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF172033),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Use este resumo para explicar melhor ao fornecedor o que você deseja para o evento.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(
                    maxHeight: 360,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.grey.shade200,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      texto,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        height: 1.45,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.close_rounded),
                        label: Text(
                          'Fechar',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: texto),
                          );

                          EasyLoading.showSuccess(
                            'Briefing copiado',
                          );
                        },
                        icon: const Icon(
                          Icons.copy_rounded,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Copiar',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  String _montarTextoBriefing(ReferenciaEventoModel ref) {
    final texto = StringBuffer()
      ..writeln('BRIEFING DE REFERÊNCIA PARA FORNECEDOR')
      ..writeln('')
      ..writeln('Referência: ${ref.titulo.isEmpty ? 'Sem título' : ref.titulo}')
      ..writeln('Categoria: ${ref.categoria.isEmpty ? 'Não informada' : ref.categoria}')
      ..writeln('Status: ${_labelStatus(ref.status)}')
      ..writeln('Prioridade: ${_labelPrioridade(ref.prioridade)}')
      ..writeln('')
      ..writeln('Descrição:')
      ..writeln(
        ref.descricao.trim().isEmpty ? 'Sem descrição cadastrada.' : ref.descricao.trim(),
      )
      ..writeln('')
      ..writeln('Observação do organizador:')
      ..writeln(
        ref.anotacao.trim().isEmpty ? 'Sem observações.' : ref.anotacao.trim(),
      );

    if (ref.paletaCores.isNotEmpty) {
      texto
        ..writeln('')
        ..writeln('Paleta de cores:')
        ..writeln(ref.paletaCores.join(', '));
    }

    if (ref.tags.isNotEmpty) {
      texto
        ..writeln('')
        ..writeln('Tags/estilo:')
        ..writeln(ref.tags.join(', '));
    }

    texto
      ..writeln('')
      ..writeln('Imagem de referência:')
      ..writeln(
        ref.imagemUrl.trim().isEmpty ? 'Sem imagem informada.' : ref.imagemUrl.trim(),
      );

    return texto.toString();
  }

  String _labelStatus(String status) {
    switch (status) {
      case 'todos':
        return 'Todos';
      case 'salva':
        return 'Salva';
      case 'em_analise':
        return 'Em análise';
      case 'orcar':
        return 'Orçar';
      case 'aprovada':
        return 'Aprovada';
      case 'contratada':
        return 'Contratada';
      case 'executada':
        return 'Executada';
      case 'descartada':
        return 'Descartada';
      default:
        return status;
    }
  }

  String _labelPrioridade(String prioridade) {
    switch (prioridade) {
      case 'baixa':
        return 'Baixa';
      case 'media':
        return 'Média';
      case 'alta':
        return 'Alta';
      case 'essencial':
        return 'Essencial';
      default:
        return prioridade;
    }
  }

  Color _corStatus(String status) {
    switch (status) {
      case 'salva':
        return Colors.blueGrey;
      case 'em_analise':
        return Colors.indigo;
      case 'orcar':
        return Colors.orange.shade800;
      case 'aprovada':
        return Colors.green.shade700;
      case 'contratada':
        return Colors.teal.shade700;
      case 'executada':
        return Colors.purple.shade700;
      case 'descartada':
        return Colors.red.shade700;
      default:
        return Colors.blueGrey;
    }
  }

  Color _corPrioridade(String prioridade) {
    switch (prioridade) {
      case 'baixa':
        return Colors.blueGrey;
      case 'media':
        return Colors.blue.shade700;
      case 'alta':
        return Colors.orange.shade800;
      case 'essencial':
        return Colors.red.shade700;
      default:
        return Colors.blueGrey;
    }
  }

  String _formatCurrency(double value) {
    final inteiro = value.toStringAsFixed(2).replaceAll('.', ',');
    return 'R\$ $inteiro';
  }
}
