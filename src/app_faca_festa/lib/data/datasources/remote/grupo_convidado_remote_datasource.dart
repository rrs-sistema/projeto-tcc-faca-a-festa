import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/convidado/convidado_model.dart';
import '../../models/convidado/grupo_convidado_model.dart';
import '../../../domain/repositories/grupo_convidado_repository.dart';

class GrupoConvidadoRemoteDatasource {
  GrupoConvidadoRemoteDatasource(this.firestore);

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _grupos =>
      firestore.collection('grupos_convidado');

  CollectionReference<Map<String, dynamic>> get _convidados =>
      firestore.collection('convidado');

  Stream<List<GrupoConvidadoModel>> observarGrupos(String idEvento) {
    return _grupos
        .where('id_evento', isEqualTo: idEvento)
        .snapshots()
        .map((snapshot) {
      final grupos = snapshot.docs.map((document) {
        final data = Map<String, dynamic>.from(document.data());
        if ((data['id_grupo'] ?? '').toString().trim().isEmpty) {
          data['id_grupo'] = document.id;
        }
        if ((data['id_evento'] ?? '').toString().trim().isEmpty) {
          data['id_evento'] = idEvento;
        }
        return GrupoConvidadoModel.fromMap(data);
      }).toList();

      grupos.sort(
        (a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()),
      );
      return grupos;
    });
  }

  Stream<List<ConvidadoModel>> observarConvidados(String idEvento) {
    late StreamController<List<ConvidadoModel>> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? principalSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? legadoSub;
    final principal = <String, ConvidadoModel>{};
    final legado = <String, ConvidadoModel>{};

    void publicar() {
      final lista = <String, ConvidadoModel>{...legado, ...principal}
          .values
          .toList()
        ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
      controller.add(lista);
    }

    controller = StreamController<List<ConvidadoModel>>(
      onListen: () {
        principalSub = _convidados
            .where('id_evento', isEqualTo: idEvento)
            .snapshots()
            .listen(
          (snapshot) {
            principal
              ..clear()
              ..addAll(_normalizarConvidados(snapshot, idEvento));
            publicar();
          },
          onError: controller.addError,
        );
        legadoSub = _convidados
            .where('id_evento_evento', isEqualTo: idEvento)
            .snapshots()
            .listen(
          (snapshot) {
            legado
              ..clear()
              ..addAll(_normalizarConvidados(snapshot, idEvento));
            publicar();
          },
          onError: controller.addError,
        );
      },
      onCancel: () async {
        await principalSub?.cancel();
        await legadoSub?.cancel();
      },
    );

    return controller.stream;
  }

  Map<String, ConvidadoModel> _normalizarConvidados(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    String idEvento,
  ) {
    final convidados = <String, ConvidadoModel>{};
    for (final document in snapshot.docs) {
      final data = Map<String, dynamic>.from(document.data());
      if ((data['id_convidado'] ?? '').toString().trim().isEmpty) {
        data['id_convidado'] = document.id;
      }
      if ((data['id_evento'] ?? '').toString().trim().isEmpty) {
        data['id_evento'] =
            (data['id_evento_evento'] ?? data['evento_id'] ?? idEvento)
                .toString();
      }

      final nomeGrupo =
          (data['nome_grupo'] ?? data['grupo_mesa'] ?? '').toString().trim();
      if (nomeGrupo.isNotEmpty) data['nome_grupo'] = nomeGrupo;

      if ((data['tipo_convidado'] ?? '').toString().trim().isEmpty) {
        data['tipo_convidado'] = data['adulto'] == false ? 'crianca' : 'adulto';
      }

      final convidado = ConvidadoModel.fromMap(data);
      final id = convidado.idConvidado.trim().isNotEmpty
          ? convidado.idConvidado
          : document.id;
      convidados[id] = convidado;
    }
    return convidados;
  }

  Future<void> salvarGrupo(GrupoConvidadoModel grupo) async {
    final data = Map<String, dynamic>.from(grupo.toMap())
      ..['id_grupo'] = grupo.idGrupo
      ..['id_evento'] = grupo.idEvento
      ..['data_atualizacao'] = FieldValue.serverTimestamp()
      ..removeWhere((key, value) => value == null);
    await _grupos.doc(grupo.idGrupo).set(data, SetOptions(merge: true));
  }

  Future<void> excluirGrupo(
    String idGrupo, {
    required bool desvincularConvidados,
  }) async {
    final batch = firestore.batch();
    if (desvincularConvidados) {
      final snapshot =
          await _convidados.where('id_grupo', isEqualTo: idGrupo).get();
      for (final document in snapshot.docs) {
        batch.update(document.reference, {
          'id_grupo': null,
          'nome_grupo': null,
          'grupo_mesa': null,
          'data_atualizacao': FieldValue.serverTimestamp(),
        });
      }
    }
    batch.delete(_grupos.doc(idGrupo));
    await batch.commit();
  }

  Future<void> vincularConvidadoAoGrupo(
    ConvidadoModel convidado,
    GrupoConvidadoModel grupo,
  ) {
    return _convidados.doc(convidado.idConvidado).set({
      'id_convidado': convidado.idConvidado,
      'id_evento': convidado.idEvento,
      'id_grupo': grupo.idGrupo,
      'nome_grupo': grupo.nome,
      'grupo_mesa': grupo.nome,
      'data_atualizacao': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> removerConvidadoDoGrupo(ConvidadoModel convidado) {
    return _convidados.doc(convidado.idConvidado).set({
      'id_grupo': null,
      'nome_grupo': null,
      'grupo_mesa': null,
      'data_atualizacao': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> vincularConvidadoNaMesa(
    ConvidadoModel convidado,
    String idMesa,
    int numeroMesa,
  ) {
    return _convidados.doc(convidado.idConvidado).set({
      'id_mesa': idMesa,
      'numero_mesa': numeroMesa,
      'data_atualizacao': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> removerConvidadoDaMesa(ConvidadoModel convidado) {
    return _convidados.doc(convidado.idConvidado).set({
      'id_mesa': null,
      'numero_mesa': null,
      'data_atualizacao': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> atualizarResumos(List<ResumoGrupoConvidado> resumos) async {
    if (resumos.isEmpty) return;
    final batch = firestore.batch();
    for (final resumo in resumos) {
      batch.set(
        _grupos.doc(resumo.idGrupo),
        {
          'total_convidados': resumo.total,
          'total_adultos': resumo.adultos,
          'total_criancas': resumo.criancas,
          'total_bebes': resumo.bebes,
          'total_confirmados': resumo.confirmados,
          'data_atualizacao': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }
}
