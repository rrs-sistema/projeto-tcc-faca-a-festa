import 'package:app_faca_festa/data/datasources/remote/evento_remote_ds.dart';
import 'package:app_faca_festa/data/models/evento/evento_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class EstadoDocumento {
  Map<String, dynamic>? dados;
  SetOptions? opcoes;
}

// Substituto de fronteira apenas no teste, sem implementar cliente na aplicação.
// ignore: subtype_of_sealed_class
class Documento extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  final estado = EstadoDocumento();
  Map<String, dynamic>? get dados => estado.dados;
  SetOptions? get opcoes => estado.opcoes;
  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    estado.dados = data;
    estado.opcoes = options;
  }
}

// ignore: subtype_of_sealed_class
class Colecao extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  final Documento documento;
  Colecao(this.documento);
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) => documento;
}

class Banco extends Fake implements FirebaseFirestore {
  final Documento documento;
  Banco(this.documento);
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      Colecao(documento);
}

class Storage extends Fake implements FirebaseStorage {}

void main() {
  test(
      'editar preserva metadados por merge e remover período envia exclusão explícita do término',
      () async {
    final doc = Documento();
    final ds = EventoRemoteDatasource(Banco(doc), storage: Storage());
    final evento = EventoModel(
        idEvento: 'festa',
        idTipoEvento: 'retiro',
        idUsuario: 'owner',
        nomeEvento: 'Retiro',
        localEvento: 'Salão',
        data: DateTime(2026, 10, 23),
        dataFim: DateTime(2026, 10, 25));
    await ds.salvar(evento);
    expect(doc.opcoes!.merge, true);
    expect(
        (doc.dados!['data_fim'] as Timestamp).toDate(), DateTime(2026, 10, 25));
    await ds.salvar(evento.copyWith(limparDataFim: true));
    expect(doc.opcoes!.merge, true);
    expect(doc.dados!['data_fim'], isA<FieldValue>());
  });
}
