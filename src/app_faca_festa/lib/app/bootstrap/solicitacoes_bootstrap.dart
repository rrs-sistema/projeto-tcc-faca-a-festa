import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/data/datasources/remote/solicitacoes_remote_datasource.dart';
import 'package:app_faca_festa/data/repositories_impl/solicitacoes_repository_impl.dart';
import 'package:app_faca_festa/domain/repositories/solicitacoes_repository.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_solicitacoes.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/cotacao/controllers/solicitacoes_controller.dart';

class SolicitacoesBootstrap {
  SolicitacoesBootstrap._();

  static void register() {
    if (!Get.isRegistered<SolicitacoesRemoteDatasource>()) {
      Get.lazyPut<SolicitacoesRemoteDatasource>(
        () => SolicitacoesRemoteDatasource(
          firestore: Get.find<FirebaseFirestore>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<SolicitacoesRepository>()) {
      Get.lazyPut<SolicitacoesRepository>(
        () => SolicitacoesRepositoryImpl(
          Get.find<SolicitacoesRemoteDatasource>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<GerenciarSolicitacoes>()) {
      Get.lazyPut<GerenciarSolicitacoes>(
        () => GerenciarSolicitacoes(Get.find<SolicitacoesRepository>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<SolicitacoesController>()) {
      Get.put(
        SolicitacoesController(
          solicitacoesFornecedor: Get.find<GerenciarSolicitacoes>(),
          nomeUsuarioAtual: () => Get.isRegistered<AppController>()
              ? Get.find<AppController>().usuarioLogado.value?.nome ??
                  'Desconhecido'
              : 'Desconhecido',
        ),
        permanent: true,
      );
    }
  }

  static SolicitacoesController findController() {
    register();
    return Get.find<SolicitacoesController>();
  }
}
