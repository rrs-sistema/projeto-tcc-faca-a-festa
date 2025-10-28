import 'package:app_faca_festa/core/utils/biblioteca.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../dialogs/edit_fornecedor_bottom_sheet.dart';
import './../../../../controllers/fornecedor_controller.dart';

class PerfilSection extends StatelessWidget {
  const PerfilSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FornecedorController>();

    return Obx(() {
      final fornecedor = controller.fornecedor.value;

      if (controller.carregando.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "🧑‍💼 Meu Perfil",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),

          // 🔹 Card de informações básicas
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔸 Razão social
                Row(
                  children: [
                    const Icon(Icons.store_mall_directory_rounded, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        fornecedor?.razaoSocial ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 🔸 CNPJ (se existir)
                if (fornecedor?.cnpj != null)
                  Row(
                    children: [
                      const Icon(Icons.badge_outlined, color: Color(0xFF388E3C)),
                      const SizedBox(width: 10),
                      Text(
                        Biblioteca.formatarCnpj(fornecedor?.cnpj),
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade700,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 10),

                // 🔸 Contatos
                Row(
                  children: [
                    const Icon(Icons.phone, color: Color(0xFF43A047)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        Biblioteca.formatarCelular(fornecedor?.telefone),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.email_outlined, color: Color(0xFF43A047)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        fornecedor?.email ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),

                const Divider(height: 24, thickness: 0.7),

                // 🔸 Descrição
                Text(
                  "Descrição",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  fornecedor?.descricao ?? "Nenhuma descrição adicionada.",
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade600,
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),

                const Divider(height: 24, thickness: 0.7),

                // 🔸 Território de atendimento (mock)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.map_outlined, color: Color(0xFF43A047)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Território de atendimento",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                              fontSize: 14.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Atende até 30 km de Curitiba/PR",
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade600,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 🔹 Botões de ação
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) {
                          return DraggableScrollableSheet(
                            expand: false,
                            initialChildSize: 0.75, // tamanho inicial do bottomsheet
                            minChildSize: 0.5, // tamanho mínimo ao arrastar pra baixo
                            maxChildSize: 0.95, // tamanho máximo ao arrastar pra cima
                            builder: (context, scrollController) {
                              return Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                ),
                                child: SingleChildScrollView(
                                  controller:
                                      scrollController, // 🔹 importante para rolagem sincronizada
                                  child: EditFornecedorBottomSheet(fornecedor: fornecedor!),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: Text(
                        "Editar",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.orange.shade300),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => Get.snackbar(
                        "Perfil Público",
                        "Abrindo visualização pública...",
                        backgroundColor: Colors.teal.shade700,
                        colorText: Colors.white,
                      ),
                      icon: const Icon(Icons.remove_red_eye_outlined, color: Colors.white),
                      label: Text(
                        "Ver Público",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}
