import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../controllers/categoria/categoria_servico_controller.dart';
import '../../../../controllers/categoria/subcategoria_servico_controller.dart';
import '../../../../controllers/tema/admin_theme.dart';
import '../../../../data/models/servico_produto/categoria_servico_model.dart';
import '../../../../data/models/servico_produto/subcategoria_servico_model.dart';
import '../../../widgets/admin/admin_kit.dart';

Future<void> showSubcategoriaServicoBottomSheet(
  BuildContext context, [
  SubcategoriaServicoModel? subcategoria,
  CategoriaServicoModel? categoriaSelecionada,
]) async {
  final categoriaController = Get.find<CategoriaServicoController>();
  final subcategoriaController = Get.find<SubcategoriaServicoController>();

  final nomeCtrl = TextEditingController(text: subcategoria?.nome ?? '');
  final descCtrl = TextEditingController(text: subcategoria?.descricao ?? '');
  final ordemCtrl = TextEditingController(text: '${subcategoria?.ordem ?? 0}');
  final ativo = (subcategoria?.ativo ?? true).obs;
  final icone = (subcategoria?.icone ?? categoriaSelecionada?.icone ?? 'category').obs;
  final idCategoria =
      (subcategoria?.idCategoria ?? categoriaSelecionada?.id ?? '').obs;
  final salvando = false.obs;

  if (categoriaController.categorias.isEmpty) {
    await categoriaController.carregarCategorias();
  }
  if (!context.mounted) return;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Obx(() {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                subcategoria == null ? 'Nova subcategoria' : 'Editar subcategoria',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AdminPalette.ink,
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: idCategoria.value.isEmpty ? null : idCategoria.value,
                decoration: adminInputDecoration(
                  label: 'Categoria vinculada',
                  icon: Icons.category_outlined,
                ),
                items: categoriaController.categorias
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.nome)))
                    .toList(),
                onChanged: (v) => idCategoria.value = v ?? '',
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nomeCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: adminInputDecoration(
                  label: 'Nome da subcategoria',
                  icon: Icons.list_alt_rounded,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                maxLength: 180,
                decoration: adminInputDecoration(
                  label: 'Descrição (opcional)',
                  icon: Icons.notes_outlined,
                ),
              ),
              TextField(
                controller: ordemCtrl,
                keyboardType: TextInputType.number,
                decoration: adminInputDecoration(
                  label: 'Ordem de exibição',
                  icon: Icons.format_list_numbered_rounded,
                ),
              ),
              const SizedBox(height: 16),
              Text('Ícone', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CategoriaIcones.catalogo.entries.map((e) {
                  final selecionado = icone.value == e.key;
                  return InkWell(
                    onTap: () => icone.value = e.key,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: selecionado
                            ? AdminPalette.primary
                            : AdminPalette.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        e.value,
                        color: selecionado ? Colors.white : AdminPalette.primary,
                        size: 20,
                      ),
                    ),
                  );
                }).toList(),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: ativo.value,
                onChanged: (v) => ativo.value = v,
                title: Text('Subcategoria ativa', style: GoogleFonts.poppins(fontSize: 14)),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: salvando.value
                      ? null
                      : () async {
                          if (idCategoria.value.isEmpty || nomeCtrl.text.trim().isEmpty) {
                            Get.snackbar(
                              'Campos obrigatórios',
                              'Informe a categoria e o nome da subcategoria.',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                            return;
                          }
                          salvando.value = true;
                          final model = SubcategoriaServicoModel(
                            id: subcategoria?.id ??
                                DateTime.now().millisecondsSinceEpoch.toString(),
                            idCategoria: idCategoria.value,
                            nome: nomeCtrl.text.trim(),
                            descricao: descCtrl.text.trim(),
                            ativo: ativo.value,
                            ordem: int.tryParse(ordemCtrl.text.trim()) ?? 0,
                            icone: icone.value,
                            dataCadastro: subcategoria?.dataCadastro ?? DateTime.now(),
                          );
                          await subcategoriaController.salvarSubcategoria(model);
                          salvando.value = false;
                          Get.back();
                        },
                  icon: const Icon(Icons.save_rounded),
                  label: Text('Salvar', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AdminPalette.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Get.back(),
                child: Center(
                  child: Text('Cancelar', style: GoogleFonts.poppins(color: AdminPalette.muted)),
                ),
              ),
            ],
          ),
        );
      }),
    ),
  );
}
