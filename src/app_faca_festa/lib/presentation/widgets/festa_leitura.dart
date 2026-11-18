import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/accessibility/preferencias_leitura.dart';
import '../../core/accessibility/tipografia_festa.dart';

/// Pinça de texto nas áreas de conteúdo, preservando a rolagem com um dedo.
class FestaLeitura extends StatefulWidget {
  const FestaLeitura({super.key, required this.child});

  final Widget child;

  static bool pincando(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_EstadoPinca>()?.pincando ??
      false;

  static ScrollPhysics? physics(BuildContext context,
          [ScrollPhysics? normal]) =>
      pincando(context) ? const NeverScrollableScrollPhysics() : normal;

  @override
  State<FestaLeitura> createState() => _FestaLeituraState();
}

class _FestaLeituraState extends State<FestaLeitura> {
  final _toques = <int, Offset>{};
  final _excluidos = <int>{};
  int? _trackpad;
  bool _ampliandoNoTrackpad = false;
  double? _distanciaInicial;
  double _escalaInicial = 1;
  Timer? _indicadorTimer;
  bool _indicador = false;
  ScrollPosition? _rolagem;
  ScrollHoldController? _pausa;

  bool get _pincando => _toques.length >= 2 || _ampliandoNoTrackpad;

  void _iniciar(PointerDownEvent evento, PreferenciasLeitura preferencias) {
    if (evento.kind != PointerDeviceKind.touch) return;
    if (_trackpad != null) return;
    if (_excluidos.contains(evento.pointer)) return;
    if (_toques.length >= 2) return;
    _toques[evento.pointer] = evento.position;
    if (_toques.length != 2) return;
    final pontos = _toques.values.toList();
    _distanciaInicial = (pontos[0] - pontos[1]).distance;
    _escalaInicial = preferencias.escala;
    _pausarRolagem();
  }

  void _pausarRolagem() {
    _indicadorTimer?.cancel();
    final rolagem = _rolagem;
    if (rolagem?.context.notificationContext?.mounted == true) {
      _pausa = rolagem!.hold(() => _pausa = null);
    }
    setState(() => _indicador = true);
  }

  void _mover(PointerMoveEvent evento, PreferenciasLeitura preferencias) {
    if (!_toques.containsKey(evento.pointer)) return;
    _toques[evento.pointer] = evento.position;
    final distancia = _distanciaInicial;
    if (_toques.length != 2 || distancia == null || distancia < 10) return;
    final pontos = _toques.values.toList();
    preferencias
        .ajustar(_escalaInicial * (pontos[0] - pontos[1]).distance / distancia);
  }

  void _terminar(PointerEvent evento, PreferenciasLeitura preferencias) {
    _excluidos.remove(evento.pointer);
    final estavaPincando = _pincando;
    _toques.remove(evento.pointer);
    if (!estavaPincando || _pincando) return;
    _distanciaInicial = null;
    _concluir(preferencias);
  }

  void _concluir(PreferenciasLeitura preferencias) {
    _pausa?.cancel();
    _pausa = null;
    unawaited(preferencias.guardar());
    setState(() {});
    _indicadorTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _indicador = false);
    });
  }

  void _iniciarTrackpad(
      PointerPanZoomStartEvent evento, PreferenciasLeitura preferencias) {
    if (_toques.isNotEmpty || _trackpad != null) return;
    if (_excluidos.contains(evento.pointer)) return;
    _trackpad = evento.pointer;
    _escalaInicial = preferencias.escala;
  }

  void _moverTrackpad(
      PointerPanZoomUpdateEvent evento, PreferenciasLeitura preferencias) {
    if (_trackpad != evento.pointer) return;
    if (!_ampliandoNoTrackpad && (evento.scale - 1).abs() < .01) return;
    if (!_ampliandoNoTrackpad) {
      _ampliandoNoTrackpad = true;
      _pausarRolagem();
    }
    preferencias.ajustar(_escalaInicial * evento.scale);
  }

  void _terminarTrackpad(
      PointerPanZoomEndEvent evento, PreferenciasLeitura preferencias) {
    _excluidos.remove(evento.pointer);
    if (_trackpad != evento.pointer) return;
    _trackpad = null;
    if (!_ampliandoNoTrackpad) return;
    _ampliandoNoTrackpad = false;
    _concluir(preferencias);
  }

  @override
  void dispose() {
    _indicadorTimer?.cancel();
    _pausa?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A raiz cobre rotas, diálogos e painéis. Áreas já integradas não duplicam
    // o tratamento do mesmo gesto.
    if (context.dependOnInheritedWidgetOfExactType<_EstadoPinca>() != null) {
      return widget.child;
    }
    final preferencias = FestaLeituraScope.maybeOf(context);
    if (preferencias == null) return widget.child;
    return RawGestureDetector(
      gestures: {
        _ReconhecedorPincaTexto:
            GestureRecognizerFactoryWithHandlers<_ReconhecedorPincaTexto>(
          _ReconhecedorPincaTexto.new,
          (reconhecedor) {
            reconhecedor.capturar = () => _pincando;
            reconhecedor.permitir = (pointer) => !_excluidos.contains(pointer);
          },
        ),
      },
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (e) => _iniciar(e, preferencias),
        onPointerMove: (e) => _mover(e, preferencias),
        onPointerUp: (e) => _terminar(e, preferencias),
        onPointerCancel: (e) => _terminar(e, preferencias),
        onPointerPanZoomStart: (e) => _iniciarTrackpad(e, preferencias),
        onPointerPanZoomUpdate: (e) => _moverTrackpad(e, preferencias),
        onPointerPanZoomEnd: (e) => _terminarTrackpad(e, preferencias),
        child: _EstadoPinca(
          pincando: _pincando,
          excluir: _excluidos.add,
          liberar: _excluidos.remove,
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  final contexto = notification.context;
                  if (contexto != null) {
                    _rolagem = Scrollable.maybeOf(contexto)?.position;
                  }
                  return false;
                },
                child: widget.child,
              ),
              if (_indicador)
                Positioned(
                  top: MediaQuery.paddingOf(context).top + 8,
                  right: 8,
                  child: FestaTextoNavegacao(
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(24),
                      color: Theme.of(context).colorScheme.surface,
                      child: IgnorePointer(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          child: Text(
                              'Texto ${(preferencias.escala * 100).round()}%'),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EstadoPinca extends InheritedWidget {
  const _EstadoPinca({
    required this.pincando,
    required this.excluir,
    required this.liberar,
    required super.child,
  });

  final bool pincando;
  final void Function(int) excluir;
  final void Function(int) liberar;

  @override
  bool updateShouldNotify(_EstadoPinca oldWidget) =>
      oldWidget.pincando != pincando;
}

/// Mapas, fotos ampliáveis e enquadramentos mantêm seu gesto de escala.
class FestaGestosProprios extends StatelessWidget {
  const FestaGestosProprios({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final estado = context.dependOnInheritedWidgetOfExactType<_EstadoPinca>();
    if (estado == null) return child;
    return Listener(
      onPointerDown: (e) => estado.excluir(e.pointer),
      onPointerUp: (e) => estado.liberar(e.pointer),
      onPointerCancel: (e) => estado.liberar(e.pointer),
      onPointerPanZoomStart: (e) => estado.excluir(e.pointer),
      onPointerPanZoomEnd: (e) => estado.liberar(e.pointer),
      child: child,
    );
  }
}

/// Só disputa a arena quando há pinça, deixando arrastes e toques comuns
/// com os reconhecedores das listas, campos e botões.
class _ReconhecedorPincaTexto extends OneSequenceGestureRecognizer {
  _ReconhecedorPincaTexto()
      : super(supportedDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.trackpad,
        });

  bool Function()? capturar;
  bool Function(int)? permitir;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (permitir?.call(event.pointer) == false) return;
    startTrackingPointer(event.pointer, event.transform);
    if (capturar?.call() == true) resolve(GestureDisposition.accepted);
  }

  @override
  void addAllowedPointerPanZoom(PointerPanZoomStartEvent event) {
    if (permitir?.call(event.pointer) == false) return;
    startTrackingPointer(event.pointer, event.transform);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerPanZoomUpdateEvent && capturar?.call() == true) {
      resolve(GestureDisposition.accepted);
    }
    if (event is PointerUpEvent ||
        event is PointerCancelEvent ||
        event is PointerPanZoomEndEvent) {
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  void rejectGesture(int pointer) => stopTrackingPointer(pointer);

  @override
  void didStopTrackingLastPointer(int pointer) =>
      resolve(GestureDisposition.rejected);

  @override
  String get debugDescription => 'pinça de texto';
}
