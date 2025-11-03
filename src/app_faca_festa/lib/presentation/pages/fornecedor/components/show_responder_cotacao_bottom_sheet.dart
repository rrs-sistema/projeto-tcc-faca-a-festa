import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../controllers/tema/event_theme_controller.dart';
import './../../../../controllers/fornecedor_controller.dart';

Future<void> showResponderCotacaoBottomSheet({
  required BuildContext context,
  required String nomeSolicitante,
  required String idCotacao,
  required String categoriaNome,
  required String descricao,
}) async {
  final theme = Get.find<EventThemeController>();
  final gradient = theme.gradient.value;
  final primary = theme.primaryColor.value;

  final prazoEntregaSelecionado = Rxn<DateTime>();
  final condicaoController = TextEditingController();
  final observacaoController = TextEditingController();
  final carregando = false.obs;

  await Get.bottomSheet(
    Obx(
      () => AbsorbPointer(
        absorbing: carregando.value,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === Handle bar ===
                  Center(
                    child: Container(
                      width: 60,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),

                  // === Cabeçalho ===
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoriaNome,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          descricao.isNotEmpty ? descricao : 'Sem descrição adicional.',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // 👇 Novo trecho: nome do organizador
                        Row(
                          children: [
                            Icon(Icons.person_rounded,
                                color: Colors.white.withValues(alpha: 0.9), size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Solicitado por: $nomeSolicitante',
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  _buildLabel("Prazo de Entrega até"),

                  Obx(() => GestureDetector(
                        onTap: () async {
                          final hoje = DateTime.now();
                          final limite = hoje.add(const Duration(days: 180));

                          // ✅ Usa o contexto global do GetX (nunca quebra)
                          final selecionada = await showDatePicker(
                            context: Get.context!,
                            initialDate: hoje,
                            firstDate: hoje,
                            lastDate: limite,
                            locale: const Locale('pt', 'BR'),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: primary,
                                    onPrimary: Colors.white,
                                    onSurface: Colors.black87,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );

                          if (selecionada != null) {
                            prazoEntregaSelecionado.value = selecionada;
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(14),
                            color: Colors.grey.shade50,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                prazoEntregaSelecionado.value != null
                                    ? 'Você selecionou o prazo para: ${DateFormat("dd/MM/yyyy").format(prazoEntregaSelecionado.value!)}'
                                    : 'Selecione uma data',
                                style: GoogleFonts.poppins(
                                  color: prazoEntregaSelecionado.value != null
                                      ? Colors.black87
                                      : Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              Icon(Icons.calendar_today_rounded, color: primary, size: 20),
                            ],
                          ),
                        ),
                      )),

                  _buildLabel("Condição de Pagamento"),
                  TextField(
                    controller: condicaoController,
                    decoration: InputDecoration(
                      hintText: "Ex: 50% na reserva e 50% na entrega",
                      prefixIcon: Icon(Icons.payments_outlined, color: primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 14),

                  _buildLabel("Observações (opcional)"),
                  TextField(
                    controller: observacaoController,
                    decoration: InputDecoration(
                      hintText: "Informações adicionais sobre a proposta...",
                      prefixIcon: Icon(Icons.edit_note_rounded, color: primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    minLines: 3,
                    maxLines: 4,
                  ),

                  const SizedBox(height: 22),

                  // === Botões de ação ===
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: carregando.value
                              ? null
                              : () {
                                  if (prazoEntregaSelecionado.value == null) {
                                    Get.snackbar(
                                      'Campo obrigatório',
                                      'Por favor, selecione o prazo de entrega.',
                                      backgroundColor: Colors.orange.shade100,
                                      colorText: Colors.black87,
                                    );
                                    return;
                                  }
                                  _enviarResposta(
                                    aceitou: true,
                                    idCotacao: idCotacao,
                                    prazo: prazoEntregaSelecionado.value ?? DateTime.now(),
                                    condicao: condicaoController.text,
                                    observacao: observacaoController.text,
                                    carregando: carregando,
                                  );
                                },
                          icon: const Icon(Icons.send_rounded),
                          label: const Text("Responder"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: carregando.value
                              ? null
                              : () {
                                  if (prazoEntregaSelecionado.value == null) {
                                    Get.snackbar(
                                      'Campo obrigatório',
                                      'Por favor, selecione o prazo de entrega.',
                                      backgroundColor: Colors.orange.shade100,
                                      colorText: Colors.black87,
                                    );
                                    return;
                                  }
                                  _enviarResposta(
                                    aceitou: false,
                                    idCotacao: idCotacao,
                                    prazo: prazoEntregaSelecionado.value ?? DateTime.now(),
                                    condicao: condicaoController.text,
                                    observacao: observacaoController.text,
                                    carregando: carregando,
                                  );
                                },
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text("Recusar"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            side: BorderSide(color: Colors.red.shade400),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (carregando.value) ...[
                    const SizedBox(height: 20),
                    const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ],

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

Widget _buildLabel(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: Colors.grey.shade800,
      ),
    ),
  );
}

Future<void> _enviarResposta({
  required bool aceitou,
  required String idCotacao,
  required DateTime? prazo,
  required String condicao,
  required String observacao,
  required RxBool carregando,
}) async {
  final fornecedorController = Get.find<FornecedorController>();
  final idFornecedor = fornecedorController.fornecedor.value?.idFornecedor;
  if (idFornecedor == null) return;

  try {
    carregando.value = true;

    // 🔍 Busca o documento do fornecedor dentro da cotação
    final subSnap = await FirebaseFirestore.instance
        .collection('cotacao')
        .doc(idCotacao)
        .collection('fornecedores')
        .where('id_fornecedor', isEqualTo: idFornecedor)
        .limit(1)
        .get();

    if (subSnap.docs.isEmpty) {
      throw Exception('Documento do fornecedor não encontrado para esta cotação.');
    }

    final docId = subSnap.docs.first.id; // ID real (ex: acXSkFFd1GQJ0jnkHxZo)

    // 🔹 Atualiza os campos corretos
    await FirebaseFirestore.instance
        .collection('cotacao')
        .doc(idCotacao)
        .collection('fornecedores')
        .doc(docId)
        .update({
      'status': aceitou ? 'respondido' : 'recusado',
      'prazo_entrega': prazo != null ? Timestamp.fromDate(prazo) : null,
      'condicao_pagamento': condicao.trim(),
      'observacao_fornecedor': observacao.trim(),
      'data_resposta': Timestamp.now(),
    });

    Get.back();
    Get.snackbar(
      aceitou ? 'Resposta enviada' : 'Cotação recusada',
      aceitou ? 'Sua proposta foi enviada ao organizador.' : 'Você recusou esta solicitação.',
      backgroundColor: aceitou ? Colors.green.shade600 : Colors.red.shade400,
      colorText: Colors.white,
      icon: Icon(
        aceitou ? Icons.check_circle_outline : Icons.cancel_rounded,
        color: Colors.white,
      ),
      duration: const Duration(seconds: 3),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
    );
  } catch (e, s) {
    debugPrint('❌ Erro ao responder cotação: $e\n$s');
    Get.snackbar(
      'Erro',
      'Falha ao enviar a resposta. Tente novamente.',
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
    );
  } finally {
    carregando.value = false;
  }
}
