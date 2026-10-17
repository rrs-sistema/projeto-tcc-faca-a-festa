import 'package:app_faca_festa/domain/entities/registro_consumo_calculadora.dart';
import 'package:app_faca_festa/domain/entities/evento.dart';
import 'package:app_faca_festa/domain/services/cenario_alternativa_service.dart';
import 'package:app_faca_festa/domain/services/resumo_compras_service.dart';
import 'package:app_faca_festa/domain/services/lista_compras_calculadora_service.dart';
import 'package:app_faca_festa/presentation/modules/convidado/components/disponibilidade_cardapio_dialog.dart';
import '../widgets/calculadora_diagnostico_card.dart';
import '../widgets/calculadora_proposta_card.dart';
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
  final String? idEvento;
  final String? tipoEvento;
  final int duracaoInicialHoras;
  final bool permitirEstimativaSemEvento;
  final int adultosIniciais;
  final int criancasIniciais;
  final int bebesIniciais;
  final CalculadoraFestaController calculadoraController;
  final EventoController eventoController;
  final EventThemeController themeController;
  final CardapioController cardapioController;
  final FornecedorMigracaoAdminController fornecedorMigracaoAdminController;

  const CalculadoraFestaScreen({
    super.key,
    this.idEvento,
    this.tipoEvento,
    this.duracaoInicialHoras = 4,
    this.permitirEstimativaSemEvento = false,
    this.adultosIniciais = 0,
    this.criancasIniciais = 0,
    this.bebesIniciais = 0,
    required this.calculadoraController,
    required this.eventoController,
    required this.themeController,
    required this.cardapioController,
    required this.fornecedorMigracaoAdminController,
  });

  @override
  State<CalculadoraFestaScreen> createState() => _CalculadoraFestaScreenState();
}

class _CalculadoraFestaScreenState extends State<CalculadoraFestaScreen> {
  late final CalculadoraFestaController calculadoraController;
  late final FornecedorMigracaoAdminController controllerTest;
  late final EventoController eventoController;
  late final CardapioController cardapioController;
  late final EventThemeController themeController;

  final TextEditingController adultosCtrl = TextEditingController();
  final TextEditingController criancasCtrl = TextEditingController();
  final TextEditingController bebesCtrl = TextEditingController();

  final RxString idCardapioSelecionado = ''.obs;
  Worker? _cardapiosWorker;
  Worker? _itensCardapioWorker;
  Worker? _estadoCardapioWorker;
  String _assinaturaCardapio = '';

  List<Cardapio> get _cardapiosDaFesta => cardapioController.cardapios
      .where((item) =>
          item.idEvento == calculadoraController.idEventoAtual.value &&
          item.ativo)
      .toList();
  int _passo = 0;
  static const _titulosPassos = ['Pessoas', 'A festa', 'Sugestões'];

  @override
  void initState() {
    super.initState();

    calculadoraController = widget.calculadoraController;
    eventoController = widget.eventoController;
    themeController = widget.themeController;
    cardapioController = widget.cardapioController;
    controllerTest = widget.fornecedorMigracaoAdminController;

    _cardapiosWorker = ever(
      cardapioController.cardapios,
      (_) => _selecionarPrimeiroCardapioDisponivel(),
    );

    _itensCardapioWorker = ever(
        cardapioController.itensPorCardapio, (_) => _sincronizarCardapio());
    _estadoCardapioWorker = everAll(
        [cardapioController.carregando, cardapioController.erro],
        (_) => _sincronizarCardapio());

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _prepararCalculadora();
    });
  }

  @override
  void dispose() {
    _cardapiosWorker?.dispose();
    _itensCardapioWorker?.dispose();
    _estadoCardapioWorker?.dispose();
    adultosCtrl.dispose();
    criancasCtrl.dispose();
    bebesCtrl.dispose();
    super.dispose();
  }

  Future<void> _prepararCalculadora() async {
    _assinaturaCardapio = '';
    final evento = eventoController.eventoAtualEntidade;
    final idEvento = widget.idEvento ?? evento?.idEvento ?? '';
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
        eventoController.tipoEventoAtualEntidade?.nome ??
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
          : BaseCalculoFesta.todosConvidados,
      duracaoInicialHoras: widget.duracaoInicialHoras,
      permitirEstimativaSemEvento: permiteSemEvento,
      adultosManuais: adultosIniciais,
      criancasManuais: criancasIniciais,
      bebesManuais: bebesIniciais,
      adultosEvento: adultosIniciais,
      criancasEvento: criancasIniciais,
      bebesEvento: bebesIniciais,
      totalConvidadosEvento: totalInicial,
    );

    if (!mounted) return;
    if (evento?.custoEstimado != null && (evento!.custoEstimado ?? 0) > 0) {
      calculadoraController.atualizarOrcamentoDisponivel(evento.custoEstimado);
    }
    if (idEvento.isNotEmpty) {
      await calculadoraController.iniciarOperacaoEvento();
      await cardapioController.escutarCardapios(idEvento);
    } else {
      idCardapioSelecionado.value = '';
    }

    if (!mounted) return;
    _sincronizarCamposManuais();
    _selecionarPrimeiroCardapioDisponivel();
  }

  Future<void> _atualizarDadosCalculadora() async {
    final c = calculadoraController;
    c.usandoContextoHistorico.value = false;
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

  void _sincronizarCardapio() {
    if (calculadoraController.usandoContextoHistorico.value) {
      return;
    }
    final menus = _cardapiosDaFesta.where((m) => m.ativo).toList();
    calculadoraController.atualizarCardapiosEvento({
      for (final m in menus)
        m.idCardapio: cardapioController.itensDoCardapio(m.idCardapio)
    }, {
      for (final m in menus) m.idCardapio: m.titulo
    },
        completo: !cardapioController.carregando.value &&
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
        titulo: selecionado?.titulo ?? '', disponivel: disponivel);
  }

  void _mostrarPessoas() => setState(() => _passo = 0);

  void _sincronizarCamposManuais() {
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
    );
  }

  Future<void> _salvarCalculo() async {
    if (calculadoraController.totalConvidados <= 0) {
      Get.snackbar(
        'Atenção',
        'Informe pelo menos um convidado para salvar o cálculo.',
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }
    await calculadoraController.salvarCalculo();
  }

  Future<void> _enviarParaCardapio() async {
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
    return Obx(() {
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
          child: Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: FestaAppBar(
              altura: 70,
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
                ? Center(child: CircularProgressIndicator(color: primary))
                : RefreshIndicator(
                    color: primary,
                    onRefresh: _atualizarDadosCalculadora,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      children: [
                        CadastroPassosBar(
                          atual: _passo,
                          titulos: _titulosPassos,
                          cor: primary,
                        ),
                        if (_passo == 0) ...[
                          _buildHero(primary, gradient),
                          const SizedBox(height: 10),
                          _buildBaseCalculoCard(primary),
                          const SizedBox(height: 10),
                          _buildTotaisCard(primary),
                        ],
                        if (_passo == 1) ...[
                          _buildPerfilFestaCard(primary),
                          const SizedBox(height: 10),
                          _buildDuracaoCard(primary),
                        ],
                        if (_passo == 2) ...[
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
                                          onPressed: _atualizarDadosCalculadora,
                                          child: const Text(
                                              'Atualizar dados da festa'))
                                    ])),
                            const SizedBox(height: 14),
                          ],
                          _buildCardapioCard(primary),
                          const SizedBox(height: 10),
                          Theme(
                              data: themeController.materialTheme,
                              child: CalculadoraPropostaCard(
                                  controller: calculadoraController,
                                  onAjustar: (item) =>
                                      _editarRegra(item: item))),
                          const SizedBox(height: 10),
                          _buildDiagnostico(primary),
                          const SizedBox(height: 14),
                          if (calculadoraController.possuiResultado) ...[
                            _buildResultadoCard(primary),
                            const SizedBox(height: 14),
                          ],
                          _buildPlanejamentoCard(primary),
                          const SizedBox(height: 14),
                          if (!calculadoraController.possuiResultado) ...[
                            _buildResultadoCard(primary),
                            const SizedBox(height: 10),
                          ],
                          if (calculadoraController.possuiResultado ||
                              calculadoraController
                                  .compromissosOrcamento.isNotEmpty)
                            _buildProximasAcoes(primary),
                          const SizedBox(height: 10),
                          if (calculadoraController.analisandoIA.value ||
                              calculadoraController.analiseIA.value != null ||
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
                                  color: primary.withValues(alpha: 0.45),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
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
          ),
        ),
      );
    });
  }
}
