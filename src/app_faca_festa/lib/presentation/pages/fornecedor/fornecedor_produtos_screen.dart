import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/biblioteca.dart';
import './../../../controllers/fornecedor_localizacao_controller.dart';
import './../../../controllers/event_theme_controller.dart';
import './components/abrir_cotacao_bottom_sheet.dart';

class FornecedorProdutosScreen extends StatefulWidget {
  final FornecedorModel fornecedor;
  const FornecedorProdutosScreen({super.key, required this.fornecedor});

  @override
  State<FornecedorProdutosScreen> createState() => _FornecedorProdutosScreenState();
}

class _FornecedorProdutosScreenState extends State<FornecedorProdutosScreen> {
  final RxSet<int> selecionados = <int>{}.obs;

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<EventThemeController>();
    final gradient = themeController.gradient.value;
    final primary = themeController.primaryColor.value;

    // Lista de produtos (simulada)
    final produtos = widget.fornecedor.produtos ??
        [
          {
            'nome': 'Bolo de Casamento',
            'preco': 'R\$ 450,00',
            'img': 'assets/images/bg_event_001.jpeg'
          },
          {
            'nome': 'Docinhos Gourmet',
            'preco': 'R\$ 320,00',
            'img': 'assets/images/bg_event_002.jpeg'
          },
          {
            'nome': 'Decoração Floral',
            'preco': 'R\$ 1.200,00',
            'img': 'assets/images/bg_event_003.jpg'
          },
        ];

    return Obx(() {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Produtos de ${widget.fornecedor.nome}',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: 16,
            ),
          ),
          centerTitle: true,
          flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
        ),

        // === GRID DE PRODUTOS ===
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: GridView.builder(
            itemCount: produtos.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 18,
              crossAxisSpacing: 18,
              childAspectRatio: 0.65,
            ),
            itemBuilder: (context, index) {
              final p = produtos[index];
              final selecionado = selecionados.contains(index);
              return GestureDetector(
                onTap: () {
                  if (selecionado) {
                    selecionados.remove(index);
                  } else {
                    selecionados.add(index);
                  }
                },
                child: _produtoCard(p, primary, gradient, selecionado),
              );
            },
          ),
        ),

        // === BOTÃO FIXO DE COTAÇÃO ===
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: selecionados.isEmpty
            ? null
            : ElevatedButton.icon(
                icon: const Icon(Icons.request_quote_rounded, color: Colors.white),
                label: Text(
                  'Cotar (${selecionados.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                  backgroundColor: primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 6,
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => CotacaoBottomSheet(
                      fornecedoresSelecionados: [widget.fornecedor.id],
                      primary: primary,
                      gradient: gradient,
                    ),
                  );
                },
              ),
      );
    });
  }

  // === Card de produto com estado visual de seleção ===
  Widget _produtoCard(
      Map<String, dynamic> p, Color primary, LinearGradient gradient, bool selecionado) {
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
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.asset(
                  p['img']!,
                  height: isTablet ? 320 : 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p['nome']!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p['preco']!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 🔹 Indicador visual de seleção
          Positioned(
            top: 8,
            right: 8,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: selecionado ? gradient : null,
                border: Border.all(
                  color: selecionado ? Colors.transparent : Colors.grey.shade400,
                  width: 1.2,
                ),
                color: selecionado ? null : Colors.white,
              ),
              child: Icon(
                selecionado ? Icons.check_rounded : Icons.add_rounded,
                color: selecionado ? Colors.white : Colors.grey.shade500,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
