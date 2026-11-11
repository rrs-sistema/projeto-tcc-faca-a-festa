// Test doubles na fronteira do SDK; não carregam coleções usadas só em contagens.
// ignore_for_file: subtype_of_sealed_class
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/data/datasources/remote/admin_dashboard_remote_datasource.dart';
import 'package:app_faca_festa/data/datasources/remote/painel_fontes_disponiveis.dart';
import 'package:app_faca_festa/data/models/evento/tema_festa_model.dart';
import 'package:app_faca_festa/data/services/functions/callable_sessao_gateway.dart';

class _Db extends Fake implements FirebaseFirestore {
  final downloads = <String>[];
  final contagens = <String>[];
  final dados = <String, List<Map<String, dynamic>>>{};
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _Collection(this, path);
  @override
  Query<Map<String, dynamic>> collectionGroup(String path) =>
      _Collection(this, path);
  @override
  DocumentReference<Map<String, dynamic>> doc(String path) {
    downloads.add(path);
    return _Doc(dados[path]?.first ?? {});
  }
}

class _Doc extends Fake implements DocumentReference<Map<String, dynamic>> {
  _Doc(this.linha);
  final Map<String, dynamic> linha;

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get(
          [GetOptions? options]) async =>
      _Document(linha);
}

class _Document extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  _Document(this.linha);
  final Map<String, dynamic> linha;

  @override
  Map<String, dynamic> data() => linha;
}

class _ReputacaoGateway extends Fake implements CallableSessaoGateway {
  @override
  String get usuario => 'f';

  Map<String, dynamic> resumo = {'quantidade': 0, 'media': null};

  @override
  Future<Map<String, dynamic>> chamar(
      String funcao, Map<String, dynamic> dados) async {
    expect(funcao, 'consultarGestaoReputacaoFn');
    expect(dados, {'idFornecedor': 'f', 'tipo': 'fornecedor', 'limite': 1});
    return {'resumo': resumo};
  }
}

class _Collection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  _Collection(this.db, this.path, [this.ativo]);
  final _Db db;
  @override
  final String path;
  final bool? ativo;
  List<Map<String, dynamic>> get linhas => (db.dados[path] ?? [])
      .where((d) => ativo == null || d['ativo'] == ativo)
      .toList();
  @override
  Query<Map<String, dynamic>> where(Object field,
          {Object? isEqualTo,
          Object? isNotEqualTo,
          Object? isLessThan,
          Object? isLessThanOrEqualTo,
          Object? isGreaterThan,
          Object? isGreaterThanOrEqualTo,
          Object? arrayContains,
          Iterable<Object?>? arrayContainsAny,
          Iterable<Object?>? whereIn,
          Iterable<Object?>? whereNotIn,
          bool? isNull}) =>
      _Collection(db, path, field == 'ativo' ? isEqualTo as bool : ativo);
  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    db.downloads.add(path);
    return _Snapshot(linhas);
  }

  @override
  AggregateQuery count() => _Aggregate(this);
}

class _Aggregate extends Fake implements AggregateQuery {
  _Aggregate(this.fonte);
  final _Collection fonte;
  @override
  Future<AggregateQuerySnapshot> get(
      {AggregateSource source = AggregateSource.server}) async {
    fonte.db.contagens.add(fonte.path);
    return _Total(fonte.linhas.length);
  }
}

class _Total extends Fake implements AggregateQuerySnapshot {
  _Total(this.count);
  @override
  final int count;
}

class _Snapshot extends Fake implements QuerySnapshot<Map<String, dynamic>> {
  _Snapshot(this.linhas);
  final List<Map<String, dynamic>> linhas;
  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs =>
      linhas.map(_Row.new).toList();
}

class _Row extends Fake implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _Row(this.linha);
  final Map<String, dynamic> linha;
  @override
  Map<String, dynamic> data() => linha;
}

void main() {
  test('indicadores admin mantêm regras legadas e só contam três cadastros',
      () async {
    final db = _Db();
    db.dados.addAll({
      'categoria_servico': [
        {},
        {'ativo': false}
      ],
      'servico_produto': [
        {},
        {'ativo': false}
      ],
      'fornecedor': [
        {'aptoParaOperar': true},
        {},
        {'ativo': false}
      ],
      'usuarios': [
        {},
        {'ativo': false}
      ],
      'evento': [
        {},
        {'status': 'cancelado'},
        {'status': 'planejamento'}
      ],
      'orcamento': [
        {},
        {'status': 'Em negociação'},
        {'status': 'fechado'}
      ],
      'subcategoria_servico': List.generate(2000, (_) => {}),
      TemaFestaModel.colecao: List.generate(300, (_) => {}),
      'territorio': List.generate(1000, (_) => {}),
    });
    final r = await AdminDashboardRemoteDatasource(firestore: db)
        .carregarIndicadores();
    expect([
      r.categoriasAtivas,
      r.servicos,
      r.fornecedoresAptos,
      r.fornecedoresPendentes
    ], [
      1,
      1,
      1,
      1
    ]);
    expect([r.usuariosAtivos, r.eventosAtivos, r.orcamentosAbertos], [1, 2, 2]);
    expect([r.subcategorias, r.temas, r.territorios], [2000, 300, 1000]);
    expect(
        db.contagens,
        unorderedEquals(
            ['subcategoria_servico', TemaFestaModel.colecao, 'territorio']));
    expect(db.downloads, hasLength(6));
    expect(db.downloads.toSet().intersection(db.contagens.toSet()), isEmpty);
  });
  test('painel conta estoque e só ofertas explicitamente ativas', () async {
    final db = _Db();
    db.dados['fornecedor_servico'] = [
      {'ativo': true},
      {'ativo': false},
      {}
    ];
    db.dados['fornecedor/f/estoque_itens'] = List.generate(2000, (_) => {});
    final r =
        await PainelFontesDisponiveis(db: db, gateway: _ReputacaoGateway())
            .carregar('f');
    expect(r['catalogo'], 1);
    expect(r['estoque'], 2000);
    expect(db.downloads, isNot(contains('fornecedor_servico')));
    expect(db.downloads, isNot(contains('fornecedor/f/estoque_itens')));
  });
  test('painel usa o resumo de avaliações e ignora o agregado do cadastro',
      () async {
    final db = _Db();
    db.dados['fornecedor/f'] = [
      {'media_avaliacoes': 4.4, 'total_avaliacoes': 45},
    ];
    final gateway = _ReputacaoGateway();
    final fontes = PainelFontesDisponiveis(db: db, gateway: gateway);

    final semAvaliacoes = await fontes.carregar('f');
    expect(semAvaliacoes['reputacao'], isNull);
    expect(semAvaliacoes['fontes']['reputacao']['estado'], 'disponivel');

    gateway.resumo = {'quantidade': 2, 'media': 4.5};
    final comAvaliacoes = await fontes.carregar('f');
    expect(comAvaliacoes['reputacao'], {'quantidade': 2, 'media': 4.5});
    expect(db.downloads, isNot(contains('fornecedor/f')));
  });
}
