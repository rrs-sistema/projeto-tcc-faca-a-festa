import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';

import '../../data/datasources/remote/foto_perfil_remote_datasource.dart';
import '../../data/datasources/remote/perfil_usuario_remote_datasource.dart';
import '../../data/repositories_impl/foto_perfil_repository_impl.dart';
import '../../data/repositories_impl/perfil_usuario_repository_impl.dart';
import '../../domain/repositories/foto_perfil_repository.dart';
import '../../domain/repositories/perfil_usuario_repository.dart';

abstract final class PerfilUsuarioBootstrap {
  static void register() {
    if (!Get.isRegistered<PerfilUsuarioRemoteDatasource>()) {
      Get.put<PerfilUsuarioRemoteDatasource>(
        FirebasePerfilUsuarioRemoteDatasource(FirebaseFirestore.instance),
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
        FirebaseFotoPerfilRemoteDatasource(FirebaseStorage.instance),
        permanent: true,
      );
    }
    if (!Get.isRegistered<FotoPerfilRepository>()) {
      Get.put<FotoPerfilRepository>(
        FotoPerfilRepositoryImpl(Get.find<FotoPerfilRemoteDatasource>()),
        permanent: true,
      );
    }
  }
}
