// ignore_for_file: use_build_context_synchronously

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../../controllers/orcamento_controller.dart';
import './../../../../data/models/model.dart';

Future<void> showResponderOrcamentoDialog(
  BuildContext context, {
  required OrcamentoModel orcamento,
}) async {
  final controller = Get.find<OrcamentoController>();
  final valorController = TextEditingController(
    text: orcamento.custoEstimado?.toStringAsFixed(2) ?? '',
  );
  final anotacoesController = TextEditingController(text: orcamento.anotacoes ?? '');

  bool fecharOrcamento = false;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Cabeçalho
              Row(
                children: [
                  const Icon(Icons.request_quote_rounded, color: Colors.teal, size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Responder Orçamento",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 🔹 Campo valor proposto
              TextField(
                controller: valorController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Valor proposto (R\$)",
                  labelStyle: GoogleFonts.poppins(color: Colors.teal.shade800),
                  prefixIcon: const Icon(Icons.monetization_on, color: Colors.teal),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 🔹 Campo observações
              TextField(
                controller: anotacoesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Observações / Detalhes adicionais",
                  labelStyle: GoogleFonts.poppins(color: Colors.teal.shade800),
                  prefixIcon: const Icon(Icons.notes_rounded, color: Colors.teal),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 🔹 Checkbox para fechar orçamento
              StatefulBuilder(
                builder: (context, setState) {
                  return CheckboxListTile(
                    value: fecharOrcamento,
                    onChanged: (v) => setState(() => fecharOrcamento = v!),
                    title: Text(
                      "Marcar como fechado",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.teal.shade700,
                  );
                },
              ),

              const SizedBox(height: 16),

              // 🔹 Botões de ação
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Cancelar",
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final valor = double.tryParse(valorController.text) ?? 0;
                      await controller.responderOrcamento(
                        idOrcamento: orcamento.idOrcamento,
                        custoEstimado: valor,
                        anotacoes: anotacoesController.text,
                        fechar: fecharOrcamento,
                      );
                      Get.snackbar(
                        "Orçamento atualizado",
                        fecharOrcamento ? "Marcado como fechado" : "Resposta enviada com sucesso",
                        backgroundColor: Colors.teal.shade700,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 2),
                      );
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    label: Text(
                      "Enviar Resposta",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
