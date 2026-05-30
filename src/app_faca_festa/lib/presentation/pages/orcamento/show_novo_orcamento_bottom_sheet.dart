import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../../controllers/tema/event_theme_controller.dart';
import '../../../controllers/orcamento_controller.dart';
import '../../../core/utils/biblioteca.dart';
import '../../../data/models/model.dart';

Future<void> showNovoOrcamentoBottomSheet({
  required BuildContext context,
  required String idEvento,
  required String idFornecedor,
  required ServicoProdutoModel servicoProduto,
  required FornecedorProdutoServicoModel servicoFornecedor,
}) async {
  final themeController = Get.find<EventThemeController>();
  final orcamentoController = Get.find<OrcamentoController>();

  final uuid = const Uuid();
  final RxBool salvando = false.obs;

  final anotacoesCtrl = TextEditingController();
  final valorEstimadoCtrl = TextEditingController();

  final primary = themeController.primaryColor.value;
  final gradient = themeController.gradient.value;

  // Cores exatas do seu modelo
  const background = Color(0xFFF8FAFC);
  const textDark = Color(0xFF1F2937);
  const textMuted = Color(0xFF64748B);

  void showSnack({required String title, required String message, required Color color}) {
    Get.snackbar(
      title,
      message,
      backgroundColor: color,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      icon: Icon(
        color == Colors.redAccent
            ? Icons.error_outline_rounded
            : Icons.check_circle_outline_rounded,
        color: Colors.white,
      ),
    );
  }

  Future<void> salvarOrcamento(BuildContext modalContext) async {
    if (salvando.value) return;

    try {
      salvando.value = true;

      final valorDigitado = Biblioteca.toDouble(valorEstimadoCtrl.text);
      final precoBase = servicoFornecedor.precoPromocao ?? servicoFornecedor.preco;
      final valorFinal = valorDigitado > 0 ? valorDigitado : precoBase;

      final orcamento = OrcamentoModel(
        idOrcamento: uuid.v4(),
        idEvento: idEvento,
        idServicoFornecido: servicoFornecedor.id,
        custoEstimado: valorFinal,
        anotacoes: anotacoesCtrl.text.trim(),
        orcamentoFechado: false,
        status: StatusOrcamento.pendente,
      );

      await orcamentoController.criarOrcamento(orcamento);

      FocusManager.instance.primaryFocus?.unfocus();
      if (modalContext.mounted) {
        Navigator.of(modalContext).pop();
      }

      showSnack(title: 'Orçamento solicitado', message: servicoProduto.nome, color: primary);
    } catch (e) {
      showSnack(title: 'Erro', message: 'Não foi possível solicitar: $e', color: Colors.redAccent);
    } finally {
      salvando.value = false;
    }
  }

  Widget buildDragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(999)),
      ),
    );
  }

  Widget buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildDragHandle(),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
                ),
                child: const Icon(
                  Icons.request_quote_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Solicitar orçamento',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          height: 1.1,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Preencha os detalhes para envio.',
                      style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 11,
                          height: 1.35,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildSectionTitle({required IconData icon, required String title, String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: primary, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        color: textDark, fontSize: 13, fontWeight: FontWeight.w800)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.poppins(
                          color: textMuted,
                          fontSize: 10,
                          height: 1.35,
                          fontWeight: FontWeight.w500)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputAction textInputAction = TextInputAction.next,
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        textInputAction: textInputAction,
        maxLines: maxLines,
        style: GoogleFonts.poppins(color: textDark, fontSize: 13, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle:
              GoogleFonts.poppins(color: textMuted, fontSize: 12, fontWeight: FontWeight.w500),
          hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 12),
          // Ajuste para o ícone não ficar no meio de campos com mais de uma linha
          prefixIcon: Column(
            mainAxisAlignment: maxLines > 1 ? MainAxisAlignment.start : MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.only(top: maxLines > 1 ? 16.0 : 0),
                child: Icon(icon, color: primary, size: 20),
              ),
            ],
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primary, width: 1.2)),
        ),
      ),
    );
  }

  // Card do serviço modelado perfeitamente com os "buildCareSwitch" do modelo
  Widget buildServiceCard() {
    final preco = servicoFornecedor.precoPromocao ?? servicoFornecedor.preco;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.inventory_2_outlined, color: primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  servicoProduto.nome,
                  style: GoogleFonts.poppins(
                      color: textDark, fontSize: 13, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  servicoProduto.descricao ?? 'Sem detalhes fornecidos.',
                  style: GoogleFonts.poppins(
                      color: textMuted, fontSize: 10, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Unid: ${servicoProduto.tipoMedida ?? 'N/A'}",
                      style: GoogleFonts.poppins(
                          color: textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      "R\$ ${preco.toStringAsFixed(2)}",
                      style: GoogleFonts.poppins(
                          color: primary, fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  try {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.60,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controllerScroll) {
            return Container(
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                  color: background, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              child: Column(
                children: [
                  buildHeader(),
                  Expanded(
                    child: ListView(
                      controller: controllerScroll,
                      padding: EdgeInsets.fromLTRB(
                          16, 16, 16, MediaQuery.of(modalContext).viewInsets.bottom + 16),
                      children: [
                        buildSectionTitle(
                          icon: Icons.info_outline_rounded,
                          title: 'Detalhes do Serviço',
                        ),
                        buildServiceCard(),
                        const SizedBox(height: 10),
                        buildSectionTitle(
                            icon: Icons.edit_note_rounded, title: 'Valores e Observações'),
                        buildTextField(
                          controller: anotacoesCtrl,
                          label: 'Observações / Detalhes adicionais',
                          icon: Icons.notes_outlined,
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: 3,
                          textInputAction: TextInputAction.newline,
                        ),
                        buildTextField(
                          controller: valorEstimadoCtrl,
                          label: 'Valor estimado (opcional)',
                          hint: 'Deixe em branco para usar o padrão',
                          icon: Icons.attach_money_rounded,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textInputAction: TextInputAction.done,
                        ),
                        const SizedBox(height: 20),
                        Obx(() {
                          final isSaving = salvando.value;
                          return SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  disabledBackgroundColor: primary.withValues(alpha: 0.45),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14))),
                              onPressed: isSaving ? null : () => salvarOrcamento(modalContext),
                              icon: isSaving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                              label: Text(isSaving ? 'Enviando...' : 'Solicitar',
                                  style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800)),
                            ),
                          );
                        }),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: TextButton.icon(
                            onPressed: () {
                              FocusManager.instance.primaryFocus?.unfocus();
                              Navigator.of(modalContext).pop();
                            },
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: Text('Cancelar',
                                style:
                                    GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13)),
                            style: TextButton.styleFrom(
                                foregroundColor: textMuted,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14))),
                          ),
                        ),
                        const SizedBox(height: 35),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  } finally {
    FocusManager.instance.primaryFocus?.unfocus();

    await Future<void>.delayed(Duration.zero);

    anotacoesCtrl.dispose();
    valorEstimadoCtrl.dispose();
  }
}
