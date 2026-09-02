import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

import './../../../../data/models/cotacao/cotacao_chat_model.dart';
import './../../../../domain/usecases/gerenciar_cotacoes.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import './../../../../core/utils/biblioteca.dart';
import './../../../../core/utils/form_validators.dart';

Future<void> showResponderCotacaoBottomSheet({
  required BuildContext context,
  required String nomeSolicitante,
  required String idCotacao,
  required String categoriaNome,
  required String descricao,
  required String dataLimite,
  required double ofertaDesejada,
}) async {
  final theme = Get.find<EventThemeController>();
  final gradient = theme.gradient.value;
  final primary = theme.primaryColor.value;

  final prazoEntregaSelecionado = Rxn<DateTime>();
  final condicaoController = TextEditingController();
  final observacaoController = TextEditingController();
  final carregando = false.obs;
  final formKey = GlobalKey<FormState>();
  var autovalidateMode = AutovalidateMode.disabled;

  await Get.bottomSheet(
    StatefulBuilder(
      builder: (modalContext, setModalState) {
        bool validarFormulario() {
          setModalState(() {
            autovalidateMode = AutovalidateMode.onUserInteraction;
          });
          return formKey.currentState?.validate() ?? false;
        }

        return Obx(
          () => AbsorbPointer(
            absorbing: carregando.value,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: SafeArea(
                top: false,
                child: Form(
                  key: formKey,
                  autovalidateMode: autovalidateMode,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 20),
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
                                      color:
                                          Colors.white.withValues(alpha: 0.20),
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.35),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                          descricao.isNotEmpty
                                              ? descricao
                                              : "Sem descrição adicional.",
                                          style: GoogleFonts.poppins(
                                            fontSize: 13.4,
                                            height: 1.42,
                                            color: Colors.white
                                                .withValues(alpha: 0.92),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0.18),
                                      Colors.white.withValues(alpha: 0.05),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.28),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    // 🎯 Ícone moderno
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.20),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.attach_money_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),

                                    const SizedBox(width: 10),

                                    // 📝 Texto e valor destacados
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Oferta desejada",
                                            style: GoogleFonts.poppins(
                                              fontSize: 11.5,
                                              color: Colors.white
                                                  .withValues(alpha: 0.95),
                                              fontWeight: FontWeight.w400,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                          Text(
                                            "R\$ ${Biblioteca.formatarValorDecimal(ofertaDesejada)}",
                                            style: GoogleFonts.poppins(
                                              fontSize: 14.5,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Chip "Data" à esquerda e "Solicitado por" à direita
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0.18),
                                      Colors.white.withValues(alpha: 0.05),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.28),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // 🔵 Lado ESQUERDO — Data limite
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.20),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.calendar_today_rounded,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Data limite",
                                              style: GoogleFonts.poppins(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w400,
                                                color: Colors.white
                                                    .withValues(alpha: 0.95),
                                              ),
                                            ),
                                            Text(
                                              dataLimite, // ← formate antes com DateFormat
                                              style: GoogleFonts.poppins(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    // 🔵 Lado DIREITO — Solicitante
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.20),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.person_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Solicitante",
                                              style: GoogleFonts.poppins(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w400,
                                                color: Colors.white
                                                    .withValues(alpha: 0.95),
                                              ),
                                            ),
                                            Text(
                                              nomeSolicitante,
                                              style: GoogleFonts.poppins(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
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
                        StreamBuilder<List<CotacaoServicoResumoModel>>(
                          stream: Get.find<GerenciarCotacoes>()
                              .observarServicosFornecedorCotacao(
                            idCotacao: idCotacao,
                            idFornecedor: Get.find<FornecedorController>()
                                    .fornecedor
                                    .value
                                    ?.idFornecedor ??
                                '0',
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            }

                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
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

                            final servicos = snapshot.data!;

                            return Column(
                              children: servicos.map((s) {
                                final nome = s.nome;
                                final qtd = s.quantidade;
                                final valor = s.valorEstimado;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    border: Border.all(
                                        color: Colors.grey
                                            .withValues(alpha: 0.15)),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                        _buildLabel("Prazo de entrega *", primary),
                        FormField<DateTime>(
                          initialValue: prazoEntregaSelecionado.value,
                          validator: (value) => FormValidators.selecao(value,
                              campo: 'o prazo de entrega'),
                          builder: (state) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    final hoje = DateTime.now();
                                    final limite =
                                        hoje.add(const Duration(days: 180));

                                    final selecionada = await showDatePicker(
                                      context: Get.context!,
                                      initialDate: state.value ?? hoje,
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
                                      prazoEntregaSelecionado.value =
                                          selecionada;
                                      state.didChange(selecionada);
                                    }
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 14),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: state.hasError
                                            ? Colors.redAccent
                                            : Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      color: Colors.grey.shade50,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            state.value != null
                                                ? 'Prazo: ${DateFormat("dd/MM/yyyy").format(state.value!)}'
                                                : 'Selecione uma data',
                                            style: GoogleFonts.poppins(
                                              color: state.value != null
                                                  ? Colors.black87
                                                  : Colors.grey.shade600,
                                              fontSize: 14,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Icon(Icons.calendar_today_rounded,
                                            color: primary, size: 20),
                                      ],
                                    ),
                                  ),
                                ),
                                if (state.hasError)
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(left: 12, top: 6),
                                    child: Text(
                                      state.errorText!,
                                      style: GoogleFonts.poppins(
                                        color: Colors.redAccent,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        // === Condição ===
                        _buildLabel(
                            "Condição de pagamento (opcional)", primary),
                        TextFormField(
                          controller: condicaoController,
                          validator: (value) => FormValidators.descricao(
                            value,
                            campo: 'a condição de pagamento',
                            obrigatorio: false,
                            minimo: 2,
                            maximo: 200,
                          ),
                          decoration: InputDecoration(
                            hintText: "Ex: 50% na reserva e 50% na entrega",
                            prefixIcon:
                                Icon(Icons.payments_outlined, color: primary),
                            errorMaxLines: 2,
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
                        TextFormField(
                          controller: observacaoController,
                          validator: (value) => FormValidators.descricao(
                            value,
                            campo: 'as observações',
                            obrigatorio: false,
                          ),
                          decoration: InputDecoration(
                            hintText: "Detalhes adicionais da proposta...",
                            prefixIcon: Icon(Icons.chat_bubble_outline_rounded,
                                color: primary),
                            errorMaxLines: 2,
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
                                        if (!validarFormulario()) return;

                                        _confirmarEnvio(
                                          context: context,
                                          onConfirmar: () {
                                            _enviarResposta(
                                              aceitou: true,
                                              idCotacao: idCotacao,
                                              prazo: prazoEntregaSelecionado
                                                      .value ??
                                                  DateTime.now(),
                                              condicao: condicaoController.text,
                                              observacao:
                                                  observacaoController.text,
                                              carregando: carregando,
                                            );
                                          },
                                        );
                                      },
                                icon: const Icon(Icons.send_rounded,
                                    color: Colors.white),
                                label: const Text(
                                  "Responder",
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
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
                                        if (!validarFormulario()) return;
                                        _enviarResposta(
                                          aceitou: false,
                                          idCotacao: idCotacao,
                                          prazo:
                                              prazoEntregaSelecionado.value ??
                                                  DateTime.now(),
                                          condicao: condicaoController.text,
                                          observacao: observacaoController.text,
                                          carregando: carregando,
                                        );
                                      },
                                icon: Icon(Icons.cancel_outlined,
                                    color: Colors.red.shade700),
                                label: Text(
                                  "Recusar",
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red.shade700,
                                  side: BorderSide(color: Colors.red.shade400),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => Get.back(),
                                icon: const Icon(Icons.cancel_outlined,
                                    color: Colors.grey),
                                label: const Text(
                                  "Sair",
                                  style: TextStyle(color: Colors.grey),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey.shade700,
                                  side: BorderSide(color: Colors.grey.shade400),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (carregando.value) ...[
                          const SizedBox(height: 20),
                          const Center(
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        ],

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
    isScrollControlled: true,
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
          style:
              GoogleFonts.poppins(fontSize: 14.5, color: Colors.grey.shade700),
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

    await Get.find<GerenciarCotacoes>().responderCotacao(
      idCotacao: idCotacao,
      aceitou: aceitou,
      prazoEntrega: prazo,
      condicaoPagamento: condicao.trim(),
      observacaoFornecedor: observacao.trim(),
    );

    Get.back();
    Get.snackbar(
      aceitou ? 'Resposta enviada' : 'Cotação recusada',
      aceitou
          ? 'Sua proposta foi enviada ao organizador.'
          : 'Você recusou esta solicitação.',
      backgroundColor: aceitou ? Colors.green.shade600 : Colors.red.shade400,
      colorText: Colors.white,
      icon: Icon(aceitou ? Icons.check_circle_outline : Icons.cancel_rounded,
          color: Colors.white),
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
