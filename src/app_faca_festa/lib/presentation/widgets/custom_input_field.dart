import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../controllers/tema/event_theme_controller.dart';

enum InputType {
  text,
  email,
  password,
  phone,
  number,
  cpfCnpj,
  money,
  multiline,
  search,
  cep,
}

class CustomInputField extends StatefulWidget {
  final String label;
  final String? hintlabel;
  final IconData icon;
  final TextEditingController controller;

  // Personalização visual
  final Color? color;
  final Color? colorIcon;
  final Color? titleColor;
  final bool readOnly;
  final bool enabled;
  final FocusNode? focusNode;
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
  final InputType type;

  const CustomInputField({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    this.hintlabel,
    this.color,
    this.colorIcon,
    this.titleColor,
    this.readOnly = false,
    this.enabled = true,
    this.focusNode,
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
    this.type = InputType.text,
  });

  @override
  State<CustomInputField> createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField> {
  final themeController = Get.find<EventThemeController>();
  bool isFocused = false;
  bool showPassword = false;

  MaskTextInputFormatter? maskFormatter;
  late TextInputType finalKeyboardType;

  @override
  void initState() {
    super.initState();
    _configureType();
  }

  // =====================================================
  // CONFIGURAÇÃO AUTOMÁTICA DOS TIPOS DE INPUT
  // =====================================================
  void _configureType() {
    if (!widget.autoFormat) {
      finalKeyboardType = widget.keyboardType ?? TextInputType.text;
      return;
    }

    switch (widget.type) {
      case InputType.email:
        finalKeyboardType = TextInputType.emailAddress;
        break;
      case InputType.cep:
        finalKeyboardType = TextInputType.number;
        maskFormatter = MaskTextInputFormatter(mask: '#####-###');
        break;
      case InputType.password:
        finalKeyboardType = TextInputType.visiblePassword;
        break;

      case InputType.phone:
        finalKeyboardType = TextInputType.phone;
        maskFormatter = MaskTextInputFormatter(mask: '(##) #####-####');
        break;

      case InputType.number:
        finalKeyboardType = TextInputType.number;
        break;

      case InputType.cpfCnpj:
        finalKeyboardType = TextInputType.number;
        maskFormatter = MaskTextInputFormatter(mask: '###.###.###-##');
        break;

      case InputType.money:
        finalKeyboardType = TextInputType.number;
        break;

      case InputType.multiline:
        finalKeyboardType = TextInputType.multiline;
        break;

      default:
        finalKeyboardType = widget.keyboardType ?? TextInputType.text;
        break;
    }
  }

  // =====================================================
  // WIDGET FINAL
  // =====================================================
  @override
  Widget build(BuildContext context) {
    Color bgColor = Colors.white;
    Color textColor = Colors.black87;
    Color iconColor = widget.colorIcon ?? themeController.primaryColor.value;
    Color titleColor = widget.titleColor ?? Colors.white;

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      borderSide: BorderSide(color: iconColor.withValues(alpha: 0.25)),
    );

    return AnimatedContainer(
      duration: 300.ms,
      margin: widget.margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LABEL EXTERNO (não flutua, não sobe demais)
          Text(
            widget.label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: titleColor.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 6),

          Focus(
            onFocusChange: (f) => setState(() => isFocused = f),
            child: TextFormField(
              controller: widget.controller,
              validator: widget.validator,
              readOnly: widget.readOnly,
              enabled: widget.enabled,
              focusNode: widget.focusNode,
              onTap: widget.onTap,
              maxLength: widget.maxLength,
              maxLines: widget.maxLines ?? (widget.type == InputType.multiline ? 4 : 1),
              obscureText: widget.type == InputType.password ? !showPassword : widget.obscureText,
              keyboardType: finalKeyboardType,
              onChanged: widget.onChanged,
              cursorColor: iconColor,
              inputFormatters: [
                if (maskFormatter != null) maskFormatter!,
                if (widget.type == InputType.money)
                  CurrencyTextInputFormatter(
                    NumberFormat.currency(
                      locale: 'pt_BR',
                      symbol: 'R\$',
                      decimalDigits: 2,
                    ),
                    enableNegative: false,
                    inputDirection: InputDirection.right,
                  ),
              ],
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(widget.icon, size: 22, color: iconColor),
                ),

                suffixIcon: widget.type == InputType.password
                    ? IconButton(
                        icon: Icon(
                          showPassword ? Icons.visibility : Icons.visibility_off,
                          color: iconColor,
                        ),
                        onPressed: () => setState(() => showPassword = !showPassword),
                      )
                    : widget.suffixIcon,

                filled: true,
                fillColor: bgColor,

                // Correção do label subindo demais
                floatingLabelBehavior: FloatingLabelBehavior.never,

                hintText: widget.hintlabel ?? "Digite a ${widget.label.toLowerCase()}...",
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: titleColor,
                ),

                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 14,
                ),

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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
