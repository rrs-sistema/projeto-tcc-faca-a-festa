import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../controllers/fornecedor_controller.dart';
import './sections/solicitacoes_section.dart';
import './sections/avaliacoes_section.dart';
import './sections/financeiro_section.dart';
import './sections/mensagens_section.dart';
import './sections/insights_section.dart';
import './sections/header_section.dart';
import './sections/resumo_section.dart';
import './sections/perfil_section.dart';

class FornecedorHomeScreen extends StatelessWidget {
  final controller = Get.find<FornecedorController>();

  FornecedorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HeaderSection(),
              const SizedBox(height: 20),
              const ResumoSection(),
              const SizedBox(height: 20),
              const SolicitacoesSection(),
              const SizedBox(height: 20),
              const MensagensSection(),
              const SizedBox(height: 20),
              const AvaliacoesSection(),
              const SizedBox(height: 20),
              const FinanceiroSection(),
              const SizedBox(height: 20),
              const PerfilSection(),
              const SizedBox(height: 20),
              const InsightsSection(),
            ],
          ),
        ),
      ),
    );
  }
}
