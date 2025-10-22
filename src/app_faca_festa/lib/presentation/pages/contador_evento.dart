import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class ContadorEventoScreen extends StatefulWidget {
  final DateTime dataEvento;
  final String tipoEvento; // 🔹 novo: tipo do evento

  const ContadorEventoScreen({
    super.key,
    required this.dataEvento,
    required this.tipoEvento,
  });

  @override
  State<ContadorEventoScreen> createState() => _ContadorEventoScreenState();
}

class _ContadorEventoScreenState extends State<ContadorEventoScreen> {
  late Timer _timer;
  Duration _duracaoRestante = Duration.zero;

  @override
  void initState() {
    super.initState();
    _atualizarTempo();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _atualizarTempo());
  }

  void _atualizarTempo() {
    final agora = DateTime.now();
    setState(() {
      _duracaoRestante = widget.dataEvento.difference(agora).isNegative
          ? Duration.zero
          : widget.dataEvento.difference(agora);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  int get dias => _duracaoRestante.inDays;
  int get horas => _duracaoRestante.inHours.remainder(24);
  int get minutos => _duracaoRestante.inMinutes.remainder(60);
  int get segundos => _duracaoRestante.inSeconds.remainder(60);

  /// 🎨 Gradiente dinâmico por tipo de evento
  LinearGradient get _gradientePorTema {
    switch (widget.tipoEvento.toLowerCase()) {
      case 'casamento':
        return const LinearGradient(
          colors: [
            Color(0xFFFFF1F3),
            Color(0xFFFFC1E3),
            Color(0xFFE57373),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'festa infantil':
        return const LinearGradient(
          colors: [
            Color(0xFFFFF8E1),
            Color(0xFFFFCC80),
            Color(0xFFFFA726),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'chá de bebê':
        return const LinearGradient(
          colors: [
            Color(0xFFB3E5FC),
            Color(0xFF4FC3F7),
            Color(0xFF0288D1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'aniversário':
        return const LinearGradient(
          colors: [
            Color(0xFFE1BEE7),
            Color(0xFFBA68C8),
            Color(0xFF8E24AA),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [
            Color(0xFFB2DFDB),
            Color(0xFF4DB6AC),
            Color(0xFF00796B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        gradient: _gradientePorTema,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _contador("dias", dias),
          _contador("horas", horas),
          _contador("min", minutos),
          _contador("s", segundos),
        ],
      ),
    );
  }

  Widget _contador(String label, int valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          Text(
            valor.toString().padLeft(2, '0'),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              shadows: [
                const Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black26),
              ],
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
