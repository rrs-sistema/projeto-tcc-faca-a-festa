import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/bootstrap/tema_festa_bootstrap.dart';
import '../../../controllers/tema/admin_theme.dart';
import '../../../controllers/tema/event_theme_controller.dart';
import '../../../controllers/tema/tema_festa_controller.dart';
import '../../../data/models/evento/tema_festa_model.dart';
import '../../widgets/tema_capa_imagem.dart';
import 'tema_festa_form_bottom_sheet.dart';

class TemaFestaAdminListScreen extends StatelessWidget {
  const TemaFestaAdminListScreen({super.key});

  static const Color _dark = Color(0xFF1F2937);
  static const Color _muted = Color(0xFF64748B);
  static const Color _surface = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    final controller = TemaFestaBootstrap.findController();
    final theme = Get.find<EventThemeController>();

    if (controller.temas.isEmpty && !controller.carregando.value) {
      controller.carregar(popularSeVazio: true);
    }

    return Theme(
      data: theme.adminThemeData,
      child: Scaffold(
        backgroundColor: _surface,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            tooltip: 'Voltar',
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'Temas da festa',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          flexibleSpace: Container(
              decoration: BoxDecoration(gradient: theme.adminGradient)),
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
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: _dark,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: Text('Novo tema', style: GoogleFonts.poppins(fontSize: 13)),
          onPressed: () => showTemaFestaFormBottomSheet(context),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      onChanged: (value) => controller.busca.value = value,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Buscar por nome, tipo ou descrição',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(chip.$2),
                              selected: selecionado,
                              selectedColor: _dark,
                              labelStyle: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selecionado ? Colors.white : _dark,
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.palette_outlined,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          controller.temas.isEmpty
                              ? 'Nenhum tema cadastrado'
                              : 'Nenhum tema nesta busca',
                          style: GoogleFonts.poppins(color: _muted),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final tema = lista[index];
                    return Slidable(
                      endActionPane: ActionPane(
                        motion: const DrawerMotion(),
                        extentRatio: 0.28,
                        children: [
                          SlidableAction(
                            onPressed: (_) =>
                                _confirmarExclusao(context, controller, tema),
                            backgroundColor: const Color(0xFFE11D48),
                            foregroundColor: Colors.white,
                            icon: Icons.delete_rounded,
                            label: 'Excluir',
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ],
                      ),
                      child: _TemaFestaCard(
                        tema: tema,
                        onTap: () =>
                            showTemaFestaFormBottomSheet(context, tema: tema),
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
    TemaFestaModel tema,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir tema'),
        content: Text(
            'Deseja excluir "${tema.nome}"? Eventos que já usam este tema não serão alterados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmar == true) {
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

  final TemaFestaModel tema;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final tipos = tema.tiposEvento.isEmpty
        ? const <String>[]
        : tema.tiposEvento.map(TemaFestaTipos.rotulo).toList();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Opacity(
            opacity: tema.ativo ? 1 : 0.58,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 92,
                  decoration: BoxDecoration(
                    gradient: tema.gradient,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(15)),
                  ),
                  child: TemaCapaImagem(
                    url: tema.capaEfetiva,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(15)),
                    fallback: DecoratedBox(
                      decoration: BoxDecoration(gradient: tema.gradient),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: tema.gradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(tema.iconData, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    tema.nome,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: const Color(0xFF1F2937),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: tema.ativo
                                        ? const Color(0xFFECFDF5)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    tema.ativo ? 'Ativo' : 'Inativo',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: tema.ativo
                                          ? const Color(0xFF047857)
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              TemaFestaCategorias.rotulo(tema.categoria),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            if ((tema.descricao ?? '').trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                tema.descricao!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            ],
                            if (tipos.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: tipos
                                    .map(
                                      (tipo) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          tipo,
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: const Color(0xFF334155),
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
                      IconButton(
                        tooltip: 'Excluir',
                        onPressed: onDelete,
                        icon:
                            const Icon(Icons.delete_outline_rounded, size: 20),
                        color: const Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
