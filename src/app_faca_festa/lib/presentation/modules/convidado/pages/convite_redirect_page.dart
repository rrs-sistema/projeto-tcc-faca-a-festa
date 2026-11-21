import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/app/routes/app_route_args.dart';
import 'package:app_faca_festa/app/routes/area_convidado_tela.dart';
import 'package:app_faca_festa/core/utils/convite_link.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_convite_controller.dart';

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
  ConflitoPapelConvite? _conflito;
  AreaConvidadoArgs? _area;
  bool _trocandoConta = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_abrir());
    });
  }

  String? get _tokenAtual {
    final token = (Get.parameters['token'] ??
            ConviteLink.tokenDaUrl() ??
            widget.appController.tokenConviteAtual() ??
            '')
        .trim();
    return token.isEmpty ? null : token;
  }

  Future<void> _abrir() async {
    final jaAberto = AreaConvidadoArgs.atual();
    if (jaAberto != null) {
      if (!mounted) return;
      setState(() {
        _area = jaAberto;
        _erro = null;
        _conflito = null;
      });
      return;
    }

    final token = _tokenAtual;
    if (token == null) {
      Get.offAllNamed('/role');
      return;
    }
    try {
      final resultado = await widget.appController
          .abrirConvite(token)
          .timeout(const Duration(seconds: 25));
      if (!mounted) return;
      if (resultado.aberto && resultado.args != null) {
        setState(() {
          _area = resultado.args;
          _erro = null;
          _conflito = null;
        });
        return;
      }
      if (resultado.temConflitoPapel && resultado.conflito != null) {
        setState(() {
          _conflito = resultado.conflito;
          _erro = null;
        });
        return;
      }
      setState(() {
        _erro = 'Não foi possível abrir este convite.';
        _conflito = null;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _erro =
            'O convite demorou para abrir. Verifique a conexão e tente novamente.';
        _conflito = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erro = 'Não foi possível abrir este convite.';
        _conflito = null;
      });
    }
  }

  Future<void> _sairEAbrirComoConvidado(ConflitoPapelConvite conflito) async {
    if (_trocandoConta) return;
    setState(() {
      _trocandoConta = true;
      _conflito = null;
      _erro = null;
    });
    try {
      await widget.appController.sairParaAbrirConvite(conflito.token);
      if (!mounted) return;
      // Se GetX reutilizar a mesma rota, remonta o fluxo aqui.
      await _abrir();
    } finally {
      if (mounted) setState(() => _trocandoConta = false);
    }
  }

  Future<void> _manterContaAtual() async {
    if (_trocandoConta) return;
    setState(() => _trocandoConta = true);
    try {
      await widget.appController.permanecerNaContaAtualAposConvite();
    } finally {
      if (mounted) setState(() => _trocandoConta = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final area = _area;
    if (area != null) {
      return AreaConvidadoTela.de(area);
    }

    final conflito = _conflito;

    return Scaffold(
      backgroundColor: const Color(0xFFFFE4E1),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_erro == null && conflito == null) ...[
                const CircularProgressIndicator(color: Color(0xFFC2185B)),
                const SizedBox(height: 16),
                Text(
                  _trocandoConta
                      ? 'Trocando de conta para abrir o convite...'
                      : 'Abrindo seu convite...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF880E4F),
                  ),
                ),
              ] else if (conflito != null) ...[
                const Icon(Icons.swap_horiz_rounded,
                    size: 48, color: Color(0xFFC2185B)),
                const SizedBox(height: 16),
                const Text(
                  'Conta diferente detectada',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF880E4F),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Você está logado como ${conflito.nomePapel}'
                  '${conflito.email.trim().isEmpty ? '' : ' (${conflito.email.trim()})'}.\n'
                  'Este link é só para convidado e não mistura com essa conta.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: Color(0xFF880E4F),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _trocandoConta
                        ? null
                        : () => unawaited(_sairEAbrirComoConvidado(conflito)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFC2185B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _trocandoConta
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Sair e abrir como convidado'),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed:
                      _trocandoConta ? null : () => unawaited(_manterContaAtual()),
                  child: const Text('Manter minha conta atual'),
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
