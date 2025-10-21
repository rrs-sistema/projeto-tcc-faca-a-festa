import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'dart:math';

import './../data/models/servico_produto/fornecedor_categoria_model.dart';
import './../data/models/servico_produto/categoria_servico_model.dart';
import './../data/models/DTO/fornecedor_detalhado_model.dart';
import './../data/models/model.dart';

class FornecedorLocalizacaoController extends GetxController {
  final db = FirebaseFirestore.instance;

  // Estados reativos
  var userLatitude = 0.0.obs;
  var userLongitude = 0.0.obs;
  var raio = 10.0.obs;
  var avaliacaoMinima = 0.0.obs;
  var carregando = true.obs;
// Listas brutas (para reatividade)
  final _fornecedoresRaw = <FornecedorModel>[].obs;
  final _relacoesRaw = <FornecedorCategoriaModel>[].obs;
  final _territoriosRaw = <TerritorioModel>[].obs;

  // Listas principais
  var fornecedores = <FornecedorDetalhadoModel>[].obs;
  var fornecedoresFiltrados = <FornecedorDetalhadoModel>[].obs;
  var categorias = <CategoriaServicoModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _obterLocalizacaoUsuario();
  }

  // ==========================================================
  // === OBTÉM LOCALIZAÇÃO DO USUÁRIO
  // ==========================================================
  Future<void> _obterLocalizacaoUsuario() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      final permission = await Geolocator.checkPermission();

      if (!serviceEnabled ||
          permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        await carregarDados();
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      userLatitude.value = pos.latitude;
      userLongitude.value = pos.longitude;
      await carregarDados();
    } catch (e) {
      if (kDebugMode) print('❌ Erro ao obter localização: $e');
      await carregarDados();
    }
  }

  // ==========================================================
  // === CARGA PRINCIPAL: PARALELISMO E OTIMIZAÇÃO
  // ==========================================================
  Future<void> carregarDados() async {
    carregando.value = true;
    try {
      // Escuta categorias ativas
      db
          .collection('categoria_servico')
          .where('ativo', isEqualTo: true)
          .snapshots()
          .listen((snapshot) {
        categorias.assignAll(snapshot.docs.map((d) {
          return CategoriaServicoModel.fromMap({'id': d.id, ...d.data()});
        }).toList());
        _reconstruirLista();
      });

      // Escuta fornecedores
      db.collection('fornecedor').where('ativo', isEqualTo: true).snapshots().listen((snapshot) {
        final lista = snapshot.docs.map((d) {
          return FornecedorModel.fromMap({...d.data(), 'id_fornecedor': d.id});
        }).toList();
        _fornecedoresRaw.assignAll(lista);
        _reconstruirLista();
      });

      // Escuta relações fornecedor↔categoria
      db.collection('fornecedor_categoria').snapshots().listen((snapshot) {
        final lista = snapshot.docs.map((d) {
          return FornecedorCategoriaModel.fromMap(d.data());
        }).toList();
        _relacoesRaw.assignAll(lista);
        _reconstruirLista();
      });

      // Escuta territórios
      db.collection('territorio').snapshots().listen((snapshot) {
        final lista = snapshot.docs.map((d) {
          return TerritorioModel.fromMap(d.data());
        }).toList();
        _territoriosRaw.assignAll(lista);
        _reconstruirLista();
      });
    } catch (e, s) {
      if (kDebugMode) {
        print('❌ Erro na escuta reativa: $e - StackTrace $s');
      }
    } finally {
      carregando.value = false;
    }
  }

  // ==========================================================
  // === FILTRO POR RAIO DE DISTÂNCIA
  // ==========================================================
  void _filtrarPorRaio() {
    if (fornecedores.isEmpty) {
      fornecedoresFiltrados.clear();
      return;
    }

    final raioGlobal = raio.value;
    fornecedoresFiltrados.value = fornecedores.where((f) {
      final distancia = f.distanciaKm;
      final raioFornecedor = f.territorio?.raioKm ?? 999;

      // 🔹 Mantém fornecedor SEM coordenadas ou fora do raio, se tiver categoria válida
      if (f.categoriaNome.isNotEmpty && f.categoriaNome != 'Outros') {
        return true;
      }

      // 🔹 Mantém apenas se dentro do raio
      if (distancia == null) return true;
      final limite = min(raioGlobal, raioFornecedor);
      return distancia <= limite;
    }).toList();
  }

  // ==========================================================
  // === CÁLCULO DE DISTÂNCIA (Haversine)
  // ==========================================================
  double _calcularDistancia(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;
    final dLat = (lat2 - lat1) * (pi / 180);
    final dLon = (lon2 - lon1) * (pi / 180);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  // ==========================================================
  // === FUNÇÕES DE APOIO
  // ==========================================================
  void atualizarRaio(double novoRaio) {
    raio.value = novoRaio;
    _filtrarPorRaio();
  }

  List<FornecedorDetalhadoModel> fornecedoresPorCategoria(String nomeCategoria) {
    final termo = nomeCategoria.trim().toLowerCase();

    // 🔹 Filtra fornecedores dentro do raio E com categoria correspondente
    return fornecedoresFiltrados.where((f) {
      return f.categoriaNome.split(',').map((c) => c.trim().toLowerCase()).contains(termo);
    }).toList();
  }

  void _reconstruirLista() {
    if (_fornecedoresRaw.isEmpty || categorias.isEmpty) return;

    final relacoesPorFornecedor = <String, List<FornecedorCategoriaModel>>{};
    for (final r in _relacoesRaw) {
      relacoesPorFornecedor.putIfAbsent(r.idFornecedor, () => []).add(r);
    }

    final categoriaPorId = {for (var c in categorias) c.id: c.nome};
    final territorioPorFornecedor = {for (var t in _territoriosRaw) t.idFornecedor: t};

    final List<FornecedorDetalhadoModel> listaDetalhada = [];

    for (final f in _fornecedoresRaw) {
      final relacoesFornecedor = relacoesPorFornecedor[f.idFornecedor] ?? [];
      if (relacoesFornecedor.isEmpty) continue;

      final nomesCategorias = relacoesFornecedor
          .map((r) => categoriaPorId[r.idCategoria])
          .whereType<String>()
          .toSet()
          .join(', ');

      if (nomesCategorias.isEmpty) continue;

      final territorio = territorioPorFornecedor[f.idFornecedor];
      double? distanciaKm;
      if (territorio?.latitude != null && territorio?.longitude != null) {
        distanciaKm = _calcularDistancia(
          userLatitude.value,
          userLongitude.value,
          territorio!.latitude!,
          territorio.longitude!,
        );
      }

      listaDetalhada.add(
        FornecedorDetalhadoModel(
          fornecedor: f,
          categoriaNome: nomesCategorias,
          territorio: territorio,
          distanciaKm: distanciaKm,
        ),
      );
    }

    fornecedores.assignAll(listaDetalhada);
    _filtrarPorRaio();
  }
}
