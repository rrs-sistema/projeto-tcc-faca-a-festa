import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../models/servico_produto/servico_foto_model.dart';

class ServicoFotoRemoteDatasource {
  ServicoFotoRemoteDatasource({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
    DateTime Function()? now,
  })  : _db = firestore,
        _storage = storage,
        _now = now ?? DateTime.now;

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final DateTime Function() _now;

  Future<List<ServicoFotoModel>> carregarFotos({
    required String idFornecedor,
    required String idProdutoServico,
  }) async {
    final snapshot = await _colecao
        .where('id_fornecedor', isEqualTo: idFornecedor)
        .where('id_produto_servico', isEqualTo: idProdutoServico)
        .get();

    return snapshot.docs
        .map((doc) => ServicoFotoModel.fromMap(doc.data()))
        .toList();
  }

  Future<ServicoFotoModel> adicionarFotoArquivo({
    required String idFornecedor,
    required String idProdutoServico,
    required File arquivo,
    required String nomeArquivo,
  }) async {
    final ref = _storage
        .ref()
        .child('servicos')
        .child(idFornecedor)
        .child(idProdutoServico)
        .child(nomeArquivo);

    final uploadTask = await ref.putFile(arquivo);
    final downloadUrl = await uploadTask.ref.getDownloadURL();

    final foto = ServicoFotoModel(
      id: _now().millisecondsSinceEpoch.toString(),
      idFornecedor: idFornecedor,
      idProdutoServico: idProdutoServico,
      url: downloadUrl,
    );

    await adicionarFotoDireto(foto);

    return foto;
  }

  Future<void> adicionarFotoDireto(ServicoFotoModel foto) {
    return _colecao.doc(foto.id).set(foto.toMap());
  }

  Future<void> removerFoto(ServicoFotoModel foto) async {
    await _colecao.doc(foto.id).delete();

    final ref = _storage.refFromURL(foto.url);
    await ref.delete();
  }

  CollectionReference<Map<String, dynamic>> get _colecao {
    return _db.collection('servico_foto');
  }
}
