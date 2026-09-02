import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/presentation/modules/catalogo/controllers/categoria_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/subcategoria_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/admin_theme.dart';
import '../../../../core/utils/form_masks.dart';
import '../../../../core/utils/form_validators.dart';
import '../../../../data/models/servico_produto/categoria_servico_model.dart';
import '../../../../data/models/servico_produto/subcategoria_servico_model.dart';
import '../../../widgets/admin/admin_kit.dart';

Future<void> showSubcategoriaServicoBottomSheet(
  BuildContext context, [
  SubcategoriaServicoModel? subcategoria,
  CategoriaServicoModel? categoriaSelecionada,
]) async {
  final categoriaController = Get.find<CategoriaServicoController>();

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
    builder: (_) => _SubcategoriaServicoSheet(
      subcategoria: subcategoria,
      categoriaSelecionada: categoriaSelecionada,
    ),
  );
}

class _SubcategoriaServicoSheet extends StatefulWidget {
  const _SubcategoriaServicoSheet({
    this.subcategoria,
    this.categoriaSelecionada,
  });

  final SubcategoriaServicoModel? subcategoria;
  final CategoriaServicoModel? categoriaSelecionada;

  @override
  State<_SubcategoriaServicoSheet> createState() =>
      _SubcategoriaServicoSheetState();
}

class _SubcategoriaServicoSheetState extends State<_SubcategoriaServicoSheet> {
  final _formKey = GlobalKey<FormState>();
  var _autovalidateMode = AutovalidateMode.disabled;

  late final TextEditingController nomeCtrl;
  late final TextEditingController descCtrl;
  late final TextEditingController ordemCtrl;
  late final CategoriaServicoController categoriaController;
  late final SubcategoriaServicoController subcategoriaController;

  late String idCategoria;
  late String icone;
  late bool ativo;
  var salvando = false;

  @override
  void initState() {
    super.initState();
    categoriaController = Get.find<CategoriaServicoController>();
    subcategoriaController = Get.find<SubcategoriaServicoController>();
    final subcategoria = widget.subcategoria;
    nomeCtrl = TextEditingController(text: subcategoria?.nome ?? '');
    descCtrl = TextEditingController(text: subcategoria?.descricao ?? '');
    ordemCtrl = TextEditingController(text: '${subcategoria?.ordem ?? 0}');
    ativo = subcategoria?.ativo ?? true;
    icone =
        subcategoria?.icone ?? widget.categoriaSelecionada?.icone ?? 'category';
    idCategoria =
        subcategoria?.idCategoria ?? widget.categoriaSelecionada?.id ?? '';
  }

  @override
  void dispose() {
    nomeCtrl.dispose();
    descCtrl.dispose();
    ordemCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
    if (!(_formKey.currentState?.validate() ?? false) || salvando) return;

    setState(() => salvando = true);
    final model = SubcategoriaServicoModel(
      id: widget.subcategoria?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      idCategoria: idCategoria,
      nome: nomeCtrl.text.trim(),
      descricao: descCtrl.text.trim(),
      ativo: ativo,
      ordem: int.tryParse(ordemCtrl.text.trim()) ?? 0,
      icone: icone,
      dataCadastro: widget.subcategoria?.dataCadastro ?? DateTime.now(),
    );
    await subcategoriaController.salvarSubcategoria(model);
    if (mounted) {
      setState(() => salvando = false);
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Form(
        key: _formKey,
        autovalidateMode: _autovalidateMode,
        child: SingleChildScrollView(
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
                widget.subcategoria == null
                    ? 'Nova subcategoria'
                    : 'Editar subcategoria',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AdminPalette.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Campos com * são obrigatórios. Descrição, ordem e ícone são opcionais.',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: AdminPalette.muted,
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: idCategoria.isEmpty ? null : idCategoria,
                decoration: adminInputDecoration(
                  label: 'Categoria vinculada',
                  icon: Icons.category_outlined,
                  obrigatorio: true,
                ),
                items: categoriaController.categorias
                    .map((c) =>
                        DropdownMenuItem(value: c.id, child: Text(c.nome)))
                    .toList(),
                validator: (v) =>
                    FormValidators.selecao(v, campo: 'a categoria'),
                onChanged: (v) => setState(() => idCategoria = v ?? ''),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: nomeCtrl,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: adminInputDecoration(
                  label: 'Nome da subcategoria',
                  icon: Icons.list_alt_rounded,
                  obrigatorio: true,
                ),
                validator: (v) => FormValidators.titulo(
                  v,
                  campo: 'o nome da subcategoria',
                  minimo: 3,
                  maximo: 80,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: descCtrl,
                maxLines: 3,
                maxLength: 180,
                textCapitalization: TextCapitalization.sentences,
                decoration: adminInputDecoration(
                  label: 'Descrição (opcional)',
                  icon: Icons.notes_outlined,
                  hint: 'O que esta subcategoria cobre no evento',
                ),
                validator: (v) => FormValidators.descricao(
                  v,
                  campo: 'a descrição',
                  obrigatorio: false,
                  minimo: 5,
                  maximo: 180,
                ),
              ),
              TextFormField(
                controller: ordemCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: FormMasks.inteiro(maxDigits: 4),
                decoration: adminInputDecoration(
                  label: 'Ordem de exibição (opcional)',
                  icon: Icons.format_list_numbered_rounded,
                  helperText: 'Números menores aparecem primeiro. Padrão: 0.',
                ),
                validator: (v) => FormValidators.inteiroNaoNegativo(
                  v,
                  campo: 'a ordem de exibição',
                  obrigatorio: false,
                  maximo: 9999,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Ícone (opcional)',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CategoriaIcones.catalogo.entries.map((e) {
                  final selecionado = icone == e.key;
                  return InkWell(
                    onTap: () => setState(() => icone = e.key),
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
                        color:
                            selecionado ? Colors.white : AdminPalette.primary,
                        size: 20,
                      ),
                    ),
                  );
                }).toList(),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: ativo,
                onChanged: (v) => setState(() => ativo = v),
                title: Text('Subcategoria ativa',
                    style: GoogleFonts.poppins(fontSize: 14)),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: salvando ? null : _salvar,
                  icon: salvando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text('Salvar',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AdminPalette.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              TextButton(
                onPressed: salvando ? null : () => Get.back(),
                child: Center(
                  child: Text('Cancelar',
                      style: GoogleFonts.poppins(color: AdminPalette.muted)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
