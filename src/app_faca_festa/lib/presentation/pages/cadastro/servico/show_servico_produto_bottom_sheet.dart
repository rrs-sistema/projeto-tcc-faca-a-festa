// ignore_for_file: use_build_context_synchronously

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../../data/models/servico_produto/subcategoria_servico_model.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/subcategoria_servico_controller.dart';
import './../../../../data/models/servico_produto/categoria_servico_model.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/categoria_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/servico_produto_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import '../../../../core/utils/form_validators.dart';
import './../../../../data/models/model.dart';

Future<void> showServicoProdutoBottomSheet(
  BuildContext context, [
  ServicoProdutoModel? servico,
]) async {
  final categoriaController = Get.find<CategoriaServicoController>();
  final subcategoriaController = Get.find<SubcategoriaServicoController>();

  if (categoriaController.categorias.isEmpty) {
    await categoriaController.carregarCategorias();
  }
  if (subcategoriaController.subcategorias.isEmpty) {
    await subcategoriaController.carregarSubcategorias();
  }
  if (!context.mounted) return;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (_) => _ServicoProdutoSheet(servico: servico),
  );
}

class _ServicoProdutoSheet extends StatefulWidget {
  const _ServicoProdutoSheet({this.servico});

  final ServicoProdutoModel? servico;

  @override
  State<_ServicoProdutoSheet> createState() => _ServicoProdutoSheetState();
}

class _ServicoProdutoSheetState extends State<_ServicoProdutoSheet> {
  static const medidas = {
    'U': 'Unidade',
    'H': 'Hora',
    'D': 'Diária',
    'P': 'Pacote',
  };

  final _formKey = GlobalKey<FormState>();
  var _autovalidateMode = AutovalidateMode.disabled;

  late final TextEditingController nomeCtrl;
  late final TextEditingController descCtrl;
  late final Color primary;
  late final ServicoProdutoController servicoController;
  late final CategoriaServicoController categoriaController;
  late final SubcategoriaServicoController subcategoriaController;

  CategoriaServicoModel? categoriaSelecionada;
  SubcategoriaServicoModel? subcategoriaSelecionada;
  String tipoMedida = '';

  @override
  void initState() {
    super.initState();
    primary = Get.find<EventThemeController>().primaryColor.value;
    servicoController = Get.find<ServicoProdutoController>();
    categoriaController = Get.find<CategoriaServicoController>();
    subcategoriaController = Get.find<SubcategoriaServicoController>();

    final servico = widget.servico;
    nomeCtrl = TextEditingController(text: servico?.nome ?? '');
    descCtrl = TextEditingController(text: servico?.descricao ?? '');
    tipoMedida = servico?.tipoMedida ?? '';

    if (servico?.idSubcategoria != null) {
      final subcat = subcategoriaController.subcategorias
          .firstWhereOrNull((s) => s.id == servico!.idSubcategoria);
      if (subcat != null) {
        subcategoriaSelecionada = subcat;
        categoriaSelecionada = categoriaController.categorias
            .firstWhereOrNull((c) => c.id == subcat.idCategoria);
      }
    }
  }

  @override
  void dispose() {
    nomeCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

  InputDecoration _decor(String label, IconData icon,
      {bool obrigatorio = false}) {
    return InputDecoration(
      labelText: obrigatorio ? '$label *' : label,
      prefixIcon: Icon(icon, color: primary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      errorMaxLines: 2,
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
      ),
    );
  }

  Future<void> _salvar() async {
    setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final model = ServicoProdutoModel(
      id: widget.servico?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      nome: nomeCtrl.text.trim(),
      tipoMedida: tipoMedida.isEmpty ? null : tipoMedida,
      descricao: descCtrl.text.trim(),
      idSubcategoria: subcategoriaSelecionada!.id,
      ativo: true,
    );
    await servicoController.salvarServico(model);
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Form(
          key: _formKey,
          autovalidateMode: _autovalidateMode,
          child: SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 20,
              right: 20,
              top: 24,
            ),
            child: Column(
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
                    widget.servico == null
                        ? 'Novo Serviço / Produto'
                        : 'Editar Serviço',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Campos com * são obrigatórios. Medida e descrição são opcionais.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<CategoriaServicoModel>(
                  value: categoriaSelecionada,
                  decoration: _decor('Categoria', Icons.category_outlined,
                      obrigatorio: true),
                  items: categoriaController.categorias
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c.nome)))
                      .toList(),
                  validator: (v) =>
                      FormValidators.selecao(v, campo: 'a categoria'),
                  onChanged: (val) {
                    setState(() {
                      categoriaSelecionada = val;
                      subcategoriaSelecionada = null;
                    });
                    if (val != null) {
                      subcategoriaController.carregarSubcategorias(val.id);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<SubcategoriaServicoModel>(
                  value: subcategoriaSelecionada,
                  decoration: _decor('Subcategoria', Icons.list_alt_outlined,
                      obrigatorio: true),
                  items: subcategoriaController.subcategorias
                      .where((s) =>
                          categoriaSelecionada == null ||
                          s.idCategoria == categoriaSelecionada?.id)
                      .map((s) =>
                          DropdownMenuItem(value: s, child: Text(s.nome)))
                      .toList(),
                  validator: (v) {
                    if (categoriaSelecionada == null) {
                      return 'Selecione a categoria primeiro';
                    }
                    return FormValidators.selecao(v, campo: 'a subcategoria');
                  },
                  onChanged: categoriaSelecionada == null
                      ? null
                      : (val) => setState(() => subcategoriaSelecionada = val),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nomeCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _decor(
                    'Nome do serviço ou produto',
                    Icons.design_services_outlined,
                    obrigatorio: true,
                  ),
                  validator: (v) => FormValidators.titulo(
                    v,
                    campo: 'o nome do serviço',
                    minimo: 3,
                    maximo: 80,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: tipoMedida.isEmpty ? null : tipoMedida,
                  decoration: _decor(
                    'Tipo de medida (opcional)',
                    Icons.straighten_outlined,
                  ),
                  items: medidas.entries
                      .map((entry) => DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => tipoMedida = v ?? ''),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descCtrl,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _decor(
                    'Descrição (opcional)',
                    Icons.notes_outlined,
                  ),
                  validator: (v) => FormValidators.descricao(
                    v,
                    campo: 'a descrição',
                    obrigatorio: false,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save_rounded, color: Colors.white),
                    label: const Text('Salvar',
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    onPressed: _salvar,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    label: const Text('Sair',
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade800,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () => Get.back(),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
