import 'package:app_faca_festa/domain/entities/cadastro_evento_rascunho.dart';
import 'dart:async';
import 'package:app_faca_festa/domain/entities/rascunho_calculadora.dart';
// ignore_for_file: use_build_context_synchronously

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/core/utils/form_masks.dart';
import 'package:app_faca_festa/core/utils/form_validators.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/tema_festa_controller.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_cadastro_controller.dart';
import 'package:app_faca_festa/presentation/modules/usuario/components/endereco/endereco_section.dart';
import './evento_preview_titulo_widget.dart';
import './tema_festa_selector.dart';
import 'package:app_faca_festa/domain/entities/evento.dart';
import 'package:app_faca_festa/domain/services/jornada_cadastro_festa.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/fornecedor_migracao_admin_controller.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/cardapio_controller.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_controller.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/pages/calculadora_festa_screen.dart';
import 'package:app_faca_festa/presentation/widgets/cadastro_passos_bar.dart';

Future<void> showCadastroEventoBottomSheet(
  BuildContext context, {
  required EventoCadastroController controller,
  required EventThemeController theme,
  required TemaFestaController temasController,
  required CalculadoraFestaController calculadoraController,
  required EventoController eventoController,
  required CardapioController cardapioController,
  required FornecedorMigracaoAdminController fornecedorMigracaoAdminController,
  Evento? eventoParaEdicao,
}) async {
  // A tela de tipos já definiu esta escolha. Limpar um formulário anterior não
  // pode apagar a identidade do novo cadastro nem seu endereço pré-preenchido.
  final tipoInicial = controller.tipoEventoSelecionado.value;
  void iniciarNovo() {
    controller.limpar(manterEndereco: true);
    controller.tipoEventoSelecionado.value = tipoInicial;
    controller.atualizarPreview();
  }

  EasyLoading.show(status: 'A carregar informações...');

  await controller.carregarTiposEvento();
  await temasController.carregar();

  if (eventoParaEdicao != null) {
    controller.carregarEvento(eventoParaEdicao);
    await controller.recuperarRascunho();
  } else {
    final LeituraCadastrosLocais locais;
    try {
      locais = await controller.listarCadastrosLocais();
    } catch (_) {
      EasyLoading.dismiss();
      Get.snackbar('Rascunhos indisponíveis',
          'Não foi possível ler os cadastros deste aparelho. Tente novamente.');
      return;
    }
    if (locais.cadastros.isNotEmpty || locais.corrompidos.isNotEmpty) {
      EasyLoading.dismiss();
      final escolha = await showDialog<String>(
          context: context,
          builder: (dialogContext) => AlertDialog(
                title: const Text('Continuar um cadastro?'),
                content: SizedBox(
                    width: double.maxFinite,
                    child: SingleChildScrollView(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('Rascunhos guardados somente neste aparelho.'),
                      if (locais.corrompidos.isNotEmpty)
                        const Text(
                            'Há um rascunho que não pôde ser lido. O original foi preservado.'),
                      for (final c in locais.cadastros)
                        ListTile(
                            title: Text(
                                (c.formulario['campos'] as Map?)?['nome']
                                            ?.toString()
                                            .isNotEmpty ==
                                        true
                                    ? (c.formulario['campos'] as Map)['nome']
                                        .toString()
                                    : 'Cadastro em andamento'),
                            subtitle: Text(c.eventoConfirmado
                                ? 'Evento salvo; conclusão pendente'
                                : 'Retomar formulário e estimativa'),
                            onTap: () => Navigator.pop(dialogContext, c.id),
                            trailing: IconButton(
                                tooltip: 'Descartar este rascunho',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  await controller.descartarCadastroLocal(c);
                                  if (dialogContext.mounted) {
                                    Navigator.pop(dialogContext, 'novo');
                                  }
                                })),
                    ]))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Voltar')),
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext, 'novo'),
                      child: const Text('Iniciar novo'))
                ],
              ));
      if (escolha == null) return;
      if (escolha != 'novo') {
        try {
          await controller.retomarCadastro(
              locais.cadastros.firstWhere((c) => c.id == escolha));
        } catch (_) {
          Get.snackbar('Cadastro preservado',
              'Não foi possível conferir o evento salvo. Tente retomar novamente.');
          return;
        }
      } else {
        iniciarNovo();
      }
    } else {
      iniciarNovo();
    }
  }

  controller.observarCadastroLocal();
  final primary = theme.primaryColor.value;
  final dinheiroMask = FormMasks.dinheiro();

  final tipoNormalizado = controller.tipoEventoSelecionado.value?.nome
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-zá-úà-ùãõâêîôûç\s]'), '')
          .trim() ??
      '';

  EasyLoading.dismiss();

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _CadastroEventoSheet(
        controller: controller,
        theme: theme,
        temasController: temasController,
        calculadoraController: calculadoraController,
        eventoController: eventoController,
        cardapioController: cardapioController,
        fornecedorMigracaoAdminController: fornecedorMigracaoAdminController,
        eventoParaEdicao: eventoParaEdicao,
        primary: primary,
        dinheiroMask: dinheiroMask,
        tipoNormalizado: tipoNormalizado,
      );
    },
  );
}

class _CadastroEventoSheet extends StatefulWidget {
  const _CadastroEventoSheet({
    required this.controller,
    required this.theme,
    required this.temasController,
    required this.calculadoraController,
    required this.eventoController,
    required this.cardapioController,
    required this.fornecedorMigracaoAdminController,
    required this.eventoParaEdicao,
    required this.primary,
    required this.dinheiroMask,
    required this.tipoNormalizado,
  });

  final EventoCadastroController controller;
  final EventThemeController theme;
  final TemaFestaController temasController;
  final CalculadoraFestaController calculadoraController;
  final EventoController eventoController;
  final CardapioController cardapioController;
  final FornecedorMigracaoAdminController fornecedorMigracaoAdminController;
  final Evento? eventoParaEdicao;
  final Color primary;
  final TextInputFormatter dinheiroMask;
  final String tipoNormalizado;

  @override
  State<_CadastroEventoSheet> createState() => _CadastroEventoSheetState();
}

class _CadastroEventoSheetState extends State<_CadastroEventoSheet>
    with WidgetsBindingObserver {
  final _rolagem = ScrollController();
  void _inicioDaEtapa() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _rolagem.hasClients) _rolagem.jumpTo(0);
      });
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      unawaited(controller.salvarCadastroLocal().catchError((Object _) {}));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.pararObservacaoCadastro();
    _rolagem.dispose();
    super.dispose();
  }

  bool _permitirSaida = false;
  Future<void> _fechar() async {
    if (controller.carregando.value) return;
    try {
      await controller.salvarCadastroLocal();
      if (!mounted) return;
      setState(() => _permitirSaida = true);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.pop(context);
    } catch (_) {
      /* A mensagem observável mantém o formulário recuperável aberto. */
    }
  }

  /// A estimativa já foi gravada no evento. Festa nova abre a home;
  /// edição volta para a tela de onde o cadastro foi aberto.
  Future<void> _continuar(Evento evento, RascunhoCalculadora? rascunho) async {
    if (!mounted) return;
    setState(() => _permitirSaida = true);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final destino = JornadaCadastroFesta.depoisDeSalvar(
      criando: widget.eventoParaEdicao == null,
    );
    Navigator.pop(context);
    if (destino == DestinoCadastroEvento.home) {
      controller.app.abrirHomeOrganizador();
    }
  }

  int _passo = 0;

  static const _titulosPassos = ['A festa', 'Quando e onde', 'Convidados'];

  EventoCadastroController get controller => widget.controller;
  Color get primary => widget.primary;

  Future<void> _avancar() async {
    final valido = controller.formKey.currentState?.validate() ?? false;
    if (!valido) return;
    try {
      await controller.salvarCadastroLocal();
    } catch (_) {
      return;
    }
    if (mounted) {
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() => _passo++);
      _inicioDaEtapa();
    }
  }

  void _voltar() {
    if (_passo == 0) return;
    setState(() => _passo--);
    _inicioDaEtapa();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: _permitirSaida,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) unawaited(_fechar());
        },
        child: Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom),
            child: FractionallySizedBox(
              heightFactor: 0.90,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 8),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.celebration_rounded,
                                  color: primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    controller.isEditando
                                        ? 'Editar Evento'
                                        : 'Novo Evento',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF111827),
                                    ),
                                  ),
                                  Text(
                                    'Preencha em 3 passos curtos.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Obx(() => IconButton(
                                  tooltip: 'Guardar rascunho e fechar',
                                  icon:
                                      const Icon(Icons.close_rounded, size: 22),
                                  onPressed: controller.carregando.value
                                      ? null
                                      : _fechar,
                                )),
                          ],
                        ),
                      ),
                      Obx(() => Column(children: [
                            if (controller.erroRascunhoLocal.value.isNotEmpty)
                              Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                      controller.erroRascunhoLocal.value,
                                      style:
                                          const TextStyle(color: Colors.red))),
                            if (controller.avisoReconciliacao.value.isNotEmpty)
                              Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                      controller.avisoReconciliacao.value)),
                          ])),
                      Divider(color: Colors.grey.shade200, height: 1),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _rolagem,
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.only(
                            left: 10,
                            right: 10,
                            top: 10,
                            bottom: 24,
                          ),
                          child: Form(
                            key: controller.formKey,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CadastroPassosBar(
                                  atual: _passo,
                                  titulos: _titulosPassos,
                                  cor: primary,
                                ),
                                if (_passo == 0) ...[
                                  Obx(() => EventoPreviewTituloWidget(
                                        controller: controller,
                                        tipoEvento: widget.tipoNormalizado,
                                        nomeEvento:
                                            controller.nomeEventoPreview.value,
                                        corPrincipal: primary,
                                      )),
                                  const SizedBox(height: 10),
                                ],
                                ..._buildCamposPorTipo(
                                  primary,
                                  controller,
                                  widget.theme,
                                  widget.temasController,
                                  widget.eventoParaEdicao,
                                  context,
                                  widget.dinheiroMask,
                                  passo: _passo,
                                  calculadoraController:
                                      widget.calculadoraController,
                                  eventoController: widget.eventoController,
                                  cardapioController: widget.cardapioController,
                                  fornecedorMigracaoAdminController:
                                      widget.fornecedorMigracaoAdminController,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_passo == 2 &&
                                  controller.rascunhoCalculadora != null &&
                                  controller.idEvento.value.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Text(
                                    'A estimativa será guardada nesta festa. O cardápio você monta depois.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              if (_passo < 2)
                                CadastroPassosAcoes(
                                  cor: primary,
                                  continuarLabel: 'Continuar',
                                  onContinuar: _avancar,
                                  onVoltar: _passo == 0 ? null : _voltar,
                                )
                              else
                                _buildAcoes(
                                  primary,
                                  controller,
                                  widget.calculadoraController,
                                  onVoltar: _voltar,
                                  aoConcluir: _continuar,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )));
  }
}

// ============================================================================
// 🔹 Geração Condicional de Campos
// ============================================================================
List<Widget> _buildCamposPorTipo(
  Color primary,
  EventoCadastroController controller,
  EventThemeController theme,
  TemaFestaController temasController,
  Evento? eventoParaEdicao,
  BuildContext context,
  TextInputFormatter dinheiroMask, {
  required int passo,
  required CalculadoraFestaController calculadoraController,
  required EventoController eventoController,
  required CardapioController cardapioController,
  required FornecedorMigracaoAdminController fornecedorMigracaoAdminController,
}) {
  final tipoNormalizado = controller.tipoEventoSelecionado.value?.nome
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-zá-úà-ùãõâêîôûç\s]'), '')
      .trim();
  final tokenTipo = controller.tokenTipoEvento;

  final passoFesta = <Widget>[
    _SectionCard(
      title: 'Informações Básicas',
      icon: Icons.info_outline_rounded,
      child: Column(
        children: [
          _CompactInputField(
            label: "Título do evento",
            icon: Icons.celebration_rounded,
            controller: controller.nomeEvento,
            validator: (v) =>
                FormValidators.titulo(v, campo: 'o título do evento'),
            onChanged: (p0) {
              controller.nomeEventoPreview.value = p0;
              controller.atualizarPreview();
            },
          ),
          if (tipoNormalizado == 'aniversario' ||
              tipoNormalizado == 'aniversário') ...[
            const SizedBox(height: 8),
            _CompactInputField(
              label: "Nome do(a) aniversariante",
              icon: Icons.cake_rounded,
              controller: controller.nomePessoalPrincipal,
              validator: (v) => FormValidators.nomePessoa(
                v,
                campo: 'o nome do(a) aniversariante',
              ),
              onChanged: (_) => controller.atualizarPreview(),
            ),
            const SizedBox(height: 10),
            TemaFestaSelector(
              cadastro: controller,
              temasController: temasController,
              theme: theme,
              primary: primary,
              obrigatorio: false,
            ),
          ],
          if (tipoNormalizado == 'formatura' ||
              tipoNormalizado == 'eventoformatura') ...[
            const SizedBox(height: 8),
            _CompactInputField(
              label: "Nome do(a) formando(a)",
              icon: Icons.school_rounded,
              controller: controller.nomePessoalPrincipal,
              validator: (v) => FormValidators.nomePessoa(
                v,
                campo: 'o nome do(a) formando(a)',
              ),
              onChanged: (_) => controller.atualizarPreview(),
            ),
            const SizedBox(height: 10),
            TemaFestaSelector(
              cadastro: controller,
              temasController: temasController,
              theme: theme,
              primary: primary,
            ),
          ],
          if (tokenTipo.contains('corporativo')) ...[
            const SizedBox(height: 8),
            _CompactInputField(
              label: "Empresa ou setor",
              icon: Icons.business_rounded,
              controller: controller.nomePessoalPrincipal,
              validator: (v) => FormValidators.titulo(
                v,
                campo: 'a empresa ou setor',
                minimo: 2,
              ),
              onChanged: (_) => controller.atualizarPreview(),
            ),
            const SizedBox(height: 10),
            TemaFestaSelector(
              cadastro: controller,
              temasController: temasController,
              theme: theme,
              primary: primary,
            ),
          ],
          if (tokenTipo.contains('cha')) ...[
            const SizedBox(height: 10),
            TemaFestaSelector(
              cadastro: controller,
              temasController: temasController,
              theme: theme,
              primary: primary,
            ),
          ],
          if (tipoNormalizado == 'festainfantil' ||
              tipoNormalizado == 'festa infantil') ...[
            const SizedBox(height: 8),
            _CompactInputField(
              label: "Nome da criança",
              icon: Icons.child_care_rounded,
              controller: controller.nomeNoiva, // reaproveitado do modelo
              validator: (v) => FormValidators.nomePessoa(
                v,
                campo: 'o nome da criança',
              ),
              onChanged: (_) => controller.atualizarPreview(),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _CompactInputField(
                    label: "Idade",
                    icon: Icons.cake_rounded,
                    controller: controller.idade,
                    keyboardType: TextInputType.number,
                    inputFormatters: FormMasks.inteiro(maxDigits: 3),
                    validator: (v) =>
                        FormValidators.idade(v, obrigatorio: true, maximo: 17),
                    onChanged: (_) => controller.atualizarPreview(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TemaFestaSelector(
              cadastro: controller,
              temasController: temasController,
              theme: theme,
              primary: primary,
              obrigatorio: true,
            ),
          ],
        ],
      ),
    ),
    const SizedBox(height: 10),
    if (tipoNormalizado == 'casamento') ...[
      _SectionCard(
        title: 'Noivos e Cerimônia',
        icon: Icons.favorite_rounded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _CompactInputField(
                    label: "Nome da noiva(o)",
                    icon: Icons.female_rounded,
                    controller: controller.nomeNoiva,
                    validator: (v) => FormValidators.nomePessoa(
                      v,
                      campo: 'o nome da noiva(o)',
                    ),
                    onChanged: (_) => controller.atualizarPreview(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CompactInputField(
                    label: "Nome do noivo(a)",
                    icon: Icons.male_rounded,
                    controller: controller.parceiro,
                    validator: (v) => FormValidators.nomePessoa(
                      v,
                      campo: 'o nome do noivo(a)',
                    ),
                    onChanged: (_) => controller.atualizarPreview(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Obx(() => DropdownButtonFormField<String>(
                        isExpanded:
                            true, // 🔹 Adicionado para evitar overflow (Garante que o texto encolhe)
                        value: controller.tipoCerimonia.value.isNotEmpty
                            ? controller.tipoCerimonia.value
                            : null,
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87),
                        decoration: InputDecoration(
                          labelText: "Cerimônia",
                          labelStyle: GoogleFonts.poppins(fontSize: 11),
                          prefixIcon:
                              const Icon(Icons.church_rounded, size: 16),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'civil',
                              child: Text('Civil',
                                  overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(
                              value: 'religiosa',
                              child: Text('Religiosa',
                                  overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(
                              value: 'religiosa_civil',
                              child: Text('Religiosa + Civil',
                                  overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(
                              value: 'simbolica',
                              child: Text('Simbólica',
                                  overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(
                              value: 'ao_ar_livre',
                              child: Text('Ao ar livre',
                                  overflow: TextOverflow.ellipsis)),
                        ],
                        onChanged: (v) =>
                            controller.tipoCerimonia.value = v ?? '',
                        validator: (v) => v == null || v.isEmpty
                            ? 'Selecione o tipo de cerimônia'
                            : null,
                      )),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Obx(() => DropdownButtonFormField<String>(
                        isExpanded: true, // 🔹 Adicionado para evitar overflow
                        value: controller.estiloCasamento.value.isNotEmpty
                            ? controller.estiloCasamento.value
                            : null,
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87),
                        decoration: InputDecoration(
                          labelText: "Estilo",
                          labelStyle: GoogleFonts.poppins(fontSize: 11),
                          prefixIcon:
                              const Icon(Icons.palette_rounded, size: 16),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'classico',
                              child: Text('Clássico',
                                  overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(
                              value: 'rustico',
                              child: Text('Rústico',
                                  overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(
                              value: 'praia',
                              child: Text('Praia',
                                  overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(
                              value: 'campo',
                              child: Text('Campo',
                                  overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(
                              value: 'boho',
                              child: Text('Boho',
                                  overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(
                              value: 'moderno',
                              child: Text('Moderno',
                                  overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(
                              value: 'industrial',
                              child: Text('Industrial',
                                  overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(
                              value: 'minimalista',
                              child: Text('Minimalista',
                                  overflow: TextOverflow.ellipsis)),
                        ],
                        onChanged: (v) =>
                            controller.estiloCasamento.value = v ?? '',
                        validator: (v) => v == null || v.isEmpty
                            ? 'Selecione o estilo do casamento'
                            : null,
                      )),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TemaFestaSelector(
              cadastro: controller,
              temasController: temasController,
              theme: theme,
              primary: primary,
            ),
            const SizedBox(height: 10),
            _buildCampoPadrinhos(primary, controller),
          ],
        ),
      ),
      const SizedBox(height: 10),
    ],
  ];
  if (passo == 0) return passoFesta;

  if (passo == 1) {
    return [
      _SectionCard(
        title: 'Planejamento',
        icon: Icons.event_note_rounded,
        child: Column(
          children: [
            Obx(() => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Duração do evento',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<bool>(
                      expandedInsets: EdgeInsets.zero,
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: false,
                          icon: Icon(Icons.today_outlined, size: 18),
                          label: Text('Um dia'),
                        ),
                        ButtonSegment(
                          value: true,
                          icon: Icon(Icons.date_range_outlined, size: 18),
                          label: Text('Vários dias'),
                        ),
                      ],
                      selected: {controller.eventoVariosDias.value},
                      onSelectionChanged: (selection) =>
                          controller.definirEventoVariosDias(selection.single),
                      style: ButtonStyle(
                        minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
                        padding: const WidgetStatePropertyAll(
                          EdgeInsets.symmetric(horizontal: 8),
                        ),
                        textStyle: WidgetStatePropertyAll(
                          GoogleFonts.poppins(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.selected)
                                ? primary
                                : const Color(0xFFF8FAFC)),
                        foregroundColor: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.selected)
                                ? Colors.white
                                : const Color(0xFF374151)),
                        iconColor: WidgetStateProperty.resolveWith((states) =>
                            states.contains(WidgetState.selected)
                                ? Colors.white
                                : primary),
                        side: WidgetStatePropertyAll(
                          BorderSide(color: primary.withValues(alpha: 0.35)),
                        ),
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        visualDensity: VisualDensity.standard,
                        tapTargetSize: MaterialTapTargetSize.padded,
                      ),
                    ),
                  ],
                )),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _CompactInputField(
                    label: "Data do evento",
                    icon: Icons.calendar_month_rounded,
                    controller: controller.dataFesta,
                    readOnly: true,
                    onTap: () async {
                      final agora = DateTime.now();
                      final hoje = DateTime(agora.year, agora.month, agora.day);
                      final selecionada = DateFormat('dd/MM/yyyy', 'pt_BR')
                          .tryParseStrict(controller.dataFesta.text);
                      final inicial = selecionada ?? hoje;
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: inicial,
                        firstDate: inicial.isBefore(hoje) ? inicial : hoje,
                        lastDate: DateTime((inicial.year > hoje.year
                                ? inicial.year
                                : hoje.year) +
                            5),
                        locale: const Locale('pt', 'BR'),
                        initialEntryMode: DatePickerEntryMode.calendarOnly,
                      );
                      if (picked != null) {
                        controller.dataFesta.text =
                            DateFormat('dd/MM/yyyy', 'pt_BR').format(picked);
                      }
                    },
                    validator: (v) =>
                        FormValidators.data(v, campo: 'a data do evento'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CompactInputField(
                    label: "Hora (opcional)",
                    icon: Icons.access_time_rounded,
                    controller: controller.horaFesta,
                    suffixIcon: IconButton(
                      tooltip: 'Deixar horário a definir',
                      icon: const Icon(Icons.close_rounded, size: 16),
                      onPressed: controller.horaFesta.clear,
                    ),
                    readOnly: true,
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) {
                        controller.horaFesta.text =
                            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                      }
                    },
                    validator: controller.validarHora,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Obx(() {
              if (!controller.eventoVariosDias.value) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CompactInputField(
                  label: 'Data de término',
                  icon: Icons.event_available_rounded,
                  controller: controller.dataFimFesta,
                  readOnly: true,
                  onTap: () async {
                    final formato = DateFormat('dd/MM/yyyy', 'pt_BR');
                    final inicio =
                        formato.tryParseStrict(controller.dataFesta.text) ??
                            DateTime.now();
                    final primeiroDia =
                        DateTime(inicio.year, inicio.month, inicio.day + 1);
                    final fim =
                        formato.tryParseStrict(controller.dataFimFesta.text);
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: fim != null && !fim.isBefore(primeiroDia)
                          ? fim
                          : primeiroDia,
                      firstDate: primeiroDia,
                      lastDate: DateTime(inicio.year + 5),
                      locale: const Locale('pt', 'BR'),
                    );
                    if (picked != null) {
                      controller.dataFimFesta.text = formato.format(picked);
                    }
                  },
                  validator: controller.validarTermino,
                ),
              );
            }),
            _CompactInputField(
              label: "Custo estimado (R\$) · opcional",
              icon: Icons.attach_money_rounded,
              controller: controller.custoEstimado,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [dinheiroMask],
              validator: controller.validarCusto,
              onChanged: (v) => controller.atualizarPreview(),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: EnderecoSection(
          cor: primary,
          controller: controller.enderecoController.value,
          titulo: 'Endereço do evento',
        ),
      ),
    ];
  }

  return [
    _buildSecaoConvidadosEstimados(primary, controller),
    const SizedBox(height: 10),
    _buildBotaoCalculadoraFesta(
      primary,
      controller,
      eventoParaEdicao,
      calculadoraController: calculadoraController,
      eventoController: eventoController,
      theme: theme,
      cardapioController: cardapioController,
      fornecedorMigracaoAdminController: fornecedorMigracaoAdminController,
    ),
  ];
}

// ============================================================================
// 🔹 Secções Específicas
// ============================================================================
Widget _buildCampoPadrinhos(
    Color primary, EventoCadastroController controller) {
  final padrinhoController = TextEditingController();

  return Obx(() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: padrinhoController,
                    style: GoogleFonts.poppins(
                        fontSize: 12, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: "💖 Nome dos padrinhos / casal",
                      hintStyle: GoogleFonts.poppins(
                          color: Colors.grey.shade500, fontSize: 11),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: (v) {
                      if (v.trim().isNotEmpty) controller.addPadrinho(v);
                      padrinhoController.clear();
                    },
                  ),
                ),
                IconButton(
                  icon:
                      Icon(Icons.add_circle_rounded, color: primary, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    if (padrinhoController.text.trim().isNotEmpty) {
                      controller.addPadrinho(padrinhoController.text);
                    }
                    padrinhoController.clear();
                  },
                ),
              ],
            ),
          ),
          if (controller.padrinhos.isNotEmpty) const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: controller.padrinhos.map((p) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      p,
                      style: GoogleFonts.poppins(
                          color: primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => controller.removePadrinho(p),
                      child:
                          Icon(Icons.close_rounded, color: primary, size: 12),
                    )
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ));
}

Widget _buildSecaoConvidadosEstimados(
    Color primary, EventoCadastroController controller) {
  void atualizarTotal() {
    if ([
      controller.totalAdultos,
      controller.totalCriancas,
      controller.totalBebes
    ].every((campo) => campo.text.trim().isEmpty)) {
      controller.totalConvidados.text =
          controller.totalPrevistoSalvo?.toString() ?? '';
      return;
    }
    final adultos = _parseIntText(controller.totalAdultos.text);
    final criancas = _parseIntText(controller.totalCriancas.text);
    final bebes = _parseIntText(controller.totalBebes.text);
    final total = adultos + criancas + bebes;

    controller.totalConvidados.text = total.toString();
    controller.atualizarPreview();
  }

  atualizarTotal();

  return _SectionCard(
    title: 'Estimativa de convidados',
    icon: Icons.groups_rounded,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Opcional. A idade muda a conta de comida e bebida. A lista de convidados fica para depois.',
          style: GoogleFonts.poppins(
            color: Colors.grey.shade600,
            fontSize: 12,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        _LinhaContagem(
          label: 'Adultos',
          campo: 'os adultos',
          icon: Icons.person_rounded,
          primary: primary,
          controller: controller.totalAdultos,
          onChanged: atualizarTotal,
        ),
        const SizedBox(height: 8),
        _LinhaContagem(
          label: 'Crianças',
          campo: 'as crianças',
          icon: Icons.child_care_rounded,
          primary: primary,
          controller: controller.totalCriancas,
          onChanged: atualizarTotal,
        ),
        const SizedBox(height: 8),
        _LinhaContagem(
          label: 'Bebês',
          campo: 'os bebês',
          icon: Icons.baby_changing_station_rounded,
          primary: primary,
          controller: controller.totalBebes,
          onChanged: atualizarTotal,
        ),
        const SizedBox(height: 12),
        ListenableBuilder(
          listenable: Listenable.merge([
            controller.totalAdultos,
            controller.totalCriancas,
            controller.totalBebes,
          ]),
          builder: (context, _) {
            atualizarTotal();
            final informou = [
              controller.totalAdultos,
              controller.totalCriancas,
              controller.totalBebes,
            ].any((campo) => campo.text.trim().isNotEmpty);
            final total = _parseIntText(controller.totalAdultos.text) +
                _parseIntText(controller.totalCriancas.text) +
                _parseIntText(controller.totalBebes.text);
            final legado = controller.totalConvidados.text.trim();
            final mostraLegado = !informou && legado.isNotEmpty;
            final exibido = informou
                ? '$total'
                : (mostraLegado ? legado : '—');
            final unidade = total == 1 ? 'pessoa' : 'pessoas';
            return Semantics(
              label: informou
                  ? 'Total previsto: $total $unidade'
                  : mostraLegado
                      ? 'Total previsto: $legado, sem divisão por idade'
                      : 'Total previsto: nada informado',
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total previsto',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          Text(
                            informou
                                ? 'Adultos, crianças e bebês'
                                : mostraLegado
                                    ? 'Sem divisão por idade'
                                    : 'Nada informado ainda',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      exibido,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: primary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    ),
  );
}

class _LinhaContagem extends StatelessWidget {
  const _LinhaContagem({
    required this.label,
    required this.campo,
    required this.icon,
    required this.primary,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final String campo;
  final IconData icon;
  final Color primary;
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: (_) => FormValidators.inteiroNaoNegativo(
        controller.text,
        campo: campo,
        maximo: 9999,
      ),
      builder: (state) {
        final atual = _parseIntText(controller.text);

        void definir(int valor) {
          final limitado = valor.clamp(0, 9999);
          controller.text = limitado.toString();
          state.didChange(controller.text);
          onChanged();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: state.hasError
                      ? Colors.red.shade400
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ExcludeSemantics(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Diminuir $label',
                    onPressed: atual <= 0 ? null : () => definir(atual - 1),
                    icon: const Icon(Icons.remove_rounded, size: 22),
                    color: primary,
                    disabledColor: Colors.grey.shade400,
                    constraints:
                        const BoxConstraints(minWidth: 48, minHeight: 48),
                    padding: EdgeInsets.zero,
                  ),
                  SizedBox(
                    width: 64,
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ListenableBuilder(
                          listenable: controller,
                          builder: (context, _) {
                            if (controller.text.trim().isNotEmpty) {
                              return const SizedBox.shrink();
                            }
                            return IgnorePointer(
                              child: Text(
                                '0',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            );
                          },
                        ),
                        Positioned.fill(
                          child: TextField(
                            controller: controller,
                            textAlign: TextAlign.center,
                            textAlignVertical: TextAlignVertical.center,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            inputFormatters: FormMasks.inteiro(maxDigits: 4),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF111827),
                            ),
                            decoration: InputDecoration(
                              labelText: label,
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.never,
                              labelStyle: const TextStyle(
                                fontSize: 0.01,
                                height: 0.01,
                                color: Colors.transparent,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              isCollapsed: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (valor) {
                              state.didChange(valor);
                              onChanged();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Aumentar $label',
                    onPressed: atual >= 9999 ? null : () => definir(atual + 1),
                    icon: const Icon(Icons.add_rounded, size: 22),
                    color: primary,
                    disabledColor: Colors.grey.shade400,
                    constraints:
                        const BoxConstraints(minWidth: 48, minHeight: 48),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  state.errorText!,
                  style: GoogleFonts.poppins(
                    color: Colors.red.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

Widget _buildBotaoCalculadoraFesta(
  Color primary,
  EventoCadastroController controller,
  Evento? eventoParaEdicao, {
  required CalculadoraFestaController calculadoraController,
  required EventoController eventoController,
  required EventThemeController theme,
  required CardapioController cardapioController,
  required FornecedorMigracaoAdminController fornecedorMigracaoAdminController,
}) {
  final idEvento = eventoParaEdicao?.idEvento.trim() ?? '';
  final eventoJaSalvo = idEvento.isNotEmpty;
  final estimativaPendente = controller.rascunhoCalculadora != null;
  final estimativaIsolada = !eventoJaSalvo || estimativaPendente;

  if (!JornadaCadastroFesta.mostraCalculadoraNoFormulario(
    festaJaSalva: eventoJaSalvo,
  )) {
    if (!estimativaPendente) return const SizedBox.shrink();
    return Text(
      'A estimativa que você já fez será guardada ao salvar a festa. Quantidades e cardápio ficam na festa, depois.',
      style: GoogleFonts.poppins(
        color: Colors.grey.shade600,
        fontSize: 11,
      ),
    );
  }

  return _SectionCard(
    title: eventoJaSalvo && !estimativaPendente
        ? 'Calculadora da festa'
        : 'Estimativa de comes e bebes',
    icon: Icons.auto_graph_rounded,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eventoJaSalvo && !estimativaPendente
              ? 'Ajuste as quantidades com os convidados e o cardápio desta festa.'
              : 'Opcional. Usa o número de pessoas que você informou, sem cardápio. Ao salvar a festa, a estimativa fica guardada. O cardápio você monta depois.',
          style: GoogleFonts.poppins(
            color: Colors.grey.shade600,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: primary,
              iconColor: primary,
              side: BorderSide(color: primary.withValues(alpha: 0.45)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: EdgeInsets.zero,
            ),
            onPressed: () async {
              try {
                await controller.salvarCadastroLocal();
              } catch (_) {
                return;
              }
              var premissas = controller.assinaturaPremissas;
              final idRascunhoAberto = controller.idRascunho;
              final dono = controller.app.usuarioLogado.value?.idUsuario;
              FocusManager.instance.primaryFocus?.unfocus();
              Get.to(
                () => CalculadoraFestaScreen(
                  idEvento: estimativaIsolada ? '' : idEvento,
                  nomeRascunho: controller.nomeEventoPreview.value,
                  periodoRascunho: controller.dataFesta.text.isEmpty
                      ? null
                      : '${controller.dataFesta.text}${controller.dataFimFesta.text.isEmpty ? '' : ' a ${controller.dataFimFesta.text}'}',
                  orcamentoInicial: controller.custoEstimadoInformado,
                  idRascunho: estimativaIsolada ? controller.idRascunho : null,
                  rascunho:
                      estimativaIsolada ? controller.rascunhoCalculadora : null,
                  persistirRascunho: estimativaIsolada
                      ? (rascunho) async {
                          if (controller.idRascunho != idRascunhoAberto ||
                              controller.app.usuarioLogado.value?.idUsuario !=
                                  dono) {
                            return;
                          }
                          await controller.receberRascunho(rascunho,
                              premissasOriginais: premissas);
                          premissas = controller.assinaturaPremissas;
                        }
                      : null,
                  tipoEvento: _resolverTipoEventoCalculadora(controller),
                  permitirEstimativaSemEvento: true,
                  adultosIniciais: _parseIntText(controller.totalAdultos.text),
                  criancasIniciais:
                      _parseIntText(controller.totalCriancas.text),
                  bebesIniciais: _parseIntText(controller.totalBebes.text),
                  calculadoraController: calculadoraController,
                  eventoController: eventoController,
                  themeController: theme,
                  cardapioController: cardapioController,
                  fornecedorMigracaoAdminController:
                      fornecedorMigracaoAdminController,
                ),
                fullscreenDialog: true,
              );
            },
            icon: const Icon(Icons.calculate_rounded, size: 18),
            label: Text(
              estimativaPendente
                  ? 'Retomar estimativa'
                  : eventoJaSalvo
                      ? 'Abrir calculadora da festa'
                      : 'Estimar quantidades',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildAcoes(Color primary, EventoCadastroController controller,
    CalculadoraFestaController calculadora,
    {required VoidCallback onVoltar,
    required Future<void> Function(Evento, RascunhoCalculadora?) aoConcluir}) {
  return Obx(() {
    final salvando = controller.carregando.value;
    final continuarLabel =
        controller.eventoJaConfirmado && controller.rascunhoCalculadora != null
            ? 'Guardar estimativa na festa'
            : controller.isEditando
                ? 'Atualizar evento'
                : 'Salvar evento';
    final frente =
        primary.computeLuminance() > .179 ? Colors.black : Colors.white;

    Future<void> salvar() async {
      final valido = controller.formKey.currentState?.validate() ?? false;
      if (!valido) return;
      EasyLoading.show(status: 'Salvando evento…');
      try {
        await controller.salvarEvento(
            vincularRascunho: calculadora.vincularRascunho,
            aoConcluir: (evento, rascunho) async {
              EasyLoading.dismiss();
              await aoConcluir(evento, rascunho);
            });
      } finally {
        EasyLoading.dismiss();
      }
    }

    final voltar = OutlinedButton(
      onPressed: salvando ? null : onVoltar,
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      child: Text(
        'Voltar',
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
      ),
    );
    final confirmar = ElevatedButton(
      onPressed: salvando ? null : salvar,
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: frente,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      child: salvando
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: frente, strokeWidth: 2),
            )
          : Text(
              continuarLabel,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
    );

    return LayoutBuilder(builder: (context, _) {
      final escalaGrande = MediaQuery.textScalerOf(context).scale(14) > 18;
      if (escalaGrande) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            confirmar,
            const SizedBox(height: 8),
            voltar,
          ],
        );
      }
      return Row(
        children: [
          Expanded(child: voltar),
          const SizedBox(width: 10),
          Expanded(flex: 2, child: confirmar),
        ],
      );
    });
  });
}

// ============================================================================
// 🔹 Componentes Auxiliares (Design System Idêntico à Calculadora)
// ============================================================================
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard(
      {required this.title, required this.icon, required this.child});

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
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _CompactInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffixIcon;

  const _CompactInputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.keyboardType,
    this.validator,
    this.inputFormatters,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      inputFormatters: inputFormatters,
      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 11),
        prefixIcon: Icon(icon, size: 16),
        suffixIcon: suffixIcon,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey.shade50,
        errorStyle: const TextStyle(fontSize: 11, height: 1.2),
        errorMaxLines: 2,
      ),
    );
  }
}

// Helpers
int _parseIntText(String? value) {
  final normalized = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '').trim();
  if (normalized.isEmpty) return 0;
  return int.tryParse(normalized) ?? 0;
}

String _resolverTipoEventoCalculadora(EventoCadastroController controller) {
  final tipoSelecionado =
      controller.tipoEventoSelecionado.value?.nome.trim() ?? '';
  if (tipoSelecionado.isNotEmpty) return tipoSelecionado;
  final nomeEvento = controller.nomeEvento.text.trim();
  if (nomeEvento.isNotEmpty) return nomeEvento;
  final preview = controller.nomeEventoPreview.value.trim();
  if (preview.isNotEmpty) return preview;
  return 'Evento';
}
