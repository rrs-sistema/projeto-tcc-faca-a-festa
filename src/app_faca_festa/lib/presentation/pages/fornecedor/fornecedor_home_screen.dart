import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import './../../../controllers/fornecedor_controller.dart';
import './sections/solicitacoes_section.dart';
import './sections/avaliacoes_section.dart';
import './sections/financeiro_section.dart';
import './sections/insights_section.dart';
import './sections/header_section.dart';
import './sections/resumo_section.dart';
import './sections/perfil_section.dart';

class FornecedorHomeScreen extends StatelessWidget {
  FornecedorHomeScreen({super.key});

  final FornecedorController controller = Get.find<FornecedorController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Obx(() {
          final fornecedor = controller.fornecedor.value;
          final bool apto = fornecedor?.aptoParaOperar ?? false;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HeaderSection(),
                const SizedBox(height: 20),
                const ResumoSection(),

                // 🔹 Só exibe as seções se o fornecedor estiver apto
                if (fornecedor != null && apto) ...[
                  const SizedBox(height: 20),
                  const SolicitacoesSection(),
                  const SizedBox(height: 20),
                  const AvaliacoesSection(),
                  const SizedBox(height: 20),
                  const FinanceiroSection(),
                  const SizedBox(height: 20),
                  const PerfilSection(),
                  const SizedBox(height: 20),
                  const InsightsSection(),
                ] else ...[
                  const SizedBox(height: 40),
                  _mensagemAguardandoAprovacao(),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  /// 🔹 Mensagem mostrada enquanto o fornecedor ainda não foi aprovado
  Widget _mensagemAguardandoAprovacao() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_empty_rounded, color: Colors.orange.shade700, size: 48),
            const SizedBox(height: 16),
            Text(
              "Seu cadastro está em análise",
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Assim que sua conta for aprovada, você poderá receber solicitações, avaliações e gerenciar seu financeiro diretamente pelo app.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
