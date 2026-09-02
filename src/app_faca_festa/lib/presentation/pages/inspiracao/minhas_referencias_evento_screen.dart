import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:app_faca_festa/presentation/modules/inspiracao/controllers/inspiracao_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
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
  State<MinhasReferenciasEventoScreen> createState() =>
      _MinhasReferenciasEventoScreenState();
}

class _MinhasReferenciasEventoScreenState
    extends State<MinhasReferenciasEventoScreen> {
  final InspiracaoController controller = Get.find<InspiracaoController>();

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
      backgroundColor: const Color(0xFFF8FAFC),
      body: Obx(() {
        final referencias = _referenciasFiltradas();

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight:
                  160, // 🔹 Altura reduzida para ficar mais compacto
              collapsedHeight: kToolbarHeight,
              pinned: true,
              elevation: 0,
              backgroundColor: primary,
              foregroundColor: Colors.white,
              title: Text(
                'Minhas Referências',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700, fontSize: 16),
              ),
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Container(
                  decoration: BoxDecoration(gradient: gradient),
                  child: SafeArea(
                    bottom: false,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final availableHeight = constraints.maxHeight;
                        if (availableHeight <= 100) {
                          return const SizedBox.shrink();
                        }

                        return ClipRect(
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Painel de decisões do evento',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 20, // 🔹 Fonte refinada
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Gerencie ideias salvas, status, prioridades, checklist e orçamento.',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      color:
                                          Colors.white.withValues(alpha: 0.88),
                                      height: 1.3,
                                    ),
                                  ),
                                ],
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
                child: Center(child: CircularProgressIndicator()),
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
                  return _referenciaCard(referencias[index], primary);
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
    final refs = controller.referenciasEvento
        .where((ref) => ref.ativo && !ref.deletado)
        .toList();
    if (status == 'todos') return refs;
    return refs.where((ref) => ref.status == status).toList();
  }

  // =========================================================================
  // 🔹 CARDS DE RESUMO (Otimizados para caberem bem na tela)
  // =========================================================================
  Widget _resumoCards(Color primary) {
    return Obx(() {
      final refsAtivas = controller.referenciasEvento
          .where((r) => r.ativo && !r.deletado)
          .toList();
      final total = refsAtivas.length;
      final favoritas = refsAtivas.where((r) => r.favorito).length;
      final aprovadas = refsAtivas.where((r) => r.status == 'aprovada').length;
      final orcar = refsAtivas.where((r) => r.status == 'orcar').length;

      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
        child: Row(
          children: [
            Expanded(
                child: _miniResumo('Ref.', total.toString(),
                    Icons.collections_bookmark_rounded, primary)),
            const SizedBox(width: 8),
            Expanded(
                child: _miniResumo('Fav.', favoritas.toString(),
                    Icons.star_rounded, Colors.amber.shade700)),
            const SizedBox(width: 8),
            Expanded(
                child: _miniResumo('Aprov.', aprovadas.toString(),
                    Icons.verified_rounded, Colors.green.shade700)),
            const SizedBox(width: 8),
            Expanded(
                child: _miniResumo('Orçar', orcar.toString(),
                    Icons.request_quote_rounded, Colors.orange.shade700)),
          ],
        ),
      );
    });
  }

  Widget _miniResumo(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E293B)),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
                fontSize: 9.5,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 🔹 FILTROS DE STATUS COMPACTOS
  // =========================================================================
  Widget _filtrosStatus(Color primary) {
    return Obx(() {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: statusOptions.map((status) {
            final selected = filtroStatus.value == status;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                filtroStatus.value = status;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? primary : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: selected ? primary : Colors.grey.shade300),
                ),
                child: Text(
                  _labelStatus(status),
                  style: GoogleFonts.poppins(
                    color: selected ? Colors.white : Colors.grey.shade700,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  // =========================================================================
  // 🔹 CARD DA REFERÊNCIA (Design Original Compactado)
  // =========================================================================
  Widget _referenciaCard(ReferenciaEventoModel ref, Color primary) {
    final totalTarefas = controller.totalTarefasPorInspiracao(ref.inspiracaoId);
    final concluidas =
        controller.tarefasConcluidasPorInspiracao(ref.inspiracaoId);
    final totalOrcamentos =
        controller.totalOrcamentosPorInspiracao(ref.inspiracaoId);
    final valorOrcado = controller.valorOrcadoPorInspiracao(ref.inspiracaoId);

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 📸 Imagem Destaque (Altura reduzida)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Stack(
              children: [
                _imagemReferencia(ref.imagemUrl),
                Positioned(
                  top: 10,
                  left: 10,
                  child: _chip(ref.categoria, primary, light: true),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        controller.atualizarReferenciaPlanejamento(
                            referenciaId: ref.id, favorito: !ref.favorito);
                      },
                      child: Icon(
                          ref.favorito
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: ref.favorito ? Colors.amber : Colors.white,
                          size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 📝 Conteúdo Textual
          Padding(
            padding: const EdgeInsets.all(12), // 🔹 Menos padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        ref.titulo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF172033)),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Editar',
                      icon: Icon(Icons.tune_rounded, color: primary, size: 20),
                      onPressed: () => _abrirEditorReferencia(ref, primary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // 🔹 Badges
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _chip(_labelStatus(ref.status), _corStatus(ref.status)),
                    _chip('Prioridade: ${_labelPrioridade(ref.prioridade)}',
                        _corPrioridade(ref.prioridade)),
                  ],
                ),

                // 🔹 Anotações
                if (ref.anotacao.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200)),
                    child: Text(
                      ref.anotacao,
                      style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: Colors.grey.shade700,
                          height: 1.4),
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // 🔹 Orçamento e Checklist
                Row(
                  children: [
                    Expanded(
                        child: _infoBox(
                            icon: Icons.checklist_rounded,
                            label: 'Checklist',
                            value: totalTarefas == 0
                                ? 'Nenhum'
                                : '$concluidas/$totalTarefas',
                            color: Colors.green.shade700)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _infoBox(
                            icon: Icons.account_balance_wallet_rounded,
                            label: 'Orçamento',
                            value: totalOrcamentos == 0
                                ? 'Nenhum'
                                : _formatCurrency(valorOrcado),
                            color: Colors.orange.shade800)),
                  ],
                ),
                const SizedBox(height: 12),

                // 🔹 Botões Ação
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _gerarBriefing(ref),
                        icon: const Icon(Icons.description_outlined, size: 16),
                        label: const Text('Briefing',
                            style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primary,
                          side: BorderSide(
                              color: primary.withValues(alpha: 0.35)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      onPressed: () => _confirmarRemocao(ref, primary),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      color: Colors.red.shade700,
                      constraints:
                          const BoxConstraints(minHeight: 40, minWidth: 40),
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

  Widget _imagemReferencia(String? url) {
    if (url == null || url.trim().isEmpty) {
      return Container(
        height: 140, // 🔹 Mais fina
        width: double.infinity,
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: Icon(Icons.image_not_supported_rounded,
            color: Colors.grey.shade400, size: 36),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      height: 140, // 🔹 Mais fina
      width: double.infinity,
      fit: BoxFit.cover,
      errorWidget: (_, __, ___) => Container(
        height: 140,
        width: double.infinity,
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: Icon(Icons.broken_image_rounded,
            color: Colors.grey.shade400, size: 36),
      ),
    );
  }

  Widget _chip(String label, Color color, {bool light = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: light
            ? Colors.white.withValues(alpha: 0.95)
            : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
            fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _infoBox(
      {required IconData icon,
      required String label,
      required String value,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 9, color: Colors.grey.shade600)),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF172033))),
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
            width: 70,
            height: 70,
            decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.08), shape: BoxShape.circle),
            child: Icon(Icons.collections_bookmark_outlined,
                color: primary, size: 36),
          ),
          const SizedBox(height: 14),
          Text(
            'Nenhuma referência',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF172033)),
          ),
          const SizedBox(height: 6),
          Text(
            'Salve ideias na tela de inspirações para montar seu painel.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                fontSize: 11.5, color: Colors.grey.shade600, height: 1.4),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 🔹 BOTOM SHEETS E DIALOGS
  // =========================================================================
  void _abrirEditorReferencia(ReferenciaEventoModel ref, Color primary) {
    final statusSelecionado = ref.status.obs;
    final prioridadeSelecionada = ref.prioridade.obs;
    String anotacaoAtual = ref.anotacao;

    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding:
              const EdgeInsets.fromLTRB(16, 12, 16, 16), // 🔹 Mais compacto
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                Text('Editar referência',
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF172033))),
                Text(ref.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 16),
                Text('Status',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(height: 6),
                Obx(() => Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: statusOptions
                          .where((s) => s != 'todos')
                          .map((status) {
                        final selected = statusSelecionado.value == status;
                        return ChoiceChip(
                          selected: selected,
                          label: Text(_labelStatus(status)),
                          onSelected: (_) => statusSelecionado.value = status,
                          selectedColor: primary.withValues(alpha: 0.15),
                          labelStyle: GoogleFonts.poppins(
                              color: selected ? primary : Colors.grey.shade800,
                              fontWeight: FontWeight.w700,
                              fontSize: 11),
                        );
                      }).toList(),
                    )),
                const SizedBox(height: 16),
                Text('Prioridade',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(height: 6),
                Obx(() => Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: prioridadeOptions.map((prioridade) {
                        final selected =
                            prioridadeSelecionada.value == prioridade;
                        return ChoiceChip(
                          selected: selected,
                          label: Text(_labelPrioridade(prioridade)),
                          onSelected: (_) =>
                              prioridadeSelecionada.value = prioridade,
                          selectedColor: primary.withValues(alpha: 0.15),
                          labelStyle: GoogleFonts.poppins(
                              color: selected ? primary : Colors.grey.shade800,
                              fontWeight: FontWeight.w700,
                              fontSize: 11),
                        );
                      }).toList(),
                    )),
                const SizedBox(height: 16),
                Text('Anotação',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(height: 6),
                TextFormField(
                  initialValue: anotacaoAtual,
                  minLines: 2,
                  maxLines: 4,
                  onChanged: (value) => anotacaoAtual = value,
                  style: GoogleFonts.poppins(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Suas observações...',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      FocusScope.of(context).unfocus();
                      await controller.atualizarReferenciaPlanejamento(
                          referenciaId: ref.id,
                          status: statusSelecionado.value,
                          prioridade: prioridadeSelecionada.value,
                          anotacao: anotacaoAtual.trim());
                      if (Get.isBottomSheetOpen == true) Get.back();
                    },
                    icon: const Icon(Icons.save_rounded,
                        color: Colors.white, size: 16),
                    label: Text('Salvar alterações',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
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

  Future<void> _confirmarRemocao(
      ReferenciaEventoModel ref, Color primary) async {
    var removerPlanejamento = false;
    final totalTarefas = controller.totalTarefasPorInspiracao(ref.inspiracaoId);
    final totalOrcamentos =
        controller.totalOrcamentosPorInspiracao(ref.inspiracaoId);
    final possuiVinculo = totalTarefas > 0 || totalOrcamentos > 0;

    await Get.dialog<void>(
      StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            contentPadding: const EdgeInsets.all(20),
            title: Text('Remover?',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800, fontSize: 16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('A referência será ocultada da lista.',
                    style: GoogleFonts.poppins(fontSize: 12.5, height: 1.3)),
                if (possuiVinculo) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade100)),
                    child: Text(
                        'Existem $totalTarefas tarefa(s) e $totalOrcamentos orçamento(s) vinculados. Por padrão, não serão apagados.',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.orange.shade900)),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: removerPlanejamento,
                    activeColor: Colors.red.shade600,
                    title: Text('Descartar vinculados',
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    onChanged: (value) => setStateDialog(
                        () => removerPlanejamento = value ?? false),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                  onPressed: Get.back,
                  child: Text('Cancelar',
                      style: GoogleFonts.poppins(fontSize: 13))),
              ElevatedButton(
                onPressed: () async {
                  Get.back();
                  await controller.removerReferenciaDoEvento(ref.id,
                      removerPlanejamentoVinculado: removerPlanejamento,
                      motivo: 'removida_organizador');
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                child: Text('Remover',
                    style:
                        GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
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
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          // 1. Usamos o IntrinsicHeight para garantir que a coluna não ocupe a tela toda se o conteúdo for pequeno
          child: IntrinsicHeight(
            child: Column(
              mainAxisSize: MainAxisSize.min, // Mantém o tamanho mínimo
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10)))),
                Row(
                  children: [
                    Icon(Icons.description_outlined, color: primary, size: 24),
                    const SizedBox(width: 8),
                    Text('Briefing Automático',
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF172033))),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Texto pronto para enviar a fornecedores.',
                    style: GoogleFonts.poppins(
                        fontSize: 11.5, color: Colors.grey.shade600)),
                const SizedBox(height: 16),

                // 2. Aqui está a chave: Expanded faz o container ocupar o espaço restante
                // de forma flexível, evitando o overflow
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200)),
                    child: SingleChildScrollView(
                      child: SelectableText(texto,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              height: 1.4,
                              color: const Color(0xFF334155))),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: texto));
                      EasyLoading.showSuccess('Copiado!');
                    },
                    icon: const Icon(Icons.copy_rounded,
                        color: Colors.white, size: 16),
                    label: Text('Copiar Texto',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 🔹 STRINGS E HELPERS
  // =========================================================================
  String _montarTextoBriefing(ReferenciaEventoModel ref) {
    final texto = StringBuffer()
      ..writeln('REFERÊNCIA PARA ORÇAMENTO')
      ..writeln('Tema: ${ref.titulo.isEmpty ? 'Sem título' : ref.titulo}')
      ..writeln(
          'Categoria: ${ref.categoria.isEmpty ? 'Não informada' : ref.categoria}')
      ..writeln(
          '\nDetalhes da imagem:\n${ref.descricao.trim().isEmpty ? '-' : ref.descricao.trim()}')
      ..writeln(
          '\nMinhas observações:\n${ref.anotacao.trim().isEmpty ? '-' : ref.anotacao.trim()}');
    if (ref.paletaCores.isNotEmpty) {
      texto.writeln('\nCores: ${ref.paletaCores.join(', ')}');
    }
    texto.writeln(
        '\nLink Imagem: ${ref.imagemUrl.trim().isEmpty ? '-' : ref.imagemUrl.trim()}');
    return texto.toString();
  }

  String _labelStatus(String status) =>
      {
        'todos': 'Todos',
        'salva': 'Salva',
        'em_analise': 'Análise',
        'orcar': 'Orçar',
        'aprovada': 'Aprovada',
        'contratada': 'Contratada',
        'executada': 'Executada',
        'descartada': 'Descartada'
      }[status] ??
      status;
  String _labelPrioridade(String p) =>
      {
        'baixa': 'Baixa',
        'media': 'Média',
        'alta': 'Alta',
        'essencial': 'Essencial'
      }[p] ??
      p;
  Color _corStatus(String status) =>
      {
        'salva': Colors.blueGrey,
        'em_analise': Colors.indigo,
        'orcar': Colors.orange.shade800,
        'aprovada': Colors.green.shade700,
        'contratada': Colors.teal.shade700,
        'executada': Colors.purple.shade700,
        'descartada': Colors.red.shade700
      }[status] ??
      Colors.blueGrey;
  Color _corPrioridade(String p) =>
      {
        'baixa': Colors.blueGrey,
        'media': Colors.blue.shade700,
        'alta': Colors.orange.shade800,
        'essencial': Colors.red.shade700
      }[p] ??
      Colors.blueGrey;
  String _formatCurrency(double v) =>
      'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';
}
