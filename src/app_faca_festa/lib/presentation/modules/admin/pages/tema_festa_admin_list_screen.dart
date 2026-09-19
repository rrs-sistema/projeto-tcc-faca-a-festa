import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/domain/entities/tema_festa.dart';
import 'package:app_faca_festa/presentation/modules/tema/admin_theme.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/tema_festa_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/tema_festa_view_model.dart';
import 'package:app_faca_festa/presentation/widgets/admin/admin_kit.dart';
import 'package:app_faca_festa/presentation/widgets/tema_capa_imagem.dart';
import 'tema_festa_form_bottom_sheet.dart';

class TemaFestaAdminListScreen extends StatelessWidget {
  final TemaFestaController controller;
  final EventThemeController theme;

  const TemaFestaAdminListScreen({
    super.key,
    required this.controller,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (controller.temas.isEmpty && !controller.carregando.value) {
      controller.carregar(popularSeVazio: true);
    }

    return Theme(
      data: theme.adminThemeData,
      child: Scaffold(
        backgroundColor: AdminPalette.surface,
        appBar: AdminBackAppBar(
          title: 'Temas da festa',
          subtitle: 'Catálogo visual',
          actions: [
            PopupMenuButton<String>(
              tooltip: 'Mais ações',
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
              onSelected: (value) async {
                if (value == 'popular') {
                  await controller.popularTemasIniciais();
                  Get.snackbar(
                    'Temas',
                    'Catálogo inicial gravado.',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                } else if (value == 'atualizar') {
                  await controller.carregar();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'popular',
                  child: Text('Popular catálogo inicial'),
                ),
                PopupMenuItem(
                  value: 'atualizar',
                  child: Text('Atualizar lista'),
                ),
              ],
            ),
          ],
        ),
        floatingActionButton: AdminCreateFab(
          label: 'Novo tema',
          onPressed: () => showTemaFestaFormBottomSheet(
            context,
            theme: theme,
            controller: controller,
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminSearchField(
                    hint: 'Buscar por nome, tipo ou descrição',
                    onChanged: (value) => controller.busca.value = value,
                  ),
                  const SizedBox(height: 8),
                  Obx(() {
                    final atual = controller.filtroCategoria.value;
                    final chips = <(String, String)>[
                      ('todos', 'Todos'),
                      ...TemaFestaCategorias.todas.map(
                        (item) => (item, TemaFestaCategorias.rotulo(item)),
                      ),
                    ];
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: chips.map((chip) {
                          final selecionado = atual == chip.$1;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(chip.$2),
                              selected: selecionado,
                              selectedColor: AdminPalette.dark,
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              labelPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 0),
                              labelStyle: GoogleFonts.poppins(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: selecionado
                                    ? Colors.white
                                    : AdminPalette.ink,
                              ),
                              side: BorderSide(
                                color: selecionado
                                    ? AdminPalette.dark
                                    : AdminPalette.border,
                              ),
                              onSelected: (_) =>
                                  controller.filtroCategoria.value = chip.$1,
                            ),
                          );
                        }).toList(),
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
                final lista = controller.temasFiltrados;
                if (lista.isEmpty) {
                  return AdminEmptyState(
                    icon: Icons.palette_outlined,
                    title: controller.temas.isEmpty
                        ? 'Nenhum tema cadastrado'
                        : 'Nenhum tema nesta busca',
                    message: controller.temas.isEmpty
                        ? 'Crie o primeiro tema ou popule o catálogo inicial.'
                        : 'Tente outro termo ou categoria.',
                    actionLabel: controller.temas.isEmpty ? 'Novo tema' : null,
                    onAction: controller.temas.isEmpty
                        ? () => showTemaFestaFormBottomSheet(
                              context,
                              theme: theme,
                              controller: controller,
                            )
                        : null,
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final tema = lista[index];
                    return Slidable(
                      endActionPane: ActionPane(
                        motion: const DrawerMotion(),
                        extentRatio: 0.22,
                        children: [
                          SlidableAction(
                            onPressed: (_) =>
                                _confirmarExclusao(context, controller, tema),
                            backgroundColor: AdminPalette.danger,
                            foregroundColor: Colors.white,
                            icon: Icons.delete_rounded,
                            label: 'Excluir',
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ],
                      ),
                      child: _TemaFestaCard(
                        tema: tema,
                        onTap: () => showTemaFestaFormBottomSheet(
                          context,
                          theme: theme,
                          controller: controller,
                          tema: tema,
                        ),
                        onDelete: () =>
                            _confirmarExclusao(context, controller, tema),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarExclusao(
    BuildContext context,
    TemaFestaController controller,
    TemaFestaViewModel tema,
  ) async {
    final confirmar = await confirmarAcaoAdmin(
      context,
      titulo: 'Excluir tema',
      mensagem:
          'Deseja excluir "${tema.nome}"? Eventos que já usam este tema não serão alterados.',
      confirmar: 'Excluir',
    );
    if (confirmar) {
      await controller.excluir(tema.idTema);
    }
  }
}

class _TemaFestaCard extends StatelessWidget {
  const _TemaFestaCard({
    required this.tema,
    required this.onTap,
    required this.onDelete,
  });

  final TemaFestaViewModel tema;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final tipos = tema.tiposEvento.isEmpty
        ? const <String>[]
        : tema.tiposEvento.map(TemaFestaTipos.rotulo).toList();
    final descricao = (tema.descricao ?? '').trim();

    return AdminCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(8, 8, 6, 8),
      child: Opacity(
        opacity: tema.ativo ? 1 : 0.58,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(gradient: tema.gradient),
                    ),
                    TemaCapaImagem(
                      url: tema.capaEfetiva,
                      fallback: DecoratedBox(
                        decoration: BoxDecoration(gradient: tema.gradient),
                        child: Icon(tema.iconData,
                            color: Colors.white.withValues(alpha: 0.92),
                            size: 22),
                      ),
                    ),
                  ],
                ),
              ),
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
                          tema.nome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                            height: 1.2,
                            color: AdminPalette.ink,
                          ),
                        ),
                      ),
                      AdminStatusChip(
                        label: tema.ativo ? 'Ativo' : 'Inativo',
                        color: tema.ativo
                            ? AdminPalette.success
                            : AdminPalette.muted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  AdminMetaLine(
                    parts: [
                      TemaFestaCategorias.rotulo(tema.categoria),
                      if (descricao.isNotEmpty) descricao,
                    ],
                  ),
                  if (tipos.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: tipos
                          .take(3)
                          .map(
                            (tipo) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AdminPalette.surface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AdminPalette.border),
                              ),
                              child: Text(
                                tipo,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: AdminPalette.ink,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            AdminIconAction(
              tooltip: 'Excluir',
              onPressed: onDelete,
              icon: Icons.delete_outline_rounded,
              color: const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }
}
