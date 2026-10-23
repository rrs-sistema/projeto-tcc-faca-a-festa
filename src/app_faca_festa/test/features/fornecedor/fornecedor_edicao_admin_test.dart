import 'dart:async';

import 'package:app_faca_festa/data/datasources/remote/fornecedor_remote_datasource.dart';
import 'package:app_faca_festa/data/repositories_impl/fornecedor_repository_impl.dart';
import 'package:app_faca_festa/domain/entities/cotacao.dart';
import 'package:app_faca_festa/domain/entities/fornecedor.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_dados_cadastrais.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_servico_detalhado.dart';
import 'package:app_faca_festa/domain/entities/usuario.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_fornecedores.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_ai_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// Dublês da fronteira do SDK; nenhuma implementação alternativa de produção.
// ignore: subtype_of_sealed_class, must_be_immutable
class _Doc extends Fake implements DocumentReference<Map<String, dynamic>> {
  int escritas = 0;
  bool falhar = false;
  Completer<void>? aguardar;
  Map<String, dynamic>? enviado;
  final dados = <String, dynamic>{
    'ativo': true,
    'apto_para_operar': true,
    'campo_desconhecido': 'preservado'
  };
  @override
  Future<void> update(Map<Object, Object?> data) async {
    escritas++;
    enviado = Map<String, dynamic>.from(data);
    if (aguardar != null) await aguardar!.future;
    if (falhar) throw StateError('Falha simulada na gravação');
    dados.addAll(enviado!);
  }
}

// ignore: subtype_of_sealed_class, must_be_immutable
class _Colecao extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  final docRef = _Doc();
  String? documentoId;
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    documentoId = path;
    return docRef;
  }
}

class _Firestore extends Fake implements FirebaseFirestore {
  final colecao = _Colecao();
  String? caminho;
  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    caminho = collectionPath;
    return colecao;
  }
}

class _Storage extends Fake implements FirebaseStorage {}

class _App extends Fake implements AppController {
  @override
  final usuarioLogado = Rx<Usuario?>(const Usuario(
      idUsuario: 'admin', nome: 'Admin', email: 'admin@teste.com', tipo: 'A'));
}

class _Ai extends Fake implements FornecedorAiController {
  @override
  void vincular(
      {required Fornecedor? Function() fornecedorAtual,
      required List<FornecedorServicoDetalhado> Function() servicosDetalhados,
      required Future<List<Cotacao>> Function() solicitacoesPendentes}) {}
}

Fornecedor _fornecedor() => Fornecedor(
      idFornecedor: 'doc-fornecedor',
      idUsuario: 'conta-fornecedor',
      razaoSocial: 'Empresa antiga',
      cnpj: '11.222.333/0001-81',
      email: 'contato@antigo.com',
      telefone: '(44) 98765-4321',
      descricao: 'Descrição anterior',
      dataCadastro: DateTime(2026, 1, 1),
      ativo: true,
      aptoParaOperar: true,
      totalContratacoes: 17,
      mediaAvaliacoes: 4.8,
      bannerUrl: 'https://example.com/banner.jpg',
      fcmToken: 'token-preservado',
    );
FornecedorDadosCadastrais _edicao() => FornecedorDadosCadastrais(
      razaoSocial: ' Empresa atualizada ',
      email: ' novo@empresa.com ',
      telefone: '(44) 98765-1234',
      cnpj: '',
      descricao: '',
    );
FornecedorController _controller(_Firestore firestore, _App app) =>
    FornecedorController(
      ai: _Ai(),
      appController: app,
      gerenciarFornecedores: GerenciarFornecedores(FornecedorRepositoryImpl(
          FirebaseFornecedorRemoteDatasource(firestore, storage: _Storage()))),
    )..fornecedores.add(_fornecedor());

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  tearDown(Get.reset);

  test(
      'patch persiste só cadastro e lista conserva alterações concorrentes de status',
      () async {
    final db = _Firestore();
    final app = _App();
    final c = _controller(db, app);
    db.colecao.docRef.aguardar = Completer<void>();
    final pendente = c.editarDadosFornecedorAdmin(
        idFornecedor: 'doc-fornecedor', dados: _edicao());
    await Future<void>.delayed(Duration.zero);
    expect(c.fornecedores.single.razaoSocial, 'Empresa antiga');
    await expectLater(
        c.editarDadosFornecedorAdmin(
            idFornecedor: 'doc-fornecedor', dados: _edicao()),
        throwsStateError);
    expect(db.colecao.docRef.escritas, 1);
    c.fornecedores[0] =
        c.fornecedores.single.copyWith(ativo: false, aptoParaOperar: false);
    db.colecao.docRef.aguardar!.complete();
    await pendente;
    final resultado = c.fornecedores.single;
    expect(db.caminho, 'fornecedor');
    expect(db.colecao.documentoId, 'doc-fornecedor');
    expect(db.colecao.docRef.enviado!.keys.toSet(),
        {'razao_social', 'email', 'telefone', 'cnpj', 'descricao'});
    expect(resultado.razaoSocial, 'Empresa atualizada');
    expect(resultado.email, 'novo@empresa.com');
    expect(resultado.cnpj, '');
    expect(resultado.descricao, '');
    expect(resultado.ativo, false);
    expect(resultado.aptoParaOperar, false);
    expect(resultado.idUsuario, 'conta-fornecedor');
    expect(resultado.totalContratacoes, 17);
    expect(resultado.mediaAvaliacoes, 4.8);
    expect(resultado.fcmToken, 'token-preservado');
    expect(db.colecao.docRef.dados['campo_desconhecido'], 'preservado');
    expect(db.colecao.docRef.dados['ativo'], true);
    c.filtroNome.value = 'atualizada';
    expect(c.fornecedoresFiltrados, hasLength(1));
  });

  test('falha remota não altera lista; tentativa posterior salva normalmente',
      () async {
    final db = _Firestore();
    final c = _controller(db, _App());
    db.colecao.docRef.falhar = true;
    await expectLater(
        c.editarDadosFornecedorAdmin(
            idFornecedor: 'doc-fornecedor', dados: _edicao()),
        throwsStateError);
    expect(c.fornecedores.single.razaoSocial, 'Empresa antiga');
    db.colecao.docRef.falhar = false;
    await c.editarDadosFornecedorAdmin(
        idFornecedor: 'doc-fornecedor', dados: _edicao());
    expect(c.fornecedores.single.razaoSocial, 'Empresa atualizada');
  });

  test('não administrador e administrador inativo não gravam', () async {
    final db = _Firestore();
    final app = _App();
    final c = _controller(db, app);
    for (final usuario in [
      app.usuarioLogado.value!.copyWith(tipo: 'F'),
      app.usuarioLogado.value!.copyWith(ativo: false)
    ]) {
      app.usuarioLogado.value = usuario;
      expect(c.podeEditarDadosFornecedor, false);
      await expectLater(
          c.editarDadosFornecedorAdmin(
              idFornecedor: 'doc-fornecedor', dados: _edicao()),
          throwsStateError);
    }
    expect(db.colecao.docRef.escritas, 0);
  });

  test('validação impede gravação por chamada direta com e-mail inválido',
      () async {
    final db = _Firestore();
    final c = _controller(db, _App());
    await expectLater(
        c.editarDadosFornecedorAdmin(
            idFornecedor: 'doc-fornecedor',
            dados: FornecedorDadosCadastrais(
                razaoSocial: 'Nome válido',
                email: 'invalido',
                telefone: '',
                cnpj: '',
                descricao: '')),
        throwsArgumentError);
    expect(db.colecao.docRef.escritas, 0);
  });

  test('troca de sessão durante gravação não repovoa a lista da nova sessão',
      () async {
    final db = _Firestore();
    final app = _App();
    final c = _controller(db, app);
    db.colecao.docRef.aguardar = Completer<void>();
    final pendente = c.editarDadosFornecedorAdmin(
        idFornecedor: 'doc-fornecedor', dados: _edicao());
    await Future<void>.delayed(Duration.zero);
    app.usuarioLogado.value = null;
    c.fornecedores.clear();
    db.colecao.docRef.aguardar!.complete();
    await pendente;
    expect(c.fornecedores, isEmpty);
  });
}
