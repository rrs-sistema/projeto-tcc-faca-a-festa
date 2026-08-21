import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../controllers/categoria/subcategoria_servico_controller.dart';
import '../../../../controllers/tema/admin_theme.dart';
import '../../../../controllers/tema/event_theme_controller.dart';
import '../../../../data/models/servico_produto/categoria_servico_model.dart';
import '../../../widgets/admin/admin_kit.dart';
import './show_subcategoria_servico_bottom_sheet.dart';

class SubcategoriaServicoListScreen extends StatefulWidget {
  final CategoriaServicoModel categoria;

  const SubcategoriaServicoListScreen({super.key, required this.categoria});

  @override
  State<SubcategoriaServicoListScreen> createState() => _SubcategoriaServicoListScreenState();
}

class _SubcategoriaServicoListScreenState extends State<SubcategoriaServicoListScreen> {
  late final SubcategoriaServicoController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<SubcategoriaServicoController>()
        ? Get.find<SubcategoriaServicoController>()
        : Get.put(SubcategoriaServicoController());
    controller.busca.value = '';
    controller.subcategoriasFiltradas.clear();
    controller.carregarSubcategorias(widget.categoria.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<EventThemeController>();

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
              onPressed: () => controller.carregarSubcategorias(widget.categoria.id),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AdminPalette.dark,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: Text('Nova subcategoria', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          onPressed: () =>
              showSubcategoriaServicoBottomSheet(context, null, widget.categoria),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  AdminSearchField(
                    hint: 'Buscar subcategoria',
                    onChanged: (v) => controller.busca.value = v,
                  ),
                  const SizedBox(height: 12),
                  Obx(() {
                    return Row(
                      children: [
                        AdminSummaryChip(
                          label: 'Nesta categoria',
                          value: '${controller.subcategoriasFiltradas.length}',
                          color: AdminPalette.primary,
                          icon: Icons.account_tree_outlined,
                        ),
                        const SizedBox(width: 8),
                        AdminSummaryChip(
                          label: 'Ativas',
                          value: '${controller.totalAtivas}',
                          color: AdminPalette.success,
                          icon: Icons.check_circle_outline_rounded,
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
                if (controller.erro.isNotEmpty) {
                  return AdminEmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Não foi possível carregar',
                    message: controller.erro.value,
                    actionLabel: 'Tentar de novo',
                    onAction: () => controller.carregarSubcategorias(widget.categoria.id),
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
                    onAction: () =>
                        showSubcategoriaServicoBottomSheet(context, null, widget.categoria),
                  );
                }

                return RefreshIndicator(
                  color: AdminPalette.primary,
                  onRefresh: () => controller.carregarSubcategorias(widget.categoria.id),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: lista.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final s = lista[i];
                      final qtd = controller.servicosDe(s.id);
                      return AdminCard(
                        onTap: () => showSubcategoriaServicoBottomSheet(context, s),
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
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: AdminPalette.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(s.iconData, color: AdminPalette.primary),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.nome,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: s.ativo ? AdminPalette.ink : AdminPalette.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    s.descricao?.isNotEmpty == true
                                        ? s.descricao!
                                        : 'Sem descrição',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.5,
                                      color: AdminPalette.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      AdminMetricChip(
                                        icon: Icons.design_services_outlined,
                                        label: qtd == 1 ? '1 serviço' : '$qtd serviços',
                                      ),
                                      if (s.ativo)
                                        AdminStatusChip.success('Ativa')
                                      else
                                        AdminStatusChip.neutral('Inativa'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: s.ativo,
                              onChanged: (v) => controller.atualizarStatus(s, v),
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
