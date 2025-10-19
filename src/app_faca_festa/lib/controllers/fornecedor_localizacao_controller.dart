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
      // 🔹 1️⃣ Faz consultas em paralelo com Future.wait
      final results = await Future.wait([
        db.collection('categoria_servico').where('ativo', isEqualTo: true).get(),
        db.collection('fornecedor').where('ativo', isEqualTo: true).get(),
        db.collection('fornecedor_categoria').get(),
        db.collection('territorio').get(),
      ]);

      final queryCategorias = results[0];
      final queryFornecedores = results[1];
      final queryRelacoes = results[2];
      final queryTerritorios = results[3];

      // 🔹 2️⃣ Converte listas
      final listaCategorias = queryCategorias.docs
          .map((d) => CategoriaServicoModel.fromMap({'id': d.id, ...d.data()}))
          .toList();

      final listaFornecedores = queryFornecedores.docs
          .map((d) => FornecedorModel.fromMap({...d.data(), 'id_fornecedor': d.id}))
          .toList();

      final relacoes =
          queryRelacoes.docs.map((d) => FornecedorCategoriaModel.fromMap(d.data())).toList();

      final territorios =
          queryTerritorios.docs.map((d) => TerritorioModel.fromMap(d.data())).toList();

      categorias.assignAll(listaCategorias);

      // 🔹 3️⃣ Usa Map para busca instantânea (O(1))
      final relacaoPorFornecedor = {
        for (var r in relacoes) r.idFornecedor: r,
      };
      final categoriaPorId = {
        for (var c in listaCategorias) c.id: c.nome,
      };
      final territorioPorFornecedor = {
        for (var t in territorios) t.idFornecedor: t,
      };

      // 🔹 4️⃣ Monta lista detalhada (sem travar a UI)
      final List<FornecedorDetalhadoModel> listaDetalhada = [];

      for (final f in listaFornecedores) {
        final relacao = relacaoPorFornecedor[f.idFornecedor];
        final categoriaNome = categoriaPorId[relacao?.idCategoria] ?? 'Outros';
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
            categoriaNome: categoriaNome,
            territorio: territorio,
            distanciaKm: distanciaKm,
          ),
        );
      }

      fornecedores.assignAll(listaDetalhada);

      // 🔹 5️⃣ Filtra e atualiza interface após microdelay
      await Future.delayed(const Duration(milliseconds: 100));
      _filtrarPorRaio();

      if (kDebugMode) {
        print('✅ ${fornecedores.length} fornecedores carregados');
      }
    } catch (e, s) {
      if (kDebugMode) print('❌ Erro ao carregar fornecedores: $e\n$s');
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

      if (distancia == null) return true;
      final limite = min(raioGlobal, raioFornecedor);
      return distancia <= limite;
    }).toList();

    if (kDebugMode) {
      print('📍 ${fornecedoresFiltrados.length} fornecedores dentro do raio ($raioGlobal km)');
    }
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
    return fornecedoresFiltrados
        .where((f) => f.categoriaNome.toLowerCase() == nomeCategoria.toLowerCase())
        .toList();
  }
}
