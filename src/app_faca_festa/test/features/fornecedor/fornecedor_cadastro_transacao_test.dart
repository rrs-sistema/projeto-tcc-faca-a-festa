// Dublês exclusivos da fronteira do SDK para observar as operações do datasource.
// ignore_for_file: subtype_of_sealed_class, must_be_immutable
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/data/datasources/remote/fornecedor_remote_datasource.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_cadastro_edicao.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_dados_cadastrais.dart';
import 'package:app_faca_festa/domain/entities/servico_produto.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_categoria.dart';

typedef _Estado = Map<String, Map<String, dynamic>>;

class _Db extends Fake implements FirebaseFirestore {
  final _Estado docs = {
    'fornecedor/forn': {
      'id_usuario': 'dono',
      'razao_social': 'Buffet atual',
      'telefone': '44987654321',
      'email': 'comercial@teste.com',
      'ativo': true,
      'apto_para_operar': true,
      'banner_url': 'https://example.com/atual.jpg',
      'media_avaliacoes': 4.9,
      'fcm_token': 'token',
      'cadastro_revisao': 2
    },
    'usuarios/dono': {
      'nome': 'Responsável Teste',
      'email': 'login@teste.com',
      'tipo': 'F',
      'senha_hash': 'preservar'
    },
    'usuarios/dono/enderecos/endereco': {
      'cep': '87010000',
      'logradouro': 'Rua original',
      'numero': '10',
      'bairro': 'Centro',
      'nome_cidade': 'Maringá',
      'uf': 'PR',
      'principal': true,
      'id_cidade': 12
    },
    'fornecedor_categoria/cat-antiga': {
      'id_fornecedor': 'forn',
      'id_categoria': 'cat',
      'nome_categoria': 'Buffet'
    },
    'fornecedor_servico/vinculo-existente': {
      'id_fornecedor': 'forn',
      'id_produto_servico': 'serv',
      'preco': 170,
      'preco_promocao': 150,
      'foto': 'foto-original',
      'ativo': true
    },
    'fornecedor_servico/vinculo-removido': {
      'id_fornecedor': 'forn',
      'id_produto_servico': 'retirado',
      'preco': 99,
      'ativo': true
    },
  };
  bool falharCommit = false;
  bool falharCanal = false;
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _Colecao(this, path);
  @override
  Future<T> runTransaction<T>(TransactionHandler<T> handler,
      {Duration timeout = const Duration(seconds: 30),
      int maxAttempts = 5}) async {
    if (falharCanal) {
      scheduleMicrotask(() => throw FirebaseException(
          plugin: 'cloud_firestore', code: 'permission-denied'));
      return Completer<T>().future;
    }
    final tx = _Tx(this);
    final result = await handler(tx);
    if (falharCommit) throw StateError('Commit recusado');
    final novo = docs
        .map((key, value) => MapEntry(key, Map<String, dynamic>.from(value)));
    for (final acao in tx.acoes) {
      acao(novo);
    }
    docs
      ..clear()
      ..addAll(novo);
    return result;
  }
}

class _Colecao extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  _Colecao(this.db, this.caminho, [this.campo, this.valor]);
  final _Db db;
  final String caminho;
  final String? campo;
  final Object? valor;
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _Doc(db, '$caminho/$path');
  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get(
          [GetOptions? options]) async =>
      _Resultado(db.docs.entries
          .where((e) =>
              e.key.startsWith('$caminho/') &&
              e.key.split('/').length == caminho.split('/').length + 1 &&
              (campo == null || e.value[campo] == valor))
          .map((e) => _ConsultaDoc(db, e.key))
          .toList());
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #where) {
      return _Colecao(
          db,
          caminho,
          invocation.positionalArguments.first as String,
          invocation.namedArguments[#isEqualTo]);
    }
    return super.noSuchMethod(invocation);
  }
}

class _Doc extends Fake implements DocumentReference<Map<String, dynamic>> {
  _Doc(this.db, this.path);
  final _Db db;
  @override
  final String path;
  @override
  String get id => path.split('/').last;
  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get(
          [GetOptions? options]) async =>
      _Snapshot(db, path);
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _Colecao(db, '${this.path}/$path');
}

class _Snapshot extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  _Snapshot(this.db, this.path);
  final _Db db;
  final String path;
  @override
  bool get exists => db.docs.containsKey(path);
  @override
  String get id => path.split('/').last;
  @override
  Map<String, dynamic>? data() => db.docs[path];
  @override
  DocumentReference<Map<String, dynamic>> get reference => _Doc(db, path);
}

class _ConsultaDoc extends _Snapshot
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _ConsultaDoc(super.db, super.path);
  @override
  Map<String, dynamic> data() => super.data()!;
}

class _Resultado extends Fake implements QuerySnapshot<Map<String, dynamic>> {
  _Resultado(this.docs);
  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  @override
  int get size => docs.length;
}

class _Tx extends Fake implements Transaction {
  _Tx(this.db);
  final _Db db;
  final acoes = <void Function(_Estado)>[];
  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
          DocumentReference<T> ref) async =>
      _Snapshot(db, ref.path) as DocumentSnapshot<T>;
  @override
  Transaction update(DocumentReference ref, Map<Object, Object?> data) {
    acoes.add((estado) {
      if (!estado.containsKey(ref.path)) throw StateError('Documento ausente');
      estado[ref.path]!.addAll(Map<String, dynamic>.from(data));
    });
    return this;
  }

  @override
  Transaction set<T>(DocumentReference<T> ref, T data, [SetOptions? options]) {
    acoes.add((estado) {
      estado[ref.path] = {
        ...(options?.merge == true
            ? estado[ref.path] ?? {}
            : <String, dynamic>{}),
        ...Map<String, dynamic>.from(data as Map)
      };
    });
    return this;
  }

  @override
  Transaction delete(DocumentReference ref) {
    acoes.add((estado) => estado.remove(ref.path));
    return this;
  }
}

class _Storage extends Fake implements FirebaseStorage {}

FornecedorCadastroAlteracao _alterar(FornecedorCadastroEdicao origem) =>
    FornecedorCadastroAlteracao(
      origem: origem,
      dados: FornecedorDadosCadastrais(
          razaoSocial: 'Buffet atualizado',
          email: 'novo@comercial.com',
          telefone: '44987651234',
          cnpj: '11222333000181',
          descricao: 'Descrição atualizada'),
      nomeResponsavel: 'Responsável Atualizado',
      endereco: origem.endereco!.copyWith(logradouro: 'Rua atualizada'),
      categorias: const [
        FornecedorCategoria(
            idFornecedor: 'forn', idCategoria: 'cat', nomeCategoria: 'Buffet')
      ],
      servicos: const [
        ServicoProduto(id: 'serv', nome: 'Atual', ativo: true),
        ServicoProduto(id: 'novo', nome: 'Novo serviço', ativo: true)
      ],
      tipoEventoIds: const ['casamento'],
      tipoEventoSlugs: const ['casamento'],
      tipoEventoNomes: const ['Casamento'],
    );

void main() {
  test(
      'carrega IDs reais e salva em conjunto sem recriar conta ou apagar preços',
      () async {
    final db = _Db();
    final remote = FirebaseFornecedorRemoteDatasource(db, storage: _Storage());
    db.docs['fornecedor_servico/duplicado-antigo'] = {
      'id_fornecedor': 'forn',
      'id_produto_servico': 'serv',
      'preco': 999,
      'ativo': true
    };
    db.docs['fornecedor/forn']!['id_fornecedor'] = 'alias-antigo-incorreto';
    final origem = await remote.carregarCadastroEdicao('forn');
    expect(origem.usuario.idUsuario, 'dono');
    expect(origem.fornecedor.idFornecedor, 'forn');
    expect(origem.endereco!.id, 'endereco');
    expect(origem.revisao, 2);
    // Alterações operacionais posteriores à abertura precisam sobreviver.
    db.docs['fornecedor/forn']!['ativo'] = false;
    await remote.salvarCadastroEdicao(_alterar(origem));
    expect(db.docs['fornecedor/forn']!['razao_social'], 'Buffet atualizado');
    expect(db.docs['fornecedor/forn']!['ativo'], false);
    expect(db.docs['fornecedor/forn']!['apto_para_operar'], true);
    expect(db.docs['fornecedor/forn']!['banner_url'],
        'https://example.com/atual.jpg');
    expect(db.docs['fornecedor/forn']!['fcm_token'], 'token');
    expect(db.docs['usuarios/dono']!['email'], 'login@teste.com');
    expect(db.docs['usuarios/dono']!['senha_hash'], 'preservar');
    expect(db.docs['usuarios/dono']!['nome'], 'Responsável Atualizado');
    expect(db.docs['usuarios/dono/enderecos/endereco']!['logradouro'],
        'Rua atualizada');
    expect(db.docs.keys.where((k) => k.startsWith('usuarios/dono/enderecos/')),
        hasLength(1));
    expect(db.docs['fornecedor_servico/vinculo-existente']!['preco'], 170);
    expect(db.docs['fornecedor_servico/vinculo-existente']!['foto'],
        'foto-original');
    expect(db.docs['fornecedor_servico/vinculo-removido']!['ativo'], false);
    expect(db.docs['fornecedor_servico/forn_novo']!['ativo'], true);
    expect(
        db.docs.entries.where((e) =>
            e.key.startsWith('fornecedor_servico/') &&
            e.value['id_produto_servico'] == 'serv' &&
            e.value['ativo'] == true),
        hasLength(1));
    expect(db.docs['fornecedor/forn']!['cadastro_revisao'], 3);
    await expectLater(
        remote.salvarCadastroEdicao(_alterar(origem)), throwsStateError);
    expect(db.docs.keys.where((k) => k == 'fornecedor_servico/forn_novo'),
        hasLength(1));
  });
  test('falha no commit preserva todos os documentos', () async {
    final db = _Db();
    final remote = FirebaseFornecedorRemoteDatasource(db, storage: _Storage());
    final origem = await remote.carregarCadastroEdicao('forn');
    final antes =
        db.docs.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v)));
    db.falharCommit = true;
    await expectLater(
        remote.salvarCadastroEdicao(_alterar(origem)), throwsStateError);
    expect(db.docs, antes);
  });
  test('falha no canal nativo retorna ao formulário sem repetir nem gravar',
      () async {
    final db = _Db();
    final remote = FirebaseFornecedorRemoteDatasource(db, storage: _Storage());
    final origem = await remote.carregarCadastroEdicao('forn');
    final antes =
        db.docs.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v)));
    db.falharCanal = true;
    await expectLater(
        remote.salvarCadastroEdicao(_alterar(origem)),
        throwsA(isA<FirebaseException>()
            .having((e) => e.code, 'code', 'permission-denied')));
    expect(db.docs, antes);
    db.falharCanal = false;
    await remote.salvarCadastroEdicao(_alterar(origem));
    expect(db.docs['fornecedor/forn']!['cadastro_revisao'], 3);
  });
  test(
      'troca de proprietário e ausência de responsável bloqueiam edição completa',
      () async {
    final db = _Db();
    final remote = FirebaseFornecedorRemoteDatasource(db, storage: _Storage());
    final origem = await remote.carregarCadastroEdicao('forn');
    db.docs['fornecedor/forn']!['id_usuario'] = 'outra-conta';
    await expectLater(
        remote.salvarCadastroEdicao(_alterar(origem)), throwsStateError);
    await expectLater(remote.carregarCadastroEdicao('forn'), throwsStateError);
    expect(db.docs['fornecedor/forn']!['razao_social'], 'Buffet atual');
  });
}
