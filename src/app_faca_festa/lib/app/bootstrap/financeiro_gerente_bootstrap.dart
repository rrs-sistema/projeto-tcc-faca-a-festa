import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/data/datasources/remote/compromissos_evento_remote.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_controller.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/controllers/financeiro_gerente_controller.dart';

class FinanceiroGerenteBootstrap {
  FinanceiroGerenteBootstrap._();

  static void register() {
    if (!Get.isRegistered<CompromissosEventoRemote>()) {
      Get.lazyPut<CompromissosEventoRemote>(
        () => CompromissosEventoRemote(Get.find<FirebaseFirestore>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<FinanceiroGerenteController>()) {
      Get.put(
        FinanceiroGerenteController(
          eventoController: Get.find<EventoController>(),
          compromissosRemote: Get.find<CompromissosEventoRemote>(),
          usuarioAtual: () => Get.find<FirebaseAuth>().currentUser?.uid,
        ),
        permanent: true,
      );
    }
  }

  static FinanceiroGerenteController find() {
    register();
    return Get.find<FinanceiroGerenteController>();
  }
}
