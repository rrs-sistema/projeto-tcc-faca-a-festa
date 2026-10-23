import 'dart:io';
import 'dart:convert';
import 'package:app_faca_festa/data/local/cadastro_armazenamento.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/data/datasources/remote/plano_execucao_remote_datasource.dart';
import 'package:app_faca_festa/domain/services/plano_execucao_service.dart';
import 'package:app_faca_festa/data/models/cardapio/cardapio_item_model.dart';
import 'package:app_faca_festa/data/models/cardapio/cardapio_model.dart';
import 'calculadora_criacao_inicial_test.dart'
    show BancoTx, DocumentoTx, TransacaoTx;
import 'calculadora_criacao_jornada_test.dart' show AuthOwner;
import 'plano_execucao_test.dart'
    show contextoExec, proporExec, loteExec, fichaExec;

class BancoExec extends BancoTx {
  @override
  DocumentReference<Map<String, dynamic>> doc(String path) =>
      DocumentoTx(this, path);
  @override
  Future<T> runTransaction<T>(TransactionHandler<T> transactionHandler,
      {Duration timeout = const Duration(seconds: 30),
      int maxAttempts = 5}) async {
    final tx = TransacaoExec(this);
    final resultado = await transactionHandler(tx);
    if (falhar) throw StateError('Falha antes do commit');
    dados.addAll(tx.escritas);
    return resultado;
  }
}

class MemoriaRecibos implements ArmazenamentoCadastroLocal {
  final dados = <String, String>{};
  @override
  Future<Map<String, String>> listar(String prefixo) async =>
      Map.fromEntries(dados.entries.where((e) => e.key.startsWith(prefixo)));
  @override
  Future<void> gravar(String chave, String valor) async {
    dados[chave] = valor;
  }

  @override
  Future<void> remover(String chave) async {
    dados.remove(chave);
  }
}

class TransacaoExec extends TransacaoTx {
  TransacaoExec(super.banco);
  @override
  Transaction update(
      DocumentReference documentReference, Map<Object, Object?> data) {
    escritas[documentReference.path] = {
      ...banco.dados[documentReference.path]!,
      ...Map<String, dynamic>.from(data)
    };
    return this;
  }
}

PropostaExecucaoPlano preparar(BancoExec banco,
    {Map<String, dynamic> operacao = const {}, bool ficha = false}) {
  if (operacao.isNotEmpty) {
    banco.dados['calculadora_operacao/evento'] = operacao;
  }
  banco.dados['evento/evento']!['total_adultos'] = 20;
  final base = contextoExec(quantidadeFinal: 7);
  for (final c in base.cardapios) {
    banco.dados['cardapios/${c.idCardapio}'] =
        CardapioModel.fromEntity(c).toMap();
    for (final i in base.itens[c.idCardapio]!) {
      banco.dados['cardapios/${c.idCardapio}/itens/${i.idItem}'] =
          CardapioItemModel.fromEntity(i).toMap();
    }
  }
  final fontes = <String, Map<String, dynamic>?>{
    for (final e in banco.dados.entries)
      e.key: Map<String, dynamic>.from(jsonDecode(
              jsonEncode(PlanoExecucaoRemoteDatasource.normalizar(e.value)))
          as Map),
    if (!banco.dados.containsKey('calculadora_operacao/evento'))
      'calculadora_operacao/evento': null,
  };
  return proporExec(
      contextoExec(fontes: fontes, quantidadeFinal: 7, operacao: operacao),
      ficha: ficha ? fichaExec() : null);
}

void main() {
  test(
      'troca de organizador bloqueia envio e não cria recuperação para outra conta',
      () async {
    final banco = BancoExec(),
        p = preparar(BancoExec()),
        memoria = MemoriaRecibos();
    p.contexto.fontes['evento/evento']!['id_usuario'] = 'outro';
    var chamadas = 0;
    final remote = PlanoExecucaoRemoteDatasource(banco, AuthOwner(),
        recuperacao: memoria, enviar: (_) async {
      chamadas++;
      return {'aplicado': true};
    });
    await expectLater(remote.aplicar(p), throwsStateError);
    expect(chamadas, 0);
    expect(memoria.dados, isEmpty);
  });
  test('conflito mostra categorias alteradas sem expor documentos privados',
      () async {
    final remote = PlanoExecucaoRemoteDatasource(BancoExec(), AuthOwner(),
        recuperacao: MemoriaRecibos(),
        enviar: (_) async => throw FirebaseFunctionsException(
                code: 'failed-precondition',
                message: 'Revise',
                details: {
                  'fontes': [
                    'convidado/privado',
                    'calculadora_operacao/evento',
                    'tarefa/id'
                  ]
                }));
    await expectLater(
        remote.aplicar(preparar(BancoExec())),
        throwsA(isA<StateError>().having(
            (e) => e.message,
            'diferenças',
            allOf(contains('público'), contains('estoque'), contains('tarefas'),
                isNot(contains('privado'))))));
  });
  test('cliente envia plano completo ao executor e não grava diretamente',
      () async {
    final banco = BancoExec(), proposta = preparar(BancoExec());
    final antes =
        jsonEncode(PlanoExecucaoRemoteDatasource.normalizar(banco.dados));
    final remote = PlanoExecucaoRemoteDatasource(banco, AuthOwner(),
        recuperacao: MemoriaRecibos(), enviar: (command) async {
      expect(command['evento'], 'evento');
      expect(command['pedido'], proposta.pedido);
      expect(command['plano'], jsonDecode(proposta.assinatura));
      return {'aplicado': true};
    });
    expect(await remote.aplicar(proposta), true);
    expect(jsonEncode(PlanoExecucaoRemoteDatasource.normalizar(banco.dados)),
        antes);
  });
  test('repetição idempotente respeita resposta do servidor', () async {
    final banco = BancoExec();
    final remote = PlanoExecucaoRemoteDatasource(banco, AuthOwner(),
        recuperacao: MemoriaRecibos(),
        enviar: (_) async => {'aplicado': false});
    expect(await remote.aplicar(preparar(banco)), false);
  });
  test('falha de rede não anuncia sucesso nem escreve no cliente', () async {
    final banco = BancoExec(), p = preparar(BancoExec());
    final antes = jsonEncode(banco.dados);
    final recibos = MemoriaRecibos();
    final remote = PlanoExecucaoRemoteDatasource(banco, AuthOwner(),
        recuperacao: recibos, enviar: (_) async => throw StateError('offline'));
    await expectLater(remote.aplicar(p), throwsStateError);
    expect(jsonEncode(banco.dados), antes);
    expect(recibos.dados.values.single, jsonEncode({'pedido': p.pedido}));
  });
  test(
      'resposta inválida não é confirmação; gera fixture do motor para emulador',
      () async {
    final banco = BancoExec(), p = preparar(BancoExec());
    final remote = PlanoExecucaoRemoteDatasource(banco, AuthOwner(),
        recuperacao: MemoriaRecibos(), enviar: (_) async => {});
    await expectLater(remote.aplicar(p), throwsStateError);
    final file = File('.dart_tool/calculadora-plano-fixture.json');
    await file.writeAsString(jsonEncode({
      'evento': p.contexto.evento,
      'pedido': p.pedido,
      'plano': jsonDecode(p.assinatura),
      'pendencias': p.pendencias
    }));
    final stock = preparar(BancoExec(), operacao: {
      'versao': 1,
      'revisao': 1,
      'lotes': {'arroz': loteExec(10)}
    });
    await File('.dart_tool/calculadora-estoque-fixture.json')
        .writeAsString(jsonEncode({
      'evento': stock.contexto.evento,
      'pedido': stock.pedido,
      'plano': jsonDecode(stock.assinatura),
      'pendencias': stock.pendencias
    }));
    final ingredients = preparar(BancoExec(), ficha: true);
    await File('.dart_tool/calculadora-ingredientes-fixture.json')
        .writeAsString(jsonEncode({
      'evento': ingredients.contexto.evento,
      'pedido': ingredients.pedido,
      'plano': jsonDecode(ingredients.assinatura),
      'pendencias': ingredients.pendencias
    }));
  });
}
