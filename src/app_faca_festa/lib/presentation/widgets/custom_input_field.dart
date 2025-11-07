import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

import '../../controllers/tema/event_theme_controller.dart';

class CustomInputField extends StatefulWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;

  // Personalização visual
  final Color? color;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextInputType? keyboardType;
  final int? maxLength;
  final int? maxLines;
  final String? Function(String?)? validator;
  final bool obscureText;
  final double borderRadius;
  final EdgeInsets margin;
  final void Function(String)? onChanged;
  final Widget? suffixIcon;
  final bool autoFormat;

  const CustomInputField({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    this.color,
    this.readOnly = false,
    this.onTap,
    this.keyboardType,
    this.maxLength,
    this.maxLines,
    this.validator,
    this.obscureText = false,
    this.borderRadius = 14,
    this.margin = const EdgeInsets.only(bottom: 16),
    this.onChanged,
    this.suffixIcon,
    this.autoFormat = true,
  });

  @override
  State<CustomInputField> createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField> {
  final themeController = Get.find<EventThemeController>();
  bool isFocused = false;
  MaskTextInputFormatter? maskFormatter;
  late TextInputType keyboardType;

  @override
  void initState() {
    super.initState();
    if (widget.autoFormat) _configurarMascara();
  }

  void _configurarMascara() {
    final label = widget.label.toLowerCase();
    if (label.contains('telefone')) {
      maskFormatter = MaskTextInputFormatter(mask: '(##) #####-####');
      keyboardType = TextInputType.phone;
      return;
    }
    if (label.contains('cpf') || label.contains('cnpj')) {
      keyboardType = TextInputType.number;
      return;
    }
    if (label.contains('cep')) {
      maskFormatter = MaskTextInputFormatter(mask: '#####-###');
      keyboardType = TextInputType.number;
      return;
    }
    if (label.contains('email')) {
      keyboardType = TextInputType.emailAddress;
      return;
    }
    keyboardType = widget.keyboardType ?? TextInputType.text;
  }

  @override
  Widget build(BuildContext context) {
    final tipo = (Get.arguments?['tipo'] ?? 'O').toString(); // F, O, C
    final gradient = themeController.gradient.value;

    // 🎨 Paletas distintas
    Color bgColor;
    Color textColor;
    Color iconColor;
    Color labelColor;

    switch (tipo) {
      case 'F': // Fornecedor
        bgColor = Colors.black.withValues(alpha: 0.65);
        textColor = Colors.white;
        iconColor = Colors.white;
        labelColor = Colors.grey.shade400;
        break;
      case 'O': // Organizador
        final base = gradient.colors.first;
        final darker = HSLColor.fromColor(base)
            .withLightness(
              (HSLColor.fromColor(base).lightness - 0.10).clamp(0.0, 1.0),
            )
            .toColor();

        // Campos em tom claro, contraste alto sobre fundo verde
        bgColor = Colors.white.withValues(alpha: 0.95);
        textColor = Colors.grey.shade900;
        iconColor = darker;
        labelColor = darker.withValues(alpha: 0.8);
        break;

      case 'C': // Convidado
        bgColor = Colors.white;
        textColor = Colors.blueGrey.shade800;
        iconColor = Colors.teal;
        labelColor = Colors.blueGrey.shade500;
        break;
      default:
        bgColor = Colors.white;
        textColor = Colors.black87;
        iconColor = Colors.black54;
        labelColor = Colors.grey.shade600;
    }

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      borderSide: BorderSide(color: iconColor.withValues(alpha: 0.25)),
    );

    return AnimatedContainer(
      duration: 300.ms,
      margin: widget.margin,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: [
          if (isFocused)
            BoxShadow(
              color: iconColor.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Focus(
        onFocusChange: (focus) => setState(() => isFocused = focus),
        child: TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          onChanged: widget.onChanged,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          obscureText: widget.obscureText,
          keyboardType: keyboardType,
          inputFormatters: maskFormatter != null ? [maskFormatter!] : [],
          cursorColor: iconColor,
          style: GoogleFonts.poppins(
            fontSize: 15.5,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
          decoration: InputDecoration(
            prefixIcon: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(widget.icon, size: 22, color: iconColor),
            ),
            suffixIcon: widget.suffixIcon,
            labelText: widget.label,
            labelStyle: GoogleFonts.poppins(
              color: isFocused ? iconColor : labelColor,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            floatingLabelStyle: GoogleFonts.poppins(
              color: iconColor.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            floatingLabelBehavior: FloatingLabelBehavior.auto, // ✅ volta ao comportamento padrão
            filled: true,
            fillColor: bgColor, // ✅ mantém o fundo visível
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: BorderSide(color: iconColor, width: 1.5),
            ),
            errorBorder: border.copyWith(
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.3),
            ),
            focusedErrorBorder: border.copyWith(
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.3),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
          ),
        ),
      ),
    );
  }
}
