import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/app/bootstrap/gift_bootstrap.dart';
import 'package:app_faca_festa/app/routes/app_route_args.dart';
import 'package:app_faca_festa/domain/usecases/get_gifts/gift_usecases.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/checklist/controllers/tarefa_controller.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/convidado_controller.dart';
import 'package:app_faca_festa/presentation/modules/convidado/pages/area/area_convidado_home_screen.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';

abstract final class AreaConvidadoTela {
  static Widget de(AreaConvidadoArgs args) {
    try {
      GiftBootstrap.ensureUseCases();
      return AreaConvidadoHomeScreen(
        convidado: args.convidado,
        evento: args.evento,
        convidadoController: Get.find<ConvidadoController>(),
        eventoController: Get.find<EventoController>(),
        tarefaController: Get.find<TarefaController>(),
        theme: Get.find<EventThemeController>(),
        appController: Get.find<AppController>(),
        giftUseCases:
            Get.isRegistered<GiftUseCases>() ? Get.find<GiftUseCases>() : null,
      );
    } catch (e, s) {
      debugPrint('[AreaConvidado] Falha ao montar a tela: $e\n$s');
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
}
