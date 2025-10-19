// ignore_for_file: use_build_context_synchronously

import 'package:app_faca_festa/core/utils/biblioteca.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:get/get.dart';

import './../../controllers/event_theme_controller.dart';
import './../../controllers/fornecedor_controller.dart';
import './../../data/models/model.dart';

Future<void> showNovoOrcamentoBottomSheet({
  required BuildContext context,
  required String idEvento,
  required String idFornecedor,
  required FornecedorProdutoServicoModel servico,
  required StatusOrcamento statusInicial,
  String? idOrcamento,
}) async {
  final uuid = const Uuid();
  final db = FirebaseFirestore.instance;
  final fornecedorController = Get.find<FornecedorController>();
  final themeController = Get.find<EventThemeController>();

  final anotacoesController = TextEditingController();
  double? valorEstimado;
  DateTime? dataReserva;

  // 🔹 Verifica se é edição (reserva existente)
  OrcamentoModel? orcamentoExistente;
  if (idOrcamento != null) {
    final doc = await db.collection('orcamento').doc(idOrcamento).get();
    if (doc.exists) {
      orcamentoExistente = OrcamentoModel.fromMap(doc.data()!);
      anotacoesController.text = orcamentoExistente.anotacoes ?? '';
      valorEstimado = orcamentoExistente.custoEstimado;
    }
  }

  final isEdicao = orcamentoExistente != null;
  final String titulo = isEdicao ? "Reservar Fornecedor" : "Solicitar Orçamento";
  final String textoBotao = isEdicao ? "Confirmar Reserva" : "Enviar Solicitação";

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final gradient = themeController.gradient.value;
      final primary = themeController.primaryColor.value;
      final produtoServico =
          fornecedorController.catalogoServicos.firstWhere((s) => s.id == servico.idProdutoServico);
      final bool isCelular = Biblioteca.isCelular(context);
      return FractionallySizedBox(
        heightFactor: 0.92,
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(22),
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // === CABEÇALHO ===
                          Center(
                            child: Column(
                              children: [
                                Icon(
                                  isEdicao
                                      ? Icons.event_available_rounded
                                      : Icons.request_quote_rounded,
                                  color: primary,
                                  size: 48,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  titulo,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  produtoServico.nome,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // === CAMPO DE MENSAGEM ===
                          TextField(
                            controller: anotacoesController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: "Mensagem ao fornecedor",
                              hintText:
                                  "Ex: Olá! Gostaria de saber mais sobre esse serviço e disponibilidade.",
                              labelStyle: GoogleFonts.poppins(color: primary),
                              prefixIcon: Icon(Icons.message_rounded, color: primary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // === CAMPO DE VALOR ESTIMADO ===
                          TextField(
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            controller: TextEditingController(
                              text: valorEstimado?.toStringAsFixed(2) ?? '',
                            ),
                            decoration: InputDecoration(
                              labelText: "Valor estimado (opcional)",
                              labelStyle: GoogleFonts.poppins(color: primary),
                              prefixIcon: Icon(Icons.attach_money_rounded, color: primary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onChanged: (v) =>
                                valorEstimado = double.tryParse(v.replaceAll(',', '.')),
                          ),

                          const SizedBox(height: 16),

                          // === DATA DE RESERVA (apenas se for reserva) ===
                          if (isEdicao) ...[
                            GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2100),
                                  builder: (context, child) {
                                    return Theme(
                                      data: ThemeData.light().copyWith(
                                        colorScheme: ColorScheme.light(
                                          primary: primary,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  setState(() => dataReserva = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  border: Border.all(color: primary.withValues(alpha: 0.4)),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(Icons.calendar_month_rounded, color: primary),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              dataReserva == null
                                                  ? "Informe data da reserva"
                                                  : DateFormat('dd/MM/yyyy').format(dataReserva!),
                                              style: GoogleFonts.poppins(
                                                fontSize: 15,
                                                color: Colors.grey.shade800,
                                              ),
                                              overflow:
                                                  TextOverflow.ellipsis, // evita quebrar a linha
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.expand_more, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // === BOTÕES ===

                          if (isCelular)
                            // 📱 CELULAR → Botões empilhados (um abaixo do outro)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                OutlinedButton(
                                  onPressed: () => Get.back(),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: primary.withValues(alpha: 0.5)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  child: Text(
                                    "Cancelar",
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      color: primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    if (isEdicao) {
                                      // === Atualiza reserva ===
                                      await db.collection('orcamento').doc(idOrcamento).update({
                                        'anotacoes': anotacoesController.text,
                                        'custo_estimado': valorEstimado,
                                        'data_reserva': dataReserva != null
                                            ? Timestamp.fromDate(dataReserva!)
                                            : null,
                                        'status': statusInicial.firestoreValue,
                                        'data_fechamento': Timestamp.fromDate(DateTime.now()),
                                      });

                                      Get.back();
                                      Get.snackbar(
                                        "Reserva confirmada",
                                        "O fornecedor foi notificado.",
                                        backgroundColor: primary,
                                        colorText: Colors.white,
                                      );
                                    } else {
                                      // === Cria novo orçamento ===
                                      final model = OrcamentoModel(
                                        idOrcamento: uuid.v4(),
                                        idEvento: idEvento,
                                        idServicoFornecido: servico.idProdutoServico,
                                        custoEstimado: valorEstimado ?? servico.preco,
                                        anotacoes: anotacoesController.text,
                                        orcamentoFechado: false,
                                        status: statusInicial,
                                      );

                                      await db
                                          .collection('orcamento')
                                          .doc(model.idOrcamento)
                                          .set(model.toMap());

                                      Get.back();
                                      Get.snackbar(
                                        "Solicitação enviada",
                                        "O fornecedor será notificado 💌",
                                        backgroundColor: primary,
                                        colorText: Colors.white,
                                      );
                                    }
                                  },
                                  icon: Icon(
                                    isEdicao ? Icons.event_available_rounded : Icons.send_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  label: Text(
                                    textoBotao,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else
                            // 💻 TABLET OU DESKTOP → Botões lado a lado
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Get.back(),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: primary.withValues(alpha: 0.5)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                    child: Text(
                                      "Cancelar",
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        color: primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      if (isEdicao) {
                                        // === Atualiza reserva ===
                                        await db.collection('orcamento').doc(idOrcamento).update({
                                          'anotacoes': anotacoesController.text,
                                          'custo_estimado': valorEstimado,
                                          'data_reserva': dataReserva != null
                                              ? Timestamp.fromDate(dataReserva!)
                                              : null,
                                          'status': statusInicial.firestoreValue,
                                          'data_fechamento': Timestamp.fromDate(DateTime.now()),
                                        });

                                        Get.back();
                                        Get.snackbar(
                                          "Reserva confirmada",
                                          "O fornecedor foi notificado.",
                                          backgroundColor: primary,
                                          colorText: Colors.white,
                                        );
                                      } else {
                                        // === Cria novo orçamento ===
                                        final model = OrcamentoModel(
                                          idOrcamento: uuid.v4(),
                                          idEvento: idEvento,
                                          idServicoFornecido: servico.idProdutoServico,
                                          custoEstimado: valorEstimado ?? servico.preco,
                                          anotacoes: anotacoesController.text,
                                          orcamentoFechado: false,
                                          status: statusInicial,
                                        );

                                        await db
                                            .collection('orcamento')
                                            .doc(model.idOrcamento)
                                            .set(model.toMap());

                                        Get.back();
                                        Get.snackbar(
                                          "Solicitação enviada",
                                          "O fornecedor será notificado 💌",
                                          backgroundColor: primary,
                                          colorText: Colors.white,
                                        );
                                      }
                                    },
                                    icon: Icon(
                                      isEdicao ? Icons.event_available_rounded : Icons.send_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    label: Text(
                                      textoBotao,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        fontSize: 15,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primary,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
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
            ),
          ),
        ),
      );
    },
  );
}
