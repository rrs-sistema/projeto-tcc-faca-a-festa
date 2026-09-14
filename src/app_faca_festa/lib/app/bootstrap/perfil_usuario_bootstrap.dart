import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/data/datasources/remote/foto_perfil_remote_datasource.dart';
import 'package:app_faca_festa/data/datasources/remote/perfil_usuario_remote_datasource.dart';
import 'package:app_faca_festa/data/repositories_impl/foto_perfil_repository_impl.dart';
import 'package:app_faca_festa/data/repositories_impl/perfil_usuario_repository_impl.dart';
import 'package:app_faca_festa/domain/repositories/autenticacao_repository.dart';
import 'package:app_faca_festa/domain/repositories/foto_perfil_repository.dart';
import 'package:app_faca_festa/domain/repositories/perfil_usuario_repository.dart';
import 'package:app_faca_festa/domain/services/auditoria_registrar.dart';
import 'package:app_faca_festa/domain/services/buscar_cep_service.dart';
import 'package:app_faca_festa/presentation/modules/usuario/controllers/endereco_usuario_controller.dart';
import 'package:app_faca_festa/presentation/modules/usuario/controllers/uf_cidade_controller.dart';
import 'package:app_faca_festa/presentation/modules/usuario/controllers/usuario_controller.dart';

abstract final class PerfilUsuarioBootstrap {
  static void register() {
    if (!Get.isRegistered<PerfilUsuarioRemoteDatasource>()) {
      Get.put<PerfilUsuarioRemoteDatasource>(
        FirebasePerfilUsuarioRemoteDatasource(Get.find<FirebaseFirestore>()),
        permanent: true,
      );
    }
    if (!Get.isRegistered<PerfilUsuarioRepository>()) {
      Get.put<PerfilUsuarioRepository>(
        PerfilUsuarioRepositoryImpl(
          Get.find<PerfilUsuarioRemoteDatasource>(),
        ),
        permanent: true,
      );
    }
    if (!Get.isRegistered<FotoPerfilRemoteDatasource>()) {
      Get.put<FotoPerfilRemoteDatasource>(
        FirebaseFotoPerfilRemoteDatasource(Get.find<FirebaseStorage>()),
        permanent: true,
      );
    }
    if (!Get.isRegistered<FotoPerfilRepository>()) {
      Get.put<FotoPerfilRepository>(
        FotoPerfilRepositoryImpl(Get.find<FotoPerfilRemoteDatasource>()),
        permanent: true,
      );
    }
    if (!Get.isRegistered<EnderecoUsuarioController>()) {
      Get.put(
        EnderecoUsuarioController(
          perfilRepository: Get.find<PerfilUsuarioRepository>(),
          buscarCepService: Get.find<BuscarCepService>(),
        ),
        permanent: true,
      );
    }
    if (!Get.isRegistered<UsuarioController>()) {
      Get.put(
        UsuarioController(
          autenticacaoRepository: Get.find<AutenticacaoRepository>(),
          perfilRepository: Get.find<PerfilUsuarioRepository>(),
          fotoPerfilRepository: Get.find<FotoPerfilRepository>(),
          auditoria: Get.isRegistered<AuditoriaRegistrar>()
              ? Get.find<AuditoriaRegistrar>()
              : const AuditoriaRegistrarVazio(),
          auditoriaResolver: () => Get.isRegistered<AuditoriaRegistrar>()
              ? Get.find<AuditoriaRegistrar>()
              : null,
          enderecoUsuarioController: Get.find<EnderecoUsuarioController>(),
          buscarCepService: Get.find<BuscarCepService>(),
          ufCidadeController: Get.find<UFCidadeController>(),
        ),
        permanent: true,
      );
    }
  }
}
