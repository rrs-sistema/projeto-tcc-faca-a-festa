import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/data/datasources/remote/fornecedor_localizacao_remote_datasource.dart';
import 'package:app_faca_festa/data/datasources/remote/fornecedor_remote_datasource.dart';
import 'package:app_faca_festa/data/repositories_impl/fornecedor_localizacao_repository_impl.dart';
import 'package:app_faca_festa/data/repositories_impl/fornecedor_repository_impl.dart';
import 'package:app_faca_festa/data/services/fornecedor_ai_service.dart';
import 'package:app_faca_festa/data/services/fornecedor_ai_generativa_service.dart';
import 'package:app_faca_festa/domain/repositories/autenticacao_repository.dart';
import 'package:app_faca_festa/domain/repositories/fornecedor_localizacao_repository.dart';
import 'package:app_faca_festa/domain/repositories/fornecedor_repository.dart';
import 'package:app_faca_festa/domain/services/auditoria_registrar.dart';
import 'package:app_faca_festa/domain/services/fornecedor_ai.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_servico_fotos.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_fornecedor_localizacao.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_fornecedores.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_servicos_produto.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_localizacao_controller.dart';

abstract final class FornecedorBootstrap {
  static void register() {
    if (!Get.isRegistered<FornecedorRemoteDatasource>()) {
      Get.put<FornecedorRemoteDatasource>(
        FirebaseFornecedorRemoteDatasource(
          Get.find<FirebaseFirestore>(),
          storage: Get.find<FirebaseStorage>(),
        ),
        permanent: true,
      );
    }
    if (!Get.isRegistered<FornecedorRepository>()) {
      Get.put<FornecedorRepository>(
        FornecedorRepositoryImpl(Get.find<FornecedorRemoteDatasource>()),
        permanent: true,
      );
    }
    if (!Get.isRegistered<GerenciarFornecedores>()) {
      Get.put<GerenciarFornecedores>(
        GerenciarFornecedores(Get.find<FornecedorRepository>()),
        permanent: true,
      );
    }
    if (!Get.isRegistered<FornecedorAiGenerativoService>()) {
      Get.lazyPut<FornecedorAiGenerativoService>(
        () => FornecedorAiGenerativaService(
          functions: Get.find<FirebaseFunctions>(),
        ),
        fenix: true,
      );
    }
    if (!Get.isRegistered<FornecedorAiRegrasService>()) {
      Get.lazyPut<FornecedorAiRegrasService>(
        () => FornecedorAiService(),
        fenix: true,
      );
    }
    if (!Get.isRegistered<FornecedorController>()) {
      Get.put(
        FornecedorController(
          autenticacaoRepository: Get.isRegistered<AutenticacaoRepository>()
              ? Get.find<AutenticacaoRepository>()
              : null,
          gerenciarFornecedores: Get.find<GerenciarFornecedores>(),
          gerenciarServicosProduto: Get.isRegistered<GerenciarServicosProduto>()
              ? Get.find<GerenciarServicosProduto>()
              : null,
          gerenciarServicosProdutoResolver: () =>
              Get.isRegistered<GerenciarServicosProduto>()
                  ? Get.find<GerenciarServicosProduto>()
                  : null,
          gerenciarServicoFotos: Get.isRegistered<GerenciarServicoFotos>()
              ? Get.find<GerenciarServicoFotos>()
              : null,
          gerenciarServicoFotosResolver: () =>
              Get.isRegistered<GerenciarServicoFotos>()
                  ? Get.find<GerenciarServicoFotos>()
                  : null,
          fornecedorAiService: Get.find<FornecedorAiRegrasService>(),
          fornecedorAiGenerativaService:
              Get.find<FornecedorAiGenerativoService>(),
          auditoria: Get.isRegistered<AuditoriaRegistrar>()
              ? Get.find<AuditoriaRegistrar>()
              : const AuditoriaRegistrarVazio(),
          auditoriaResolver: () => Get.isRegistered<AuditoriaRegistrar>()
              ? Get.find<AuditoriaRegistrar>()
              : null,
          appControllerResolver: () => Get.isRegistered<AppController>()
              ? Get.find<AppController>()
              : null,
        ),
        permanent: true,
      );
    }
    if (!Get.isRegistered<FornecedorLocalizacaoRemoteDatasource>()) {
      Get.lazyPut<FornecedorLocalizacaoRemoteDatasource>(
        () => FornecedorLocalizacaoRemoteDatasource(
          firestore: Get.find<FirebaseFirestore>(),
        ),
        fenix: true,
      );
    }
    if (!Get.isRegistered<FornecedorLocalizacaoRepository>()) {
      Get.lazyPut<FornecedorLocalizacaoRepository>(
        () => FornecedorLocalizacaoRepositoryImpl(
          Get.find<FornecedorLocalizacaoRemoteDatasource>(),
        ),
        fenix: true,
      );
    }
    if (!Get.isRegistered<GerenciarFornecedorLocalizacao>()) {
      Get.lazyPut<GerenciarFornecedorLocalizacao>(
        () => GerenciarFornecedorLocalizacao(
          Get.find<FornecedorLocalizacaoRepository>(),
        ),
        fenix: true,
      );
    }
    if (!Get.isRegistered<FornecedorLocalizacaoController>()) {
      Get.lazyPut<FornecedorLocalizacaoController>(
        () => FornecedorLocalizacaoController(
          localizacao: Get.find<GerenciarFornecedorLocalizacao>(),
        ),
        fenix: true,
      );
    }
  }
}
