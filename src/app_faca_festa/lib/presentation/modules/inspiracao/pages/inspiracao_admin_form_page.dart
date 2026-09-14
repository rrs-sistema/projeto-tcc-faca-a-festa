import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/app/routes/app_route_args.dart';
import 'package:app_faca_festa/core/utils/form_validators.dart';
import 'package:app_faca_festa/domain/entities/inspiracao.dart';
import 'package:app_faca_festa/domain/entities/inspiracao_sugestao.dart';
import 'package:app_faca_festa/presentation/modules/inspiracao/controllers/inspiracao_admin_controller.dart';

part '../sections/inspiracao_admin_form_layout.dart';
part '../sections/inspiracao_admin_form_midia.dart';
part '../sections/inspiracao_admin_form_planejamento.dart';
part '../widgets/inspiracao_admin_form_widgets.dart';

const Color _primary = Color(0xFFE94B8A);
const Color _secondary = Color(0xFFFF8A65);
const Color _dark = Color(0xFF1F2937);
const Color _muted = Color(0xFF64748B);
const Color _surface = Color(0xFFF8FAFC);
const Color _success = Color(0xFF10B981);
const Color _warning = Color(0xFFF59E0B);
const Color _danger = Color(0xFFEF4444);
const Color _info = Color(0xFF3B82F6);

const List<_TipoEventoOption> _tiposEventoPadrao = <_TipoEventoOption>[
  _TipoEventoOption(
    id: '1eab2c53-a7d3-4a97-b473-02572464e779',
    nome: '🍼 Chá de Bebê',
    slug: 'cha_de_bebe',
  ),
  _TipoEventoOption(
    id: '7f8aa427-9b80-45ef-9b7c-f4e7c08ffcda',
    nome: '🎂 Aniversário',
    slug: 'aniversario',
  ),
  _TipoEventoOption(
    id: 'ccbdb965-8f3c-4c92-bc94-2331c0ca2bb8',
    nome: '🎈 Festa Infantil',
    slug: 'festa_infantil',
  ),
  _TipoEventoOption(
    id: 'WlLdfdmu4Chvw2p8daUm',
    nome: '🎓 Formatura',
    slug: 'formatura',
  ),
  _TipoEventoOption(
    id: '302191a2-dbf3-4ac6-ba53-08273b384cab',
    nome: '💍 Casamento',
    slug: 'casamento',
  ),
  _TipoEventoOption(
    id: 'lXf0M5vMNvyRn52yQ2fY',
    nome: '💼 Evento Corporativo',
    slug: 'evento_corporativo',
  ),
];

const List<String> _categoriasTarefaSugerida = <String>[
  'Decoração',
  'Doces',
  'Buffet',
  'Papelaria',
  'DIY',
  'Bolo',
  'Lembrancinhas',
  'Fotografia',
  'Música',
  'Local',
  'Convidados',
  'Geral',
];

const List<String> _prioridadesTarefaSugerida = <String>[
  'baixa',
  'media',
  'alta',
];

const List<String> _categoriasOrcamentoSugerido = <String>[
  'Decoração',
  'Doces',
  'Buffet',
  'Papelaria',
  'DIY',
  'Bolo',
  'Lembrancinhas',
  'Fotografia',
  'Música',
  'Local',
  'Bebidas',
  'Brindes',
  'Serviços',
  'Geral',
];

const List<String> _unidadesOrcamentoSugerido = <String>[
  'unidade',
  'pessoa',
  'kg',
  'cento',
  'pacote',
  'metro',
  'hora',
  'diária',
  'serviço',
];

class InspiracaoAdminFormPage extends StatefulWidget {
  final Inspiracao? inspiracao;
  final InspiracaoAdminController controller;
  final String? usuarioId;
  final bool imagemObrigatoria;

  const InspiracaoAdminFormPage({
    super.key,
    this.inspiracao,
    required this.controller,
    this.usuarioId,
    this.imagemObrigatoria = false,
  });

  @override
  State<InspiracaoAdminFormPage> createState() =>
      _InspiracaoAdminFormPageState();
}

class _InspiracaoAdminFormPageState extends State<InspiracaoAdminFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final InspiracaoAdminController controller;
  late final Inspiracao? _inspiracaoInicial;

  late final TextEditingController _tituloController;
  late final TextEditingController _descricaoController;
  late final TextEditingController _categoriaController;
  late final TextEditingController _categoriaIdController;
  late final TextEditingController _imagemUrlController;
  late final TextEditingController _galeriaUrlsController;
  late final TextEditingController _tagsController;
  late final TextEditingController _paletaCoresController;
  late final TextEditingController _estiloController;
  late final TextEditingController _faixaCustoController;
  late final TextEditingController _nivelDificuldadeController;
  late final TextEditingController _ordemController;

  late final TextEditingController _tipoEventoController;
  late final TextEditingController _tipoEventoIdController;
  late final TextEditingController _tipoEventoNormalizadoController;
  late final TextEditingController _tipoEventoIdsController;
  late final TextEditingController _tipoEventoSlugsController;
  late final TextEditingController _tipoEventoNomesController;

  late final TextEditingController _tarefasSugeridasController;
  late final TextEditingController _itensOrcamentoSugeridosController;
  late final TextEditingController _categoriasFornecedorSugeridasController;
  late final TextEditingController _fornecedoresRelacionadosController;

  bool _ativo = true;
  bool _publicado = false;
  bool _destaque = false;
  bool _tentouSalvar = false;

  final Set<String> _tipoEventoIdsSelecionados = <String>{};
  bool get _isEdicao => _inspiracaoInicial?.id.trim().isNotEmpty == true;

  String get _inspiracaoId => _inspiracaoInicial?.id.trim() ?? '';

  @override
  void initState() {
    super.initState();

    controller = widget.controller;

    _inspiracaoInicial = widget.inspiracao ??
        InspiracaoAdminFormArgs.maybeOf(Get.arguments)?.inspiracao;

    _inicializarControllers();
    _popularCampos();
  }

  void _inicializarControllers() {
    _tituloController = TextEditingController();
    _descricaoController = TextEditingController();
    _categoriaController = TextEditingController();
    _categoriaIdController = TextEditingController();
    _imagemUrlController = TextEditingController();
    _galeriaUrlsController = TextEditingController();
    _tagsController = TextEditingController();
    _paletaCoresController = TextEditingController();
    _estiloController = TextEditingController();
    _faixaCustoController = TextEditingController();
    _nivelDificuldadeController = TextEditingController();
    _ordemController = TextEditingController();

    _tipoEventoController = TextEditingController();
    _tipoEventoIdController = TextEditingController();
    _tipoEventoNormalizadoController = TextEditingController();
    _tipoEventoIdsController = TextEditingController();
    _tipoEventoSlugsController = TextEditingController();
    _tipoEventoNomesController = TextEditingController();

    _tarefasSugeridasController = TextEditingController();
    _itensOrcamentoSugeridosController = TextEditingController();
    _categoriasFornecedorSugeridasController = TextEditingController();
    _fornecedoresRelacionadosController = TextEditingController();

    _imagemUrlController.addListener(_sincronizarImagemPrincipalUrl);
    _galeriaUrlsController.addListener(_sincronizarGaleriaFormulario);
  }

  void _popularCampos() {
    final inspiracao = _inspiracaoInicial;

    if (inspiracao == null) {
      _ordemController.text = controller.proximaOrdemSugerida().toString();
      _ativo = true;
      _publicado = false;
      _destaque = false;
      controller.prepararTarefasSugeridasFormulario(const []);
      controller.prepararItensOrcamentoSugeridosFormulario(const []);
      controller.prepararImagensFormulario(
        imagemUrl: '',
        galeriaUrls: const [],
        limparPendentes: true,
      );
      return;
    }

    _tituloController.text = inspiracao.titulo;
    _descricaoController.text = inspiracao.descricao;
    _categoriaController.text = (inspiracao.categoria ?? '').trim();
    _categoriaIdController.text = (inspiracao.categoriaId ?? '').trim();
    _imagemUrlController.text = inspiracao.imagemUrl;
    _galeriaUrlsController.text = _joinLinhas(inspiracao.galeriaUrls);
    _tagsController.text = _joinLista(inspiracao.tags);
    _paletaCoresController.text = _joinLista(inspiracao.paletaCores);
    _estiloController.text = inspiracao.estilo;
    _faixaCustoController.text = inspiracao.faixaCusto;
    _nivelDificuldadeController.text = inspiracao.nivelDificuldade;
    _ordemController.text =
        (_isEdicao ? inspiracao.ordem : controller.proximaOrdemSugerida())
            .toString();

    _tipoEventoController.text = inspiracao.tipoEvento;
    _tipoEventoIdController.text = inspiracao.tipoEventoId;
    _tipoEventoNormalizadoController.text = inspiracao.tipoEventoNormalizado;
    _tipoEventoIdsController.text = _joinLista(inspiracao.tipoEventoIds);
    _tipoEventoSlugsController.text = _joinLista(inspiracao.tipoEventoSlugs);
    _tipoEventoNomesController.text = _joinLista(inspiracao.tipoEventoNomes);

    controller.prepararTarefasSugeridasFormulario(inspiracao.tarefasSugeridas);
    _tarefasSugeridasController.text =
        _formatarTarefas(controller.tarefasSugeridasFormulario);
    controller.prepararItensOrcamentoSugeridosFormulario(
      inspiracao.itensOrcamentoSugeridos,
    );
    _itensOrcamentoSugeridosController.text = _formatarItensOrcamento(
      controller.itensOrcamentoSugeridosFormulario,
    );
    _categoriasFornecedorSugeridasController.text =
        _joinLista(inspiracao.categoriasFornecedorSugeridas);
    _fornecedoresRelacionadosController.text =
        _joinLinhas(inspiracao.fornecedoresRelacionados);

    _ativo = inspiracao.ativo;
    _publicado = inspiracao.publicado;
    _destaque = inspiracao.destaque;

    final ids = inspiracao.tipoEventoIds;
    final idPrincipal = _tipoEventoIdController.text.trim();
    final slugs = inspiracao.tipoEventoSlugs;
    final nomes = inspiracao.tipoEventoNomes;

    for (final option in _tiposEventoPadrao) {
      final selecionadoPorId =
          ids.contains(option.id) || idPrincipal == option.id;
      final selecionadoPorSlug = slugs.map(_normalizeKey).contains(option.slug);
      final selecionadoPorNome =
          nomes.map(_normalizeKey).contains(_normalizeKey(option.nome));
      if (selecionadoPorId || selecionadoPorSlug || selecionadoPorNome) {
        _tipoEventoIdsSelecionados.add(option.id);
      }
    }

    if (_tipoEventoIdsSelecionados.isNotEmpty) {
      _sincronizarCamposTipos(preferirCamposAtuais: true);
    }

    controller.prepararImagensFormulario(
      imagemUrl: _imagemUrlController.text,
      galeriaUrls: _parseStringList(_galeriaUrlsController.text),
      limparPendentes: true,
    );
  }

  @override
  void dispose() {
    _imagemUrlController.removeListener(_sincronizarImagemPrincipalUrl);
    _galeriaUrlsController.removeListener(_sincronizarGaleriaFormulario);

    _tituloController.dispose();
    _descricaoController.dispose();
    _categoriaController.dispose();
    _categoriaIdController.dispose();
    _imagemUrlController.dispose();
    _galeriaUrlsController.dispose();
    _tagsController.dispose();
    _paletaCoresController.dispose();
    _estiloController.dispose();
    _faixaCustoController.dispose();
    _nivelDificuldadeController.dispose();
    _ordemController.dispose();

    _tipoEventoController.dispose();
    _tipoEventoIdController.dispose();
    _tipoEventoNormalizadoController.dispose();
    _tipoEventoIdsController.dispose();
    _tipoEventoSlugsController.dispose();
    _tipoEventoNomesController.dispose();

    _tarefasSugeridasController.dispose();
    _itensOrcamentoSugeridosController.dispose();
    _categoriasFornecedorSugeridasController.dispose();
    _fornecedoresRelacionadosController.dispose();
    super.dispose();
  }

  void _sincronizarImagemPrincipalUrl() {
    controller.atualizarImagemPrincipalUrlFormulario(_imagemUrlController.text);
    if (mounted) {
      setState(() {});
    }
  }

  void _sincronizarGaleriaFormulario() {
    controller.atualizarGaleriaUrlsFormulario(
        _parseStringList(_galeriaUrlsController.text));
  }

  void _atualizarTela() {
    if (mounted) {
      setState(() {});
    }
  }

  void _atualizarCampo(VoidCallback fn) {
    setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _surface,
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: _dark,
        titleSpacing: 0,
        title: Text(
          _isEdicao ? 'Editar inspiração' : 'Nova inspiração',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _dark,
          ),
        ),
        actions: [
          if (_isEdicao)
            IconButton(
              tooltip: 'Excluir logicamente',
              onPressed: _confirmarExclusao,
              icon: const Icon(Icons.delete_outline_rounded, color: _danger),
            ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 980;
            final horizontal = constraints.maxWidth >= 1200 ? 32.0 : 16.0;

            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  horizontal,
                  16,
                  horizontal,
                  128 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeroCard(isWide: isWide),
                        const SizedBox(height: 14),
                        _FormSection(
                          icon: Icons.article_outlined,
                          title: 'Dados principais',
                          subtitle:
                              'Informações básicas exibidas para o organizador do evento.',
                          child: Column(
                            children: [
                              _responsiveFields(
                                isWide: isWide,
                                children: [
                                  _buildTextField(
                                    controller: _tituloController,
                                    label: 'Título da inspiração',
                                    hint:
                                        'Ex.: Mesa provençal rosa com dourado',
                                    icon: Icons.title_rounded,
                                    requiredField: true,
                                    validator: (value) => FormValidators.titulo(
                                        value,
                                        campo: 'o título'),
                                  ),
                                  _buildTextField(
                                    controller: _categoriaController,
                                    label: 'Categoria',
                                    hint: 'Ex.: Decoração',
                                    icon: Icons.category_outlined,
                                    requiredField: true,
                                    validator: (value) =>
                                        FormValidators.obrigatorio(
                                      value,
                                      campo: 'a categoria',
                                    ),
                                  ),
                                  _buildTextField(
                                    controller: _categoriaIdController,
                                    label: 'Categoria ID',
                                    hint: 'Ex.: decoracao',
                                    icon: Icons.tag_rounded,
                                  ),
                                  _buildTextField(
                                    controller: _ordemController,
                                    label: 'Ordem',
                                    hint: 'Ex.: 1',
                                    icon: Icons.sort_rounded,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildTextField(
                                controller: _descricaoController,
                                label: 'Descrição',
                                hint:
                                    'Descreva a ideia, quando usar e quais detalhes ela sugere.',
                                icon: Icons.notes_rounded,
                                minLines: 4,
                                maxLines: 8,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _FormSection(
                          icon: Icons.image_outlined,
                          title: 'Imagem e galeria',
                          subtitle:
                              'Cadastre a imagem principal e URLs extras de referência.',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildImagePanel(),
                              const SizedBox(height: 12),
                              _buildTextField(
                                controller: _imagemUrlController,
                                label: 'Imagem principal URL',
                                hint: 'https://...',
                                icon: Icons.link_rounded,
                                keyboardType: TextInputType.url,
                                validator: (value) => FormValidators.url(
                                  value,
                                  obrigatorio: false,
                                  campo: 'a URL da imagem',
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildTextField(
                                controller: _galeriaUrlsController,
                                label: 'URLs adicionais da galeria',
                                hint:
                                    'Uma URL por linha. Você também pode adicionar imagens pelo botão abaixo.',
                                icon: Icons.collections_outlined,
                                minLines: 3,
                                maxLines: 6,
                              ),
                              const SizedBox(height: 12),
                              _buildGaleriaPanel(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _FormSection(
                          icon: Icons.event_available_outlined,
                          title: 'Tipos de evento',
                          subtitle:
                              'Selecione pelo menos um tipo de evento onde essa inspiração será exibida.',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildTipoEventoChips(),
                              if (_tentouSalvar &&
                                  !_possuiTipoEventoValido()) ...[
                                const SizedBox(height: 10),
                                _buildInlineWarning(
                                  'Selecione pelo menos um tipo de evento ou preencha os campos de tipo manualmente.',
                                  color: _danger,
                                  icon: Icons.error_outline_rounded,
                                ),
                              ],
                              const SizedBox(height: 14),
                              _responsiveFields(
                                isWide: isWide,
                                children: [
                                  _buildTextField(
                                    controller: _tipoEventoController,
                                    label: 'Tipo de evento principal',
                                    hint: 'Ex.: Casamento',
                                    icon: Icons.celebration_outlined,
                                  ),
                                  _buildTextField(
                                    controller: _tipoEventoIdController,
                                    label: 'Tipo de evento ID principal',
                                    hint: 'ID principal',
                                    icon: Icons.key_rounded,
                                  ),
                                  _buildTextField(
                                    controller:
                                        _tipoEventoNormalizadoController,
                                    label: 'Tipo normalizado',
                                    hint: 'Ex.: casamento',
                                    icon: Icons.data_object_rounded,
                                  ),
                                  _buildTextField(
                                    controller: _tipoEventoIdsController,
                                    label: 'TipoEventoIds',
                                    hint: 'IDs separados por vírgula',
                                    icon: Icons.format_list_bulleted_rounded,
                                  ),
                                  _buildTextField(
                                    controller: _tipoEventoSlugsController,
                                    label: 'TipoEventoSlugs',
                                    hint: 'slugs separados por vírgula',
                                    icon: Icons.link_outlined,
                                  ),
                                  _buildTextField(
                                    controller: _tipoEventoNomesController,
                                    label: 'TipoEventoNomes',
                                    hint: 'nomes separados por vírgula',
                                    icon: Icons.badge_outlined,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _FormSection(
                          icon: Icons.tune_rounded,
                          title: 'Classificação',
                          subtitle:
                              'Dados usados para busca, filtros e experiência personalizada.',
                          child: Column(
                            children: [
                              _responsiveFields(
                                isWide: isWide,
                                children: [
                                  _buildTextField(
                                    controller: _tagsController,
                                    label: 'Tags',
                                    hint: 'moderno, rosa, luxo',
                                    icon: Icons.sell_outlined,
                                  ),
                                  _buildTextField(
                                    controller: _paletaCoresController,
                                    label: 'Paleta de cores',
                                    hint: '#E94B8A, dourado, branco',
                                    icon: Icons.palette_outlined,
                                  ),
                                  _buildTextField(
                                    controller: _estiloController,
                                    label: 'Estilo',
                                    hint: 'Ex.: Clássico, moderno, rústico',
                                    icon: Icons.auto_awesome_outlined,
                                  ),
                                  _buildTextField(
                                    controller: _faixaCustoController,
                                    label: 'Faixa de custo',
                                    hint: 'Ex.: baixo, médio, alto',
                                    icon: Icons.attach_money_rounded,
                                  ),
                                  _buildTextField(
                                    controller: _nivelDificuldadeController,
                                    label: 'Nível de dificuldade',
                                    hint: 'Ex.: fácil, médio, avançado',
                                    icon: Icons.speed_rounded,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _FormSection(
                          icon: Icons.fact_check_outlined,
                          title: 'Planejamento sugerido',
                          subtitle:
                              'Itens que podem gerar checklist, orçamento e fornecedores sugeridos.',
                          child: Column(
                            children: [
                              _buildTarefasSugeridasEditor(),
                              const SizedBox(height: 12),
                              _buildItensOrcamentoSugeridosEditor(),
                              const SizedBox(height: 12),
                              _responsiveFields(
                                isWide: isWide,
                                children: [
                                  _buildTextField(
                                    controller:
                                        _categoriasFornecedorSugeridasController,
                                    label: 'Categorias de fornecedor sugeridas',
                                    hint: 'Decoração, Buffet, Fotografia',
                                    icon: Icons.storefront_outlined,
                                  ),
                                  _buildTextField(
                                    controller:
                                        _fornecedoresRelacionadosController,
                                    label: 'Fornecedores relacionados',
                                    hint: 'Um ID, nome ou referência por linha',
                                    icon: Icons.handshake_outlined,
                                    minLines: 3,
                                    maxLines: 6,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _FormSection(
                          icon: Icons.public_rounded,
                          title: 'Publicação',
                          subtitle:
                              'Controle de disponibilidade da inspiração no app público.',
                          child: _buildPublicacaoCards(isWide: isWide),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _salvar() async {
    setState(() => _tentouSalvar = true);

    final formValido = _formKey.currentState?.validate() ?? false;
    if (!formValido) {
      EasyLoading.showInfo('Revise os campos obrigatórios.');
      return;
    }

    if (!_possuiTipoEventoValido()) {
      EasyLoading.showInfo('Selecione pelo menos um tipo de evento.');
      return;
    }

    final erroTarefas = controller.validarTarefasSugeridasFormulario();
    if (erroTarefas != null) {
      EasyLoading.showInfo(erroTarefas);
      return;
    }

    final erroItensOrcamento =
        controller.validarItensOrcamentoSugeridosFormulario();
    if (erroItensOrcamento != null) {
      EasyLoading.showInfo(erroItensOrcamento);
      return;
    }

    if (widget.imagemObrigatoria && !_possuiImagemPrincipal()) {
      EasyLoading.showInfo('Informe ou selecione a imagem principal.');
      return;
    }

    controller.prepararImagensFormulario(
      imagemUrl: _imagemUrlController.text,
      galeriaUrls: _parseStringList(_galeriaUrlsController.text),
      limparPendentes: false,
    );

    final inspiracao = _montarInspiracaoFormulario();

    final id = await controller.salvarInspiracao(
      inspiracao: inspiracao,
      usuarioId: widget.usuarioId,
    );

    if (id != null && id.trim().isNotEmpty) {
      Get.back(result: true);
    }
  }

  Future<void> _confirmarExclusao() async {
    if (!_isEdicao) return;

    final titulo = _tituloController.text.trim().isEmpty
        ? 'esta inspiração'
        : _tituloController.text.trim();

    final confirmar = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
        contentPadding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _danger.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: _danger),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Excluir inspiração?',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          'Essa ação fará exclusão lógica de "$titulo". O documento será mantido no Firestore com ativo=false, publicado=false e deletado=true.',
          style: GoogleFonts.poppins(color: _muted, height: 1.35, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Get.back(result: true),
            style: FilledButton.styleFrom(
              backgroundColor: _danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.delete_rounded, size: 18),
            label: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final sucesso = await controller.excluirLogicamente(_inspiracaoId,
          usuarioId: widget.usuarioId);
      if (sucesso) {
        Get.back(result: true);
      }
    }
  }

  Inspiracao _montarInspiracaoFormulario() {
    final tipos = _resolverTiposEvento();
    final categoriaId = _categoriaIdController.text.trim().isNotEmpty
        ? _categoriaIdController.text.trim()
        : _normalizeKey(_categoriaController.text);
    final inicial = _inspiracaoInicial;

    return Inspiracao(
      id: _isEdicao ? _inspiracaoId : '',
      titulo: _tituloController.text.trim(),
      descricao: _descricaoController.text.trim(),
      categoria: _categoriaController.text.trim(),
      categoriaId: categoriaId,
      imagemUrl: controller.imagemPrincipalUrlAtual.value.trim(),
      galeriaUrls: _parseStringList(_galeriaUrlsController.text),
      tags: _parseStringList(_tagsController.text),
      paletaCores: _parseStringList(_paletaCoresController.text),
      estilo: _estiloController.text.trim(),
      faixaCusto: _faixaCustoController.text.trim(),
      nivelDificuldade: _nivelDificuldadeController.text.trim(),
      ordem: int.tryParse(_ordemController.text.trim()) ??
          controller.proximaOrdemSugerida(),
      tipoEvento: tipos.tipoEvento,
      tipoEventoId: tipos.tipoEventoId,
      tipoEventoNormalizado: tipos.tipoEventoNormalizado,
      tipoEventoIds: tipos.tipoEventoIds,
      tipoEventoSlugs: tipos.tipoEventoSlugs,
      tipoEventoNomes: tipos.tipoEventoNomes,
      tarefasSugeridas: controller.tarefasSugeridasDoFormulario(),
      itensOrcamentoSugeridos: controller.itensOrcamentoSugeridosDoFormulario(),
      categoriasFornecedorSugeridas: _parseStringList(
        _categoriasFornecedorSugeridasController.text,
      ),
      fornecedoresRelacionados:
          _parseStringList(_fornecedoresRelacionadosController.text),
      ativo: _ativo,
      publicado: _publicado,
      destaque: _destaque,
      deletado: false,
      favorito: inicial?.favorito ?? false,
      criadoEm: inicial?.criadoEm,
    );
  }

  _TiposEventoResolvidos _resolverTiposEvento() {
    final selectedOptions = _tiposEventoPadrao
        .where((option) => _tipoEventoIdsSelecionados.contains(option.id))
        .toList();

    final LinkedHashSet<String> ids = LinkedHashSet<String>();
    final LinkedHashSet<String> slugs = LinkedHashSet<String>();
    final LinkedHashSet<String> nomes = LinkedHashSet<String>();

    for (final option in selectedOptions) {
      ids.add(option.id);
      slugs.add(option.slug);
      nomes.add(option.nome);
    }

    ids.addAll(_parseStringList(_tipoEventoIdsController.text));
    slugs.addAll(
        _parseStringList(_tipoEventoSlugsController.text).map(_normalizeKey));
    nomes.addAll(_parseStringList(_tipoEventoNomesController.text));

    final tipoEventoManual = _tipoEventoController.text.trim();
    final tipoEventoIdManual = _tipoEventoIdController.text.trim();
    final tipoEventoNormalizadoManual =
        _tipoEventoNormalizadoController.text.trim();

    if (tipoEventoIdManual.isNotEmpty) ids.add(tipoEventoIdManual);
    if (tipoEventoManual.isNotEmpty) nomes.add(tipoEventoManual);
    if (tipoEventoNormalizadoManual.isNotEmpty) {
      slugs.add(_normalizeKey(tipoEventoNormalizadoManual));
    }

    final tipoEvento = nomes.isNotEmpty ? nomes.first : tipoEventoManual;
    final tipoEventoId = ids.isNotEmpty ? ids.first : tipoEventoIdManual;
    final tipoEventoNormalizado = slugs.isNotEmpty
        ? slugs.first
        : _normalizeKey(tipoEventoNormalizadoManual.isNotEmpty
            ? tipoEventoNormalizadoManual
            : tipoEvento);

    return _TiposEventoResolvidos(
      tipoEvento: tipoEvento,
      tipoEventoId: tipoEventoId,
      tipoEventoNormalizado: tipoEventoNormalizado,
      tipoEventoIds: ids.where((e) => e.trim().isNotEmpty).toList(),
      tipoEventoSlugs: slugs.where((e) => e.trim().isNotEmpty).toList(),
      tipoEventoNomes: nomes.where((e) => e.trim().isNotEmpty).toList(),
    );
  }

  void _sincronizarCamposTipos({bool preferirCamposAtuais = false}) {
    final options = _tiposEventoPadrao
        .where((option) => _tipoEventoIdsSelecionados.contains(option.id))
        .toList();

    if (options.isEmpty) {
      if (!preferirCamposAtuais) {
        _tipoEventoIdsController.clear();
        _tipoEventoSlugsController.clear();
        _tipoEventoNomesController.clear();
      }
      return;
    }

    final ids = options.map((e) => e.id).toList();
    final slugs = options.map((e) => e.slug).toList();
    final nomes = options.map((e) => e.nome).toList();

    _tipoEventoIdsController.text = ids.join(', ');
    _tipoEventoSlugsController.text = slugs.join(', ');
    _tipoEventoNomesController.text = nomes.join(', ');

    if (!preferirCamposAtuais || _tipoEventoController.text.trim().isEmpty) {
      _tipoEventoController.text = nomes.first;
    }
    if (!preferirCamposAtuais || _tipoEventoIdController.text.trim().isEmpty) {
      _tipoEventoIdController.text = ids.first;
    }
    if (!preferirCamposAtuais ||
        _tipoEventoNormalizadoController.text.trim().isEmpty) {
      _tipoEventoNormalizadoController.text = slugs.first;
    }
  }

  bool _possuiTipoEventoValido() {
    final tipos = _resolverTiposEvento();
    return tipos.tipoEventoIds.isNotEmpty ||
        tipos.tipoEventoSlugs.isNotEmpty ||
        tipos.tipoEventoNomes.isNotEmpty ||
        tipos.tipoEvento.trim().isNotEmpty ||
        tipos.tipoEventoId.trim().isNotEmpty;
  }

  bool _possuiImagemPrincipal() {
    return controller.possuiImagemPrincipalFormulario ||
        _imagemUrlController.text.trim().isNotEmpty;
  }

  List<String> _parseStringList(String value) {
    return value
        .split(RegExp(r'[\n,;|]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
  }

  String _formatarTarefas(List<TarefaInspiracaoSugerida> tarefas) {
    return tarefas
        .map((tarefa) {
          return <String>[tarefa.titulo, tarefa.categoria, tarefa.descricao]
              .where((e) => e.trim().isNotEmpty)
              .join(' | ');
        })
        .where((e) => e.trim().isNotEmpty)
        .join('\n');
  }

  String _formatarItensOrcamento(List<ItemOrcamentoInspiracaoSugerido> itens) {
    return itens
        .map((item) {
          final valor =
              item.custoEstimado == 0 ? '' : item.custoEstimado.toString();
          return <String>[item.categoria, item.item, valor]
              .where((e) => e.trim().isNotEmpty)
              .join(' | ');
        })
        .where((e) => e.trim().isNotEmpty)
        .join('\n');
  }

  String _joinLista(Iterable<String> values) {
    return values.map((e) => e.trim()).where((e) => e.isNotEmpty).join(', ');
  }

  String _joinLinhas(Iterable<String> values) {
    return values.map((e) => e.trim()).where((e) => e.isNotEmpty).join('\n');
  }

  String _normalizeKey(String value) {
    var text = value.trim().toLowerCase();
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

    accents.forEach((key, value) {
      text = text.replaceAll(key, value);
    });

    text = text.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    text = text.replaceAll(RegExp(r'_+'), '_');
    if (text.startsWith('_')) text = text.substring(1);
    if (text.endsWith('_')) text = text.substring(0, text.length - 1);
    return text;
  }
}
