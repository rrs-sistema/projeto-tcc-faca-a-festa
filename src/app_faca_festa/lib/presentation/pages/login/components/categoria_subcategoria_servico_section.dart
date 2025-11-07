import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../../controllers/categoria/subcategoria_servico_controller.dart';
import './../../../../controllers/categoria/categoria_servico_controller.dart';
import './../../../../controllers/servico_produto_controller.dart';
import './../../../../controllers/register_controller.dart';

class CategoriaSubcategoriaServicoSection extends StatelessWidget {
  final RegisterController controller;
  final Color primary;

  const CategoriaSubcategoriaServicoSection({
    super.key,
    required this.controller,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final categoriaController = Get.find<CategoriaServicoController>();
    final subcategoriaController = Get.find<SubcategoriaServicoController>();
    final servicoController = Get.find<ServicoProdutoController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Áreas de atuação',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),

        // 🟢 CATEGORIAS
        Obx(() {
          final categorias = categoriaController.categorias.toList();
          final selecionadas = controller.categoriasSelecionadas.toList();

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: categorias.isEmpty
                ? Padding(
                    key: const ValueKey('no_cat'),
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Nenhuma categoria disponível.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  )
                : SizedBox(
                    key: const ValueKey('cat_list'),
                    height: 50,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemCount: categorias.length,
                      itemBuilder: (_, i) {
                        final cat = categorias[i];
                        final isSelecionada =
                            selecionadas.map((c) => c.idCategoria).contains(cat.id);

                        return ChoiceChip(
                          label: Text(
                            cat.nome,
                            style: GoogleFonts.poppins(
                              color: isSelecionada ? Colors.white : Colors.grey.shade700,
                              fontWeight: isSelecionada ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          selected: isSelecionada,
                          selectedColor: primary,
                          backgroundColor: Colors.grey.shade200,
                          onSelected: (v) async {
                            if (v) {
                              final jaExiste = controller.categoriasSelecionadas
                                  .any((c) => c.idCategoria == cat.id);

                              if (!jaExiste) {
                                EasyLoading.show(status: 'Processando...');
                                controller.adicionarCategoria(cat);

                                // 🔹 Carrega subcategorias sem limpar tudo
                                await subcategoriaController
                                    .carregarSubcategoriasPorCategoria(cat.id);

                                // 🔹 (Opcional) Limpa apenas serviços da nova categoria
                                final subcats =
                                    subcategoriaController.subcategoriasPorCategoria[cat.id] ?? [];
                                for (final sub in subcats) {
                                  servicoController.removerServicosPorSubcategoria(sub.id);
                                }

                                await EasyLoading.dismiss();
                              }
                            } else {
                              controller.categoriasSelecionadas
                                  .removeWhere((c) => c.idCategoria == cat.id);

                              // 🔹 Limpa apenas subcategorias e serviços dessa categoria desmarcada
                              controller.limparSubcategorias(cat.id);
                              final subcats =
                                  subcategoriaController.subcategoriasPorCategoria[cat.id] ?? [];
                              for (final sub in subcats) {
                                servicoController.removerServicosPorSubcategoria(sub.id);
                              }
                            }
                          },
                        );
                      },
                    ),
                  ),
          );
        }),

        Divider(thickness: 1, color: Colors.grey.shade200, height: 20),

        // 🟣 SUBCATEGORIAS
        Obx(() {
          final selecionadas = controller.categoriasSelecionadas.toList();
          if (selecionadas.isEmpty) return const SizedBox.shrink();

          final todasSubcats = selecionadas.expand((catSel) {
            return subcategoriaController.subcategoriasPorCategoria[catSel.idCategoria] ?? [];
          }).toList();

          return AnimatedSize(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            child: todasSubcats.isEmpty
                ? Padding(
                    padding: const EdgeInsets.only(left: 6, top: 4),
                    child: Text(
                      'Nenhuma subcategoria cadastrada.',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subcategorias',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 52,
                        child: _HorizontalScrollChips(
                          subcats: todasSubcats,
                          catSel: selecionadas.first,
                          primary: primary,
                          onToggle: (sub, v) async {
                            controller.alternarSubcategoria(selecionadas.first, sub, v);
                            if (v) {
                              EasyLoading.show(status: 'Processando...');
                              final lista =
                                  await servicoController.carregarServicosPorSubcategoria(sub.id);

                              // 🔹 Adiciona os novos serviços sem apagar os anteriores
                              controller.servicosSelecionados.addAll(lista);

                              await EasyLoading.dismiss();
                            } else {
                              // 🔹 Remove apenas os serviços da subcategoria desmarcada
                              servicoController.removerServicosPorSubcategoria(sub.id);

                              // 🔹 Remove também da lista reativa de selecionados
                              controller.servicosSelecionados.removeWhere(
                                (s) => s.idSubcategoria == sub.id,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
          );
        }),

        Divider(thickness: 1, color: Colors.grey.shade200, height: 20),

        // 🟠 SERVIÇOS
        Obx(() {
          final selecionadas = controller.categoriasSelecionadas;
          if (selecionadas.isEmpty) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Padding(
                key: const ValueKey('sem_cat_serv'),
                padding: const EdgeInsets.only(left: 10, top: 6),
                child: Text(
                  'Selecione uma categoria para visualizar os serviços disponíveis.',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }

          final servicosMap = servicoController.servicosPorSubcategoria;
          final todasSubcats =
              subcategoriaController.subcategoriasPorCategoria.values.expand((e) => e).toList();
          final todosServicos = todasSubcats.expand((sub) => servicosMap[sub.id] ?? []).toList();

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: servicoController.carregando.value
                ? const Padding(
                    key: ValueKey('loading_serv'),
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : todosServicos.isEmpty
                    ? Padding(
                        key: const ValueKey('no_serv'),
                        padding: const EdgeInsets.only(left: 10, top: 6),
                        child: Text(
                          'Nenhum serviço cadastrado para esta subcategoria.',
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                        ),
                      )
                    : Column(
                        key: const ValueKey('serv_list'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Serviços e produtos',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 52,
                            child: _HorizontalScrollChipsServicos(
                              servicos: todosServicos,
                              primary: primary,
                              onToggle: (servico, selecionado) {
                                controller.alternarServico(servico, selecionado);

                                if (!selecionado) {
                                  for (final entry
                                      in servicoController.servicosPorSubcategoria.entries) {
                                    final idSub = entry.key;
                                    final lista = entry.value;

                                    lista.removeWhere((s) => s.id == servico.id);
                                    servicoController.servicosPorSubcategoria[idSub] =
                                        List.from(lista);
                                  }

                                  servicoController.servicosPorSubcategoria.refresh();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
          );
        }),
      ],
    );
  }
}

class _HorizontalScrollChips extends StatefulWidget {
  final List subcats;
  final dynamic catSel;
  final Color primary;
  final void Function(dynamic sub, bool selected) onToggle;

  const _HorizontalScrollChips({
    required this.subcats,
    required this.catSel,
    required this.primary,
    required this.onToggle,
  });

  @override
  State<_HorizontalScrollChips> createState() => _HorizontalScrollChipsState();
}

class _HorizontalScrollChipsState extends State<_HorizontalScrollChips> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      thickness: 6,
      radius: const Radius.circular(12),
      interactive: true,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: widget.subcats.map((sub) {
            final selecionada =
                widget.catSel.subcategorias.any((s) => s['idSubcategoria'] == sub.id);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(sub.nome),
                labelStyle: GoogleFonts.poppins(
                  color: selecionada ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                backgroundColor: Colors.grey.shade100,
                selectedColor: widget.primary.withValues(alpha: 0.85),
                checkmarkColor: Colors.white,
                selected: selecionada,
                onSelected: (v) => widget.onToggle(sub, v),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _HorizontalScrollChipsServicos extends StatefulWidget {
  final List servicos;
  final Color primary;
  final void Function(dynamic servico, bool selected) onToggle;

  const _HorizontalScrollChipsServicos({
    required this.servicos,
    required this.primary,
    required this.onToggle,
  });

  @override
  State<_HorizontalScrollChipsServicos> createState() => _HorizontalScrollChipsServicosState();
}

class _HorizontalScrollChipsServicosState extends State<_HorizontalScrollChipsServicos> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.primary;

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      thickness: 6,
      radius: const Radius.circular(12),
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: widget.servicos.map((serv) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                avatar: const Icon(Icons.design_services_rounded, size: 18, color: Colors.white),
                label: Text(serv.nome),
                labelStyle: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                backgroundColor: primary.withValues(alpha: 0.3),
                selectedColor: primary.withValues(alpha: 0.9),
                checkmarkColor: Colors.white,
                selected: true,
                onSelected: (v) => widget.onToggle(serv, v),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
