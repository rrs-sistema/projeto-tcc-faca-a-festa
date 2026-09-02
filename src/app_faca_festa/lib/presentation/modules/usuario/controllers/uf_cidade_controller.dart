import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/domain/usecases/gerenciar_ufs_cidades.dart';

class UFCidadeController extends GetxController {
  UFCidadeController({required GerenciarUfsCidades ufsCidades})
      : _ufsCidades = ufsCidades;

  final GerenciarUfsCidades _ufsCidades;

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
      estados.value = await _ufsCidades.carregarEstados();
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
      cidades.value = await _ufsCidades.carregarCidades(idEstado);
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

  void limpar() {
    // 🔹 Limpa as listas de estados e cidades carregadas
    cidades.clear();
    // Mantém a lista de estados (já carregada na inicialização)
    // mas você pode limpar também se quiser reiniciar totalmente:
    // estados.clear();

    // 🔹 Reseta seleções reativas
    estadoSelecionado.value = null;
    cidadeSelecionada.value = null;

    // 🔹 Garante estado visual limpo
    carregando.value = false;
  }
}
