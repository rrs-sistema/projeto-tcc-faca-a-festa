// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/presentation/modules/convidado/controllers/cardapio_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import './../../../../core/utils/form_validators.dart';
import './../../../../data/models/cardapio/cardapio_model.dart';

class CadastroCardapioBottomSheet extends StatefulWidget {
  final String idEvento;
  const CadastroCardapioBottomSheet({super.key, required this.idEvento});

  @override
  State<CadastroCardapioBottomSheet> createState() =>
      _CadastroCardapioBottomSheetState();
}

class _CadastroCardapioBottomSheetState
    extends State<CadastroCardapioBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tituloCtrl;

  IconData _iconeSelecionado = Icons.restaurant_menu;
  Color _corSelecionada = Colors.teal;
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
    _tituloCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
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
                      title: 'Novo Cardápio',
                      subtitle: 'Crie uma nova categoria de itens',
                      icon: Icons.menu_book_rounded,
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
                      hint: 'Ex.: Comidas, Bebidas...',
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
    String? hint,
    bool requiredField = false,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
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
              FormValidators.titulo(value, campo: 'o título', minimo: 2)
          : null,
    );
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);

    try {
      final controller = Get.find<CardapioController>();
      final novo = Cardapio(
        idCardapio: DateTime.now().millisecondsSinceEpoch.toString(),
        idEvento: widget.idEvento,
        titulo: _tituloCtrl.text.trim(),
        icone: _iconeSelecionado.codePoint.toString(),
        corHex: _colorToHex(_corSelecionada),
        publicoAlvo: PublicoAlvoCardapio.todos,
        totalItens: 0,
        totalComidas: 0,
        totalBebidas: 0,
        totalSobremesas: 0,
        ativo: true,
      );
      await controller.adicionarCardapio(novo);
      Get.back();
    } catch (_) {
      Get.snackbar(
        'Não foi possível salvar o cardápio',
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

  String _colorToHex(Color color) {
    String channelToHex(double value) =>
        (value * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    return '#${channelToHex(color.a)}${channelToHex(color.r)}${channelToHex(color.g)}${channelToHex(color.b)}'
        .toUpperCase();
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
