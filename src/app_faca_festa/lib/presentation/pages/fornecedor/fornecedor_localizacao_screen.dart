import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/biblioteca.dart';
import './../../../controllers/fornecedor_localizacao_controller.dart';
import './../../../controllers/event_theme_controller.dart';
import './components/filtro_fornecedor_bottom_sheet.dart';
import './components/abrir_cotacao_bottom_sheet.dart';
import 'fornecedor_detalhe_screen.dart';
import 'fornecedor_produtos_screen.dart';

class FornecedorLocalizacaoScreen extends StatefulWidget {
  const FornecedorLocalizacaoScreen({super.key});

  @override
  State<FornecedorLocalizacaoScreen> createState() => _FornecedorLocalizacaoScreenState();
}

class _FornecedorLocalizacaoScreenState extends State<FornecedorLocalizacaoScreen> {
  final themeController = Get.find<EventThemeController>();
  final controller = Get.put(FornecedorLocalizacaoController());

  final List<String> categorias = [
    'Buffet',
    'Decoração',
    'Fotografia',
    'Música',
    'Locação',
    'Doces',
    'Convites',
  ];

  String categoriaSelecionada = 'Buffet';
  final RxSet<String> selecionados = <String>{}.obs; // 🔹 IDs selecionados

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final gradient = themeController.gradient.value;

      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            'Fornecedores',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.black),
          ),
          centerTitle: true,
          elevation: 0,
          flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_alt_outlined, color: Colors.black),
              tooltip: 'Filtrar fornecedores',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  isScrollControlled: true,
                  builder: (_) => FiltroFornecedorBottomSheet(controller: controller),
                );
              },
            ),
          ],
        ),
        body: Obx(() {
          final primary = themeController.primaryColor.value;
          final gradient = themeController.gradient.value;

          if (controller.carregando.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final fornecedoresPorCategoria = controller.fornecedoresFiltrados
              .where((f) => f.categoria == categoriaSelecionada)
              .toList();

          final selecionadosSet = selecionados; // observável aqui (já é RxSet)

          return Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),

                      _menuCategorias(primary, gradient),
                      const SizedBox(height: 20),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Center(
                          child: Text(
                            'Fornecedores de $categoriaSelecionada',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // === GRID ===
                      fornecedoresPorCategoria.isEmpty
                          ? _mensagemVazia()
                          : Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 18,
                                  crossAxisSpacing: 10,
                                  childAspectRatio: 0.55,
                                ),
                                itemCount: fornecedoresPorCategoria.length,
                                itemBuilder: (context, index) {
                                  final f = fornecedoresPorCategoria[index];
                                  final selecionado = selecionadosSet.contains(f.id);

                                  return GestureDetector(
                                    onTap: () {
                                      if (selecionado) {
                                        selecionados.remove(f.id);
                                      } else {
                                        selecionados.add(f.id);
                                      }
                                    },
                                    child: _cardFornecedor(
                                      f,
                                      primary,
                                      gradient,
                                      selecionado,
                                    ),
                                  );
                                },
                              ),
                            ),
                    ],
                  ),
                ),
              ),

              // === BOTÃO FIXO ===
              if (selecionados.isNotEmpty)
                Positioned(
                  bottom: 20,
                  left: 16,
                  right: 16,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.request_quote_rounded, color: Colors.white),
                    label: Text(
                      'Fazer Cotação (${selecionados.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 5,
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => CotacaoBottomSheet(
                          fornecedoresSelecionados: selecionados.toList(),
                          primary: primary,
                          gradient: gradient,
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        }),
      );
    });
  }

  // === Menu de categorias ===
  Widget _menuCategorias(Color primary, LinearGradient gradient) {
    final icones = {
      'Buffet': Icons.restaurant_rounded,
      'Decoração': Icons.style_rounded,
      'Fotografia': Icons.photo_camera_rounded,
      'Música': Icons.music_note_rounded,
      'Locação': Icons.store_mall_directory_rounded,
      'Doces': Icons.cake_rounded,
      'Convites': Icons.mail_outline_rounded,
    };

    return Container(
      height: 45,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: categorias.length,
        itemBuilder: (context, index) {
          final categoria = categorias[index];
          final selected = categoriaSelecionada == categoria;
          final icon = icones[categoria] ?? Icons.star_rounded;

          return GestureDetector(
            onTap: () => setState(() => categoriaSelecionada = categoria),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                gradient: selected ? gradient : null,
                color: selected ? null : Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: selected ? Colors.transparent : Colors.grey.shade300,
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: selected ? Colors.white : primary),
                  const SizedBox(width: 6),
                  Text(
                    categoria,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15.5,
                      color: selected ? Colors.white : Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // === Card com estado de seleção ===
  Widget _cardFornecedor(
    FornecedorModel f,
    Color primary,
    LinearGradient gradient,
    bool selecionado,
  ) {
    final isTablet = Biblioteca.isTablet(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: selecionado ? primary.withValues(alpha: 0.05) : Colors.white,
        border: Border.all(
          color: selecionado ? primary : Colors.grey.shade300,
          width: selecionado ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: selecionado ? 0.3 : 0.08),
            blurRadius: selecionado ? 10 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // ✅ evita overflow
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === Imagem do fornecedor ===
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.asset(
              f.imagem ?? 'assets/images/fornecedor_default.jpg',
              height: isTablet ? 320 : 100,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          // === Dados principais ===
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 13, color: primary),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        '${f.distanciaKm.toStringAsFixed(1)} km de você',
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // === Botões de ação (um sobre o outro) ===
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.inventory_2_outlined, size: 18),
                  label: const Text('Outros Produtos', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.teal.shade50,
                    foregroundColor: primary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Get.to(() => FornecedorProdutosScreen(fornecedor: f));
                  },
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.info_outline_rounded, size: 18),
                  label: const Text('Ver Detalhes', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Get.to(() => FornecedorDetalheScreen(fornecedor: f));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mensagemVazia() => Padding(
        padding: const EdgeInsets.only(top: 100),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Nenhum fornecedor encontrado',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
            const SizedBox(height: 6),
            Text('Tente ajustar os filtros ou escolha outra categoria ✨',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          ],
        ),
      );
}
