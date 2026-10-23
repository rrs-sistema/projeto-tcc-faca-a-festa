import 'package:app_faca_festa/domain/entities/ocorrencia_servico.dart';
import 'package:app_faca_festa/domain/entities/referencia_contextual.dart';
import 'package:app_faca_festa/domain/entities/contexto_servico_planejador.dart';
import 'package:app_faca_festa/domain/services/planejador_hibrido_service.dart';
import 'package:app_faca_festa/domain/repositories/planejador_hibrido_repository.dart';
import 'package:app_faca_festa/domain/repositories/catalogo_contextual_repository.dart';
import 'package:app_faca_festa/domain/services/agenda_servico_service.dart';
import 'package:uuid/uuid.dart';
import 'package:app_faca_festa/domain/entities/confirmacao_configuracao_calculadora.dart';
import 'package:app_faca_festa/domain/services/publico_planejamento_service.dart';
import 'package:app_faca_festa/domain/repositories/vinculo_rascunho_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_faca_festa/domain/entities/contexto_planejamento_evento.dart';
import 'package:app_faca_festa/domain/repositories/entrada_assistente_calculadora_repository.dart';
import 'package:app_faca_festa/domain/services/comando_texto_calculadora_service.dart';
import 'package:app_faca_festa/domain/services/memoria_calculadora_service.dart';
import 'package:app_faca_festa/domain/repositories/memoria_calculadora_repository.dart';
import 'package:app_faca_festa/domain/repositories/execucao_calculadora_repository.dart';
import 'package:app_faca_festa/domain/services/plano_execucao_service.dart';
import 'package:app_faca_festa/domain/services/criacao_cardapio_inicial_service.dart';
import 'package:app_faca_festa/domain/services/plano_evento_service.dart';
import 'package:app_faca_festa/domain/entities/evento.dart';
import 'package:app_faca_festa/domain/entities/rascunho_calculadora.dart';
import 'package:app_faca_festa/domain/services/operacao_calculadora_service.dart';
import 'package:app_faca_festa/domain/services/proposta_refeicao_service.dart';
import 'package:app_faca_festa/domain/services/resumo_compras_service.dart';
import 'package:app_faca_festa/domain/services/analise_refeicao_service.dart';
import 'package:app_faca_festa/domain/services/medicao_uso_calculadora.dart';
import 'package:app_faca_festa/domain/entities/disponibilidade_cardapio.dart';
import 'package:app_faca_festa/domain/services/lista_compras_calculadora_service.dart';
import 'package:app_faca_festa/domain/entities/cardapio.dart';
import 'package:app_faca_festa/domain/services/composicao_refeicao_service.dart';
import 'package:app_faca_festa/domain/services/diagnostico_calculadora_service.dart';
import 'package:app_faca_festa/domain/services/consumo_observado_service.dart';
import 'package:app_faca_festa/domain/entities/registro_consumo_calculadora.dart';
import 'dart:async';
import 'dart:convert';
import 'package:app_faca_festa/domain/entities/cardapio_item.dart';
import 'package:app_faca_festa/domain/services/revisao_cardapio_service.dart';
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

part 'calculadora_festa_publico.dart';
part 'calculadora_festa_configuracao.dart';
part 'calculadora_festa_agenda.dart';
part 'calculadora_festa_catalogo.dart';
part 'calculadora_festa_planejador.dart';
part 'calculadora_festa_operacao.dart';
part 'calculadora_festa_personalizacao.dart';
part 'calculadora_festa_entrada.dart';
part 'calculadora_festa_execucao.dart';
part 'calculadora_festa_proposta.dart';
part 'calculadora_festa_analise_ia.dart';
part 'calculadora_festa_historico.dart';

enum OrigemItensCalculadora {
  firestore,
  indisponivel,
  semConfiguracao,
  simulacao,
}

extension OrigemItensCalculadoraExtension on OrigemItensCalculadora {
  String get label {
    switch (this) {
      case OrigemItensCalculadora.firestore:
        return 'Firestore';
      case OrigemItensCalculadora.simulacao:
        return 'Simulação salva';
      case OrigemItensCalculadora.semConfiguracao:
        return 'Sem configuração';
      case OrigemItensCalculadora.indisponivel:
        return 'Base indisponível';
    }
  }
}

class CalculadoraFestaController extends GetxController {
  final catalogoContextual = CatalogoContextual.indisponivel.obs;
  final carregandoCatalogo = false.obs;
  int _consultaCatalogo = 0;
  final RxList<Map<String, dynamic>> _memoriasReceitas =
      <Map<String, dynamic>>[].obs;
  String? _donoMemoria;
  final Map<String, String> _regrasExecucaoRecebidas = {};
  String _eventoRegrasExecucao = '';
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

  final estadoConvidados = EstadoFontePlanejamento.naoConsultada.obs;
  final estadoEvento = EstadoFontePlanejamento.naoConsultada.obs;
  final avisoContexto = ''.obs;
  final escritaContextoPendente = false.obs;
  final consultaOperacaoIniciada = false.obs;
  final consultaFinanceiroIniciada = false.obs;
  String _idRascunhoContexto = '';
  String _revisaoEvento = '';
  String _revisaoPeriodo = '';
  final estadoCardapios = EstadoFontePlanejamento.naoConsultada.obs;

  ContextoPlanejamentoEvento get contextoEvento {
    FontePlanejamento fonte(
            EstadoFontePlanejamento estado, String origem, Object revisao) =>
        FontePlanejamento(estado, origem: origem, revisao: revisao.toString());
    if (usandoContextoHistorico.value) {
      final snapshot = calculoAtual.value;
      return ContextoPlanejamentoEvento(
          usuario: snapshot?.idUsuario ?? '',
          evento: snapshot?.idEvento ?? '',
          rascunho: '',
          geracao: _versaoPreparacao,
          historico: true,
          fontes: {
            for (final nome in [
              'evento',
              'publico',
              'regras',
              'cardapios',
              'operacao',
              'financeiro'
            ])
              nome: fonte(EstadoFontePlanejamento.disponivel, 'simulacao salva',
                  snapshot?.dataAtualizacao.toIso8601String() ?? ''),
          });
    }
    final local = estimativaSemEvento.value;
    return ContextoPlanejamentoEvento(
        usuario: _uidAtual ?? '',
        evento: idEventoAtual.value,
        rascunho: _idRascunhoContexto,
        geracao: _versaoPreparacao,
        historico: usandoContextoHistorico.value,
        fontes: {
          'evento': fonte(
              local ? EstadoFontePlanejamento.disponivel : estadoEvento.value,
              local ? 'rascunho' : 'evento',
              _revisaoEvento),
          'publico': fonte(
              baseCalculo.value == BaseCalculoFesta.manual
                  ? EstadoFontePlanejamento.disponivel
                  : baseCalculo.value == BaseCalculoFesta.previstos
                      ? publicoPlanejado.idades != null
                          ? EstadoFontePlanejamento.disponivel
                          : publicoPlanejado.total != null
                              ? EstadoFontePlanejamento.desatualizada
                              : EstadoFontePlanejamento.naoConsultada
                      : estadoConvidados.value,
              baseCalculo.value.name,
              '$totalAdultos/$totalCriancas/$totalBebes'),
          'regras': fonte(
              carregandoItensBase.value
                  ? EstadoFontePlanejamento.carregando
                  : erroItensBase.value.isNotEmpty
                      ? EstadoFontePlanejamento.erro
                      : regrasDisponiveis.isEmpty
                          ? EstadoFontePlanejamento.vazia
                          : EstadoFontePlanejamento.disponivel,
              origemItensCalculadora.value.name,
              assinaturaExecucao(
                  regrasDisponiveis.map((r) => r.toPlanejamento()).toList())),
          'cardapios': fonte(
              local ? EstadoFontePlanejamento.vazia : estadoCardapios.value,
              'cardapios/itens',
              assinaturaExecucao({
                for (final e in cardapiosEvento.entries)
                  e.key: e.value.map(_serializarItem).toList()
              })),
          'operacao': fonte(
              escritaContextoPendente.value
                  ? EstadoFontePlanejamento.escritaPendente
                  : !consultaOperacaoIniciada.value && !local
                      ? EstadoFontePlanejamento.naoConsultada
                      : local
                          ? EstadoFontePlanejamento.vazia
                          : erroOperacao.value.isNotEmpty
                              ? EstadoFontePlanejamento.erro
                              : !operacaoCarregada.value
                                  ? EstadoFontePlanejamento.carregando
                                  : EstadoFontePlanejamento.disponivel,
              'calculadora_operacao',
              operacaoEvento['revisao'] ?? 0),
          'financeiro': fonte(
              !consultaFinanceiroIniciada.value && !local
                  ? EstadoFontePlanejamento.naoConsultada
                  : local
                      ? EstadoFontePlanejamento.vazia
                      : carregandoOrcamento.value
                          ? EstadoFontePlanejamento.carregando
                          : erroOrcamento.value.isNotEmpty
                              ? EstadoFontePlanejamento.erro
                              : EstadoFontePlanejamento.disponivel,
              'orcamentos',
              assinaturaExecucao(compromissosOrcamento)),
        });
  }

  void sincronizarEvento(Evento evento, {bool aceitarPeriodo = false}) {
    if (usandoContextoHistorico.value ||
        evento.idEvento != idEventoAtual.value ||
        evento.idUsuario != _uidAtual) {
      return;
    }
    final revisao = assinaturaExecucao([
      evento.totalAdultosCalculado,
      evento.totalCriancasCalculado,
      evento.totalBebesCalculado,
      evento.totalConvidadosCalculado,
      evento.custoEstimado,
      evento.data.toIso8601String(),
      evento.dataFim?.toIso8601String(),
      evento.hora
    ]);
    final periodo = assinaturaExecucao([
      evento.data.toIso8601String(),
      evento.dataFim?.toIso8601String(),
      evento.hora
    ]);
    final mudouPeriodo =
        _revisaoPeriodo.isNotEmpty && _revisaoPeriodo != periodo;
    _revisaoPeriodo = periodo;
    if (aceitarPeriodo) {
      estadoEvento.value = EstadoFontePlanejamento.disponivel;
      avisoContexto.value = '';
    } else if (mudouPeriodo) {
      estadoEvento.value = EstadoFontePlanejamento.desatualizada;
    } else if (estadoEvento.value != EstadoFontePlanejamento.desatualizada) {
      estadoEvento.value = EstadoFontePlanejamento.disponivel;
    }
    if (_revisaoEvento == revisao) {
      if (aceitarPeriodo) calcular();
      return;
    }
    final anterior = _revisaoEvento;
    _revisaoEvento = revisao;
    _registrarTotaisDoEvento(
        adultos: evento.totalAdultosCalculado,
        criancas: evento.totalCriancasCalculado,
        bebes: evento.totalBebesCalculado,
        totalLegado: evento.totalConvidadosCalculado,
        informada: evento.previsaoPublicoInformada,
        idadesInformadas: evento.distribuicaoPublicoInformada);
    orcamentoDisponivel.value = evento.custoEstimado;
    if (baseCalculo.value == BaseCalculoFesta.previstos) {
      aplicarTotaisDoCadastroDoEvento();
    }
    if (anterior.isNotEmpty) {
      avisoContexto.value =
          'Os dados da festa mudaram. A projeção foi recalculada; revise antes de confirmar.';
    }
    if (mudouPeriodo) {
      avisoContexto.value =
          'O período da festa mudou. Atualize os dados e confira a duração antes de continuar.';
    }
    calcular();
  }

  final RxMap<String, dynamic> operacaoEvento = <String, dynamic>{}.obs;
  final _previsaoTotal = RxnInt();
  bool _previsaoIdadesConhecidas = true;
  final completudeLista = CompletudeLista.desconhecida.obs;
  final estadoConfiguracao = EstadoConfirmacaoConfiguracao.editando.obs;
  final mensagemConfiguracao = ''.obs;
  final Set<String> _camposConfiguracaoEditados = {};
  Future<void>? _restauracaoCatalogo;
  Map<String, dynamic> _configuracaoConfirmada = {};
  final basePublicoConfirmada = false.obs;
  final avisoPublico = ''.obs;
  bool _baseLocalAlterada = false;
  String _politicaPublicoRecebida = '';
  final RxBool operacaoCarregada = true.obs;
  final RxString erroOperacao = ''.obs;
  StreamSubscription<Map<String, dynamic>>? _operacaoSubscription;
  int _versaoOperacao = 0;

  final RxBool loading = false.obs;
  final RxBool salvando = false.obs;
  final RxBool enviandoParaCardapio = false.obs;
  final RxBool convertendoOrcamento = false.obs;
  final RxBool analisandoIA = false.obs;
  final RxBool carregandoItensBase = false.obs;
  final RxBool salvandoConsumo = false.obs;

  String contextoConsumo(ItemEstimativaFinanceira regra,
          {int? duracaoObservada}) =>
      const ConsumoObservadoService().contexto(regra, itensParaCalculo,
          servicoPlanejador: dimensoesConsumoPlanejador,
          duracaoHoras: duracaoObservada ?? duracaoHoras.value,
          publicoDietario: restricoesDoItem(regra),
          gruposAlimentares: OperacaoCalculadoraService.lista(
              const OperacaoCalculadoraService().refeicao(
                  Map<String, dynamic>.from(operacaoEvento),
                  _cardapioConsolidadoAtual)['grupos']),
          refeicao: tituloCardapio,
          tipoEvento: tipoEventoAtual.value,
          itensSemRegra: itensSemRegra.map((i) =>
              RevisaoCardapioService.identidade(
                  i.nome, i.unidade, i.publicoAlvo.name)));

  Future<List<ItemEstimativaFinanceira>> consultarReceitasSalvas() =>
      _repository.listarReceitasDoOrganizador();

  Future<List<RegistroConsumoCalculadora>> consultarConsumos() =>
      _repository.listarConsumosDoOrganizador();

  Future<void> registrarConsumo(RegistroConsumoCalculadora registro) async {
    registro.validar();
    final calculo = calculoAtual.value;
    if (salvandoConsumo.value ||
        loading.value ||
        calculo == null ||
        !possuiEventoVinculado ||
        registro.idEvento != calculo.idEvento ||
        registro.contexto !=
            contextoConsumo(registro.regra,
                duracaoObservada: registro.duracaoHoras)) {
      throw StateError(
          'Selecione um evento e confira o contexto antes de registrar o consumo.');
    }
    final snapshot = calculo.copyWith(
        contextoPlanejamento: snapshotPlanejamento,
        idUsuario: calculo.idUsuario ?? _uidAtual);
    final itens = itensCalculados.toList();
    try {
      salvandoConsumo.value = true;
      await _repository.salvarSimulacao(calculo: snapshot, itens: itens);
      await _repository.registrarConsumo(snapshot.idCalculo, registro);
      medicaoUso.consumosRegistrados++;
      await carregarSimulacoesSalvas();
    } finally {
      salvandoConsumo.value = false;
    }
  }

  ResumoConsumoObservado resumirConsumo(ItemEstimativaFinanceira regra,
          List<RegistroConsumoCalculadora> registros) =>
      const ConsumoObservadoService().resumir(
          registros: registros,
          contexto: contextoConsumo(regra),
          eventoAtual: idEventoAtual.value,
          pessoas: convidadosEquivalentes);

  void adotarConsumoObservado(
      ItemEstimativaFinanceira regra, ResumoConsumoObservado resumo) {
    adicionarItemManual(const ConsumoObservadoService().aplicar(regra, resumo));
  }

  final RxBool itensOrigemRemota = false.obs;
  final Rx<OrigemItensCalculadora> origemItensCalculadora =
      OrigemItensCalculadora.indisponivel.obs;
  final RxString erroItensBase = ''.obs;
  final RxString erroAnaliseIA = ''.obs;
  final RxBool revisarCardapio = false.obs;
  final RxBool usandoContextoHistorico = false.obs;
  final RxList<CardapioItem> itensCardapio = <CardapioItem>[].obs;
  final RxList<ItemEstimativaFinanceira> regrasManuais =
      <ItemEstimativaFinanceira>[].obs;
  final RxList<Map<String, dynamic>> compromissosOrcamento =
      <Map<String, dynamic>>[].obs;
  final RxString erroOrcamento = ''.obs;
  final RxBool carregandoOrcamento = false.obs;
  final RxBool cardapioDisponivel = false.obs;
  String tituloCardapio = '';
  bool _modoEscolhido = false;
  final _revisao = const RevisaoCardapioService();

  List<ItemEstimativaFinanceira> get regrasDisponiveis => {
        for (final item in [
          ...itensEstimativa,
          ...regrasDaMemoria,
          ...regrasManuais
        ])
          item.id: item
      }.values.toList();
  List<CardapioItem> get itensSemRegra => revisarCardapio.value
      ? itensCardapio
          .where((item) => _revisao.regraPara(item, regrasDisponiveis) == null)
          .toList()
      : [];
  List<ItemEstimativaFinanceira> get itensParaCalculo => revisarCardapio.value
      ? itensCardapio
          .map((item) => _revisao.regraPara(item, regrasDisponiveis))
          .whereType<ItemEstimativaFinanceira>()
          .map(regraDoPublico)
          .toList()
      : regrasDisponiveis
          .where((item) =>
              !regrasManuais.contains(item) || !item.id.startsWith('menu_'))
          .toList();
  ItemEstimativaFinanceira? regraDoResultado(CalculadoraFestaItem resultado) {
    final prefixo = '${resultado.idCalculo}_';
    final id = resultado.idItemResultado.startsWith(prefixo)
        ? resultado.idItemResultado.substring(prefixo.length)
        : resultado.idItemResultado;
    for (final regra
        in const ComposicaoRefeicaoService().compor(itensParaCalculo)) {
      if (regra.id == id) return regra;
    }
    return null;
  }

  final RxMap<String, List<CardapioItem>> cardapiosEvento =
      <String, List<CardapioItem>>{}.obs;
  final RxMap<String, String> titulosCardapiosEvento = <String, String>{}.obs;
  final Map<String, EscopoCardapio> escoposCardapiosEvento = {};
  final RxBool consultaCardapiosCompleta = true.obs;

  void atualizarCardapiosEvento(
      Map<String, List<CardapioItem>> itens, Map<String, String> titulos,
      {required bool completo,
      Map<String, EscopoCardapio> escopos = const {}}) {
    if (usandoContextoHistorico.value) {
      return;
    }
    escoposCardapiosEvento
      ..clear()
      ..addAll(escopos);
    cardapiosEvento.assignAll(itens);
    titulosCardapiosEvento.assignAll(titulos);
    consultaCardapiosCompleta.value = completo;
    _agendarAnaliseIA();
  }

  String get _cardapioConsolidadoAtual => idCardapioAtual.isNotEmpty
      ? idCardapioAtual
      : (itensCardapio.isEmpty ? '' : itensCardapio.first.idCardapio);
  List<CardapioItem> get itensSemRegraEvento => [
        ...itensSemRegra,
        for (final e in cardapiosEvento.entries
            .where((e) => e.key != _cardapioConsolidadoAtual))
          ...e.value
              .where((i) => _revisao.regraPara(i, regrasDisponiveis) == null)
      ];

  List<ItemListaCompras> get listaComprasEvento =>
      listaComprasEventoComResultados(itensCalculados.toList());
  List<ItemListaCompras> listaComprasEventoComResultados(
      List<CalculadoraFestaItem> atuais) {
    final atual = calculoAtual.value;
    if (atual == null) return [];
    final lista = listaComprasDosResultados(atuais);
    for (final e in cardapiosEvento.entries
        .where((e) => e.key != _cardapioConsolidadoAtual)) {
      final regras = const ComposicaoRefeicaoService().compor(e.value
          .map((i) => _revisao.regraPara(i, regrasDisponiveis))
          .whereType<ItemEstimativaFinanceira>()
          .map(regraDoPublico)
          .toList());
      final resultados = _service.calcularItens(
          calculo: calculoDaRefeicao(atual, e.key), itensBase: regras);
      for (final resultado in resultados) {
        final candidatas = regras.where(
            (r) => resultado.idItemResultado == '${atual.idCalculo}_${r.id}');
        lista.add(analisarCompra(resultado,
            candidatas.length == 1 ? candidatas.single : null, e.value, e.key));
      }
    }
    return lista;
  }

  final medicaoUso = MedicaoUsoCalculadora();
  ResumoCompras get resumoCompras => const ResumoComprasService().calcular(
      itens: listaComprasEvento,
      compromissos: compromissosOrcamento.toList(),
      semRegra: itensSemRegraEvento.length +
          cardapiosEvento.values.where((i) => i.isEmpty).length,
      consultaCompleta: publicoPlanejado.idades != null &&
          erroOrcamento.value.isEmpty &&
          !carregandoOrcamento.value &&
          consultaCardapiosCompleta.value &&
          operacaoCarregada.value &&
          erroOperacao.value.isEmpty &&
          revisarCardapio.value,
      limite: orcamentoDisponivel.value);
  bool get representaRefeicao =>
      escopoCardapioAtual == EscopoCardapio.refeicao ||
      escopoCardapioAtual == EscopoCardapio.naoDefinido;
  AnaliseRefeicao get analiseRefeicao {
    final base = const AnaliseRefeicaoService().analisar(itensParaCalculo,
        refeicao: tituloCardapio,
        servico: const AgendaServicoService()
                    .porCardapio(Map.of(operacaoEvento), idCardapioAtual) ==
                null
            ? null
            : (const OperacaoCalculadoraService().refeicao(
                        Map.of(operacaoEvento), idCardapioAtual)['servico']
                    as String?) ??
                'nao_definido',
        avaliarComposicao: escopoCardapioAtual == EscopoCardapio.refeicao ||
            escopoCardapioAtual == EscopoCardapio.naoDefinido,
        adultos: convidadosEquivalentes.adultos,
        criancas: convidadosEquivalentes.criancas,
        bebes: convidadosEquivalentes.bebes);
    return AnaliseRefeicao(
        base.principais, base.acompanhamentos, base.bebidas, [
      ...base.pendencias,
      ...pendenciasAlimentares(_cardapioConsolidadoAtual, itensParaCalculo)
    ]);
  }

  List<ItemListaCompras> get listaCompras =>
      listaComprasDosResultados(itensCalculados.toList());
  List<ItemListaCompras> listaComprasDosResultados(
          List<CalculadoraFestaItem> resultados) =>
      resultados
          .map((r) => analisarCompra(r, regraDoResultado(r),
              itensCardapio.toList(), _cardapioConsolidadoAtual))
          .toList();
  List<CalculadoraFestaItem> simularReserva(double reserva) {
    final atual = calculoAtual.value;
    if (atual == null || !reserva.isFinite || reserva < 0 || reserva > .3) {
      return [];
    }
    return _service.calcularItens(
        calculo: atual.copyWith(margemPersonalizada: reserva),
        itensBase: const ComposicaoRefeicaoService().compor(itensParaCalculo));
  }

  String? faixaDoResultado(CalculadoraFestaItem resultado) {
    final r = regraDoResultado(resultado);
    final minimo = r?.premissas['consumo_min'],
        maximo = r?.premissas['consumo_max'];
    if (r == null ||
        minimo is! num ||
        maximo is! num ||
        !minimo.isFinite ||
        !maximo.isFinite ||
        minimo <= 0 ||
        maximo <= minimo) {
      return null;
    }
    double quantidade(num valor) => r
        .copyWith(quantidadePorConvidadoEquivalente: valor.toDouble())
        .calcularQuantidadeArredondada(
            convidados: convidadosEquivalentes,
            perfil: perfilSelecionado.value,
            duracaoHoras: duracaoHoras.value,
            margemPersonalizada: margemPersonalizada.value);
    return 'Faixa da referência: ${quantidade(minimo).toStringAsFixed(2).replaceAll('.', ',')}–'
        '${quantidade(maximo).toStringAsFixed(2).replaceAll('.', ',')} ${r.unidade.label}, com reserva. '
        'Não é um intervalo estatístico.';
  }

  DiagnosticoCalculadora get diagnosticoPlanejamento =>
      const DiagnosticoCalculadoraService().analisar(
          avaliarComposicao: representaRefeicao,
          pessoas: convidadosEquivalentes.totalInformado,
          cardapio: itensCardapio.toList(),
          regras: regrasDisponiveis);

  bool get coberturaFinanceiraIncompleta => compromissosOrcamento
      .any((gasto) => gasto['cobertura_identificavel'] == false);

  bool get podeTentarCarregarBase =>
      origemItensCalculadora.value == OrigemItensCalculadora.indisponivel &&
      erroItensBase.value.isNotEmpty;

  final RxList<String> regrasRejeitadas = <String>[].obs;

  bool get estimativaIncompleta =>
      regrasRejeitadas.isNotEmpty ||
      itensParaCalculo.any((r) => r.premissas['unidade_original'] != null) ||
      itensSemRegra.isNotEmpty ||
      !resumoCompras.completo;

  EscopoCardapio escopoCardapioAtual = EscopoCardapio.naoDefinido;
  void atualizarCardapio(List<CardapioItem> itens,
      {required String titulo,
      required bool disponivel,
      EscopoCardapio escopo = EscopoCardapio.naoDefinido}) {
    escopoCardapioAtual = escopo;
    itensCardapio.assignAll(itens);
    tituloCardapio = titulo;
    idCardapioAtual =
        itens.isNotEmpty ? itens.first.idCardapio : idCardapioAtual;
    cardapioDisponivel.value = disponivel;
    if (!_modoEscolhido &&
        disponivel &&
        itens.isNotEmpty &&
        origemItensCalculadora.value != OrigemItensCalculadora.simulacao) {
      revisarCardapio.value = true;
    }
    if (revisarCardapio.value) {
      calcular();
    } else {
      _agendarAnaliseIA();
    }
  }

  void alterarModoCardapio(bool revisar) {
    _modoEscolhido = true;
    revisarCardapio.value = revisar;
    calcular();
  }

  String idCardapioAtual = '';
  Map<String, dynamic> _serializarItem(CardapioItem i) => {
        'id': i.idItem,
        'evento': i.idEvento,
        'cardapio': i.idCardapio,
        'nome': i.nome,
        'tipo': i.tipo.name,
        'publico': i.publicoAlvo.name,
        'unidade': i.unidade,
        'final': i.quantidadeFinal,
        'sugerida': i.quantidadeSugerida,
        'confirmado': i.confirmado,
        'disponibilidade': i.disponibilidade?.toMap()
      };
  CardapioItem restaurarItem(Map<String, dynamic> i) => CardapioItem(
      idItem: i['id'] as String,
      idEvento: i['evento'] as String,
      idCardapio: i['cardapio'] as String,
      nome: i['nome'] as String,
      tipo: TipoItemCardapio.fromString(i['tipo'] as String),
      publicoAlvo: PublicoAlvoCardapio.fromString(i['publico'] as String),
      unidade: i['unidade'] as String,
      quantidadeFinal: (i['final'] as num).toDouble(),
      quantidadeSugerida: (i['sugerida'] as num).toDouble(),
      confirmado: i['confirmado'] == true,
      disponibilidade: DisponibilidadeCardapio.fromMap(i['disponibilidade']));

  Map<String, dynamic> get snapshotPlanejamento => {
        'catalogo_contextual': catalogoContextual.value.snapshot,
        'politica_publico': {
          'base_confirmada': basePublicoConfirmada.value,
          'lista_completude': completudeLista.value.valor,
          'previstos_total': previsaoPublico.total,
          'idades_informadas': _previsaoIdadesConhecidas
        },
        'verba_alimentacao': verbaAlimentacao.value,
        'operacao': Map<String, dynamic>.from(operacaoEvento),
        'publico_evento': {
          'adultos': totalAdultos.value,
          'criancas': totalCriancas.value,
          'bebes': totalBebes.value
        },
        'versao_motor': 6,
        'cardapios_evento': {
          for (final e in cardapiosEvento.entries)
            e.key: e.value.map(_serializarItem).toList()
        },
        'titulos_cardapios_evento':
            Map<String, String>.from(titulosCardapiosEvento),
        'consulta_cardapios_completa': consultaCardapiosCompleta.value,
        'modo_revisao': revisarCardapio.value,
        'id_cardapio': idCardapioAtual,
        'titulo_cardapio': tituloCardapio,
        'escopo_cardapio': escopoCardapioAtual.name,
        'cardapio_disponivel': cardapioDisponivel.value,
        'regras': regrasDisponiveis.map((r) => r.toPlanejamento()).toList(),
        'regras_catalogo':
            itensEstimativa.map((r) => r.toPlanejamento()).toList(),
        'regras_manuais': regrasManuais.map((r) => r.toPlanejamento()).toList(),
        'regras_rejeitadas': regrasRejeitadas.toList(),
        'cardapio': itensCardapio
            .map((i) => {
                  'id': i.idItem,
                  'evento': i.idEvento,
                  'cardapio': i.idCardapio,
                  'nome': i.nome,
                  'tipo': i.tipo.name,
                  'publico': i.publicoAlvo.name,
                  'unidade': i.unidade,
                  'final': i.quantidadeFinal,
                  'sugerida': i.quantidadeSugerida,
                  'confirmado': i.confirmado,
                  'disponibilidade': i.disponibilidade?.toMap(),
                })
            .toList(),
        'financeiro': contextoPlanejamento,
        'compromissos': compromissosOrcamento.toList(),
      };

  Future<void> conferirCusto(Map<String, dynamic> gasto, String modo) async {
    if (usandoContextoHistorico.value) throw StateError('Atualize a festa.');
    await _repository.salvarConferenciaFinanceira(gasto['id'] as String, {
      'modo': modo,
      'valor': gasto['valor'],
      'identidade': gasto['identidade'],
      'coberturas': List<String>.from(gasto['cobre_itens'] as List? ?? [])
    });
    await carregarContextoOrcamento();
  }

  Future<void> definirCobertura(String id, List<String> identidades) async {
    await _repository.salvarCoberturaOrcamento(id, identidades);
    await carregarContextoOrcamento();
  }

  Map<String, dynamic> get contextoPlanejamento {
    final resumo = resumoCompras;
    final gastos = resumo.orcado;
    final novos = resumo.custoConhecido;
    return {
      'fonte_publico': usandoTotaisDoCadastroDoEvento
          ? 'previstos_cadastro'
          : baseCalculo.value.name,
      'modo': revisarCardapio.value ? 'revisar_cardapio' : 'estimar_do_zero',
      'versao_motor': 6,
      'regras_em_uso': const ComposicaoRefeicaoService()
          .compor(itensParaCalculo)
          .where((r) => r.selecionado)
          .map((r) => r.toPlanejamento())
          .toList(),
      'cardapio': tituloCardapio,
      'escopo_cardapio': escopoCardapioAtual.name,
      'cardapio_disponivel': cardapioDisponivel.value,
      'itens_cardapio': itensCardapio
          .map((item) => {
                'nome': item.nome,
                'tipo': item.tipo.name,
                'publico_alvo': item.publicoAlvo.name,
                'unidade': item.unidade,
                'quantidade_planejada': item.quantidadeFinal,
                'confirmado': item.confirmado,
              })
          .toList(),
      'itens_sem_regra': itensSemRegra.map((item) => item.nome).toList(),
      'estimativa_incompleta':
          estimativaIncompleta || coberturaFinanceiraIncompleta,
      'cobertura_financeira_incompleta': coberturaFinanceiraIncompleta,
      'orcamento_carregado': erroOrcamento.value.isEmpty &&
          !carregandoOrcamento.value &&
          consultaCardapiosCompleta.value &&
          operacaoCarregada.value &&
          erroOperacao.value.isEmpty &&
          revisarCardapio.value,
      'gastos_existentes': gastos,
      'total_pago': compromissosOrcamento.fold<double>(
          0, (s, g) => s + ((g['pago'] as num?)?.toDouble() ?? 0)),
      'total_contratado': compromissosOrcamento
          .where((g) => g['contratado'] == true)
          .fold<double>(0, (s, g) => s + ((g['valor_contratado']??g['valor']) as num).toDouble()),
      'compras_restantes': resumo.toMap(),
      'escopo_financeiro': 'evento',
      'cardapios_considerados': titulosCardapiosEvento.values.toList(),
      'premissa_publico_refeicoes':
          'Público configurado por refeição; na ausência de configuração, usa o público da festa.',
      'analise_refeicao': analiseRefeicao.pendencias,
      'operacao': Map<String, dynamic>.from(operacaoEvento),
      'pendencias_alimentares': pendenciasAlimentaresEvento,
      'custo_adicional_estimado': novos,
      'custo_projetado': gastos + novos,
      'limite_total': orcamentoDisponivel.value,
      'saldo_apos_planejamento': resumo.saldoAposCompras,
      'estado_planejamento': {
        'quantidades_calculadas':
            itensSemRegra.isEmpty && itensCalculados.isNotEmpty,
        'compras_definidas': resumo.quantidadesPendentes == 0,
        'financeiro_completo': resumo.completo,
        'refeicao_revisada': !analiseRefeicao.precisaRevisar &&
            pendenciasAlimentaresEvento.isEmpty,
      },
    };
  }

  Future<void> carregarContextoOrcamento() async {
    consultaFinanceiroIniciada.value = true;
    final usuario = _uidAtual;
    final versao = ++_versaoOrcamento;
    final anterior = _orcamentoSubscription;
    _orcamentoSubscription = null;
    await anterior?.cancel();
    if (versao != _versaoOrcamento) return;
    final evento = idEventoAtual.value;
    if (evento.isEmpty) return;
    carregandoOrcamento.value = true;
    erroOrcamento.value = '';
    try {
      final itens = await _repository.listarCompromissosDoEvento(evento);
      if (usuario != _uidAtual ||
          evento != idEventoAtual.value ||
          versao != _versaoOrcamento ||
          usandoContextoHistorico.value) {
        return;
      }
      compromissosOrcamento.assignAll(itens);
      _orcamentoSubscription =
          _repository.observarCompromissosDoEvento(evento).listen((novos) {
        if (usuario != _uidAtual ||
            evento != idEventoAtual.value ||
            versao != _versaoOrcamento ||
            usandoContextoHistorico.value) {
          return;
        }
        compromissosOrcamento.assignAll(novos);
        erroOrcamento.value = '';
        _agendarAnaliseIA();
      }, onError: (Object erro) {
        if (usuario != _uidAtual ||
            evento != idEventoAtual.value ||
            versao != _versaoOrcamento ||
            usandoContextoHistorico.value) {
          return;
        }
        erroOrcamento.value =
            'Não foi possível atualizar os gastos existentes.';
        _agendarAnaliseIA();
      });
    } catch (_) {
      if (usuario == _uidAtual &&
          evento == idEventoAtual.value &&
          versao == _versaoOrcamento &&
          !usandoContextoHistorico.value) {
        erroOrcamento.value =
            'Não foi possível consultar os gastos existentes.';
      }
    } finally {
      if (usuario == _uidAtual &&
          evento == idEventoAtual.value &&
          versao == _versaoOrcamento &&
          !usandoContextoHistorico.value) {
        carregandoOrcamento.value = false;
        _agendarAnaliseIA();
      }
    }
  }

  int _versaoCarregamentoItens = 0;
  int _versaoPreparacao = 0;
  int _versaoConvidados = 0;
  int _versaoOrcamento = 0;
  int _ultimaRequisicaoIA = 0;
  StreamSubscription<List<Map<String, dynamic>>>? _orcamentoSubscription;

  bool get usandoItensDoFirestore {
    return origemItensCalculadora.value == OrigemItensCalculadora.firestore;
  }

  bool get baseCalculadoraIndisponivel {
    return origemItensCalculadora.value ==
            OrigemItensCalculadora.indisponivel ||
        origemItensCalculadora.value == OrigemItensCalculadora.semConfiguracao;
  }

  String get mensagemOrigemItensCalculadora {
    if (usandoItensDoFirestore) {
      return 'Usando base configurada da calculadora.';
    }

    if (origemItensCalculadora.value ==
        OrigemItensCalculadora.semConfiguracao) {
      return 'Não há regras de consumo para este tipo de festa. Adicione itens manualmente ou revise seu cardápio.';
    }
    return 'Não foi possível carregar as regras de consumo. Verifique sua conexão e tente novamente.';
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
  final Rxn<double> verbaAlimentacao = Rxn<double>();

  /// Quando null, usa a margem padrão do perfil selecionado.
  final Rxn<double> margemPersonalizada = Rxn<double>();

  final RxInt _versaoAnaliseIA = 0.obs;
  Worker? _workerAnaliseIA;

  final RxList<Convidado> convidados = <Convidado>[].obs;
  final RxList<ItemEstimativaFinanceira> itensEstimativa =
      <ItemEstimativaFinanceira>[].obs;
  final RxList<CalculadoraFestaItem> itensCalculados =
      <CalculadoraFestaItem>[].obs;
  final RxList<CalculadoraFesta> simulacoesSalvas = <CalculadoraFesta>[].obs;
  final RxBool carregandoSimulacoes = false.obs;

  final Rxn<CalculadoraFesta> calculoAtual = Rxn<CalculadoraFesta>();
  final Rxn<EstimativaFinanceira> estimativaAtual = Rxn<EstimativaFinanceira>();
  final Rxn<AnaliseCalculadoraIA> analiseIA = Rxn<AnaliseCalculadoraIA>();

  int get totalConvidados => baseCalculo.value == BaseCalculoFesta.previstos
      ? publicoPlanejado.total ?? 0
      : totalAdultos.value + totalCriancas.value + totalBebes.value;

  int get totalConvidadosEvento => previsaoPublico.total ?? 0;

  bool get possuiTotaisDoEvento => previsaoPublico.total != null;

  bool get possuiConvidadosCadastrados => convidados.isNotEmpty;

  bool get usandoTotaisDoCadastroDoEvento =>
      baseCalculo.value == BaseCalculoFesta.previstos;

  ConvidadosEquivalentes get publicoEvento => ConvidadosEquivalentes(
        adultos: totalAdultos.value,
        criancas: totalCriancas.value,
        bebes: totalBebes.value,
      );

  ConvidadosEquivalentes get convidadosEquivalentes =>
      publicoDaRefeicao(_cardapioConsolidadoAtual);

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
      time: const Duration(milliseconds: 1500),
    );
  }

  @override
  void onClose() {
    _workerAnaliseIA?.dispose();
    _versaoOperacao++;
    _versaoPreparacao++;
    _versaoConvidados++;
    _versaoCarregamentoItens++;
    _versaoAnaliseIA.value++;
    _versaoOrcamento++;
    unawaited(_orcamentoSubscription?.cancel());
    unawaited(_operacaoSubscription?.cancel());
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
    String? idSessao,
    int adultosManuais = 0,
    int criancasManuais = 0,
    int bebesManuais = 0,
    int adultosEvento = 0,
    int criancasEvento = 0,
    int bebesEvento = 0,
    int totalConvidadosEvento = 0,
    bool baseConfirmada = false,
    bool? previsaoInformada,
    bool? distribuicaoEtariaInformada,
  }) async {
    final preparacao = ++_versaoPreparacao;
    catalogoContextual.value = CatalogoContextual.indisponivel;
    _camposConfiguracaoEditados.clear();
    _restauracaoCatalogo = null;
    _configuracaoConfirmada = {};
    estadoConfiguracao.value = EstadoConfirmacaoConfiguracao.editando;
    mensagemConfiguracao.value = '';
    basePublicoConfirmada.value = baseConfirmada ||
        base == BaseCalculoFesta.manual ||
        permitirEstimativaSemEvento && idEvento.isEmpty;
    _baseLocalAlterada = false;
    _politicaPublicoRecebida = '';
    completudeLista.value = CompletudeLista.desconhecida;
    avisoPublico.value = '';
    consultaOperacaoIniciada.value = false;
    consultaFinanceiroIniciada.value = false;
    _idRascunhoContexto = idSessao ?? '';
    _revisaoEvento = '';
    _revisaoPeriodo = '';
    estadoEvento.value = EstadoFontePlanejamento.naoConsultada;
    estadoConvidados.value = EstadoFontePlanejamento.naoConsultada;
    estadoCardapios.value = EstadoFontePlanejamento.naoConsultada;
    avisoContexto.value = '';
    _versaoOperacao++;
    escritaContextoPendente.value = false;
    unawaited(_operacaoSubscription?.cancel());
    _operacaoSubscription = null;
    operacaoEvento.clear();
    erroOperacao.value = '';
    operacaoCarregada.value = idEvento.trim().isEmpty;
    _versaoOrcamento++;
    unawaited(_orcamentoSubscription?.cancel());
    _orcamentoSubscription = null;
    final idEventoNormalizado = idEvento.trim();
    medicaoUso.iniciarSessao(idSessao ??
        (idEventoNormalizado.isEmpty ? 'estimativa' : idEventoNormalizado));
    final modoEstimativa =
        idEventoNormalizado.isEmpty && permitirEstimativaSemEvento;

    idEventoAtual.value = idEventoNormalizado;
    tipoEventoAtual.value =
        tipoEvento.trim().isEmpty ? 'Evento' : tipoEvento.trim();
    estimativaSemEvento.value = modoEstimativa;
    baseCalculo.value = modoEstimativa
        ? BaseCalculoFesta.manual
        : (baseConfirmada || base == BaseCalculoFesta.manual)
            ? base
            : BaseCalculoFesta.previstos;
    perfilSelecionado.value = PerfilFesta.fromTipo(perfilInicial);
    duracaoHoras.value = duracaoInicialHoras <= 0 ? 4 : duracaoInicialHoras;
    _registrarTotaisDoEvento(
      adultos: adultosEvento,
      criancas: criancasEvento,
      bebes: bebesEvento,
      totalLegado: totalConvidadosEvento,
      informada: previsaoInformada,
      idadesInformadas: distribuicaoEtariaInformada,
    );
    calculoAtual.value = null;
    estimativaAtual.value = null;
    itensCalculados.clear();
    cardapiosEvento.clear();
    escoposCardapiosEvento.clear();
    titulosCardapiosEvento.clear();
    consultaCardapiosCompleta.value = false;
    regrasManuais.clear();
    regrasRejeitadas.clear();
    itensCardapio.clear();
    idCardapioAtual = '';
    tituloCardapio = '';
    escopoCardapioAtual = EscopoCardapio.naoDefinido;
    revisarCardapio.value = false;
    usandoContextoHistorico.value = false;
    _modoEscolhido = false;
    cardapioDisponivel.value = false;
    compromissosOrcamento.clear();
    carregandoOrcamento.value = true;
    orcamentoDisponivel.value = null;
    verbaAlimentacao.value = null;
    margemPersonalizada.value = null;
    analiseIA.value = null;
    erroAnaliseIA.value = '';
    _agendarAnaliseIA();

    if (modoEstimativa) {
      convidados.clear();
      totalAdultos.value = _normalizarQuantidade(adultosManuais);
      totalCriancas.value = _normalizarQuantidade(criancasManuais);
      totalBebes.value = _normalizarQuantidade(bebesManuais);

      await carregarItensBasePorTipoEvento(
        recalcularAposCarregar: false,
      );

      if (preparacao == _versaoPreparacao && calcularAutomaticamente) {
        calcular();
      }
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
    if (preparacao != _versaoPreparacao) return;

    if (baseCalculo.value != BaseCalculoFesta.manual) {
      aplicarTotaisDosConvidados();
    } else {
      totalAdultos.value = _normalizarQuantidade(adultosManuais);
      totalCriancas.value = _normalizarQuantidade(criancasManuais);
      totalBebes.value = _normalizarQuantidade(bebesManuais);
    }

    await carregarItensBasePorTipoEvento(
      recalcularAposCarregar: false,
    );

    if (preparacao != _versaoPreparacao) return;
    await iniciarOperacaoEvento(aguardarPrimeira: true);
    await _restauracaoCatalogo;
    if (preparacao != _versaoPreparacao) return;
    if (calcularAutomaticamente) calcular();
    await carregarSimulacoesSalvas();
    if (preparacao != _versaoPreparacao) return;
    await carregarContextoOrcamento();
  }

  RascunhoCalculadora capturarRascunho(String id, {DateTime? criadoEm}) {
    if (!estimativaSemEvento.value || possuiEventoVinculado) {
      throw StateError(
          'Somente a estimativa sem evento pode voltar ao cadastro.');
    }
    return RascunhoCalculadora(
        id: id,
        tipoEvento: tipoEventoAtual.value,
        adultos: totalAdultos.value,
        criancas: totalCriancas.value,
        bebes: totalBebes.value,
        duracaoHoras: duracaoHoras.value,
        perfil: perfilSelecionado.value,
        limite: orcamentoDisponivel.value,
        margem: margemPersonalizada.value,
        criadoEm: criadoEm ?? DateTime.now(),
        contexto: snapshotPlanejamento);
  }

  void restaurarRascunho(RascunhoCalculadora rascunho) {
    if (!estimativaSemEvento.value ||
        possuiEventoVinculado ||
        rascunho.tipoEvento != tipoEventoAtual.value) {
      throw StateError('O rascunho não corresponde à estimativa aberta.');
    }
    totalAdultos.value = rascunho.adultos;
    totalCriancas.value = rascunho.criancas;
    totalBebes.value = rascunho.bebes;
    duracaoHoras.value = rascunho.duracaoHoras;
    perfilSelecionado.value = rascunho.perfil;
    margemPersonalizada.value = rascunho.margem;
    orcamentoDisponivel.value = rascunho.limite;
    restaurarVerbaAlimentacao(rascunho.contexto['verba_alimentacao']);
    if (rascunho.contexto['catalogo_requer_atualizacao'] != true) {
      itensEstimativa.assignAll(rascunho.regras('regras_catalogo'));
    }
    regrasManuais.assignAll(rascunho.regras('regras_manuais'));
    regrasRejeitadas.assignAll(List<String>.from(
        rascunho.contexto['regras_rejeitadas'] as List? ?? []));
    calcular();
  }

  /// Grava o snapshot sem trocar o estado do evento ativo. A chave é estável
  /// para que uma tentativa após falha não crie outra simulação.
  Future<void> vincularRascunho(
      RascunhoCalculadora rascunho, Evento evento) async {
    if (evento.idEvento.isEmpty || evento.idUsuario.isEmpty) {
      throw StateError('Salve o evento antes de vincular a estimativa.');
    }
    final previsao = PrevisaoPublico.doEvento(evento);
    if (previsao.total != null && previsao.idades == null) {
      throw StateError(
          'Informe a distribuição etária antes de vincular a estimativa.');
    }
    final adultos = previsao.idades?.adultos ?? rascunho.adultos;
    final criancas = previsao.idades?.criancas ?? rascunho.criancas;
    final bebes = previsao.idades?.bebes ?? rascunho.bebes;
    final reconciliado = rascunho.reconciliar(
        tipoEvento: rascunho.tipoEvento,
        adultos: adultos,
        criancas: criancas,
        bebes: bebes,
        limite: evento.custoEstimado);
    final base = reconciliado.calculoPara(
        evento.idEvento, evento.idUsuario, evento.custoEstimado);
    // Ajustes no cadastro depois da prévia prevalecem sobre o público antigo.
    final calculo = base.copyWith(
        totalAdultos: adultos,
        totalCriancas: criancas,
        totalBebes: bebes,
        contextoPlanejamento: {
          ...base.contextoPlanejamento,
          'publico_evento': {
            'adultos': adultos,
            'criancas': criancas,
            'bebes': bebes
          }
        });
    final regras = const ComposicaoRefeicaoService().compor([
      ...rascunho.regras('regras_catalogo').where(
          (r) => !rascunho.regras('regras_manuais').any((m) => m.id == r.id)),
      ...rascunho.regras('regras_manuais'),
    ]);
    final itens = _service.calcularItens(calculo: calculo, itensBase: regras);
    final finalizado = calculo.copyWith(
        custoTotalEstimado:
            itens.fold<double>(0, (s, i) => s + i.custoEstimado));
    final repo = _repository;
    if (repo is VinculoRascunhoRepository) {
      await (repo as VinculoRascunhoRepository)
          .vincularEstimativaInicial(calculo: finalizado, itens: itens);
    } else {
      await repo.salvarSimulacao(calculo: finalizado, itens: itens);
    }
  }

  void iniciarNovoCalculo({
    bool limparQuantidades = true,
    bool limparOrcamento = true,
    bool manterPerfil = true,
    bool manterDuracao = true,
  }) {
    _agendarAnaliseIA();
    calculoAtual.value = null;
    estimativaAtual.value = null;
    analiseIA.value = null;
    analisandoIA.value = false;

    itensCalculados.clear();

    if (limparOrcamento) {
      orcamentoDisponivel.value = null;
      verbaAlimentacao.value = null;
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
    final versao = ++_versaoCarregamentoItens;
    itensEstimativa.clear();
    itensCalculados.clear();
    calculoAtual.value = null;
    estimativaAtual.value = null;
    analiseIA.value = null;
    itensOrigemRemota.value = false;
    origemItensCalculadora.value = OrigemItensCalculadora.indisponivel;
    _agendarAnaliseIA();
    regrasRejeitadas.clear();
    final tipoEventoKey = _normalizarTipoEventoParaConsulta(
      tipoEventoAtual.value,
    );
    final perfilFestaKey = _normalizarPerfilFestaParaConsulta();

    if (tipoEventoKey.isEmpty) {
      carregandoItensBase.value = false;
      _marcarBaseIndisponivel(
        motivo: 'Tipo de evento não informado para a calculadora.',
        semConfiguracao: true,
        recalcularAposCarregar: recalcularAposCarregar,
      );
      return;
    }

    try {
      carregandoItensBase.value = true;
      erroItensBase.value = '';

      if (_itensBaseRepository is CatalogoContextualRepository) {
        await atualizarCatalogoContextual();
        if (versao != _versaoCarregamentoItens) return;
        origemItensCalculadora.value =
            catalogoContextual.value.estado == 'indisponivel'
                ? OrigemItensCalculadora.indisponivel
                : OrigemItensCalculadora.firestore;
        itensOrigemRemota.value =
            catalogoContextual.value.estado == 'disponivel';
        if (recalcularAposCarregar) calcular();
        return;
      }

      final itensRemotos =
          await _itensBaseRepository.buscarItensPorTipoEventoComFallback(
        tipoEvento: tipoEventoKey,
        perfilFesta: perfilFestaKey.isEmpty ? null : perfilFestaKey,
      );

      if (versao != _versaoCarregamentoItens) return;

      if (itensRemotos.isEmpty) {
        _marcarBaseIndisponivel(
          motivo: 'Nenhum item remoto encontrado para $tipoEventoKey.',
          semConfiguracao: true,
          recalcularAposCarregar: recalcularAposCarregar,
        );
        return;
      }

      final itensConvertidos = <ItemEstimativaFinanceira>[];
      regrasRejeitadas.clear();
      for (final item in itensRemotos.where((item) => item.ativo)) {
        try {
          itensConvertidos.add(_converterItemEventoParaEstimativa(item));
        } on StateError {
          regrasRejeitadas.add(item.nome);
        }
      }

      if (itensConvertidos.isEmpty) {
        _marcarBaseIndisponivel(
          motivo: 'Os itens remotos encontrados não puderam ser convertidos.',
          semConfiguracao: true,
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
      if (versao != _versaoCarregamentoItens) return;
      _marcarBaseIndisponivel(
        motivo: 'Erro ao carregar itens remotos da calculadora: $e',
        recalcularAposCarregar: recalcularAposCarregar,
      );
    } finally {
      if (versao == _versaoCarregamentoItens) carregandoItensBase.value = false;
    }
  }

  Future<void> atualizarTipoEventoCalculadora(String tipoEvento) async {
    tipoEventoAtual.value =
        tipoEvento.trim().isEmpty ? 'Evento' : tipoEvento.trim();
    await carregarItensBasePorTipoEvento();
  }

  void _marcarBaseIndisponivel({
    bool semConfiguracao = false,
    required String motivo,
    required bool recalcularAposCarregar,
  }) {
    erroItensBase.value = motivo;
    itensOrigemRemota.value = false;
    origemItensCalculadora.value = semConfiguracao
        ? OrigemItensCalculadora.semConfiguracao
        : OrigemItensCalculadora.indisponivel;
    itensEstimativa.clear();
    itensCalculados.clear();
    calculoAtual.value = null;
    estimativaAtual.value = null;
    analiseIA.value = null;
    _agendarAnaliseIA();

    debugPrint(
      '[CalculadoraFestaController] $motivo '
      'Nenhum preço local será usado.',
    );

    if (recalcularAposCarregar) {
      calcular();
    }
  }

  ItemEstimativaFinanceira _converterItemEventoParaEstimativa(
    CalculadoraEventoItem item,
  ) {
    final unidade = _unidadeEstimativaFromString(item.unidade);
    if (!item.quantidadePorConvidadoEquivalente.isFinite ||
        item.quantidadePorConvidadoEquivalente <= 0 ||
        !item.valorUnitarioMedio.isFinite ||
        item.valorUnitarioMedio < 0 ||
        RevisaoCardapioService.unidade(item.unidade) !=
            RevisaoCardapioService.unidade(unidade.label)) {
      throw StateError(
          'Regra inválida para ${item.nome}. Revise consumo, preço e unidade.');
    }
    for (final campo in [
      'rendimento',
      'participacao',
      'embalagem',
      'numero_servicos'
    ]) {
      final valor = item.premissas[campo];
      if (valor != null &&
          (valor is! num ||
              !valor.isFinite ||
              (campo == 'embalagem' ? valor < 0 : valor <= 0))) {
        throw StateError('Premissa inválida: $campo em ${item.nome}.');
      }
    }
    for (final campo in ['peso_crianca', 'peso_bebe']) {
      final valor = item.premissas[campo];
      if (valor != null &&
          (valor is! num || !valor.isFinite || valor < 0 || valor > 1)) {
        throw StateError('Peso de público inválido em ${item.nome}.');
      }
    }
    final selecionado = item.obrigatorio || item.selecionadoPadrao;

    return ItemEstimativaFinanceira(
      id: item.id,
      categoria: item.categoria,
      premissas: item.premissas,
      nome: item.nome,
      tipoItem: RevisaoCardapioService.tipo(
              item.nome, item.categoria, item.idItemBase)
          .name,
      publicoAlvo: item.publicoAlvo,
      unidade: unidade,
      quantidadePorConvidadoEquivalente: item.quantidadePorConvidadoEquivalente,
      valorUnitarioMedio: item.valorUnitarioMedio,
      selecionado: selecionado,
    );
  }

  Future<void> carregarConvidadosDoEvento(String idEvento) async {
    final usuario = _uidAtual;
    final versao = ++_versaoConvidados;
    estadoConvidados.value = EstadoFontePlanejamento.carregando;
    convidados.clear();
    if (idEvento.trim().isEmpty) {
      convidados.clear();
      return;
    }

    try {
      loading.value = true;
      final lista = await _repository.listarConvidadosDoEvento(idEvento);
      if (usuario != _uidAtual ||
          versao != _versaoConvidados ||
          idEvento != idEventoAtual.value ||
          usandoContextoHistorico.value) {
        return;
      }
      convidados.assignAll(lista);
      estadoConvidados.value = lista.isEmpty
          ? EstadoFontePlanejamento.vazia
          : EstadoFontePlanejamento.disponivel;
    } catch (e) {
      if (usuario != _uidAtual ||
          versao != _versaoConvidados ||
          idEvento != idEventoAtual.value ||
          usandoContextoHistorico.value) {
        return;
      }
      estadoConvidados.value = EstadoFontePlanejamento.erro;
      Get.snackbar(
        'Erro',
        'Não foi possível carregar os convidados: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      if (versao == _versaoConvidados) loading.value = false;
    }
  }

  void sincronizarConvidados(List<Convidado> atualizados,
      {String? eventoFonte}) {
    if (eventoFonte != null && eventoFonte != idEventoAtual.value) return;
    if (atualizados.isNotEmpty &&
        atualizados.every((c) => c.idEvento != idEventoAtual.value)) {
      return;
    }
    if (usandoContextoHistorico.value || idEventoAtual.value.isEmpty) return;
    estadoConvidados.value = atualizados.isEmpty
        ? EstadoFontePlanejamento.vazia
        : EstadoFontePlanejamento.disponivel;
    convidados
        .assignAll(atualizados.where((i) => i.idEvento == idEventoAtual.value));
    if (baseCalculo.value != BaseCalculoFesta.manual) {
      aplicarTotaisDosConvidados();
      calcular();
    }
  }

  void aplicarTotaisDosConvidados() {
    if (baseCalculo.value == BaseCalculoFesta.manual) return;
    final pessoas = publicoPlanejado.idades;
    totalAdultos.value = pessoas?.adultos ?? 0;
    totalCriancas.value = pessoas?.criancas ?? 0;
    totalBebes.value = pessoas?.bebes ?? 0;
  }

  void aplicarTotaisDoCadastroDoEvento() {
    totalAdultos.value =
        _previsaoIdadesConhecidas ? totalAdultosEvento.value : 0;
    totalCriancas.value =
        _previsaoIdadesConhecidas ? totalCriancasEvento.value : 0;
    totalBebes.value = _previsaoIdadesConhecidas ? totalBebesEvento.value : 0;
  }

  void alterarBaseCalculo(BaseCalculoFesta novaBase) {
    basePublicoConfirmada.value = !possuiEventoVinculado;
    _baseLocalAlterada = true;
    if (novaBase != baseCalculo.value) {
      medicaoUso.registrarDecisao('fonte_publico');
    }
    baseCalculo.value = novaBase;

    if (novaBase != BaseCalculoFesta.manual) {
      aplicarTotaisDosConvidados();
    }

    calcular();
  }

  void selecionarPerfil(TipoPerfilFesta tipo) {
    marcarEdicaoConfiguracao('perfil');
    perfilSelecionado.value = PerfilFesta.fromTipo(tipo);
    margemPersonalizada.value = null;

    // O perfil pode alterar os itens retornados pelo Firestore
    // por causa do filtro perfis_festa. A tela não precisa mudar:
    // ela continua observando os mesmos estados reativos.
    carregarItensBasePorTipoEvento();
  }

  void atualizarMargemPersonalizada(double? margem) {
    marcarEdicaoConfiguracao('margem');
    if (margem == null) {
      margemPersonalizada.value = null;
    } else {
      margemPersonalizada.value = margem.clamp(0, 0.30).toDouble();
    }

    calcular();
  }

  void adicionarItemManual(ItemEstimativaFinanceira item) {
    regrasManuais.removeWhere((atual) => atual.id == item.id);
    regrasManuais.add(item);
    erroItensBase.value = '';
    calcular();
  }

  void alternarItemEstimativa(String idItem, bool selecionado) {
    for (final lista in [itensEstimativa, regrasManuais]) {
      lista.assignAll(lista
          .map((item) => item.id == idItem
              ? item.copyWith(selecionado: selecionado)
              : item)
          .toList());
    }

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
    bool intervencaoHumana = false,
  }) {
    if (intervencaoHumana) {
      if (adultos != totalAdultos.value) {
        medicaoUso.registrarCampo('publico_adultos');
      }
      if (criancas != totalCriancas.value) {
        medicaoUso.registrarCampo('publico_criancas');
      }
      if (bebes != totalBebes.value) medicaoUso.registrarCampo('publico_bebes');
    }
    baseCalculo.value = BaseCalculoFesta.manual;
    basePublicoConfirmada.value = !possuiEventoVinculado;
    _baseLocalAlterada = true;
    totalAdultos.value = _normalizarQuantidade(adultos);
    totalCriancas.value = _normalizarQuantidade(criancas);
    totalBebes.value = _normalizarQuantidade(bebes);
    calcular();
  }

  void atualizarDuracao(int horas) {
    marcarEdicaoConfiguracao('duracao');
    duracaoHoras.value = horas <= 0 ? 4 : horas;
    calcular();
  }

  List<CalculadoraFestaItem> simularPerfil(PerfilFesta perfil) {
    final atual = calculoAtual.value;
    if (atual == null) return [];
    return _service.calcularItens(
        calculo: atual.copyWith(
            perfilFesta: perfil, limparMargemPersonalizada: true),
        itensBase: const ComposicaoRefeicaoService().compor(itensParaCalculo));
  }

  void aplicarPerfilPlanejamento(PerfilFesta perfil) {
    perfilSelecionado.value = perfil;
    margemPersonalizada.value = null;
    calcular();
  }

  void calcular() {
    _agendarAnaliseIA();
    analiseIA.value = null;
    erroAnaliseIA.value = '';
    analisandoIA.value = false;
    if (possuiEventoVinculado &&
        !usandoContextoHistorico.value &&
        !operacaoCarregada.value) {
      calculoAtual.value = null;
      itensCalculados.clear();
      estimativaAtual.value = null;
      return;
    }
    final propria = OperacaoCalculadoraService.mapa(
        OperacaoCalculadoraService.mapa(operacaoEvento['refeicoes'])[
            _cardapioConsolidadoAtual])['publico'] is Map;
    if ((!usandoContextoHistorico.value &&
            publicoPlanejado.idades == null &&
            !propria) ||
        (estadoEvento.value == EstadoFontePlanejamento.desatualizada &&
            !usandoContextoHistorico.value) ||
        (estadoConvidados.value == EstadoFontePlanejamento.erro &&
            baseCalculo.value != BaseCalculoFesta.manual &&
            baseCalculo.value != BaseCalculoFesta.previstos &&
            !usandoContextoHistorico.value) ||
        (revisarCardapio.value && !cardapioDisponivel.value) ||
        itensParaCalculo.isEmpty ||
        (!possuiEventoVinculado && !estimativaSemEvento.value)) {
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
      totalAdultos: convidadosEquivalentes.adultos,
      totalCriancas: convidadosEquivalentes.criancas,
      totalBebes: convidadosEquivalentes.bebes,
      duracaoHoras: duracaoHoras.value,
      dataCalculo: calculoAtual.value?.dataCalculo ?? agora,
      dataAtualizacao: agora,
      perfilFesta: perfilSelecionado.value,
      margemPersonalizada: margemPersonalizada.value,
      orcamentoDisponivel: orcamentoDisponivel.value,
      idUsuario: calculoAtual.value?.idUsuario ?? _uidAtual,
      contextoPlanejamento: snapshotPlanejamento,
    );

    final itens = _service.calcularItens(
      calculo: calculoBase,
      itensBase: const ComposicaoRefeicaoService().compor(itensParaCalculo),
    );

    final custoTotal =
        itens.fold<double>(0, (total, item) => total + item.custoEstimado);
    final calculoFinal = calculoBase.copyWith(custoTotalEstimado: custoTotal);

    calculoAtual.value = calculoFinal;
    itensCalculados.assignAll(itens);
    calculoAtual.value =
        calculoFinal.copyWith(contextoPlanejamento: snapshotPlanejamento);
    estimativaAtual.value = _service.calcularEstimativa(
      calculo: calculoFinal,
      itensBase: const ComposicaoRefeicaoService().compor(itensParaCalculo),
    );
    _agendarAnaliseIA();
  }

  Future<void> salvarLimitePlanejamento(double? valor) async {
    if (possuiEventoVinculado) {
      await _repository.salvarLimiteEvento(idEventoAtual.value, valor);
    }
    atualizarOrcamentoDisponivel(valor);
  }

  void atualizarOrcamentoDisponivel(double? valor) {
    if (valor == null || !valor.isFinite || valor < 0) {
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

  void restaurarVerbaAlimentacao(dynamic valor) {
    verbaAlimentacao.value =
        valor is num && valor.isFinite && valor >= 0 ? valor.toDouble() : null;
  }

  void atualizarVerbaAlimentacao(double valor) {
    if (!valor.isFinite ||
        valor <= 0 ||
        (orcamentoDisponivel.value != null &&
            valor > orcamentoDisponivel.value!)) {
      throw ArgumentError(
          'A verba deve ser positiva e caber no limite total informado.');
    }
    marcarEdicaoConfiguracao('verba_alimentacao');
    verbaAlimentacao.value = valor;
    calcular();
  }

  void limpar() {
    _previsaoTotal.value = null;
    _previsaoIdadesConhecidas = true;
    completudeLista.value = CompletudeLista.desconhecida;
    basePublicoConfirmada.value = false;
    _baseLocalAlterada = false;
    _politicaPublicoRecebida = '';
    avisoPublico.value = '';
    consultaOperacaoIniciada.value = false;
    consultaFinanceiroIniciada.value = false;
    estadoEvento.value = EstadoFontePlanejamento.naoConsultada;
    estadoConvidados.value = EstadoFontePlanejamento.naoConsultada;
    estadoCardapios.value = EstadoFontePlanejamento.naoConsultada;
    _revisaoEvento = '';
    _revisaoPeriodo = '';
    avisoContexto.value = '';
    _idRascunhoContexto = '';
    _versaoOperacao++;
    escritaContextoPendente.value = false;
    unawaited(_operacaoSubscription?.cancel());
    _operacaoSubscription = null;
    operacaoEvento.clear();
    operacaoCarregada.value = true;
    erroOperacao.value = '';
    idCardapioAtual = '';
    _versaoCarregamentoItens++;
    _versaoPreparacao++;
    _versaoConvidados++;
    _versaoOrcamento++;
    unawaited(_orcamentoSubscription?.cancel());
    _orcamentoSubscription = null;
    _agendarAnaliseIA();
    cardapiosEvento.clear();
    escoposCardapiosEvento.clear();
    titulosCardapiosEvento.clear();
    consultaCardapiosCompleta.value = false;
    regrasManuais.clear();
    regrasRejeitadas.clear();
    itensCardapio.clear();
    compromissosOrcamento.clear();
    revisarCardapio.value = false;
    usandoContextoHistorico.value = false;
    _modoEscolhido = false;
    erroAnaliseIA.value = '';
    cardapioDisponivel.value = false;
    carregandoOrcamento.value = false;
    erroOrcamento.value = '';
    tituloCardapio = '';
    idEventoAtual.value = '';
    tipoEventoAtual.value = '';
    verbaAlimentacao.value = null;
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
    itensEstimativa.clear();
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
    origemItensCalculadora.value = OrigemItensCalculadora.indisponivel;
    erroItensBase.value = '';
  }

  String? get _uidAtual {
    if (Get.isRegistered<FirebaseAuth>()) {
      return Get.find<FirebaseAuth>().currentUser?.uid;
    }
    if (Firebase.apps.isEmpty) return null;
    return FirebaseAuth.instance.currentUser?.uid;
  }

  void _registrarTotaisDoEvento(
      {required int adultos,
      required int criancas,
      required int bebes,
      required int totalLegado,
      bool? informada,
      bool? idadesInformadas}) {
    final a = _normalizarQuantidade(adultos),
        c = _normalizarQuantidade(criancas),
        b = _normalizarQuantidade(bebes);
    final total = _normalizarQuantidade(totalLegado);
    _previsaoTotal.value = (informada ?? (total > 0 || a + c + b > 0))
        ? (informada == true
            ? total
            : total > 0
                ? total
                : a + c + b)
        : null;
    _previsaoIdadesConhecidas =
        idadesInformadas ?? !(a + c + b == 0 && total > 0);
    totalAdultosEvento.value = a;
    totalCriancasEvento.value = c;
    totalBebesEvento.value = b;
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
    final normalized = RevisaoCardapioService.unidade(value ?? '');
    return UnidadeEstimativa.values.firstWhere(
        (item) =>
            RevisaoCardapioService.unidade(item.label) == normalized ||
            item.name == normalized,
        orElse: () => UnidadeEstimativa.unidade);
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
