// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../../controllers/convidado/cardapio_controller.dart';
import './../../../../core/utils/form_validators.dart';
import './../../../../data/models/cardapio/cardapio_item_model.dart';
import './../../../../controllers/tema/event_theme_controller.dart';

class EditarItemCardapioBottomSheet extends StatefulWidget {
  final String idCardapio;
  final CardapioItem item;

  const EditarItemCardapioBottomSheet({
    super.key,
    required this.idCardapio,
    required this.item,
  });

  @override
  State<EditarItemCardapioBottomSheet> createState() =>
      _EditarItemCardapioBottomSheetState();
}

class _EditarItemCardapioBottomSheetState
    extends State<EditarItemCardapioBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeCtrl;
  late TipoItemCardapio _tipo;
  late bool _confirmado;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _nomeCtrl = TextEditingController(text: widget.item.nome);
    _tipo = widget.item.tipo;
    _confirmado = widget.item.confirmado;
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final primaryColor = Get.find<EventThemeController>().primaryColor.value;

    return FractionallySizedBox(
      heightFactor: 0.88,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding:
                EdgeInsets.only(left: 16, right: 16, bottom: bottomInset + 16),
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
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _Header(
                      title: 'Editar Item',
                      subtitle: 'Modifique as informações',
                      icon: Icons.edit_rounded,
                      color: primaryColor,
                    ),
                    const SizedBox(height: 10),
                    Divider(
                        height: 1,
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    _textField(
                      controller: _nomeCtrl,
                      label: 'Nome do item',
                      icon: Icons.fastfood_rounded,
                      requiredField: true,
                    ),
                    const SizedBox(height: 16),
                    Text('Tipo do Item',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _tipoChip(
                            'Comida', TipoItemCardapio.comida, primaryColor),
                        _tipoChip(
                            'Bebida', TipoItemCardapio.bebida, primaryColor),
                        _tipoChip('Sobremesa', TipoItemCardapio.sobremesa,
                            primaryColor),
                        _tipoChip('Descartável', TipoItemCardapio.descartavel,
                            primaryColor),
                        _tipoChip(
                            'Outro', TipoItemCardapio.outro, primaryColor),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: theme.colorScheme.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Item confirmado',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13)),
                                Text('Marque se já está garantido no evento.',
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(fontSize: 11)),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _confirmado,
                            activeColor: primaryColor,
                            onChanged: (v) => setState(() => _confirmado = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    _FooterActions(
                      isSaving: _salvando,
                      onSubmit: _salvar,
                      primaryColor: primaryColor,
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

  Widget _tipoChip(String label, TipoItemCardapio valor, Color primaryColor) {
    final selected = _tipo == valor;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => setState(() => _tipo = valor),
      selectedColor: primaryColor.withValues(alpha: 0.2),
      labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: selected ? primaryColor : Colors.black87),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selected ? primaryColor : Colors.grey.shade300),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool requiredField = false,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13),
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      ),
      validator: requiredField
          ? (value) => FormValidators.titulo(value, campo: 'o nome do item', minimo: 2)
          : null,
    );
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);

    try {
      final controller = Get.find<CardapioController>();
      final atualizado = CardapioItem(
        idItem: widget.item.idItem,
        nome: _nomeCtrl.text.trim(),
        tipo: _tipo,
        confirmado: _confirmado,
        idEvento: widget.item.idEvento,
        idCardapio: widget.idCardapio,
      );
      await controller.addItem(widget.idCardapio, atualizado);
      Get.back();
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _Header({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800, fontSize: 16)),
              Text(subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

class _FooterActions extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onSubmit;
  final Color primaryColor;

  const _FooterActions({
    required this.isSaving,
    required this.onSubmit,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isSaving ? null : () => Get.back<void>(),
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Cancelar', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: isSaving ? null : onSubmit,
            icon: isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_outlined, size: 16),
            label: Text(isSaving ? 'Salvando...' : 'Salvar',
                style: const TextStyle(fontSize: 13)),
            style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
          ),
        ),
      ],
    );
  }
}
