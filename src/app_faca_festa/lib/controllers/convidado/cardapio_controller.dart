import 'dart:async';

import 'package:get/get.dart';

import './../../domain/entities/cardapio.dart';
import './../../domain/entities/cardapio_item.dart';
import './../../domain/repositories/cardapio_repository.dart';

class CardapioController extends GetxController {
  CardapioController({required CardapioRepository repository})
      : _repository = repository;

  final CardapioRepository _repository;

  final RxList<Cardapio> cardapios = <Cardapio>[].obs;
  final RxMap<String, List<CardapioItem>> itensPorCardapio =
      <String, List<CardapioItem>>{}.obs;
  final RxBool carregando = false.obs;
  final RxString erro = ''.obs;

  StreamSubscription<List<Cardapio>>? _cardapiosSubscription;
  final Map<String, StreamSubscription<List<CardapioItem>>>
      _itensSubscriptions = {};

  Future<void> escutarCardapios(String idEvento) async {
    carregando.value = true;
    erro.value = '';
    await _cancelarEscutas();

    _cardapiosSubscription = _repository.observarCardapios(idEvento).listen(
      (lista) {
        cardapios.assignAll(lista);
        final idsAtuais = lista.map((item) => item.idCardapio).toSet();
        for (final idCardapio in _itensSubscriptions.keys.toList()) {
          if (!idsAtuais.contains(idCardapio)) {
            unawaited(_itensSubscriptions.remove(idCardapio)?.cancel());
            itensPorCardapio.remove(idCardapio);
          }
        }
        for (final cardapio in lista) {
          _escutarItensDoCardapio(cardapio.idCardapio);
        }
        itensPorCardapio.refresh();
        carregando.value = false;
      },
      onError: (Object error, StackTrace stackTrace) {
        erro.value = 'Não foi possível carregar os cardápios: $error';
        carregando.value = false;
      },
    );
  }

  void _escutarItensDoCardapio(String idCardapio) {
    if (_itensSubscriptions.containsKey(idCardapio)) return;
    _itensSubscriptions[idCardapio] = _repository
        .observarItens(
      idCardapio,
      idEvento: _idEventoPorCardapio(idCardapio),
    )
        .listen(
      (itens) {
        itensPorCardapio[idCardapio] = itens;
        itensPorCardapio.refresh();
        unawaited(_sincronizarResumoCardapio(idCardapio, itens));
      },
      onError: (Object error, StackTrace stackTrace) {
        erro.value = 'Não foi possível carregar os itens do cardápio: $error';
      },
    );
  }

  Future<void> adicionarCardapio(Cardapio cardapio) =>
      _repository.salvarCardapio(cardapio);

  Future<void> atualizarCardapio(Cardapio cardapio) =>
      _repository.salvarCardapio(cardapio);

  Future<void> excluirCardapio(String idCardapio) async {
    await _repository.excluirCardapio(idCardapio);
    await _itensSubscriptions.remove(idCardapio)?.cancel();
    itensPorCardapio.remove(idCardapio);
    itensPorCardapio.refresh();
  }

  Future<void> addItem(String idCardapio, CardapioItem item) {
    final idEvento = item.idEvento.trim().isNotEmpty
        ? item.idEvento
        : (_idEventoPorCardapio(idCardapio) ?? '');
    return _repository.salvarItem(
      idCardapio,
      item.copyWith(idCardapio: idCardapio, idEvento: idEvento),
    );
  }

  Future<void> atualizarItem(String idCardapio, CardapioItem item) =>
      _repository.salvarItem(idCardapio, item);

  Future<void> toggleConfirmado(String idCardapio, CardapioItem item) =>
      _repository.alternarConfirmado(idCardapio, item);

  Future<void> excluirItem(String idCardapio, String idItem) =>
      _repository.excluirItem(idCardapio, idItem);

  List<CardapioItem> itensDoCardapio(String idCardapio) =>
      List.unmodifiable(itensPorCardapio[idCardapio] ?? const []);

  int totalItensDoCardapio(String idCardapio) =>
      itensPorCardapio[idCardapio]?.length ??
      cardapioPorId(idCardapio)?.totalItens ??
      0;

  int totalComidasDoCardapio(String idCardapio) => _totalPorTipoOuResumo(
        idCardapio,
        _tipoEhComida,
        (cardapio) => cardapio.totalComidas,
      );

  int totalBebidasDoCardapio(String idCardapio) => _totalPorTipoOuResumo(
        idCardapio,
        (tipo) => _tipoEh(tipo, 'bebida'),
        (cardapio) => cardapio.totalBebidas,
      );

  int totalSobremesasDoCardapio(String idCardapio) => _totalPorTipoOuResumo(
        idCardapio,
        (tipo) => _tipoEh(tipo, 'sobremesa'),
        (cardapio) => cardapio.totalSobremesas,
      );

  int _totalPorTipoOuResumo(
    String idCardapio,
    bool Function(dynamic) corresponde,
    int Function(Cardapio) resumo,
  ) {
    final itens = itensPorCardapio[idCardapio];
    if (itens != null) {
      return itens.where((item) => corresponde(item.tipo)).length;
    }
    final cardapio = cardapioPorId(idCardapio);
    return cardapio == null ? 0 : resumo(cardapio);
  }

  int get totalCardapios => cardapios.length;
  int get totalItens => _totalGeral(
        (itens) => itens.length,
        (cardapio) => cardapio.totalItens,
      );
  int get totalComidas => _totalGeral(
        (itens) => itens.where((i) => _tipoEhComida(i.tipo)).length,
        (cardapio) => cardapio.totalComidas,
      );
  int get totalBebidas => _totalGeral(
        (itens) => itens.where((i) => _tipoEh(i.tipo, 'bebida')).length,
        (cardapio) => cardapio.totalBebidas,
      );
  int get totalSobremesas => _totalGeral(
        (itens) => itens.where((i) => _tipoEh(i.tipo, 'sobremesa')).length,
        (cardapio) => cardapio.totalSobremesas,
      );

  int _totalGeral(
    int Function(List<CardapioItem>) calcularItens,
    int Function(Cardapio) calcularResumo,
  ) {
    if (itensPorCardapio.isNotEmpty) {
      return itensPorCardapio.values
          .fold(0, (soma, itens) => soma + calcularItens(itens));
    }
    return cardapios.fold(
      0,
      (soma, cardapio) => soma + calcularResumo(cardapio),
    );
  }

  Future<void> _sincronizarResumoCardapio(
    String idCardapio,
    List<CardapioItem> itens,
  ) async {
    final resumo = ResumoCardapio(
      totalItens: itens.length,
      totalComidas: itens.where((i) => _tipoEhComida(i.tipo)).length,
      totalBebidas: itens.where((i) => _tipoEh(i.tipo, 'bebida')).length,
      totalSobremesas: itens.where((i) => _tipoEh(i.tipo, 'sobremesa')).length,
    );
    final atual = cardapioPorId(idCardapio);
    final atualizado = atual != null &&
        atual.totalItens == resumo.totalItens &&
        atual.totalComidas == resumo.totalComidas &&
        atual.totalBebidas == resumo.totalBebidas &&
        atual.totalSobremesas == resumo.totalSobremesas;
    if (!atualizado) {
      await _repository.atualizarResumo(idCardapio, resumo);
    }
  }

  Cardapio? cardapioPorId(String idCardapio) =>
      cardapios.firstWhereOrNull((item) => item.idCardapio == idCardapio);

  String? _idEventoPorCardapio(String idCardapio) =>
      cardapioPorId(idCardapio)?.idEvento;

  bool _tipoEhComida(dynamic tipo) {
    final normalizado = _normalizarTexto(_valorEnumOuTexto(tipo));
    return normalizado == 'comida' || normalizado == 'bolo';
  }

  bool _tipoEh(dynamic tipo, String esperado) =>
      _normalizarTexto(_valorEnumOuTexto(tipo)) == _normalizarTexto(esperado);

  String _valorEnumOuTexto(dynamic value) {
    if (value == null) return '';
    try {
      final dynamic dynamicValue = value;
      final enumName = dynamicValue.name;
      if (enumName != null) return enumName.toString();
    } catch (_) {}
    final text = value.toString();
    return text.contains('.') ? text.split('.').last : text;
  }

  String _normalizarTexto(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('à', 'a')
      .replaceAll('ã', 'a')
      .replaceAll('â', 'a')
      .replaceAll('é', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ô', 'o')
      .replaceAll('õ', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ç', 'c');

  Future<void> _cancelarEscutas() async {
    await _cardapiosSubscription?.cancel();
    _cardapiosSubscription = null;
    for (final subscription in _itensSubscriptions.values) {
      await subscription.cancel();
    }
    _itensSubscriptions.clear();
  }

  @override
  void onClose() {
    unawaited(_cancelarEscutas());
    super.onClose();
  }
}
