import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/app/routes/app_route_args.dart';
import 'package:app_faca_festa/app/routes/area_convidado_tela.dart';
import 'package:app_faca_festa/core/utils/convite_link.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';

class ConviteRedirectPage extends StatefulWidget {
  const ConviteRedirectPage({
    super.key,
    required this.appController,
  });

  final AppController appController;

  @override
  State<ConviteRedirectPage> createState() => _ConviteRedirectPageState();
}

class _ConviteRedirectPageState extends State<ConviteRedirectPage> {
  String? _erro;
  AreaConvidadoArgs? _area;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_abrir());
    });
  }

  Future<void> _abrir() async {
    final jaAberto = AreaConvidadoArgs.atual();
    if (jaAberto != null) {
      if (!mounted) return;
      setState(() => _area = jaAberto);
      return;
    }

    final token = (Get.parameters['token'] ??
            ConviteLink.tokenDaUrl() ??
            widget.appController.tokenConviteAtual() ??
            '')
        .trim();
    if (token.isEmpty) {
      Get.offAllNamed('/role');
      return;
    }
    try {
      final args = await widget.appController.abrirConvite(token);
      if (!mounted) return;
      if (args == null) {
        setState(() {
          _erro = 'Não foi possível abrir este convite.';
        });
        return;
      }
      setState(() => _area = args);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erro = 'Não foi possível abrir este convite.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final area = _area;
    if (area != null) {
      return AreaConvidadoTela.de(area);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFE4E1),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_erro == null) ...[
                const CircularProgressIndicator(color: Color(0xFFC2185B)),
                const SizedBox(height: 16),
                const Text(
                  'Abrindo seu convite...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF880E4F),
                  ),
                ),
              ] else ...[
                const Icon(Icons.mail_outline,
                    size: 48, color: Color(0xFFC2185B)),
                const SizedBox(height: 16),
                Text(
                  _erro!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF880E4F),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Get.offAllNamed('/role'),
                  child: const Text('Voltar ao início'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
