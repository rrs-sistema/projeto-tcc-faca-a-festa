import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/domain/entities/uf_cidade.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_ufs_cidades.dart';

class UFCidadeController extends GetxController {
  UFCidadeController({required GerenciarUfsCidades ufsCidades})
      : _ufsCidades = ufsCidades;

  final GerenciarUfsCidades _ufsCidades;

  final estados = <Estado>[].obs;
  final cidades = <Cidade>[].obs;

  final estadoSelecionado = Rxn<Estado>();
  final cidadeSelecionada = Rxn<Cidade>();

  final carregando = false.obs;

  Future<void> inicializar() async {
    await carregarEstados();
  }

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

  Future<void> selecionarEstado(Estado estado) async {
    estadoSelecionado.value = estado;
    cidadeSelecionada.value = null;
    await carregarCidades(estado.id);
  }

  void selecionarCidade(Cidade cidade) {
    cidadeSelecionada.value = cidade;
  }

  int? get idCidadeSelecionada => cidadeSelecionada.value?.idCidade;

  void limpar() {
    cidades.clear();
    estadoSelecionado.value = null;
    cidadeSelecionada.value = null;
    carregando.value = false;
  }
}
