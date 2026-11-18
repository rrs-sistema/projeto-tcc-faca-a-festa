import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import 'package:app_faca_festa/domain/entities/territorio.dart';
import 'package:app_faca_festa/presentation/modules/admin/controllers/admin_territorio_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/pages/fornecedor/components/territorio_mapa_zoom.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';

Future<void> showAddTerritorioBottomSheet(
  BuildContext context,
  String idFornecedor, {
  required EventThemeController theme,
  required AdminTerritorioController controller,
  Territorio? existente,
}) async {
  await _abrirEditor(
    context,
    idFornecedor: idFornecedor,
    cor: theme.primaryColor.value,
    controller: controller,
    existente: existente,
    devolverCobertura: false,
  );
}

Future<Territorio?> editarCoberturaNoMapa(
  BuildContext context, {
  required Territorio territorio,
  required Color cor,
  required AdminTerritorioController controller,
}) =>
    _abrirEditor(
      context,
      idFornecedor: territorio.idFornecedor,
      cor: cor,
      controller: controller,
      existente: territorio,
      devolverCobertura: true,
    );

Future<Territorio?> _abrirEditor(
  BuildContext context, {
  required String idFornecedor,
  required Color cor,
  required AdminTerritorioController controller,
  required Territorio? existente,
  required bool devolverCobertura,
}) {
  return showModalBottomSheet<Territorio>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (_) => _EditorTerritorio(
      idFornecedor: idFornecedor,
      cor: cor,
      controller: controller,
      existente: existente,
      devolverCobertura: devolverCobertura,
    ),
  );
}

class _EditorTerritorio extends StatefulWidget {
  const _EditorTerritorio({
    required this.idFornecedor,
    required this.cor,
    required this.controller,
    required this.devolverCobertura,
    this.existente,
  });

  final String idFornecedor;
  final Color cor;
  final AdminTerritorioController controller;
  final Territorio? existente;
  final bool devolverCobertura;

  @override
  State<_EditorTerritorio> createState() => _EditorTerritorioState();
}

class _EditorTerritorioState extends State<_EditorTerritorio> {
  static const _curitiba = LatLng(-25.4284, -49.2733);
  static const _distancia = Distance();
  final _mapa = MapController();
  final _vertices = <LatLng>[];
  LatLng? _centro;
  late final LatLng _centroInicial;
  late final CameraFit? _enquadramentoInicial;
  late final double _raioMinimo;
  late final double _raioMaximo;
  late double _raio;
  late bool _porRaio;
  bool _desenhando = false;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    final existente = widget.existente;
    _porRaio = existente?.tipoCobertura != 'regiao';
    final raio = existente?.raioKm ?? 10.0;
    _raio = raio.isFinite && raio > 0 ? raio : 10;
    _raioMinimo = math.min(1.0, _raio);
    _raioMaximo = math.max(100.0, _raio);
    _centro = _coordenada(existente?.latitude, existente?.longitude);
    for (final vertice in existente?.regioes ?? const <String>[]) {
      final partes = vertice.split(',');
      if (partes.length != 2) continue;
      final ponto = _coordenada(
        double.tryParse(partes.first.trim()),
        double.tryParse(partes.last.trim()),
      );
      if (ponto != null) _vertices.add(ponto);
    }
    _centroInicial =
        (!_porRaio && _vertices.isNotEmpty ? _vertices.first : _centro) ??
            _curitiba;
    _enquadramentoInicial = _enquadramento();
  }

  LatLng? _coordenada(double? latitude, double? longitude) {
    if (latitude == null ||
        longitude == null ||
        !latitude.isFinite ||
        !longitude.isFinite ||
        latitude.abs() > 90 ||
        longitude.abs() > 180) {
      return null;
    }
    return LatLng(latitude, longitude);
  }

  CameraFit? _enquadramento() {
    final centro = _centro;
    final contorno = _porRaio
        ? [
            if (centro != null)
              for (final direcao in [0.0, 90.0, 180.0, 270.0])
                _distancia.offset(centro, _raio * 1000, direcao),
          ]
        : _vertices;
    if (contorno.isEmpty) return null;
    return CameraFit.bounds(
      bounds: LatLngBounds.fromPoints(contorno),
      padding: EdgeInsets.fromLTRB(32, _porRaio ? 138 : 104, 32, 86),
      maxZoom: 15,
    );
  }

  void _enquadrarCobertura() {
    final enquadramento = _enquadramento();
    if (enquadramento != null) _mapa.fitCamera(enquadramento);
  }

  void _marcarPonto(LatLng ponto) {
    if (_salvando) return;
    if (_porRaio) {
      setState(() => _centro = ponto);
      _enquadrarCobertura();
    } else if (_desenhando && !_vertices.contains(ponto)) {
      setState(() => _vertices.add(ponto));
    }
  }

  void _alternarModo() {
    setState(() {
      _porRaio = !_porRaio;
      _desenhando = !_porRaio && _vertices.isEmpty;
      _erro = null;
    });
    _enquadrarCobertura();
  }

  void _limparPontos() {
    setState(() {
      if (_porRaio) {
        _centro = null;
      } else {
        _vertices.clear();
        _desenhando = true;
      }
      _erro = null;
    });
  }

  Future<void> _centralizarNaLocalizacao() async {
    try {
      final local = await Geolocator.getCurrentPosition();
      if (mounted && !_salvando) {
        _mapa.move(LatLng(local.latitude, local.longitude), 13);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _erro = 'Não foi possível obter sua localização.');
      }
    }
  }

  bool get _podeSalvar =>
      !_salvando && (_porRaio ? _centro != null : _vertices.length >= 3);

  Future<void> _salvar() async {
    if (!_podeSalvar) return;
    final existente = widget.existente;
    final agora = DateTime.now();
    final descricao = existente?.descricao;
    final territorio = Territorio(
      idTerritorio: existente?.idTerritorio ?? const Uuid().v4(),
      idFornecedor: widget.idFornecedor,
      ativo: existente?.ativo ?? true,
      descricao: descricao == null || descricao.isEmpty
          ? 'Território ${agora.day}/${agora.month}'
          : descricao,
      tipoCobertura: _porRaio ? 'raio' : 'regiao',
      raioKm: _porRaio ? _raio : null,
      latitude: _porRaio ? _centro!.latitude : null,
      longitude: _porRaio ? _centro!.longitude : null,
      regioes: _porRaio
          ? null
          : _vertices.map((p) => '${p.latitude},${p.longitude}').toList(),
    );
    if (widget.devolverCobertura) {
      Navigator.of(context).pop(territorio);
      return;
    }
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      await widget.controller.salvarTerritorio(territorio);
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _salvando = false;
          _erro = 'Não foi possível salvar o território. Tente novamente.';
        });
      }
    }
  }

  @override
  void dispose() {
    _mapa.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cor = widget.cor;
    final centro = _centro;
    return PopScope(
      canPop: !_salvando,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              FlutterMap(
                mapController: _mapa,
                options: MapOptions(
                  initialCenter: _centroInicial,
                  initialZoom: 11,
                  minZoom: 0,
                  maxZoom: 19,
                  initialCameraFit: _enquadramentoInicial,
                  onTap: (_, ponto) => _marcarPonto(ponto),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'app_faca_festa',
                  ),
                  Obx(() => CircleLayer(
                        circles: [
                          for (final territorio
                              in widget.controller.territorios)
                            if (territorio.idTerritorio !=
                                    widget.existente?.idTerritorio &&
                                territorio.tipoCobertura == 'raio' &&
                                territorio.latitude != null &&
                                territorio.longitude != null)
                              CircleMarker(
                                point: LatLng(territorio.latitude!,
                                    territorio.longitude!),
                                radius: (territorio.raioKm ?? 10) * 1000,
                                color: cor.withValues(alpha: 0.10),
                                borderColor: cor.withValues(alpha: 0.34),
                                borderStrokeWidth: 1.5,
                                useRadiusInMeter: true,
                              ),
                        ],
                      )),
                  if (_porRaio && centro != null)
                    CircleLayer(
                      key: const ValueKey('raioEmEdicao'),
                      circles: [
                        CircleMarker(
                          point: centro,
                          radius: _raio * 1000,
                          color: cor.withValues(alpha: 0.20),
                          borderColor: cor,
                          borderStrokeWidth: 3,
                          useRadiusInMeter: true,
                        ),
                      ],
                    ),
                  if (!_porRaio && _vertices.length == 2)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                            points: [..._vertices], color: cor, strokeWidth: 3),
                      ],
                    ),
                  if (!_porRaio && _vertices.length >= 3)
                    PolygonLayer(
                      polygons: [
                        Polygon(
                          points: [..._vertices],
                          color: cor.withValues(alpha: 0.20),
                          borderColor: cor,
                          borderStrokeWidth: 3,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      if (_porRaio && centro != null)
                        Marker(
                          point: centro,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_on,
                              color: Colors.redAccent, size: 34),
                        ),
                      if (!_porRaio)
                        for (final ponto in _vertices)
                          Marker(
                            point: ponto,
                            width: 14,
                            height: 14,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: cor,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                    ],
                  ),
                  Positioned(
                    left: 12,
                    bottom: 106,
                    child: TerritorioMapaZoom(cor: cor),
                  ),
                ],
              ),
              Positioned(top: 16, left: 16, right: 16, child: _cabecalho()),
              Positioned(right: 12, bottom: 98, child: _acoesDoMapa()),
              Positioned(bottom: 10, left: 10, right: 10, child: _rodape()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cabecalho() {
    final acao = widget.existente == null ? 'Novo' : 'Editar';
    final modo = _porRaio ? 'Raio' : 'Região';
    final titulo = widget.devolverCobertura
        ? 'Cobertura no mapa ($modo)'
        : '$acao Território ($modo)';
    return _painel(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(titulo,
              style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: widget.cor)),
          if (_porRaio) ...[
            Text('Raio de ${_raio.toStringAsFixed(1)} km'),
            Slider(
              value: _raio,
              min: _raioMinimo,
              max: _raioMaximo,
              divisions: (_raioMaximo - _raioMinimo).ceil(),
              activeColor: widget.cor,
              label: '${_raio.toStringAsFixed(1)} km',
              onChanged:
                  _salvando ? null : (valor) => setState(() => _raio = valor),
              onChangeEnd: (_) => _enquadrarCobertura(),
            ),
            if (_centro == null)
              const Text('Clique no mapa para marcar o centro.'),
          ] else
            Text(
              _desenhando
                  ? 'Pontos marcados: ${_vertices.length}. Marque ao menos 3 no mapa.'
                  : 'Use Desenhar região para acrescentar pontos.',
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _acoesDoMapa() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _botaoMapa(Icons.gps_fixed, 'Centralizar', _centralizarNaLocalizacao),
        _botaoMapa(
          _porRaio ? Icons.polyline_outlined : Icons.radio_button_checked,
          _porRaio ? 'Editar por região' : 'Editar por raio',
          _alternarModo,
        ),
        if (!_porRaio)
          _botaoMapa(
            _desenhando ? Icons.check : Icons.brush,
            _desenhando ? 'Finalizar desenho' : 'Desenhar região',
            () {
              setState(() => _desenhando = !_desenhando);
              if (!_desenhando) _enquadrarCobertura();
            },
            ativo: _desenhando,
          ),
        _botaoMapa(Icons.delete_outline, 'Limpar pontos', _limparPontos),
      ],
    );
  }

  Widget _botaoMapa(IconData icone, String dica, VoidCallback acao,
      {bool ativo = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FloatingActionButton.small(
        heroTag: null,
        tooltip: dica,
        backgroundColor: ativo ? widget.cor : Colors.white,
        foregroundColor: ativo ? Colors.white : widget.cor,
        onPressed: _salvando ? null : acao,
        child: Icon(icone),
      ),
    );
  }

  Widget _rodape() {
    return _painel(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_erro case final String erro)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Semantics(liveRegion: true, child: Text(erro)),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _salvando ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _podeSalvar ? _salvar : null,
                  style: FilledButton.styleFrom(backgroundColor: widget.cor),
                  icon: const Icon(Icons.save),
                  label: Text(_salvando
                      ? 'Salvando…'
                      : widget.devolverCobertura
                          ? 'Usar cobertura'
                          : widget.existente == null
                              ? 'Salvar'
                              : 'Atualizar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _painel(Widget filho) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white.withValues(alpha: 0.92),
          child: filho,
        ),
      ),
    );
  }
}
