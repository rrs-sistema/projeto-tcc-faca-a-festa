import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/presentation/modules/calculadora/controllers/sugestao_base_festa_controller.dart';
import '../../../core/utils/form_validators.dart';
import '../../../data/models/evento/sugestao_base_festa_model.dart';

class SugestaoBaseFestaFormDialog extends StatefulWidget {
  const SugestaoBaseFestaFormDialog({
    super.key,
    this.sugestao,
  });

  final SugestaoBaseFestaModel? sugestao;

  @override
  State<SugestaoBaseFestaFormDialog> createState() =>
      _SugestaoBaseFestaFormDialogState();
}

class _SugestaoBaseFestaFormDialogState
    extends State<SugestaoBaseFestaFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _tituloController;
  late final TextEditingController _descricaoController;
  late final TextEditingController _temaController;
  late final TextEditingController _tipoEventoController;
  late final TextEditingController _perfisFestaController;
  late final TextEditingController _tagsController;
  late final TextEditingController _ordemController;
  late final TextEditingController _duracaoMinimaController;
  late final TextEditingController _riscoMinimoController;

  late String _modulo;
  late String _categoria;
  late String _prioridade;
  late bool _ativo;

  SugestaoBaseFestaController get controller =>
      Get.find<SugestaoBaseFestaController>();

  SugestaoBaseFestaModel get _base =>
      widget.sugestao ?? SugestaoBaseFestaModel.empty();

  bool get _isEditing => widget.sugestao != null;

  @override
  void initState() {
    super.initState();

    final sugestao = _base;

    _tituloController = TextEditingController(text: sugestao.titulo);
    _descricaoController = TextEditingController(text: sugestao.descricao);
    _temaController = TextEditingController(text: sugestao.tema);
    _tipoEventoController = TextEditingController(
      text: sugestao.tipoEvento.isEmpty
          ? 'todos'
          : sugestao.tipoEvento.join(', '),
    );
    _perfisFestaController = TextEditingController(
      text: sugestao.perfisFesta.isEmpty
          ? 'todos'
          : sugestao.perfisFesta.join(', '),
    );
    _tagsController = TextEditingController(text: sugestao.tags.join(', '));
    _ordemController = TextEditingController(text: sugestao.ordem.toString());
    _duracaoMinimaController = TextEditingController(
      text: _mapValueAsString(sugestao.gatilhos['duracao_minima_horas']),
    );
    _riscoMinimoController = TextEditingController(
      text: _mapValueAsString(sugestao.gatilhos['risco_minimo']),
    );

    _modulo = SugestaoBaseFestaOptions.modulos.contains(sugestao.modulo)
        ? sugestao.modulo
        : SugestaoBaseFestaOptions.modulos.first;
    _categoria =
        SugestaoBaseFestaOptions.categorias.contains(sugestao.categoria)
            ? sugestao.categoria
            : SugestaoBaseFestaOptions.categorias.first;
    _prioridade =
        SugestaoBaseFestaOptions.prioridades.contains(sugestao.prioridade)
            ? sugestao.prioridade
            : 'media';
    _ativo = sugestao.ativo;
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _temaController.dispose();
    _tipoEventoController.dispose();
    _perfisFestaController.dispose();
    _tagsController.dispose();
    _ordemController.dispose();
    _duracaoMinimaController.dispose();
    _riscoMinimoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final screenHeight = media.size.height;
    final keyboardHeight = media.viewInsets.bottom;

    // Não usamos AnimatedPadding externo com bottom = teclado.
    // Em alguns aparelhos/rotas o ModalBottomSheet já reduz a área útil quando
    // o teclado abre. Somar esse padding fora do conteúdo causa o efeito de a
    // tela "subir" demais e gera overflow no Column principal.
    // A solução segura é deixar o BottomSheet ancorado e tornar o conteúdo
    // inteiro rolável, com espaço extra no final do scroll quando o teclado está aberto.
    final dialogMaxHeight = math.min(
      screenHeight - media.padding.top - 16,
      760.0,
    );

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 780,
              maxHeight: dialogMaxHeight,
            ),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.only(
                    bottom: keyboardHeight > 0 ? keyboardHeight + 16 : 0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Header(isEditing: _isEditing),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _InstructionPanel(isEditing: _isEditing),
                              const SizedBox(height: 12),
                              _FormSection(
                                icon: Icons.article_outlined,
                                title: 'Conteúdo da sugestão',
                                subtitle:
                                    'Escreva uma regra curada que ajude a IA a orientar melhor o usuário.',
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _TextField(
                                      controller: _tituloController,
                                      label: 'Título',
                                      icon: Icons.title_rounded,
                                      validator: (v) => FormValidators.titulo(v,
                                          campo: 'o título'),
                                    ),
                                    const SizedBox(height: 10),
                                    _TextField(
                                      controller: _descricaoController,
                                      label: 'Descrição',
                                      icon: Icons.notes_rounded,
                                      maxLines: 4,
                                      validator: (v) =>
                                          FormValidators.descricao(
                                        v,
                                        campo: 'a descrição',
                                        obrigatorio: true,
                                        minimo: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              _FormSection(
                                icon: Icons.dashboard_customize_outlined,
                                title: 'Classificação',
                                subtitle:
                                    'Defina onde esta sugestão será usada e a relevância dela.',
                                child: _ResponsiveWrap(
                                  children: [
                                    _DropdownField(
                                      value: _modulo,
                                      label: 'Módulo',
                                      icon: Icons.widgets_rounded,
                                      values: SugestaoBaseFestaOptions.modulos,
                                      onChanged: (value) =>
                                          setState(() => _modulo = value),
                                    ),
                                    _TextField(
                                      controller: _temaController,
                                      label: 'Tema',
                                      icon: Icons.sell_rounded,
                                      validator: (v) => FormValidators.titulo(
                                        v,
                                        campo: 'o tema',
                                        minimo: 2,
                                      ),
                                    ),
                                    _DropdownField(
                                      value: _categoria,
                                      label: 'Categoria',
                                      icon: Icons.category_rounded,
                                      values:
                                          SugestaoBaseFestaOptions.categorias,
                                      onChanged: (value) =>
                                          setState(() => _categoria = value),
                                    ),
                                    _DropdownField(
                                      value: _prioridade,
                                      label: 'Prioridade',
                                      icon: Icons.priority_high_rounded,
                                      values:
                                          SugestaoBaseFestaOptions.prioridades,
                                      onChanged: (value) =>
                                          setState(() => _prioridade = value),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              _FormSection(
                                icon: Icons.segment_outlined,
                                title: 'Segmentação',
                                subtitle:
                                    'Use listas separadas por vírgula. Use “todos” quando a regra for genérica.',
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _TextField(
                                      controller: _tipoEventoController,
                                      label: 'Tipos de evento',
                                      hint:
                                          'Ex.: todos, aniversario_infantil, cha_de_bebe',
                                      icon: Icons.celebration_rounded,
                                    ),
                                    const SizedBox(height: 10),
                                    _TextField(
                                      controller: _perfisFestaController,
                                      label: 'Perfis de festa',
                                      hint:
                                          'Ex.: todos, economico, padrao, premium',
                                      icon: Icons.workspace_premium_rounded,
                                    ),
                                    const SizedBox(height: 10),
                                    _TextField(
                                      controller: _tagsController,
                                      label: 'Tags',
                                      hint: 'Ex.: bebidas, duracao, consumo',
                                      icon: Icons.tag_rounded,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              _FormSection(
                                icon: Icons.rule_folder_outlined,
                                title: 'Regras e publicação',
                                subtitle:
                                    'Gatilhos ajudam a IA a entender quando a sugestão deve ganhar mais importância.',
                                child: _ResponsiveWrap(
                                  children: [
                                    _TextField(
                                      controller: _ordemController,
                                      label: 'Ordem',
                                      icon: Icons.sort_rounded,
                                      keyboardType: TextInputType.number,
                                    ),
                                    _TextField(
                                      controller: _duracaoMinimaController,
                                      label: 'Duração mínima (h)',
                                      icon: Icons.schedule_rounded,
                                      keyboardType: TextInputType.number,
                                    ),
                                    _TextField(
                                      controller: _riscoMinimoController,
                                      label: 'Risco mínimo (%)',
                                      icon: Icons.warning_amber_rounded,
                                      keyboardType: TextInputType.number,
                                    ),
                                    _SwitchCard(
                                      value: _ativo,
                                      onChanged: (value) =>
                                          setState(() => _ativo = value),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _Actions(onSave: _salvar),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final gatilhos = <String, dynamic>{..._base.gatilhos};
    final duracaoMinima = int.tryParse(_duracaoMinimaController.text.trim());
    final riscoMinimo = int.tryParse(_riscoMinimoController.text.trim());

    if (duracaoMinima != null && duracaoMinima > 0) {
      gatilhos['duracao_minima_horas'] = duracaoMinima;
    } else {
      gatilhos.remove('duracao_minima_horas');
    }

    if (riscoMinimo != null && riscoMinimo > 0) {
      gatilhos['risco_minimo'] = riscoMinimo;
    } else {
      gatilhos.remove('risco_minimo');
    }

    final sugestao = _base.copyWith(
      titulo: _tituloController.text.trim(),
      descricao: _descricaoController.text.trim(),
      modulo: SugestaoBaseFestaModel.normalizeToken(_modulo),
      tema: SugestaoBaseFestaModel.normalizeToken(_temaController.text.trim()),
      tipoEvento: _parseList(_tipoEventoController.text, fallback: ['todos']),
      perfisFesta: _parseList(_perfisFestaController.text, fallback: ['todos']),
      categoria: SugestaoBaseFestaModel.normalizeToken(_categoria),
      prioridade: SugestaoBaseFestaModel.normalizeToken(_prioridade),
      tags: _parseList(_tagsController.text),
      ordem: int.tryParse(_ordemController.text.trim()) ?? 0,
      ativo: _ativo,
      gatilhos: gatilhos,
    );

    await controller.salvar(sugestao);

    if (mounted) Navigator.of(context).pop();
  }

  List<String> _parseList(String value, {List<String> fallback = const []}) {
    final list = value
        .split(',')
        .map(SugestaoBaseFestaModel.normalizeToken)
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    return list.isEmpty ? fallback : list;
  }

  String _mapValueAsString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isEditing});

  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 8, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.18),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.psychology_alt_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEditing ? 'Editar sugestão IA' : 'Nova sugestão IA',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Base curada usada como contexto pela IA',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color
                        ?.withValues(alpha: 0.68),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Fechar',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _InstructionPanel extends StatelessWidget {
  const _InstructionPanel({required this.isEditing});

  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isEditing
                  ? 'Atualize apenas o necessário. Mantenha título, tema e segmentação objetivos para a IA encontrar a regra correta.'
                  : 'Cadastre uma orientação curta, objetiva e reaproveitável. A IA usará esta base como referência, sem recalcular quantidades.',
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.25,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.2,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.62),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ResponsiveWrap extends StatelessWidget {
  const _ResponsiveWrap({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 640;
        final itemWidth =
            isWide ? (constraints.maxWidth - 10) / 2 : constraints.maxWidth;

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

class _Actions extends StatelessWidget {
  const _Actions({required this.onSave});

  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SugestaoBaseFestaController>();
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.18),
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useColumn = constraints.maxWidth < 340;
          final cancelButton = OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
            label: const Text('Cancelar'),
          );

          final saveButton = Obx(
            () => FilledButton.icon(
              onPressed: controller.saving.value ? null : onSave,
              icon: controller.saving.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(controller.saving.value ? 'Salvando...' : 'Salvar'),
            ),
          );

          if (useColumn) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: double.infinity, child: saveButton),
                const SizedBox(height: 8),
                SizedBox(width: double.infinity, child: cancelButton),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: cancelButton),
              const SizedBox(width: 10),
              Expanded(child: saveButton),
            ],
          );
        },
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      textInputAction:
          maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.label,
    required this.icon,
    required this.values,
    required this.onChanged,
  });

  final String value;
  final String label;
  final IconData icon;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final safeValue = values.contains(value) ? value : values.first;

    return DropdownButtonFormField<String>(
      value: safeValue,
      isExpanded: true,
      items: values
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}

class _SwitchCard extends StatelessWidget {
  const _SwitchCard({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(
            value
                ? Icons.check_circle_rounded
                : Icons.pause_circle_outline_rounded,
            color: value ? Colors.green.shade700 : Colors.grey.shade600,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value ? 'Ativa' : 'Inativa',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
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
