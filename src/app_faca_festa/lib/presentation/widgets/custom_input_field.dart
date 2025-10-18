import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

class CustomInputField extends StatefulWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final Color color;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextInputType? keyboardType;
  final int? maxLength;
  final String? Function(String?)? validator;
  final bool obscureText;
  final double borderRadius;
  final EdgeInsets margin;
  final void Function(String)? onChanged;

  const CustomInputField({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    required this.color,
    this.readOnly = false,
    this.onTap,
    this.keyboardType,
    this.maxLength,
    this.validator,
    this.obscureText = false,
    this.borderRadius = 14,
    this.margin = const EdgeInsets.only(bottom: 16),
    this.onChanged,
  });

  @override
  State<CustomInputField> createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField> {
  bool isFocused = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.color;
    final focusColor = baseColor.withValues(alpha: 0.85);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
    );

    return FocusScope(
      child: Focus(
        onFocusChange: (focus) => setState(() => isFocused = focus),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          margin: widget.margin,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: isFocused
                ? LinearGradient(
                    colors: [
                      baseColor.withValues(alpha: 0.05),
                      baseColor.withValues(alpha: 0.02),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: baseColor.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
            color: Colors.white,
          ),
          child: TextFormField(
            controller: widget.controller,
            validator: widget.validator,
            onChanged: widget.onChanged,
            readOnly: widget.readOnly,
            onTap: widget.onTap,
            keyboardType: widget.keyboardType,
            maxLength: widget.maxLength,
            obscureText: widget.obscureText,
            cursorColor: focusColor,
            style: GoogleFonts.poppins(
              fontSize: 15.5,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              prefixIcon: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      baseColor.withValues(alpha: isFocused ? 0.9 : 0.6),
                      baseColor.withValues(alpha: isFocused ? 0.6 : 0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(widget.icon, color: Colors.white, size: 20),
              ),
              labelText: widget.label,
              labelStyle: GoogleFonts.poppins(
                color: isFocused ? baseColor : Colors.grey.shade600,
                fontSize: isFocused ? 15 : 14,
                fontWeight: FontWeight.w500,
              ),
              counterText: "",
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              enabledBorder: border,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                borderSide: BorderSide(color: baseColor, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                borderSide: BorderSide(color: Colors.red.shade400, width: 1.3),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                borderSide: BorderSide(color: Colors.red.shade400, width: 1.3),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
            ),
          ),
        ),
      ),
    );
  }
}
