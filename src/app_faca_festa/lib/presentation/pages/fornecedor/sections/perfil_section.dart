import 'package:app_faca_festa/core/utils/biblioteca.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../dialogs/edit_fornecedor_bottom_sheet.dart';
import '../../../../controllers/fornecedor/fornecedor_controller.dart';

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

      return Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ]),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 CABEÇALHO 100% RESPONSIVO (Sem Overflow)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.business_rounded, size: 20, color: Colors.grey.shade800),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Perfil Institucional",
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade900),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // 🔹 WRAP PROTEGE AS AÇÕES
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Tooltip(
                      message: "Visualizar como Cliente",
                      child: IconButton(
                        onPressed: () => Get.snackbar(
                            "Perfil Público", "Abrindo visualização pública...",
                            backgroundColor: Colors.grey.shade900, colorText: Colors.white),
                        icon: Icon(Icons.remove_red_eye_outlined,
                            size: 20, color: Colors.grey.shade600),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) {
                          return DraggableScrollableSheet(
                            expand: false,
                            initialChildSize: 0.85,
                            minChildSize: 0.5,
                            maxChildSize: 0.95,
                            builder: (context, scrollController) {
                              return Container(
                                decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                child: SingleChildScrollView(
                                    controller: scrollController,
                                    child: EditFornecedorBottomSheet(fornecedor: fornecedor!)),
                              );
                            },
                          );
                        },
                      ),
                      icon: Icon(Icons.edit_outlined, size: 16, color: Colors.grey.shade800),
                      label: Text("Editar",
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              color: Colors.grey.shade800)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 24),

            // 🔹 INFOS CORPORATIVAS (Protegidas com Expanded no método auxiliar)
            _buildInfoRow(Icons.store_mall_directory_outlined, "Razão Social",
                fornecedor?.razaoSocial ?? 'Não informado'),
            if (fornecedor?.cnpj != null) ...[
              const SizedBox(height: 16),
              _buildInfoRow(
                  Icons.badge_outlined, "CNPJ", Biblioteca.formatarCnpj(fornecedor?.cnpj)),
            ],
            const SizedBox(height: 16),
            _buildInfoRow(Icons.phone_outlined, "Telefone Comercial",
                Biblioteca.formatarCelular(fornecedor?.telefone)),
            const SizedBox(height: 16),
            _buildInfoRow(
                Icons.email_outlined, "E-mail de Contato", fornecedor?.email ?? 'Não informado'),

            const Divider(height: 32, color: Color(0xFFEEEEEE)),

            Text("Resumo Institucional / Biografia",
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, color: Colors.grey.shade800, fontSize: 14)),
            const SizedBox(height: 8),
            Text(
              fornecedor?.descricao ?? "Nenhuma descrição informada pelo fornecedor.",
              style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 13, height: 1.5),
            ),

            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.map_outlined, color: Colors.grey.shade500, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Território: Atende até 30 km de Curitiba/PR",
                    style: GoogleFonts.poppins(color: Colors.grey.shade700, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  // 🔹 MÉTODO SEGURO CONTRA OVERFLOW (Uso de Expanded)
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey.shade400, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500)),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                    fontSize: 14, color: Colors.grey.shade900, fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
