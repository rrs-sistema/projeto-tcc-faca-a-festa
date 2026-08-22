import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../data/datasources/remote/documento_remote_datasource.dart';
import '../../data/repositories_impl/documento_repository_impl.dart';
import '../../domain/repositories/documento_repository.dart';
import '../../domain/usecases/gerenciar_documentos.dart';

abstract final class DocumentoBootstrap {
  static void register() {
    if (!Get.isRegistered<DocumentoRemoteDatasource>()) {
      Get.put<DocumentoRemoteDatasource>(
        FirebaseDocumentoRemoteDatasource(FirebaseFirestore.instance),
        permanent: true,
      );
    }
    if (!Get.isRegistered<DocumentoRepository>()) {
      Get.put<DocumentoRepository>(
        DocumentoRepositoryImpl(Get.find<DocumentoRemoteDatasource>()),
        permanent: true,
      );
    }
    if (!Get.isRegistered<GerenciarDocumentos>()) {
      Get.put<GerenciarDocumentos>(
        GerenciarDocumentos(Get.find<DocumentoRepository>()),
        permanent: true,
      );
    }
  }
}
