// ignore_for_file: use_build_context_synchronously

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/calculadora/calculadora_festa_controller.dart';
import '../../../controllers/tests/fornecedor_migracao_admin_controller.dart';
import '../../../data/models/evento/analise_calculadora_ia_model.dart';
import '../../../data/models/evento/calculadora_festa_item_model.dart';
import '../../../controllers/convidado/cardapio_controller.dart';
import '../../../domain/repositories/cardapio_repository.dart';
import '../../../data/models/evento/calculadora_festa_model.dart';
import '../../../controllers/evento_controller.dart';
import '../../../data/models/evento/perfil_festa_model.dart';
import 'minhas_simulacoes_calculadora_bottom_sheet.dart';
import 'calculadora_item_icon_helper.dart';

// ============================================================================
// 🔹 Tela da Calculadora Inteligente de Festa (Versão Ultracompacta)
// ============================================================================

class CalculadoraFestaScreen extends StatefulWidget {
  final String? idEvento;
  final String? tipoEvento;
  final int duracaoInicialHoras;
  final bool permitirEstimativaSemEvento;
  final int adultosIniciais;
  final int criancasIniciais;
  final int bebesIniciais;

  const CalculadoraFestaScreen({
    super.key,
    this.idEvento,
    this.tipoEvento,
    this.duracaoInicialHoras = 4,
    this.permitirEstimativaSemEvento = false,
    this.adultosIniciais = 0,
    this.criancasIniciais = 0,
    this.bebesIniciais = 0,
  });

  @override
  State<CalculadoraFestaScreen> createState() => _CalculadoraFestaScreenState();
}

class _CalculadoraFestaScreenState extends State<CalculadoraFestaScreen> {
  late final CalculadoraFestaController calculadoraController;
  late final FornecedorMigracaoAdminController controllerTest;
  late final EventoController eventoController;
  late final CardapioController cardapioController;

  final TextEditingController adultosCtrl = TextEditingController();
  final TextEditingController criancasCtrl = TextEditingController();
  final TextEditingController bebesCtrl = TextEditingController();

  final RxString idCardapioSelecionado = ''.obs;
  Worker? _cardapiosWorker;

  @override
  void initState() {
    super.initState();

    calculadoraController = Get.isRegistered<CalculadoraFestaController>()
        ? Get.find<CalculadoraFestaController>()
        : Get.put(CalculadoraFestaController());

    eventoController = Get.find<EventoController>();

    cardapioController = Get.isRegistered<CardapioController>()
        ? Get.find<CardapioController>()
        : Get.put(
            CardapioController(repository: Get.find<CardapioRepository>()),
          );

    controllerTest = Get.isRegistered<FornecedorMigracaoAdminController>()
        ? Get.find<FornecedorMigracaoAdminController>()
        : Get.put(FornecedorMigracaoAdminController());

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

    final adultosIniciais =
        _normalizarQuantidadeInicial(widget.adultosIniciais);
    final criancasIniciais =
        _normalizarQuantidadeInicial(widget.criancasIniciais);
    final bebesIniciais = _normalizarQuantidadeInicial(widget.bebesIniciais);
    final totalInicial = adultosIniciais + criancasIniciais + bebesIniciais;

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
    );

    if (aplicouSimulacao == true) {
      _sincronizarCamposManuais();
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        toolbarHeight: 48, // AppBar mais fina
        title: Text(
          'Calculadora Inteligente',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        actions: [
          IconButton(
            tooltip: 'Minhas simulações',
            onPressed: _abrirMinhasSimulacoes,
            icon: const Icon(Icons.history_rounded, size: 22),
          ),
        ],
      ),
      body: Obx(() {
        if (calculadoraController.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: _prepararCalculadora,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                6, 10, 6, 80), // Margens laterais reduzidas
            children: [
              _buildHero(primary),
              const SizedBox(height: 10), // Espaçamentos gerais reduzidos
              _buildSimulacoesCard(primary),
              const SizedBox(height: 10),
              _buildBaseCalculoCard(primary),
              const SizedBox(height: 10),
              _buildPerfilFestaCard(primary),
              const SizedBox(height: 10),
              _buildTotaisCard(primary),
              const SizedBox(height: 10),
              _buildDuracaoCard(primary),
              const SizedBox(height: 10),
              if (calculadoraController.analisandoIA.value ||
                  calculadoraController.analiseIA.value != null) ...[
                _buildAssistenteIACard(primary),
                const SizedBox(height: 10),
              ],
              _buildResultadoCard(primary),
              const SizedBox(height: 10),
              _buildCardapioCard(primary),
              const SizedBox(height: 12),
              _buildAcoes(primary),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHero(Color primary) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: 0.92),
            primary.withValues(alpha: 0.62)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Cálculo de Itens',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Sugestões inteligentes baseadas no público e duração.',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulacoesCard(Color primary) {
    return _SectionCard(
      title: 'Simulações salvas',
      icon: Icons.history_rounded,
      trailing: Obx(() {
        final total = calculadoraController.simulacoesSalvas.length;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            total.toString(),
            style: GoogleFonts.poppins(
              color: primary,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        );
      }),
      child: SizedBox(
        width: double.infinity,
        height: 38, // Botão mais compacto
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            side: BorderSide(color: primary.withValues(alpha: 0.45)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: EdgeInsets.zero,
          ),
          onPressed: _abrirMinhasSimulacoes,
          icon: const Icon(Icons.auto_awesome_motion_rounded, size: 18),
          label: Text(
            'Abrir minhas simulações',
            style:
                GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildBaseCalculoCard(Color primary) {
    return _SectionCard(
      title: 'Base de cálculo',
      icon: Icons.tune_rounded,
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: BaseCalculoFesta.values.map((base) {
            final selected = calculadoraController.baseCalculo.value == base;

            return ChoiceChip(
              label: Text(base.label),
              selected: selected,
              selectedColor: primary.withValues(alpha: 0.18),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              labelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
                color: selected ? primary : Colors.grey.shade700,
              ),
              onSelected: (_) {
                calculadoraController.alterarBaseCalculo(base);
                _sincronizarCamposManuais();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPerfilFestaCard(Color primary) {
    return Obx(() {
      final perfilAtual = calculadoraController.perfilSelecionado.value;
      final margemPercentual =
          (calculadoraController.margemEmUso * 100).round();

      return _SectionCard(
        title: 'Perfil da festa',
        icon: Icons.auto_graph_rounded,
        trailing: Text(
          '$margemPercentual% margem',
          style: GoogleFonts.poppins(
            color: primary,
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: TipoPerfilFesta.values.map((tipo) {
                final perfilTipo = PerfilFestaModel.fromTipo(tipo);
                final selected = _normalizarTexto(perfilAtual.nome) ==
                    _normalizarTexto(perfilTipo.nome);

                return _buildPerfilFestaChip(
                  primary: primary,
                  tipo: tipo,
                  selected: selected,
                );
              }).toList(),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 13,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Ajusta as regras dos itens e a margem da estimativa.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontSize: 10.2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPerfilFestaChip({
    required Color primary,
    required TipoPerfilFesta tipo,
    required bool selected,
  }) {
    final borderRadius = BorderRadius.circular(12);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: () => calculadoraController.selecionarPerfil(tipo),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? primary.withValues(alpha: 0.12) : Colors.white,
            borderRadius: borderRadius,
            border: Border.all(
              color: selected
                  ? primary.withValues(alpha: 0.45)
                  : Colors.black.withValues(alpha: 0.12),
              width: selected ? 1.2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : const [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: selected
                      ? primary.withValues(alpha: 0.14)
                      : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  selected ? Icons.check_rounded : _iconePerfilFesta(tipo),
                  size: selected ? 14 : 13,
                  color: selected ? primary : Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                _labelPerfilFesta(tipo),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  color: selected ? primary : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _labelPerfilFesta(TipoPerfilFesta tipo) {
    final nome = PerfilFestaModel.fromTipo(tipo).nome.trim();

    if (nome.isNotEmpty) {
      return nome;
    }

    final key = _enumKey(tipo);

    if (key.contains('econom')) return 'Econômico';
    if (key.contains('premium')) return 'Premium';
    return 'Padrão';
  }

  IconData _iconePerfilFesta(TipoPerfilFesta tipo) {
    final key = _enumKey(tipo);

    if (key.contains('econom')) {
      return Icons.savings_rounded;
    }

    if (key.contains('premium')) {
      return Icons.workspace_premium_rounded;
    }

    return Icons.verified_rounded;
  }

  String _enumKey(Object value) {
    return value.toString().split('.').last.trim().toLowerCase();
  }

  String _normalizarTexto(String value) {
    return value.trim().toLowerCase();
  }

  Widget _buildTotaisCard(Color primary) {
    final manual =
        calculadoraController.baseCalculo.value == BaseCalculoFesta.manual;

    return _SectionCard(
      title: 'Convidados',
      icon: Icons.groups_rounded,
      trailing: Text(
        '${calculadoraController.totalConvidados} total',
        style: GoogleFonts.poppins(
          color: primary,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _NumberField(
                  controller: adultosCtrl,
                  label: 'Adultos',
                  icon: Icons.person_rounded,
                  enabled: manual,
                  onChanged: (_) => _atualizarManual(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NumberField(
                  controller: criancasCtrl,
                  label: 'Crianças',
                  icon: Icons.child_care_rounded,
                  enabled: manual,
                  onChanged: (_) => _atualizarManual(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NumberField(
                  controller: bebesCtrl,
                  label: 'Bebês',
                  icon: Icons.baby_changing_station_rounded,
                  enabled: manual,
                  onChanged: (_) => _atualizarManual(),
                ),
              ),
            ],
          ),
          if (!manual) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Preenchido via lista de convidados.',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDuracaoCard(Color primary) {
    return _SectionCard(
      title: 'Duração',
      icon: Icons.schedule_rounded,
      trailing: Text(
        '${calculadoraController.duracaoHoras.value}h',
        style: GoogleFonts.poppins(
          color: primary,
          fontWeight: FontWeight.w900,
          fontSize: 14,
        ),
      ),
      child: SizedBox(
        height: 24, // Comprime a altura do slider
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
          ),
          child: Slider(
            value: calculadoraController.duracaoHoras.value.toDouble(),
            min: 2,
            max: 8,
            divisions: 6,
            onChanged: (value) =>
                calculadoraController.atualizarDuracao(value.round()),
          ),
        ),
      ),
    );
  }

  Widget _buildResultadoCard(Color primary) {
    final itens = calculadoraController.itensCalculados;

    return _SectionCard(
      title: 'Sugestões',
      icon: Icons.insights_rounded,
      child: itens.isEmpty
          ? const _EmptyMessage(
              icon: Icons.calculate_outlined,
              text: 'Informe convidados para calcular.',
            )
          : Column(
              children:
                  itens.map((item) => _ResultadoItemTile(item: item)).toList(),
            ),
    );
  }

  Widget _buildAssistenteIACard(Color primary) {
    final analisando = calculadoraController.analisandoIA.value;
    final analise = calculadoraController.analiseIA.value;

    return _SectionCard(
      title: 'Assistente IA',
      icon: Icons.auto_awesome_rounded,
      trailing: analisando
          ? SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: primary),
            )
          : _MiniBadge(
              label: analise?.statusOrcamento ?? 'Pronta',
              color: analise?.acimaDoOrcamento == true
                  ? Colors.orange
                  : Colors.teal,
            ),
      child: analisando && analise == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analisando sua simulação...',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    color: primary,
                    backgroundColor: primary.withValues(alpha: 0.10),
                  ),
                ),
              ],
            )
          : _AnaliseIACompacta(
              analise: analise,
              primary: primary,
              onDetalhes:
                  analise == null ? null : () => _abrirDetalhesIA(analise),
            ),
    );
  }

  Future<void> _abrirDetalhesIA(AnaliseCalculadoraIAModel analise) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AnaliseIADetalhesSheet(analise: analise),
    );
  }

  Widget _buildCardapioCard(Color primary) {
    return _SectionCard(
      title: 'Cardápio',
      icon: Icons.restaurant_menu_rounded,
      child: Obx(() {
        final cardapios = cardapioController.cardapios;

        if (cardapios.isEmpty) {
          return const _EmptyMessage(
            icon: Icons.no_meals_outlined,
            text: 'Crie um cardápio antes de enviar.',
          );
        }

        final selectedValue =
            cardapios.any((c) => c.idCardapio == idCardapioSelecionado.value)
                ? idCardapioSelecionado.value
                : null;

        return SizedBox(
          height: 44, // Força uma altura menor no dropdown
          child: DropdownButtonFormField<String>(
            value: selectedValue,
            isDense: true,
            decoration: InputDecoration(
              labelText: 'Destino',
              labelStyle: GoogleFonts.poppins(fontSize: 12),
              prefixIcon: const Icon(Icons.restaurant_rounded, size: 18),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            items: cardapios.map((cardapio) {
              return DropdownMenuItem<String>(
                value: cardapio.idCardapio,
                child: Text(cardapio.titulo,
                    style: GoogleFonts.poppins(fontSize: 12)),
              );
            }).toList(),
            onChanged: (value) => idCardapioSelecionado.value = value ?? '',
          ),
        );
      }),
    );
  }

  Widget _buildAcoes(Color primary) {
    return Obx(() {
      final salvando = calculadoraController.salvando.value;
      final enviando = calculadoraController.enviandoParaCardapio.value;

      return Row(
        // Colocando os botões lado a lado para economizar mais espaço
        children: [
          Expanded(
            child: SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: EdgeInsets.zero,
                ),
                onPressed: salvando ? null : _salvarCalculo,
                icon: salvando
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(
                  salvando ? 'Salvando...' : 'Salvar',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  side: BorderSide(color: primary.withValues(alpha: 0.55)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: EdgeInsets.zero,
                ),
                onPressed: enviando || idCardapioSelecionado.value.isEmpty
                    ? null
                    : _enviarParaCardapio,
                icon: enviando
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: primary))
                    : const Icon(Icons.playlist_add_check_rounded, size: 18),
                label: Text(
                  enviando ? 'Enviando...' : 'Adicionar',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _SectionCard(
      {required this.title,
      required this.icon,
      required this.child,
      this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Theme.of(context).primaryColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const _NumberField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40, // Altura restrita do TextField
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: onChanged,
        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(fontSize: 11),
          prefixIcon: Icon(icon, size: 16),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
        ),
      ),
    );
  }
}

class _AnaliseIACompacta extends StatelessWidget {
  final AnaliseCalculadoraIAModel? analise;
  final Color primary;
  final VoidCallback? onDetalhes;

  const _AnaliseIACompacta({
    required this.analise,
    required this.primary,
    required this.onDetalhes,
  });

  @override
  Widget build(BuildContext context) {
    final data = analise;

    if (data == null) {
      return const _EmptyMessage(
        icon: Icons.auto_awesome_outlined,
        text: 'A análise inteligente aparecerá após o cálculo.',
      );
    }

    final primeiraSugestao =
        data.sugestoes.isNotEmpty ? data.sugestoes.first : null;
    final resumo = data.resumo.trim().isNotEmpty
        ? data.resumo.trim()
        : primeiraSugestao?.descricao.trim() ??
            'Análise inteligente concluída.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _IndicadorIA(
                label: 'Conforto',
                value: _formatPercent(data.indiceConforto),
                color: Colors.teal,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _IndicadorIA(
                label: 'Risco',
                value: _formatPercent(data.indiceRiscoFaltarItens),
                color: data.indiceRiscoFaltarItens >= 70
                    ? Colors.redAccent
                    : Colors.orange,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _IndicadorIA(
                label: 'Economia',
                value: _formatPercent(data.indiceEconomia),
                color: primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          resumo,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 11.2,
            height: 1.25,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (primeiraSugestao != null) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            decoration: BoxDecoration(
              color: _corSugestao(primeiraSugestao).withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _corSugestao(primeiraSugestao).withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _iconeSugestao(primeiraSugestao),
                  size: 16,
                  color: _corSugestao(primeiraSugestao),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    primeiraSugestao.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ),
                if (onDetalhes != null)
                  InkWell(
                    onTap: onDetalhes,
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      child: Text(
                        'Ver',
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  static String _formatPercent(double value) {
    final normalized = value.clamp(0, 100).round();
    return '$normalized%';
  }

  static Color _corSugestao(SugestaoCalculadoraIAModel sugestao) {
    switch (sugestao.prioridade) {
      case PrioridadeSugestaoCalculadoraIA.alta:
        return Colors.orange;
      case PrioridadeSugestaoCalculadoraIA.media:
        return Colors.blueGrey;
      case PrioridadeSugestaoCalculadoraIA.baixa:
        return Colors.teal;
    }
  }

  static IconData _iconeSugestao(SugestaoCalculadoraIAModel sugestao) {
    return CalculadoraItemIconHelper.resolverIcone(
      nome: '${sugestao.titulo} ${sugestao.descricao}',
      tipoItem: sugestao.tipo.toString(),
      fallback: _iconeSugestaoPorTipo(sugestao.tipo),
    );
  }

  static IconData _iconeSugestaoPorTipo(TipoSugestaoCalculadoraIA tipo) {
    switch (tipo) {
      case TipoSugestaoCalculadoraIA.economia:
        return Icons.savings_rounded;
      case TipoSugestaoCalculadoraIA.alerta:
        return Icons.warning_amber_rounded;
      case TipoSugestaoCalculadoraIA.melhoria:
        return Icons.tips_and_updates_rounded;
      case TipoSugestaoCalculadoraIA.excesso:
        return Icons.remove_circle_outline_rounded;
      case TipoSugestaoCalculadoraIA.falta:
        return Icons.add_circle_outline_rounded;
      case TipoSugestaoCalculadoraIA.planejamento:
        return Icons.event_note_rounded;
    }
  }
}

class _IndicadorIA extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _IndicadorIA({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 130),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 9.8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _AnaliseIADetalhesSheet extends StatelessWidget {
  final AnaliseCalculadoraIAModel analise;

  const _AnaliseIADetalhesSheet({required this.analise});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final topSugestoes = analise.sugestoes.take(5).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.72,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    analise.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _IndicadorIA(
                        label: 'Conforto',
                        value: _AnaliseIACompacta._formatPercent(
                            analise.indiceConforto),
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _IndicadorIA(
                        label: 'Risco',
                        value: _AnaliseIACompacta._formatPercent(
                          analise.indiceRiscoFaltarItens,
                        ),
                        color: analise.indiceRiscoFaltarItens >= 70
                            ? Colors.redAccent
                            : Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _IndicadorIA(
                        label: 'Economia',
                        value: _AnaliseIACompacta._formatPercent(
                            analise.indiceEconomia),
                        color: primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _DetalheBloco(
                  title: 'Resumo',
                  text: analise.resumo.trim().isEmpty
                      ? 'Análise inteligente concluída para esta simulação.'
                      : analise.resumo,
                ),
                const SizedBox(height: 10),
                _DetalheBloco(
                  title: 'Orçamento',
                  text:
                      '${analise.statusOrcamento} • Diferença: ${_formatMoney(analise.diferencaOrcamento)}',
                ),
                if (topSugestoes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Sugestões',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final sugestao in topSugestoes)
                    _SugestaoIATile(sugestao: sugestao),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetalheBloco extends StatelessWidget {
  final String title;
  final String text;

  const _DetalheBloco({
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              height: 1.3,
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SugestaoIATile extends StatelessWidget {
  final SugestaoCalculadoraIAModel sugestao;

  const _SugestaoIATile({required this.sugestao});

  @override
  Widget build(BuildContext context) {
    final color = _AnaliseIACompacta._corSugestao(sugestao);

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_AnaliseIACompacta._iconeSugestao(sugestao),
              size: 17, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sugestao.titulo,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sugestao.descricao,
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    height: 1.25,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultadoItemTile extends StatelessWidget {
  final CalculadoraFestaItemModel item;

  const _ResultadoItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final Color color = item.adicionadoAoCardapio
        ? Colors.teal
        : Theme.of(context).primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_resolverIconeItem(item), color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nome,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                Text(
                  item.regraAplicada,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.quantidadeFormatada,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  IconData _resolverIconeItem(CalculadoraFestaItemModel item) {
    return CalculadoraItemIconHelper.resolverIcone(
      tipoItem: item.tipoItem,
      nome: item.nome,
      categoria: item.regraAplicada,
      fallback: Icons.restaurant_menu_rounded,
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyMessage({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatMoney(double value) {
  final normalized = value.toStringAsFixed(2).replaceAll('.', ',');
  final parts = normalized.split(',');
  final integer = parts.first.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return 'R\$ $integer,${parts.last}';
}
