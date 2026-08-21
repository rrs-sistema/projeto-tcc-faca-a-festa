import 'dart:developer' as developer;

import 'package:get/get.dart';

import '../../data/models/calculadora/calculadora_evento_item_model.dart';
import '../../data/models/calculadora/calculadora_item_base_model.dart';
import '../../domain/repositories/calculadora_itens_base_repository_contract.dart';

class CalculadoraItensAdminController extends GetxController {
  final CalculadoraItensBaseRepositoryContract repository;

  CalculadoraItensAdminController({
    required this.repository,
  });

  final RxBool loading = false.obs;
  final RxBool saving = false.obs;

  final RxList<CalculadoraItemBaseModel> itensBase =
      <CalculadoraItemBaseModel>[].obs;
  final RxList<CalculadoraEventoItemModel> itensEvento =
      <CalculadoraEventoItemModel>[].obs;

  final Rxn<CalculadoraItemBaseModel> itemBaseSelecionado =
      Rxn<CalculadoraItemBaseModel>();
  final Rxn<CalculadoraEventoItemModel> itemEventoSelecionado =
      Rxn<CalculadoraEventoItemModel>();

  final RxString erro = ''.obs;

  final RxString buscaBase = ''.obs;
  final RxString filtroCategoriaBase = ''.obs;
  final RxString filtroStatusBase = ''.obs;

  final RxString buscaEvento = ''.obs;
  final RxString filtroTipoEvento = ''.obs;
  final RxString filtroPerfilFesta = ''.obs;
  final RxString filtroCategoriaEvento = ''.obs;
  final RxString filtroStatusEvento = ''.obs;

  static const List<String> tiposEvento = <String>[
    'cha_de_bebe',
    'aniversario',
    'festa_infantil',
    'formatura',
    'casamento',
    'evento_corporativo',
  ];

  static const Map<String, String> tiposEventoLabels = <String, String>{
    'cha_de_bebe': 'Chá de Bebê',
    'aniversario': 'Aniversário',
    'festa_infantil': 'Festa Infantil',
    'formatura': 'Formatura',
    'casamento': 'Casamento',
    'evento_corporativo': 'Evento Corporativo',
  };

  static const List<String> perfisFestaPadrao = <String>[
    'economico',
    'padrao',
    'premium',
  ];

  static const List<String> publicosAlvo = <String>[
    'todos',
    'adultos',
    'criancas',
  ];

  static const List<String> unidadesPadrao = <String>[
    'unidade',
    'quilo',
    'litro',
    'pessoa',
    'porcao',
    'pacote',
  ];

  @override
  void onInit() {
    super.onInit();
    carregarTudo();
  }

  Future<void> carregarTudo() async {
    loading.value = true;
    erro.value = '';

    try {
      await Future.wait([
        carregarItensBase(showLoading: false),
        carregarItensEvento(showLoading: false),
      ]);
    } catch (error, stackTrace) {
      _logError('carregarTudo', error, stackTrace);
      erro.value = 'Não foi possível carregar os itens da calculadora.';
    } finally {
      loading.value = false;
    }
  }

  Future<void> carregarItensBase({bool showLoading = true}) async {
    if (showLoading) loading.value = true;

    try {
      final itens = await repository.listarItensBase();
      _ordenarItensBase(itens);
      itensBase.assignAll(itens);
    } catch (error, stackTrace) {
      _logError('carregarItensBase', error, stackTrace);
      erro.value = 'Falha ao carregar o catálogo de itens base.';
    } finally {
      if (showLoading) loading.value = false;
    }
  }

  Future<void> carregarItensEvento({bool showLoading = true}) async {
    if (showLoading) loading.value = true;

    try {
      final itens = await repository.listarItensEvento();
      _ordenarItensEvento(itens);
      itensEvento.assignAll(itens);
    } catch (error, stackTrace) {
      _logError('carregarItensEvento', error, stackTrace);
      erro.value = 'Falha ao carregar as regras por tipo de evento.';
    } finally {
      if (showLoading) loading.value = false;
    }
  }

  Future<void> salvarItemBase(CalculadoraItemBaseModel item) async {
    saving.value = true;
    erro.value = '';

    try {
      await repository.salvarItemBase(item);
      await carregarItensBase(showLoading: false);
      Get.back<void>();
      _showSuccess('Item base salvo com sucesso.');
    } catch (error, stackTrace) {
      _logError('salvarItemBase', error, stackTrace);
      erro.value = 'Não foi possível salvar o item base.';
      _showError(erro.value);
    } finally {
      saving.value = false;
    }
  }

  Future<void> salvarItemEvento(CalculadoraEventoItemModel item) async {
    saving.value = true;
    erro.value = '';

    try {
      await repository.salvarItemEvento(item);
      await carregarItensEvento(showLoading: false);
      Get.back<void>();
      _showSuccess('Configuração salva com sucesso.');
    } catch (error, stackTrace) {
      _logError('salvarItemEvento', error, stackTrace);
      erro.value = 'Não foi possível salvar a configuração do evento.';
      _showError(erro.value);
    } finally {
      saving.value = false;
    }
  }

  Future<void> ativarDesativarItemBase(
    CalculadoraItemBaseModel item,
    bool ativo,
  ) async {
    saving.value = true;
    erro.value = '';

    try {
      await repository.ativarDesativarItemBase(item.id, ativo);

      final index = itensBase.indexWhere((element) => element.id == item.id);
      if (index >= 0) {
        itensBase[index] = item.copyWith(
          ativo: ativo,
          updatedAt: DateTime.now(),
        );
      }

      _showSuccess(ativo ? 'Item base ativado.' : 'Item base desativado.');
    } catch (error, stackTrace) {
      _logError('ativarDesativarItemBase', error, stackTrace);
      erro.value = 'Não foi possível atualizar o status do item base.';
      _showError(erro.value);
    } finally {
      saving.value = false;
    }
  }

  Future<void> ativarDesativarItemEvento(
    CalculadoraEventoItemModel item,
    bool ativo,
  ) async {
    saving.value = true;
    erro.value = '';

    try {
      await repository.ativarDesativarItemEvento(item.id, ativo);

      final index = itensEvento.indexWhere((element) => element.id == item.id);
      if (index >= 0) {
        itensEvento[index] = item.copyWith(
          ativo: ativo,
          updatedAt: DateTime.now(),
        );
      }

      _showSuccess(ativo ? 'Regra ativada.' : 'Regra desativada.');
    } catch (error, stackTrace) {
      _logError('ativarDesativarItemEvento', error, stackTrace);
      erro.value = 'Não foi possível atualizar o status da regra.';
      _showError(erro.value);
    } finally {
      saving.value = false;
    }
  }

  Future<void> duplicarItemEvento({
    required CalculadoraEventoItemModel item,
    required String novoTipoEvento,
  }) async {
    final tipoEventoSlug = normalizarChave(novoTipoEvento);

    if (tipoEventoSlug.isEmpty) {
      _showError('Selecione o tipo de evento de destino.');
      return;
    }

    saving.value = true;
    erro.value = '';

    try {
      final novoId = '${tipoEventoSlug}_${item.idItemBase}';

      final novoItem = item.copyWith(
        id: novoId,
        tipoEvento: tipoEventoSlug,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.salvarItemEvento(novoItem);
      await carregarItensEvento(showLoading: false);
      Get.back<void>();
      _showSuccess('Configuração duplicada com sucesso.');
    } catch (error, stackTrace) {
      _logError('duplicarItemEvento', error, stackTrace);
      erro.value = 'Não foi possível duplicar a configuração.';
      _showError(erro.value);
    } finally {
      saving.value = false;
    }
  }

  void selecionarItemBase(CalculadoraItemBaseModel? item) {
    itemBaseSelecionado.value = item;
  }

  void selecionarItemEvento(CalculadoraEventoItemModel? item) {
    itemEventoSelecionado.value = item;
  }

  void limparFiltros() {
    buscaBase.value = '';
    filtroCategoriaBase.value = '';
    filtroStatusBase.value = '';
    buscaEvento.value = '';
    filtroTipoEvento.value = '';
    filtroPerfilFesta.value = '';
    filtroCategoriaEvento.value = '';
    filtroStatusEvento.value = '';
  }

  List<CalculadoraItemBaseModel> get itensBaseFiltrados {
    final busca = normalizarChave(buscaBase.value);
    final categoria = filtroCategoriaBase.value.trim().toLowerCase();
    final status = filtroStatusBase.value.trim().toLowerCase();

    final filtrados = itensBase.where((item) {
      if (categoria.isNotEmpty &&
          item.categoriaPadrao.trim().toLowerCase() != categoria) {
        return false;
      }

      if (status == 'ativos' && !item.ativo) return false;
      if (status == 'inativos' && item.ativo) return false;

      if (busca.isEmpty) return true;

      final nome = normalizarChave(item.nome);
      final tipo = normalizarChave(item.tipoItem);
      final tags = item.tags.map(normalizarChave).join(' ');

      return nome.contains(busca) ||
          tipo.contains(busca) ||
          tags.contains(busca);
    }).toList();

    _ordenarItensBase(filtrados);
    return filtrados;
  }

  List<CalculadoraEventoItemModel> get itensEventoFiltrados {
    final busca = normalizarChave(buscaEvento.value);
    final tipoEvento = filtroTipoEvento.value.trim();
    final perfil = filtroPerfilFesta.value.trim();
    final categoria = filtroCategoriaEvento.value.trim().toLowerCase();
    final status = filtroStatusEvento.value.trim().toLowerCase();

    final filtrados = itensEvento.where((item) {
      if (tipoEvento.isNotEmpty && item.tipoEvento != tipoEvento) {
        return false;
      }

      if (categoria.isNotEmpty &&
          item.categoria.trim().toLowerCase() != categoria) {
        return false;
      }

      if (perfil.isNotEmpty &&
          !item.perfisFesta.any((value) => value.trim() == perfil)) {
        return false;
      }

      if (status == 'ativos' && !item.ativo) return false;
      if (status == 'inativos' && item.ativo) return false;

      if (busca.isEmpty) return true;

      final nome = normalizarChave(item.nome);
      final base = normalizarChave(item.idItemBase);
      final observacao = normalizarChave(item.observacao);

      return nome.contains(busca) ||
          base.contains(busca) ||
          observacao.contains(busca);
    }).toList();

    _ordenarItensEvento(filtrados);
    return filtrados;
  }

  List<String> get categoriasBase {
    final categorias = itensBase
        .map((item) => item.categoriaPadrao.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
    categorias.sort();
    return categorias;
  }

  List<String> get categoriasEvento {
    final categorias = itensEvento
        .map((item) => item.categoria.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
    categorias.sort();
    return categorias;
  }

  List<CalculadoraItemBaseModel> get itensBaseAtivos {
    final itens = itensBase.where((item) => item.ativo).toList();
    _ordenarItensBase(itens);
    return itens;
  }

  String labelTipoEvento(String tipoEvento) {
    return tiposEventoLabels[tipoEvento] ?? tipoEvento;
  }

  String gerarIdItemBase({
    required String nome,
    required String tipoItem,
  }) {
    final base = tipoItem.trim().isNotEmpty ? tipoItem : nome;
    return normalizarChave(base);
  }

  String gerarIdItemEvento({
    required String tipoEvento,
    required String idItemBase,
  }) {
    return '${normalizarChave(tipoEvento)}_${normalizarChave(idItemBase)}';
  }

  String normalizarChave(String value) {
    var text = value.trim().toLowerCase();
    if (text.isEmpty) return '';

    text = _removerAcentos(text);
    text = text
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_'), '')
        .replaceAll(RegExp(r'_$'), '');

    return text;
  }

  String _removerAcentos(String value) {
    const accents = <String, String>{
      'á': 'a',
      'à': 'a',
      'ã': 'a',
      'â': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'õ': 'o',
      'ô': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
    };

    var result = value;
    accents.forEach((accented, plain) {
      result = result.replaceAll(accented, plain);
    });

    return result;
  }

  void _ordenarItensBase(List<CalculadoraItemBaseModel> itens) {
    itens.sort((a, b) {
      final ordem = a.ordem.compareTo(b.ordem);
      if (ordem != 0) return ordem;
      return a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
    });
  }

  void _ordenarItensEvento(List<CalculadoraEventoItemModel> itens) {
    itens.sort((a, b) {
      final tipo = a.tipoEvento.compareTo(b.tipoEvento);
      if (tipo != 0) return tipo;

      final ordem = a.ordem.compareTo(b.ordem);
      if (ordem != 0) return ordem;

      return a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
    });
  }

  void _showSuccess(String message) {
    if (Get.testMode) return;

    Get.snackbar(
      'Calculadora',
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void _showError(String message) {
    if (Get.testMode) return;

    Get.snackbar(
      'Atenção',
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  void _logError(String method, Object error, StackTrace stackTrace) {
    developer.log(
      'Erro em CalculadoraItensAdminController.$method',
      name: 'CalculadoraItensAdminController',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
