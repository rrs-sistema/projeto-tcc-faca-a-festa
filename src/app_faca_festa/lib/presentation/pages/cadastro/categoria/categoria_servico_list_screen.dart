import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/presentation/modules/catalogo/controllers/categoria_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/subcategoria_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/admin_theme.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import '../../../../data/models/servico_produto/categoria_servico_model.dart';
import '../../../widgets/admin/admin_kit.dart';
import './categoria_servico_bottom_sheet.dart';
import './subcategoria_servico_list_screen.dart';

class CategoriaServicoListScreen extends StatelessWidget {
  const CategoriaServicoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CategoriaServicoController>();
    final theme = Get.find<EventThemeController>();

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
                  await _popularCatalogo(context, controller);
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
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AdminPalette.dark,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: Text('Nova categoria',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          onPressed: () => showCategoriaServicoBottomSheet(context),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  AdminSearchField(
                    hint: 'Buscar categoria ou descrição',
                    onChanged: (v) => controller.busca.value = v,
                  ),
                  const SizedBox(height: 12),
                  Obx(() {
                    return Row(
                      children: [
                        AdminSummaryChip(
                          label: 'Total',
                          value: '${controller.categorias.length}',
                          color: AdminPalette.primary,
                          icon: Icons.category_rounded,
                          onTap: () => controller.filtroAtivo.value = null,
                        ),
                        const SizedBox(width: 8),
                        AdminSummaryChip(
                          label: 'Ativas',
                          value: '${controller.totalAtivas}',
                          color: AdminPalette.success,
                          icon: Icons.check_circle_outline_rounded,
                          onTap: () => controller.filtroAtivo.value = true,
                        ),
                        const SizedBox(width: 8),
                        AdminSummaryChip(
                          label: 'Inativas',
                          value:
                              '${controller.categorias.length - controller.totalAtivas}',
                          color: AdminPalette.muted,
                          icon: Icons.pause_circle_outline_rounded,
                          onTap: () => controller.filtroAtivo.value = false,
                        ),
                      ],
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
                        ? () => _popularCatalogo(context, controller)
                        : () => showCategoriaServicoBottomSheet(context),
                  );
                }

                return RefreshIndicator(
                  color: AdminPalette.primary,
                  onRefresh: controller.carregarCategorias,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: lista.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final c = lista[i];
                      return _CategoriaAdminCard(
                        categoria: c,
                        subcategorias: controller.subcategoriasDe(c.id),
                        onEditar: () =>
                            showCategoriaServicoBottomSheet(context, c),
                        onSubcategorias: () => Get.to(
                            () => SubcategoriaServicoListScreen(categoria: c)),
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
  CategoriaServicoController controller,
) async {
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
    if (Get.isRegistered<SubcategoriaServicoController>()) {
      await Get.find<SubcategoriaServicoController>()
          .carregarTodasSubcategoria();
    }
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
  final CategoriaServicoModel categoria;
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
    return AdminCard(
      onTap: onEditar,
      onLongPress: onExcluir,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AdminPalette.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(categoria.iconData, color: AdminPalette.primary),
          ),
          const SizedBox(width: 14),
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
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: categoria.ativo
                              ? AdminPalette.ink
                              : AdminPalette.muted,
                        ),
                      ),
                    ),
                    Switch.adaptive(
                      value: categoria.ativo,
                      onChanged: onToggle,
                    ),
                  ],
                ),
                Text(
                  categoria.descricao?.isNotEmpty == true
                      ? categoria.descricao!
                      : 'Sem descrição cadastrada',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: AdminPalette.muted,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    AdminMetricChip(
                      icon: Icons.account_tree_outlined,
                      label: subcategorias == 1
                          ? '1 subcategoria'
                          : '$subcategorias subcategorias',
                    ),
                    if (!categoria.ativo)
                      AdminStatusChip.neutral('Inativa',
                          icon: Icons.pause_rounded)
                    else
                      AdminStatusChip.success('Ativa',
                          icon: Icons.check_rounded),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: onSubcategorias,
                      icon: const Icon(Icons.subdirectory_arrow_right_rounded,
                          size: 18),
                      label: Text('Subcategorias',
                          style: GoogleFonts.poppins(fontSize: 13)),
                      style: TextButton.styleFrom(
                          foregroundColor: AdminPalette.primary),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Excluir',
                      onPressed: onExcluir,
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AdminPalette.danger),
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
}
