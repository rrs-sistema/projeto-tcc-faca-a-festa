import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'dart:math';

import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';

class ContadorEventoScreen extends StatefulWidget {
  final DateTime dataEvento;
  final String tipoEvento;
  final ScrollController? scrollController;

  const ContadorEventoScreen({
    super.key,
    required this.dataEvento,
    required this.tipoEvento,
    this.scrollController,
  });

  @override
  State<ContadorEventoScreen> createState() => _ContadorEventoScreenState();
}

class _ContadorEventoScreenState extends State<ContadorEventoScreen>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  Duration _duracaoRestante = Duration.zero;
  late AnimationController _animController;
  final Random _random = Random();
  bool _mostrarConfete = false;
  bool _eventoEncerradoProcessado = false;
  Timer? _confeteTimer;
  bool _estaNoTopo = false;

  @override
  void initState() {
    super.initState();
    _atualizarTempo();
    _timer =
        Timer.periodic(const Duration(seconds: 1), (_) => _atualizarTempo());
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: false);

    // 🔹 Escuta o scroll externo (caso passado)
    widget.scrollController?.addListener(_detectarTopo);
  }

  void _detectarTopo() {
    final controller = widget.scrollController;
    if (controller == null || !mounted) return;

    final posicao = controller.offset;
    final bool noTopo = posicao > 60; // Quando sobe mais que 60px

    if (noTopo != _estaNoTopo) {
      setState(() => _estaNoTopo = noTopo);
    }
  }

  void _atualizarTempo() {
    final agora = DateTime.now();
    final diferenca = widget.dataEvento.difference(agora);

    if (!mounted) return;

    if (diferenca.isNegative) {
      setState(() {
        _duracaoRestante = Duration.zero;
      });

      if (!_eventoEncerradoProcessado) {
        _eventoEncerradoProcessado = true;

        setState(() {
          _mostrarConfete = true;
        });

        _confeteTimer?.cancel();
        _confeteTimer = Timer(const Duration(seconds: 3), () {
          if (!mounted) return;
          setState(() => _mostrarConfete = false);
        });
      }

      return;
    }

    setState(() => _duracaoRestante = diferenca);
  }

  @override
  void dispose() {
    _timer.cancel();
    _animController.dispose();
    _confeteTimer?.cancel();
    widget.scrollController?.removeListener(_detectarTopo);
    super.dispose();
  }

  int get dias => _duracaoRestante.inDays;
  int get horas => _duracaoRestante.inHours.remainder(24);
  int get minutos => _duracaoRestante.inMinutes.remainder(60);
  int get segundos => _duracaoRestante.inSeconds.remainder(60);

  LinearGradient _gradienteDoTema(Color primary) {
    final escuro = Color.lerp(primary, const Color(0xFF111827), 0.42)!;
    final medio = Color.lerp(primary, const Color(0xFF111827), 0.12)!;
    return LinearGradient(
      colors: [escuro, medio, primary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  List<Color> get _coresParticulas {
    switch (widget.tipoEvento.toLowerCase()) {
      case 'casamento':
        // 💍 Tons dourados e vermelhos suaves (luxo e romance)
        return const [
          Color(0xFFFFD54F),
          Color(0xFFFFB300),
          Color(0xFFD32F2F),
        ];

      case 'festa infantil':
        // 🎈 Tons alegres e vibrantes (diversão e energia)
        return const [
          Color(0xFFFF7043),
          Color(0xFF29B6F6),
          Color(0xFFEC407A),
          Color(0xFFFFEE58),
        ];

      case 'chá de bebê':
        // 🍼 Tons suaves de azul e branco (ternura e leveza)
        return const [
          Color(0xFF0288D1),
          Color(0xFF4FC3F7),
          Color(0xFFE1F5FE),
        ];

      case 'aniversário':
        // 🎂 Paleta festiva e contrastante (alegria e celebração)
        return const [
          Color(0xFF8E24AA),
          Color(0xFFD81B60),
          Color(0xFFFFA726),
          Color(0xFFFFEE58),
        ];

      case 'evento corporativo':
        // 💼 Azul petróleo e cinzas sofisticados (profissional e moderno)
        return const [
          Color(0xFF00796B),
          Color(0xFF004D40),
          Color(0xFF26A69A),
          Color(0xFF80CBC4),
        ];

      case 'formatura':
        // 🎓 Roxos e dourados (elegância e conquista)
        return const [
          Color(0xFF7E57C2),
          Color(0xFFB39DDB),
          Color(0xFFFFD54F),
          Color(0xFF9575CD),
        ];

      default:
        // 🌈 Tema padrão — verde água suave
        return const [
          Color(0xFF26A69A),
          Color(0xFF004D40),
          Color(0xFF80CBC4),
        ];
    }
  }

  bool get _ativarParticulas => dias <= 5 && _duracaoRestante > Duration.zero;

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<EventThemeController>();
    final compacto = _estaNoTopo;
    final glowAtivo =
        _duracaoRestante.inSeconds <= 10 && _duracaoRestante.inSeconds > 0;

    return Obx(() {
      final primary = theme.primaryColor.value;

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: _gradienteDoTema(primary),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.10),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                if (_ativarParticulas)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _animController,
                        builder: (context, _) {
                          return CustomPaint(
                            painter: _ParticlePainter(
                              progress: _animController.value,
                              random: _random,
                              cores: _coresParticulas,
                              glow: glowAtivo,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                if (_mostrarConfete)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'O grande dia chegou',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: compacto ? 6 : 8,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _unidade('dias', dias, compacto),
                          _divisor(),
                          _unidade('horas', horas, compacto),
                          _divisor(),
                          _unidade('min', minutos, compacto),
                          _divisor(),
                          _unidade('seg', segundos, compacto),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _unidade(String rotulo, int valor, bool compacto) {
    return Container(
      constraints: const BoxConstraints(minWidth: 56),
      padding: EdgeInsets.symmetric(
        horizontal: compacto ? 10 : 12,
        vertical: compacto ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            valor.toString().padLeft(2, '0'),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: compacto ? 20 : 22,
              fontWeight: FontWeight.w800,
              height: 1.05,
              letterSpacing: 0.6,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            rotulo.toUpperCase(),
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divisor() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        ':',
        style: GoogleFonts.poppins(
          color: Colors.white.withValues(alpha: 0.55),
          fontSize: 18,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

// ignore: unused_element
String _mensagemContagemRegressiva(int dias, String tipoEvento) {
  final tipo =
      tipoEvento.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();

  String tempo;
  if (dias > 1) {
    tempo = "$dias dias";
  } else if (dias == 1) {
    tempo = "1 dia";
  } else {
    tempo = "poucas horas";
  }

  switch (tipo) {
    case 'casamento':
      return "💍 Contagem regressiva: $tempo até o grande dia do seu casamento!";
    case 'festa infantil':
      return "🎈 Faltam $tempo para a diversão começar na sua festa!";
    case 'chá de bebê':
      return "🍼 Faltam $tempo para celebrar a chegada do bebê!";
    case 'aniversário':
      return "🎂 $tempo até o seu aniversário especial!";
    case 'evento corporativo':
      return "💼 $tempo até o início do seu evento corporativo!";
    case 'formatura':
      return "🎓 $tempo para a sua formatura inesquecível!";
    default:
      return "⏳ Faltam $tempo para o seu evento!";
  }
}

// 🎇 Partículas temáticas
class _ParticlePainter extends CustomPainter {
  final double progress;
  final Random random;
  final List<Color> cores;
  final bool glow;

  _ParticlePainter({
    required this.progress,
    required this.random,
    required this.cores,
    this.glow = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < 25; i++) {
      final corBase = cores[random.nextInt(cores.length)];
      final paint = Paint()
        ..color = corBase.withValues(alpha: 0.4 + random.nextDouble() * 0.4)
        ..maskFilter = glow ? const MaskFilter.blur(BlurStyle.outer, 6) : null;

      final dx = random.nextDouble() * size.width;
      final dy = size.height - (random.nextDouble() * size.height * progress);
      final radius = 1.8 + random.nextDouble() * 2.8;
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.glow != glow;
}
