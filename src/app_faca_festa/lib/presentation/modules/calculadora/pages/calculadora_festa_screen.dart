import '../widgets/calculadora_planejador_dialog.dart';
import '../widgets/calculadora_contexto_card.dart';
import '../widgets/calculadora_agenda_dialog.dart';
import '../widgets/calculadora_configuracao_dialog.dart';
import 'package:app_faca_festa/domain/services/publico_planejamento_service.dart';
import 'dart:async';
import 'package:app_faca_festa/domain/entities/contexto_planejamento_evento.dart';
import '../widgets/calculadora_entrada_inteligente_dialog.dart';
import 'package:app_faca_festa/domain/services/operacao_calculadora_service.dart';
import '../widgets/calculadora_comando_texto_dialog.dart';
import '../widgets/calculadora_revisao_pos_evento_dialog.dart';
import '../widgets/calculadora_execucao_dialog.dart';
import 'package:app_faca_festa/domain/services/plano_evento_service.dart';
import '../widgets/calculadora_criar_cardapio_dialog.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/convidado_controller.dart';
import 'package:app_faca_festa/domain/entities/rascunho_calculadora.dart';
import 'package:app_faca_festa/domain/entities/registro_consumo_calculadora.dart';
import 'package:app_faca_festa/domain/entities/evento.dart';
import 'package:app_faca_festa/domain/services/cenario_alternativa_service.dart';
import 'package:app_faca_festa/domain/services/resumo_compras_service.dart';
import 'package:app_faca_festa/domain/services/lista_compras_calculadora_service.dart';
import 'package:app_faca_festa/presentation/modules/convidado/components/disponibilidade_cardapio_dialog.dart';
import '../widgets/calculadora_diagnostico_card.dart';
import '../widgets/calculadora_proposta_card.dart';
import '../widgets/calculadora_plano_evento_card.dart';
// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'calculadora_operacao_dialog.dart';
import 'package:app_faca_festa/domain/entities/cardapio.dart';
import 'package:app_faca_festa/domain/entities/cardapio_item.dart';
import 'package:app_faca_festa/domain/services/revisao_cardapio_service.dart';
import 'calculadora_regra_manual_dialog.dart';
import 'calculadora_limite_orcamento_dialog.dart';
import 'calculadora_consumo_dialog.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/domain/entities/analise_calculadora_ia.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa_item.dart';
import 'package:app_faca_festa/domain/entities/perfil_festa.dart';
import 'package:app_faca_festa/domain/entities/estimativa_financeira.dart';
import 'package:app_faca_festa/presentation/modules/convidado/components/cadastro_cardapio_bottom_sheet.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/fornecedor_migracao_admin_controller.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/cardapio_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_controller.dart';
import 'package:app_faca_festa/presentation/widgets/cadastro_passos_bar.dart';
import 'package:app_faca_festa/presentation/widgets/festa_app_bar.dart';
import 'minhas_simulacoes_calculadora_bottom_sheet.dart';
import 'calculadora_item_icon_helper.dart';

// ============================================================================
// 🔹 Tela da Calculadora Inteligente de Festa (Versão Ultracompacta)
// ============================================================================

part '../sections/calculadora_festa_layout.dart';
part '../sections/calculadora_festa_compras.dart';
part '../sections/calculadora_festa_decisoes.dart';
part '../sections/calculadora_festa_planejamento.dart';
part '../sections/calculadora_festa_historico.dart';
part '../sections/calculadora_festa_totais.dart';
part '../sections/calculadora_festa_itens.dart';
part '../sections/calculadora_festa_ia.dart';
part '../widgets/calculadora_festa_section_widgets.dart';

class CalculadoraFestaScreen extends StatefulWidget {
  final String? idSimulacaoInicial;
  final Future<void> Function(RascunhoCalculadora)? persistirRascunho;
  final String? idEvento;
  final String? nomeRascunho, periodoRascunho;
  final String? tipoEvento;
  final double? orcamentoInicial;
  final RascunhoCalculadora? rascunho;
  final String? idRascunho;
  final ValueChanged<RascunhoCalculadora>? onRascunho;
  final int duracaoInicialHoras;
  final bool permitirEstimativaSemEvento;
  final int adultosIniciais;
  final int criancasIniciais;
  final int bebesIniciais;
  final CalculadoraFestaController calculadoraController;
  final EventoController eventoController;
  final EventThemeController themeController;
  final CardapioController cardapioController;
  final ConvidadoController? convidadoController;
  final FornecedorMigracaoAdminController fornecedorMigracaoAdminController;

  const CalculadoraFestaScreen({
    super.key,
    this.idEvento,
    this.nomeRascunho,
    this.periodoRascunho,
    this.idSimulacaoInicial,
    this.persistirRascunho,
    this.tipoEvento,
    this.orcamentoInicial,
    this.rascunho,
    this.idRascunho,
    this.onRascunho,
    this.duracaoInicialHoras = 4,
    this.permitirEstimativaSemEvento = false,
    this.adultosIniciais = 0,
    this.criancasIniciais = 0,
    this.bebesIniciais = 0,
    required this.calculadoraController,
    required this.eventoController,
    required this.themeController,
    required this.cardapioController,
    this.convidadoController,
    required this.fornecedorMigracaoAdminController,
  });

  @override
  State<CalculadoraFestaScreen> createState() => _CalculadoraFestaScreenState();
}

class _CalculadoraFestaScreenState extends State<CalculadoraFestaScreen>
    with WidgetsBindingObserver {
  late final CalculadoraFestaController calculadoraController;
  late final FornecedorMigracaoAdminController controllerTest;
  late final EventoController eventoController;
  late final CardapioController cardapioController;
  late final EventThemeController themeController;

  final TextEditingController adultosCtrl = TextEditingController();
  final TextEditingController criancasCtrl = TextEditingController();
  final TextEditingController bebesCtrl = TextEditingController();

  final RxString idCardapioSelecionado = ''.obs;
  Worker? _rascunhoWorker;
  Timer? _rascunhoTimer;
  late DateTime _criadoEmRascunho;
  bool _permitirSaida = false;
  final _erroSalvarRascunho = ''.obs;
  final _estadoRascunho = ''.obs;
  int _versaoGravacaoRascunho = 0;
  Future<void> _guardarRascunho() async {
    _rascunhoTimer?.cancel();
    if (!_preparada ||
        widget.persistirRascunho == null ||
        widget.idRascunho == null ||
        !calculadoraController.estimativaSemEvento.value ||
        calculadoraController.possuiEventoVinculado) {
      return;
    }
    final sessao = calculadoraController.sessaoPlanejador;
    final versao = ++_versaoGravacaoRascunho;
    _estadoRascunho.value = 'Guardando estimativa neste aparelho…';
    try {
      await widget.persistirRascunho!(calculadoraController
          .capturarRascunho(widget.idRascunho!, criadoEm: _criadoEmRascunho));
      if (sessao == calculadoraController.sessaoPlanejador &&
          versao == _versaoGravacaoRascunho) {
        _erroSalvarRascunho.value = '';
        _estadoRascunho.value = 'Estimativa guardada neste aparelho.';
      }
    } catch (_) {
      if (sessao == calculadoraController.sessaoPlanejador &&
          versao == _versaoGravacaoRascunho) {
        _estadoRascunho.value = '';
        _erroSalvarRascunho.value =
            'Não foi possível guardar a estimativa neste aparelho. Seus valores continuam na tela; tente novamente antes de sair.';
      }
      rethrow;
    }
  }

  void _agendarRascunho() {
    if (!_preparada || widget.persistirRascunho == null) return;
    _versaoGravacaoRascunho++;
    _estadoRascunho.value =
        'Alterações aguardando armazenamento neste aparelho…';
    _rascunhoTimer?.cancel();
    _rascunhoTimer = Timer(const Duration(milliseconds: 300), () {
      unawaited(_guardarRascunho().catchError((Object _) {}));
    });
  }

  Worker? _eventoWorker;
  Worker? _cardapiosWorker;
  Worker? _convidadosWorker;
  Worker? _estadoConvidadosWorker;
  Worker? _itensCardapioWorker;
  Worker? _estadoCardapioWorker;
  Worker? _agendaWorker;
  String _assinaturaCardapio = '';

  List<Cardapio> get _cardapiosDaFesta => cardapioController.cardapios
      .where((item) =>
          item.idEvento == calculadoraController.idEventoAtual.value &&
          item.ativo &&
          !item.somenteModelo)
      .toList();
  int _passo = 0;
  bool _preparada = false;
  static const _titulosPassos = ['Pessoas', 'A festa', 'Sugestões'];
  final GlobalKey _chavePublico = GlobalKey(debugLabel: 'base_calculo_publico');

  @override
  void initState() {
    super.initState();

    calculadoraController = widget.calculadoraController;
    calculadoraController.medicaoUso.visibilidade(true);
    WidgetsBinding.instance.addObserver(this);
    eventoController = widget.eventoController;
    themeController = widget.themeController;
    cardapioController = widget.cardapioController;
    controllerTest = widget.fornecedorMigracaoAdminController;

    _criadoEmRascunho = widget.rascunho?.criadoEm ?? DateTime.now();
    _rascunhoWorker = everAll([
      calculadoraController.totalAdultos,
      calculadoraController.totalCriancas,
      calculadoraController.totalBebes,
      calculadoraController.perfilSelecionado,
      calculadoraController.duracaoHoras,
      calculadoraController.orcamentoDisponivel,
      calculadoraController.margemPersonalizada,
      calculadoraController.itensEstimativa,
      calculadoraController.regrasManuais,
      calculadoraController.regrasRejeitadas,
      calculadoraController.verbaAlimentacao
    ], (_) => _agendarRascunho());
    _eventoWorker = ever(eventoController.eventoAtual, (Evento? evento) {
      if (_preparada && evento != null) {
        calculadoraController.sincronizarEvento(evento);
        _sincronizarCamposManuais();
      }
    });
    _cardapiosWorker = ever(
      cardapioController.cardapios,
      (_) => _selecionarPrimeiroCardapioDisponivel(),
    );

    _itensCardapioWorker = ever(
        cardapioController.itensPorCardapio, (_) => _sincronizarCardapio());
    _estadoCardapioWorker = everAll(
        [cardapioController.carregando, cardapioController.erro],
        (_) => _sincronizarCardapio());

    _agendaWorker = ever(calculadoraController.operacaoEvento, (_) {
      if (_preparada) _sincronizarCardapio();
    });
    final convidados = widget.convidadoController;
    if (convidados != null) {
      void sincronizarLista() {
        if (!_preparada ||
            convidados.idEventoAtual.value !=
                calculadoraController.idEventoAtual.value) {
          return;
        }
        if (convidados.erro.value.isNotEmpty) {
          calculadoraController.estadoConvidados.value =
              EstadoFontePlanejamento.erro;
          return;
        }
        if (convidados.carregando.value) {
          calculadoraController.estadoConvidados.value =
              EstadoFontePlanejamento.carregando;
          return;
        }
        calculadoraController.sincronizarConvidados(
            convidados.convidados.toList(),
            eventoFonte: convidados.idEventoAtual.value);
        _sincronizarCamposManuais();
      }

      _convidadosWorker =
          ever(convidados.convidados, (_) => sincronizarLista());
      _estadoConvidadosWorker = everAll(
          [convidados.idEventoAtual, convidados.carregando, convidados.erro],
          (_) => sincronizarLista());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _prepararCalculadora();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    calculadoraController.medicaoUso.visibilidade(false);
    if (_preparada &&
        widget.idRascunho != null &&
        widget.onRascunho != null &&
        calculadoraController.estimativaSemEvento.value &&
        !calculadoraController.possuiEventoVinculado) {
      widget.onRascunho!(calculadoraController.capturarRascunho(
          widget.idRascunho!,
          criadoEm: widget.rascunho?.criadoEm));
    }
    _rascunhoTimer?.cancel();
    _rascunhoWorker?.dispose();
    _eventoWorker?.dispose();
    _convidadosWorker?.dispose();
    _estadoConvidadosWorker?.dispose();
    _cardapiosWorker?.dispose();
    _itensCardapioWorker?.dispose();
    _estadoCardapioWorker?.dispose();
    _agendaWorker?.dispose();
    adultosCtrl.dispose();
    criancasCtrl.dispose();
    bebesCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    calculadoraController.medicaoUso
        .visibilidade(state == AppLifecycleState.resumed);
    if (state != AppLifecycleState.resumed) {
      unawaited(_guardarRascunho().catchError((Object _) {}));
    }
  }

  Future<void> _prepararCalculadora() async {
    _assinaturaCardapio = '';
    final ativo = eventoController.eventoAtualEntidade;
    // String vazia é uma escolha explícita de rascunho, sem fallback ao evento ativo.
    final idEvento = widget.idEvento ?? ativo?.idEvento ?? '';
    final evento =
        idEvento.isNotEmpty && ativo?.idEvento == idEvento ? ativo : null;
    final permiteSemEvento = widget.permitirEstimativaSemEvento;

    if (idEvento.isEmpty && !permiteSemEvento) {
      Get.snackbar(
        'Atenção',
        'Nenhum evento selecionado para calcular as quantidades.',
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }

    final tipoEvento = widget.tipoEvento ??
        (evento == null
            ? null
            : eventoController.tipoEventoAtualEntidade?.nome) ??
        'Evento';

    final usouParametrosDaTela = widget.adultosIniciais > 0 ||
        widget.criancasIniciais > 0 ||
        widget.bebesIniciais > 0;

    final adultosIniciais = _normalizarQuantidadeInicial(
      usouParametrosDaTela
          ? widget.adultosIniciais
          : (evento?.totalAdultosCalculado ?? 0),
    );
    final criancasIniciais = _normalizarQuantidadeInicial(
      usouParametrosDaTela
          ? widget.criancasIniciais
          : (evento?.totalCriancasCalculado ?? 0),
    );
    final bebesIniciais = _normalizarQuantidadeInicial(
      usouParametrosDaTela
          ? widget.bebesIniciais
          : (evento?.totalBebesCalculado ?? 0),
    );
    final totalInicial = adultosIniciais + criancasIniciais + bebesIniciais > 0
        ? adultosIniciais + criancasIniciais + bebesIniciais
        : (evento?.totalConvidadosCalculado ?? 0);

    await calculadoraController.prepararCalculadora(
      idEvento: idEvento,
      tipoEvento: tipoEvento,
      base: idEvento.isEmpty
          ? BaseCalculoFesta.manual
          : totalInicial > 0
              ? BaseCalculoFesta.previstos
              : BaseCalculoFesta.naoRecusados,
      duracaoInicialHoras: widget.duracaoInicialHoras,
      permitirEstimativaSemEvento: permiteSemEvento,
      idSessao: widget.idRascunho,
      adultosManuais: adultosIniciais,
      criancasManuais: criancasIniciais,
      bebesManuais: bebesIniciais,
      adultosEvento: adultosIniciais,
      criancasEvento: criancasIniciais,
      bebesEvento: bebesIniciais,
      totalConvidadosEvento: evento?.totalConvidadosCalculado ?? totalInicial,
      previsaoInformada: evento?.previsaoPublicoInformada,
      distribuicaoEtariaInformada: evento?.distribuicaoPublicoInformada,
    );

    if (!mounted) return;
    final limite = widget.orcamentoInicial ?? evento?.custoEstimado;
    if (limite != null && limite >= 0) {
      calculadoraController.atualizarOrcamentoDisponivel(limite);
    }
    if (idEvento.isEmpty &&
        widget.rascunho != null &&
        widget.rascunho!.id == widget.idRascunho &&
        widget.rascunho!.tipoEvento == tipoEvento) {
      calculadoraController.restaurarRascunho(widget.rascunho!);
      // O formulário pode ter sido atualizado depois da última estimativa.
      calculadoraController
          .atualizarOrcamentoDisponivel(widget.orcamentoInicial);
      calculadoraController.atualizarTotaisManuais(
          adultos: widget.adultosIniciais,
          criancas: widget.criancasIniciais,
          bebes: widget.bebesIniciais);
    }
    _preparada = true;
    _agendarRascunho();
    final atual = eventoController.eventoAtualEntidade;
    if (atual != null) calculadoraController.sincronizarEvento(atual);
    if (idEvento.isNotEmpty) {
      if (!calculadoraController.consultaOperacaoIniciada.value) {
        await calculadoraController.iniciarOperacaoEvento();
      }
      await cardapioController.escutarCardapios(idEvento);
    } else {
      idCardapioSelecionado.value = '';
    }

    if (!mounted) return;
    _sincronizarCamposManuais();
    _selecionarPrimeiroCardapioDisponivel();
    if (widget.idSimulacaoInicial != null) {
      final simulacao = calculadoraController.simulacoesSalvas
          .firstWhereOrNull((c) => c.idCalculo == widget.idSimulacaoInicial);
      if (simulacao != null) {
        await calculadoraController.carregarSimulacaoNoEditor(simulacao);
        if (mounted) {
          _sincronizarCamposManuais();
          setState(() => _passo = 2);
        }
      }
    }
  }

  Future<void> _atualizarDadosCalculadora() async {
    final c = calculadoraController;
    if (c.usandoContextoHistorico.value) c.retomarPoliticaPublicoAtual();
    c.usandoContextoHistorico.value = false;
    final atual = eventoController.eventoAtualEntidade;
    if (atual != null) c.sincronizarEvento(atual, aceitarPeriodo: true);
    await c.iniciarOperacaoEvento();
    final evento = c.idEventoAtual.value;
    final anterior = c.calculoAtual.value;
    if (evento.isNotEmpty) {
      await c.carregarConvidadosDoEvento(evento);
      if (!mounted || evento != c.idEventoAtual.value) return;
      if (c.baseCalculo.value != BaseCalculoFesta.manual) {
        c.aplicarTotaisDosConvidados();
      }
      await c.carregarContextoOrcamento();
      if (!mounted || evento != c.idEventoAtual.value) return;
      if (cardapioController.erro.value.isNotEmpty) {
        await cardapioController.escutarCardapios(evento);
      }
    }
    if (!mounted || evento != c.idEventoAtual.value) return;
    if (c.origemItensCalculadora.value != OrigemItensCalculadora.simulacao) {
      final selecoes = {
        for (final item in c.itensEstimativa) item.id: item.selecionado
      };
      await c.carregarItensBasePorTipoEvento(recalcularAposCarregar: false);
      if (!mounted || evento != c.idEventoAtual.value) return;
      c.itensEstimativa.assignAll(c.itensEstimativa
          .map((item) =>
              item.copyWith(selecionado: selecoes[item.id] ?? item.selecionado))
          .toList());
    }
    _assinaturaCardapio = '';
    _sincronizarCardapio();
    if (c.itensParaCalculo.isNotEmpty) c.calculoAtual.value = anterior;
    c.calcular();
    _sincronizarCamposManuais();
  }

  void _selecionarPrimeiroCardapioDisponivel() {
    if (calculadoraController.usandoContextoHistorico.value) {
      return;
    }
    final cardapios = _cardapiosDaFesta;

    if (cardapios.isEmpty) {
      idCardapioSelecionado.value = '';
      _sincronizarCardapio();
      return;
    }

    final selecionadoExiste = cardapios.any(
      (cardapio) => cardapio.idCardapio == idCardapioSelecionado.value,
    );

    if (!selecionadoExiste) {
      idCardapioSelecionado.value = cardapios.first.idCardapio;
    }
    _sincronizarCardapio();
  }

  Future<void> _criarCardapioInicial(
      DestinoPlanoEvento destino, CalculadoraFesta calculo) async {
    final c = calculadoraController;
    final assinatura = c.assinaturaProposta;
    final evento = c.idEventoAtual.value;
    bool contextoValido() =>
        mounted &&
        evento == c.idEventoAtual.value &&
        assinatura == c.assinaturaProposta &&
        !cardapioController.carregando.value &&
        cardapioController.erro.value.isEmpty &&
        _cardapiosDaFesta.isEmpty &&
        !c.usandoContextoHistorico.value &&
        c.operacaoCarregada.value &&
        c.erroOperacao.value.isEmpty;
    await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => Theme(
            data: themeController.materialTheme,
            child: CalculadoraCriarCardapioDialog(
                destino: destino,
                onSalvar: (titulo) async {
                  if (!contextoValido()) {
                    throw StateError(
                        'O planejamento mudou. Abra a proposta novamente.');
                  }
                  final proposta =
                      c.prepararCardapioInicial(destino, calculo, titulo);
                  final criado =
                      await cardapioController.criarPropostaInicial(proposta);
                  if (!mounted || c.idEventoAtual.value != evento) return;
                  // O retorno false é uma repetição: o conteúdo anterior continua intacto.
                  if (criado) {
                    c.regrasManuais.removeWhere(
                        (r) => proposta.regras.any((n) => n.id == r.id));
                    c.regrasManuais.addAll(proposta.regras);
                  }
                  idCardapioSelecionado.value = proposta.cardapio.idCardapio;
                  _sincronizarCardapio();
                  await c.carregarSimulacoesSalvas();
                })));
  }

  void _sincronizarCardapio() {
    if (calculadoraController.usandoContextoHistorico.value) {
      return;
    }
    final menus = _cardapiosDaFesta.where((m) => m.ativo).toList();
    final aguardandoAgenda = calculadoraController.agendaServicos
        .any((o) => !menus.any((m) => m.idCardapio == o.cardapio));
    calculadoraController.estadoCardapios.value =
        cardapioController.erro.value.isNotEmpty
            ? EstadoFontePlanejamento.erro
            : cardapioController.carregando.value || aguardandoAgenda
                ? EstadoFontePlanejamento.carregando
                : menus.any((m) => !cardapioController.itensPorCardapio
                        .containsKey(m.idCardapio))
                    ? EstadoFontePlanejamento.carregando
                    : menus.isEmpty
                        ? EstadoFontePlanejamento.vazia
                        : EstadoFontePlanejamento.disponivel;
    calculadoraController.atualizarCardapiosEvento({
      for (final m in menus)
        m.idCardapio: cardapioController.itensDoCardapio(m.idCardapio)
    }, {
      for (final m in menus)
        m.idCardapio:
            calculadoraController.tituloDaOcorrencia(m.idCardapio, m.titulo)
    },
        escopos: {
          for (final m in menus) m.idCardapio: m.escopo
        },
        completo: !aguardandoAgenda &&
            !cardapioController.carregando.value &&
            cardapioController.erro.value.isEmpty &&
            menus.every((m) =>
                cardapioController.itensPorCardapio.containsKey(m.idCardapio)));
    final id = idCardapioSelecionado.value;
    calculadoraController.idCardapioAtual = id;
    final selecionado = cardapioController.cardapioPorId(id);
    final disponivel = selecionado != null &&
        selecionado.idEvento == calculadoraController.idEventoAtual.value &&
        cardapioController.erro.value.isEmpty &&
        cardapioController.itensPorCardapio.containsKey(id);
    final itens =
        disponivel ? cardapioController.itensDoCardapio(id) : <CardapioItem>[];
    final assinatura = jsonEncode([
      id,
      disponivel,
      selecionado?.titulo,
      selecionado?.escopo.name,
      itens
          .map((item) => [
                item.idItem,
                item.nome,
                item.tipo.name,
                item.publicoAlvo.name,
                item.unidade,
                item.quantidadeFinal,
                item.disponibilidade?.toMap(),
                item.confirmado
              ])
          .toList()
    ]);
    if (assinatura == _assinaturaCardapio) return;
    _assinaturaCardapio = assinatura;
    calculadoraController.atualizarCardapio(itens,
        escopo: selecionado?.escopo ?? EscopoCardapio.naoDefinido,
        titulo: selecionado?.titulo ?? '',
        disponivel: disponivel);
  }

  void _mostrarPessoas() {
    final jaNoPasso = _passo == 0;
    if (!jaNoPasso) setState(() => _passo = 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final alvo = _chavePublico.currentContext;
      if (alvo == null) return;
      Scrollable.ensureVisible(
        alvo,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        alignment: 0.08,
      );
    });
  }

  void _sincronizarCamposManuais() {
    if (calculadoraController.publicoPlanejado.semDistribuicao) {
      adultosCtrl.clear();
      criancasCtrl.clear();
      bebesCtrl.clear();
      return;
    }
    adultosCtrl.text = calculadoraController.totalAdultos.value.toString();
    criancasCtrl.text = calculadoraController.totalCriancas.value.toString();
    bebesCtrl.text = calculadoraController.totalBebes.value.toString();
  }

  int _parseInt(String value) {
    return int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  int _normalizarQuantidadeInicial(int value) {
    return value < 0 ? 0 : value;
  }

  void _atualizarManual() {
    calculadoraController.atualizarTotaisManuais(
      adultos: _parseInt(adultosCtrl.text),
      criancas: _parseInt(criancasCtrl.text),
      bebes: _parseInt(bebesCtrl.text),
      intervencaoHumana: true,
    );
  }

  Future<void> _salvarCalculo() async {
    if (!calculadoraController.contextoEvento.estimarQuantidades) {
      Get.snackbar(
          'Dados pendentes', 'Atualize as fontes antes de salvar a simulação.');
      return;
    }
    if (calculadoraController.totalConvidados <= 0) {
      Get.snackbar(
        'Atenção',
        'Informe pelo menos um convidado para salvar o cálculo.',
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }
    calculadoraController.medicaoUso.registrarDecisao('salvar_simulacao');
    await calculadoraController.salvarCalculo();
  }

  Future<void> _enviarParaCardapio() async {
    if (!calculadoraController.contextoEvento.aplicarProposta) {
      Get.snackbar('Dados pendentes',
          'Atualize as fontes da festa antes de aplicar a proposta.');
      return;
    }
    if (calculadoraController.itensCalculados.isEmpty) {
      Get.snackbar(
        'Atenção',
        'Calcule as quantidades antes de enviar para o cardápio.',
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }

    final idCardapio = idCardapioSelecionado.value.trim();

    if (idCardapio.isEmpty) {
      Get.snackbar(
        'Atenção',
        'Selecione o cardápio de destino.',
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }

    final assinatura = _assinaturaCardapio;
    final resultados = calculadoraController.itensCalculados.toList();
    final escolhidos = await _revisarEnvioCardapio(resultados);
    if (!mounted || escolhidos == null || escolhidos.isEmpty) return;
    if (assinatura != _assinaturaCardapio ||
        idCardapio != idCardapioSelecionado.value ||
        !identical(resultados.first,
            calculadoraController.itensCalculados.firstOrNull)) {
      Get.snackbar('Planejamento atualizado',
          'O cálculo ou cardápio mudou. Revise as sugestões novamente.');
      return;
    }
    calculadoraController.medicaoUso.registrarDecisao('aplicar_cardapio');
    await calculadoraController.enviarResultadoParaCardapio(
        idCardapio: idCardapio, itensRevisados: escolhidos);
  }

  Future<void> _abrirMinhasSimulacoes() async {
    await calculadoraController.carregarSimulacoesSalvas();
    /*
    controllerTest.migrarTiposEventoFornecedores(
      dryRun: false,
      aplicar: true,
      sobrescrever: false,
      limite: 500,
    );
    */

    final aplicouSimulacao = await MinhasSimulacoesCalculadoraBottomSheet.show(
      context: context,
      controller: calculadoraController,
      themeController: themeController,
    );

    if (aplicouSimulacao == true) {
      idCardapioSelecionado.value = calculadoraController.idCardapioAtual;
      _sincronizarCamposManuais();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: widget.persistirRascunho == null || _permitirSaida,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          try {
            await _guardarRascunho();
            if (!mounted) return;
            setState(() => _permitirSaida = true);
            await WidgetsBinding.instance.endOfFrame;
            if (context.mounted) Navigator.pop(context);
          } catch (_) {}
        },
        child: Obx(() {
          final primary = themeController.primaryColor.value;
          final gradient = themeController.gradient.value;
          final onPrimary = themeController.onPrimaryColor.value;

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: FestaSystemUi.fundoEscuro,
            child: Theme(
              data: themeController.materialTheme.copyWith(
                iconTheme: IconThemeData(color: primary),
                sliderTheme: SliderThemeData(
                  activeTrackColor: primary,
                  inactiveTrackColor: primary.withValues(alpha: 0.22),
                  thumbColor: primary,
                  overlayColor: primary.withValues(alpha: 0.14),
                  valueIndicatorColor: primary,
                ),
                inputDecorationTheme: InputDecorationTheme(
                  prefixIconColor: primary,
                  suffixIconColor: primary,
                  iconColor: primary,
                ),
              ),
              child: Listener(
                  onPointerDown: (_) =>
                      calculadoraController.medicaoUso.atividade(),
                  child: Scaffold(
                    backgroundColor: const Color(0xFFF8FAFC),
                    appBar: FestaAppBar(
                      altura: 56,
                      titulo: 'Calculadora Inteligente',
                      themeController: themeController,
                      acoes: [
                        IconButton(
                          tooltip: 'Minhas simulações',
                          onPressed: _abrirMinhasSimulacoes,
                          icon: Icon(
                            Icons.history_rounded,
                            size: 22,
                            color: onPrimary,
                          ),
                        ),
                      ],
                    ),
                    body: calculadoraController.loading.value
                        ? Center(
                            child: CircularProgressIndicator(color: primary))
                        : RefreshIndicator(
                            color: primary,
                            onRefresh: _atualizarDadosCalculadora,
                            child: ListView(
                              key: const Key('rolagem_calculadora'),
                              padding:
                                  const EdgeInsets.fromLTRB(16, FestaPageInsets.belowAppBar, 16, 32),
                              children: [
                                CalculadoraContextoCard(
                                  controller: calculadoraController,
                                  evento: eventoController.eventoAtualEntidade,
                                  nomeRascunho: widget.nomeRascunho,
                                  periodoRascunho: widget.periodoRascunho,
                                  onPublico: _mostrarPessoas,
                                  onEscolhas: () {
                                    if (!_podeAlterarPlanejamento()) return;
                                    showDialog<void>(
                                        context: context,
                                        builder: (_) =>
                                            CalculadoraConfiguracaoDialog(
                                                controller:
                                                    calculadoraController));
                                  },
                                  onAtualizar: _atualizarDadosCalculadora,
                                ),
                                if (_estadoRascunho.value.isNotEmpty)
                                  Semantics(
                                      liveRegion: true,
                                      child: Text(_estadoRascunho.value)),
                                if (_erroSalvarRascunho.value.isNotEmpty)
                                  Card(
                                      child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                Semantics(
                                                    liveRegion: true,
                                                    child: Text(
                                                        _erroSalvarRascunho
                                                            .value,
                                                        style: TextStyle(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .error))),
                                                TextButton(
                                                    onPressed: () => unawaited(
                                                        _guardarRascunho()
                                                            .catchError(
                                                                (Object _) {})),
                                                    child: const Text(
                                                        'Tentar guardar novamente')),
                                              ]))),
                                if (calculadoraController
                                    .avisoContexto.value.isNotEmpty)
                                  Text(calculadoraController
                                      .avisoContexto.value),
                                if (!calculadoraController
                                        .usandoContextoHistorico.value &&
                                    calculadoraController
                                        .contextoEvento.pendencias.isNotEmpty)
                                  Card(
                                      child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                    'Planejamento parcial'),
                                                Text(calculadoraController
                                                        .contextoEvento
                                                        .estimarQuantidades
                                                    ? 'Quantidades disponíveis. Compras e custos dependem das fontes abaixo.'
                                                    : 'Aguarde as fontes para concluir as quantidades.'),
                                                Text(calculadoraController
                                                    .contextoEvento.pendencias
                                                    .join('\n')),
                                                TextButton(
                                                    onPressed:
                                                        _atualizarDadosCalculadora,
                                                    child: const Text(
                                                        'Atualizar dados da festa')),
                                              ]))),
                                CadastroPassosBar(
                                  atual: _passo,
                                  titulos: _titulosPassos,
                                  cor: primary,
                                ),
                                if (_passo == 0) ...[
                                  _buildHero(primary, gradient),
                                  const SizedBox(height: 10),
                                  KeyedSubtree(
                                    key: _chavePublico,
                                    child: _buildPublicoCalculoCard(primary),
                                  ),
                                ],
                                if (_passo == 1) ...[
                                  _buildPerfilFestaCard(primary),
                                  const SizedBox(height: 10),
                                  _buildDuracaoCard(primary),
                                ],
                                if (_passo == 2) ...[
                                  CalculadoraPlanoEventoCard(
                                    controller: calculadoraController,
                                    cardapios: cardapioController,
                                    onPublico: _mostrarPessoas,
                                    onCriarInicial: _criarCardapioInicial,
                                    onAjustar: (item) {
                                      idCardapioSelecionado.value =
                                          item.idCardapio;
                                      _sincronizarCardapio();
                                      _editarRegra(item: item);
                                    },
                                    onAbrirDestino: (id) {
                                      idCardapioSelecionado.value = id;
                                      _sincronizarCardapio();
                                      showDialog<void>(
                                          context: context,
                                          builder: (_) => Theme(
                                              data:
                                                  themeController.materialTheme,
                                              child: CalculadoraPropostaDialog(
                                                  controller:
                                                      calculadoraController)));
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  if (calculadoraController
                                      .usandoContextoHistorico.value) ...[
                                    _SectionCard(
                                        title: 'Dados da simulação salva',
                                        icon: Icons.history,
                                        primary: primary,
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                  'Pessoas, cardápio e valores correspondem ao histórico. Atualize para consultar a situação atual da festa.'),
                                              TextButton(
                                                  onPressed:
                                                      _atualizarDadosCalculadora,
                                                  child: const Text(
                                                      'Atualizar dados da festa'))
                                            ])),
                                    const SizedBox(height: 14),
                                  ],
                                  _buildCardapioCard(primary),
                                  if (!calculadoraController.estimativaSemEvento.value &&
                                      !calculadoraController
                                          .usandoContextoHistorico.value &&
                                      _cardapiosDaFesta.isNotEmpty)
                                    Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        child: FilledButton.tonalIcon(
                                            onPressed: () => showDialog<bool>(
                                                context: context,
                                                barrierDismissible: false,
                                                builder: (_) => Theme(
                                                    data: themeController
                                                        .materialTheme,
                                                    child: CalculadoraExecucaoDialog(
                                                        controller:
                                                            calculadoraController))),
                                            icon: const Icon(
                                                Icons.playlist_add_check),
                                            label:
                                                const Text('Organizar compras e tarefas'))),
                                  const SizedBox(height: 10),
                                  _buildDiagnostico(primary),
                                  const SizedBox(height: 14),
                                  if (calculadoraController
                                      .possuiResultado) ...[
                                    _buildResultadoCard(primary),
                                    const SizedBox(height: 14),
                                  ],
                                  _buildPlanejamentoCard(primary),
                                  const SizedBox(height: 14),
                                  if (!calculadoraController
                                      .possuiResultado) ...[
                                    _buildResultadoCard(primary),
                                    const SizedBox(height: 10),
                                  ],
                                  if (calculadoraController.possuiResultado ||
                                      calculadoraController
                                          .compromissosOrcamento.isNotEmpty)
                                    _buildProximasAcoes(primary),
                                  const SizedBox(height: 10),
                                  if (calculadoraController
                                          .analisandoIA.value ||
                                      calculadoraController.analiseIA.value !=
                                          null ||
                                      calculadoraController
                                          .erroAnaliseIA.value.isNotEmpty) ...[
                                    _buildAssistenteIACard(primary),
                                    const SizedBox(height: 10),
                                  ],
                                  Text(
                                    calculadoraController.possuiResultado
                                        ? 'Confira as porções antes de aplicar ao cardápio.'
                                        : 'Adicione ou selecione um item para liberar as ações.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      height: 1.35,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildAcoes(primary),
                                  const SizedBox(height: 10),
                                  _buildSimulacoesCard(primary),
                                ],
                                const SizedBox(height: 12),
                                if (_passo < 2)
                                  CadastroPassosAcoes(
                                    cor: primary,
                                    continuarLabel: 'Continuar',
                                    onContinuar: () => setState(() => _passo++),
                                    onVoltar: _passo == 0
                                        ? null
                                        : () => setState(() => _passo--),
                                  )
                                else
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: OutlinedButton(
                                      onPressed: () => setState(() => _passo--),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: primary,
                                        iconColor: primary,
                                        side: BorderSide(
                                          color:
                                              primary.withValues(alpha: 0.45),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: Text(
                                        'Voltar',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                  )),
            ),
          );
        }));
  }
}
