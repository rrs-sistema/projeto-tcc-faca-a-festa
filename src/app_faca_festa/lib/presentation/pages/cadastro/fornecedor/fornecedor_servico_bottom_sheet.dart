// ignore_for_file: use_build_context_synchronously

import 'package:app_faca_festa/presentation/pages/cadastro/fornecedor/components/titulo_vinculo_animado.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../../data/models/servico_produto/subcategoria_servico_model.dart';
import './../../../../controllers/categoria/subcategoria_servico_controller.dart';
import './../../../../data/models/servico_produto/categoria_servico_model.dart';
import './../../../../controllers/categoria/categoria_servico_controller.dart';
import './../../../../controllers/servico/servico_foto_controller.dart';
import './../../../../data/models/servico_produto/servico_foto.dart';
import './../../../../controllers/servico_produto_controller.dart';
import '../../../../controllers/tema/event_theme_controller.dart';
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
  final fotoController = Get.put(ServicoFotoController());

  final primary = themeController.primaryColor.value;

  final precoCtrl = TextEditingController(text: vinculo?.preco.toStringAsFixed(2) ?? '');
  final promocaoCtrl =
      TextEditingController(text: vinculo?.precoPromocao?.toStringAsFixed(2) ?? '');
  final urlController = TextEditingController();

  final categoriaSelecionada = Rxn<CategoriaServicoModel>();
  final subcategoriaSelecionada = Rxn<SubcategoriaServicoModel>();
  final servicoSelecionado = Rxn<ServicoProdutoModel>();
  final ativo = (vinculo?.ativo ?? true).obs;

  // --- Carregar listas
  if (categoriaController.categorias.isEmpty) await categoriaController.carregarCategorias();
  if (subcategoriaController.subcategorias.isEmpty) {
    await subcategoriaController.carregarSubcategorias();
  }
  if (servicoController.servicos.isEmpty) await servicoController.carregarServicos();

  // --- Se edição, preencher
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

  InputDecoration decor(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 1.6),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      );

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Obx(() {
          return SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 20,
              right: 20,
              top: 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Gradiente topo ---
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primary, primary.withValues(alpha: 0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.design_services_rounded,
                            color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TituloVinculoAnimado(isEdicao: vinculo != null, primary: primary),
                          Text(
                            'Preencha os dados do serviço com atenção',
                            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // --- Categoria / Subcategoria / Serviço ---
                DropdownButtonFormField<CategoriaServicoModel>(
                  value: categoriaSelecionada.value,
                  decoration: decor('Categoria', Icons.category_outlined),
                  items: categoriaController.categorias
                      .map((c) => DropdownMenuItem(value: c, child: Text(c.nome)))
                      .toList(),
                  onChanged: (val) {
                    categoriaSelecionada.value = val;
                    subcategoriaSelecionada.value = null;
                    servicoSelecionado.value = null;
                    if (val != null) subcategoriaController.carregarSubcategorias(val.id);
                  },
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<SubcategoriaServicoModel>(
                  value: subcategoriaSelecionada.value,
                  decoration: decor('Subcategoria', Icons.list_alt_outlined),
                  items: subcategoriaController.subcategorias
                      .map((s) => DropdownMenuItem(value: s, child: Text(s.nome)))
                      .toList(),
                  onChanged: (val) => subcategoriaSelecionada.value = val,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<ServicoProdutoModel>(
                  value: servicoSelecionado.value,
                  decoration: decor('Serviço / Produto', Icons.work_outline_rounded),
                  items: servicoController.servicos
                      .where((s) => s.idSubcategoria == subcategoriaSelecionada.value?.id)
                      .map((s) => DropdownMenuItem(value: s, child: Text(s.nome)))
                      .toList(),
                  onChanged: (val) => servicoSelecionado.value = val,
                ),

                const SizedBox(height: 24),

                // --- Card de preços e status ---
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(
                          controller: precoCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: decor('Preço padrão (R\$)', Icons.attach_money_rounded),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: promocaoCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration:
                              decor('Preço promocional (opcional)', Icons.local_offer_outlined),
                        ),
                        const Divider(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Serviço ativo', style: GoogleFonts.poppins(fontSize: 15)),
                            Switch(
                                value: ativo.value,
                                activeColor: primary,
                                onChanged: (v) => ativo.value = v),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // --- Imagens ---
                if (servicoSelecionado.value != null) ...[
                  Text('Imagens do serviço',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 12),
                  Obx(() {
                    final fotos = fotoController.fotos;
                    if (fotos.isEmpty) {
                      return Container(
                        height: 100,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text('Nenhuma imagem ainda.\nAdicione fotos atrativas!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(color: Colors.grey.shade600)),
                      );
                    }
                    return SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: fotos.length,
                        itemBuilder: (_, i) {
                          final f = fotos[i];
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Material(
                              elevation: 3,
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(f.url,
                                        width: 130, height: 120, fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: InkWell(
                                      onTap: () => fotoController.removerFoto(f),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black45,
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(4),
                                        child:
                                            const Icon(Icons.close, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  TextField(
                    controller: urlController,
                    decoration: decor('Cole o link da imagem (URL)', Icons.link_rounded),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add_link_rounded),
                          label: const Text('Adicionar via URL'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () async {
                            final url = urlController.text.trim();
                            if (url.isEmpty) {
                              Get.snackbar('Atenção', 'Informe uma URL válida antes de salvar');
                              return;
                            }
                            EasyLoading.show(status: 'Processando...');
                            final novaFoto = ServicoFotoModel(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              idProdutoServico: servicoSelecionado.value!.id,
                              idFornecedor: idFornecedor,
                              url: url,
                              dataUpload: DateTime.now(),
                            );
                            await fotoController.adicionarFotoDireto(novaFoto);
                            EasyLoading.dismiss();
                            urlController.clear();
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add_a_photo_outlined),
                          label: const Text('Enviar do dispositivo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade400,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () async {
                            EasyLoading.show(status: 'Processando...');
                            await fotoController.adicionarFoto(
                              idFornecedor: idFornecedor,
                              idProdutoServico: servicoSelecionado.value!.id,
                            );
                            EasyLoading.dismiss();
                          },
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save_rounded),
                    label: const Text(
                      'Salvar',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      elevation: 3,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      if (servicoSelecionado.value == null) {
                        Get.snackbar(
                          'Atenção',
                          'Selecione um serviço antes de salvar',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red.shade100,
                          colorText: Colors.black87,
                        );
                        return;
                      }
                      EasyLoading.show(status: 'Salvando as informações...');
                      final vinculoNovo = FornecedorProdutoServicoModel(
                        id: vinculo?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                        idProdutoServico: servicoSelecionado.value!.id,
                        idSubcategoria: subcategoriaSelecionada.value!.id,
                        idFornecedor: idFornecedor,
                        preco: double.tryParse(precoCtrl.text.replaceAll(',', '.')) ?? 0.0,
                        precoPromocao: double.tryParse(promocaoCtrl.text.replaceAll(',', '.')),
                        ativo: ativo.value,
                      );

                      await fornecedorController.vincularServico(vinculoNovo);
                      EasyLoading.dismiss();

                      //await fornecedorController.limparDuplicatasFornecedorCategoria();
                      Get.back();
                    },

                    /*
                    onPressed: () async {
                      if (servicoSelecionado.value == null) {
                        Get.snackbar(
                          'Atenção',
                          'Selecione um serviço antes de salvar',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red.shade100,
                          colorText: Colors.black87,
                        );
                        return;
                      }

                      final vinculoNovo = FornecedorProdutoServicoModel(
                        id: vinculo?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
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
                    */
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    icon: const Icon(Icons.exit_to_app_rounded),
                    label: const Text(
                      'Sair',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      backgroundColor: Colors.grey.shade400,
                    ),
                    onPressed: () => Get.back(),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        });
      },
    ),
  );
}
