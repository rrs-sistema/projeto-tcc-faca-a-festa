import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/presentation/modules/catalogo/categoria_icones.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/categoria_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/subcategoria_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/admin_theme.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/domain/entities/categoria_servico.dart';
import 'package:app_faca_festa/presentation/widgets/admin/admin_kit.dart';
import './show_subcategoria_servico_bottom_sheet.dart';

class SubcategoriaServicoListScreen extends StatefulWidget {
  final CategoriaServico categoria;
  final CategoriaServicoController categoriaController;
  final SubcategoriaServicoController subcategoriaController;
  final EventThemeController themeController;

  const SubcategoriaServicoListScreen({
    super.key,
    required this.categoria,
    required this.categoriaController,
    required this.subcategoriaController,
    required this.themeController,
  });

  @override
  State<SubcategoriaServicoListScreen> createState() =>
      _SubcategoriaServicoListScreenState();
}

class _SubcategoriaServicoListScreenState
    extends State<SubcategoriaServicoListScreen> {
  late final SubcategoriaServicoController controller;

  @override
  void initState() {
    super.initState();
    controller = widget.subcategoriaController;
    controller.busca.value = '';
    controller.subcategoriasFiltradas.clear();
    controller.carregarSubcategorias(widget.categoria.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.themeController;

    return Theme(
      data: theme.adminThemeData,
      child: Scaffold(
        backgroundColor: AdminPalette.surface,
        appBar: AdminBackAppBar(
          title: 'Subcategorias',
          subtitle: widget.categoria.nome,
          actions: [
            IconButton(
              tooltip: 'Atualizar',
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: () =>
                  controller.carregarSubcategorias(widget.categoria.id),
            ),
          ],
        ),
        floatingActionButton: AdminCreateFab(
          label: 'Nova subcategoria',
          onPressed: () => showSubcategoriaServicoBottomSheet(
            context,
            subcategoria: null,
            categoriaSelecionada: widget.categoria,
            categoriaController: widget.categoriaController,
            subcategoriaController: controller,
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Column(
                children: [
                  AdminSearchField(
                    hint: 'Buscar subcategoria',
                    onChanged: (v) => controller.busca.value = v,
                  ),
                  const SizedBox(height: 8),
                  Obx(() {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          AdminSummaryChip(
                            label: 'Nesta categoria',
                            value:
                                '${controller.subcategoriasFiltradas.length}',
                            color: AdminPalette.primary,
                            icon: Icons.account_tree_outlined,
                          ),
                          const SizedBox(width: 6),
                          AdminSummaryChip(
                            label: 'Ativas',
                            value: '${controller.totalAtivas}',
                            color: AdminPalette.success,
                            icon: Icons.check_circle_outline_rounded,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.carregando.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.erro.isNotEmpty) {
                  return AdminEmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Não foi possível carregar',
                    message: controller.erro.value,
                    actionLabel: 'Tentar de novo',
                    onAction: () =>
                        controller.carregarSubcategorias(widget.categoria.id),
                  );
                }

                final lista = controller.visiveis;
                if (lista.isEmpty) {
                  return AdminEmptyState(
                    icon: Icons.list_alt_outlined,
                    title: controller.subcategoriasFiltradas.isEmpty
                        ? 'Nenhuma subcategoria nesta categoria'
                        : 'Nenhum resultado para a busca',
                    message: controller.subcategoriasFiltradas.isEmpty
                        ? 'Cadastre subcategorias para detalhar os serviços de ${widget.categoria.nome}.'
                        : 'Tente outro termo.',
                    actionLabel: 'Nova subcategoria',
                    onAction: () => showSubcategoriaServicoBottomSheet(
                      context,
                      subcategoria: null,
                      categoriaSelecionada: widget.categoria,
                      categoriaController: widget.categoriaController,
                      subcategoriaController: controller,
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AdminPalette.primary,
                  onRefresh: () =>
                      controller.carregarSubcategorias(widget.categoria.id),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
                    itemCount: lista.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final s = lista[i];
                      final qtd = controller.servicosDe(s.id);
                      final descricao = s.descricao?.trim();
                      return AdminCard(
                        onTap: () => showSubcategoriaServicoBottomSheet(
                          context,
                          subcategoria: s,
                          categoriaController: widget.categoriaController,
                          subcategoriaController: controller,
                        ),
                        onLongPress: () async {
                          final ok = await confirmarAcaoAdmin(
                            context,
                            titulo: 'Excluir subcategoria',
                            mensagem: 'Deseja realmente excluir "${s.nome}"?',
                          );
                          if (ok) await controller.excluirSubcategoria(s.id);
                        },
                        child: Row(
                          children: [
                            AdminLeadingMark(
                              icon: CategoriaIcones.de(s.icone),
                              color: s.ativo
                                  ? AdminPalette.primary
                                  : AdminPalette.muted,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.nome,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
                                      color: s.ativo
                                          ? AdminPalette.ink
                                          : AdminPalette.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  AdminMetaLine(
                                    parts: [
                                      if (descricao != null &&
                                          descricao.isNotEmpty)
                                        descricao,
                                      qtd == 1 ? '1 serviço' : '$qtd serviços',
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (!s.ativo)
                              AdminStatusChip.neutral('Inativa',
                                  icon: Icons.pause_rounded),
                            AdminCompactSwitch(
                              value: s.ativo,
                              onChanged: (v) =>
                                  controller.atualizarStatus(s, v),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
