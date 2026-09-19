import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/app/bootstrap/gift_bootstrap.dart';
import 'package:app_faca_festa/app/routes/app_route_args.dart';
import 'package:app_faca_festa/app/routes/area_convidado_tela.dart';
import 'package:app_faca_festa/core/utils/convite_link.dart';
import 'package:app_faca_festa/domain/entities/convidado.dart';
import 'package:app_faca_festa/domain/entities/evento.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/convidado_controller.dart';
import 'package:app_faca_festa/presentation/modules/convidado/pages/convite_nao_encontrado_screen.dart';
import 'package:app_faca_festa/presentation/modules/convidado/pages/convite_redirect_page.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_controller.dart';

enum AreaConvidadoDestino { area, reabrirConvite, naoEncontrado }

/// Monta `/areaconvidado` sem depender só de [Get.arguments].
///
/// No web o GetX reparseia o hash e perde os argumentos; em release isso
/// vira a tela cinza. O Drift/Wasm também pode falhar e o `Get.find` de
/// presentes derruba a rota inteira.
abstract final class AreaConvidadoRota {
  static AreaConvidadoDestino resolver({
    Object? arguments,
    Convidado? convidadoAtual,
    Evento? eventoAtual,
    String? token,
  }) {
    final args = AreaConvidadoArgs.maybeOf(arguments);
    final convidado = args?.convidado ?? convidadoAtual;
    final evento = args?.evento ?? eventoAtual;
    if (convidado != null && evento != null) {
      return AreaConvidadoDestino.area;
    }
    if ((token ?? '').trim().isNotEmpty) {
      return AreaConvidadoDestino.reabrirConvite;
    }
    return AreaConvidadoDestino.naoEncontrado;
  }

  static Widget page() {
    try {
      return _montar();
    } catch (e, s) {
      debugPrint('[AreaConvidado] Falha ao montar a tela: $e\n$s');
      if (Get.isRegistered<AppController>()) {
        return ConviteNaoEncontradoScreen(
          appController: Get.find<AppController>(),
        );
      }
      return const ConviteFalhaTela();
    }
  }

  static Widget _montar() {
    GiftBootstrap.ensureUseCases();

    final app = Get.find<AppController>();
    final args = AreaConvidadoArgs.maybeOf(Get.arguments);
    final convidado = args?.convidado ??
        Get.find<ConvidadoController>().convidadoAtual.value;
    final evento =
        args?.evento ?? Get.find<EventoController>().eventoAtual.value;
    final token = (Get.parameters['token'] ??
            ConviteLink.tokenDaUrl() ??
            app.tokenConviteAtual() ??
            '')
        .trim();

    final destino = resolver(
      arguments: args,
      convidadoAtual: convidado,
      eventoAtual: evento,
      token: token,
    );

    if (destino == AreaConvidadoDestino.area &&
        convidado != null &&
        evento != null) {
      return AreaConvidadoTela.de(
        AreaConvidadoArgs(convidado: convidado, evento: evento),
      );
    }

    if (destino == AreaConvidadoDestino.reabrirConvite) {
      return ConviteRedirectPage(appController: app);
    }

    return ConviteNaoEncontradoScreen(appController: app);
  }
}

class ConviteFalhaTela extends StatelessWidget {
  const ConviteFalhaTela({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFFFE4E1),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Não foi possível abrir o convite.\nTente novamente pelo link recebido.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF880E4F),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
