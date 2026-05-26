import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/services/calculadora_festa_service.dart';
import '../data/models/cardapio/cardapio_item_model.dart';
import '../data/models/cardapio/cardapio_model.dart';
import '../data/models/evento/calculadora_festa_item_model.dart';
import '../data/models/evento/calculadora_festa_model.dart';
import './../data/models/model.dart';

class CalculadoraFestaController extends GetxController {
  final FirebaseFirestore _db;
  final CalculadoraFestaService _service;

  CalculadoraFestaController({
    FirebaseFirestore? firestore,
    CalculadoraFestaService? service,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _service = service ?? CalculadoraFestaService();

  static const String _collectionConvidado = 'convidado';
  static const String _collectionCalculadora = 'calculadora_festa';
  static const String _collectionCardapios = 'cardapios';

  final RxBool loading = false.obs;
  final RxBool salvando = false.obs;
  final RxBool enviandoParaCardapio = false.obs;

  final RxString idEventoAtual = ''.obs;
  final RxString tipoEventoAtual = ''.obs;
  final RxBool estimativaSemEvento = false.obs;

  final Rx<BaseCalculoFesta> baseCalculo = BaseCalculoFesta.todosConvidados.obs;

  final RxInt totalAdultos = 0.obs;
  final RxInt totalCriancas = 0.obs;
  final RxInt totalBebes = 0.obs;
  final RxInt duracaoHoras = 4.obs;

  final RxList<ConvidadoModel> convidados = <ConvidadoModel>[].obs;
  final RxList<CalculadoraFestaItemModel> itensCalculados = <CalculadoraFestaItemModel>[].obs;
  final Rxn<CalculadoraFestaModel> calculoAtual = Rxn<CalculadoraFestaModel>();

  int get totalConvidados => totalAdultos.value + totalCriancas.value + totalBebes.value;

  bool get possuiEventoVinculado => idEventoAtual.value.trim().isNotEmpty;

  bool get modoEstimativaManualSemEvento => estimativaSemEvento.value && !possuiEventoVinculado;

  bool get possuiResultado => itensCalculados.isNotEmpty;

  Future<void> prepararCalculadora({
    required String idEvento,
    required String tipoEvento,
    BaseCalculoFesta base = BaseCalculoFesta.todosConvidados,
    int duracaoInicialHoras = 4,
    bool calcularAutomaticamente = true,
    bool permitirEstimativaSemEvento = false,
    int adultosManuais = 0,
    int criancasManuais = 0,
    int bebesManuais = 0,
  }) async {
    final idEventoNormalizado = idEvento.trim();
    final modoEstimativa = idEventoNormalizado.isEmpty && permitirEstimativaSemEvento;

    idEventoAtual.value = idEventoNormalizado;
    tipoEventoAtual.value = tipoEvento.trim().isEmpty ? 'Evento' : tipoEvento.trim();
    estimativaSemEvento.value = modoEstimativa;
    baseCalculo.value = modoEstimativa ? BaseCalculoFesta.manual : base;
    duracaoHoras.value = duracaoInicialHoras <= 0 ? 4 : duracaoInicialHoras;
    calculoAtual.value = null;
    itensCalculados.clear();

    if (modoEstimativa) {
      convidados.clear();
      totalAdultos.value = adultosManuais < 0 ? 0 : adultosManuais;
      totalCriancas.value = criancasManuais < 0 ? 0 : criancasManuais;
      totalBebes.value = bebesManuais < 0 ? 0 : bebesManuais;

      if (calcularAutomaticamente) calcular();
      return;
    }

    if (idEventoNormalizado.isEmpty) {
      convidados.clear();
      totalAdultos.value = 0;
      totalCriancas.value = 0;
      totalBebes.value = 0;
      return;
    }

    await carregarConvidadosDoEvento(idEventoNormalizado);

    if (baseCalculo.value != BaseCalculoFesta.manual) {
      aplicarTotaisDosConvidados();
    } else {
      totalAdultos.value = adultosManuais < 0 ? 0 : adultosManuais;
      totalCriancas.value = criancasManuais < 0 ? 0 : criancasManuais;
      totalBebes.value = bebesManuais < 0 ? 0 : bebesManuais;
    }

    if (calcularAutomaticamente) calcular();
  }

  Future<void> carregarConvidadosDoEvento(String idEvento) async {
    if (idEvento.trim().isEmpty) {
      convidados.clear();
      return;
    }

    try {
      loading.value = true;
      final Map<String, ConvidadoModel> mapa = {};

      final snapPrincipal =
          await _db.collection(_collectionConvidado).where('id_evento', isEqualTo: idEvento).get();

      for (final doc in snapPrincipal.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id_convidado'] = data['id_convidado'] ?? doc.id;
        data['id_evento'] = data['id_evento'] ?? idEvento;
        final convidado = ConvidadoModel.fromMap(data);
        mapa[convidado.idConvidado] = convidado;
      }

      // Compatibilidade com base antiga, caso algum documento ainda use id_evento_evento.
      final snapLegado = await _db
          .collection(_collectionConvidado)
          .where('id_evento_evento', isEqualTo: idEvento)
          .get();

      for (final doc in snapLegado.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id_convidado'] = data['id_convidado'] ?? doc.id;
        data['id_evento'] = data['id_evento'] ?? data['id_evento_evento'] ?? idEvento;
        final convidado = ConvidadoModel.fromMap(data);
        mapa[convidado.idConvidado] = convidado;
      }

      convidados.assignAll(mapa.values.toList());
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível carregar os convidados: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      loading.value = false;
    }
  }

  void aplicarTotaisDosConvidados() {
    Iterable<ConvidadoModel> base = convidados;

    if (baseCalculo.value == BaseCalculoFesta.apenasConfirmados) {
      base = convidados.where((c) => c.status == StatusConvidado.confirmado);
    }

    totalAdultos.value = base.where((c) => c.tipoConvidado == TipoConvidado.adulto).length;
    totalCriancas.value = base.where((c) => c.tipoConvidado == TipoConvidado.crianca).length;
    totalBebes.value = base.where((c) => c.tipoConvidado == TipoConvidado.bebe).length;
  }

  void alterarBaseCalculo(BaseCalculoFesta novaBase) {
    baseCalculo.value = novaBase;

    if (novaBase != BaseCalculoFesta.manual) {
      aplicarTotaisDosConvidados();
    }

    calcular();
  }

  void atualizarTotaisManuais({
    required int adultos,
    required int criancas,
    required int bebes,
  }) {
    baseCalculo.value = BaseCalculoFesta.manual;
    totalAdultos.value = adultos < 0 ? 0 : adultos;
    totalCriancas.value = criancas < 0 ? 0 : criancas;
    totalBebes.value = bebes < 0 ? 0 : bebes;
    calcular();
  }

  void atualizarDuracao(int horas) {
    duracaoHoras.value = horas <= 0 ? 4 : horas;
    calcular();
  }

  void calcular() {
    if (!possuiEventoVinculado && !estimativaSemEvento.value) {
      itensCalculados.clear();
      calculoAtual.value = null;
      return;
    }

    final agora = DateTime.now();
    final idBaseCalculo = possuiEventoVinculado ? idEventoAtual.value : 'estimativa';
    final prefixo = possuiEventoVinculado ? 'calc' : 'estimativa';
    final idCalculo = calculoAtual.value?.idCalculo ??
        '${prefixo}_${idBaseCalculo}_${agora.microsecondsSinceEpoch}';

    final calculo = CalculadoraFestaModel(
      idCalculo: idCalculo,
      idEvento: possuiEventoVinculado ? idEventoAtual.value : 'estimativa_temporaria',
      tipoEvento: tipoEventoAtual.value.trim().isEmpty ? 'Evento' : tipoEventoAtual.value,
      baseCalculo: baseCalculo.value,
      totalAdultos: totalAdultos.value,
      totalCriancas: totalCriancas.value,
      totalBebes: totalBebes.value,
      duracaoHoras: duracaoHoras.value,
      dataCalculo: calculoAtual.value?.dataCalculo ?? agora,
      dataAtualizacao: agora,
    );

    calculoAtual.value = calculo;
    itensCalculados.assignAll(_service.calcularItens(calculo: calculo));
  }

  Future<void> salvarCalculo() async {
    final calculo = calculoAtual.value;

    if (!possuiEventoVinculado) {
      Get.snackbar(
        'Estimativa ainda não vinculada',
        'Salve o evento primeiro para gravar este cálculo no histórico.',
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }

    if (calculo == null) {
      Get.snackbar(
        'Atenção',
        'Calcule as quantidades antes de salvar.',
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }

    try {
      salvando.value = true;

      final calculoRef = _db.collection(_collectionCalculadora).doc(calculo.idCalculo);
      await calculoRef.set(calculo.toMap(), SetOptions(merge: true));

      final batch = _db.batch();
      for (final item in itensCalculados) {
        batch.set(
          calculoRef.collection('itens').doc(item.idItemResultado),
          item.toMap(),
          SetOptions(merge: true),
        );
      }
      await batch.commit();

      Get.snackbar(
        'Cálculo salvo',
        'As sugestões foram salvas com sucesso.',
        backgroundColor: Colors.teal,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível salvar o cálculo: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      salvando.value = false;
    }
  }

  Future<void> enviarResultadoParaCardapio({required String idCardapio}) async {
    final calculo = calculoAtual.value;

    if (!possuiEventoVinculado) {
      Get.snackbar(
        'Evento não salvo',
        'Salve o evento primeiro para enviar a estimativa ao cardápio.',
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }

    if (calculo == null || itensCalculados.isEmpty) {
      Get.snackbar(
        'Atenção',
        'Nenhum cálculo disponível para enviar ao cardápio.',
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }

    if (idCardapio.trim().isEmpty) {
      Get.snackbar(
        'Atenção',
        'Selecione um cardápio para receber os itens.',
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }

    try {
      enviandoParaCardapio.value = true;
      final batch = _db.batch();
      final cardapioRef = _db.collection(_collectionCardapios).doc(idCardapio);

      for (final item in itensCalculados) {
        final idItemCardapio = _gerarIdItemCardapio(calculo.idCalculo, item.nome);

        final cardapioItem = CardapioItemModel(
          idItem: idItemCardapio,
          idEvento: calculo.idEvento,
          idCardapio: idCardapio,
          nome: item.nome,
          tipo: TipoItemCardapio.fromString(item.tipoItem),
          publicoAlvo: PublicoAlvoCardapio.fromString(item.publicoAlvo),
          quantidadeSugerida: item.quantidade,
          quantidadeFinal: item.quantidade,
          unidade: item.unidade,
          confirmado: false,
          geradoPelaCalculadora: true,
          observacao: item.regraAplicada,
        );

        batch.set(
          cardapioRef.collection('itens').doc(idItemCardapio),
          cardapioItem.toMap(),
          SetOptions(merge: true),
        );

        batch.set(
          _db
              .collection(_collectionCalculadora)
              .doc(calculo.idCalculo)
              .collection('itens')
              .doc(item.idItemResultado),
          item.copyWith(adicionadoAoCardapio: true).toMap(),
          SetOptions(merge: true),
        );
      }

      await batch.commit();
      await _atualizarTotaisDoCardapio(idCardapio);

      itensCalculados.assignAll(
        itensCalculados.map((i) => i.copyWith(adicionadoAoCardapio: true)).toList(),
      );

      Get.snackbar(
        'Cardápio atualizado',
        'As sugestões foram adicionadas ao cardápio.',
        backgroundColor: Colors.teal,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível enviar as sugestões para o cardápio: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      enviandoParaCardapio.value = false;
    }
  }

  Future<void> _atualizarTotaisDoCardapio(String idCardapio) async {
    final itensSnap =
        await _db.collection(_collectionCardapios).doc(idCardapio).collection('itens').get();

    int totalItens = 0;
    int totalComidas = 0;
    int totalBebidas = 0;
    int totalSobremesas = 0;

    for (final doc in itensSnap.docs) {
      final data = doc.data();
      if (data['ativo'] == false) continue;

      totalItens++;
      final tipo = data['tipo']?.toString().toLowerCase();

      switch (tipo) {
        case 'comida':
        case 'bolo':
          totalComidas++;
          break;
        case 'bebida':
          totalBebidas++;
          break;
        case 'sobremesa':
          totalSobremesas++;
          break;
      }
    }

    await _db.collection(_collectionCardapios).doc(idCardapio).set(
      {
        'total_itens': totalItens,
        'total_comidas': totalComidas,
        'total_bebidas': totalBebidas,
        'total_sobremesas': totalSobremesas,
      },
      SetOptions(merge: true),
    );
  }

  String _gerarIdItemCardapio(String idCalculo, String nome) {
    final normalized = nome
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9áéíóúâêîôûãõç]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+'), '')
        .replaceAll(RegExp(r'_+$'), '');

    final safeName = normalized.isEmpty ? 'item' : normalized;
    return 'calc_${idCalculo}_$safeName';
  }

  void limpar() {
    idEventoAtual.value = '';
    tipoEventoAtual.value = '';
    estimativaSemEvento.value = false;
    baseCalculo.value = BaseCalculoFesta.todosConvidados;
    totalAdultos.value = 0;
    totalCriancas.value = 0;
    totalBebes.value = 0;
    duracaoHoras.value = 4;
    convidados.clear();
    itensCalculados.clear();
    calculoAtual.value = null;
  }
}
