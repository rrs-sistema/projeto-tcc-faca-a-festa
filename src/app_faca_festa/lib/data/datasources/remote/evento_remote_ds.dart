import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

import 'package:app_faca_festa/core/conectividade/conectividade_service.dart';
import 'package:app_faca_festa/core/conectividade/escrita_local_primeiro.dart';
import 'package:app_faca_festa/domain/services/evento_leitura_confirmada.dart';

import '../../models/evento/evento_model.dart';
import '../../models/evento/tipo_evento.dart';

/// Isolates the existing Firestore operations for Eventos.
class EventoRemoteDatasource {
  EventoRemoteDatasource(
    this.firestore, {
    required this.storage,
  });

  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  CollectionReference<Map<String, dynamic>> get _eventos =>
      firestore.collection('evento');

  Future<EventoModel?> buscarPorId(String idEvento) async {
    final snapshot = await LeituraLocalPrimeiro.consulta(_eventos
        .where('id_evento', isEqualTo: idEvento)
        .orderBy('data_cadastro', descending: true)
        .limit(1));

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return EventoModel.fromMap(snapshot.docs.first.data());
  }

  Future<EventoModel?> buscarUltimoPorUsuario(String idUsuario) async {
    final snapshot = await LeituraLocalPrimeiro.consulta(_eventos
        .where('id_usuario', isEqualTo: idUsuario)
        .orderBy('data_cadastro', descending: true)
        .limit(1));

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return EventoModel.fromMap(snapshot.docs.first.data());
  }

  Stream<EventoModel?> observarUltimoPorUsuario(String idUsuario) {
    return EventoLeituraConfirmada.ultimosConfirmados(
      _consultas(_eventos
          .where('id_usuario', isEqualTo: idUsuario)
          .orderBy('data_cadastro', descending: true)
          .limit(1)),
    );
  }

  Stream<EventoModel?> observarPorId(String idEvento) {
    return _eventos.doc(idEvento).snapshots().map(
          (document) =>
              document.exists ? EventoModel.fromMap(document.data()!) : null,
        );
  }

  Future<TipoEventoModel?> buscarTipoPorId(String idTipoEvento) async {
    DocumentSnapshot<Map<String, dynamic>>? document;
    try {
      document = await LeituraLocalPrimeiro.documento(
        firestore.collection('tipo_evento').doc(idTipoEvento),
      );
    } on FirebaseException catch (erro) {
      // Fora do cache e sem servidor: tenta a consulta abaixo.
      if (erro.code == 'permission-denied') rethrow;
    }

    if (document != null && document.exists && document.data() != null) {
      final data = document.data()!;
      return TipoEventoModel.fromMap({
        ...data,
        'id_tipo_evento': data['id_tipo_evento'] ?? document.id,
      });
    }

    final snapshot = await LeituraLocalPrimeiro.consulta(firestore
        .collection('tipo_evento')
        .where('id_tipo_evento', isEqualTo: idTipoEvento)
        .limit(1));

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return TipoEventoModel.fromMap(snapshot.docs.first.data());
  }

  Future<List<TipoEventoModel>> listarTiposAtivos() async {
    final snapshot = await LeituraLocalPrimeiro.consulta(
      firestore.collection('tipo_evento').where('ativo', isEqualTo: true),
    );

    return snapshot.docs
        .map((document) => TipoEventoModel.fromMap(document.data()))
        .toList();
  }

  Future<void> salvar(EventoModel evento) {
    final data = evento.toMap();
    // Merge preserva metadados fora do formulário; a remoção do término é explícita.
    if (evento.dataFim == null) data['data_fim'] = FieldValue.delete();
    return escritaLocalPrimeiro(
      _eventos.doc(evento.idEvento).set(data, SetOptions(merge: true)),
      descricao: 'dados do evento "${evento.nomeEvento}"',
      chave: evento.idEvento,
    );
  }

  Future<String> enviarCapa({
    required String idEvento,
    required List<int> bytes,
  }) async {
    final ref =
        storage.ref().child('eventos').child(idEvento).child('capa.jpg');
    final payload = Uint8List.fromList(bytes);
    await ref.putData(
      payload,
      SettableMetadata(contentType: _contentTypeCapa(payload)),
    );
    final url = await ref.getDownloadURL();
    return '$url${url.contains('?') ? '&' : '?'}v=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> removerArquivoCapa(String idEvento) {
    return storage
        .ref()
        .child('eventos')
        .child(idEvento)
        .child('capa.jpg')
        .delete();
  }

  Future<void> atualizarImagemCapa({
    required String idEvento,
    String? imagemCapaUrl,
  }) {
    final url = (imagemCapaUrl ?? '').trim();
    return escritaLocalPrimeiro(
      _eventos.doc(idEvento).update({
        'imagem_capa_url': url.isEmpty ? FieldValue.delete() : url,
      }),
      descricao: 'capa do evento',
      chave: idEvento,
    );
  }

  Future<void> atualizarRotuloBanner({
    required String idEvento,
    String? rotuloBanner,
  }) {
    final texto = (rotuloBanner ?? '').trim();
    return escritaLocalPrimeiro(
      _eventos.doc(idEvento).update({
        'rotulo_banner': texto.isEmpty ? FieldValue.delete() : texto,
      }),
      descricao: 'rótulo do banner',
      chave: idEvento,
    );
  }

  Future<void> excluir(String idEvento) {
    return escritaLocalPrimeiro(
      _eventos.doc(idEvento).delete(),
      descricao: 'exclusão do evento',
      chave: idEvento,
    );
  }

  Stream<List<EventoModel>> listarPorUsuario(String idUsuario) {
    final uid = idUsuario.trim();
    if (uid.isEmpty) {
      return Stream.value(const <EventoModel>[]);
    }

    // Une eventos próprios + eventos em que o usuário é co-organizador.
    // A 1ª emissão só sai quando os dois lados responderam — evita o boot
    // da sessão mandar co-organizador puro para /welcome com lista vazia.
    final controller = StreamController<List<EventoModel>>();
    var proprios = <EventoModel>[];
    var comoCo = <EventoModel>[];
    var propriosProntos = false;
    var coProntos = false;

    void emitir() {
      if (controller.isClosed) return;
      if (!propriosProntos || !coProntos) return;
      final mapa = <String, EventoModel>{};
      for (final evento in [...proprios, ...comoCo]) {
        final id = evento.idEvento.trim();
        if (id.isEmpty) continue;
        mapa[id] = evento;
      }
      controller.add(mapa.values.toList());
    }

    final subProprios = EventoLeituraConfirmada.listasConfirmadas(
      _consultas(_eventos.where('id_usuario', isEqualTo: uid)),
    ).listen(
      (lista) {
        proprios = lista;
        propriosProntos = true;
        emitir();
      },
      onError: (Object error, StackTrace stack) {
        // Não bloqueia a lista de co-organização se a query própria falhar.
        debugPrint('❌ [EventoRemote] listar próprios: $error');
        propriosProntos = true;
        emitir();
        if (!coProntos) controller.addError(error, stack);
      },
    );

    final subCo = EventoLeituraConfirmada.listasConfirmadas(
      _consultas(_eventos.where('co_organizadores', arrayContains: uid)),
    ).listen(
      (lista) {
        comoCo = lista;
        coProntos = true;
        emitir();
      },
      onError: (Object error, StackTrace stack) {
        debugPrint('❌ [EventoRemote] listar co-org: $error');
        coProntos = true;
        emitir();
      },
    );

    controller.onCancel = () async {
      await subProprios.cancel();
      await subCo.cancel();
    };

    return controller.stream;
  }

  /// Snapshots da consulta, reavaliados quando a conexão cai: o snapshot com
  /// escrita pendente omitido antes do corte passa a ser publicado.
  Stream<ConsultaEventos<EventoModel>> _consultas(
    Query<Map<String, dynamic>> query,
  ) {
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? snapshots;
    StreamSubscription<bool>? transicoes;
    QuerySnapshot<Map<String, dynamic>>? ultimo;
    late final StreamController<ConsultaEventos<EventoModel>> controller;
    controller = StreamController(
      onListen: () {
        snapshots = query.snapshots().listen(
          (snapshot) {
            ultimo = snapshot;
            controller.add(_consultaDeEventos(snapshot));
          },
          onError: controller.addError,
        );
        transicoes =
            ConectividadeService.instancia?.transicoes.listen((online) {
          final snapshot = ultimo;
          if (!online && snapshot != null && !controller.isClosed) {
            controller.add(_consultaDeEventos(snapshot));
          }
        });
      },
      onCancel: () async {
        await transicoes?.cancel();
        await snapshots?.cancel();
      },
    );
    return controller.stream;
  }

  ConsultaEventos<EventoModel> _consultaDeEventos(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return ConsultaEventos(
      semServidor: ConectividadeService.offlineAgora,
      escritaPendente: snapshot.metadata.hasPendingWrites,
      documentos: [
        for (final document in snapshot.docs)
          EventoEmTransito(
            valor: EventoModel.fromMap(document.data()),
            escritaPendente: document.metadata.hasPendingWrites,
          ),
      ],
    );
  }

  String _contentTypeCapa(Uint8List bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    return 'image/jpeg';
  }
}
