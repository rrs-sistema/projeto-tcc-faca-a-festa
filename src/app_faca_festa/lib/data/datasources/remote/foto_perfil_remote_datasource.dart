import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

abstract interface class FotoPerfilRemoteDatasource {
  Future<String> enviar({
    required String idUsuario,
    required String caminhoArquivo,
    required String nomeArquivo,
  });
}

class FirebaseFotoPerfilRemoteDatasource implements FotoPerfilRemoteDatasource {
  FirebaseFotoPerfilRemoteDatasource(this.storage);

  final FirebaseStorage storage;

  @override
  Future<String> enviar({
    required String idUsuario,
    required String caminhoArquivo,
    required String nomeArquivo,
  }) async {
    final extensao = nomeArquivo.split('.').last;
    final referencia = storage
        .ref()
        .child('usuarios')
        .child(idUsuario)
        .child('perfil.$extensao');
    await referencia.putFile(File(caminhoArquivo));
    return referencia.getDownloadURL();
  }
}
