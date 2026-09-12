import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/domain/entities/orcamento.dart';
import 'package:app_faca_festa/presentation/modules/orcamento/controllers/orcamento_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/dialogs/show_responder_orcamento_dialog.dart';

class OrcamentosScreen extends StatelessWidget {
  const OrcamentosScreen({
    super.key,
    required this.controller,
    required this.idFornecedor,
  });

  final OrcamentoController controller;
  final String idFornecedor;

  @override
  Widget build(BuildContext context) {
    if (idFornecedor.trim().isNotEmpty) {
      controller.escutarOrcamentos(idFornecedor);
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'Voltar',
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Orçamentos Recebidos",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 3,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          final lista = controller.orcamentos;

          if (lista.isEmpty) {
            return Center(
              child: Text(
                "Nenhum orçamento recebido ainda.",
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            separatorBuilder: (_, __) =>
                const Divider(height: 1, thickness: 0.6),
            itemCount: lista.length,
            itemBuilder: (context, index) {
              final orcamento = lista[index];
              return _OrcamentoCard(
                orcamento: orcamento,
                controller: controller,
              );
            },
          );
        }),
      ),
    );
  }
}

class _OrcamentoCard extends StatelessWidget {
  final Orcamento orcamento;
  final OrcamentoController controller;

  const _OrcamentoCard({
    required this.orcamento,
    required this.controller,
  });

  Color get corStatus {
    switch (orcamento.status) {
      case StatusOrcamento
            .pendente: //statusInicial: StatusOrcamento.emNegociacao,
        return Colors.orange.shade700;
      case StatusOrcamento.emNegociacao:
        return Colors.blue.shade700;
      case StatusOrcamento.fechado:
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      leading: CircleAvatar(
        backgroundColor: corStatus.withValues(alpha: 0.15),
        radius: 24,
        child: Icon(Icons.request_quote_rounded, color: corStatus),
      ),
      title: Text(
        orcamento.idOrcamento.toUpperCase(),
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
          fontSize: 15,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          orcamento.anotacoes ?? "Sem observações adicionais.",
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            color: Colors.grey.shade700,
          ),
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            orcamento.custoEstimado != null
                ? "R\$ ${orcamento.custoEstimado!.toStringAsFixed(2)}"
                : "—",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.teal.shade700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            orcamento.status.label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 11,
              color: corStatus,
            ),
          ),
        ],
      ),
      onTap: () => showResponderOrcamentoDialog(
        context,
        orcamento: orcamento,
        controller: controller,
      ),
    );
  }
}
