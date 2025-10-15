import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomInputField extends StatelessWidget {
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
    this.borderRadius = 16,
    this.margin = const EdgeInsets.only(bottom: 16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType,
        maxLength: maxLength,
        obscureText: obscureText,
        style: GoogleFonts.poppins(
          fontSize: 15,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: color),
          labelText: label,
          counterText: "",
          labelStyle: GoogleFonts.poppins(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(color: color.withValues(alpha: 0.7), width: 1.5),
          ),
        ),
      ),
    );
  }
}
