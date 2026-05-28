import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/calculadora/calculadora_itens_admin_controller.dart';
import '../../../data/models/calculadora/calculadora_item_base_model.dart';

class CalculadoraItemBaseFormDialog {
  static Future<void> show({CalculadoraItemBaseModel? item}) async {
    // 🔹 Substituído Get.bottomSheet por showModalBottomSheet para espelhar
    // perfeitamente o comportamento do seu modal de eventos e evitar o duplo padding.
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

    // =========================================================================
    // 🔹 ESTRUTURA COPIADA DO CADASTRO_EVENTO_BOTTOM_SHEET.DART
    // =========================================================================
    return FractionallySizedBox(
      heightFactor: 0.92,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 14,
              right: 14,
              // O padding dinâmico que sobe a tela junto com o teclado
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        width: 60,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // =========================================================
                    // 🔹 CONTEÚDOS DO CALCULADORA_ITEM_BASE
                    // =========================================================
                    _Header(
                      title: isEditing ? 'Editar item base' : 'Novo item base',
                      subtitle: isEditing
                          ? 'Atualize o catálogo global da calculadora'
                          : 'Cadastre um item genérico para reutilizar nas regras por tipo de evento.',
                    ),
                    const SizedBox(height: 12),
                    Divider(
                      height: 1,
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),

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
                                  child: Text(_labelPublico(value)),
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
                    const SizedBox(height: 12),

                    _textField(
                      controller: _descricaoController,
                      label: 'Descrição',
                      icon: Icons.description_outlined,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),

                    _textField(
                      controller: _tagsController,
                      label: 'Tags',
                      hint: 'Separe por vírgula: bolo, recepção, comida',
                      icon: Icons.tag_outlined,
                    ),
                    const SizedBox(height: 12),

                    _ActiveSwitchCard(
                      value: _ativo,
                      onChanged: (value) => setState(() => _ativo = value),
                    ),
                    const SizedBox(height: 32),

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
      textInputAction: maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
      decoration: _decoration(label: label, icon: icon, hint: hint),
      validator: requiredField
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Campo obrigatório';
              }
              return null;
            }
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
      prefixIcon: icon == null
          ? null
          : Icon(
              icon,
              size: 18,
            ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
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
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            Icons.calculate_outlined,
            color: theme.colorScheme.primary,
            size: 21,
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
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () => Get.back<void>(),
          icon: const Icon(Icons.close),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
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
        final itemWidth = isWide ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
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
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
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
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Itens inativos não aparecem nas configurações da calculadora.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Cancelar'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              onPressed: controller.saving.value ? null : onSubmit,
              icon: controller.saving.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined, size: 18),
              label: Text(
                controller.saving.value ? 'Salvando...' : 'Salvar',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
