import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

class TituloVinculoAnimado extends StatefulWidget {
  final bool isEdicao;
  final Color primary;

  const TituloVinculoAnimado({
    super.key,
    required this.isEdicao,
    required this.primary,
  });

  @override
  State<TituloVinculoAnimado> createState() => _TituloVinculoAnimadoState();
}

class _TituloVinculoAnimadoState extends State<TituloVinculoAnimado>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titulo = widget.isEdicao ? 'Editando Serviço' : 'Cadastrar Serviço';
    final primary = widget.primary;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.design_services_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                titulo,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
