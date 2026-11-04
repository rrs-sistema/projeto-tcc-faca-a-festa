// Firestore seals its public types; these test doubles only simulate reads.
// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/data/datasources/remote/orcamentos_admin_remote_datasource.dart';

// Exercita o datasource real sem rede ou projeto Firebase.
class _Db extends Fake implements FirebaseFirestore {
  final dados = <String, Map<String, dynamic>>{};
  final leituras = <String, int>{};
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _Collection(this, path);
}

class _Collection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  _Collection(this.db, this.caminho);
  final _Db db;
  final String caminho;
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _Reference(db, '$caminho/$path');
  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get(
          [GetOptions? options]) async =>
      _Snapshot(db.dados.keys
          .where((p) =>
              p.startsWith('$caminho/') &&
              p.split('/').length == caminho.split('/').length + 1)
          .map((p) => _Doc(db, p))
          .toList());
}

class _Reference extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  _Reference(this.db, this.caminho);
  final _Db db;
  final String caminho;
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _Collection(db, '$caminho/$path');
  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get(
      [GetOptions? options]) async {
    db.leituras.update(caminho, (n) => n + 1, ifAbsent: () => 1);
    return _Doc(db, caminho);
  }
}

class _Doc extends Fake implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _Doc(this.db, this.caminho);
  final _Db db;
  final String caminho;
  @override
  String get id => caminho.split('/').last;
  @override
  bool get exists => db.dados.containsKey(caminho);
  @override
  Map<String, dynamic> data() => db.dados[caminho] ?? {};
}

class _Snapshot extends Fake implements QuerySnapshot<Map<String, dynamic>> {
  _Snapshot(this.docs);
  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
}

void main() {
  test(
      'nome/cidade atuais, identidade do documento e pagamentos reais do detalhe',
      () async {
    final db = _Db();
    db.dados.addAll({
      'evento/ev': {
        'nome_evento': 'Aniversário da família',
        'nome_cidade': 'Curitiba',
        'custo_estimado': 5500
      },
      'orcamento/a': {
        'id_evento': 'ev',
        'custo_estimado': 6500,
        'status': 'pendente'
      },
      'orcamento/b': {
        'id_evento': 'ev',
        'custo_estimado': 500,
        'status': 'pendente'
      },
      'orcamento/a/orcamento_gasto/gasto': {
        'nome': 'Decoração',
        'custo': 6500,
        'pago': 4200
      },
    });
    final lista = await OrcamentosAdminRemoteDatasource(firestore: db)
        .listarOrcamentosComEventoDetalhes();
    final a = lista.firstWhere((o) => o.id == 'a');
    expect(a.idEvento, 'ev');
    expect(a.eventoNome, 'Aniversário da família');
    expect(a.cidade, 'Curitiba');
    expect(a.custoTotalEvento, 5500);
    expect(a.pagoCentavos, 420000);
    expect(db.leituras['evento/ev'], 1);
  });

  test('cadastro legado e campos atuais vazios usam nomes anteriores',
      () async {
    final db = _Db();
    db.dados.addAll({
      'evento/ev': {
        'nome_evento': ' ',
        'nome': 'Evento legado',
        'nome_cidade': '',
        'cidade': 'Maringá'
      },
      'orcamento/a': {'id_evento': 'ev'},
    });
    final lista = await OrcamentosAdminRemoteDatasource(firestore: db)
        .listarOrcamentosComEventoDetalhes();
    expect(lista.single.eventoNome, 'Evento legado');
    expect(lista.single.cidade, 'Maringá');
  });
}
