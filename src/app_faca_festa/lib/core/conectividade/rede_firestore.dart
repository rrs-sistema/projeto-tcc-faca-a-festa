import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'conectividade_service.dart';

/// Leva o estado de conexão do app ao Firestore.
///
/// Com a rede do SDK desligada, leituras respondem do cache na hora e
/// escritas entram na fila local, em vez de esperarem o timeout do servidor.
class RedeFirestore {
  RedeFirestore(this._firestore, this._conectividade);

  final FirebaseFirestore _firestore;
  final ConectividadeService _conectividade;
  StreamSubscription<bool>? _sub;
  Future<void> _fila = Future<void>.value();

  void iniciar() {
    _sub ??= _conectividade.transicoes.listen(_aplicar);
    if (_conectividade.offline) _aplicar(false);
  }

  void _aplicar(bool online) {
    _fila = _fila.then((_) async {
      try {
        if (online) {
          await _firestore.enableNetwork();
        } else {
          await _firestore.disableNetwork();
        }
      } catch (erro) {
        debugPrint('[RedeFirestore] Falha ao alternar rede: $erro');
      }
    });
  }

  Future<void> parar() async {
    await _sub?.cancel();
    _sub = null;
    await _fila;
  }
}
