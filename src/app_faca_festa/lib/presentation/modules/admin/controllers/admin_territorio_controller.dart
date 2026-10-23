import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import 'package:app_faca_festa/domain/entities/territorio.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_admin_territorios.dart';

enum FiltroStatusTerritorio { todos, ativos, inativos }

class AdminTerritorioController extends GetxController {
  AdminTerritorioController({
    required GerenciarAdminTerritorios territoriosAdmin,
  }) : _territoriosAdmin = territoriosAdmin;

  final GerenciarAdminTerritorios _territoriosAdmin;

  final mapController = MapController();
  final buscaCtrl = TextEditingController();
  final territorios = <Territorio>[].obs;
  final idTerritorioSelecionado = RxnString();
  final busca = ''.obs;
  final filtroStatus = FiltroStatusTerritorio.todos.obs;

  static const LatLng centroBrasil = LatLng(-15.78, -47.93);

  List<Territorio> get territoriosFiltrados {
    final q = busca.value.trim().toLowerCase();
    final status = filtroStatus.value;

    return territorios.where((t) {
      if (status == FiltroStatusTerritorio.ativos && !t.ativo) return false;
      if (status == FiltroStatusTerritorio.inativos && t.ativo) return false;
      if (q.isEmpty) return true;

      final desc = (t.descricao ?? '').toLowerCase();
      final idForn = t.idFornecedor.toLowerCase();
      final tipo = (t.tipoCobertura ?? '').toLowerCase();
      return desc.contains(q) || idForn.contains(q) || tipo.contains(q);
    }).toList();
  }

  Territorio? get territorioSelecionado {
    final id = idTerritorioSelecionado.value;
    if (id == null) return null;
    return territorios.firstWhereOrNull((t) => t.idTerritorio == id);
  }

  int get totalAtivos => territorios.where((t) => t.ativo).length;

  Future<void> carregarTerritorios({bool ajustarMapa = true}) async {
    try {
      territorios.value = await _territoriosAdmin.listarTerritorios();
      final selecionado = idTerritorioSelecionado.value;
      if (selecionado != null &&
          !territorios.any((t) => t.idTerritorio == selecionado)) {
        idTerritorioSelecionado.value = null;
      }
      if (ajustarMapa) {
        _agendarAjusteMapa(() {
          if (idTerritorioSelecionado.value != null) {
            ajustarMapaParaSelecionado();
          } else {
            ajustarMapaParaTerritorios();
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar territórios: $e');
    }
  }

  void atualizarBusca(String value) => busca.value = value;

  void limparBusca() {
    buscaCtrl.clear();
    busca.value = '';
  }

  void definirFiltroStatus(FiltroStatusTerritorio status) {
    filtroStatus.value = status;
  }

  void selecionarTerritorio(Territorio? t) {
    idTerritorioSelecionado.value = t?.idTerritorio;
    if (t == null) {
      ajustarMapaParaTerritorios();
      return;
    }
    ajustarMapaParaSelecionado();
  }

  void verTodos() {
    idTerritorioSelecionado.value = null;
    ajustarMapaParaTerritorios();
  }

  void ajustarMapaParaTerritorios() {
    final pontos = <LatLng>[];
    for (final t in territorios.where((t) => t.ativo)) {
      pontos.addAll(_pontosDeCobertura(t));
    }
    _aplicarFit(pontos);
  }

  void ajustarMapaParaSelecionado() {
    final t = territorioSelecionado;
    if (t == null) {
      ajustarMapaParaTerritorios();
      return;
    }
    _aplicarFit(_pontosDeCobertura(t), maxZoom: 12);
  }

  List<LatLng> _pontosDeCobertura(Territorio t) {
    final pontos = <LatLng>[];

    if (t.tipoCobertura == 'regiao' &&
        t.regioes != null &&
        t.regioes!.isNotEmpty) {
      for (final r in t.regioes!) {
        final parts = r.split(',');
        if (parts.length < 2) continue;
        final lat = double.tryParse(parts[0].trim());
        final lng = double.tryParse(parts[1].trim());
        if (lat == null || lng == null) continue;
        pontos.add(LatLng(lat, lng));
      }
      return pontos;
    }

    if (t.latitude == null || t.longitude == null) return pontos;

    final centro = LatLng(t.latitude!, t.longitude!);
    final raioKm = (t.raioKm ?? 10).clamp(1, 500).toDouble();
    final dLat = raioKm / 111.0;
    final cosLat = math.cos(centro.latitude * math.pi / 180).abs();
    final dLng = cosLat < 0.01 ? raioKm / 111.0 : raioKm / (111.0 * cosLat);

    pontos.addAll([
      centro,
      LatLng(centro.latitude + dLat, centro.longitude),
      LatLng(centro.latitude - dLat, centro.longitude),
      LatLng(centro.latitude, centro.longitude + dLng),
      LatLng(centro.latitude, centro.longitude - dLng),
    ]);
    return pontos;
  }

  void _aplicarFit(List<LatLng> pontos, {double? maxZoom}) {
    if (Get.testMode) return;

    void aplicar() {
      if (pontos.isEmpty) {
        mapController.move(centroBrasil, 4.3);
        return;
      }
      if (pontos.length == 1) {
        mapController.move(pontos.first, maxZoom ?? 10);
        return;
      }
      mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(pontos),
          padding: const EdgeInsets.all(48),
          maxZoom: maxZoom ?? 11,
        ),
      );
    }

    try {
      aplicar();
    } catch (_) {
      // Mapa ainda não montado — tenta no próximo frame.
      _agendarAjusteMapa(() {
        try {
          aplicar();
        } catch (_) {}
      });
    }
  }

  void _agendarAjusteMapa(VoidCallback acao) {
    if (Get.testMode) return;
    try {
      WidgetsBinding.instance.addPostFrameCallback((_) => acao());
    } catch (_) {}
  }

  /// Filtra por texto considerando também o nome do fornecedor (resolvido na UI).
  bool correspondeBusca(Territorio t, String nomeFornecedor) {
    final q = busca.value.trim().toLowerCase();
    if (q.isEmpty) return true;
    return (t.descricao ?? '').toLowerCase().contains(q) ||
        t.idFornecedor.toLowerCase().contains(q) ||
        (t.tipoCobertura ?? '').toLowerCase().contains(q) ||
        nomeFornecedor.toLowerCase().contains(q);
  }

  List<Territorio> filtrarComNomes(String Function(String id) nomeFornecedor) {
    final status = filtroStatus.value;
    return territorios.where((t) {
      if (status == FiltroStatusTerritorio.ativos && !t.ativo) return false;
      if (status == FiltroStatusTerritorio.inativos && t.ativo) return false;
      return correspondeBusca(t, nomeFornecedor(t.idFornecedor));
    }).toList();
  }

  Future<void> toggleAtivo(Territorio t, bool ativo) async {
    await _territoriosAdmin.atualizarAtivo(t.idTerritorio, ativo);
    _mostrarSnackbar(
      ativo ? 'Ativado' : 'Desativado',
      'Território ${t.descricao ?? ''}',
      backgroundColor: ativo ? Colors.green : Colors.redAccent,
      colorText: Colors.white,
    );
    await carregarTerritorios(ajustarMapa: false);
  }

  Future<void> salvarTerritorio(Territorio t) async {
    await _territoriosAdmin.salvarTerritorio(t);
    idTerritorioSelecionado.value = t.idTerritorio;
    await carregarTerritorios();
    _mostrarSnackbar(
      'Sucesso',
      'Território salvo com sucesso!',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _mostrarSnackbar(
    String titulo,
    String mensagem, {
    Color? backgroundColor,
    Color? colorText,
    SnackPosition? snackPosition,
  }) {
    if (Get.testMode) return;
    if (Get.context == null && Get.overlayContext == null) return;

    Get.snackbar(
      titulo,
      mensagem,
      backgroundColor: backgroundColor,
      colorText: colorText,
      snackPosition: snackPosition,
    );
  }

  @override
  void onClose() {
    buscaCtrl.dispose();
    mapController.dispose();
    super.onClose();
  }
}
