import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:app_faca_festa/core/conectividade/conectividade_service.dart';
import 'package:app_faca_festa/core/conectividade/estado_sincronizacao.dart';
import 'package:app_faca_festa/core/database/app_database.dart';
import 'package:app_faca_festa/data/datasources/local/gift_local_datasource.dart';
import 'package:app_faca_festa/data/datasources/remote/gift_remote_datasource.dart';
import 'package:app_faca_festa/data/models/gift/gift_model.dart';
import 'package:app_faca_festa/data/repositories_impl/gift_repository_impl.dart';
import 'package:app_faca_festa/data/services/gift/gift_sync_service.dart';
import 'package:app_faca_festa/domain/entities/gift/gift.dart';
import 'package:app_faca_festa/domain/entities/gift/gift_contribution.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/open.dart';

class _FirestoreFalso extends Fake implements FirebaseFirestore {}

typedef _Lote = ({List<GiftModel> presentes, bool doServidor});

/// Servidor controlado pelo teste: cada envio fica pendente até o teste
/// decidir, como uma escrita do Firestore sem internet.
class _ServidorFalso extends GiftRemoteDatasource {
  _ServidorFalso() : super(_FirestoreFalso());

  final lotes = StreamController<_Lote>.broadcast();
  final enviados = <String>[];
  final contribuicoes = <String, double>{};
  final envios = <Completer<void>>[];
  var responderNaHora = true;

  Future<void> _envio() {
    if (responderNaHora) return Future.value();
    final c = Completer<void>();
    envios.add(c);
    return c.future;
  }

  @override
  Stream<_Lote> observarServidor(String eventoId) => lotes.stream;

  @override
  Future<void> enviarDoAparelho(String eventoId, GiftModel model) {
    enviados.add(model.id);
    return _envio();
  }

  @override
  Future<void> deleteGift(String eventoId, String giftId) {
    enviados.add('excluir:$giftId');
    return _envio();
  }

  @override
  Future<void> saveContribution(
      String eventoId, String giftId, GiftContribution contribution) async {
    // Mesmo contrato do servidor: o id da contribuição é a chave.
    contribuicoes.putIfAbsent(contribution.id, () => contribution.valor);
  }
}

GiftModel _presente(String id, {double arrecadado = 0}) => GiftModel(
      id: id,
      nome: 'Presente $id',
      categoria: 'geral',
      tipo: GiftType.pix,
      valorArrecadado: arrecadado,
      status: GiftStatus.disponivel,
      createdAt: DateTime(2026, 11, 1),
    );

Future<ConectividadeService> _rede({required bool online}) async {
  final servico = Get.put(ConectividadeService(
    mudancasRede: const Stream.empty(),
    redeAtual: () async =>
        [online ? ConnectivityResult.wifi : ConnectivityResult.none],
    sonda: () async => online,
    intervaloOffline: const Duration(hours: 1),
    intervaloOnline: const Duration(hours: 1),
  ));
  await servico.iniciar();
  return servico;
}

void main() {
  setUpAll(() {
    if (Platform.isWindows) {
      open.overrideFor(
          OperatingSystem.windows, () => DynamicLibrary.open('winsqlite3.dll'));
    }
  });

  late AppDatabase banco;
  late GiftLocalDatasource local;
  late _ServidorFalso servidor;
  late GiftRepositoryImpl repo;

  setUp(() {
    Get.reset();
    banco = AppDatabase(NativeDatabase.memory());
    local = GiftLocalDatasource(banco);
    servidor = _ServidorFalso();
    repo = GiftRepositoryImpl(local: local, remote: servidor);
  });

  tearDown(() async {
    await banco.close();
    Get.reset();
  });

  test('a lista do servidor chega ao banco do aparelho', () async {
    final lista = repo.getGifts('evt');
    final chegou = lista.firstWhere((l) => l.any((g) => g.id == 'p1'));
    await Future<void>.delayed(Duration.zero);
    servidor.lotes.add((presentes: [_presente('p1')], doServidor: true));

    await chegou.timeout(const Duration(seconds: 2));
    expect((await local.getGift('p1'))?.synced, isTrue);
  });

  test('alteração local pendente não é sobrescrita pelo servidor', () async {
    await _rede(online: false);
    servidor.responderNaHora = false;
    final sub = repo.getGifts('evt').listen((_) {});
    await repo.createGift('evt', _presente('p1'));
    await repo.updateGift('evt', _presente('p1'));

    await repo.mesclarDoServidor('evt', [_presente('p1', arrecadado: 99)],
        doServidor: true);

    final linha = await local.getGift('p1');
    expect(linha?.synced, isFalse);
    expect(linha?.valorArrecadado, 0);
    await sub.cancel();
  });

  test('snapshot só do cache não apaga; o do servidor apaga o que sumiu',
      () async {
    await repo.mesclarDoServidor('evt', [_presente('p1'), _presente('p2')],
        doServidor: true);

    await repo.mesclarDoServidor('evt', [_presente('p1')], doServidor: false);
    expect(await local.getGift('p2'), isNotNull);

    await repo.mesclarDoServidor('evt', [_presente('p1')], doServidor: true);
    expect(await local.getGift('p2'), isNull);
  });

  test('cadastrar sem internet não espera o servidor e fica pendente',
      () async {
    await _rede(online: false);
    final estado = Get.put(EstadoSincronizacao());
    servidor.responderNaHora = false;

    final relogio = Stopwatch()..start();
    await repo.createGift('evt', _presente('p-off'));
    expect(relogio.elapsedMilliseconds, lessThan(500));

    expect((await local.getGift('p-off'))?.synced, isFalse);
    expect(estado.chavesPendentes, contains('p-off'));

    servidor.envios.single.complete();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect((await local.getGift('p-off'))?.synced, isTrue);
    expect(estado.chavesPendentes, isNot(contains('p-off')));
  });

  test('edição feita durante o envio continua pendente', () async {
    servidor.responderNaHora = false;
    await repo.createGift('evt', _presente('p1'));
    // Drift guarda a data em segundos: a segunda versão precisa ser outra.
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await repo.updateGift('evt', _presente('p1'));

    servidor.envios.first.complete();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect((await local.getGift('p1'))?.synced, isFalse);

    servidor.envios.last.complete();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect((await local.getGift('p1'))?.synced, isTrue);
  });

  test('contribuição offline soma no aparelho e é enviada uma única vez',
      () async {
    await repo.mesclarDoServidor('evt', [_presente('p1', arrecadado: 10)],
        doServidor: true);
    final rede = await _rede(online: false);

    await repo.contribuirPix(
        'evt',
        'p1',
        GiftContribution(
            id: 'c1', nome: 'Tia', valor: 50, data: DateTime(2026, 11, 2)));
    expect(servidor.contribuicoes, isEmpty);
    expect((await local.getGift('p1'))?.valorArrecadado, 60);

    // O servidor ainda não tem a contribuição: o valor local não volta a 10.
    await repo.mesclarDoServidor('evt', [_presente('p1', arrecadado: 10)],
        doServidor: true);
    expect((await local.getGift('p1'))?.valorArrecadado, 60);

    final sync = GiftSyncService(local: local, remote: servidor);
    await sync.syncPendentes();
    expect(servidor.contribuicoes, isEmpty, reason: 'offline não envia');

    rede.online.value = true;
    await sync.syncPendentes();
    await sync.syncPendentes();
    expect(servidor.contribuicoes, {'c1': 50});
    expect(await local.getUnsyncedContributions(), isEmpty);
  });

  test('contribuição sem id ganha um id estável antes de ir à fila', () async {
    await repo.mesclarDoServidor('evt', [_presente('p1')], doServidor: true);
    await _rede(online: false);
    await repo.contribuirPix('evt', 'p1',
        GiftContribution(id: '', nome: 'Ana', valor: 5, data: DateTime(2026)));

    final fila = await local.getUnsyncedContributions();
    expect(fila.single.contributionId, isNotEmpty);
  });
}
