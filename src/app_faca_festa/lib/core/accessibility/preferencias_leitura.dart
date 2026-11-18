import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

class PreferenciasLeitura extends ChangeNotifier {
  static const minimo = 0.85;
  static const maximo = 2.0;
  static const chave = 'preferencia_tamanho_texto_v1';

  PreferenciasLeitura({
    double escalaInicial = 1,
    Future<void> Function(double)? salvar,
  })  : _escala = normalizar(escalaInicial),
        _salvar = salvar;

  factory PreferenciasLeitura.persistidas(GetStorage storage) {
    final valor = storage.read<dynamic>(chave);
    return PreferenciasLeitura(
      escalaInicial: valor is num ? valor.toDouble() : 1,
      salvar: (escala) async {
        await storage.write(chave, escala);
        await Future<void>.delayed(Duration.zero);
        await storage.queue.add(() async {});
      },
    );
  }

  final Future<void> Function(double)? _salvar;
  double _escala;
  String? _erro;
  Timer? _timer;
  Future<void> _gravacao = Future.value();
  int _versao = 0;
  bool _encerrado = false;

  double get escala => _escala;
  String? get erro => _erro;

  static double normalizar(double valor) =>
      valor.isFinite ? valor.clamp(minimo, maximo).toDouble() : 1;

  void ajustar(double valor) {
    final proxima = normalizar(valor);
    if ((proxima - _escala).abs() < 0.005) return;
    _escala = proxima;
    _versao++;
    _erro = null;
    notifyListeners();
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 300), () {
      unawaited(guardar());
    });
  }

  Future<void> guardar() {
    _timer?.cancel();
    final salvar = _salvar;
    if (salvar == null) return Future.value();
    final escala = _escala;
    final versao = _versao;
    _gravacao = _gravacao.then((_) async {
      try {
        await salvar(escala);
        if (!_encerrado && versao == _versao && _erro != null) {
          _erro = null;
          notifyListeners();
        }
      } catch (_) {
        if (!_encerrado && versao == _versao) {
          _erro =
              'O tamanho foi aplicado. Tente guardar novamente neste aparelho.';
          notifyListeners();
        }
      }
    });
    return _gravacao;
  }

  @override
  void dispose() {
    _encerrado = true;
    _timer?.cancel();
    super.dispose();
  }
}
