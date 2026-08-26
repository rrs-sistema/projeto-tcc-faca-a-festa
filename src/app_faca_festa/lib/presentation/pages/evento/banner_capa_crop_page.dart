import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Proporção do banner da home (largura ÷ altura ≈ 16:9).
const double kBannerCapaAspectRatio = 16 / 9;

/// Saída final do crop: largura máxima em pixels.
const int kBannerCapaLarguraMax = 1600;

/// Tela para enquadrar a foto no formato do banner antes de enviar.
class BannerCapaCropPage extends StatefulWidget {
  const BannerCapaCropPage({
    super.key,
    required this.bytes,
    this.aspectRatio = kBannerCapaAspectRatio,
  });

  final Uint8List bytes;
  final double aspectRatio;

  static Future<Uint8List?> abrir(
    BuildContext context, {
    required Uint8List bytes,
    double aspectRatio = kBannerCapaAspectRatio,
  }) {
    return Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => BannerCapaCropPage(
          bytes: bytes,
          aspectRatio: aspectRatio,
        ),
      ),
    );
  }

  @override
  State<BannerCapaCropPage> createState() => _BannerCapaCropPageState();
}

class _BannerCapaCropPageState extends State<BannerCapaCropPage> {
  ui.Image? _imagem;
  String? _erro;

  double _scale = 1;
  double _baseScale = 1;
  Offset _offset = Offset.zero;
  Offset _baseOffset = Offset.zero;

  bool _exportando = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _imagem?.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.bytes);
      final frame = await codec.getNextFrame();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() {
        _imagem = frame.image;
        _erro = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _aplicarEnquadramentoInicial();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = 'Não foi possível abrir esta imagem.');
    }
  }

  /// Para fotos verticais, começa enquadrando o topo (rosto) no banner.
  void _aplicarEnquadramentoInicial() {
    final imagem = _imagem;
    if (imagem == null) return;
    final size = MediaQuery.sizeOf(context);
    final crop = _tamanhoCrop(size);
    if (crop.width <= 0 || crop.height <= 0) return;

    final imgW = imagem.width.toDouble();
    final imgH = imagem.height.toDouble();
    final cover = math.max(crop.width / imgW, crop.height / imgH);

    final displayW = imgW * cover;
    final displayH = imgH * cover;

    // Centro horizontal; vertical: prioriza o terço superior em fotos altas.
    var dx = (crop.width - displayW) / 2;
    var dy = (crop.height - displayH) / 2;
    if (imgH / imgW > 1.15) {
      dy = 0;
    }

    setState(() {
      _scale = 1;
      _baseScale = 1;
      _offset = Offset(dx, dy);
      _baseOffset = _offset;
      _limitarOffset(crop, _scale);
    });
  }

  Size _tamanhoCrop(Size tela) {
    final maxW = math.min(tela.width - 32, 520.0);
    final h = maxW / widget.aspectRatio;
    final maxH = tela.height * 0.48;
    if (h <= maxH) return Size(maxW, h);
    return Size(maxH * widget.aspectRatio, maxH);
  }

  void _limitarOffset(Size crop, double scale) {
    final imagem = _imagem;
    if (imagem == null) return;

    final cover = math.max(
      crop.width / imagem.width,
      crop.height / imagem.height,
    );
    final displayW = imagem.width * cover * scale;
    final displayH = imagem.height * cover * scale;

    final minX = crop.width - displayW;
    final minY = crop.height - displayH;

    _offset = Offset(
      _offset.dx.clamp(minX, 0.0),
      _offset.dy.clamp(minY, 0.0),
    );
  }

  Future<void> _confirmar() async {
    final imagem = _imagem;
    if (imagem == null || _exportando) return;

    setState(() => _exportando = true);
    try {
      final size = MediaQuery.sizeOf(context);
      final crop = _tamanhoCrop(size);
      final bytes = await _exportarRecorte(imagem, crop);
      if (!mounted) return;
      if (bytes == null || bytes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível gerar o banner.')),
        );
        return;
      }
      Navigator.of(context).pop(bytes);
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  Future<Uint8List?> _exportarRecorte(ui.Image imagem, Size cropView) async {
    final cover = math.max(
      cropView.width / imagem.width,
      cropView.height / imagem.height,
    );
    final displayScale = cover * _scale;

    // Retângulo visível no espaço da imagem original.
    var srcW = cropView.width / displayScale;
    var srcH = cropView.height / displayScale;
    srcW = srcW.clamp(1.0, imagem.width.toDouble());
    srcH = srcH.clamp(1.0, imagem.height.toDouble());

    var srcX = (-_offset.dx) / displayScale;
    var srcY = (-_offset.dy) / displayScale;
    srcX = srcX.clamp(0.0, imagem.width - srcW);
    srcY = srcY.clamp(0.0, imagem.height - srcH);

    final src = Rect.fromLTWH(srcX, srcY, srcW, srcH);

    final outW = kBannerCapaLarguraMax;
    (outW / widget.aspectRatio).round().clamp(1, 4000);

    Future<Uint8List?> gerar(int largura) async {
      final altura = (largura / widget.aspectRatio).round().clamp(1, 4000);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final dest = Rect.fromLTWH(0, 0, largura.toDouble(), altura.toDouble());
      canvas.drawImageRect(
        imagem,
        src,
        dest,
        Paint()..filterQuality = FilterQuality.high,
      );
      final picture = recorder.endRecording();
      final out = await picture.toImage(largura, altura);
      picture.dispose();
      final data = await out.toByteData(format: ui.ImageByteFormat.png);
      out.dispose();
      return data?.buffer.asUint8List();
    }

    var bytes = await gerar(outW);
    // PNG pode passar de 1,5 MB; reduz resolução até caber.
    for (final largura in [1400, 1200, 1000, 800]) {
      if (bytes == null || bytes.length <= 1_500_000) break;
      bytes = await gerar(largura);
    }
    return bytes;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final size = MediaQuery.sizeOf(context);
    final crop = _tamanhoCrop(size);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Enquadrar banner',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: _exportando || _imagem == null ? null : _confirmar,
            child: _exportando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Usar',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ],
      ),
      body: _erro != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _erro!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.white70),
                ),
              ),
            )
          : _imagem == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                      child: Text(
                        'Arraste e pinçe para enquadrar o rosto e o que importa. '
                        'A área clara é o que aparece no banner.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: SizedBox(
                          width: crop.width,
                          height: crop.height,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: GestureDetector(
                              onScaleStart: (details) {
                                _baseScale = _scale;
                                _baseOffset = _offset;
                              },
                              onScaleUpdate: (details) {
                                setState(() {
                                  _scale = (_baseScale * details.scale)
                                      .clamp(1.0, 4.0);
                                  _offset = _baseOffset + details.focalPointDelta;
                                  _limitarOffset(crop, _scale);
                                });
                              },
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ColoredBox(
                                    color: Colors.black,
                                    child: CustomPaint(
                                      painter: _BannerCapaPainter(
                                        image: _imagem!,
                                        scale: _scale,
                                        offset: _offset,
                                        cropSize: crop,
                                      ),
                                    ),
                                  ),
                                  IgnorePointer(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.35),
                                          width: 1.5,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        gradient: const LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Color(0x33000000),
                                            Color(0x00000000),
                                            Color(0x99000000),
                                          ],
                                          stops: [0, 0.45, 1],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const IgnorePointer(
                                    child: Align(
                                      alignment: Alignment(0, 0.55),
                                      child: Text(
                                        'Prévia do banner',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black54,
                                              blurRadius: 6,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.35),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: _exportando
                                    ? null
                                    : () => Navigator.of(context).pop(),
                                child: Text(
                                  'Cancelar',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: primary,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed:
                                    _exportando || _imagem == null ? null : _confirmar,
                                child: Text(
                                  'Usar neste banner',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _BannerCapaPainter extends CustomPainter {
  _BannerCapaPainter({
    required this.image,
    required this.scale,
    required this.offset,
    required this.cropSize,
  });

  final ui.Image image;
  final double scale;
  final Offset offset;
  final Size cropSize;

  @override
  void paint(Canvas canvas, Size size) {
    final cover = math.max(
      cropSize.width / image.width,
      cropSize.height / image.height,
    );
    final displayW = image.width * cover * scale;
    final displayH = image.height * cover * scale;
    final dest = Rect.fromLTWH(offset.dx, offset.dy, displayW, displayH);
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    canvas.drawImageRect(
      image,
      src,
      dest,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(covariant _BannerCapaPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.scale != scale ||
        oldDelegate.offset != offset ||
        oldDelegate.cropSize != cropSize;
  }
}
