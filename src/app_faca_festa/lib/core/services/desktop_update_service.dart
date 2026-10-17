import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

enum DesktopUpdateStatus {
  idle,
  checking,
  downloading,
  ready,
  installing,
  error
}

class DesktopUpdateState {
  const DesktopUpdateState(this.status,
      {this.version = '', this.build = 0, this.message = ''});
  final DesktopUpdateStatus status;
  final String version;
  final int build;
  final String message;
}

/// WinSparkle verifica a assinatura e entrega um pacote pronto; somente a ação
/// explícita do operador permite iniciar o helper de instalação.
class DesktopUpdateService {
  DesktopUpdateService({http.Client? client, MethodChannel? channel})
      : _client = client ?? http.Client(),
        _channel = channel ?? const MethodChannel('faca_festa/desktop_update');
  static final instance = DesktopUpdateService();
  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
  final http.Client _client;
  final MethodChannel _channel;
  final state =
      ValueNotifier(const DesktopUpdateState(DesktopUpdateStatus.idle));
  Timer? _timer;
  Timer? _downloadDeadline;
  int _installedBuild = 0;
  bool _initialized = false;
  bool _checking = false;
  final installedVersion = ValueNotifier('');
  bool _preparationFailed = false;

  void reportError(String message) {
    state.value =
        DesktopUpdateState(DesktopUpdateStatus.error, message: message);
  }

  Future<void> initialize({int? installedBuild}) async {
    if (_initialized) return;
    final info = installedBuild == null
        ? await _channel
            .invokeMapMethod<String, dynamic>('installedInfo')
            .timeout(const Duration(seconds: 10))
        : null;
    _installedBuild =
        installedBuild ?? int.tryParse(info?['build'].toString() ?? '') ?? 0;
    installedVersion.value =
        '${info?['version'] ?? ''} • build $_installedBuild';
    if (_installedBuild <= 0) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'ready') {
        _downloadDeadline?.cancel();
        final data = Map<String, dynamic>.from(call.arguments as Map);
        final build = (data['build'] as num).toInt();
        if (build <= _installedBuild) return;
        state.value = DesktopUpdateState(DesktopUpdateStatus.ready,
            version: data['version'].toString(), build: build);
      } else if (call.method == 'error') {
        _downloadDeadline?.cancel();
        state.value = const DesktopUpdateState(DesktopUpdateStatus.error,
            message:
                'Não foi possível baixar ou verificar a atualização. Tente novamente.');
      } else if (call.method == 'noUpdate') {
        state.value = const DesktopUpdateState(DesktopUpdateStatus.idle);
      }
    });
    await _channel
        .invokeMethod<void>('initialize')
        .timeout(const Duration(seconds: 10));
    _initialized = true;
    _timer =
        Timer.periodic(const Duration(hours: 1), (_) => unawaited(check()));
    await check();
  }

  Future<void> check() async {
    if (!_initialized ||
        _checking ||
        {
          DesktopUpdateStatus.downloading,
          DesktopUpdateStatus.ready,
          DesktopUpdateStatus.installing
        }.contains(state.value.status)) {
      return;
    }
    _checking = true;
    state.value = const DesktopUpdateState(DesktopUpdateStatus.checking);
    try {
      final response = await _client
          .get(Uri.parse(
              'https://faca-a-festa.web.app/desktop/updates/latest.json'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) throw StateError('Catálogo indisponível');
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final build = (data['build'] as num).toInt();
      if (data['identity'] != 'faca-festa-windows-x64' ||
          data['platform'] != 'windows-x64' ||
          build <= _installedBuild) {
        state.value = const DesktopUpdateState(DesktopUpdateStatus.idle);
        return;
      }
      state.value = DesktopUpdateState(DesktopUpdateStatus.downloading,
          version: data['version'].toString(), build: build);
      // URL e chave ficam no executável. O JSON não escolhe um instalador
      // arbitrário: WinSparkle consulta o appcast e verifica o pacote assinado.
      await _channel
          .invokeMethod<void>('download')
          .timeout(const Duration(seconds: 10));
      _downloadDeadline?.cancel();
      _downloadDeadline = Timer(const Duration(minutes: 10), () {
        if (state.value.status == DesktopUpdateStatus.downloading) {
          reportError(
              'O download excedeu o prazo. Verifique a conexão e tente novamente.');
        }
      });
    } catch (_) {
      state.value = const DesktopUpdateState(DesktopUpdateStatus.error,
          message:
              'Sem acesso às atualizações. O sistema pode continuar sendo usado.');
    } finally {
      _checking = false;
    }
  }

  Future<void> startInstall(
      {Future<void> Function()? prepare,
      Duration preparationTimeout = const Duration(seconds: 20)}) async {
    if (_preparationFailed) {
      throw StateError(
          'Feche e reabra o aplicativo antes de tentar novamente.');
    }
    if (state.value.status != DesktopUpdateStatus.ready) {
      throw StateError('Nenhuma atualização pronta.');
    }
    final ready = state.value;
    state.value = DesktopUpdateState(DesktopUpdateStatus.installing,
        version: ready.version, build: ready.build);
    try {
      // O helper só inicia depois que os dados locais foram salvos.
      if (prepare != null) await prepare().timeout(preparationTimeout);
      await _channel
          .invokeMethod<void>('install')
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      _preparationFailed = true;
      reportError(
          'Não foi possível preparar a atualização no prazo. Feche e reabra o aplicativo; nenhuma instalação foi iniciada.');
      rethrow;
    }
  }

  void dispose() {
    _timer?.cancel();
    _downloadDeadline?.cancel();
    _client.close();
    _channel.setMethodCallHandler(null);
  }
}
