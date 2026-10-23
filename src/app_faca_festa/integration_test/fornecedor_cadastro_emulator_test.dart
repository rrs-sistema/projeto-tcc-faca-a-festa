import 'dart:convert';

import 'package:app_faca_festa/data/datasources/remote/fornecedor_remote_datasource.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_cadastro_edicao.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_categoria.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_dados_cadastrais.dart';
import 'package:app_faca_festa/domain/entities/servico_produto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

class _Storage extends Fake implements FirebaseStorage {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('SDK real salva e reabre cadastro completo com regras locais',
      (tester) async {
    if (!const bool.fromEnvironment('FORNECEDOR_QA')) {
      throw StateError('Execute somente com os emuladores locais.');
    }
    const projeto = 'demo-fornecedor-cadastro';
    final app = await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: 'AIzaSyAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
            appId: '1:1234567890:web:1234567890abcdef',
            messagingSenderId: '1234567890',
            projectId: projeto));
    if (app.options.projectId != projeto) throw StateError('Projeto recusado');
    final auth = FirebaseAuth.instanceFor(app: app);
    final db = FirebaseFirestore.instanceFor(app: app);
    db.settings = const Settings(persistenceEnabled: false);
    await auth.useAuthEmulator('127.0.0.1', 9197, automaticHostMapping: false);
    db.useFirestoreEmulator('127.0.0.1', 8187, automaticHostMapping: false);
    final conta = await auth.createUserWithEmailAndPassword(
        email: 'admin-${DateTime.now().microsecondsSinceEpoch}@example.test',
        password: 'TesteLocal123!');
    // REST local usa o bypass exclusivo do emulador para preparar a fixture.
    Future<void> preparar(String path, Map<String, dynamic> fields) async {
      final resposta = await http.patch(
          Uri.parse(
              'http://127.0.0.1:8187/v1/projects/$projeto/databases/(default)/documents/$path'),
          headers: {
            'Authorization': 'Bearer owner',
            'Content-Type': 'application/json'
          },
          body: jsonEncode({'fields': fields}));
      expect(resposta.statusCode, 200, reason: resposta.body);
    }

    Map<String, dynamic> texto(String v) => {'stringValue': v};
    await preparar('usuarios/${conta.user!.uid}', {
      'tipo': texto('A'),
      'ativo': {'booleanValue': true},
    });
    await preparar('usuarios/dono', {
      'nome': texto('Responsável Teste'),
      'email': texto('login@example.test'),
      'tipo': texto('F'),
      'ativo': {'booleanValue': true},
    });
    await preparar('fornecedor/forn', {
      'id_fornecedor': texto('forn'),
      'id_usuario': texto('dono'),
      'razao_social': texto('Fornecedor Teste'),
      'email': texto('comercial@example.test'),
      'telefone': texto('44987654321'),
      'ativo': {'booleanValue': true},
      'apto_para_operar': {'booleanValue': true},
    });
    await preparar('usuarios/dono/enderecos/principal', {
      'id_usuario': texto('dono'),
      'logradouro': texto('Rua Inicial'),
      'numero': texto('10'),
      'cep': texto('87010000'),
      'bairro': texto('Centro'),
      'nome_cidade': texto('Maringá'),
      'uf': texto('PR'),
      'principal': {'booleanValue': true},
    });
    await preparar('fornecedor_servico/existente', {
      'id_fornecedor': texto('forn'),
      'id_produto_servico': texto('existente'),
      'preco': {'doubleValue': 170},
      'ativo': {'booleanValue': true},
    });
    final remote = FirebaseFornecedorRemoteDatasource(db, storage: _Storage());
    FornecedorCadastroAlteracao alterar(FornecedorCadastroEdicao origem) =>
        FornecedorCadastroAlteracao(
          origem: origem,
          dados: FornecedorDadosCadastrais(
              razaoSocial: 'Fornecedor Atualizado',
              email: 'novo@example.test',
              telefone: '44987654321',
              cnpj: '',
              descricao: 'Descrição atualizada'),
          nomeResponsavel: 'Responsável Atualizado',
          endereco: origem.endereco!.copyWith(logradouro: 'Rua Atualizada'),
          categorias: const [
            FornecedorCategoria(
                idFornecedor: 'forn',
                idCategoria: 'cat',
                nomeCategoria: 'Buffet')
          ],
          servicos: const [
            ServicoProduto(id: 'existente', nome: 'Existente', ativo: true),
            ServicoProduto(
                id: 'novo', nome: 'Novo', idSubcategoria: 'sub', ativo: true),
          ],
          tipoEventoIds: const ['casamento'],
          tipoEventoSlugs: const ['casamento'],
          tipoEventoNomes: const ['Casamento'],
        );
    final origem = await remote.carregarCadastroEdicao('forn');
    await remote.salvarCadastroEdicao(alterar(origem));
    final salvo = await remote.carregarCadastroEdicao('forn');
    expect(salvo.revisao, 1);
    expect(salvo.fornecedor.razaoSocial, 'Fornecedor Atualizado');
    expect(salvo.usuario.nome, 'Responsável Atualizado');
    expect(salvo.usuario.email, 'login@example.test');
    expect(salvo.endereco!.logradouro, 'Rua Atualizada');
    expect(salvo.vinculos, hasLength(2));
    expect(
        salvo.vinculos
            .firstWhere((v) => v.idProdutoServico == 'existente')
            .preco,
        170);
    await expectLater(
        remote.salvarCadastroEdicao(alterar(origem)), throwsStateError);
    expect((await remote.carregarCadastroEdicao('forn')).revisao, 1);
    await auth.signOut();
    await auth.createUserWithEmailAndPassword(
        email: 'outro-${DateTime.now().microsecondsSinceEpoch}@example.test',
        password: 'TesteLocal123!');
    await expectLater(
        remote.salvarCadastroEdicao(alterar(salvo)),
        throwsA(isA<FirebaseException>().having(
            (e) => e.code,
            'code',
            // TransactionGet do SDK Windows perde o código original da negativa.
            defaultTargetPlatform == TargetPlatform.windows
                ? anyOf('permission-denied', 'unknown')
                : 'permission-denied')));
    await auth.signOut();
    await auth.signInWithEmailAndPassword(
        email: conta.user!.email!, password: 'TesteLocal123!');
    final depoisDaNegativa = await remote.carregarCadastroEdicao('forn');
    expect(depoisDaNegativa.revisao, 1);
    expect(depoisDaNegativa.usuario.email, 'login@example.test');
    expect(depoisDaNegativa.vinculos, hasLength(2));
    await auth.signOut();
  }, timeout: const Timeout(Duration(minutes: 3)));
}
