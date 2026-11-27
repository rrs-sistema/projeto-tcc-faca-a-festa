import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'conectividade_service.dart';

/// Alterações salvas no aparelho que ainda não foram confirmadas pelo servidor.
class EstadoSincronizacao extends GetxService {
  EstadoSincronizacao({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  /// Escritas desta sessão ainda sem confirmação do servidor.
  final RxInt pendentes = 0.obs;

  /// Há escritas de sessões anteriores na fila persistida do Firestore.
  final RxBool pendenciasAnteriores = false.obs;

  /// Última recusa do servidor para uma escrita feita offline.
  final RxnString ultimaRecusa = RxnString();

  /// Ids de documentos com escrita desta sessão ainda sem confirmação.
  final RxSet<String> chavesPendentes = <String>{}.obs;
  final _escritasPorChave = <String, int>{};

  StreamSubscription<void>? _reconexaoSub;
  final _filaEnviada = StreamController<void>.broadcast();

  static EstadoSincronizacao? get instancia =>
      Get.isRegistered<EstadoSincronizacao>()
          ? Get.find<EstadoSincronizacao>()
          : null;

  bool get temPendencias => pendentes.value > 0 || pendenciasAnteriores.value;

  /// Emite quando, depois de reconectar, o servidor confirmou a fila local.
  ///
  /// Escutas abertas offline sobre documentos criados no aparelho podem ter
  /// sido recusadas pelas regras antes de a criação chegar ao servidor.
  Stream<void> get filaEnviada => _filaEnviada.stream;

  /// Acompanha a confirmação de [escrita] sem bloquear quem a disparou.
  void registrar(Future<void> escrita, {String? descricao, String? chave}) {
    pendentes.value++;
    final id = chave?.trim() ?? '';
    if (id.isNotEmpty) {
      _escritasPorChave[id] = (_escritasPorChave[id] ?? 0) + 1;
      chavesPendentes.add(id);
    }
    escrita.then(
      (_) {},
      onError: (Object erro) {
        final codigo = erro is FirebaseException ? erro.code : '';
        if (codigo == 'permission-denied' ||
            codigo == 'failed-precondition' ||
            codigo == 'invalid-argument' ||
            codigo == 'not-found') {
          ultimaRecusa.value = descricao == null
              ? 'Uma alteração feita sem internet foi recusada pelo servidor.'
              : 'O servidor recusou: $descricao.';
        }
        debugPrint('[Sincronizacao] Escrita recusada ($codigo): $erro');
      },
    ).whenComplete(() {
      if (pendentes.value > 0) pendentes.value--;
      if (id.isEmpty) return;
      final restantes = (_escritasPorChave[id] ?? 1) - 1;
      if (restantes > 0) {
        _escritasPorChave[id] = restantes;
      } else {
        _escritasPorChave.remove(id);
        chavesPendentes.remove(id);
      }
    });
  }

  /// Descobre se a fila persistida do Firestore ainda tem escritas de antes.
  Future<void> iniciar() async {
    final db = _firestore;
    if (db == null) return;
    final conectividade = ConectividadeService.instancia;
    _reconexaoSub = conectividade?.aoReconectar.listen((_) {
      unawaited(_acompanharFilaPersistida(db, aposReconectar: true));
    });
    unawaited(_acompanharFilaPersistida(db));
  }

  Future<void> _acompanharFilaPersistida(
    FirebaseFirestore db, {
    bool aposReconectar = false,
  }) async {
    final espera = db.waitForPendingWrites();
    final concluiuLogo = await espera
        .then((_) => true)
        .timeout(const Duration(milliseconds: 800), onTimeout: () => false)
        .catchError((Object _) => true);
    if (!concluiuLogo) {
      pendenciasAnteriores.value = true;
      try {
        await espera;
      } catch (_) {}
    }
    pendenciasAnteriores.value = false;
    if (aposReconectar && !_filaEnviada.isClosed) _filaEnviada.add(null);
  }

  void limparRecusa() => ultimaRecusa.value = null;

  @override
  void onClose() {
    unawaited(_reconexaoSub?.cancel());
    unawaited(_filaEnviada.close());
    super.onClose();
  }
}
