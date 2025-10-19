import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../../controllers/event_theme_controller.dart';
import '../../../controllers/orcamento_controller.dart';
import '../../../data/models/model.dart';

Future<void> showNovoOrcamentoBottomSheet({
  required BuildContext context,
  required String idEvento,
  required String idFornecedor,
  required ServicoProdutoModel servicoProduto,
  required FornecedorProdutoServicoModel servicoFornecedor,
}) async {
  final theme = Get.find<EventThemeController>();
  final controller = Get.find<OrcamentoController>();
  final uuid = const Uuid();

  final anotacoesController = TextEditingController();
  double? valorEstimado;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final cor = theme.primaryColor.value;
      final grad = theme.gradient.value;

      return FractionallySizedBox(
        heightFactor: 0.9,
        child: Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: cor.withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // === Cabeçalho ===
                    Row(
                      children: [
                        Icon(Icons.request_quote_rounded, color: cor, size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Solicitar orçamento",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Get.back(),
                          icon: const Icon(Icons.close_rounded, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // === Card do Serviço ===
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: grad,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            servicoProduto.nome,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            servicoProduto.descricao ?? "Sem descrição detalhada.",
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Unidade: ${servicoProduto.tipoMedida ?? 'N/A'}",
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                "R\$ ${(servicoFornecedor.precoPromocao ?? servicoFornecedor.preco).toStringAsFixed(2)}",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // === Campos ===
                    TextField(
                      controller: anotacoesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: "Observações / detalhes adicionais",
                        labelStyle: GoogleFonts.poppins(color: cor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.notes_rounded, color: cor),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: "Valor estimado (opcional)",
                        labelStyle: GoogleFonts.poppins(color: cor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.attach_money_rounded, color: cor),
                      ),
                      onChanged: (v) => valorEstimado = double.tryParse(v),
                    ),

                    const SizedBox(height: 24),

                    // === Botões ===
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Get.back(),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: cor.withValues(alpha: 0.5)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              "Cancelar",
                              style: GoogleFonts.poppins(
                                color: cor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.send_rounded, color: Colors.white),
                            label: Text(
                              "Enviar",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: cor,
                            ),
                            onPressed: () async {
                              final orcamento = OrcamentoModel(
                                idOrcamento: uuid.v4(),
                                idEvento: idEvento,
                                idServicoFornecido: servicoFornecedor.idFornecedorServico,
                                custoEstimado: valorEstimado ?? servicoFornecedor.preco,
                                anotacoes: anotacoesController.text,
                                orcamentoFechado: false,
                                status: StatusOrcamento.pendente,
                              );

                              await controller.criarOrcamento(orcamento);
                              Get.back();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    },
  );
}
