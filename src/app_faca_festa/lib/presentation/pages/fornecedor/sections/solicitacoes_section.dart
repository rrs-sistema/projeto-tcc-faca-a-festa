import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../../controllers/contacao/solicitacoes_controller.dart';
import './../../../../controllers/fornecedor_controller.dart';
import 'solicitacao/solicitacao_fornecedor_card.dart';

class SolicitacoesSection extends StatelessWidget {
  const SolicitacoesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final fornecedorController = Get.find<FornecedorController>();
    final fornecedor = fornecedorController.fornecedor.value;

    if (fornecedor == null) {
      return const Center(child: Text("Nenhum fornecedor logado."));
    }

    final controller = Get.put(SolicitacoesController());
    controller.carregarSolicitacoes(fornecedor.idFornecedor);

    return Obx(() {
      if (controller.carregando.value) {
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      }

      if (controller.erro.isNotEmpty) {
        return Center(
          child: Text(
            controller.erro.value,
            style: GoogleFonts.poppins(color: Colors.red.shade600),
          ),
        );
      }

      final lista = controller.solicitacoes;
      if (lista.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text(
              "Nenhuma solicitação recente.",
              style: GoogleFonts.poppins(color: Colors.grey.shade600),
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "📩 Solicitações Recentes",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            itemCount: lista.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final solicitacao = lista[index];
              return SolicitacaoFornecedorCard(solicitacao: solicitacao);
            },
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                Get.snackbar(
                  "Solicitações",
                  "Abrindo lista completa...",
                  backgroundColor: const Color(0xFF2E7D32),
                  colorText: Colors.white,
                );
              },
              icon: const Icon(Icons.list_alt_rounded, color: Colors.white),
              label: Text(
                "Ver todas",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}
