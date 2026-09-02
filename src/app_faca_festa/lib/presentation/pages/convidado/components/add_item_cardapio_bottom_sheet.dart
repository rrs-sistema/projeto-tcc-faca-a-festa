// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import '../../../../core/utils/form_validators.dart';
import '../../../../data/models/cardapio/cardapio_model.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/cardapio_controller.dart';
import './../../../../data/models/cardapio/cardapio_item_model.dart';

class AddItemCardapioBottomSheet extends StatefulWidget {
  final String idCardapio;
  final String? idEvento;

  const AddItemCardapioBottomSheet({
    super.key,
    required this.idCardapio,
    this.idEvento,
  });

  @override
  State<AddItemCardapioBottomSheet> createState() =>
      _AddItemCardapioBottomSheetState();
}

class _AddItemCardapioBottomSheetState
    extends State<AddItemCardapioBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeCtrl;
  TipoItemCardapio _tipo = TipoItemCardapio.comida;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _nomeCtrl = TextEditingController();
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
                      title: 'Novo Item',
                      subtitle: 'Adicione comida, bebida ou outro item',
                      icon: Icons.add_circle_outline_rounded,
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
                        _tipoChip('Bolo', TipoItemCardapio.bolo, primaryColor),
                        _tipoChip('Descartável', TipoItemCardapio.descartavel,
                            primaryColor),
                      ],
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
          ? (value) =>
              FormValidators.titulo(value, campo: 'o nome do item', minimo: 2)
          : null,
    );
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);

    try {
      final controller = Get.find<CardapioController>();
      final idEvento = _resolverIdEvento(controller);

      if (idEvento.isEmpty) {
        Get.snackbar(
          'Atenção',
          'Não foi possível identificar o evento deste cardápio.',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        return;
      }

      final novoItem = CardapioItem(
        idItem: '',
        idEvento: idEvento,
        idCardapio: widget.idCardapio,
        nome: _nomeCtrl.text.trim(),
        tipo: _tipo,
        publicoAlvo: PublicoAlvoCardapio.todos,
        quantidadeSugerida: 0,
        quantidadeFinal: 0,
        unidade: 'un',
        confirmado: false,
        geradoPelaCalculadora: false,
      );

      await controller.addItem(widget.idCardapio, novoItem);
      Get.back();
    } catch (_) {
      Get.snackbar(
        'Não foi possível salvar o item',
        'Verifique se você é o organizador deste evento e tente novamente.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  String _resolverIdEvento(CardapioController controller) {
    final idEventoInformado = widget.idEvento?.trim() ?? '';
    if (idEventoInformado.isNotEmpty) return idEventoInformado;

    for (final cardapio in controller.cardapios) {
      if (cardapio.idCardapio == widget.idCardapio) {
        return cardapio.idEvento;
      }
    }
    return '';
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
