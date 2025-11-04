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
    final solicitacoesController = Get.put(SolicitacoesController(), permanent: false);

    // 🔹 Inicializa o listener uma única vez (fora do Obx)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fornecedor = fornecedorController.fornecedor.value;
      if (fornecedor != null) {
        solicitacoesController.inicializar(fornecedor.idFornecedor);
      }
    });

    return Obx(() {
      final fornecedor = fornecedorController.fornecedor.value;

      if (fornecedor == null) {
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      }

      if (solicitacoesController.carregando.value) {
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      }

      if (solicitacoesController.erro.isNotEmpty) {
        return Center(
          child: Text(
            solicitacoesController.erro.value,
            style: GoogleFonts.poppins(color: Colors.red.shade600),
          ),
        );
      }

      final lista = solicitacoesController.solicitacoes;

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
            "🗂️ Cotações Recentes",
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
              return SolicitacaoFornecedorCard(solicitacao: lista[index]);
            },
          ),
        ],
      );
    });
  }
}
