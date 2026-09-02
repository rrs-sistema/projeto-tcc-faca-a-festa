import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/core/services/calculadora_festa_ai_service.dart';
import 'package:app_faca_festa/core/services/calculadora_festa_service.dart';
import 'package:app_faca_festa/data/models/calculadora/calculadora_evento_item_model.dart';
import 'package:app_faca_festa/data/models/evento/analise_calculadora_ia_model.dart';
import 'package:app_faca_festa/data/models/evento/calculadora_festa_item_model.dart';
import 'package:app_faca_festa/data/models/evento/calculadora_festa_model.dart';
import 'package:app_faca_festa/data/models/evento/convidados_equivalentes_model.dart';
import 'package:app_faca_festa/data/models/evento/estimativa_financeira_model.dart';
import 'package:app_faca_festa/data/models/evento/perfil_festa_model.dart';
import 'package:app_faca_festa/data/models/model.dart';
import 'package:app_faca_festa/domain/repositories/calculadora_festa_repository.dart';
import 'package:app_faca_festa/domain/repositories/calculadora_itens_base_repository_contract.dart';
import 'package:app_faca_festa/domain/services/calculadora_festa_ai_service.dart';

enum OrigemItensCalculadora {
  firestore,
  fallbackLocal,
}

extension OrigemItensCalculadoraExtension on OrigemItensCalculadora {
  String get label {
    switch (this) {
      case OrigemItensCalculadora.firestore:
        return 'Firestore';
      case OrigemItensCalculadora.fallbackLocal:
        return 'Base padrão local';
    }
  }
}

class CalculadoraFestaController extends GetxController {
  final CalculadoraFestaService _service;
  final ICalculadoraFestaAIService _aiService;
  final CalculadoraFestaRepository _repository;
  final CalculadoraItensBaseRepositoryContract _itensBaseRepository;

  CalculadoraFestaController({
    CalculadoraFestaService? service,
    ICalculadoraFestaAIService? aiService,
    CalculadoraFestaRepository? repository,
    CalculadoraItensBaseRepositoryContract? itensBaseRepository,
  })  : _service = service ?? const CalculadoraFestaService(),
        _aiService = aiService ?? const CalculadoraFestaAIService(),
        _repository = repository ?? Get.find<CalculadoraFestaRepository>(),
        _itensBaseRepository = itensBaseRepository ??
            Get.find<CalculadoraItensBaseRepositoryContract>();

  final RxBool loading = false.obs;
  final RxBool salvando = false.obs;
  final RxBool enviandoParaCardapio = false.obs;
  final RxBool convertendoOrcamento = false.obs;
  final RxBool analisandoIA = false.obs;
  final RxBool carregandoItensBase = false.obs;
  final RxBool itensOrigemRemota = false.obs;
  final Rx<OrigemItensCalculadora> origemItensCalculadora =
      OrigemItensCalculadora.fallbackLocal.obs;
  final RxString erroItensBase = ''.obs;

  bool get usandoItensDoFirestore {
    return origemItensCalculadora.value == OrigemItensCalculadora.firestore;
  }

  bool get usandoFallbackLocalCalculadora {
    return origemItensCalculadora.value == OrigemItensCalculadora.fallbackLocal;
  }

  String get mensagemOrigemItensCalculadora {
    if (usandoItensDoFirestore) {
      return 'Usando base configurada da calculadora.';
    }

    return 'Usando base padrão da calculadora.';
  }

  final RxString idEventoAtual = ''.obs;
  final RxString tipoEventoAtual = ''.obs;
  final RxBool estimativaSemEvento = false.obs;

  final Rx<BaseCalculoFesta> baseCalculo = BaseCalculoFesta.todosConvidados.obs;
  final Rx<PerfilFestaModel> perfilSelecionado = PerfilFestaModel.padrao().obs;

  final RxInt totalAdultos = 0.obs;
  final RxInt totalCriancas = 0.obs;
  final RxInt totalBebes = 0.obs;

  /// Totais vindos do cadastro do evento.
  /// São usados como fallback quando o evento ainda não possui convidados
  /// cadastrados individualmente.
  final RxInt totalAdultosEvento = 0.obs;
  final RxInt totalCriancasEvento = 0.obs;
  final RxInt totalBebesEvento = 0.obs;

  final RxInt duracaoHoras = 4.obs;

  /// Orçamento informado pelo usuário para a IA avaliar se a festa cabe no limite.
  final Rxn<double> orcamentoDisponivel = Rxn<double>();

  /// Quando null, usa a margem padrão do perfil selecionado.
  final Rxn<double> margemPersonalizada = Rxn<double>();

  final RxInt _versaoAnaliseIA = 0.obs;
  Worker? _workerAnaliseIA;

  final RxList<ConvidadoModel> convidados = <ConvidadoModel>[].obs;
  final RxList<ItemEstimativaFinanceiraModel> itensEstimativa =
      CalculadoraFestaService.itensPadraoEstimativa.obs;
  final RxList<CalculadoraFestaItemModel> itensCalculados =
      <CalculadoraFestaItemModel>[].obs;
  final RxList<CalculadoraFestaModel> simulacoesSalvas =
      <CalculadoraFestaModel>[].obs;
  final RxBool carregandoSimulacoes = false.obs;

  final Rxn<CalculadoraFestaModel> calculoAtual = Rxn<CalculadoraFestaModel>();
  final Rxn<EstimativaFinanceiraModel> estimativaAtual =
      Rxn<EstimativaFinanceiraModel>();
  final Rxn<AnaliseCalculadoraIAModel> analiseIA =
      Rxn<AnaliseCalculadoraIAModel>();

  int get totalConvidados =>
      totalAdultos.value + totalCriancas.value + totalBebes.value;

  int get totalConvidadosEvento {
    return totalAdultosEvento.value +
        totalCriancasEvento.value +
        totalBebesEvento.value;
  }

  bool get possuiTotaisDoEvento => totalConvidadosEvento > 0;

  bool get possuiConvidadosCadastrados => convidados.isNotEmpty;

  bool get usandoTotaisDoCadastroDoEvento {
    return baseCalculo.value == BaseCalculoFesta.todosConvidados &&
        !possuiConvidadosCadastrados &&
        possuiTotaisDoEvento;
  }

  ConvidadosEquivalentesModel get convidadosEquivalentes =>
      ConvidadosEquivalentesModel(
        adultos: totalAdultos.value,
        criancas: totalCriancas.value,
        bebes: totalBebes.value,
      );

  int get totalConvidadosEquivalentes =>
      convidadosEquivalentes.totalEquivalenteArredondado;

  double get custoTotalEstimado {
    return itensCalculados.fold<double>(
        0, (total, item) => total + item.custoEstimado);
  }

  String get custoTotalEstimadoFormatado => _formatMoney(custoTotalEstimado);

  double get margemEmUso {
    return margemPersonalizada.value ??
        perfilSelecionado.value.margemSegurancaPadrao;
  }

  bool get possuiEventoVinculado => idEventoAtual.value.trim().isNotEmpty;

  bool get modoEstimativaManualSemEvento =>
      estimativaSemEvento.value && !possuiEventoVinculado;

  bool get possuiResultado => itensCalculados.isNotEmpty;

  bool get possuiAnaliseIA => analiseIA.value != null;

  @override
  void onInit() {
    super.onInit();
    _workerAnaliseIA = debounce<int>(
      _versaoAnaliseIA,
      (_) => _executarAnaliseIA(),
      time: const Duration(milliseconds: 500),
    );
  }

  @override
  void onClose() {
    _workerAnaliseIA?.dispose();
    super.onClose();
  }

  Future<void> prepararCalculadora({
    required String idEvento,
    required String tipoEvento,
    BaseCalculoFesta base = BaseCalculoFesta.todosConvidados,
    TipoPerfilFesta perfilInicial = TipoPerfilFesta.padrao,
    int duracaoInicialHoras = 4,
    bool calcularAutomaticamente = true,
    bool permitirEstimativaSemEvento = false,
    int adultosManuais = 0,
    int criancasManuais = 0,
    int bebesManuais = 0,
    int adultosEvento = 0,
    int criancasEvento = 0,
    int bebesEvento = 0,
    int totalConvidadosEvento = 0,
  }) async {
    final idEventoNormalizado = idEvento.trim();
    final modoEstimativa =
        idEventoNormalizado.isEmpty && permitirEstimativaSemEvento;

    idEventoAtual.value = idEventoNormalizado;
    tipoEventoAtual.value =
        tipoEvento.trim().isEmpty ? 'Evento' : tipoEvento.trim();
    estimativaSemEvento.value = modoEstimativa;
    baseCalculo.value = modoEstimativa ? BaseCalculoFesta.manual : base;
    perfilSelecionado.value = PerfilFestaModel.fromTipo(perfilInicial);
    duracaoHoras.value = duracaoInicialHoras <= 0 ? 4 : duracaoInicialHoras;
    _registrarTotaisDoEvento(
      adultos: adultosEvento,
      criancas: criancasEvento,
      bebes: bebesEvento,
      totalLegado: totalConvidadosEvento,
    );
    calculoAtual.value = null;
    estimativaAtual.value = null;
    itensCalculados.clear();

    if (modoEstimativa) {
      convidados.clear();
      totalAdultos.value = _normalizarQuantidade(adultosManuais);
      totalCriancas.value = _normalizarQuantidade(criancasManuais);
      totalBebes.value = _normalizarQuantidade(bebesManuais);

      await carregarItensBasePorTipoEvento(
        recalcularAposCarregar: false,
      );

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
      final totalManual = adultosManuais + criancasManuais + bebesManuais;

      if (totalManual > 0) {
        totalAdultos.value = _normalizarQuantidade(adultosManuais);
        totalCriancas.value = _normalizarQuantidade(criancasManuais);
        totalBebes.value = _normalizarQuantidade(bebesManuais);
      } else {
        aplicarTotaisDoCadastroDoEvento();
      }
    }

    await carregarItensBasePorTipoEvento(
      recalcularAposCarregar: false,
    );

    if (calcularAutomaticamente) calcular();
    await carregarSimulacoesSalvas();
  }

  void iniciarNovoCalculo({
    bool limparQuantidades = true,
    bool limparOrcamento = true,
    bool manterPerfil = true,
    bool manterDuracao = true,
  }) {
    calculoAtual.value = null;
    estimativaAtual.value = null;
    analiseIA.value = null;
    analisandoIA.value = false;

    itensCalculados.clear();

    if (limparOrcamento) {
      orcamentoDisponivel.value = null;
    }

    if (!manterPerfil) {
      perfilSelecionado.value = PerfilFestaModel.padrao();
      margemPersonalizada.value = null;
    }

    if (!manterDuracao) {
      duracaoHoras.value = 4;
    }

    if (limparQuantidades) {
      baseCalculo.value = BaseCalculoFesta.manual;
      totalAdultos.value = 0;
      totalCriancas.value = 0;
      totalBebes.value = 0;
    }

    debugPrint(
      '[CalculadoraFestaController] Novo cálculo iniciado. '
      'Itens base mantidos: ${itensEstimativa.length}. '
      'Origem: ${origemItensCalculadora.value.label}.',
    );
  }

  Future<void> carregarItensBasePorTipoEvento({
    bool recalcularAposCarregar = true,
  }) async {
    final tipoEventoKey = _normalizarTipoEventoParaConsulta(
      tipoEventoAtual.value,
    );
    final perfilFestaKey = _normalizarPerfilFestaParaConsulta();

    if (tipoEventoKey.isEmpty) {
      _usarItensFixosComoFallback(
        motivo: 'Tipo de evento não informado para a calculadora.',
        recalcularAposCarregar: recalcularAposCarregar,
      );
      return;
    }

    try {
      carregandoItensBase.value = true;
      erroItensBase.value = '';

      final itensRemotos =
          await _itensBaseRepository.buscarItensPorTipoEventoComFallback(
        tipoEvento: tipoEventoKey,
        perfilFesta: perfilFestaKey.isEmpty ? null : perfilFestaKey,
      );

      if (itensRemotos.isEmpty) {
        _usarItensFixosComoFallback(
          motivo: 'Nenhum item remoto encontrado para $tipoEventoKey.',
          recalcularAposCarregar: recalcularAposCarregar,
        );
        return;
      }

      final itensConvertidos = itensRemotos
          .where((item) => item.ativo)
          .map(_converterItemEventoParaEstimativa)
          .toList();

      if (itensConvertidos.isEmpty) {
        _usarItensFixosComoFallback(
          motivo: 'Os itens remotos encontrados não puderam ser convertidos.',
          recalcularAposCarregar: recalcularAposCarregar,
        );
        return;
      }

      itensEstimativa.assignAll(itensConvertidos);
      itensOrigemRemota.value = true;
      origemItensCalculadora.value = OrigemItensCalculadora.firestore;
      erroItensBase.value = '';

      debugPrint(
        '[CalculadoraFestaController] Itens carregados do Firestore | '
        'tipoEvento=$tipoEventoKey | perfil=$perfilFestaKey | total=${itensConvertidos.length}',
      );

      if (recalcularAposCarregar) {
        calcular();
      }
    } catch (e) {
      _usarItensFixosComoFallback(
        motivo: 'Erro ao carregar itens remotos da calculadora: $e',
        recalcularAposCarregar: recalcularAposCarregar,
      );
    } finally {
      carregandoItensBase.value = false;
    }
  }

  Future<void> atualizarTipoEventoCalculadora(String tipoEvento) async {
    tipoEventoAtual.value =
        tipoEvento.trim().isEmpty ? 'Evento' : tipoEvento.trim();
    await carregarItensBasePorTipoEvento();
  }

  void _usarItensFixosComoFallback({
    required String motivo,
    required bool recalcularAposCarregar,
  }) {
    erroItensBase.value = motivo;
    itensOrigemRemota.value = false;
    origemItensCalculadora.value = OrigemItensCalculadora.fallbackLocal;
    itensEstimativa.assignAll(CalculadoraFestaService.itensPadraoEstimativa);

    debugPrint(
      '[CalculadoraFestaController] $motivo '
      'Usando fallback local: CalculadoraFestaService.itensPadraoEstimativa.',
    );

    if (recalcularAposCarregar) {
      calcular();
    }
  }

  ItemEstimativaFinanceiraModel _converterItemEventoParaEstimativa(
    CalculadoraEventoItemModel item,
  ) {
    final selecionado = item.obrigatorio || item.selecionadoPadrao;

    return ItemEstimativaFinanceiraModel.fromMap({
      'id': item.id,
      'id_item_base': item.idItemBase,
      'idItemBase': item.idItemBase,
      'nome': item.nome,
      'categoria': item.categoria,
      'tipo_item': item.idItemBase.trim().isNotEmpty
          ? item.idItemBase
          : _normalizarSlug(item.nome),
      'tipoItem': item.idItemBase.trim().isNotEmpty
          ? item.idItemBase
          : _normalizarSlug(item.nome),
      'unidade': item.unidade,
      'publico_alvo': item.publicoAlvo,
      'publicoAlvo': item.publicoAlvo,
      'quantidade_por_convidado_equivalente':
          item.quantidadePorConvidadoEquivalente,
      'quantidadePorConvidadoEquivalente':
          item.quantidadePorConvidadoEquivalente,
      'quantidade_por_convidado': item.quantidadePorConvidadoEquivalente,
      'quantidadePorConvidado': item.quantidadePorConvidadoEquivalente,
      'valor_unitario_medio': item.valorUnitarioMedio,
      'valorUnitarioMedio': item.valorUnitarioMedio,
      'perfis_festa': item.perfisFesta,
      'perfisFesta': item.perfisFesta,
      'selecionado': selecionado,
      'selecionado_padrao': item.selecionadoPadrao,
      'selecionadoPadrao': item.selecionadoPadrao,
      'obrigatorio': item.obrigatorio,
      'ativo': item.ativo,
      'ordem': item.ordem,
      'observacao': item.observacao,
    });
  }

  Future<void> carregarConvidadosDoEvento(String idEvento) async {
    if (idEvento.trim().isEmpty) {
      convidados.clear();
      return;
    }

    try {
      loading.value = true;
      convidados
          .assignAll(await _repository.listarConvidadosDoEvento(idEvento));
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

    final adultos =
        base.where((c) => c.tipoConvidado == TipoConvidado.adulto).length;
    final criancas =
        base.where((c) => c.tipoConvidado == TipoConvidado.crianca).length;
    final bebes =
        base.where((c) => c.tipoConvidado == TipoConvidado.bebe).length;
    final totalEncontrado = adultos + criancas + bebes;

    if (totalEncontrado > 0 ||
        baseCalculo.value == BaseCalculoFesta.apenasConfirmados) {
      totalAdultos.value = adultos;
      totalCriancas.value = criancas;
      totalBebes.value = bebes;
      return;
    }

    // Quando ainda não existe lista de convidados, usamos a estimativa salva
    // no cadastro do evento: total_adultos, total_criancas e total_bebes.
    aplicarTotaisDoCadastroDoEvento();
  }

  void aplicarTotaisDoCadastroDoEvento() {
    totalAdultos.value = totalAdultosEvento.value;
    totalCriancas.value = totalCriancasEvento.value;
    totalBebes.value = totalBebesEvento.value;
  }

  void alterarBaseCalculo(BaseCalculoFesta novaBase) {
    baseCalculo.value = novaBase;

    if (novaBase != BaseCalculoFesta.manual) {
      aplicarTotaisDosConvidados();
    }

    calcular();
  }

  void selecionarPerfil(TipoPerfilFesta tipo) {
    perfilSelecionado.value = PerfilFestaModel.fromTipo(tipo);
    margemPersonalizada.value = null;

    // O perfil pode alterar os itens retornados pelo Firestore
    // por causa do filtro perfis_festa. A tela não precisa mudar:
    // ela continua observando os mesmos estados reativos.
    carregarItensBasePorTipoEvento();
  }

  void atualizarMargemPersonalizada(double? margem) {
    if (margem == null) {
      margemPersonalizada.value = null;
    } else {
      margemPersonalizada.value = margem.clamp(0, 0.30).toDouble();
    }

    calcular();
  }

  void alternarItemEstimativa(String idItem, bool selecionado) {
    itensEstimativa.assignAll(
      itensEstimativa.map((item) {
        if (item.id != idItem) return item;
        return item.copyWith(selecionado: selecionado);
      }).toList(),
    );

    calcular();
  }

  void atualizarValorMedioItem(String idItem, double valorUnitarioMedio) {
    itensEstimativa.assignAll(
      itensEstimativa.map((item) {
        if (item.id != idItem) return item;
        return item.copyWith(
            valorUnitarioMedio:
                valorUnitarioMedio < 0 ? 0 : valorUnitarioMedio);
      }).toList(),
    );

    calcular();
  }

  void atualizarTotaisManuais({
    required int adultos,
    required int criancas,
    required int bebes,
  }) {
    baseCalculo.value = BaseCalculoFesta.manual;
    totalAdultos.value = _normalizarQuantidade(adultos);
    totalCriancas.value = _normalizarQuantidade(criancas);
    totalBebes.value = _normalizarQuantidade(bebes);
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
      estimativaAtual.value = null;
      analiseIA.value = null;
      return;
    }

    final agora = DateTime.now();
    final idBaseCalculo =
        possuiEventoVinculado ? idEventoAtual.value : 'estimativa';
    final prefixo = possuiEventoVinculado ? 'calc' : 'estimativa';
    final idCalculo = calculoAtual.value?.idCalculo ??
        '${prefixo}_${idBaseCalculo}_${agora.microsecondsSinceEpoch}';

    final calculoBase = CalculadoraFestaModel(
      idCalculo: idCalculo,
      idEvento:
          possuiEventoVinculado ? idEventoAtual.value : 'estimativa_temporaria',
      tipoEvento: tipoEventoAtual.value.trim().isEmpty
          ? 'Evento'
          : tipoEventoAtual.value,
      baseCalculo: baseCalculo.value,
      totalAdultos: totalAdultos.value,
      totalCriancas: totalCriancas.value,
      totalBebes: totalBebes.value,
      duracaoHoras: duracaoHoras.value,
      dataCalculo: calculoAtual.value?.dataCalculo ?? agora,
      dataAtualizacao: agora,
      perfilFesta: perfilSelecionado.value,
      margemPersonalizada: margemPersonalizada.value,
      orcamentoDisponivel: orcamentoDisponivel.value,
    );

    final itens = _service.calcularItens(
      calculo: calculoBase,
      itensBase: itensEstimativa,
    );

    final custoTotal =
        itens.fold<double>(0, (total, item) => total + item.custoEstimado);
    final calculoFinal = calculoBase.copyWith(custoTotalEstimado: custoTotal);

    calculoAtual.value = calculoFinal;
    itensCalculados.assignAll(itens);
    estimativaAtual.value = _service.calcularEstimativa(
      calculo: calculoFinal,
      itensBase: itensEstimativa,
    );
    _agendarAnaliseIA();
  }

  void atualizarOrcamentoDisponivel(double? valor) {
    if (valor == null || valor <= 0) {
      orcamentoDisponivel.value = null;
    } else {
      orcamentoDisponivel.value = valor;
    }

    final calculo = calculoAtual.value;
    if (calculo != null) {
      calculoAtual.value = calculo.copyWith(
        orcamentoDisponivel: orcamentoDisponivel.value,
        limparOrcamentoDisponivel: orcamentoDisponivel.value == null,
        dataAtualizacao: DateTime.now(),
      );
    }

    _agendarAnaliseIA();
  }

  void _agendarAnaliseIA() {
    _versaoAnaliseIA.value++;
  }

  Future<void> _executarAnaliseIA({bool force = false}) async {
    final estimativa = estimativaAtual.value;
    final calculoReferencia = calculoAtual.value;
    final versaoSolicitada = _versaoAnaliseIA.value;

    if (estimativa == null ||
        calculoReferencia == null ||
        itensCalculados.isEmpty) {
      analiseIA.value = null;
      return;
    }

    try {
      analisandoIA.value = true;

      final analise = await _aiService.analisarEstimativa(
        estimativa: estimativa,
        itensCalculados: itensCalculados.toList(),
        tipoEvento: tipoEventoAtual.value,
        orcamentoDisponivel: orcamentoDisponivel.value,
      );

      if (!force && versaoSolicitada != _versaoAnaliseIA.value) {
        return;
      }

      final calculoAtualizado = calculoAtual.value;

      if (calculoAtualizado == null ||
          calculoAtualizado.idCalculo != calculoReferencia.idCalculo) {
        return;
      }

      analiseIA.value = analise;

      calculoAtual.value = calculoAtualizado.copyWith(
        analiseIA: analise,
        orcamentoDisponivel: orcamentoDisponivel.value,
        limparOrcamentoDisponivel: orcamentoDisponivel.value == null,
        dataAtualizacao: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Erro ao executar análise inteligente da calculadora: $e');
    } finally {
      analisandoIA.value = false;
    }
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

      final calculoParaSalvar = calculo.copyWith(
        orcamentoDisponivel: orcamentoDisponivel.value,
        limparOrcamentoDisponivel: orcamentoDisponivel.value == null,
        analiseIA: analiseIA.value,
        limparAnaliseIA: analiseIA.value == null,
        dataAtualizacao: DateTime.now(),
      );

      await _repository.salvarSimulacao(
        calculo: calculoParaSalvar,
        itens: itensCalculados,
      );

      calculoAtual.value = calculoParaSalvar;
      await carregarSimulacoesSalvas();

      Get.snackbar(
        'Simulação salva',
        'O cálculo e a análise inteligente foram salvos com sucesso.',
        backgroundColor: Colors.teal,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível salvar a simulação: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      salvando.value = false;
    }
  }

  Future<void> carregarSimulacoesSalvas() async {
    if (!possuiEventoVinculado) {
      simulacoesSalvas.clear();
      return;
    }

    try {
      carregandoSimulacoes.value = true;
      final simulacoes =
          await _repository.listarSimulacoesPorEvento(idEventoAtual.value);
      simulacoesSalvas.assignAll(simulacoes);
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível carregar as simulações: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      carregandoSimulacoes.value = false;
    }
  }

  Future<List<CalculadoraFestaItemModel>> listarItensDaSimulacao(
      String idCalculo) {
    return _repository.listarItensDaSimulacao(idCalculo);
  }

  /// Aplica uma simulação salva no estado atual da calculadora.
  ///
  /// Uso principal: BottomSheet "Minhas simulações". O usuário abre um cenário
  /// antigo, revisa os itens e pode continuar trabalhando sobre ele.
  Future<void> carregarSimulacaoNoEditor(
      CalculadoraFestaModel simulacao) async {
    try {
      loading.value = true;

      final itens =
          await _repository.listarItensDaSimulacao(simulacao.idCalculo);

      idEventoAtual.value = simulacao.idEvento;
      tipoEventoAtual.value = simulacao.tipoEvento;
      estimativaSemEvento.value = false;
      baseCalculo.value = simulacao.baseCalculo;
      perfilSelecionado.value = simulacao.perfilFesta;
      margemPersonalizada.value = simulacao.margemPersonalizada;
      orcamentoDisponivel.value = simulacao.orcamentoDisponivel;
      totalAdultos.value = _normalizarQuantidade(simulacao.totalAdultos);
      totalCriancas.value = _normalizarQuantidade(simulacao.totalCriancas);
      totalBebes.value = _normalizarQuantidade(simulacao.totalBebes);
      duracaoHoras.value =
          simulacao.duracaoHoras <= 0 ? 4 : simulacao.duracaoHoras;
      calculoAtual.value = simulacao;
      analiseIA.value = simulacao.analiseIA;
      itensCalculados.assignAll(itens);

      // Mantém a estimativa em memória coerente para novas análises de IA.
      estimativaAtual.value = _service.calcularEstimativa(
        calculo: simulacao,
        itensBase: itensEstimativa,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível carregar a simulação: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      loading.value = false;
    }
  }

  Future<void> aprovarSimulacao(String idCalculo) async {
    try {
      await _repository.atualizarStatusSimulacao(
        idCalculo: idCalculo,
        status: StatusSimulacaoCalculadora.aprovada,
      );
      await carregarSimulacoesSalvas();
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível aprovar a simulação: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  Future<void> excluirSimulacao(String idCalculo) async {
    try {
      await _repository.excluirSimulacao(idCalculo);
      simulacoesSalvas.removeWhere((item) => item.idCalculo == idCalculo);

      if (calculoAtual.value?.idCalculo == idCalculo) {
        calculoAtual.value = null;
        itensCalculados.clear();
        estimativaAtual.value = null;
        analiseIA.value = null;
      }

      Get.snackbar(
        'Simulação excluída',
        'A simulação foi removida com sucesso.',
        backgroundColor: Colors.teal,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível excluir a simulação: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  /// Converte uma simulação aprovada em itens oficiais do orçamento.
  ///
  /// Fluxo:
  /// 1. Valida se a simulação pertence a um evento salvo.
  /// 2. Exige status "aprovada" para evitar converter rascunhos por acidente.
  /// 3. Cria/atualiza os itens na coleção de orçamento.
  /// 4. Marca os itens da calculadora como enviados para orçamento.
  /// 5. Marca a simulação como convertida.
  Future<void> transformarSimulacaoEmOrcamento(
      CalculadoraFestaModel simulacao) async {
    if (simulacao.idEvento.trim().isEmpty ||
        simulacao.idEvento == 'estimativa_temporaria') {
      Get.snackbar(
        'Evento não salvo',
        'Salve o evento antes de transformar a simulação em orçamento.',
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }

    if (simulacao.convertidoEmOrcamento ||
        simulacao.statusSimulacao ==
            StatusSimulacaoCalculadora.convertidaOrcamento) {
      Get.snackbar(
        'Simulação já convertida',
        'Esta simulação já foi transformada em orçamento.',
        backgroundColor: Colors.blueGrey,
        colorText: Colors.white,
      );
      return;
    }

    if (simulacao.statusSimulacao != StatusSimulacaoCalculadora.aprovada) {
      Get.snackbar(
        'Aprovação necessária',
        'Aprove a simulação antes de transformar em orçamento.',
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }

    try {
      convertendoOrcamento.value = true;

      final itens =
          await _repository.listarItensDaSimulacao(simulacao.idCalculo);
      final itensPendentes =
          itens.where((item) => !item.adicionadoAoOrcamento).toList();

      if (itensPendentes.isEmpty) {
        await _repository.marcarComoConvertidaEmOrcamento(simulacao.idCalculo);
        await carregarSimulacoesSalvas();

        Get.snackbar(
          'Orçamento já atualizado',
          'Não há novos itens pendentes para adicionar ao orçamento.',
          backgroundColor: Colors.blueGrey,
          colorText: Colors.white,
        );
        return;
      }

      final agora = DateTime.now();
      final idsOrcamentoPorItem =
          await _repository.transformarSimulacaoEmOrcamento(
        simulacao: simulacao,
        itensPendentes: itensPendentes,
      );

      if (calculoAtual.value?.idCalculo == simulacao.idCalculo) {
        calculoAtual.value = calculoAtual.value!.copyWith(
          statusSimulacao: StatusSimulacaoCalculadora.convertidaOrcamento,
          convertidoEmOrcamento: true,
          dataConversaoOrcamento: agora,
          dataAtualizacao: agora,
        );

        final idsConvertidos =
            itensPendentes.map((e) => e.idItemResultado).toSet();
        itensCalculados.assignAll(
          itensCalculados.map((item) {
            if (!idsConvertidos.contains(item.idItemResultado)) return item;

            return item.copyWith(
              adicionadoAoOrcamento: true,
              idOrcamentoGerado: idsOrcamentoPorItem[item.idItemResultado],
              dataAdicionadoAoOrcamento: agora,
            );
          }).toList(),
        );
      }

      await carregarSimulacoesSalvas();

      Get.snackbar(
        'Orçamento criado',
        '${itensPendentes.length} item(ns) foram adicionados ao orçamento do evento.',
        backgroundColor: Colors.teal,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível transformar a simulação em orçamento: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      convertendoOrcamento.value = false;
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
      await _repository.enviarResultadoParaCardapio(
        calculo: calculo,
        itens: itensCalculados.toList(),
        idCardapio: idCardapio,
      );

      itensCalculados.assignAll(
        itensCalculados
            .map((i) => i.copyWith(adicionadoAoCardapio: true))
            .toList(),
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

  void limpar() {
    idEventoAtual.value = '';
    tipoEventoAtual.value = '';
    estimativaSemEvento.value = false;
    baseCalculo.value = BaseCalculoFesta.todosConvidados;
    perfilSelecionado.value = PerfilFestaModel.padrao();
    margemPersonalizada.value = null;
    orcamentoDisponivel.value = null;
    totalAdultos.value = 0;
    totalCriancas.value = 0;
    totalBebes.value = 0;
    totalAdultosEvento.value = 0;
    totalCriancasEvento.value = 0;
    totalBebesEvento.value = 0;
    duracaoHoras.value = 4;
    convidados.clear();
    itensEstimativa.assignAll(CalculadoraFestaService.itensPadraoEstimativa);
    itensCalculados.clear();
    simulacoesSalvas.clear();
    carregandoSimulacoes.value = false;
    convertendoOrcamento.value = false;
    calculoAtual.value = null;
    estimativaAtual.value = null;
    analiseIA.value = null;
    analisandoIA.value = false;
    carregandoItensBase.value = false;
    itensOrigemRemota.value = false;
    origemItensCalculadora.value = OrigemItensCalculadora.fallbackLocal;
    erroItensBase.value = '';
  }

  void _registrarTotaisDoEvento({
    required int adultos,
    required int criancas,
    required int bebes,
    required int totalLegado,
  }) {
    final adultosNormalizados = _normalizarQuantidade(adultos);
    final criancasNormalizadas = _normalizarQuantidade(criancas);
    final bebesNormalizados = _normalizarQuantidade(bebes);
    final totalPorTipo =
        adultosNormalizados + criancasNormalizadas + bebesNormalizados;
    final totalLegadoNormalizado = _normalizarQuantidade(totalLegado);

    // Compatibilidade com eventos antigos que tinham apenas total_convidados:
    // nesse caso, tratamos o total legado como adultos para não zerar a estimativa.
    if (totalPorTipo == 0 && totalLegadoNormalizado > 0) {
      totalAdultosEvento.value = totalLegadoNormalizado;
      totalCriancasEvento.value = 0;
      totalBebesEvento.value = 0;
      return;
    }

    totalAdultosEvento.value = adultosNormalizados;
    totalCriancasEvento.value = criancasNormalizadas;
    totalBebesEvento.value = bebesNormalizados;
  }

  String _normalizarTipoEventoParaConsulta(String value) {
    final slug = _normalizarSlug(value);

    if (slug.isEmpty || slug == 'evento') {
      return '';
    }

    if (slug.contains('cha') && slug.contains('bebe')) {
      return 'cha_de_bebe';
    }

    if (slug.contains('festa') && slug.contains('infantil')) {
      return 'festa_infantil';
    }

    if (slug.contains('aniversario')) {
      return 'aniversario';
    }

    if (slug.contains('formatura')) {
      return 'formatura';
    }

    if (slug.contains('casamento')) {
      return 'casamento';
    }

    if (slug.contains('corporativo') ||
        slug.contains('empresa') ||
        slug.contains('empresarial')) {
      return 'evento_corporativo';
    }

    return slug;
  }

  String _normalizarPerfilFestaParaConsulta() {
    final slug = _normalizarSlug(perfilSelecionado.value.nome);

    if (slug.contains('econom')) {
      return 'economico';
    }

    if (slug.contains('premium') || slug.contains('luxo')) {
      return 'premium';
    }

    if (slug.contains('padrao') ||
        slug.contains('medio') ||
        slug.contains('normal')) {
      return 'padrao';
    }

    return slug.isEmpty ? 'padrao' : slug;
  }

  String _normalizarSlug(String value) {
    var text = value.trim().toLowerCase();

    if (text.isEmpty) {
      return '';
    }

    text = _removerAcentos(text);

    return text
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+'), '')
        .replaceAll(RegExp(r'_+$'), '');
  }

  String _removerAcentos(String value) {
    const accents = {
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

  int _normalizarQuantidade(int value) => value < 0 ? 0 : value;

  String _formatMoney(double value) {
    final normalized = value.toStringAsFixed(2).replaceAll('.', ',');
    final parts = normalized.split(',');
    final integer = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return 'R\$ $integer,${parts.last}';
  }
}
