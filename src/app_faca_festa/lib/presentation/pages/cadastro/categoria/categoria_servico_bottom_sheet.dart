import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../controllers/categoria/categoria_servico_controller.dart';
import '../../../../controllers/tema/admin_theme.dart';
import '../../../../core/utils/form_masks.dart';
import '../../../../core/utils/form_validators.dart';
import '../../../../data/models/servico_produto/categoria_servico_model.dart';
import '../../../widgets/admin/admin_kit.dart';

Future<void> showCategoriaServicoBottomSheet(
  BuildContext context, [
  CategoriaServicoModel? categoria,
]) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _CategoriaServicoSheet(categoria: categoria),
  );
}

class _CategoriaServicoSheet extends StatefulWidget {
  const _CategoriaServicoSheet({this.categoria});

  final CategoriaServicoModel? categoria;

  @override
  State<_CategoriaServicoSheet> createState() => _CategoriaServicoSheetState();
}

class _CategoriaServicoSheetState extends State<_CategoriaServicoSheet> {
  final _formKey = GlobalKey<FormState>();
  var _autovalidateMode = AutovalidateMode.disabled;

  late final TextEditingController nomeCtrl;
  late final TextEditingController descCtrl;
  late final TextEditingController ordemCtrl;
  late final CategoriaServicoController controller;

  late String icone;
  late bool ativo;
  var salvando = false;

  @override
  void initState() {
    super.initState();
    controller = Get.find<CategoriaServicoController>();
    final categoria = widget.categoria;
    nomeCtrl = TextEditingController(text: categoria?.nome ?? '');
    descCtrl = TextEditingController(text: categoria?.descricao ?? '');
    ordemCtrl = TextEditingController(text: '${categoria?.ordem ?? 0}');
    ativo = categoria?.ativo ?? true;
    icone = categoria?.icone ?? 'category';
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
    final model = CategoriaServicoModel(
      id: widget.categoria?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      nome: nomeCtrl.text.trim(),
      descricao: descCtrl.text.trim(),
      ativo: ativo,
      ordem: int.tryParse(ordemCtrl.text.trim()) ?? 0,
      icone: icone,
      dataCadastro: widget.categoria?.dataCadastro ?? DateTime.now(),
    );
    await controller.salvarCategoria(model);
    if (mounted) {
      setState(() => salvando = false);
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                widget.categoria == null ? 'Nova categoria' : 'Editar categoria',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AdminPalette.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Campos com * são obrigatórios. Descrição, ordem e ícone são opcionais.',
                style: GoogleFonts.poppins(fontSize: 12.5, color: AdminPalette.muted),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: nomeCtrl,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: adminInputDecoration(
                  label: 'Nome da categoria',
                  icon: Icons.category_outlined,
                  obrigatorio: true,
                ),
                validator: (v) => FormValidators.titulo(
                  v,
                  campo: 'o nome da categoria',
                  minimo: 3,
                  maximo: 80,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: descCtrl,
                maxLines: 4,
                maxLength: 180,
                textCapitalization: TextCapitalization.sentences,
                decoration: adminInputDecoration(
                  label: 'Descrição (opcional)',
                  icon: Icons.notes_outlined,
                  hint: 'O que esta categoria cobre no evento',
                ),
                validator: (v) => FormValidators.descricao(
                  v,
                  campo: 'a descrição',
                  obrigatorio: false,
                  minimo: 5,
                  maximo: 180,
                ),
              ),
              const SizedBox(height: 8),
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
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Ícone (opcional)',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
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
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: selecionado
                            ? AdminPalette.primary
                            : AdminPalette.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selecionado ? AdminPalette.primary : AdminPalette.border,
                        ),
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
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: ativo,
                onChanged: (v) => setState(() => ativo = v),
                title: Text('Categoria ativa', style: GoogleFonts.poppins(fontSize: 14)),
                subtitle: Text(
                  'Inativas deixam de aparecer no cadastro de fornecedores.',
                  style: GoogleFonts.poppins(fontSize: 12, color: AdminPalette.muted),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: salvando ? null : _salvar,
                  icon: salvando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text('Salvar', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AdminPalette.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: salvando ? null : () => Get.back(),
                  child: Text('Cancelar', style: GoogleFonts.poppins(color: AdminPalette.muted)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
