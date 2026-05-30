import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:get/get.dart';

import './../../../controllers/tema/event_theme_controller.dart';
import './../../../controllers/gift/gift_controller.dart';
import './../../../data/models/gift/gift_model.dart';
import './../../../app/bindings/gift_binding.dart';
import './../../../domain/entities/gift/gift.dart';

void abrirDialogCadastrarPresente(
  BuildContext context, {
  GiftModel? presente,
}) {
  GiftBinding().dependencies();

  final themeController = Get.find<EventThemeController>();
  final controller = Get.find<GiftController>();

  final uuid = const Uuid();
  final bool editando = presente != null;

  final nomeCtrl = TextEditingController(text: presente?.nome ?? '');
  final descricaoCtrl = TextEditingController(text: presente?.descricao ?? '');
  final valorCtrl = TextEditingController(text: presente?.valor?.toString() ?? '');
  final lojaCtrl = TextEditingController(text: presente?.loja ?? '');
  final linkCtrl = TextEditingController(text: presente?.link ?? '');
  final pixCtrl = TextEditingController(text: presente?.pix ?? '');
  final metaCtrl = TextEditingController(text: presente?.metaValor?.toString() ?? '');
  final imagemCtrl = TextEditingController(text: presente?.imagem ?? '');

  final Rx<GiftType> tipoSelecionado = (presente?.tipo ?? GiftType.fisico).obs;
  final RxBool salvando = false.obs;
  final RxString urlPreview = (presente?.imagem ?? '').obs;

  final primary = themeController.primaryColor.value;
  final gradient = themeController.gradient.value;

  const background = Color(0xFFF8FAFC);
  const textDark = Color(0xFF1F2937);
  const textMuted = Color(0xFF64748B);

  imagemCtrl.addListener(() => urlPreview.value = imagemCtrl.text.trim());

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

  Future<void> salvar(BuildContext modalContext) async {
    if (salvando.value) return;

    if (nomeCtrl.text.trim().isEmpty) {
      showSnack(title: "Erro", message: "Nome é obrigatório", color: Colors.redAccent);
      return;
    }

    salvando.value = true;
    try {
      final double valor = tipoSelecionado.value == GiftType.fisico
          ? 0.0
          : (double.tryParse(valorCtrl.text.replaceAll(',', '.')) ?? 0.0);
      final double meta = double.tryParse(metaCtrl.text.replaceAll(',', '.')) ?? 0.0;

      final model = GiftModel(
        id: editando ? presente.id : uuid.v4(),
        nome: nomeCtrl.text.trim(),
        descricao: descricaoCtrl.text.trim(),
        tipo: tipoSelecionado.value,
        valor: valor,
        loja: lojaCtrl.text.trim(),
        link: linkCtrl.text.trim(),
        pix: pixCtrl.text.trim(),
        metaValor: meta,
        imagem: imagemCtrl.text.trim(),
        categoria: presente?.categoria ?? "geral",
        status: presente?.status ?? GiftStatus.disponivel,
        createdAt: presente?.createdAt ?? DateTime.now(),
      );

      editando ? await controller.atualizarPresente(model) : await controller.criarPresente(model);

      FocusManager.instance.primaryFocus?.unfocus();
      if (modalContext.mounted) {
        Navigator.of(modalContext).pop();
      }

      showSnack(
          title: "Sucesso", message: editando ? "Atualizado!" : "Adicionado!", color: primary);
    } catch (e, s) {
      debugPrint('❌ Erro ao salvar presente: $e');
      debugPrintStack(stackTrace: s);

      showSnack(
        title: "Erro",
        message: "Erro ao salvar presente. Verifique o console.",
        color: Colors.redAccent,
      );
    } finally {
      salvando.value = false;
    }
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: GoogleFonts.poppins(color: textDark, fontSize: 12, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle:
              GoogleFonts.poppins(color: textMuted, fontSize: 11, fontWeight: FontWeight.w500),
          prefixIcon: Column(
            mainAxisAlignment: maxLines > 1 ? MainAxisAlignment.start : MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                  padding: EdgeInsets.only(top: maxLines > 1 ? 12.0 : 0),
                  child: Icon(icon, color: primary, size: 18)),
            ],
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primary, width: 1.2)),
        ),
      ),
    );
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
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
              color: background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // === HEADER COMPACTO ===
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(gradient: gradient),
                  child: Column(
                    children: [
                      Center(
                          child: Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(10)))),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12)),
                            child: Icon(
                                editando
                                    ? Icons.edit_note_rounded
                                    : Icons.add_shopping_cart_rounded,
                                color: Colors.white,
                                size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(editando ? 'Editar Presente' : 'Novo Presente',
                                    style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800)),
                                Text('Preencha os detalhes para a lista.',
                                    style: GoogleFonts.poppins(
                                        color: Colors.white.withValues(alpha: 0.9), fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // === CORPO ===
                Expanded(
                  child: ListView(
                    controller: controllerScroll,
                    padding: EdgeInsets.fromLTRB(
                        16, 16, 16, MediaQuery.of(modalContext).viewInsets.bottom + 16),
                    children: [
                      // Preview Imagem
                      Obx(() {
                        final hasUrl = urlPreview.value.isNotEmpty;
                        return Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2))
                              ],
                            ),
                            child: hasUrl
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.network(urlPreview.value,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            Icon(Icons.broken_image, color: Colors.grey.shade400)))
                                : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    Icon(Icons.add_a_photo_outlined,
                                        color: Colors.grey.shade400, size: 24),
                                    const SizedBox(height: 4),
                                    Text("Sem Foto",
                                        style: GoogleFonts.poppins(
                                            color: Colors.grey.shade500, fontSize: 9))
                                  ]),
                          ),
                        );
                      }),

                      // Chips Tipo
                      Text("Formato do presente",
                          style: GoogleFonts.poppins(
                              color: textDark, fontWeight: FontWeight.w700, fontSize: 12)),
                      const SizedBox(height: 8),
                      Obx(() => Row(
                            children: GiftType.values.map((tipo) {
                              final isSelected = tipoSelecionado.value == tipo;
                              IconData icone = tipo == GiftType.fisico
                                  ? Icons.inventory_2_outlined
                                  : (tipo == GiftType.pix ? Icons.pix : Icons.groups_outlined);
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: InkWell(
                                    onTap: () => tipoSelecionado.value = tipo,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected ? primary : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: isSelected ? primary : Colors.grey.shade300),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(icone,
                                              size: 14,
                                              color: isSelected ? Colors.white : textMuted),
                                          const SizedBox(width: 4),
                                          Text(tipo.name.capitalizeFirst!,
                                              style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  color: isSelected ? Colors.white : textDark,
                                                  fontWeight: isSelected
                                                      ? FontWeight.w700
                                                      : FontWeight.w500)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          )),

                      const SizedBox(height: 16),

                      buildTextField(
                          label: "Nome do presente",
                          icon: Icons.redeem_rounded,
                          controller: nomeCtrl),
                      buildTextField(
                          label: "Descrição curta",
                          icon: Icons.short_text_rounded,
                          controller: descricaoCtrl,
                          maxLines: 2),

                      Obx(() => Column(
                            children: [
                              if (tipoSelecionado.value == GiftType.fisico)
                                buildTextField(
                                    label: "URL da Foto do Produto",
                                    icon: Icons.image_search_rounded,
                                    controller: imagemCtrl),
                              if (tipoSelecionado.value != GiftType.fisico)
                                buildTextField(
                                    label: "Valor sugerido (R\$)",
                                    icon: Icons.attach_money_rounded,
                                    controller: valorCtrl,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(decimal: true)),
                              if (tipoSelecionado.value == GiftType.fisico) ...[
                                buildTextField(
                                    label: "Nome da Loja",
                                    icon: Icons.storefront_rounded,
                                    controller: lojaCtrl),
                                buildTextField(
                                    label: "Link para Compra",
                                    icon: Icons.shopping_cart_checkout_rounded,
                                    controller: linkCtrl),
                              ],
                              if (tipoSelecionado.value != GiftType.fisico)
                                buildTextField(
                                    label: "Chave PIX",
                                    icon: Icons.key_rounded,
                                    controller: pixCtrl),
                              if (tipoSelecionado.value == GiftType.coletivo)
                                buildTextField(
                                    label: "Meta (R\$)",
                                    icon: Icons.flag_outlined,
                                    controller: metaCtrl,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(decimal: true)),
                            ],
                          )),

                      const SizedBox(height: 20),

                      // Botões
                      Obx(() {
                        final isSaving = salvando.value;
                        return SizedBox(
                          height: 42,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12))),
                            onPressed: isSaving ? null : () => salvar(modalContext),
                            icon: isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                            label: Text(isSaving ? "Salvando..." : "Confirmar",
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 42,
                        child: TextButton(
                          onPressed: () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            Navigator.of(modalContext).pop();
                          },
                          style: TextButton.styleFrom(
                              shape:
                                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: Text("Cancelar",
                              style: GoogleFonts.poppins(
                                  color: textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ),
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
}
