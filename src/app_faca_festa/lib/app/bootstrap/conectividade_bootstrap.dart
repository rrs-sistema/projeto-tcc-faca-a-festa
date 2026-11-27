import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/core/conectividade/conectividade_service.dart';
import 'package:app_faca_festa/core/conectividade/estado_sincronizacao.dart';
import 'package:app_faca_festa/core/conectividade/rede_firestore.dart';

/// Estado de conexão e fila de sincronização, permanentes desde o início do app.
abstract final class ConectividadeBootstrap {
  /// Registra os serviços antes do primeiro `await`; o `Future` termina com a
  /// primeira verificação de alcance.
  static Future<void> initialize({
    ConectividadeService? conectividade,
    FirebaseFirestore? firestore,
  }) async {
    final servico = Get.isRegistered<ConectividadeService>()
        ? Get.find<ConectividadeService>()
        : Get.put<ConectividadeService>(
            conectividade ?? ConectividadeService(),
            permanent: true,
          );

    final db = firestore ??
        (Get.isRegistered<FirebaseFirestore>()
            ? Get.find<FirebaseFirestore>()
            : null);
    EstadoSincronizacao? estado;
    if (db != null) {
      if (!Get.isRegistered<RedeFirestore>()) {
        Get.put<RedeFirestore>(RedeFirestore(db, servico), permanent: true);
      }
      if (!Get.isRegistered<EstadoSincronizacao>()) {
        estado = Get.put<EstadoSincronizacao>(
          EstadoSincronizacao(firestore: db),
          permanent: true,
        );
      }
    }

    await servico.iniciar();
    if (Get.isRegistered<RedeFirestore>()) Get.find<RedeFirestore>().iniciar();
    await estado?.iniciar();
  }
}
