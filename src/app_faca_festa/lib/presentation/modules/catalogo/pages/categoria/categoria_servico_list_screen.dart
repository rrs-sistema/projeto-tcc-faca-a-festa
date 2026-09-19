import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/presentation/modules/catalogo/controllers/categoria_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/subcategoria_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/categoria_icones.dart';
import 'package:app_faca_festa/presentation/modules/tema/admin_theme.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/domain/entities/categoria_servico.dart';
import 'package:app_faca_festa/presentation/widgets/admin/admin_kit.dart';
import './categoria_servico_bottom_sheet.dart';
import './subcategoria_servico_list_screen.dart';

class CategoriaServicoListScreen extends StatelessWidget {
  final CategoriaServicoController controller;
  final EventThemeController theme;
  final SubcategoriaServicoController subcategoriaController;

  const CategoriaServicoListScreen({
    super.key,
    required this.controller,
    required this.theme,
    required this.subcategoriaController,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: theme.adminThemeData,
      child: Scaffold(
        backgroundColor: AdminPalette.surface,
        appBar: AdminBackAppBar(
          title: 'Categorias de Serviços',
          subtitle: 'Catálogo operacional',
          actions: [
            IconButton(
              tooltip: 'Atualizar',
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: controller.carregarCategorias,
            ),
            PopupMenuButton<String>(
              tooltip: 'Mais ações',
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
              onSelected: (value) async {
                if (value == 'popular') {
                  await _popularCatalogo(
                    context,
                    controller,
                    subcategoriaController: subcategoriaController,
                  );
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'popular',
                  child: Text('Popular catálogo de festas'),
                ),
              ],
            ),
          ],
        ),
        floatingActionButton: AdminCreateFab(
          label: 'Nova categoria',
          onPressed: () => showCategoriaServicoBottomSheet(
            context,
            controller: controller,
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Column(
                children: [
                  AdminSearchField(
                    hint: 'Buscar categoria ou descrição',
                    onChanged: (v) => controller.busca.value = v,
                  ),
                  const SizedBox(height: 8),
                  Obx(() {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          AdminSummaryChip(
                            label: 'Total',
                            value: '${controller.categorias.length}',
                            color: AdminPalette.primary,
                            icon: Icons.category_rounded,
                            onTap: () => controller.filtroAtivo.value = null,
                          ),
                          const SizedBox(width: 6),
                          AdminSummaryChip(
                            label: 'Ativas',
                            value: '${controller.totalAtivas}',
                            color: AdminPalette.success,
                            icon: Icons.check_circle_outline_rounded,
                            onTap: () => controller.filtroAtivo.value = true,
                          ),
                          const SizedBox(width: 6),
                          AdminSummaryChip(
                            label: 'Inativas',
                            value:
                                '${controller.categorias.length - controller.totalAtivas}',
                            color: AdminPalette.muted,
                            icon: Icons.pause_circle_outline_rounded,
                            onTap: () => controller.filtroAtivo.value = false,
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
                final lista = controller.categoriasFiltradas;
                if (lista.isEmpty) {
                  return AdminEmptyState(
                    icon: Icons.category_outlined,
                    title: controller.categorias.isEmpty
                        ? 'Nenhuma categoria cadastrada'
                        : 'Nenhuma categoria nesta busca',
                    message: controller.categorias.isEmpty
                        ? 'Crie a primeira categoria para organizar o catálogo de serviços.'
                        : 'Tente outro termo ou limpe o filtro de status.',
                    actionLabel: controller.categorias.isEmpty
                        ? 'Popular catálogo de festas'
                        : 'Nova categoria',
                    onAction: controller.categorias.isEmpty
                        ? () => _popularCatalogo(
                              context,
                              controller,
                              subcategoriaController: subcategoriaController,
                            )
                        : () => showCategoriaServicoBottomSheet(
                              context,
                              controller: controller,
                            ),
                  );
                }

                return RefreshIndicator(
                  color: AdminPalette.primary,
                  onRefresh: controller.carregarCategorias,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
                    itemCount: lista.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final c = lista[i];
                      return _CategoriaAdminCard(
                        categoria: c,
                        subcategorias: controller.subcategoriasDe(c.id),
                        onEditar: () => showCategoriaServicoBottomSheet(
                          context,
                          controller: controller,
                          categoria: c,
                        ),
                        onSubcategorias: () => Get.to(
                          () => SubcategoriaServicoListScreen(
                            categoria: c,
                            categoriaController: controller,
                            subcategoriaController: subcategoriaController,
                            themeController: theme,
                          ),
                        ),
                        onToggle: (v) => controller.atualizarStatus(c, v),
                        onExcluir: () async {
                          final n = controller.subcategoriasDe(c.id);
                          final ok = await confirmarAcaoAdmin(
                            context,
                            titulo: 'Excluir categoria',
                            mensagem: n > 0
                                ? 'Excluir "${c.nome}" também remove $n subcategoria(s) vinculada(s).'
                                : 'Deseja realmente excluir "${c.nome}"?',
                          );
                          if (ok) await controller.excluirCategoria(c.id);
                        },
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

Future<void> _popularCatalogo(
  BuildContext context,
  CategoriaServicoController controller, {
  required SubcategoriaServicoController subcategoriaController,
}) async {
  final ok = await confirmarAcaoAdmin(
    context,
    titulo: 'Popular catálogo de festas',
    mensagem:
        'Isso grava as categorias e subcategorias mais usadas no mercado de festas '
        '(espaços, buffet, vestidos, beleza, transporte e outras). '
        'Itens já cadastrados são atualizados sem perder os vínculos de fornecedores.',
    confirmar: 'Popular catálogo',
    cor: AdminPalette.primary,
  );
  if (!ok) return;

  try {
    EasyLoading.show(status: 'Gravando catálogo...');
    final resultado = await controller.popularCatalogoInicial();
    await subcategoriaController.carregarTodasSubcategoria();
    EasyLoading.dismiss();
    Get.snackbar(
      'Catálogo de festas',
      '${resultado.categorias} categorias e ${resultado.subcategorias} subcategorias gravadas.',
      snackPosition: SnackPosition.BOTTOM,
    );
  } catch (e) {
    EasyLoading.dismiss();
    Get.snackbar(
      'Erro ao popular catálogo',
      e.toString(),
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

class _CategoriaAdminCard extends StatelessWidget {
  final CategoriaServico categoria;
  final int subcategorias;
  final VoidCallback onEditar;
  final VoidCallback onSubcategorias;
  final ValueChanged<bool> onToggle;
  final VoidCallback onExcluir;

  const _CategoriaAdminCard({
    required this.categoria,
    required this.subcategorias,
    required this.onEditar,
    required this.onSubcategorias,
    required this.onToggle,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    final descricao = categoria.descricao?.trim();
    return AdminCard(
      onTap: onEditar,
      onLongPress: onExcluir,
      child: Row(
        children: [
          AdminLeadingMark(
            icon: CategoriaIcones.de(categoria.icone),
            color: categoria.ativo ? AdminPalette.primary : AdminPalette.muted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        categoria.nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                          height: 1.2,
                          color: categoria.ativo
                              ? AdminPalette.ink
                              : AdminPalette.muted,
                        ),
                      ),
                    ),
                    if (!categoria.ativo)
                      AdminStatusChip.neutral('Inativa',
                          icon: Icons.pause_rounded),
                  ],
                ),
                const SizedBox(height: 2),
                AdminMetaLine(
                  parts: [
                    if (descricao != null && descricao.isNotEmpty) descricao,
                    subcategorias == 1
                        ? '1 subcategoria'
                        : '$subcategorias subcategorias',
                  ],
                ),
              ],
            ),
          ),
          AdminIconAction(
            tooltip: 'Subcategorias',
            icon: Icons.account_tree_outlined,
            color: AdminPalette.primary,
            onPressed: onSubcategorias,
          ),
          AdminCompactSwitch(value: categoria.ativo, onChanged: onToggle),
          AdminIconAction(
            tooltip: 'Excluir',
            icon: Icons.delete_outline_rounded,
            color: AdminPalette.danger,
            onPressed: onExcluir,
          ),
        ],
      ),
    );
  }
}
