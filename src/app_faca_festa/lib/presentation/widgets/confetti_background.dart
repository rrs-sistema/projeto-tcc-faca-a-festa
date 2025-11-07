import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';

class ConfettiBackground extends StatefulWidget {
  final int? seconds;
  const ConfettiBackground({super.key, this.seconds});

  @override
  State<ConfettiBackground> createState() => _ConfettiBackgroundState();
}

class _ConfettiBackgroundState extends State<ConfettiBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _timer;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Lottie.asset(
          'assets/animations/confetti_background.json',
          fit: BoxFit.cover,
          controller: _controller,
          onLoaded: (composition) {
            // Define a duração do controller
            _controller.duration = composition.duration;

            // Só executa a primeira vez após carregado
            if (!_isLoaded) {
              _isLoaded = true;
              _controller.forward();

              // Repetição periódica
              _timer = Timer.periodic(
                Duration(seconds: widget.seconds ?? 5),
                (_) {
                  _controller.reset();
                  _controller.forward();
                },
              );
            }
          },
        ),
      ),
    );
  }
}
