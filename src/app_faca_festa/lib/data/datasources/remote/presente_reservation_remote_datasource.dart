import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:app_faca_festa/core/conectividade/escrita_local_primeiro.dart';

class PresenteReservationRemoteDatasource {
  PresenteReservationRemoteDatasource(this._firestore);

  final FirebaseFirestore _firestore;

  /// Sem internet a reserva fica no aparelho e vai ao reconectar. Se outra
  /// pessoa reservou antes, as regras recusam e o aviso de sincronização
  /// informa o convidado.
  Future<void> reservar({
    required String idEvento,
    required String idPresente,
    required String idConvidado,
    required String nomeConvidado,
    required DateTime dataReserva,
  }) async {
    final ref = _firestore
        .collection('evento')
        .doc(idEvento)
        .collection('presentes')
        .doc(idPresente);

    final atual = await LeituraLocalPrimeiro.documento(ref);
    final dados = atual.data();
    final reservadoPor = (dados?['reservado_por'] as String?)?.trim() ?? '';
    if (reservadoPor.isNotEmpty && dados?['id_convidado'] != idConvidado) {
      throw StateError('Este presente já foi reservado por outra pessoa.');
    }

    final nome = (dados?['nome'] as String?)?.trim();
    await escritaLocalPrimeiro(
      ref.update({
        'reservado_por': nomeConvidado,
        'id_convidado': idConvidado,
        'data_reserva': Timestamp.fromDate(dataReserva),
      }),
      descricao: 'reserva do presente${nome == null || nome.isEmpty ? '' : ' "$nome"'}'
          ' (outra pessoa pode ter reservado antes)',
      chave: idPresente,
    );
  }
}
