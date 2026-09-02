import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../data/datasources/remote/fornecedor_migracao_remote_datasource.dart';
import '../../data/repositories_impl/calculadora/calculadora_itens_base_repository_impl.dart';
import '../../data/repositories_impl/calculadora_festa_repository_impl.dart';
import '../../data/repositories_impl/fornecedor_migracao_repository_impl.dart';
import '../../data/repositories_impl/sugestao_base_festa_repository_impl.dart';
import '../../data/services/calculadora/calculadora_festa_remote_ai_service.dart';
import '../../domain/repositories/calculadora_festa_repository.dart';
import '../../domain/repositories/calculadora_itens_base_repository_contract.dart';
import '../../domain/repositories/fornecedor_migracao_repository.dart';
import '../../domain/repositories/sugestao_base_festa_repository_contract.dart';
import '../../domain/services/calculadora_festa_ai_service.dart';
import '../../domain/usecases/executar_migracao_fornecedores.dart';
import '../../presentation/modules/calculadora/controllers/calculadora_itens_admin_controller.dart';
import '../../presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import '../../presentation/modules/calculadora/controllers/fornecedor_migracao_admin_controller.dart';
import '../../presentation/modules/calculadora/controllers/sugestao_base_festa_controller.dart';

abstract final class CalculadoraBootstrap {
  static void register() {
    if (!Get.isRegistered<ICalculadoraFestaAIService>()) {
      Get.lazyPut<ICalculadoraFestaAIService>(
        () => CalculadoraFestaRemoteAIService(
          executor: (payload) async {
            final callable = Get.find<FirebaseFunctions>().httpsCallable(
              'analisarCalculadoraFestaIA',
              options: HttpsCallableOptions(
                timeout: const Duration(seconds: 60),
              ),
            );
            final result = await callable.call(payload);
            final data = result.data;
            if (data is Map) {
              return Map<String, dynamic>.from(data);
            }
            throw Exception(
              'Resposta inválida da Cloud Function analisarCalculadoraFestaIA.',
            );
          },
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<CalculadoraFestaRepository>()) {
      Get.lazyPut<CalculadoraFestaRepository>(
        () => CalculadoraFestaRepositoryImpl(
          firestore: Get.find<FirebaseFirestore>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<CalculadoraFestaController>()) {
      Get.lazyPut<CalculadoraFestaController>(
        () => CalculadoraFestaController(
          aiService: Get.find<ICalculadoraFestaAIService>(),
          repository: Get.find<CalculadoraFestaRepository>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<SugestaoBaseFestaRepositoryContract>()) {
      Get.lazyPut<SugestaoBaseFestaRepositoryContract>(
        () => SugestaoBaseFestaRepositoryImpl(
          firestore: Get.find<FirebaseFirestore>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<SugestaoBaseFestaController>()) {
      Get.lazyPut<SugestaoBaseFestaController>(
        () => SugestaoBaseFestaController(
          repository: Get.find<SugestaoBaseFestaRepositoryContract>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<CalculadoraItensBaseRepositoryContract>()) {
      Get.lazyPut<CalculadoraItensBaseRepositoryContract>(
        () => CalculadoraItensBaseRepositoryImpl(
          firestore: Get.find<FirebaseFirestore>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<CalculadoraItensAdminController>()) {
      Get.lazyPut<CalculadoraItensAdminController>(
        () => CalculadoraItensAdminController(
          repository: Get.find<CalculadoraItensBaseRepositoryContract>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<FornecedorMigracaoRemoteDatasource>()) {
      Get.lazyPut<FornecedorMigracaoRemoteDatasource>(
        () => FornecedorMigracaoRemoteDatasource(
          functions: Get.find<FirebaseFunctions>(),
        ),
        fenix: true,
      );
    }
    if (!Get.isRegistered<FornecedorMigracaoRepository>()) {
      Get.lazyPut<FornecedorMigracaoRepository>(
        () => FornecedorMigracaoRepositoryImpl(
          Get.find<FornecedorMigracaoRemoteDatasource>(),
        ),
        fenix: true,
      );
    }
    if (!Get.isRegistered<ExecutarMigracaoFornecedores>()) {
      Get.lazyPut<ExecutarMigracaoFornecedores>(
        () => ExecutarMigracaoFornecedores(
          Get.find<FornecedorMigracaoRepository>(),
        ),
        fenix: true,
      );
    }
    if (!Get.isRegistered<FornecedorMigracaoAdminController>()) {
      Get.lazyPut<FornecedorMigracaoAdminController>(
        () => FornecedorMigracaoAdminController(
          migracaoFornecedores: Get.find<ExecutarMigracaoFornecedores>(),
        ),
        fenix: true,
      );
    }
  }
}
