import 'package:app_faca_festa/presentation/widgets/button/botao_cancelar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

import '../../../../data/models/model.dart';
import './../../../../controllers/tema/event_theme_controller.dart';
import './../../../../controllers/fornecedor_controller.dart';

Future<void> showResponderCotacaoBottomSheet({
  required BuildContext context,
  required String nomeSolicitante,
  required String idCotacao,
  required String categoriaNome,
  required String descricao,
  required String dataLimite,
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
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              child: Column(
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
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.22),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Ícone grande do tema
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  width: 1.4,
                                ),
                              ),
                              child: Icon(
                                theme.icon.value,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),

                            const SizedBox(width: 14),

                            // Títulos e textos
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    categoriaNome,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                      color: Colors.white,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    descricao.isNotEmpty ? descricao : "Sem descrição adicional.",
                                    style: GoogleFonts.poppins(
                                      fontSize: 13.4,
                                      height: 1.42,
                                      color: Colors.white.withValues(alpha: 0.92),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Chip "Data" à esquerda e "Solicitado por" à direita
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.26),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // 🍀 Lado ESQUERDO (DATA)
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded,
                                      size: 16, color: Colors.white),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Data limite: $dataLimite',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13.2,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),

                              // 🍀 Lado DIREITO (SOLICITANTE)
                              Row(
                                children: [
                                  const Icon(Icons.person_rounded, size: 18, color: Colors.white),
                                  const SizedBox(width: 6),

                                  // Nome bem encostado na direita
                                  Text(
                                    'Solicitante: $nomeSolicitante',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13.2,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // === ITENS DA COTAÇÃO ===
                  _buildLabel("Itens solicitados", primary),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('cotacao')
                        .doc(idCotacao)
                        .collection('fornecedores')
                        .doc(Get.find<FornecedorController>().fornecedor.value?.idFornecedor ?? '0')
                        .collection('servicos')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            "Nenhum item de serviço associado a esta cotação.",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        );
                      }

                      final servicos = snapshot.data!.docs;

                      return Column(
                        children: servicos.map((s) {
                          final d = s.data() as Map<String, dynamic>;
                          final nome = d['nome_produto_servico'] ?? 'Serviço';
                          final qtd = d['quantidade'] ?? 1;
                          final valor = (d['valor_estimado'] ?? 0) as num;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    "$nome (x$qtd)",
                                    style: GoogleFonts.poppins(
                                      fontSize: 13.5,
                                      color: Colors.grey.shade800,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  "R\$ ${(valor * qtd).toStringAsFixed(2)}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // === Prazo ===
                  _buildLabel("Prazo de Entrega até", primary),
                  GestureDetector(
                    onTap: () async {
                      final hoje = DateTime.now();
                      final limite = hoje.add(const Duration(days: 180));

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
                    child: Obx(() => Container(
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
                              Flexible(
                                child: Text(
                                  prazoEntregaSelecionado.value != null
                                      ? 'Prazo: ${DateFormat("dd/MM/yyyy").format(prazoEntregaSelecionado.value!)}'
                                      : 'Selecione uma data',
                                  style: GoogleFonts.poppins(
                                    color: prazoEntregaSelecionado.value != null
                                        ? Colors.black87
                                        : Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(Icons.calendar_today_rounded, color: primary, size: 20),
                            ],
                          ),
                        )),
                  ),

                  const SizedBox(height: 16),

                  // === Condição ===
                  _buildLabel("Condição de Pagamento", primary),
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

                  const SizedBox(height: 16),

                  // === Observação ===
                  _buildLabel("Observações (opcional)", primary),
                  TextField(
                    controller: observacaoController,
                    decoration: InputDecoration(
                      hintText: "Detalhes adicionais da proposta...",
                      prefixIcon: Icon(Icons.chat_bubble_outline_rounded, color: primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    minLines: 3,
                    maxLines: 4,
                  ),

                  const SizedBox(height: 24),

                  // === Botões ===
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: carregando.value
                              ? null
                              : () {
                                  if (prazoEntregaSelecionado.value == null) {
                                    Get.snackbar(
                                        'Prazo obrigatório', 'Selecione o prazo de entrega.',
                                        backgroundColor: Colors.orange.shade100,
                                        colorText: Colors.black87);
                                    return;
                                  }

                                  _confirmarEnvio(
                                    context: context,
                                    onConfirmar: () {
                                      _enviarResposta(
                                        aceitou: true,
                                        idCotacao: idCotacao,
                                        prazo: prazoEntregaSelecionado.value ?? DateTime.now(),
                                        condicao: condicaoController.text,
                                        observacao: observacaoController.text,
                                        carregando: carregando,
                                      );
                                    },
                                  );
                                },
                          icon: const Icon(Icons.send_rounded),
                          label: const Text("Responder"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 3,
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
                                        'Prazo obrigatório', 'Selecione o prazo de entrega.',
                                        backgroundColor: Colors.orange.shade100,
                                        colorText: Colors.black87);
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

                  const SizedBox(height: 24),

                  BotaoCancelar(
                    corBackground: Colors.grey.shade700,
                    corPrincipal: primary,
                    texto: "Cancelar/Sair",
                    onPressed: () {
                      if (!carregando.value) {
                        Get.back();
                      }
                    },
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

Future<void> _confirmarEnvio({
  required BuildContext context,
  required VoidCallback onConfirmar,
}) async {
  if (!context.mounted) {
    context = Get.context!;
  }

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final primary = Theme.of(ctx).colorScheme.primary;

      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(Icons.help_outline_rounded, color: primary, size: 26),
            const SizedBox(width: 8),
            Text(
              "Confirmar envio",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 17,
              ),
            ),
          ],
        ),
        content: Text(
          "Deseja realmente enviar sua resposta para esta cotação?",
          style: GoogleFonts.poppins(fontSize: 14.5, color: Colors.grey.shade700),
        ),
        actionsPadding: const EdgeInsets.only(bottom: 8, right: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancelar",
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirmar();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              "Enviar",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    },
  );
}

/// === LABEL ESTILIZADO ===
Widget _buildLabel(String text, Color primary) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Container(
          width: 5,
          height: 18,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.grey.shade800,
          ),
        ),
      ],
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
    final db = FirebaseFirestore.instance;

    // 🔍 Busca o documento do fornecedor
    final subSnap = await db
        .collection('cotacao')
        .doc(idCotacao)
        .collection('fornecedores')
        .where('id_fornecedor', isEqualTo: idFornecedor)
        .limit(1)
        .get();

    if (subSnap.docs.isEmpty) throw Exception('Fornecedor não encontrado.');

    final docId = subSnap.docs.first.id;

    // 🔹 Atualiza o fornecedor atual
    await db.collection('cotacao').doc(idCotacao).collection('fornecedores').doc(docId).update({
      'status': aceitou
          ? StatusFornecedorCotacao.respondido.firestoreValue
          : StatusFornecedorCotacao.recusado.firestoreValue,
      'prazo_entrega': prazo != null ? Timestamp.fromDate(prazo) : null,
      'condicao_pagamento': condicao.trim(),
      'observacao_fornecedor': observacao.trim(),
      'data_resposta': Timestamp.now(),
    });

    // 🔍 Verifica se todos responderam
    final fornecedoresSnap =
        await db.collection('cotacao').doc(idCotacao).collection('fornecedores').get();

    final todosResponderam = fornecedoresSnap.docs.every((d) {
      final s = d['status'] ?? '';
      return s == 'respondido' || s == 'recusado';
    });

    if (todosResponderam) {
      await db.collection('cotacao').doc(idCotacao).update({
        'status': StatusCotacao.respondida.firestoreValue,
        'data_resposta_completa': Timestamp.now(),
      });
    }

    Get.back();
    Get.snackbar(
      aceitou ? 'Resposta enviada' : 'Cotação recusada',
      aceitou ? 'Sua proposta foi enviada ao organizador.' : 'Você recusou esta solicitação.',
      backgroundColor: aceitou ? Colors.green.shade600 : Colors.red.shade400,
      colorText: Colors.white,
      icon: Icon(aceitou ? Icons.check_circle_outline : Icons.cancel_rounded, color: Colors.white),
      duration: const Duration(seconds: 3),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
    );
  } catch (e, s) {
    debugPrint('❌ Erro ao responder cotação: $e\n$s');
    Get.snackbar('Erro', 'Falha ao enviar a resposta. Tente novamente.',
        backgroundColor: Colors.redAccent, colorText: Colors.white);
  } finally {
    carregando.value = false;
  }
}
