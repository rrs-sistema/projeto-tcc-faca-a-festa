import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/app/routes/app_route_args.dart';
import 'package:app_faca_festa/core/database/app_database.dart';
import 'package:app_faca_festa/data/datasources/local/gift_local_datasource.dart';
import 'package:app_faca_festa/data/datasources/remote/gift_remote_datasource.dart';
import 'package:app_faca_festa/data/repositories_impl/gift_remote_only_repository.dart';
import 'package:app_faca_festa/data/repositories_impl/gift_repository_impl.dart';
import 'package:app_faca_festa/domain/repositories/gift_repository.dart';
import 'package:app_faca_festa/domain/usecases/get_gifts/gift_usecases.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_controller.dart';
import 'package:app_faca_festa/presentation/modules/gifts/controllers/gift_controller.dart';

/// Route-scoped composition for Gifts.
///
/// Offline-first infrastructure is registered by [GiftOfflineBootstrap].
/// This bootstrap only fills gaps (web / tests) and creates [GiftController]
/// with the `eventoId` of the current route.
abstract final class GiftBootstrap {
  /// Garante [GiftUseCases] mesmo quando o Drift/Wasm da web não inicializa.
  static void ensureUseCases() {
    if (Get.isRegistered<GiftUseCases>()) return;

    if (Get.isRegistered<AppDatabase>()) {
      try {
        registerRoute();
        if (Get.isRegistered<GiftUseCases>()) return;
      } catch (e, s) {
        debugPrint('[Gift] Falha ao registrar rota de presentes: $e\n$s');
      }
    }

    _registerRemoteOnly();
  }

  static void _registerRemoteOnly() {
    if (!Get.isRegistered<FirebaseFirestore>()) return;

    if (!Get.isRegistered<GiftRemoteDatasource>()) {
      Get.put<GiftRemoteDatasource>(
        GiftRemoteDatasource(Get.find<FirebaseFirestore>()),
        permanent: true,
      );
    }
    if (!Get.isRegistered<GiftRepository>()) {
      Get.put<GiftRepository>(
        GiftRemoteOnlyRepository(Get.find<GiftRemoteDatasource>()),
        permanent: true,
      );
    }
    Get.put<GiftUseCases>(
      GiftUseCases(Get.find<GiftRepository>()),
      permanent: true,
    );
    debugPrint('[Gift] Presentes em modo só remoto (sem banco local).');
  }

  static void registerRoute() {
    if (!Get.isRegistered<GiftLocalDatasource>()) {
      Get.lazyPut<GiftLocalDatasource>(
        () => GiftLocalDatasource(Get.find<AppDatabase>()),
      );
    }
    if (!Get.isRegistered<GiftRemoteDatasource>()) {
      Get.lazyPut<GiftRemoteDatasource>(
        () => GiftRemoteDatasource(Get.find<FirebaseFirestore>()),
      );
    }
    if (!Get.isRegistered<GiftRepository>()) {
      Get.lazyPut<GiftRepository>(
        () => GiftRepositoryImpl(
          local: Get.find<GiftLocalDatasource>(),
          remote: Get.find<GiftRemoteDatasource>(),
        ),
      );
    }
    if (!Get.isRegistered<GiftUseCases>()) {
      Get.lazyPut<GiftUseCases>(
        () => GiftUseCases(Get.find<GiftRepository>()),
      );
    }

    Get.lazyPut<GiftController>(() {
      final routeEventoId =
          GerenciarPresentesArgs.maybeOf(Get.arguments)?.eventoId;
      final eventoId = routeEventoId ??
          Get.find<EventoController>().eventoAtualEntidade?.idEvento ??
          '';
      return GiftController(
        eventoId: eventoId,
        usecases: Get.find<GiftUseCases>(),
      );
    });
  }
}
