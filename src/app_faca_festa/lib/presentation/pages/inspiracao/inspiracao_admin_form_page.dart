import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../controllers/inspiracao/inspiracao_admin_controller.dart';
import './../../../data/models/model.dart';

class InspiracaoAdminFormPage extends StatefulWidget {
  final InspiracaoModel? inspiracao;
  final String? usuarioId;
  final bool imagemObrigatoria;

  const InspiracaoAdminFormPage({
    super.key,
    this.inspiracao,
    this.usuarioId,
    this.imagemObrigatoria = false,
  });

  @override
  State<InspiracaoAdminFormPage> createState() => _InspiracaoAdminFormPageState();
}

class _InspiracaoAdminFormPageState extends State<InspiracaoAdminFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final InspiracaoAdminController controller;
  late final InspiracaoModel? _inspiracaoInicial;

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

  XFile? _imagemSelecionada;
  Uint8List? _imagemSelecionadaBytes;
  String? _nomeImagemSelecionada;

  final Set<String> _tipoEventoIdsSelecionados = <String>{};

  static const Color _primary = Color(0xFFE94B8A);
  static const Color _secondary = Color(0xFFFF8A65);
  static const Color _dark = Color(0xFF1F2937);
  static const Color _muted = Color(0xFF64748B);
  static const Color _surface = Color(0xFFF8FAFC);
  static const Color _success = Color(0xFF10B981);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _info = Color(0xFF3B82F6);

  static const List<_TipoEventoOption> _tiposEventoPadrao = <_TipoEventoOption>[
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

  bool get _isEdicao => _inspiracaoInicial?.id.trim().isNotEmpty == true;

  String get _inspiracaoId => _inspiracaoInicial?.id.trim() ?? '';

  @override
  void initState() {
    super.initState();

    controller = Get.isRegistered<InspiracaoAdminController>()
        ? Get.find<InspiracaoAdminController>()
        : Get.put(InspiracaoAdminController());

    final arguments = Get.arguments;
    _inspiracaoInicial = widget.inspiracao ?? (arguments is InspiracaoModel ? arguments : null);

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
  }

  void _popularCampos() {
    final inspiracao = _inspiracaoInicial;
    final data =
        inspiracao == null ? <String, dynamic>{} : controller.dadosDaInspiracao(inspiracao.id);

    _tituloController.text = _readString(data, 'titulo', fallback: inspiracao?.titulo ?? '');
    _descricaoController.text = _readString(
      data,
      'descricao',
      fallback: inspiracao?.descricao ?? '',
    );
    _categoriaController.text = _readString(
      data,
      'categoria',
      fallback: inspiracao?.categoria ?? '',
    );
    _categoriaIdController.text = _readString(
      data,
      'categoriaId',
      fallback: inspiracao?.categoriaId ?? '',
    );
    _imagemUrlController.text = _readString(
      data,
      'imagemUrl',
      fallback: inspiracao?.imagemUrl ?? '',
    );
    _galeriaUrlsController.text = _readStringList(data, 'galeriaUrls').join('\n');
    _tagsController.text = _readStringList(
      data,
      'tags',
      fallback: inspiracao?.tags ?? const <String>[],
    ).join(', ');
    _paletaCoresController.text = _readStringList(data, 'paletaCores').join(', ');
    _estiloController.text = _readString(data, 'estilo');
    _faixaCustoController.text = _readString(data, 'faixaCusto');
    _nivelDificuldadeController.text = _readString(data, 'nivelDificuldade');
    _ordemController.text = _readInt(
      data,
      'ordem',
      fallback: _isEdicao ? 0 : controller.proximaOrdemSugerida(),
    ).toString();

    _tipoEventoController.text =
        _readString(data, 'tipoEvento', fallback: inspiracao?.tipoEvento ?? '');
    _tipoEventoIdController.text = _readString(
      data,
      'tipoEventoId',
      fallback: inspiracao?.tipoEventoId ?? '',
    );
    _tipoEventoNormalizadoController.text = _readString(
      data,
      'tipoEventoNormalizado',
      fallback: inspiracao?.tipoEventoNormalizado ?? '',
    );
    _tipoEventoIdsController.text = _readStringList(data, 'tipoEventoIds').join(', ');
    _tipoEventoSlugsController.text = _readStringList(data, 'tipoEventoSlugs').join(', ');
    _tipoEventoNomesController.text = _readStringList(data, 'tipoEventoNomes').join(', ');

    _tarefasSugeridasController.text = _formatarTarefas(_readMapList(data, 'tarefasSugeridas'));
    _itensOrcamentoSugeridosController.text = _formatarItensOrcamento(
      _readMapList(data, 'itensOrcamentoSugeridos'),
    );
    _categoriasFornecedorSugeridasController.text = _readStringList(
      data,
      'categoriasFornecedorSugeridas',
    ).join(', ');
    _fornecedoresRelacionadosController.text = _readDynamicList(
      data,
      'fornecedoresRelacionados',
    ).map((e) => e.toString()).where((e) => e.trim().isNotEmpty).join('\n');

    _ativo = _readBool(data, 'ativo', fallback: true);
    _publicado = _readBool(data, 'publicado', fallback: false);
    _destaque = _readBool(data, 'destaque', fallback: false);

    final ids = _readStringList(data, 'tipoEventoIds');
    final idPrincipal = _tipoEventoIdController.text.trim();
    final slugs = _readStringList(data, 'tipoEventoSlugs');
    final nomes = _readStringList(data, 'tipoEventoNomes');

    for (final option in _tiposEventoPadrao) {
      final selecionadoPorId = ids.contains(option.id) || idPrincipal == option.id;
      final selecionadoPorSlug = slugs.map(_normalizeKey).contains(option.slug);
      final selecionadoPorNome = nomes.map(_normalizeKey).contains(_normalizeKey(option.nome));
      if (selecionadoPorId || selecionadoPorSlug || selecionadoPorNome) {
        _tipoEventoIdsSelecionados.add(option.id);
      }
    }

    if (_tipoEventoIdsSelecionados.isNotEmpty) {
      _sincronizarCamposTipos(preferirCamposAtuais: true);
    }
  }

  @override
  void dispose() {
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
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                          subtitle: 'Informações básicas exibidas para o organizador do evento.',
                          child: Column(
                            children: [
                              _responsiveFields(
                                isWide: isWide,
                                children: [
                                  _buildTextField(
                                    controller: _tituloController,
                                    label: 'Título da inspiração',
                                    hint: 'Ex.: Mesa provençal rosa com dourado',
                                    icon: Icons.title_rounded,
                                    requiredField: true,
                                    validator: _requiredValidator('Informe o título.'),
                                  ),
                                  _buildTextField(
                                    controller: _categoriaController,
                                    label: 'Categoria',
                                    hint: 'Ex.: Decoração',
                                    icon: Icons.category_outlined,
                                    requiredField: true,
                                    validator: _requiredValidator('Informe a categoria.'),
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
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildTextField(
                                controller: _descricaoController,
                                label: 'Descrição',
                                hint: 'Descreva a ideia, quando usar e quais detalhes ela sugere.',
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
                          subtitle: 'Cadastre a imagem principal e URLs extras de referência.',
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
                              ),
                              const SizedBox(height: 12),
                              _buildTextField(
                                controller: _galeriaUrlsController,
                                label: 'Galeria de imagens',
                                hint: 'Uma URL por linha',
                                icon: Icons.collections_outlined,
                                minLines: 3,
                                maxLines: 6,
                              ),
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
                              if (_tentouSalvar && !_possuiTipoEventoValido()) ...[
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
                                    controller: _tipoEventoNormalizadoController,
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
                          subtitle: 'Dados usados para busca, filtros e experiência personalizada.',
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
                              _buildTextField(
                                controller: _tarefasSugeridasController,
                                label: 'Tarefas sugeridas',
                                hint: 'Uma por linha: título | categoria | descrição',
                                icon: Icons.checklist_rounded,
                                minLines: 4,
                                maxLines: 8,
                              ),
                              const SizedBox(height: 12),
                              _buildTextField(
                                controller: _itensOrcamentoSugeridosController,
                                label: 'Itens de orçamento sugeridos',
                                hint: 'Uma por linha: categoria | item | valor estimado',
                                icon: Icons.receipt_long_outlined,
                                minLines: 4,
                                maxLines: 8,
                              ),
                              const SizedBox(height: 12),
                              _responsiveFields(
                                isWide: isWide,
                                children: [
                                  _buildTextField(
                                    controller: _categoriasFornecedorSugeridasController,
                                    label: 'Categorias de fornecedor sugeridas',
                                    hint: 'Decoração, Buffet, Fotografia',
                                    icon: Icons.storefront_outlined,
                                  ),
                                  _buildTextField(
                                    controller: _fornecedoresRelacionadosController,
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
                          subtitle: 'Controle de disponibilidade da inspiração no app público.',
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

  Widget _buildHeroCard({required bool isWide}) {
    return Container(
      padding: EdgeInsets.fromLTRB(isWide ? 22 : 18, 18, isWide ? 22 : 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primary, _secondary],
        ),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.20),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isWide ? 58 : 50,
            height: isWide ? 58 : 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEdicao ? 'Editar inspiração pública' : 'Cadastrar inspiração pública',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: isWide ? 22 : 18,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Preencha os dados com cuidado para que a ideia apareça corretamente nas buscas, filtros e sugestões do evento.',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontWeight: FontWeight.w500,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Obx(() {
          final salvando = controller.salvando.value || controller.enviandoImagem.value;
          final compact = MediaQuery.sizeOf(context).width < 520;

          final cancelar = OutlinedButton.icon(
            onPressed: salvando ? null : () => Get.back(result: false),
            style: OutlinedButton.styleFrom(
              foregroundColor: _dark,
              side: BorderSide(color: _dark.withValues(alpha: 0.16)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            ),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Cancelar'),
          );

          final salvar = FilledButton.icon(
            onPressed: salvando ? null : _salvar,
            style: FilledButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            ),
            icon: salvando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_rounded, size: 18),
            label: Text(salvando ? 'Salvando...' : 'Salvar'),
          );

          if (compact) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                salvar,
                const SizedBox(height: 8),
                cancelar,
              ],
            );
          }

          return Row(
            children: [
              if (_isEdicao)
                TextButton.icon(
                  onPressed: salvando ? null : _confirmarExclusao,
                  style: TextButton.styleFrom(foregroundColor: _danger),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Excluir logicamente'),
                ),
              const Spacer(),
              cancelar,
              const SizedBox(width: 10),
              salvar,
            ],
          );
        }),
      ),
    );
  }

  Widget _responsiveFields({
    required bool isWide,
    required List<Widget> children,
  }) {
    if (!isWide) {
      return Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: children
          .map(
            (child) => SizedBox(
              width: 360,
              child: child,
            ),
          )
          .toList(),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    bool requiredField = false,
    int minLines = 1,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      inputFormatters: inputFormatters,
      textInputAction: maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
      style: GoogleFonts.poppins(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: _dark,
      ),
      decoration: InputDecoration(
        labelText: requiredField ? '$label *' : label,
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.white,
        alignLabelWithHint: maxLines > 1,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        labelStyle: GoogleFonts.poppins(
          color: _muted,
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
        ),
        hintStyle: GoogleFonts.poppins(
          color: _muted.withValues(alpha: 0.72),
          fontWeight: FontWeight.w500,
          fontSize: 12.5,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: _dark.withValues(alpha: 0.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: _dark.withValues(alpha: 0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _danger, width: 1.2),
        ),
      ),
    );
  }

  Widget _buildImagePanel() {
    final imagemUrl = _imagemUrlController.text.trim();
    final hasCurrentImage = imagemUrl.isNotEmpty;
    final hasSelectedImage = _imagemSelecionadaBytes != null;
    final missingImage = !hasCurrentImage && !hasSelectedImage;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: missingImage ? _warning.withValues(alpha: 0.08) : _info.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: missingImage ? _warning.withValues(alpha: 0.26) : _info.withValues(alpha: 0.16),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final preview = _buildImagePreview();
          final actions = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Imagem principal',
                style: GoogleFonts.poppins(
                  color: _dark,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Você pode informar uma URL ou selecionar uma imagem para upload. A imagem melhora a experiência visual na área pública.',
                style: GoogleFonts.poppins(
                  color: _muted,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              if (missingImage) ...[
                const SizedBox(height: 10),
                _buildInlineWarning(
                  widget.imagemObrigatoria
                      ? 'Imagem principal obrigatória para salvar.'
                      : 'Imagem principal ainda não informada. Você pode salvar, mas o card ficará menos atrativo.',
                  color: widget.imagemObrigatoria ? _danger : _warning,
                  icon: widget.imagemObrigatoria
                      ? Icons.error_outline_rounded
                      : Icons.info_outline_rounded,
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: _selecionarImagemPrincipal,
                    style: FilledButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.upload_rounded, size: 18),
                    label: const Text('Selecionar imagem'),
                  ),
                  if (hasSelectedImage || hasCurrentImage)
                    OutlinedButton.icon(
                      onPressed: _limparImagemPrincipal,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _danger,
                        side: BorderSide(color: _danger.withValues(alpha: 0.28)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Remover'),
                    ),
                ],
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                preview,
                const SizedBox(height: 12),
                actions,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 220, child: preview),
              const SizedBox(width: 14),
              Expanded(child: actions),
            ],
          );
        },
      ),
    );
  }

  Widget _buildImagePreview() {
    final imagemUrl = _imagemUrlController.text.trim();

    Widget child;
    if (_imagemSelecionadaBytes != null) {
      child = Image.memory(
        _imagemSelecionadaBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else if (imagemUrl.isNotEmpty) {
      child = Image.network(
        imagemUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _buildImagePlaceholder(
          icon: Icons.broken_image_outlined,
          text: 'Não foi possível carregar a imagem',
        ),
      );
    } else {
      child = _buildImagePlaceholder(
        icon: Icons.image_outlined,
        text: 'Sem imagem',
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 10,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: ColoredBox(
          color: Colors.white,
          child: child,
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder({required IconData icon, required String text}) {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _muted, size: 34),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: _muted,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineWarning(String text, {required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: _dark,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipoEventoChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _tiposEventoPadrao.map((option) {
        final selected = _tipoEventoIdsSelecionados.contains(option.id);
        return FilterChip(
          selected: selected,
          label: Text(option.nome),
          avatar: selected ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
          onSelected: (value) {
            setState(() {
              if (value) {
                _tipoEventoIdsSelecionados.add(option.id);
              } else {
                _tipoEventoIdsSelecionados.remove(option.id);
              }
              _sincronizarCamposTipos();
            });
          },
          labelStyle: GoogleFonts.poppins(
            color: selected ? Colors.white : _dark,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          selectedColor: _primary,
          checkmarkColor: Colors.white,
          backgroundColor: Colors.white,
          side: BorderSide(
            color: selected ? _primary : _dark.withValues(alpha: 0.10),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        );
      }).toList(),
    );
  }

  Widget _buildPublicacaoCards({required bool isWide}) {
    final cards = <Widget>[
      _SwitchStatusCard(
        title: 'Ativa',
        subtitle: 'Permite que a inspiração continue disponível no catálogo.',
        icon: Icons.toggle_on_outlined,
        color: _success,
        value: _ativo,
        onChanged: (value) => setState(() => _ativo = value),
      ),
      _SwitchStatusCard(
        title: 'Publicada',
        subtitle: 'Exibe a inspiração para os organizadores no app público.',
        icon: Icons.public_rounded,
        color: _info,
        value: _publicado,
        onChanged: (value) => setState(() => _publicado = value),
      ),
      _SwitchStatusCard(
        title: 'Destaque',
        subtitle: 'Prioriza a inspiração em listas e vitrines de ideias.',
        icon: Icons.star_rounded,
        color: _warning,
        value: _destaque,
        onChanged: (value) => setState(() => _destaque = value),
      ),
    ];

    if (!isWide) {
      return Column(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i < cards.length - 1) const SizedBox(height: 10),
          ],
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i < cards.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }

  Future<void> _selecionarImagemPrincipal() async {
    final imagem = await controller.escolherImagem(source: ImageSource.gallery);
    if (imagem == null) return;

    final bytes = await imagem.readAsBytes();
    setState(() {
      _imagemSelecionada = imagem;
      _imagemSelecionadaBytes = bytes;
      _nomeImagemSelecionada = imagem.name;
    });
  }

  void _limparImagemPrincipal() {
    setState(() {
      _imagemSelecionada = null;
      _imagemSelecionadaBytes = null;
      _nomeImagemSelecionada = null;
      _imagemUrlController.clear();
    });
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

    if (widget.imagemObrigatoria && !_possuiImagemPrincipal()) {
      EasyLoading.showInfo('Informe ou selecione a imagem principal.');
      return;
    }

    final dados = _montarPayloadFormulario();

    final id = await controller.salvarInspiracao(
      id: _isEdicao ? _inspiracaoId : null,
      dados: dados,
      imagemPrincipal: _imagemSelecionada,
      imagemPrincipalBytes: _imagemSelecionadaBytes,
      nomeImagemPrincipal: _nomeImagemSelecionada,
      usuarioId: widget.usuarioId,
    );

    if (id != null && id.trim().isNotEmpty) {
      Get.back(result: true);
    }
  }

  Future<void> _confirmarExclusao() async {
    if (!_isEdicao) return;

    final titulo =
        _tituloController.text.trim().isEmpty ? 'esta inspiração' : _tituloController.text.trim();

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
                style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 18),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.delete_rounded, size: 18),
            label: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final sucesso =
          await controller.excluirLogicamente(_inspiracaoId, usuarioId: widget.usuarioId);
      if (sucesso) {
        Get.back(result: true);
      }
    }
  }

  Map<String, dynamic> _montarPayloadFormulario() {
    final tipos = _resolverTiposEvento();

    return <String, dynamic>{
      'titulo': _tituloController.text.trim(),
      'descricao': _descricaoController.text.trim(),
      'categoria': _categoriaController.text.trim(),
      'categoriaId': _categoriaIdController.text.trim().isNotEmpty
          ? _categoriaIdController.text.trim()
          : _normalizeKey(_categoriaController.text),
      'imagemUrl': _imagemUrlController.text.trim(),
      'galeriaUrls': _parseStringList(_galeriaUrlsController.text),
      'tags': _parseStringList(_tagsController.text),
      'paletaCores': _parseStringList(_paletaCoresController.text),
      'estilo': _estiloController.text.trim(),
      'faixaCusto': _faixaCustoController.text.trim(),
      'nivelDificuldade': _nivelDificuldadeController.text.trim(),
      'ordem': int.tryParse(_ordemController.text.trim()) ?? controller.proximaOrdemSugerida(),
      'tipoEvento': tipos.tipoEvento,
      'tipoEventoId': tipos.tipoEventoId,
      'tipoEventoNormalizado': tipos.tipoEventoNormalizado,
      'tipoEventoIds': tipos.tipoEventoIds,
      'tipoEventoSlugs': tipos.tipoEventoSlugs,
      'tipoEventoNomes': tipos.tipoEventoNomes,
      'tarefasSugeridas': _parseTarefasSugeridas(_tarefasSugeridasController.text),
      'itensOrcamentoSugeridos': _parseItensOrcamentoSugeridos(
        _itensOrcamentoSugeridosController.text,
      ),
      'categoriasFornecedorSugeridas': _parseStringList(
        _categoriasFornecedorSugeridasController.text,
      ),
      'fornecedoresRelacionados': _parseStringList(_fornecedoresRelacionadosController.text),
      'ativo': _ativo,
      'publicado': _publicado,
      'destaque': _destaque,
      'deletado': false,
    };
  }

  _TiposEventoResolvidos _resolverTiposEvento() {
    final selectedOptions = _tiposEventoPadrao
        .where((option) => _tipoEventoIdsSelecionados.contains(option.id))
        .toList();

    final ids = LinkedHashSet<String>();
    final slugs = LinkedHashSet<String>();
    final nomes = LinkedHashSet<String>();

    for (final option in selectedOptions) {
      ids.add(option.id);
      slugs.add(option.slug);
      nomes.add(option.nome);
    }

    ids.addAll(_parseStringList(_tipoEventoIdsController.text));
    slugs.addAll(_parseStringList(_tipoEventoSlugsController.text).map(_normalizeKey));
    nomes.addAll(_parseStringList(_tipoEventoNomesController.text));

    final tipoEventoManual = _tipoEventoController.text.trim();
    final tipoEventoIdManual = _tipoEventoIdController.text.trim();
    final tipoEventoNormalizadoManual = _tipoEventoNormalizadoController.text.trim();

    if (tipoEventoIdManual.isNotEmpty) ids.add(tipoEventoIdManual);
    if (tipoEventoManual.isNotEmpty) nomes.add(tipoEventoManual);
    if (tipoEventoNormalizadoManual.isNotEmpty) {
      slugs.add(_normalizeKey(tipoEventoNormalizadoManual));
    }

    final tipoEvento = nomes.isNotEmpty ? nomes.first : tipoEventoManual;
    final tipoEventoId = ids.isNotEmpty ? ids.first : tipoEventoIdManual;
    final tipoEventoNormalizado = slugs.isNotEmpty
        ? slugs.first
        : _normalizeKey(
            tipoEventoNormalizadoManual.isNotEmpty ? tipoEventoNormalizadoManual : tipoEvento);

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
    if (!preferirCamposAtuais || _tipoEventoNormalizadoController.text.trim().isEmpty) {
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
    return _imagemSelecionadaBytes != null || _imagemUrlController.text.trim().isNotEmpty;
  }

  String? Function(String?) _requiredValidator(String message) {
    return (value) {
      if ((value ?? '').trim().isEmpty) {
        return message;
      }
      return null;
    };
  }

  List<String> _parseStringList(String value) {
    return value
        .split(RegExp(r'[\n,;|]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
  }

  List<Map<String, dynamic>> _parseTarefasSugeridas(String value) {
    final linhas = value.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    return linhas.map((linha) {
      final partes = linha.split('|').map((e) => e.trim()).toList();
      final titulo = partes.isNotEmpty ? partes[0] : linha;
      final categoria =
          partes.length > 1 && partes[1].isNotEmpty ? partes[1] : _categoriaController.text.trim();
      final descricao = partes.length > 2 ? partes.sublist(2).join(' | ').trim() : '';

      return <String, dynamic>{
        'titulo': titulo,
        'categoria': categoria,
        'descricao': descricao,
        'status': 'pendente',
        'origem': 'inspiracao_admin',
      };
    }).toList();
  }

  List<Map<String, dynamic>> _parseItensOrcamentoSugeridos(String value) {
    final linhas = value.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    return linhas.map((linha) {
      final partes = linha.split('|').map((e) => e.trim()).toList();
      final categoria =
          partes.isNotEmpty && partes[0].isNotEmpty ? partes[0] : _categoriaController.text.trim();
      final item = partes.length > 1 && partes[1].isNotEmpty ? partes[1] : linha;
      final valor = partes.length > 2 ? _parseDoubleBr(partes[2]) : 0.0;

      return <String, dynamic>{
        'categoria': categoria,
        'item': item,
        'custoEstimado': valor,
        'custoReal': 0.0,
        'statusPagamento': 'pendente',
        'origem': 'inspiracao_admin',
      };
    }).toList();
  }

  double _parseDoubleBr(String value) {
    final normalized = value.replaceAll('R\$', '').replaceAll('.', '').replaceAll(',', '.').trim();
    return double.tryParse(normalized) ?? 0.0;
  }

  String _formatarTarefas(List<Map<String, dynamic>> tarefas) {
    return tarefas
        .map((tarefa) {
          final titulo = (tarefa['titulo'] ?? tarefa['nome'] ?? '').toString().trim();
          final categoria = (tarefa['categoria'] ?? '').toString().trim();
          final descricao = (tarefa['descricao'] ?? '').toString().trim();
          return <String>[titulo, categoria, descricao]
              .where((e) => e.trim().isNotEmpty)
              .join(' | ');
        })
        .where((e) => e.trim().isNotEmpty)
        .join('\n');
  }

  String _formatarItensOrcamento(List<Map<String, dynamic>> itens) {
    return itens
        .map((item) {
          final categoria = (item['categoria'] ?? '').toString().trim();
          final nome = (item['item'] ?? item['nome'] ?? '').toString().trim();
          final valor = (item['custoEstimado'] ?? item['valorEstimado'] ?? '').toString().trim();
          return <String>[categoria, nome, valor].where((e) => e.trim().isNotEmpty).join(' | ');
        })
        .where((e) => e.trim().isNotEmpty)
        .join('\n');
  }

  String _readString(
    Map<String, dynamic> data,
    String key, {
    String fallback = '',
  }) {
    final value = data[key];
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  int _readInt(Map<String, dynamic> data, String key, {int fallback = 0}) {
    final value = data[key];
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  bool _readBool(Map<String, dynamic> data, String key, {bool fallback = false}) {
    final value = data[key];
    if (value == null) return fallback;
    if (value is bool) return value;
    final text = value.toString().trim().toLowerCase();
    if (<String>{'true', '1', 'sim', 's', 'yes', 'y'}.contains(text)) return true;
    if (<String>{'false', '0', 'nao', 'não', 'n', 'no'}.contains(text)) return false;
    return fallback;
  }

  List<String> _readStringList(
    Map<String, dynamic> data,
    String key, {
    List<String> fallback = const <String>[],
  }) {
    final value = data[key];
    if (value == null) return fallback;
    if (value is List) {
      return value
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
    }

    final text = value.toString().trim();
    if (text.isEmpty) return fallback;
    return _parseStringList(text);
  }

  List<dynamic> _readDynamicList(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) return <dynamic>[];
    if (value is List) return value;
    return <dynamic>[value];
  }

  List<Map<String, dynamic>> _readMapList(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) return <Map<String, dynamic>>[];
    if (value is List) {
      return value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    if (value is Map) return <Map<String, dynamic>>[Map<String, dynamic>.from(value)];
    return <Map<String, dynamic>>[];
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

class _FormSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _FormSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFF1F2937).withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE94B8A), Color(0xFFFF8A65)],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF1F2937),
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _SwitchStatusCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchStatusCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: value ? 0.10 : 0.045),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: value ? 0.25 : 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF1F2937),
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: color,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _TipoEventoOption {
  final String id;
  final String nome;
  final String slug;

  const _TipoEventoOption({
    required this.id,
    required this.nome,
    required this.slug,
  });
}

class _TiposEventoResolvidos {
  final String tipoEvento;
  final String tipoEventoId;
  final String tipoEventoNormalizado;
  final List<String> tipoEventoIds;
  final List<String> tipoEventoSlugs;
  final List<String> tipoEventoNomes;

  const _TiposEventoResolvidos({
    required this.tipoEvento,
    required this.tipoEventoId,
    required this.tipoEventoNormalizado,
    required this.tipoEventoIds,
    required this.tipoEventoSlugs,
    required this.tipoEventoNomes,
  });
}
