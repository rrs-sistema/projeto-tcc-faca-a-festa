import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/convidado/convidado_model.dart';
import '../../../domain/repositories/convite_convidado_repository.dart';

abstract interface class ConviteConvidadoRemoteDatasource {
  Future<ConvidadoModel?> vincularPorToken({
    required String token,
    required String uid,
    required String email,
  });

  Future<ConvidadoModel?> buscarOuVincularPorUsuario({
    required String uid,
    required String email,
  });
}

class FirebaseConviteConvidadoRemoteDatasource
    implements ConviteConvidadoRemoteDatasource {
  FirebaseConviteConvidadoRemoteDatasource(this.firestore);

  final FirebaseFirestore firestore;

  static const _colecoes = ['convidado', 'convidados'];

  @override
  Future<ConvidadoModel?> vincularPorToken({
    required String token,
    required String uid,
    required String email,
  }) async {
    final documento = await _buscarPorToken(token);
    if (documento == null) return null;
    return _vincular(documento, uid: uid, email: email);
  }

  @override
  Future<ConvidadoModel?> buscarOuVincularPorUsuario({
    required String uid,
    required String email,
  }) async {
    final documentos = await _buscarPorUsuario(uid: uid, email: email);
    if (documentos.isEmpty) return null;

    QueryDocumentSnapshot<Map<String, dynamic>>? escolhido;
    for (final documento in documentos) {
      if (_campoTexto(
            documento.data(),
            const ['id_usuario', 'idUsuario'],
          ) ==
          uid) {
        escolhido = documento;
        break;
      }
    }
    escolhido ??= documentos.first;
    return _vincular(escolhido, uid: uid, email: email);
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _buscarPorToken(
    String token,
  ) async {
    final tokenLimpo = token.trim();
    if (tokenLimpo.isEmpty) return null;

    for (final colecao in _colecoes) {
      for (final campo in const ['convite_token', 'token_convite', 'token']) {
        final snapshot = await firestore
            .collection(colecao)
            .where(campo, isEqualTo: tokenLimpo)
            .limit(1)
            .get();
        if (snapshot.docs.isNotEmpty) return snapshot.docs.first;
      }
    }
    return null;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _buscarPorUsuario({
    required String uid,
    required String email,
  }) async {
    final emailNormalizado = _normalizarEmail(email);
    final encontrados = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};

    Future<void> buscar(String colecao, String campo, String valor) async {
      if (valor.trim().isEmpty) return;
      final snapshot = await firestore
          .collection(colecao)
          .where(campo, isEqualTo: valor)
          .limit(20)
          .get();
      for (final documento in snapshot.docs) {
        encontrados[documento.reference.path] = documento;
      }
    }

    for (final colecao in _colecoes) {
      await buscar(colecao, 'id_usuario', uid);
      await buscar(colecao, 'idUsuario', uid);
      if (emailNormalizado.isNotEmpty) {
        await buscar(colecao, 'email_normalizado', emailNormalizado);
        await buscar(colecao, 'email', email.trim());
        await buscar(colecao, 'email', emailNormalizado);
      }
    }

    return encontrados.values.where((documento) {
      final data = documento.data();
      final idUsuario = _campoTexto(data, const ['id_usuario', 'idUsuario']);
      final emailDocumento = _normalizarEmail(
        _campoTexto(data, const ['email_normalizado', 'email']),
      );
      return idUsuario == uid ||
          (idUsuario.isEmpty &&
              emailNormalizado.isNotEmpty &&
              emailDocumento == emailNormalizado);
    }).toList(growable: false);
  }

  Future<ConvidadoModel?> _vincular(
    QueryDocumentSnapshot<Map<String, dynamic>> documento, {
    required String uid,
    required String email,
  }) async {
    final data = documento.data();
    final idUsuarioAtual = _campoTexto(data, const ['id_usuario', 'idUsuario']);
    if (idUsuarioAtual.isNotEmpty && idUsuarioAtual != uid) {
      throw const ConviteJaVinculadoException();
    }

    await documento.reference.set({
      'id_usuario': uid,
      'email_usuario': email.trim(),
      'email_normalizado': _normalizarEmail(email),
      'convite_status': 'vinculado',
      'data_vinculo_usuario': FieldValue.serverTimestamp(),
      'data_ultimo_acesso': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final atualizado = await documento.reference.get();
    if (!atualizado.exists || atualizado.data() == null) return null;
    final dados = atualizado.data()!;
    return ConvidadoModel.fromMap({
      ...dados,
      'id_convidado':
          dados['id_convidado'] ?? dados['idConvidado'] ?? atualizado.id,
    });
  }

  String _campoTexto(Map<String, dynamic> data, List<String> campos) {
    for (final campo in campos) {
      final valor = data[campo];
      if (valor != null && valor.toString().trim().isNotEmpty) {
        return valor.toString().trim();
      }
    }
    return '';
  }

  String _normalizarEmail(String email) => email.trim().toLowerCase();
}
