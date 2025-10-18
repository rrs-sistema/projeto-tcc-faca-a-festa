import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/event_theme_controller.dart';
import '../../../controllers/fornecedor_localizacao_controller.dart';
import 'components/abrir_cotacao_bottom_sheet.dart';

class FornecedorDetalheScreen extends StatelessWidget {
  final FornecedorModel fornecedor;
  const FornecedorDetalheScreen({super.key, required this.fornecedor});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<EventThemeController>();
    final gradient = themeController.gradient.value;
    final primary = themeController.primaryColor.value;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          fornecedor.nome,
          style:
              GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16),
        ),
        centerTitle: true,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === Foto principal ===
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                fornecedor.imagem ?? 'assets/images/fornecedor_default.jpg',
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),

            // === Nome e Categoria ===
            Text(
              fornecedor.nome,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              fornecedor.categoria,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 16),
            _infoTile(Icons.place_outlined, fornecedor.cidade ?? 'Cidade não informada'),
            _infoTile(Icons.call_outlined, fornecedor.telefone ?? 'Telefone não informado'),
            _infoTile(Icons.email_outlined, fornecedor.email ?? 'E-mail não informado'),

            const SizedBox(height: 20),

            // === Descrição ===
            Text(
              'Descrição do serviço',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              fornecedor.descricao ??
                  'Este fornecedor ainda não adicionou uma descrição detalhada sobre seus serviços.',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54, height: 1.5),
            ),

            const SizedBox(height: 30),

            // === Botão para cotação ===
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.request_quote_rounded, color: Colors.white),
                label: const Text('Solicitar Orçamento',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 6,
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => CotacaoBottomSheet(
                      fornecedoresSelecionados: [fornecedor.id],
                      primary: primary,
                      gradient: gradient,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
