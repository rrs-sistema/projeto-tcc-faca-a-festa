import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../../controllers/contacao/solicitacoes_controller.dart';
import '../../../../controllers/fornecedor/fornecedor_controller.dart';
import 'solicitacao/solicitacao_fornecedor_card.dart';

class SolicitacoesSection extends StatelessWidget {
  const SolicitacoesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final fornecedorController = Get.find<FornecedorController>();
    final solicitacoesController = Get.put(SolicitacoesController(), permanent: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fornecedor = fornecedorController.fornecedor.value;
      if (fornecedor != null) {
        solicitacoesController.inicializar(fornecedor.idFornecedor);
      }
    });

    return Obx(() {
      final fornecedor = fornecedorController.fornecedor.value;

      if (fornecedor == null || solicitacoesController.carregando.value) {
        return const SizedBox(
            height: 100, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
      }

      if (solicitacoesController.erro.isNotEmpty) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Text(solicitacoesController.erro.value,
              style: GoogleFonts.poppins(color: Colors.red.shade600, fontSize: 14)),
        );
      }

      final lista = solicitacoesController.solicitacoes;

      if (lista.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200)),
          child: Center(
              child: Text("Sua esteira de solicitações está vazia no momento.",
                  style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 14))),
        );
      }

      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.inbox_rounded, size: 20, color: Colors.grey.shade800),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Cotações Recebidas e Pendentes",
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
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
        ),
      );
    });
  }
}
