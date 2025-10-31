import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PrimaryActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final RxBool carregando;
  final VoidCallback onPressed;
  final IconData icon;
  final double fontSize;
  final double height;
  final double borderRadius;
  final double elevation;

  const PrimaryActionButton({
    super.key,
    required this.label,
    required this.color,
    required this.carregando,
    required this.onPressed,
    this.icon = Icons.check_circle_outline_rounded,
    this.fontSize = 17,
    this.height = 52,
    this.borderRadius = 14,
    this.elevation = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() => ElevatedButton.icon(
          icon: carregando.value
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(icon, color: Colors.white),
          label: Text(
            carregando.value ? '$label...' : label,
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            minimumSize: Size(double.infinity, height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            elevation: elevation,
          ),
          onPressed: carregando.value ? null : onPressed,
        ));
  }
}
