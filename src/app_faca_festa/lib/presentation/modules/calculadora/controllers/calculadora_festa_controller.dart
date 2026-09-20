import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/domain/services/calculadora_festa_service.dart';
import 'package:app_faca_festa/domain/entities/analise_calculadora_ia.dart';
import 'package:app_faca_festa/domain/entities/calculadora_evento_item.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa_item.dart';
import 'package:app_faca_festa/domain/entities/convidado.dart';
import 'package:app_faca_festa/domain/entities/convidados_equivalentes.dart';
import 'package:app_faca_festa/domain/entities/estimativa_financeira.dart';
import 'package:app_faca_festa/domain/entities/perfil_festa.dart';
import 'package:app_faca_festa/domain/repositories/calculadora_festa_repository.dart';
import 'package:app_faca_festa/domain/repositories/calculadora_itens_base_repository_contract.dart';
import 'package:app_faca_festa/domain/services/calculadora_festa_ai_service.dart';

part 'calculadora_festa_analise_ia.dart';
part 'calculadora_festa_historico.dart';

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
    required ICalculadoraFestaAIService aiService,
    required CalculadoraFestaRepository repository,
    required CalculadoraItensBaseRepositoryContract itensBaseRepository,
  })  : _service = service ?? const CalculadoraFestaService(),
        _aiService = aiService,
        _repository = repository,
        _itensBaseRepository = itensBaseRepository;

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
  final Rx<PerfilFesta> perfilSelecionado = PerfilFesta.padrao().obs;

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

  final RxList<Convidado> convidados = <Convidado>[].obs;
  final RxList<ItemEstimativaFinanceira> itensEstimativa =
      CalculadoraFestaService.itensPadraoEstimativa.toList().obs;
  final RxList<CalculadoraFestaItem> itensCalculados =
      <CalculadoraFestaItem>[].obs;
  final RxList<CalculadoraFesta> simulacoesSalvas = <CalculadoraFesta>[].obs;
  final RxBool carregandoSimulacoes = false.obs;

  final Rxn<CalculadoraFesta> calculoAtual = Rxn<CalculadoraFesta>();
  final Rxn<EstimativaFinanceira> estimativaAtual = Rxn<EstimativaFinanceira>();
  final Rxn<AnaliseCalculadoraIA> analiseIA = Rxn<AnaliseCalculadoraIA>();

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

  ConvidadosEquivalentes get convidadosEquivalentes => ConvidadosEquivalentes(
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
    perfilSelecionado.value = PerfilFesta.fromTipo(perfilInicial);
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
      perfilSelecionado.value = PerfilFesta.padrao();
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
    itensEstimativa.assignAll(
      CalculadoraFestaService.itensPadraoEstimativa,
    );

    debugPrint(
      '[CalculadoraFestaController] $motivo '
      'Usando fallback local: CalculadoraFestaService.itensPadraoEstimativa.',
    );

    if (recalcularAposCarregar) {
      calcular();
    }
  }

  ItemEstimativaFinanceira _converterItemEventoParaEstimativa(
    CalculadoraEventoItem item,
  ) {
    final selecionado = item.obrigatorio || item.selecionadoPadrao;

    return ItemEstimativaFinanceira(
      id: item.id,
      categoria: item.categoria,
      nome: item.nome,
      tipoItem: item.idItemBase.trim().isNotEmpty
          ? item.idItemBase
          : _normalizarSlug(item.nome),
      publicoAlvo: item.publicoAlvo,
      unidade: _unidadeEstimativaFromString(item.unidade),
      quantidadePorConvidadoEquivalente: item.quantidadePorConvidadoEquivalente,
      valorUnitarioMedio: item.valorUnitarioMedio,
      selecionado: selecionado,
    );
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
    Iterable<Convidado> base = convidados;

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
    perfilSelecionado.value = PerfilFesta.fromTipo(tipo);
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

    final calculoBase = CalculadoraFesta(
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
      idUsuario: calculoAtual.value?.idUsuario ?? _uidAtual,
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

  void limpar() {
    idEventoAtual.value = '';
    tipoEventoAtual.value = '';
    estimativaSemEvento.value = false;
    baseCalculo.value = BaseCalculoFesta.todosConvidados;
    perfilSelecionado.value = PerfilFesta.padrao();
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
    itensEstimativa.assignAll(
      CalculadoraFestaService.itensPadraoEstimativa,
    );
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

  String? get _uidAtual {
    if (Get.isRegistered<FirebaseAuth>()) {
      return Get.find<FirebaseAuth>().currentUser?.uid;
    }
    return FirebaseAuth.instance.currentUser?.uid;
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

  UnidadeEstimativa _unidadeEstimativaFromString(String? value) {
    final normalized = value?.trim().toLowerCase() ?? '';

    return UnidadeEstimativa.values.firstWhere(
      (item) =>
          item.name.toLowerCase() == normalized ||
          item.label.toLowerCase() == normalized,
      orElse: () => UnidadeEstimativa.unidade,
    );
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
