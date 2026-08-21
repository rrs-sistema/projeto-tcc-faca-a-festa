// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../../controllers/convidado/cardapio_controller.dart';
import './../../../../controllers/tema/event_theme_controller.dart';
import './../../../../data/models/cardapio/cardapio_model.dart';

class EditarCardapioBottomSheet extends StatefulWidget {
  final Cardapio cardapio;
  const EditarCardapioBottomSheet({super.key, required this.cardapio});

  @override
  State<EditarCardapioBottomSheet> createState() =>
      _EditarCardapioBottomSheetState();
}

class _EditarCardapioBottomSheetState extends State<EditarCardapioBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tituloCtrl;

  late IconData _iconeSelecionado;
  late Color _corSelecionada;
  bool _salvando = false;

  final icones = [
    Icons.restaurant_menu,
    Icons.child_care,
    Icons.cake,
    Icons.local_drink,
    Icons.fastfood,
    Icons.local_pizza,
  ];

  final cores = [
    Colors.teal,
    Colors.pinkAccent,
    Colors.orange,
    Colors.blueAccent,
    Colors.green,
    Colors.purple,
  ];

  @override
  void initState() {
    super.initState();
    _tituloCtrl = TextEditingController(text: widget.cardapio.titulo);
    _iconeSelecionado = _iconFromString(widget.cardapio.icone);
    _corSelecionada =
        _colorFromHex(widget.cardapio.corHex, fallback: Colors.teal);
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    super.dispose();
  }

  IconData _iconFromString(String? value) {
    final iconKey = (value ?? '').trim().toLowerCase();

    switch (iconKey) {
      case 'bolo':
      case 'cake':
        return Icons.cake_rounded;

      case 'bebida':
      case 'bebidas':
      case 'drink':
        return Icons.local_drink_rounded;

      case 'docinho':
      case 'docinhos':
      case 'sobremesa':
      case 'sobremesas':
        return Icons.emoji_food_beverage_rounded;

      case 'salgado':
      case 'salgados':
      case 'salgadinho':
      case 'salgadinhos':
        return Icons.fastfood_rounded;

      case 'almoco':
      case 'almoço':
      case 'jantar':
      case 'refeicao':
      case 'refeição':
        return Icons.dinner_dining_rounded;

      case 'buffet':
      case 'cardapio':
      case 'cardápio':
      case 'menu':
        return Icons.restaurant_menu_rounded;

      default:
        return Icons.restaurant_menu_rounded;
    }
  }

  Color _colorFromHex(String? hex, {Color fallback = Colors.teal}) {
    try {
      if (hex == null || hex.trim().isEmpty) return fallback;
      var value = hex.replaceAll('#', '').trim();
      if (value.length == 6) value = 'FF$value';
      return Color(int.parse(value, radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  String _colorToHex(Color color) {
    String channelToHex(double value) =>
        (value * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    return '#${channelToHex(color.a)}${channelToHex(color.r)}${channelToHex(color.g)}${channelToHex(color.b)}'
        .toUpperCase();
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
                      title: 'Editar Cardápio',
                      subtitle: 'Altere a categoria de itens',
                      icon: Icons.edit_note_rounded,
                      color: primaryColor,
                    ),
                    const SizedBox(height: 10),
                    Divider(
                        height: 1,
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    _textField(
                      controller: _tituloCtrl,
                      label: 'Título',
                      icon: Icons.text_fields,
                      requiredField: true,
                    ),
                    const SizedBox(height: 16),
                    Text('Ícone',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: icones
                          .map((icon) => _buildIconOption(icon, primaryColor))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    Text('Cor',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: cores
                          .map((color) => _buildColorOption(color))
                          .toList(),
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

  Widget _buildIconOption(IconData icon, Color primaryColor) {
    final selected = _iconeSelecionado == icon;
    return GestureDetector(
      onTap: () => setState(() => _iconeSelecionado = icon),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected
              ? primaryColor.withValues(alpha: 0.15)
              : Colors.transparent,
          shape: BoxShape.circle,
          border:
              Border.all(color: selected ? primaryColor : Colors.grey.shade300),
        ),
        child: Icon(icon,
            color: selected ? primaryColor : Colors.black54, size: 24),
      ),
    );
  }

  Widget _buildColorOption(Color color) {
    final selected = _corSelecionada == color;
    return GestureDetector(
      onTap: () => setState(() => _corSelecionada = color),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
              color: selected ? Colors.black54 : Colors.transparent,
              width: selected ? 2 : 0),
        ),
        child: selected
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : null,
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
          ? (value) => (value == null || value.trim().isEmpty)
              ? 'Campo obrigatório'
              : null
          : null,
    );
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);

    try {
      final controller = Get.find<CardapioController>();
      final atualizado = Cardapio(
        idCardapio: widget.cardapio.idCardapio,
        idEvento: widget.cardapio.idEvento,
        titulo: _tituloCtrl.text.trim(),
        icone: _iconeSelecionado.codePoint.toString(),
        corHex: _colorToHex(_corSelecionada),
        publicoAlvo: widget.cardapio.publicoAlvo,
        totalItens: widget.cardapio.totalItens,
        totalComidas: widget.cardapio.totalComidas,
        totalBebidas: widget.cardapio.totalBebidas,
        totalSobremesas: widget.cardapio.totalSobremesas,
        ativo: widget.cardapio.ativo,
      );
      await controller.atualizarCardapio(atualizado);
      Get.back();
    } catch (_) {
      Get.snackbar(
        'Não foi possível atualizar o cardápio',
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
