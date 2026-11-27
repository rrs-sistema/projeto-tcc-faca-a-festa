import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'conectividade_service.dart';
import 'estado_sincronizacao.dart';

/// Espera da confirmação do servidor antes de tratar a escrita como pendente.
const esperaConfirmacaoServidor = Duration(seconds: 6);

/// Escrita do Firestore que não trava a tela sem internet.
///
/// O SDK aplica a escrita no cache local na hora, mas o `Future` só termina
/// quando o servidor confirma. Offline isso nunca acontece. Online, a espera
/// continua para que recusas do servidor cheguem a quem chamou.
///
/// [chave] é o id do documento, usado pelo selo de pendência na lista.
Future<void> escritaLocalPrimeiro(
  Future<void> escrita, {
  String? descricao,
  String? chave,
  Duration espera = esperaConfirmacaoServidor,
}) async {
  unawaited(escrita.then((_) {}, onError: (Object _) {}));
  EstadoSincronizacao.instancia
      ?.registrar(escrita, descricao: descricao, chave: chave);

  if (ConectividadeService.offlineAgora) return;
  try {
    await escrita.timeout(espera);
  } on TimeoutException {
    ConectividadeService.instancia?.informarFalhaDeRede();
  } on FirebaseException catch (erro) {
    if (erro.code == 'unavailable') {
      ConectividadeService.instancia?.informarFalhaDeRede();
      return;
    }
    rethrow;
  }
}

/// Leituras que usam o cache do aparelho quando o servidor não responde.
abstract final class LeituraLocalPrimeiro {
  static const _espera = Duration(seconds: 8);

  static GetOptions get _opcoes => ConectividadeService.offlineAgora
      ? const GetOptions(source: Source.cache)
      : const GetOptions(source: Source.serverAndCache);

  /// Online lê do servidor; offline, ou se o servidor não responder, do cache.
  static Future<DocumentSnapshot<T>> documento<T>(
    DocumentReference<T> ref, {
    Duration espera = _espera,
  }) async {
    try {
      return await ref.get(_opcoes).timeout(espera);
    } on FirebaseException catch (erro) {
      if (erro.code == 'permission-denied') rethrow;
      return ref.get(const GetOptions(source: Source.cache));
    } on TimeoutException {
      ConectividadeService.instancia?.informarFalhaDeRede();
      return ref.get(const GetOptions(source: Source.cache));
    }
  }

  /// Mesmo critério de [documento], para consultas.
  static Future<QuerySnapshot<T>> consulta<T>(
    Query<T> query, {
    Duration espera = _espera,
  }) async {
    try {
      return await query.get(_opcoes).timeout(espera);
    } on FirebaseException catch (erro) {
      if (erro.code == 'permission-denied') rethrow;
      return query.get(const GetOptions(source: Source.cache));
    } on TimeoutException {
      ConectividadeService.instancia?.informarFalhaDeRede();
      return query.get(const GetOptions(source: Source.cache));
    }
  }

  /// Snapshot vindo só do cache é aceito quando não há como falar com o servidor.
  static bool aceitarSnapshot(SnapshotMetadata metadata) =>
      !metadata.isFromCache || ConectividadeService.offlineAgora;
}

extension DocumentoLocalPrimeiro<T> on DocumentReference<T> {
  Future<DocumentSnapshot<T>> lerLocalPrimeiro() =>
      LeituraLocalPrimeiro.documento(this);
}

extension ConsultaLocalPrimeiro<T> on Query<T> {
  Future<QuerySnapshot<T>> lerLocalPrimeiro() =>
      LeituraLocalPrimeiro.consulta(this);
}
