import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:get/get.dart';

import '../../data/datasources/remote/convidado_remote_datasource.dart';
import '../../data/datasources/remote/convite_convidado_remote_datasource.dart';
import '../../data/datasources/remote/cardapio_remote_datasource.dart';
import '../../data/datasources/remote/grupo_convidado_remote_datasource.dart';
import '../../data/datasources/remote/tarefa_remote_datasource.dart';
import '../../data/repositories_impl/convidado_repository_impl.dart';
import '../../data/repositories_impl/convite_convidado_repository_impl.dart';
import '../../data/repositories_impl/cardapio_repository_impl.dart';
import '../../data/repositories_impl/grupo_convidado_repository_impl.dart';
import '../../data/repositories_impl/tarefa_repository_impl.dart';
import '../../data/repositories_impl/presente_reservation_repository_impl.dart';
import '../../data/services/convite/enviar_convites_por_email_service.dart';
import '../../domain/repositories/convidado_repository.dart';
import '../../domain/repositories/convite_convidado_repository.dart';
import '../../domain/repositories/cardapio_repository.dart';
import '../../domain/repositories/grupo_convidado_repository.dart';
import '../../domain/repositories/tarefa_repository.dart';
import '../../domain/repositories/presente_reservation_repository.dart';
import '../../presentation/modules/convidado/controllers/cardapio_controller.dart';
import '../../presentation/modules/convidado/controllers/convidado_controller.dart';
import '../../presentation/modules/convidado/controllers/grupo_convidado_controller.dart';
import '../../presentation/modules/convidado/controllers/tarefa_controller.dart';

abstract final class ConvidadoBootstrap {
  static void register() {
    if (!Get.isRegistered<CardapioRemoteDatasource>()) {
      Get.put<CardapioRemoteDatasource>(
        CardapioRemoteDatasource(Get.find<FirebaseFirestore>()),
        permanent: true,
      );
    }

    if (!Get.isRegistered<CardapioRepository>()) {
      Get.put<CardapioRepository>(
        CardapioRepositoryImpl(Get.find<CardapioRemoteDatasource>()),
        permanent: true,
      );
    }

    if (!Get.isRegistered<CardapioController>()) {
      Get.put<CardapioController>(
        CardapioController(repository: Get.find<CardapioRepository>()),
        permanent: true,
      );
    }

    if (!Get.isRegistered<ConvidadoRemoteDatasource>()) {
      Get.put<ConvidadoRemoteDatasource>(
        ConvidadoRemoteDatasource(Get.find<FirebaseFirestore>()),
        permanent: true,
      );
    }

    if (!Get.isRegistered<ConvidadoRepository>()) {
      Get.put<ConvidadoRepository>(
        ConvidadoRepositoryImpl(Get.find<ConvidadoRemoteDatasource>()),
        permanent: true,
      );
    }

    if (!Get.isRegistered<ConviteConvidadoRemoteDatasource>()) {
      Get.put<ConviteConvidadoRemoteDatasource>(
        FirebaseConviteConvidadoRemoteDatasource(Get.find<FirebaseFirestore>()),
        permanent: true,
      );
    }

    if (!Get.isRegistered<ConviteConvidadoRepository>()) {
      Get.put<ConviteConvidadoRepository>(
        ConviteConvidadoRepositoryImpl(
          Get.find<ConviteConvidadoRemoteDatasource>(),
        ),
        permanent: true,
      );
    }

    if (!Get.isRegistered<TarefaRemoteDatasource>()) {
      Get.put<TarefaRemoteDatasource>(
        TarefaRemoteDatasource(Get.find<FirebaseFirestore>()),
        permanent: true,
      );
    }

    if (!Get.isRegistered<TarefaRepository>()) {
      Get.put<TarefaRepository>(
        TarefaRepositoryImpl(Get.find<TarefaRemoteDatasource>()),
        permanent: true,
      );
    }

    if (!Get.isRegistered<TarefaController>()) {
      Get.put<TarefaController>(
        TarefaController(
          repository: Get.find<TarefaRepository>(),
          convidadoRepository: Get.find<ConvidadoRepository>(),
        ),
        permanent: true,
      );
    }

    if (!Get.isRegistered<GrupoConvidadoRemoteDatasource>()) {
      Get.put<GrupoConvidadoRemoteDatasource>(
        GrupoConvidadoRemoteDatasource(Get.find<FirebaseFirestore>()),
        permanent: true,
      );
    }

    if (!Get.isRegistered<GrupoConvidadoRepository>()) {
      Get.put<GrupoConvidadoRepository>(
        GrupoConvidadoRepositoryImpl(
          Get.find<GrupoConvidadoRemoteDatasource>(),
        ),
        permanent: true,
      );
    }

    if (!Get.isRegistered<GrupoConvidadoController>()) {
      Get.put<GrupoConvidadoController>(
        GrupoConvidadoController(
          repository: Get.find<GrupoConvidadoRepository>(),
        ),
        permanent: true,
      );
    }

    if (!Get.isRegistered<PresenteReservationRepository>()) {
      Get.put<PresenteReservationRepository>(
        PresenteReservationRepositoryImpl(Get.find<FirebaseFirestore>()),
        permanent: true,
      );
    }

    if (!Get.isRegistered<EnviarConvitesPorEmailService>()) {
      Get.put<EnviarConvitesPorEmailService>(
        EnviarConvitesPorEmailService(
          functions: Get.find<FirebaseFunctions>(),
        ),
        permanent: true,
      );
    }

    if (!Get.isRegistered<ConvidadoController>()) {
      Get.put<ConvidadoController>(
        ConvidadoController(
          repository: Get.find<ConvidadoRepository>(),
          presenteReservationRepository:
              Get.find<PresenteReservationRepository>(),
          conviteEmailService: Get.find<EnviarConvitesPorEmailService>(),
        ),
        permanent: true,
      );
    }
  }
}
