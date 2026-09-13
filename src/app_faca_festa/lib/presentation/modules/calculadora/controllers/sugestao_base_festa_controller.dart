import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/domain/entities/sugestao_base_festa.dart';
import 'package:app_faca_festa/domain/repositories/sugestao_base_festa_repository_contract.dart';

class SugestaoBaseFestaController extends GetxController {
  SugestaoBaseFestaController({
    required SugestaoBaseFestaRepositoryContract repository,
  }) : _repository = repository;

  final SugestaoBaseFestaRepositoryContract _repository;

  final RxBool loading = false.obs;
  final RxBool saving = false.obs;
  final RxString error = ''.obs;

  final RxList<SugestaoBaseFesta> listaSugestoes = <SugestaoBaseFesta>[].obs;
  final RxList<SugestaoBaseFesta> listaFiltrada = <SugestaoBaseFesta>[].obs;

  final RxString filtroModulo = ''.obs;
  final RxString filtroTema = ''.obs;
  final RxString filtroTipoEvento = ''.obs;
  final RxString filtroPerfilFesta = ''.obs;
  final RxString filtroAtivo = 'todos'.obs;
  final RxString buscaTexto = ''.obs;

  final Rxn<SugestaoBaseFesta> sugestaoSelecionada = Rxn<SugestaoBaseFesta>();

  final TextEditingController buscaController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    carregarSugestoes();

    debounce<String>(
      buscaTexto,
      (_) => aplicarFiltros(),
      time: const Duration(milliseconds: 350),
    );

    everAll([
      filtroModulo,
      filtroTema,
      filtroTipoEvento,
      filtroPerfilFesta,
      filtroAtivo,
    ], (_) => aplicarFiltros());

    //importarSugestoesTeste(sobrescrever: true);
  }

  Future<int> importarSugestoesTeste({
    bool sobrescrever = true,
  }) async {
    return _repository.importarSugestoesTeste(
      sobrescrever: sobrescrever,
    );
  }


  @override
  void onClose() {
    buscaController.dispose();
    super.onClose();
  }

  Future<void> carregarSugestoes() async {
    try {
      loading.value = true;
      error.value = '';

      final sugestoes = await _repository.listarSugestoes();
      listaSugestoes.assignAll(sugestoes);
      aplicarFiltros();
    } catch (e) {
      error.value = 'Erro ao carregar sugestões IA: $e';
      listaFiltrada.clear();
    } finally {
      loading.value = false;
    }
  }

  void aplicarFiltros() {
    final modulo = filtroModulo.value.trim();
    final tema = filtroTema.value.trim();
    final tipoEvento = filtroTipoEvento.value.trim();
    final perfilFesta = filtroPerfilFesta.value.trim();
    final ativo = filtroAtivo.value.trim();
    final busca = buscaTexto.value.trim().toLowerCase();

    final filtradas = listaSugestoes.where((item) {
      if (modulo.isNotEmpty && item.modulo != modulo) return false;
      if (tema.isNotEmpty && item.tema != tema) return false;
      if (tipoEvento.isNotEmpty &&
          !item.tipoEvento.contains(tipoEvento) &&
          !item.tipoEvento.contains('todos')) {
        return false;
      }
      if (perfilFesta.isNotEmpty &&
          !item.perfisFesta.contains(perfilFesta) &&
          !item.perfisFesta.contains('todos')) {
        return false;
      }
      if (ativo == 'ativos' && !item.ativo) return false;
      if (ativo == 'inativos' && item.ativo) return false;

      if (busca.isNotEmpty) {
        final alvo = [
          item.titulo,
          item.descricao,
          item.modulo,
          item.tema,
          item.categoria,
          item.prioridade,
          item.tags.join(' '),
          item.tipoEvento.join(' '),
          item.perfisFesta.join(' '),
        ].join(' ').toLowerCase();

        if (!alvo.contains(busca)) return false;
      }

      return true;
    }).toList()
      ..sort((a, b) {
        final ordemCompare = a.ordem.compareTo(b.ordem);
        if (ordemCompare != 0) return ordemCompare;
        return a.titulo.toLowerCase().compareTo(b.titulo.toLowerCase());
      });

    listaFiltrada.assignAll(filtradas);
  }

  void limparFiltros() {
    filtroModulo.value = '';
    filtroTema.value = '';
    filtroTipoEvento.value = '';
    filtroPerfilFesta.value = '';
    filtroAtivo.value = 'todos';
    buscaTexto.value = '';
    buscaController.clear();
    aplicarFiltros();
  }

  Future<void> salvar(SugestaoBaseFesta sugestao) async {
    try {
      saving.value = true;
      error.value = '';

      if (sugestao.isNew) {
        await _repository.salvarSugestao(sugestao);
      } else {
        await _repository.atualizarSugestao(sugestao);
      }

      await carregarSugestoes();

      Get.snackbar(
        'Sugestões IA',
        'Sugestão salva com sucesso.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      error.value = 'Erro ao salvar sugestão: $e';
      Get.snackbar(
        'Erro ao salvar',
        error.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      rethrow;
    } finally {
      saving.value = false;
    }
  }

  Future<void> editar(SugestaoBaseFesta sugestao) async {
    sugestaoSelecionada.value = sugestao;
  }

  Future<void> ativarDesativar(SugestaoBaseFesta sugestao) async {
    try {
      await _repository.ativarDesativarSugestao(
        id: sugestao.id,
        ativo: !sugestao.ativo,
      );
      await carregarSugestoes();

      Get.snackbar(
        'Sugestões IA',
        sugestao.ativo ? 'Sugestão desativada.' : 'Sugestão ativada.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível alterar o status: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    }
  }

  Future<void> excluirLogicamente(SugestaoBaseFesta sugestao) async {
    try {
      await _repository.excluirLogicamente(sugestao.id);
      await carregarSugestoes();

      Get.snackbar(
        'Sugestões IA',
        'Sugestão removida da listagem.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível excluir a sugestão: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    }
  }

  List<String> get modulosDisponiveis => _uniqueSorted(
        listaSugestoes.map((e) => e.modulo),
        fallback: SugestaoBaseFestaOptions.modulos,
      );

  List<String> get temasDisponiveis => _uniqueSorted(
        listaSugestoes.map((e) => e.tema),
        fallback: SugestaoBaseFestaOptions.temas,
      );

  List<String> get tiposEventoDisponiveis => _uniqueSorted(
        listaSugestoes.expand((e) => e.tipoEvento),
        fallback: SugestaoBaseFestaOptions.tiposEvento,
      );

  List<String> get perfisFestaDisponiveis => _uniqueSorted(
        listaSugestoes.expand((e) => e.perfisFesta),
        fallback: SugestaoBaseFestaOptions.perfisFesta,
      );

  List<String> _uniqueSorted(
    Iterable<String> values, {
    required List<String> fallback,
  }) {
    final set = <String>{
      ...fallback,
      ...values.where((e) => e.trim().isNotEmpty)
    };
    final list = set.toList()..sort();
    return list;
  }
}

class SugestaoBaseFestaOptions {
  static const List<String> modulos = [
    'calculadora',
    'orcamento',
    'convidados',
    'fornecedores',
    'checklist',
    'espaco_convidados',
    'referencias',
    'cardapio',
    'decoracao',
    'presentes',
  ];

  static const List<String> temas = [
    'geral',
    'bebidas',
    'bolo',
    'salgadinhos',
    'docinhos',
    'lembrancinhas',
    'orcamento',
    'fornecedores',
    'cardapio',
    'decoracao',
    'presentes',
  ];

  static const List<String> tiposEvento = [
    'todos',
    'aniversario',
    'aniversario_infantil',
    'cha_de_bebe',
    'casamento',
    'natal',
    'ano_novo',
    'confraternizacao',
  ];

  static const List<String> perfisFesta = [
    'todos',
    'economico',
    'padrao',
    'premium',
  ];

  static const List<String> categorias = [
    'dica',
    'alerta',
    'risco',
    'economia',
    'organizacao',
    'fornecedor',
  ];

  static const List<String> prioridades = [
    'baixa',
    'media',
    'alta',
    'critica',
  ];
}

