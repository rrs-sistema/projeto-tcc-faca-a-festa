import 'dart:async';

import 'package:app_faca_festa/core/conectividade/conectividade_service.dart';
import 'package:app_faca_festa/core/conectividade/recarregar_ao_reconectar.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Tela extends GetxController with RecarregarAoReconectar {
  @override
  Duration get esperaFilaAoReconectar => const Duration(milliseconds: 20);
}

void main() {
  late StreamController<List<ConnectivityResult>> mudancas;
  late ConectividadeService servico;
  var servidorResponde = false;

  Future<void> ficarOffline() async {
    servidorResponde = false;
    await servico.verificarAgora();
  }

  /// Reconecta e espera [ate] ficar verdadeiro (a repetição roda em outro
  /// microtask/timer). Sem [ate], só confirma a verificação.
  Future<void> reconectar([bool Function()? ate]) async {
    servidorResponde = true;
    await servico.verificarAgora();
    if (ate == null) return;
    final limite = DateTime.now().add(const Duration(seconds: 5));
    while (!ate() && DateTime.now().isBefore(limite)) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  setUp(() async {
    Get.reset();
    mudancas = StreamController<List<ConnectivityResult>>.broadcast();
    servidorResponde = false;
    servico = Get.put(ConectividadeService(
      mudancasRede: mudancas.stream,
      redeAtual: () async => [ConnectivityResult.wifi],
      sonda: () async => servidorResponde,
      intervaloOffline: const Duration(hours: 1),
      intervaloOnline: const Duration(hours: 1),
    ));
    await servico.verificarAgora();
  });

  tearDown(() async {
    servico.onClose();
    await mudancas.close();
    Get.reset();
  });

  group('RecarregarAoReconectar', () {
    test('repete a carga a cada volta da internet', () async {
      final tela = _Tela();
      var cargas = 0;
      tela.repetirAoReconectar('lista', () async => cargas++);

      await reconectar(() => cargas == 1);
      expect(cargas, 1);

      await ficarOffline();
      await reconectar(() => cargas == 2);
      expect(cargas, 2);
      tela.onClose();
    });

    test('escuta que caiu com erro é refeita só uma vez', () async {
      final tela = _Tela();
      var refeitas = 0;
      tela.refazerAoReconectar('escuta', () => refeitas++);

      await reconectar(() => refeitas == 1);
      await ficarOffline();
      await reconectar();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(refeitas, 1);
      tela.onClose();
    });

    test('com condição, só repete enquanto ela vale', () async {
      final tela = _Tela();
      var cargas = 0;
      var semDados = false;
      tela.repetirAoReconectar('calculo', () async => cargas++,
          quando: () => semDados);

      await reconectar();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(cargas, 0);

      semDados = true;
      await ficarOffline();
      await reconectar(() => cargas == 1);
      expect(cargas, 1);
      tela.onClose();
    });

    test('falha de uma carga não impede as outras', () async {
      final tela = _Tela();
      var segunda = 0;
      tela.repetirAoReconectar('quebra', () async => throw StateError('x'));
      tela.repetirAoReconectar('lista', () async => segunda++);

      await reconectar(() => segunda == 1);
      expect(segunda, 1);
      tela.onClose();
    });

    test('tela fechada não recarrega nem esquecida é repetida', () async {
      final fechada = _Tela();
      final aberta = _Tela();
      var cargasFechada = 0;
      var cargasEsquecida = 0;
      fechada.repetirAoReconectar('lista', () async => cargasFechada++);
      aberta.repetirAoReconectar('lista', () async => cargasEsquecida++);
      aberta.esquecerRecarga('lista');
      fechada.onClose();

      await reconectar();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(cargasFechada, 0);
      expect(cargasEsquecida, 0);
      aberta.onClose();
    });
  });

  group('mensagens sem internet', () {
    test('falhaDeConexao reconhece o aparelho offline', () async {
      expect(falhaDeConexao(StateError('qualquer')), isTrue);
      await reconectar();
      expect(falhaDeConexao(StateError('qualquer')), isFalse);
    });

    test('semInternetPara explica quando o dado aparece', () {
      expect(semInternetPara('As recomendações aparecem'),
          'Sem internet. As recomendações aparecem quando a conexão voltar.');
    });
  });
}
