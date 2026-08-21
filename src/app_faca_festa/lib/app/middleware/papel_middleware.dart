import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../controllers/app_controller.dart';

class PapelMiddleware extends GetMiddleware {
  PapelMiddleware({required this.tiposPermitidos}) : super(priority: 1);

  final List<String> tiposPermitidos;

  @override
  RouteSettings? redirect(String? route) {
    if (!Get.isRegistered<AppController>()) {
      return const RouteSettings(name: '/splash');
    }

    final app = Get.find<AppController>();
    final usuario = app.usuarioLogado.value;
    if (usuario == null) {
      final conviteVisitante = tiposPermitidos.contains('C') &&
          (app.acessoPorLink.value || app.fluxoConviteAtivo);
      if (conviteVisitante) return null;
      return const RouteSettings(name: '/splash');
    }

    if (usuario.ativo == false) {
      return const RouteSettings(name: '/role');
    }

    final tipo = (usuario.tipo ?? '').trim();
    if (!tiposPermitidos.contains(tipo)) {
      final conviteVisitante = tiposPermitidos.contains('C') &&
          (app.acessoPorLink.value || app.fluxoConviteAtivo);
      if (!conviteVisitante) {
        return const RouteSettings(name: '/splash');
      }
    }

    return null;
  }
}
