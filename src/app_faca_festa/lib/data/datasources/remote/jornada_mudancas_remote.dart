import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

/// Avisa quando algo do atendimento muda no servidor (proposta, contrato,
/// execução). O aviso só pede uma nova consulta; não carrega dados.
typedef MudancasJornada = Stream<void> Function(
    String idCotacao, String idFornecedor, String? idOrcamento);

/// Observador padrão, ou null quando o Firestore não está registrado (testes).
MudancasJornada? mudancasJornadaPadrao() {
  if (!Get.isRegistered<FirebaseFirestore>()) return null;
  final db = Get.find<FirebaseFirestore>();
  return (idCotacao, idFornecedor, idOrcamento) =>
      observarMudancasJornada(db, idCotacao, idFornecedor, idOrcamento);
}

/// Escuta o pedido do fornecedor, o pedido em si e, quando existe, o contrato.
/// A primeira emissão de cada documento é ignorada: ela só repete a consulta
/// que a tela acabou de fazer.
Stream<void> observarMudancasJornada(
  FirebaseFirestore db,
  String idCotacao,
  String idFornecedor,
  String? idOrcamento,
) {
  final cotacao = db.collection('cotacao').doc(idCotacao);
  final fontes = <Stream<void>>[
    cotacao
        .collection('fornecedores')
        .doc(idFornecedor)
        .snapshots()
        .skip(1)
        .map((_) {}),
    cotacao.snapshots().skip(1).map((_) {}),
    if (idOrcamento != null && idOrcamento.isNotEmpty)
      db
          .collection('orcamento')
          .doc(idOrcamento)
          .snapshots()
          .skip(1)
          .map((_) {}),
  ];

  final controle = StreamController<void>();
  final assinaturas = <StreamSubscription<void>>[];
  controle.onListen = () {
    for (final fonte in fontes) {
      assinaturas.add(fonte.listen((_) => controle.add(null),
          onError: (Object _) {}));
    }
  };
  controle.onCancel = () async {
    for (final assinatura in assinaturas) {
      await assinatura.cancel();
    }
    assinaturas.clear();
  };
  return controle.stream;
}
