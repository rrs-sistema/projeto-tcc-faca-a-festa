import 'dart:async';
import 'dart:io' show Socket;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Responde se o backend está alcançável agora.
typedef SondaAlcance = Future<bool> Function();

/// Sonda TCP: só a interface de rede ligada não prova que o servidor responde
/// (Wi-Fi sem internet, portal cativo, servidor fora do ar).
SondaAlcance sondaTcp(
  String host,
  int porta, {
  Duration limite = const Duration(seconds: 4),
}) {
  return () async {
    if (kIsWeb) return true;
    try {
      final socket = await Socket.connect(host, porta, timeout: limite);
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  };
}

/// Estado de conexão do aplicativo, compartilhado por dados e interface.
///
/// Combina o aviso do sistema ([Connectivity]) com uma sonda de alcance do
/// backend, refeita periodicamente enquanto estiver offline.
class ConectividadeService extends GetxService {
  ConectividadeService({
    Stream<List<ConnectivityResult>>? mudancasRede,
    Future<List<ConnectivityResult>> Function()? redeAtual,
    SondaAlcance? sonda,
    this.intervaloOffline = const Duration(seconds: 8),
    this.intervaloOnline = const Duration(seconds: 60),
  })  : _mudancasRede = mudancasRede,
        _redeAtual = redeAtual,
        _sonda = sonda ?? sondaTcp('firestore.googleapis.com', 443);

  final Stream<List<ConnectivityResult>>? _mudancasRede;
  final Future<List<ConnectivityResult>> Function()? _redeAtual;
  final SondaAlcance _sonda;
  final Duration intervaloOffline;
  final Duration intervaloOnline;

  final RxBool online = true.obs;
  final Rx<DateTime?> ultimaMudanca = Rx<DateTime?>(null);

  final _transicoes = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _redeSub;
  Timer? _timer;
  Future<bool>? _verificando;
  bool _iniciado = false;

  /// Emite `true` ao reconectar e `false` ao perder a conexão.
  Stream<bool> get transicoes => _transicoes.stream;

  Stream<void> get aoReconectar => transicoes.where((online) => online);

  bool get offline => !online.value;

  static ConectividadeService? get instancia =>
      Get.isRegistered<ConectividadeService>()
          ? Get.find<ConectividadeService>()
          : null;

  /// Sem serviço registrado (testes de unidade antigos) o app é tratado como online.
  static bool get offlineAgora => instancia?.offline ?? false;

  Future<void> iniciar() async {
    if (_iniciado) return;
    _iniciado = true;
    final mudancas = _mudancasRede ?? _conectividadeDoSistema();
    _redeSub = mudancas?.listen(
      (_) => unawaited(verificarAgora()),
      onError: (Object _) {},
    );
    await verificarAgora();
  }

  Stream<List<ConnectivityResult>>? _conectividadeDoSistema() {
    try {
      return Connectivity().onConnectivityChanged;
    } catch (_) {
      return null;
    }
  }

  /// Chamado por quem observou uma falha de rede, para não esperar o timer.
  void informarFalhaDeRede() => unawaited(verificarAgora());

  Future<bool> verificarAgora() {
    return _verificando ??=
        _verificar().whenComplete(() => _verificando = null);
  }

  Future<bool> _verificar() async {
    var alcancavel = false;
    try {
      final rede = await (_redeAtual?.call() ?? _redeDoSistema());
      final semRede =
          rede.isNotEmpty && rede.every((r) => r == ConnectivityResult.none);
      alcancavel = !semRede && await _sonda();
    } catch (_) {
      alcancavel = await _sonda().catchError((Object _) => false);
    }
    _aplicar(alcancavel);
    return alcancavel;
  }

  Future<List<ConnectivityResult>> _redeDoSistema() async {
    try {
      return await Connectivity().checkConnectivity();
    } catch (_) {
      return const [ConnectivityResult.other];
    }
  }

  void _aplicar(bool alcancavel) {
    if (online.value != alcancavel) {
      online.value = alcancavel;
      ultimaMudanca.value = DateTime.now();
      debugPrint(alcancavel
          ? '[Conectividade] Conexão restabelecida.'
          : '[Conectividade] Sem conexão com o servidor.');
      if (!_transicoes.isClosed) _transicoes.add(alcancavel);
    }
    _agendar();
  }

  void _agendar() {
    _timer?.cancel();
    if (_transicoes.isClosed) return;
    _timer = Timer(
      online.value ? intervaloOnline : intervaloOffline,
      () => unawaited(verificarAgora()),
    );
  }

  @override
  void onClose() {
    _timer?.cancel();
    unawaited(_redeSub?.cancel());
    unawaited(_transicoes.close());
    super.onClose();
  }
}
