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
import './../../../../data/models/model.dart';

Future<void> showServicoProdutoBottomSheet(
  BuildContext context, [
  ServicoProdutoModel? servico,
]) async {
  final themeController = Get.find<EventThemeController>();
  final servicoController = Get.find<ServicoProdutoController>();
  final categoriaController = Get.find<CategoriaServicoController>();
  final subcategoriaController = Get.find<SubcategoriaServicoController>();

  final primary = themeController.primaryColor.value;

  // 🔹 Mapa de medidas
  final Map<String, String> medidas = {
    'U': 'Unidade',
    'H': 'Hora',
    'D': 'Diária',
    'P': 'Pacote',
  };

  final nomeCtrl = TextEditingController(text: servico?.nome ?? '');
  final descCtrl = TextEditingController(text: servico?.descricao ?? '');
  RxString tipoMedida = (servico?.tipoMedida ?? '').obs;

  final categoriaSelecionada = Rxn<CategoriaServicoModel>();
  final subcategoriaSelecionada = Rxn<SubcategoriaServicoModel>();

  // 🔹 Carrega listas se estiverem vazias
  if (categoriaController.categorias.isEmpty) {
    await categoriaController.carregarCategorias();
  }
  if (subcategoriaController.subcategorias.isEmpty) {
    await subcategoriaController.carregarSubcategorias();
  }

  // 🔹 Pré-seleção em caso de edição
  if (servico?.idSubcategoria != null) {
    final subcat = subcategoriaController.subcategorias
        .firstWhereOrNull((s) => s.id == servico!.idSubcategoria);
    if (subcat != null) {
      subcategoriaSelecionada.value = subcat;
      categoriaSelecionada.value =
          categoriaController.categorias.firstWhereOrNull((c) => c.id == subcat.idCategoria);
    }
  }

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
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
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    servico == null ? 'Novo Serviço / Produto' : 'Editar Serviço',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

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
                      .where((s) =>
                          categoriaSelecionada.value == null ||
                          s.idCategoria == categoriaSelecionada.value?.id)
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.nome),
                          ))
                      .toList(),
                  onChanged: (val) => subcategoriaSelecionada.value = val,
                ),
                const SizedBox(height: 16),

                // 🔹 Nome
                TextField(
                  controller: nomeCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nome do serviço ou produto',
                    prefixIcon: const Icon(Icons.design_services_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // 🔹 Tipo de medida
                DropdownButtonFormField<String>(
                  value: tipoMedida.value.isEmpty
                      ? null
                      : medidas.keys.firstWhere((k) => k == tipoMedida.value),
                  decoration: InputDecoration(
                    labelText: 'Tipo de medida',
                    prefixIcon: const Icon(Icons.straighten_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: medidas.entries
                      .map((entry) => DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value),
                          ))
                      .toList(),
                  onChanged: (v) => tipoMedida.value = v ?? '',
                ),
                const SizedBox(height: 16),

                // 🔹 Descrição
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Descrição',
                    prefixIcon: const Icon(Icons.notes_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 28),

                // 🔹 Botão Salvar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Salvar', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    onPressed: () async {
                      if (nomeCtrl.text.trim().isEmpty) {
                        Get.snackbar('Campo obrigatório', 'Informe o nome do serviço.');
                        return;
                      }

                      if (subcategoriaSelecionada.value == null) {
                        Get.snackbar('Atenção', 'Selecione uma subcategoria.');
                        return;
                      }

                      final model = ServicoProdutoModel(
                          id: servico?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                          nome: nomeCtrl.text.trim(),
                          tipoMedida: tipoMedida.value.isEmpty ? null : tipoMedida.value,
                          descricao: descCtrl.text.trim(),
                          idSubcategoria: subcategoriaSelecionada.value!.id, // ✅ novo vínculo
                          ativo: true);

                      await servicoController.salvarServico(model);
                      Get.back();
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // 🔹 Botão Sair
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Sair', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.grey.shade800,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
