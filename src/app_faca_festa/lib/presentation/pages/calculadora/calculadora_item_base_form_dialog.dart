import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/calculadora/calculadora_itens_admin_controller.dart';
import '../../../core/utils/form_validators.dart';
import '../../../data/models/calculadora/calculadora_item_base_model.dart';

class CalculadoraItemBaseFormDialog {
  static Future<void> show({CalculadoraItemBaseModel? item}) async {
    await showModalBottomSheet<void>(
      context: Get.context!,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _CalculadoraItemBaseFormContent(item: item);
      },
    );
  }
}

class _CalculadoraItemBaseFormContent extends StatefulWidget {
  final CalculadoraItemBaseModel? item;

  const _CalculadoraItemBaseFormContent({this.item});

  @override
  State<_CalculadoraItemBaseFormContent> createState() => _CalculadoraItemBaseFormContentState();
}

class _CalculadoraItemBaseFormContentState extends State<_CalculadoraItemBaseFormContent> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomeController;
  late final TextEditingController _descricaoController;
  late final TextEditingController _categoriaController;
  late final TextEditingController _tipoItemController;
  late final TextEditingController _unidadeController;
  late final TextEditingController _ordemController;
  late final TextEditingController _tagsController;
  late final TextEditingController _iconeController;

  late bool _ativo;
  late String _publicoAlvo;

  CalculadoraItensAdminController get controller => Get.find<CalculadoraItensAdminController>();

  bool get isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();

    final item = widget.item;

    _nomeController = TextEditingController(text: item?.nome ?? '');
    _descricaoController = TextEditingController(text: item?.descricao ?? '');
    _categoriaController = TextEditingController(text: item?.categoriaPadrao ?? '');
    _tipoItemController = TextEditingController(text: item?.tipoItem ?? '');
    _unidadeController = TextEditingController(text: item?.unidadePadrao ?? 'unidade');
    _ordemController = TextEditingController(text: '${item?.ordem ?? 0}');
    _tagsController = TextEditingController(text: item?.tags.join(', ') ?? '');
    _iconeController = TextEditingController(text: item?.icone ?? '');

    _ativo = item?.ativo ?? true;
    _publicoAlvo = _normalizarOpcao(
      item?.publicoAlvo,
      CalculadoraItensAdminController.publicosAlvo,
      'todos',
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _categoriaController.dispose();
    _tipoItemController.dispose();
    _unidadeController.dispose();
    _ordemController.dispose();
    _tagsController.dispose();
    _iconeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return FractionallySizedBox(
      heightFactor: 0.88, // 🔹 Mais compacto
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 14,
              right: 14,
              bottom: bottomInset + 12, // 🔹 Padding dinâmico e menor
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 50,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _Header(
                      title: isEditing ? 'Editar item base' : 'Novo item base',
                      subtitle: isEditing
                          ? 'Atualize o catálogo global'
                          : 'Cadastre um item genérico reutilizável',
                    ),
                    const SizedBox(height: 10),
                    Divider(
                      height: 1,
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    _InfoIdPreview(
                      isEditing: isEditing,
                      id: widget.item?.id,
                      previewBuilder: () => controller.gerarIdItemBase(
                        nome: _nomeController.text,
                        tipoItem: _tipoItemController.text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ResponsiveFields(
                      children: [
                        _textField(
                          controller: _nomeController,
                          label: 'Nome',
                          icon: Icons.sell_outlined,
                          requiredField: true,
                          onChanged: (_) => setState(() {}),
                        ),
                        _textField(
                          controller: _tipoItemController,
                          label: 'Tipo do item',
                          hint: 'Ex.: bolo, salgadinhos',
                          icon: Icons.key_outlined,
                          requiredField: true,
                          onChanged: (_) => setState(() {}),
                        ),
                        _textField(
                          controller: _categoriaController,
                          label: 'Categoria padrão',
                          icon: Icons.category_outlined,
                          requiredField: true,
                        ),
                        _textField(
                          controller: _unidadeController,
                          label: 'Unidade padrão',
                          icon: Icons.straighten_outlined,
                          requiredField: true,
                        ),
                        DropdownButtonFormField<String>(
                          value: _publicoAlvo,
                          isExpanded: true,
                          decoration: _decoration(
                            label: 'Público-alvo',
                            icon: Icons.groups_2_outlined,
                          ),
                          items: CalculadoraItensAdminController.publicosAlvo
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(_labelPublico(value),
                                      style: const TextStyle(fontSize: 13)),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _publicoAlvo = value);
                          },
                        ),
                        _textField(
                          controller: _ordemController,
                          label: 'Ordem',
                          icon: Icons.sort_outlined,
                          keyboardType: TextInputType.number,
                        ),
                        _textField(
                          controller: _iconeController,
                          label: 'Ícone',
                          hint: 'Ex.: cake, restaurant',
                          icon: Icons.emoji_symbols_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _textField(
                      controller: _descricaoController,
                      label: 'Descrição',
                      icon: Icons.description_outlined,
                      maxLines: 2, // 🔹 Reduzido
                    ),
                    const SizedBox(height: 10),
                    _textField(
                      controller: _tagsController,
                      label: 'Tags',
                      hint: 'Separe por vírgula: bolo, recepção, comida',
                      icon: Icons.tag_outlined,
                    ),
                    const SizedBox(height: 10),
                    _ActiveSwitchCard(
                      value: _ativo,
                      onChanged: (value) => setState(() => _ativo = value),
                    ),
                    const SizedBox(height: 20),
                    _FooterActions(
                      controller: controller,
                      onSubmit: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final id = widget.item?.id ??
        controller.gerarIdItemBase(
          nome: _nomeController.text,
          tipoItem: _tipoItemController.text,
        );

    if (id.isEmpty) {
      Get.snackbar(
        'Atenção',
        'Informe nome ou tipo do item para gerar o ID.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final item = CalculadoraItemBaseModel(
      id: id,
      nome: _nomeController.text.trim(),
      descricao: _descricaoController.text.trim(),
      categoriaPadrao: _categoriaController.text.trim(),
      tipoItem: controller.normalizarChave(_tipoItemController.text),
      unidadePadrao: controller.normalizarChave(_unidadeController.text),
      publicoAlvo: _publicoAlvo,
      ativo: _ativo,
      ordem: int.tryParse(_ordemController.text.trim()) ?? 0,
      icone: _iconeController.text.trim(),
      tags: _parseTags(_tagsController.text),
      createdAt: widget.item?.createdAt ?? now,
      updatedAt: now,
    );

    controller.salvarItemBase(item);
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    String? hint,
    bool requiredField = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13), // 🔹 Fonte menor
      textInputAction: maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
      decoration: _decoration(label: label, icon: icon, hint: hint),
      validator: requiredField
          ? (value) => FormValidators.titulo(value, campo: label.toLowerCase(), minimo: 2)
          : null,
    );
  }

  InputDecoration _decoration({
    required String label,
    IconData? icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(fontSize: 13), // 🔹 Fonte menor
      prefixIcon: icon == null ? null : Icon(icon, size: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 10, // 🔹 Espaçamento compacto
      ),
    );
  }

  List<String> _parseTags(String value) {
    final result = <String>[];
    for (final item in value.split(',')) {
      final parsed = item.trim();
      if (parsed.isNotEmpty && !result.contains(parsed)) {
        result.add(parsed);
      }
    }
    return result;
  }

  String _normalizarOpcao(
    String? value,
    List<String> options,
    String fallback,
  ) {
    final normalized = controller.normalizarChave(value ?? '');
    return options.contains(normalized) ? normalized : fallback;
  }

  String _labelPublico(String value) {
    switch (value) {
      case 'adultos':
        return 'Adultos';
      case 'criancas':
        return 'Crianças';
      default:
        return 'Todos';
    }
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;

  const _Header({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.calculate_outlined,
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () => Get.back<void>(),
          icon: const Icon(Icons.close, size: 20),
        ),
      ],
    );
  }
}

class _InfoIdPreview extends StatelessWidget {
  final bool isEditing;
  final String? id;
  final String Function() previewBuilder;

  const _InfoIdPreview({
    required this.isEditing,
    required this.id,
    required this.previewBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedId = isEditing ? id ?? '' : previewBuilder();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isEditing
            ? 'ID do documento: $resolvedId'
            : 'ID gerado ao salvar: ${resolvedId.isEmpty ? 'preencha nome/tipo' : resolvedId}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _ResponsiveFields extends StatelessWidget {
  final List<Widget> children;

  const _ResponsiveFields({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 620;
        final itemWidth = isWide ? (constraints.maxWidth - 10) / 2 : constraints.maxWidth;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: children
              .map(
                (child) => SizedBox(
                  width: itemWidth,
                  child: child,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _ActiveSwitchCard extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ActiveSwitchCard({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Item ativo',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Itens inativos não aparecem na calculadora.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _FooterActions extends StatelessWidget {
  final CalculadoraItensAdminController controller;
  final VoidCallback onSubmit;

  const _FooterActions({
    required this.controller,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: controller.saving.value ? null : () => Get.back<void>(),
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Cancelar', style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              onPressed: controller.saving.value ? null : onSubmit,
              icon: controller.saving.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined, size: 16),
              label: Text(
                controller.saving.value ? 'Salvando...' : 'Salvar',
                style: const TextStyle(fontSize: 13),
              ),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
            ),
          ),
        ],
      ),
    );
  }
}
