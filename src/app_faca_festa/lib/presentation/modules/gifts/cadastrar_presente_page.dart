import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:get/get.dart';

import './../../../controllers/tema/event_theme_controller.dart';
import './../../../controllers/gift/gift_controller.dart';
import './../../../data/models/gift/gift_model.dart';
import './../../../app/bindings/gift_binding.dart';
import './../../../domain/entities/gift/gift.dart';
import './../../widgets/custom_input_field.dart';

void abrirDialogCadastrarPresente(
  BuildContext context, {
  GiftModel? presente,
}) {
  GiftBinding().dependencies();

  final themeController = Get.find<EventThemeController>();
  final controller = Get.find<GiftController>();

  final uuid = const Uuid();
  final bool editando = presente != null;

  // CONTROLADORES
  final nomeCtrl = TextEditingController(text: presente?.nome ?? '');
  final descricaoCtrl = TextEditingController(text: presente?.descricao ?? '');
  final valorCtrl = TextEditingController(text: presente?.valor?.toString() ?? '');
  final lojaCtrl = TextEditingController(text: presente?.loja ?? '');
  final linkCtrl = TextEditingController(text: presente?.link ?? '');
  final pixCtrl = TextEditingController(text: presente?.pix ?? '');
  final metaCtrl = TextEditingController(text: presente?.metaValor?.toString() ?? '');
  // 🔹 Novo controlador para imagem
  final imagemCtrl = TextEditingController(text: presente?.imagem ?? '');

  final Rx<GiftType> tipoSelecionado = (presente?.tipo ?? GiftType.fisico).obs;
  final RxBool salvando = false.obs;
  // 🔹 Rx para atualizar o preview da imagem em tempo real
  final RxString urlPreview = (presente?.imagem ?? '').obs;

  final gradient = themeController.gradient.value;
  final primary = themeController.primaryColor.value;

  // Listener para o preview
  imagemCtrl.addListener(() => urlPreview.value = imagemCtrl.text.trim());

  Future<void> salvar() async {
    if (nomeCtrl.text.trim().isEmpty) {
      Get.snackbar("Erro", "Nome é obrigatório",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
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
        imagem: imagemCtrl.text.trim(), // 🔹 Salvando o campo imagem separado
        categoria: presente?.categoria ?? "geral",
        status: presente?.status ?? GiftStatus.disponivel,
        createdAt: presente?.createdAt ?? DateTime.now(),
      );

      editando ? await controller.atualizarPresente(model) : await controller.criarPresente(model);

      Get.back();
      Get.snackbar("Sucesso", editando ? "Atualizado!" : "Adicionado!",
          backgroundColor: primary, colorText: Colors.white);
    } finally {
      salvando.value = false;
    }
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 28,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(editando),
                        const SizedBox(height: 24),

                        // PREVIEW DA IMAGEM (Sênior Touch)
                        _buildImagePreview(urlPreview, primary),

                        const SizedBox(height: 24),
                        _buildTypeChips(tipoSelecionado, primary),
                        const SizedBox(height: 24),

                        CustomInputField(
                            label: "Nome do presente",
                            icon: Icons.redeem,
                            controller: nomeCtrl,
                            color: Colors.white),

                        Obx(() => AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              child: Column(
                                children: [
                                  // Campo de Imagem sempre visível para presente físico
                                  if (tipoSelecionado.value == GiftType.fisico)
                                    CustomInputField(
                                      label: "URL da Foto do Produto",
                                      icon: Icons.image_search,
                                      controller: imagemCtrl,
                                      color: Colors.white,
                                      // hint: "Cole o link da imagem aqui"
                                    ),

                                  if (tipoSelecionado.value != GiftType.fisico)
                                    CustomInputField(
                                        label: "Valor sugerido (R\$)",
                                        icon: Icons.attach_money,
                                        controller: valorCtrl,
                                        color: Colors.white),

                                  if (tipoSelecionado.value == GiftType.fisico) ...[
                                    CustomInputField(
                                        label: "Nome da Loja (Ex: Amazon)",
                                        icon: Icons.storefront,
                                        controller: lojaCtrl,
                                        color: Colors.white),
                                    CustomInputField(
                                        label: "Link para Compra (Opcional)",
                                        icon: Icons.shopping_cart_checkout,
                                        controller: linkCtrl,
                                        color: Colors.white),
                                  ],

                                  if (tipoSelecionado.value != GiftType.fisico)
                                    CustomInputField(
                                        label: "Chave PIX",
                                        icon: Icons.key,
                                        controller: pixCtrl,
                                        color: Colors.white),

                                  if (tipoSelecionado.value == GiftType.coletivo)
                                    CustomInputField(
                                        label: "Meta de arrecadação (R\$)",
                                        icon: Icons.flag_outlined,
                                        controller: metaCtrl,
                                        color: Colors.white),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
                _buildButtons(salvando, salvar, primary),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// 🔹 HEADER DO DIÁLOGO
Widget _buildHeader(bool editando) {
  return Column(
    children: [
      Center(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            editando ? Icons.edit_note : Icons.add_shopping_cart,
            size: 36,
            color: Colors.white,
          ),
        ),
      ),
      const SizedBox(height: 12),
      Center(
        child: Text(
          editando ? "Editar Presente" : "Cadastrar Presente",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
      ),
    ],
  );
}

// 🔹 SELEÇÃO DE TIPOS (CHIPS)
Widget _buildTypeChips(Rx<GiftType> tipoSelecionado, Color primary) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "Formato do presente",
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      const SizedBox(height: 12),
      Obx(() => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: GiftType.values.map((tipo) {
                final bool isSelected = tipoSelecionado.value == tipo;
                IconData icone;
                switch (tipo) {
                  case GiftType.fisico:
                    icone = Icons.inventory_2_outlined;
                    break;
                  case GiftType.pix:
                    icone = Icons.pix;
                    break;
                  case GiftType.coletivo:
                    icone = Icons.groups_outlined;
                    break;
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icone, size: 16, color: isSelected ? primary : Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          tipo.name.capitalizeFirst ?? tipo.name,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: isSelected ? primary : Colors.white,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (_) => tipoSelecionado.value = tipo,
                    selectedColor: Colors.white,
                         backgroundColor: isSelected ? Colors.white : Colors.grey
                      ..withValues(alpha: 0.15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          )),
    ],
  );
}

// 🔹 BOTÕES DE AÇÃO (SALVAR E CANCELAR)
Widget _buildButtons(RxBool salvando, Future<void> Function() onSalvar, Color primary) {
  return Column(
    children: [
      const SizedBox(height: 16),
      Obx(() => SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: salvando.value ? null : onSalvar,
              label: Text(
                salvando.value ? "Salvando..." : "Confirmar",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              icon: salvando.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check),
            ),
          )),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => Get.back(),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white54),
          ),
          child: const Text("Cancelar", style: TextStyle(color: Colors.white)),
        ),
      ),
    ],
  );
}

// 🔹 WIDGET DE PREVIEW DINÂMICO
Widget _buildImagePreview(RxString url, Color primary) {
  return Obx(() {
    final hasUrl = url.value.isNotEmpty;
    return Center(
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: hasUrl
            ? ClipRRect(
                borderRadius: BorderRadius.circular(19),
                child: Image.network(
                  url.value,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image, color: Colors.white54, size: 40),
                ),
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, color: Colors.white54, size: 32),
                  SizedBox(height: 8),
                  Text("Sem Foto", style: TextStyle(color: Colors.white54, fontSize: 10)),
                ],
              ),
      ),
    );
  });
}
