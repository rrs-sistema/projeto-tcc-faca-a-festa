import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'conectividade_service.dart';
import 'erro_de_rede.dart';
import 'estado_sincronizacao.dart';

/// A falha veio da falta de internet (e não de uma recusa do servidor).
bool falhaDeConexao(Object erro) =>
    ConectividadeService.offlineAgora || erroDeRede(erro);

/// Texto de tela para o que depende do servidor enquanto não há internet.
String semInternetPara(String oQue) =>
    'Sem internet. $oQue quando a conexão voltar.';

/// Emite quando a internet volta e o servidor já recebeu a fila do aparelho.
///
/// Sem confirmação da fila em [espera], emite assim mesmo: uma escrita presa
/// não pode impedir as telas de buscar os dados novos.
Stream<void> sinalDeReconexao({
  Duration espera = const Duration(seconds: 8),
}) {
  final conectividade = ConectividadeService.instancia;
  if (conectividade == null) return const Stream<void>.empty();
  late StreamController<void> controller;
  StreamSubscription<void>? reconexao;
  StreamSubscription<void>? fila;
  Timer? limite;

  void emitir() {
    limite?.cancel();
    limite = null;
    if (!controller.isClosed) controller.add(null);
  }

  controller = StreamController<void>.broadcast(
    onListen: () {
      reconexao = conectividade.aoReconectar.listen((_) {
        limite?.cancel();
        limite = Timer(espera, emitir);
      });
      fila = EstadoSincronizacao.instancia?.filaEnviada.listen((_) {
        if (limite != null) emitir();
      });
    },
    onCancel: () async {
      limite?.cancel();
      await reconexao?.cancel();
      await fila?.cancel();
    },
  );
  return controller.stream;
}

/// Para telas que guardam a consulta no próprio [State] (`FutureBuilder`).
///
/// Passe a consulta por [acompanharConsulta]; se ela falhar, a tela chama
/// [recarregarAoReconectar] quando a internet voltar.
mixin RecarregarConsultaAoReconectar<T extends StatefulWidget> on State<T> {
  StreamSubscription<void>? _reconexaoConsulta;
  bool _consultaFalhou = false;

  void recarregarAoReconectar();

  Future<R> acompanharConsulta<R>(Future<R> consulta) {
    _consultaFalhou = false;
    _reconexaoConsulta ??= sinalDeReconexao().listen((_) {
      if (mounted && _consultaFalhou) recarregarAoReconectar();
    });
    consulta.then<void>((_) {}, onError: (Object _) {
      _consultaFalhou = true;
    });
    return consulta;
  }

  @override
  void dispose() {
    unawaited(_reconexaoConsulta?.cancel());
    super.dispose();
  }
}

/// Repete as cargas da tela quando a internet volta.
///
/// Leituras feitas sem internet vêm do cache (às vezes vazio ou antigo) e
/// chamadas ao servidor falham; sem repetir, a lista fica assim até o
/// usuário sair e voltar à tela.
mixin RecarregarAoReconectar on GetLifeCycleBase {
  final _cargas = <String, Future<void> Function()>{};
  final _umaVez = <String>{};
  StreamSubscription<void>? _reconexao;
  bool _repetindo = false;

  /// Guarda [carga] para repetir a cada reconexão (a última vence por [chave]).
  ///
  /// Com [quando], só repete se ainda fizer sentido (ex.: a tela ficou com
  /// erro ou sem dados), para não descartar o que o usuário está editando.
  void repetirAoReconectar(
    String chave,
    Future<void> Function() carga, {
    bool Function()? quando,
  }) {
    _cargas[chave] = quando == null
        ? carga
        : () async {
            if (quando()) await carga();
          };
    _umaVez.remove(chave);
    _escutar();
  }

  /// Para escutas que morreram com erro: refaz só na próxima reconexão.
  void refazerAoReconectar(String chave, FutureOr<void> Function() carga) {
    _cargas[chave] = () async => carga();
    _umaVez.add(chave);
    _escutar();
  }

  void esquecerRecarga(String chave) {
    _cargas.remove(chave);
    _umaVez.remove(chave);
  }

  /// Quanto esperar a fila de escritas antes de buscar os dados novos.
  @protected
  Duration get esperaFilaAoReconectar => const Duration(seconds: 8);

  void _escutar() {
    _reconexao ??= sinalDeReconexao(espera: esperaFilaAoReconectar)
        .listen((_) => unawaited(_repetir()));
  }

  Future<void> _repetir() async {
    if (_repetindo || isClosed) return;
    _repetindo = true;
    try {
      final cargas = Map.of(_cargas);
      for (final chave in _umaVez) {
        _cargas.remove(chave);
      }
      _umaVez.clear();
      for (final entrada in cargas.entries) {
        if (isClosed) return;
        try {
          await entrada.value();
        } catch (e) {
          debugPrint('[Reconexao] ${entrada.key}: $e');
        }
      }
    } finally {
      _repetindo = false;
    }
  }

  @override
  void onClose() {
    unawaited(_reconexao?.cancel());
    _reconexao = null;
    _cargas.clear();
    _umaVez.clear();
    super.onClose();
  }
}
