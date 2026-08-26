import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../controllers/tema/event_theme_controller.dart';
import './../../core/utils/form_masks.dart';
import './../../core/utils/form_validators.dart';

enum InputType {
  text,
  email,
  password,
  phone,
  number,
  cpf,
  cnpj,
  cpfCnpj,
  money,
  multiline,
  search,
  cep,
}

class CustomInputField extends StatefulWidget {
  final String label;
  final String? hintlabel;
  final IconData? icon;
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

  // Validação
  final String? Function(String?)? validator;
  final bool isRequired; // <-- Adicionado: Flag para tornar campo obrigatório de forma simplificada

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
    this.isRequired = false, // <-- Adicionado: Padrão é falso (opcional)
    this.obscureText = false,
    this.borderRadius = 14,
    this.margin = const EdgeInsets.only(bottom: 2),
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
        maskFormatter = FormMasks.telefone();
        break;
      case InputType.number:
        finalKeyboardType = TextInputType.number;
        break;
      case InputType.cpf:
        finalKeyboardType = TextInputType.number;
        maskFormatter = MaskTextInputFormatter(
          mask: '###.###.###-##',
          filter: {'#': RegExp(r'[0-9]')},
        );
        break;
      case InputType.cnpj:
        finalKeyboardType = TextInputType.number;
        maskFormatter = MaskTextInputFormatter(
          mask: '##.###.###/####-##',
          filter: {'#': RegExp(r'[0-9]')},
        );
        break;
      case InputType.cpfCnpj:
        finalKeyboardType = TextInputType.number;
        maskFormatter = MaskTextInputFormatter(
          mask: '###.###.###-##',
          filter: {'#': RegExp(r'[0-9]')},
        );
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
          Text(
            // Adiciona o asterisco dinamicamente no título se for obrigatório
            widget.isRequired ? '${widget.label} *' : widget.label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: titleColor.withValues(alpha: 0.85),
            ),
          ),
          Focus(
            onFocusChange: (f) => setState(() => isFocused = f),
            child: TextFormField(
              controller: widget.controller,

              validator: widget.validator ?? _validarPorTipo,

              readOnly: widget.readOnly,
              enabled: widget.enabled,
              focusNode: widget.focusNode,
              onTap: widget.onTap,
              maxLength: widget.maxLength,
              maxLines: widget.maxLines ?? (widget.type == InputType.multiline ? 4 : 1),
              obscureText: widget.type == InputType.password ? !showPassword : widget.obscureText,
              keyboardType: finalKeyboardType,
              onChanged: _onChanged,
              cursorColor: iconColor,
              inputFormatters: [
                if (maskFormatter != null) maskFormatter!,
                if (widget.type == InputType.money)
                  CurrencyTextInputFormatter.currency(
                    // Atualização sutil para a sintaxe mais recente do pacote, caso aplicável
                    locale: 'pt_BR',
                    symbol: 'R\$',
                    decimalDigits: 2,
                    enableNegative: false,
                  ),
              ],
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(8),
                  child: widget.icon != null ? Icon(widget.icon, size: 22, color: iconColor) : null,
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
                floatingLabelBehavior: FloatingLabelBehavior.never,
                hintText: widget.hintlabel ?? "Digite o(a) ${widget.label.toLowerCase()}...",
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: textColor.withValues(
                      alpha: 0.6), // Leve ajuste de opacidade no hint para contraste mais limpo
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 14,
                ),
                enabledBorder: border,
                focusedBorder: border.copyWith(
                  borderSide: BorderSide(color: iconColor, width: 1.5),
                ),
                errorMaxLines: 3,
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

  void _onChanged(String value) {
    if (widget.type == InputType.cpfCnpj && maskFormatter != null) {
      final digitos = value.replaceAll(RegExp(r'\D'), '');
      final novaMascara =
          digitos.length > 11 ? '##.###.###/####-##' : '###.###.###-##';
      if (maskFormatter!.getMask() != novaMascara) {
        maskFormatter!.updateMask(mask: novaMascara);
      }
    }
    if (widget.type == InputType.phone && maskFormatter != null) {
      FormMasks.atualizarTelefone(
        maskFormatter!,
        value,
        controller: widget.controller,
      );
    }
    widget.onChanged?.call(value);
  }

  String? _validarPorTipo(String? value) {
    switch (widget.type) {
      case InputType.email:
        return FormValidators.email(value, obrigatorio: widget.isRequired);
      case InputType.password:
        return FormValidators.senha(value, obrigatorio: widget.isRequired);
      case InputType.phone:
        return FormValidators.telefone(value, obrigatorio: widget.isRequired);
      case InputType.cep:
        return FormValidators.cep(value, obrigatorio: widget.isRequired);
      case InputType.cpf:
        return FormValidators.cpf(value, obrigatorio: widget.isRequired);
      case InputType.cnpj:
        return FormValidators.cnpj(value, obrigatorio: widget.isRequired);
      case InputType.cpfCnpj:
        return FormValidators.cpfOuCnpj(value, obrigatorio: widget.isRequired);
      case InputType.money:
        return FormValidators.dinheiro(
          value,
          obrigatorio: widget.isRequired,
          campo: widget.label.toLowerCase(),
        );
      default:
        return widget.isRequired
            ? FormValidators.obrigatorio(
                value,
                campo: widget.label.toLowerCase(),
              )
            : null;
    }
  }
}
