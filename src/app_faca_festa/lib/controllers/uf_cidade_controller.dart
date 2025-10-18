import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UFCidadeController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Listas reativas
  var estados = <Map<String, dynamic>>[].obs;
  var cidades = <Map<String, dynamic>>[].obs;

  /// Estado e cidade selecionados
  var estadoSelecionado = Rxn<Map<String, dynamic>>();
  var cidadeSelecionada = Rxn<Map<String, dynamic>>();

  /// Indicador de carregamento
  var carregando = false.obs;

  Future<void> inicializar() async {
    await carregarEstados();
  }

  /// 🔹 Carrega todos os estados disponíveis
  Future<void> carregarEstados() async {
    try {
      carregando.value = true;
      final snapshot = await _db.collection('estado').orderBy('nome').get();
      estados.value = snapshot.docs.map((d) {
        final data = d.data();
        return {
          'id': d.id,
          'nome': data['nome'],
          'uf': data['uf'],
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao carregar estados: $e');
      }
    } finally {
      carregando.value = false;
    }
  }

  /// 🔹 Carrega as cidades de um estado selecionado
  Future<void> carregarCidades(String idEstado) async {
    try {
      carregando.value = true;
      final snapshot =
          await _db.collection('estado').doc(idEstado).collection('cidades').orderBy('nome').get();

      cidades.value = snapshot.docs.map((d) {
        final data = d.data();
        return {
          'id': d.id,
          'nome': data['nome'],
          'uf': data['uf'],
          'id_cidade': data['id_cidade'],
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao carregar cidades: $e');
      }
      cidades.clear();
    } finally {
      carregando.value = false;
    }
  }

  /// 🔹 Define o estado selecionado e busca cidades
  Future<void> selecionarEstado(Map<String, dynamic> estado) async {
    estadoSelecionado.value = estado;
    cidadeSelecionada.value = null;
    await carregarCidades(estado['id']);
  }

  /// 🔹 Define a cidade selecionada
  void selecionarCidade(Map<String, dynamic> cidade) {
    cidadeSelecionada.value = cidade;
  }

  /// 🔹 Retorna o ID da cidade selecionada
  int? get idCidadeSelecionada {
    final cidade = cidadeSelecionada.value;
    if (cidade == null) return null;

    final id = cidade['id_cidade'];
    if (id == null) return null;

    if (id is int) return id;

    return int.tryParse(id.toString());
  }
}
