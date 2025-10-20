// ignore_for_file: use_build_context_synchronously

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../../data/models/servico_produto/subcategoria_servico_model.dart';
import './../../../../controllers/categoria/subcategoria_servico_controller.dart';
import './../../../../data/models/servico_produto/categoria_servico_model.dart';
import './../../../../controllers/categoria/categoria_servico_controller.dart';
import './../../../../controllers/servico_produto_controller.dart';
import './../../../../controllers/event_theme_controller.dart';
import './../../../../controllers/fornecedor_controller.dart';

import './../../../../data/models/model.dart';

Future<void> showFornecedorServicoBottomSheet(
  BuildContext context,
  String idFornecedor, {
  FornecedorProdutoServicoModel? vinculo,
}) async {
  final themeController = Get.find<EventThemeController>();
  final fornecedorController = Get.find<FornecedorController>();
  final categoriaController = Get.find<CategoriaServicoController>();
  final subcategoriaController = Get.find<SubcategoriaServicoController>();
  final servicoController = Get.find<ServicoProdutoController>();

  final primary = themeController.primaryColor.value;

  final precoCtrl = TextEditingController(
    text: vinculo?.preco.toStringAsFixed(2) ?? '',
  );
  final promocaoCtrl = TextEditingController(
    text: vinculo?.precoPromocao?.toStringAsFixed(2) ?? '',
  );

  final categoriaSelecionada = Rxn<CategoriaServicoModel>();
  final subcategoriaSelecionada = Rxn<SubcategoriaServicoModel>();
  final servicoSelecionado = Rxn<ServicoProdutoModel>();
  final ativo = (vinculo?.ativo ?? true).obs;

  // ============================================================
  // 🔹 Log inicial
  // ============================================================

  if (categoriaController.categorias.isEmpty) {
    await categoriaController.carregarCategorias();
  }
  if (subcategoriaController.subcategorias.isEmpty) {
    await subcategoriaController.carregarSubcategorias();
  }
  if (servicoController.servicos.isEmpty) {
    await servicoController.carregarServicos();
  }

  // ============================================================
  // 🔹 Se for edição, definir seleções
  // ============================================================
  if (vinculo != null) {
    final servico =
        servicoController.servicos.firstWhereOrNull((s) => s.id == vinculo.idProdutoServico);

    final subcategoria = subcategoriaController.subcategorias
        .firstWhereOrNull((s) => s.id == (servico?.idSubcategoria ?? vinculo.idSubcategoria));

    final categoria =
        categoriaController.categorias.firstWhereOrNull((c) => c.id == subcategoria?.idCategoria);

    categoriaSelecionada.value = categoria;
    subcategoriaSelecionada.value = subcategoria;
    servicoSelecionado.value = servico;
  }

  // ============================================================
  // 🔹 Exibe modal
  // ============================================================
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 20,
            right: 20,
            top: 24,
          ),
          child: Obx(() {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 60,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      vinculo == null ? 'Vincular Serviço' : 'Editar Vínculo',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                    Icon(Icons.design_services_outlined, color: primary),
                  ],
                ),
                const SizedBox(height: 20),

                // ============================================================
                // 🔸 Categoria
                // ============================================================
                DropdownButtonFormField<CategoriaServicoModel>(
                  value: categoriaController.categorias.firstWhereOrNull(
                    (c) => c.id == categoriaSelecionada.value?.id,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Categoria',
                    prefixIcon: const Icon(Icons.category_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: categoriaController.categorias
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.nome),
                          ))
                      .toList(),
                  onChanged: (val) {
                    categoriaSelecionada.value = val;
                    subcategoriaSelecionada.value = null;
                    servicoSelecionado.value = null;
                    if (val != null) {
                      subcategoriaController.carregarSubcategorias(val.id);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // ============================================================
                // 🔸 Subcategoria
                // ============================================================
                DropdownButtonFormField<SubcategoriaServicoModel>(
                  value: subcategoriaController.subcategorias.firstWhereOrNull(
                    (s) => s.id == subcategoriaSelecionada.value?.id,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Subcategoria',
                    prefixIcon: const Icon(Icons.list_alt_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: subcategoriaController.subcategorias
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.nome),
                          ))
                      .toList(),
                  onChanged: (val) {
                    subcategoriaSelecionada.value = val;
                    servicoSelecionado.value = null;
                  },
                ),
                const SizedBox(height: 16),

                // ============================================================
                // 🔸 Serviço / Produto
                // ============================================================
                DropdownButtonFormField<ServicoProdutoModel>(
                  value: servicoController.servicos.firstWhereOrNull(
                    (s) => s.id == servicoSelecionado.value?.id,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Serviço / Produto',
                    prefixIcon: const Icon(Icons.design_services_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: servicoController.servicos
                      .where((s) => s.idSubcategoria == subcategoriaSelecionada.value?.id)
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.nome),
                          ))
                      .toList(),
                  onChanged: (val) {
                    servicoSelecionado.value = val;
                  },
                ),
                const SizedBox(height: 16),

                // ============================================================
                // 🔸 Campos de preço e status
                // ============================================================
                TextField(
                  controller: precoCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Preço padrão (R\$)',
                    prefixIcon: const Icon(Icons.attach_money),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: promocaoCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Preço promocional (opcional)',
                    prefixIcon: const Icon(Icons.local_offer_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Serviço ativo', style: GoogleFonts.poppins(fontSize: 15)),
                    Switch(
                      value: ativo.value,
                      activeColor: primary,
                      onChanged: (v) => ativo.value = v,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Salvar vínculo', style: TextStyle(fontSize: 16)),
                    onPressed: () async {
                      if (servicoSelecionado.value == null) {
                        Get.snackbar(
                          'Atenção',
                          'Selecione um serviço antes de salvar',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red.shade100,
                        );
                        return;
                      }

                      final vinculoNovo = FornecedorProdutoServicoModel(
                        idFornecedorServico: vinculo?.idFornecedorServico ??
                            DateTime.now().millisecondsSinceEpoch.toString(),
                        idProdutoServico: servicoSelecionado.value!.id,
                        idSubcategoria: subcategoriaSelecionada.value!.id,
                        idFornecedor: idFornecedor,
                        preco: double.tryParse(precoCtrl.text.replaceAll(',', '.')) ?? 0.0,
                        precoPromocao: double.tryParse(promocaoCtrl.text.replaceAll(',', '.')),
                        ativo: ativo.value,
                      );

                      await fornecedorController.vincularServico(vinculoNovo);
                      Get.back();
                    },
                  ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Sair', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.grey.shade800,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => Get.back(),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            );
          }),
        );
      },
    ),
  );
}
