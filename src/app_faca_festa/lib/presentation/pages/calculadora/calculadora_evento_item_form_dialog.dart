import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_itens_admin_controller.dart';
import '../../../core/utils/form_validators.dart';
import '../../../data/models/calculadora/calculadora_evento_item_model.dart';
import '../../../data/models/calculadora/calculadora_item_base_model.dart';
import 'calculadora_item_icon_helper.dart';

class CalculadoraEventoItemFormDialog {
  static Future<void> show({CalculadoraEventoItemModel? item}) async {
    await Get.bottomSheet<void>(
      _CalculadoraEventoItemFormContent(item: item),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      ignoreSafeArea: false,
    );
  }
}

class _CalculadoraEventoItemFormContent extends StatefulWidget {
  final CalculadoraEventoItemModel? item;

  const _CalculadoraEventoItemFormContent({this.item});

  @override
  State<_CalculadoraEventoItemFormContent> createState() =>
      _CalculadoraEventoItemFormContentState();
}

class _CalculadoraEventoItemFormContentState
    extends State<_CalculadoraEventoItemFormContent> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomeController;
  late final TextEditingController _categoriaController;
  late final TextEditingController _unidadeController;
  late final TextEditingController _quantidadeController;
  late final TextEditingController _valorController;
  late final TextEditingController _ordemController;
  late final TextEditingController _observacaoController;

  late String _idItemBase;
  late String _tipoEvento;
  late String _publicoAlvo;
  late bool _selecionadoPadrao;
  late bool _obrigatorio;
  late bool _ativo;
  late Set<String> _perfisSelecionados;

  CalculadoraItensAdminController get controller =>
      Get.find<CalculadoraItensAdminController>();

  bool get isEditing => widget.item != null;

  IconData get _iconeItemBaseSelecionado {
    final itemBase = controller.itensBaseAtivos.firstWhereOrNull(
      (item) => item.id == _idItemBase,
    );

    if (itemBase == null) {
      return CalculadoraItemIconHelper.resolverIcone(
        idItemBase: _idItemBase,
        nome: _nomeController.text,
        categoria: _categoriaController.text,
        unidade: _unidadeController.text,
      );
    }

    return CalculadoraItemIconHelper.resolverIcone(
      idItemBase: itemBase.id,
      tipoItem: itemBase.tipoItem,
      nome: itemBase.nome,
      categoria: itemBase.categoriaPadrao,
      unidade: itemBase.unidadePadrao,
      icone: itemBase.icone,
    );
  }

  @override
  void initState() {
    super.initState();

    final item = widget.item;

    _idItemBase = item?.idItemBase ?? '';
    _tipoEvento = _normalizarOpcao(
      item?.tipoEvento,
      CalculadoraItensAdminController.tiposEvento,
      CalculadoraItensAdminController.tiposEvento.first,
    );
    _publicoAlvo = _normalizarOpcao(
      item?.publicoAlvo,
      CalculadoraItensAdminController.publicosAlvo,
      'todos',
    );

    _nomeController = TextEditingController(text: item?.nome ?? '');
    _categoriaController = TextEditingController(text: item?.categoria ?? '');
    _unidadeController =
        TextEditingController(text: item?.unidade ?? 'unidade');
    _quantidadeController = TextEditingController(
      text: item == null
          ? '1'
          : _formatDouble(item.quantidadePorConvidadoEquivalente),
    );
    _valorController = TextEditingController(
      text: item == null ? '0' : _formatDouble(item.valorUnitarioMedio),
    );
    _ordemController = TextEditingController(text: '${item?.ordem ?? 0}');
    _observacaoController = TextEditingController(text: item?.observacao ?? '');

    _selecionadoPadrao = item?.selecionadoPadrao ?? true;
    _obrigatorio = item?.obrigatorio ?? false;
    _ativo = item?.ativo ?? true;
    _perfisSelecionados = item?.perfisFesta.toSet() ??
        CalculadoraItensAdminController.perfisFestaPadrao.toSet();

    if (_idItemBase.isEmpty && controller.itensBaseAtivos.isNotEmpty) {
      _aplicarItemBase(controller.itensBaseAtivos.first,
          sobrescreverCampos: true);
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _categoriaController.dispose();
    _unidadeController.dispose();
    _quantidadeController.dispose();
    _valorController.dispose();
    _ordemController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Material(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(26),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Header(
                          title: isEditing
                              ? 'Editar regra do evento'
                              : 'Nova regra por evento',
                          subtitle: isEditing
                              ? 'Ajuste a quantidade, valores e perfis da calculadora'
                              : 'Configure como um item aparece em um tipo de evento',
                        ),
                        const SizedBox(height: 14),
                        _buildIdPreview(context),
                        const SizedBox(height: 12),
                        Obx(() => _buildItemBaseSelector(context)),
                        const SizedBox(height: 12),
                        _ResponsiveFields(
                          children: [
                            DropdownButtonFormField<String>(
                              value: _tipoEvento,
                              decoration: _decoration(
                                label: 'Tipo de evento',
                                icon: Icons.event_outlined,
                              ),
                              items: CalculadoraItensAdminController.tiposEvento
                                  .map(
                                    (value) => DropdownMenuItem(
                                      value: value,
                                      child: Text(
                                          controller.labelTipoEvento(value)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: isEditing
                                  ? null
                                  : (value) {
                                      if (value == null) return;
                                      setState(() => _tipoEvento = value);
                                    },
                            ),
                            _textField(
                              controller: _nomeController,
                              label: 'Nome',
                              icon: _iconeItemBaseSelecionado,
                              requiredField: true,
                            ),
                            _textField(
                              controller: _categoriaController,
                              label: 'Categoria',
                              icon: Icons.category_outlined,
                              requiredField: true,
                            ),
                            _textField(
                              controller: _unidadeController,
                              label: 'Unidade',
                              icon: Icons.straighten_outlined,
                              requiredField: true,
                            ),
                            DropdownButtonFormField<String>(
                              value: _publicoAlvo,
                              decoration: _decoration(
                                label: 'Público-alvo',
                                icon: Icons.groups_2_outlined,
                              ),
                              items:
                                  CalculadoraItensAdminController.publicosAlvo
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
                              controller: _quantidadeController,
                              label: 'Qtd. por convidado equivalente',
                              icon: Icons.calculate_outlined,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              requiredField: true,
                            ),
                            _textField(
                              controller: _valorController,
                              label: 'Valor unitário médio',
                              icon: Icons.attach_money_outlined,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              requiredField: true,
                            ),
                            _textField(
                              controller: _ordemController,
                              label: 'Ordem',
                              icon: Icons.sort_outlined,
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Perfis da festa',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              CalculadoraItensAdminController.perfisFestaPadrao
                                  .map(
                                    (perfil) => FilterChip(
                                      label: Text(_labelPerfil(perfil)),
                                      selected:
                                          _perfisSelecionados.contains(perfil),
                                      onSelected: (selected) {
                                        setState(() {
                                          if (selected) {
                                            _perfisSelecionados.add(perfil);
                                          } else {
                                            _perfisSelecionados.remove(perfil);
                                          }
                                        });
                                      },
                                    ),
                                  )
                                  .toList(),
                        ),
                        const SizedBox(height: 12),
                        _textField(
                          controller: _observacaoController,
                          label: 'Observação',
                          icon: Icons.notes_outlined,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 10),
                        _SwitchGrid(
                          children: [
                            SwitchListTile.adaptive(
                              value: _selecionadoPadrao,
                              title: const Text('Selecionado por padrão'),
                              contentPadding: EdgeInsets.zero,
                              onChanged: (value) => setState(
                                () => _selecionadoPadrao = value,
                              ),
                            ),
                            SwitchListTile.adaptive(
                              value: _obrigatorio,
                              title: const Text('Obrigatório'),
                              contentPadding: EdgeInsets.zero,
                              onChanged: (value) => setState(
                                () => _obrigatorio = value,
                              ),
                            ),
                            SwitchListTile.adaptive(
                              value: _ativo,
                              title: const Text('Ativo'),
                              contentPadding: EdgeInsets.zero,
                              onChanged: (value) =>
                                  setState(() => _ativo = value),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Obx(
                          () => Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: controller.saving.value
                                      ? null
                                      : () => Get.back<void>(),
                                  icon: const Icon(Icons.close),
                                  label: const Text('Cancelar'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed:
                                      controller.saving.value ? null : _submit,
                                  icon: controller.saving.value
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.save_outlined),
                                  label: Text(
                                    controller.saving.value
                                        ? 'Salvando...'
                                        : 'Salvar',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdPreview(BuildContext context) {
    final theme = Theme.of(context);
    final id = widget.item?.id ??
        controller.gerarIdItemEvento(
          tipoEvento: _tipoEvento,
          idItemBase: _idItemBase,
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        isEditing
            ? 'ID do documento: $id'
            : 'ID gerado ao salvar: ${id.trim().isEmpty ? 'selecione item e evento' : id}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildItemBaseSelector(BuildContext context) {
    final itensBase = controller.itensBaseAtivos;

    if (itensBase.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .errorContainer
              .withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text(
          'Cadastre ou ative pelo menos um item base antes de criar regras por evento.',
        ),
      );
    }

    final selectedValue = itensBase.any((item) => item.id == _idItemBase)
        ? _idItemBase
        : itensBase.first.id;

    if (_idItemBase.isEmpty || _idItemBase != selectedValue) {
      _idItemBase = selectedValue;
    }

    return DropdownButtonFormField<String>(
      value: selectedValue,
      decoration: _decoration(
        label: 'Item base',
        icon: _iconeItemBaseSelecionado,
      ),
      items: itensBase
          .map(
            (item) => DropdownMenuItem(
              value: item.id,
              child: _ItemBaseDropdownLabel(item: item),
            ),
          )
          .toList(),
      onChanged: isEditing
          ? null
          : (value) {
              final itemBase = itensBase.firstWhereOrNull(
                (item) => item.id == value,
              );
              if (itemBase == null) return;
              setState(() => _aplicarItemBase(itemBase));
            },
    );
  }

  void _aplicarItemBase(
    CalculadoraItemBaseModel item, {
    bool sobrescreverCampos = false,
  }) {
    _idItemBase = item.id;

    if (sobrescreverCampos || _nomeController.text.trim().isEmpty) {
      _nomeController.text = item.nome;
    }

    if (sobrescreverCampos || _categoriaController.text.trim().isEmpty) {
      _categoriaController.text = item.categoriaPadrao;
    }

    if (sobrescreverCampos || _unidadeController.text.trim().isEmpty) {
      _unidadeController.text = item.unidadePadrao;
    }

    _publicoAlvo = _normalizarOpcao(
      item.publicoAlvo,
      CalculadoraItensAdminController.publicosAlvo,
      'todos',
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_idItemBase.trim().isEmpty) {
      Get.snackbar(
        'Atenção',
        'Selecione um item base.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_perfisSelecionados.isEmpty) {
      Get.snackbar(
        'Atenção',
        'Selecione pelo menos um perfil de festa.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final now = DateTime.now();
    final id = widget.item?.id ??
        controller.gerarIdItemEvento(
          tipoEvento: _tipoEvento,
          idItemBase: _idItemBase,
        );

    final item = CalculadoraEventoItemModel(
      id: id,
      idItemBase: _idItemBase,
      tipoEvento: _tipoEvento,
      nome: _nomeController.text.trim(),
      categoria: _categoriaController.text.trim(),
      unidade: controller.normalizarChave(_unidadeController.text),
      publicoAlvo: _publicoAlvo,
      quantidadePorConvidadoEquivalente: _parseDouble(
        _quantidadeController.text,
      ),
      valorUnitarioMedio: _parseDouble(_valorController.text),
      perfisFesta: _perfisSelecionados.toList()..sort(),
      selecionadoPadrao: _selecionadoPadrao,
      obrigatorio: _obrigatorio,
      ativo: _ativo,
      ordem: int.tryParse(_ordemController.text.trim()) ?? 0,
      observacao: _observacaoController.text.trim(),
      createdAt: widget.item?.createdAt ?? now,
      updatedAt: now,
    );

    controller.salvarItemEvento(item);
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    bool requiredField = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: _decoration(label: label, icon: icon),
      validator: requiredField
          ? (value) => FormValidators.titulo(value,
              campo: label.toLowerCase(), minimo: 2)
          : null,
    );
  }

  InputDecoration _decoration({
    required String label,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon == null ? null : Icon(icon, size: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      isDense: true,
    );
  }

  double _parseDouble(String value) {
    final normalized = value
        .trim()
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');

    return double.tryParse(normalized) ?? 0.0;
  }

  String _formatDouble(double value) {
    final text = value.toStringAsFixed(2);
    if (text.endsWith('00')) return value.toStringAsFixed(0);
    if (text.endsWith('0')) return value.toStringAsFixed(1);
    return text;
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

  String _labelPerfil(String value) {
    switch (value) {
      case 'economico':
        return 'Econômico';
      case 'premium':
        return 'Premium';
      default:
        return 'Padrão';
    }
  }
}

class _ItemBaseDropdownLabel extends StatelessWidget {
  final CalculadoraItemBaseModel item;

  const _ItemBaseDropdownLabel({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = CalculadoraItemIconHelper.resolverIcone(
      idItemBase: item.id,
      tipoItem: item.tipoItem,
      nome: item.nome,
      categoria: item.categoriaPadrao,
      unidade: item.unidadePadrao,
      icone: item.icone,
    );

    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${item.nome}  •  ${item.categoriaPadrao}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
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
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.rule_folder_outlined,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Get.back<void>(),
          icon: const Icon(Icons.close),
        ),
      ],
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
        final isWide = constraints.maxWidth >= 700;
        final itemWidth =
            isWide ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;

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

class _SwitchGrid extends StatelessWidget {
  final List<Widget> children;

  const _SwitchGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        final itemWidth =
            isWide ? (constraints.maxWidth - 24) / 3 : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 4,
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
