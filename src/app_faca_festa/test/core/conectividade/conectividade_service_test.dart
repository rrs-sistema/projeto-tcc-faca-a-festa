import 'dart:async';

import 'package:app_faca_festa/core/conectividade/conectividade_service.dart';
import 'package:app_faca_festa/core/conectividade/escrita_local_primeiro.dart';
import 'package:app_faca_festa/core/conectividade/estado_sincronizacao.dart';
import 'package:app_faca_festa/core/conectividade/exigir_conexao.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Rede {
  final mudancas = StreamController<List<ConnectivityResult>>.broadcast();
  var atual = [ConnectivityResult.wifi];
  var servidorResponde = true;
  var sondas = 0;

  ConectividadeService servico() => ConectividadeService(
        mudancasRede: mudancas.stream,
        redeAtual: () async => atual,
        sonda: () async {
          sondas++;
          return servidorResponde;
        },
        intervaloOffline: const Duration(milliseconds: 40),
        intervaloOnline: const Duration(hours: 1),
      );
}

void main() {
  setUp(Get.reset);
  tearDown(Get.reset);

  group('ConectividadeService', () {
    test('Wi-Fi ligado sem servidor alcançável conta como offline', () async {
      final rede = _Rede()..servidorResponde = false;
      final servico = rede.servico();
      await servico.iniciar();
      expect(servico.offline, isTrue);
      servico.onClose();
    });

    test('sem interface de rede nem chama a sonda', () async {
      final rede = _Rede()..atual = [ConnectivityResult.none];
      final servico = rede.servico();
      await servico.iniciar();
      expect(servico.offline, isTrue);
      expect(rede.sondas, 0);
      servico.onClose();
    });

    test('a sonda periódica percebe a volta e emite a reconexão', () async {
      final rede = _Rede()..servidorResponde = false;
      final servico = rede.servico();
      final transicoes = <bool>[];
      servico.transicoes.listen(transicoes.add);
      await servico.iniciar();
      rede.servidorResponde = true;
      await servico.aoReconectar.first.timeout(const Duration(seconds: 2));
      expect(servico.offline, isFalse);
      expect(transicoes, [false, true]);
      servico.onClose();
    });

    test('mudança do sistema dispara verificação imediata', () async {
      final rede = _Rede();
      final servico = rede.servico();
      await servico.iniciar();
      expect(servico.offline, isFalse);
      rede.atual = [ConnectivityResult.none];
      rede.mudancas.add(rede.atual);
      await servico.transicoes.first.timeout(const Duration(seconds: 2));
      expect(servico.offline, isTrue);
      servico.onClose();
    });

    test('sem serviço registrado o app é tratado como online', () {
      expect(ConectividadeService.offlineAgora, isFalse);
    });
  });

  group('escritaLocalPrimeiro', () {
    test('offline não espera o servidor e conta a pendência', () async {
      final rede = _Rede()..servidorResponde = false;
      final servico = Get.put(rede.servico());
      final estado = Get.put(EstadoSincronizacao());
      await servico.iniciar();
      final servidor = Completer<void>();
      final relogio = Stopwatch()..start();
      await escritaLocalPrimeiro(servidor.future, descricao: 'tarefa');
      expect(relogio.elapsedMilliseconds, lessThan(200));
      expect(estado.pendentes.value, 1);
      servidor.complete();
      await Future<void>.delayed(Duration.zero);
      expect(estado.pendentes.value, 0);
      servico.onClose();
    });

    test('online espera a confirmação até o limite e não trava', () async {
      final rede = _Rede();
      final servico = Get.put(rede.servico());
      await servico.iniciar();
      final nunca = Completer<void>().future;
      final relogio = Stopwatch()..start();
      await escritaLocalPrimeiro(nunca,
          espera: const Duration(milliseconds: 120));
      expect(relogio.elapsedMilliseconds, greaterThanOrEqualTo(100));
      servico.onClose();
    });

    test('recusa do servidor vira aviso para o usuário', () async {
      final estado = Get.put(EstadoSincronizacao());
      final falha = Future<void>.error(
          FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
          StackTrace.empty);
      estado.registrar(falha, descricao: 'reserva do presente');
      await Future<void>.delayed(Duration.zero);
      expect(estado.ultimaRecusa.value, contains('reserva do presente'));
    });
  });

  group('exigirConexao', () {
    test('bloqueia com mensagem clara quando offline', () async {
      final rede = _Rede()..servidorResponde = false;
      final servico = Get.put(rede.servico());
      await servico.iniciar();
      expect(
        () => garantirConexao('Pagamento por PIX'),
        throwsA(isA<SemConexaoException>().having(
            (e) => e.toString(), 'mensagem', contains('precisa de internet'))),
      );
      servico.onClose();
    });

    test('online deixa passar', () async {
      final servico = Get.put(_Rede().servico());
      await servico.iniciar();
      expect(() => garantirConexao('Pagamento'), returnsNormally);
      servico.onClose();
    });
  });
}
