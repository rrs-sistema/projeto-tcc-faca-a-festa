import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

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

  // 🔹 Controle da cor e posição
  bool _estaNoTopo = false;
  Color _corTexto = Colors.white;

  @override
  void initState() {
    super.initState();
    _atualizarTempo();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _atualizarTempo());
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
      setState(() {
        _estaNoTopo = noTopo;
        _corTexto = noTopo ? Colors.red.shade700 : Colors.white;
      });
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

// 🔹 Gradiente dinâmico com transição suave
  LinearGradient get _gradientePorTema {
    final tipo = widget.tipoEvento.toLowerCase();

    // Gradiente padrão (quando ainda não chegou no topo)
    LinearGradient gradienteNormal;
    // Gradiente alternativo (quando o contador está fixo no topo)
    LinearGradient gradienteTopo;

    switch (tipo) {
      case 'casamento':
        gradienteNormal = const LinearGradient(
          colors: [Color(0xFFB71C1C), Color(0xFFD81B60), Color(0xFFF06292)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        gradienteTopo = const LinearGradient(
          colors: [Color(0xFFFFEBEE), Color(0xFFFFCDD2), Color(0xFFE53935)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        break;

      case 'festa infantil':
        gradienteNormal = const LinearGradient(
          colors: [Color(0xFFFFB300), Color(0xFFF57C00), Color(0xFFE65100)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        gradienteTopo = const LinearGradient(
          colors: [Color(0xFFFFF8E1), Color(0xFFFFCC80), Color(0xFFFFA000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        break;

      case 'chá de bebê':
        gradienteNormal = const LinearGradient(
          colors: [Color(0xFF0277BD), Color(0xFF039BE5), Color(0xFF4FC3F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        gradienteTopo = const LinearGradient(
          colors: [Color(0xFFE1F5FE), Color(0xFF81D4FA), Color(0xFF0288D1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        break;

      case 'aniversário':
        gradienteNormal = const LinearGradient(
          colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA), Color(0xFFBA68C8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        gradienteTopo = const LinearGradient(
          colors: [Color(0xFFF3E5F5), Color(0xFFCE93D8), Color(0xFF7B1FA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        break;

      default:
        gradienteNormal = const LinearGradient(
          colors: [Color(0xFF004D40), Color(0xFF00796B), Color(0xFF26A69A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        gradienteTopo = const LinearGradient(
          colors: [Color(0xFFE0F2F1), Color(0xFF80CBC4), Color(0xFF004D40)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }

    // 🔹 Transição animada entre os gradientes
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: List.generate(3, (i) {
        return Color.lerp(
          gradienteNormal.colors[i],
          gradienteTopo.colors[i],
          _estaNoTopo ? 1.0 : 0.0, // muda gradualmente quando chega no topo
        )!;
      }),
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
    final pulsar = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    final bool glowAtivo = _duracaoRestante.inSeconds <= 10 && _duracaoRestante.inSeconds > 0;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Fundo
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            gradient: _gradientePorTema,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),

        // Partículas coloridas + brilho pulsante
        if (_ativarParticulas)
          IgnorePointer(
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
                  size: const Size(double.infinity, 120),
                );
              },
            ),
          ),

        // 🎉 Confete e texto quando o evento chega
        if (_mostrarConfete)
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, _) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      painter: _ConfetePainter(
                        progress: _animController.value,
                        random: _random,
                      ),
                      size: const Size(double.infinity, 150),
                    ),
                    AnimatedOpacity(
                      opacity: _mostrarConfete ? 1 : 0,
                      duration: const Duration(milliseconds: 400),
                      child: Transform.scale(
                        scale: 1.1 + sin(_animController.value * pi) * 0.05,
                        child: Text(
                          '🎉 O grande dia chegou! 🎉',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: const [
                              Shadow(
                                offset: Offset(0, 2),
                                blurRadius: 6,
                                color: Colors.black45,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

        // Conteúdo normal do contador
        if (!_mostrarConfete)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 350),
                    style: GoogleFonts.poppins(
                      color: _corTexto,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          color: _estaNoTopo ? Colors.black54 : Colors.black26,
                          offset: const Offset(0, 1),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    child: SizedBox.shrink(),
                    /*Text(
                      _mensagemContagemRegressiva(dias, widget.tipoEvento),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),*/
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedBuilder(
                  animation: pulsar,
                  builder: (context, _) {
                    return Transform.scale(
                      scale: pulsar.value,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _contador("dias", dias, _corTexto),
                          _separador(_corTexto),
                          _contador("h", horas, _corTexto),
                          _separador(_corTexto),
                          _contador("min", minutos, _corTexto),
                          _separador(_corTexto),
                          _contador("s", segundos, _corTexto),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
      ],
    );
  }

  Widget _contador(String label, int valor, Color cor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 350),
            style: GoogleFonts.poppins(
              color: cor,
              fontSize: _estaNoTopo ? 28 : 26,
              fontWeight: FontWeight.w800,
              shadows: [
                Shadow(
                  color: _estaNoTopo ? Colors.black54 : Colors.black26,
                  offset: const Offset(0, 1),
                  blurRadius: 3,
                ),
              ],
            ),
            child: Text(valor.toString().padLeft(2, '0')),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: cor.withValues(alpha: 0.9),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _separador(Color cor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Text(
        '·',
        style: GoogleFonts.poppins(
          color: cor.withValues(alpha: 0.9),
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ignore: unused_element
String _mensagemContagemRegressiva(int dias, String tipoEvento) {
  final tipo = tipoEvento.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();

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

// 🎉 Confete animado
class _ConfetePainter extends CustomPainter {
  final double progress;
  final Random random;

  _ConfetePainter({required this.progress, required this.random});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < 120; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = size.height * progress + (random.nextDouble() * size.height * 0.5);
      final paint = Paint()
        ..color = _colorful[random.nextInt(_colorful.length)].withValues(alpha: 0.85)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      if (i.isEven) {
        canvas.drawCircle(Offset(dx, dy), 2 + random.nextDouble() * 2, paint);
      } else {
        canvas.drawLine(
          Offset(dx, dy),
          Offset(dx + random.nextDouble() * 4, dy + random.nextDouble() * 4),
          paint,
        );
      }
    }
  }

  List<Color> get _colorful => const [
        Color(0xFFFF5252),
        Color(0xFFFFC107),
        Color(0xFF4CAF50),
        Color(0xFF2196F3),
        Color(0xFFE040FB),
        Color(0xFFFF9800),
        Color(0xFF009688),
      ];

  @override
  bool shouldRepaint(covariant _ConfetePainter oldDelegate) => oldDelegate.progress != progress;
}
