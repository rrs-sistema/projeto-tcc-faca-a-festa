// ignore_for_file: use_build_context_synchronously

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/domain/entities/analise_calculadora_ia.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa_item.dart';
import 'package:app_faca_festa/domain/entities/perfil_festa.dart';
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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _prepararCalculadora();
    });
  }

  @override
  void dispose() {
    _cardapiosWorker?.dispose();
    adultosCtrl.dispose();
    criancasCtrl.dispose();
    bebesCtrl.dispose();
    super.dispose();
  }

  Future<void> _prepararCalculadora() async {
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
        evento?.nomeEvento ??
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

    if (idEvento.isNotEmpty) {
      await cardapioController.escutarCardapios(idEvento);
    } else {
      idCardapioSelecionado.value = '';
    }

    _sincronizarCamposManuais();
    _selecionarPrimeiroCardapioDisponivel();
  }

  void _selecionarPrimeiroCardapioDisponivel() {
    final cardapios = cardapioController.cardapios;

    if (cardapios.isEmpty) {
      idCardapioSelecionado.value = '';
      return;
    }

    final selecionadoExiste = cardapios.any(
      (cardapio) => cardapio.idCardapio == idCardapioSelecionado.value,
    );

    if (!selecionadoExiste) {
      idCardapioSelecionado.value = cardapios.first.idCardapio;
    }
  }

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

    await calculadoraController.enviarResultadoParaCardapio(
        idCardapio: idCardapio);
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
                  onRefresh: _prepararCalculadora,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(6, 10, 6, 80),
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
                        _buildResultadoCard(primary),
                        const SizedBox(height: 10),
                        if (calculadoraController.analisandoIA.value ||
                            calculadoraController.analiseIA.value != null) ...[
                          _buildAssistenteIACard(primary),
                          const SizedBox(height: 10),
                        ],
                        _buildCardapioCard(primary),
                        const SizedBox(height: 10),
                        Text(
                          'Salve esta estimativa ou envie as sugestões para o cardápio da festa.',
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
