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

    final usuario = Get.find<AppController>().usuarioLogado.value;
    if (usuario == null) {
      return const RouteSettings(name: '/splash');
    }

    if (usuario.ativo == false) {
      return const RouteSettings(name: '/role');
    }

    final tipo = (usuario.tipo ?? '').trim();
    if (!tiposPermitidos.contains(tipo)) {
      return const RouteSettings(name: '/splash');
    }

    return null;
  }
}
