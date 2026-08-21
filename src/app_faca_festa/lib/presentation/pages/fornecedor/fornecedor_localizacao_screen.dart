import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

import '../../../app/bootstrap/fornecedor_recomendacao_bootstrap.dart';
import './../../../controllers/fornecedor/fornecedor_recomendacao_controller.dart';
import './../../../../data/models/servico_produto/categoria_servico_model.dart';
import '../../../controllers/fornecedor/fornecedor_localizacao_controller.dart';
import '../../../data/models/fornecedor/fornecedor_recomendacao_model.dart';
import './../../../data/models/DTO/fornecedor_servico_detalhado_dto.dart';
import './../../../data/models/DTO/fornecedor_detalhado_dto.dart';
import './../../../controllers/tema/event_theme_controller.dart';
import './../../../controllers/evento_controller.dart';
import './cotacao/servico_detalhe_screen.dart';
import './../../../core/utils/biblioteca.dart';
import './../../widgets/festa_app_bar.dart';
import './fornecedor_detalhe_screen.dart';

class FornecedorLocalizacaoScreen extends StatefulWidget {
  final bool? showLeading;
  const FornecedorLocalizacaoScreen({super.key, required this.showLeading});

  @override
  State<FornecedorLocalizacaoScreen> createState() =>
      _FornecedorLocalizacaoScreenState();
}

class _FornecedorLocalizacaoScreenState
    extends State<FornecedorLocalizacaoScreen>
    with AutomaticKeepAliveClientMixin {
  final EventThemeController themeController = Get.find<EventThemeController>();
  final FornecedorLocalizacaoController controllerLocalizacao =
      FornecedorLocalizacaoController.to;
  final EventoController eventoController = Get.find<EventoController>();
  final FornecedorRecomendacaoController recomendacaoController =
      FornecedorRecomendacaoBootstrap.findController();

  final TextEditingController _searchController = TextEditingController();
  final PageController _servicosPageController =
      PageController(viewportFraction: 0.88);

  CategoriaServicoModel? categoriaSelecionada;
  String termoBusca = '';
  bool _recomendacoesSolicitadas = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_carregarRecomendacoesIA());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _servicosPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Obx(() {
      final gradient = themeController.gradient.value;
      final primary = themeController.primaryColor.value;
      final bool automaticallyImplyLeading = widget.showLeading ?? false;

      final fornecedoresBase = _baseFornecedores();
      final fornecedoresFiltrados = _aplicarFiltros(fornecedoresBase);
      final fornecedoresProximos =
          _aplicarFiltros(controllerLocalizacao.fornecedoresProximos.toList());
      final fornecedoresDestaque =
          _aplicarFiltros(controllerLocalizacao.fornecedoresDestaque.toList());
      final recomendados =
          _recomendados(fornecedoresFiltrados, fornecedoresDestaque);

      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: FestaAppBar(
          titulo: 'Fornecedores',
          automaticamenteImplyLeading: automaticallyImplyLeading,
          acoes: [
            IconButton(
              tooltip: 'Filtros',
              icon:
                  const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
              onPressed: () => Get.back(), // Pode adicionar a lógica do filtro
            )
          ],
        ),
        body: RefreshIndicator(
          color: primary,
          onRefresh: () async {
            await controllerLocalizacao.inicializar(forcarLocalizacao: true);
            if (categoriaSelecionada != null) {
              await controllerLocalizacao
                  .buscarServicosPorCategoria(categoriaSelecionada!.id);
            }
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeroSection(
                  primary: primary,
                  gradient: gradient,
                  totalFornecedores: fornecedoresFiltrados.length,
                ),
              ),
              SliverToBoxAdapter(
                child: _buildIACompactaFornecedores(
                  primary: primary,
                  gradient: gradient,
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _CategoriasHeaderDelegateBuilder(
                  child: _menuCategorias(primary, gradient),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: controllerLocalizacao.carregando.value
                      ? _loadingState(primary)
                      : _buildConteudo(
                          primary: primary,
                          gradient: gradient,
                          fornecedoresFiltrados: fornecedoresFiltrados,
                          fornecedoresProximos: fornecedoresProximos,
                          fornecedoresDestaque: fornecedoresDestaque,
                          recomendados: recomendados,
                        ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Map<String, String> _dadosEventoParaIA() {
    final eventoAtual = eventoController.eventoAtualEntidade;
    final tipoEventoAtual = eventoController.tipoEventoAtualEntidade;

    return {
      'idUsuario': FirebaseAuth.instance.currentUser?.uid ?? '',
      'idEvento': eventoAtual?.idEvento ?? '',
      'tipoEventoId': tipoEventoAtual?.idTipoEvento ?? '',
      'tipoEventoNome': tipoEventoAtual?.nome ?? '',
      'cidade': eventoAtual?.nomeCidade ?? '',
    };
  }

  Future<void> _carregarRecomendacoesIA({bool forcar = false}) async {
    final dados = _dadosEventoParaIA();
    final idEvento = dados['idEvento'] ?? '';
    final idUsuario = dados['idUsuario'] ?? '';

    if (idEvento.trim().isEmpty || idUsuario.trim().isEmpty) {
      return;
    }

    if (!forcar &&
        _recomendacoesSolicitadas &&
        recomendacaoController.recomendacoes.isNotEmpty) {
      return;
    }

    _recomendacoesSolicitadas = true;
    await recomendacaoController.garantirRecomendacoes(
      idEvento: idEvento,
      idUsuario: idUsuario,
      limite: 5,
      forcar: forcar,
      gerarSeVazio: true,
      modoDemo: true,
    );
  }

  Widget _buildIACompactaFornecedores({
    required Color primary,
    required LinearGradient gradient,
  }) {
    final dados = _dadosEventoParaIA();
    final idEvento = dados['idEvento'] ?? '';
    final idUsuario = dados['idUsuario'] ?? '';

    if (idEvento.trim().isEmpty || idUsuario.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    // Sem Obx aninhado: o Obx da tela já observa estes Rx.
    final loading = recomendacaoController.carregando.value ||
        recomendacaoController.gerando.value;
    final recomendacoes = recomendacaoController.recomendacoes.take(5).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primary.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
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
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primary.withValues(alpha: 0.95),
                      gradient.colors.last.withValues(alpha: 0.85),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fornecedores ideais para seu evento',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      recomendacoes.isEmpty
                          ? 'A IA analisa perfil, localização e avaliações.'
                          : '${recomendacoes.length} sugestão${recomendacoes.length == 1 ? '' : 'ões'} personalizada${recomendacoes.length == 1 ? '' : 's'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                height: 32,
                child: TextButton.icon(
                  onPressed: loading
                      ? null
                      : () => _carregarRecomendacoesIA(forcar: true),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    foregroundColor: primary,
                  ),
                  icon: loading
                      ? SizedBox(
                          width: 13,
                          height: 13,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: primary,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded, size: 15),
                  label: Text(
                    loading ? 'IA' : 'Atualizar',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (loading && recomendacoes.isEmpty) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              minHeight: 4,
              color: primary,
              backgroundColor: primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            const SizedBox(height: 8),
            Text(
              'Analisando fornecedores compatíveis...',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else if (recomendacoes.isEmpty) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _carregarRecomendacoesIA(forcar: true),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.psychology_alt_rounded,
                        color: primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Gerar recomendações inteligentes agora',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded,
                        color: primary, size: 12),
                  ],
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: recomendacoes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) => _IACardFornecedorCompacto(
                  recomendacao: recomendacoes[index],
                  primary: primary,
                  onTap: () =>
                      _abrirFornecedorRecomendadoIA(recomendacoes[index]),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _abrirFornecedorRecomendadoIA(
    FornecedorRecomendacaoModel recomendacao,
  ) async {
    final dados = _dadosEventoParaIA();

    await recomendacaoController.visualizarFornecedor(
      idEvento: dados['idEvento'] ?? '',
      idFornecedor: recomendacao.idFornecedor,
      tipoEventoId: dados['tipoEventoId'],
      tipoEventoNome: dados['tipoEventoNome'],
      cidade: dados['cidade'],
    );

    final fornecedor =
        _buscarFornecedorDetalhadoPorId(recomendacao.idFornecedor);

    if (fornecedor == null) {
      Get.snackbar(
        'Fornecedor recomendado',
        'A recomendação foi gerada, mas o fornecedor ainda não foi carregado na vitrine. Atualize a tela e tente novamente.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
      );
      return;
    }

    _abrirDetalheFornecedor(fornecedor);
  }

  FornecedorDetalhadoDto? _buscarFornecedorDetalhadoPorId(String idFornecedor) {
    final id = idFornecedor.trim();
    if (id.isEmpty) return null;

    final listas = <FornecedorDetalhadoDto>[
      ...controllerLocalizacao.fornecedoresFiltrados,
      ...controllerLocalizacao.fornecedoresProximos,
      ...controllerLocalizacao.fornecedoresDestaque,
      ...controllerLocalizacao.fornecedores,
    ];

    for (final item in listas) {
      if (item.fornecedor.idFornecedor.trim() == id) {
        return item;
      }
    }

    return null;
  }

  List<FornecedorDetalhadoDto> _baseFornecedores() {
    final filtrados = controllerLocalizacao.fornecedoresFiltrados.toList();
    if (filtrados.isNotEmpty) return filtrados;
    final proximos = controllerLocalizacao.fornecedoresProximos.toList();
    if (proximos.isNotEmpty) return proximos;
    return controllerLocalizacao.fornecedores.toList();
  }

  List<FornecedorDetalhadoDto> _aplicarFiltros(
      List<FornecedorDetalhadoDto> lista) {
    final termo = termoBusca.trim().toLowerCase();
    var resultado = List<FornecedorDetalhadoDto>.from(lista);
    if (categoriaSelecionada != null) {
      final idCategoria = categoriaSelecionada!.id;
      final nomeCategoria = categoriaSelecionada!.nome.trim().toLowerCase();
      resultado = resultado
          .where((f) =>
              f.categoriaId == idCategoria ||
              f.categoriaNome.toLowerCase().contains(nomeCategoria))
          .toList();
    }
    if (termo.isNotEmpty) {
      resultado = resultado.where((f) {
        final fornecedor = f.fornecedor;
        final nome = fornecedor.razaoSocial.toLowerCase();
        final descricao = (fornecedor.descricao ?? '').toLowerCase();
        final categoria = f.categoriaNome.toLowerCase();
        return nome.contains(termo) ||
            descricao.contains(termo) ||
            categoria.contains(termo);
      }).toList();
    }
    resultado.sort((a, b) {
      final cmpNota =
          (controllerLocalizacao.mediasAvaliacoes[b.fornecedor.idFornecedor] ??
                  0.0)
              .compareTo(controllerLocalizacao
                      .mediasAvaliacoes[a.fornecedor.idFornecedor] ??
                  0.0);
      if (cmpNota != 0) return cmpNota;
      return (a.distanciaKm ?? 999999).compareTo(b.distanciaKm ?? 999999);
    });
    return resultado;
  }

  List<FornecedorDetalhadoDto> _recomendados(List<FornecedorDetalhadoDto> todos,
      List<FornecedorDetalhadoDto> destaques) {
    final mapa = <String, FornecedorDetalhadoDto>{};
    for (final f in destaques) {
      mapa[f.fornecedor.idFornecedor] = f;
    }
    for (final f in todos) {
      mapa.putIfAbsent(f.fornecedor.idFornecedor, () => f);
      if (mapa.length >= 8) break;
    }
    return mapa.values.take(8).toList();
  }

  Widget _buildHeroSection(
      {required Color primary,
      required LinearGradient gradient,
      required int totalFornecedores}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withValues(alpha: 0.95),
            primary.withValues(alpha: 0.75)
          ],
        ),
        boxShadow: [
          BoxShadow(
              color: primary.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.handshake_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Encontre fornecedores',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Tudo para a sua festa.',
                      style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildSearchBox(primary),
        ],
      ),
    );
  }

  Widget _buildSearchBox(Color primary) {
    return Container(
      height: 38, // Bem compacto
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => termoBusca = value),
        textInputAction: TextInputAction.search,
        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'Buscar buffet, decoração...',
          hintStyle:
              GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 12),
          prefixIcon: Icon(Icons.search_rounded,
              color: primary.withValues(alpha: 0.8), size: 16),
          suffixIcon: termoBusca.trim().isEmpty
              ? null
              : IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.close_rounded, size: 14),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => termoBusca = '');
                  },
                ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        ),
      ),
    );
  }

  Widget _menuCategorias(Color primary, LinearGradient gradient) {
    final categorias = controllerLocalizacao.categorias.toList();

    return SizedBox(
      height: _CategoriasHeaderDelegateBuilder.extent,
      child: ColoredBox(
        color: const Color(0xFFF8FAFC).withValues(alpha: 0.98),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemCount: categorias.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _NeedChip(
                label: 'Todos',
                icon: Icons.grid_view_rounded,
                selected: categoriaSelecionada == null,
                primary: primary,
                onTap: () {
                  setState(() => categoriaSelecionada = null);
                },
              );
            }
            final c = categorias[index - 1];
            return _NeedChip(
              label: c.nome,
              icon: Biblioteca.iconePorCategoria(c.nome),
              selected: categoriaSelecionada?.id == c.id,
              primary: primary,
              iconColor: Biblioteca.corPorCategoria(c.nome),
              onTap: () async {
                setState(() => categoriaSelecionada =
                    (categoriaSelecionada?.id == c.id) ? null : c);
                if (categoriaSelecionada != null) {
                  await controllerLocalizacao.buscarServicosPorCategoria(c.id);
                }
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildConteudo({
    required Color primary,
    required LinearGradient gradient,
    required List<FornecedorDetalhadoDto> fornecedoresFiltrados,
    required List<FornecedorDetalhadoDto> fornecedoresProximos,
    required List<FornecedorDetalhadoDto> fornecedoresDestaque,
    required List<FornecedorDetalhadoDto> recomendados,
  }) {
    if (fornecedoresFiltrados.isEmpty &&
        fornecedoresProximos.isEmpty &&
        fornecedoresDestaque.isEmpty) {
      return _mensagemVazia(primary);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (categoriaSelecionada != null) _categoriaSelecionadaBanner(primary),
        if (categoriaSelecionada != null) ...[
          _carrosselServicos(primary),
        ],
        if (fornecedoresProximos.isNotEmpty) ...[
          _SectionHeader(
              title: 'Perto de você',
              icon: Icons.near_me_rounded,
              color: primary),
          _horizontalFornecedores(
              fornecedoresProximos.take(8).toList(), primary, gradient),
        ],
        _SectionHeader(
            title: 'Todos os fornecedores',
            icon: Icons.storefront_rounded,
            color: primary),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: fornecedoresFiltrados
                .map((f) => _FornecedorListCard(
                      fornecedorDetalhado: f,
                      media: controllerLocalizacao
                              .mediasAvaliacoes[f.fornecedor.idFornecedor] ??
                          0.0,
                      primary: primary,
                      categoriaSelecionada: categoriaSelecionada,
                      onTap: () => _abrirDetalheFornecedor(f),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _horizontalFornecedores(List<FornecedorDetalhadoDto> fornecedores,
      Color primary, LinearGradient gradient) {
    return SizedBox(
      height: 185, // Reduzido
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: fornecedores.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) => SizedBox(
          width: 175, // Cards mais estreitos
          child: _FornecedorPremiumCard(
            fornecedorDetalhado: fornecedores[index],
            media: controllerLocalizacao.mediasAvaliacoes[
                    fornecedores[index].fornecedor.idFornecedor] ??
                0.0,
            primary: primary,
            categoriaSelecionada: categoriaSelecionada,
            onTap: () => _abrirDetalheFornecedor(fornecedores[index]),
          ),
        ),
      ),
    );
  }

  Widget _categoriaSelecionadaBanner(Color primary) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(Biblioteca.iconePorCategoria(categoriaSelecionada!.nome),
              color: primary, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              categoriaSelecionada!.nome,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937)),
            ),
          ),
          InkWell(
            onTap: () {
              setState(() => categoriaSelecionada = null);
            },
            child: Icon(Icons.close_rounded, size: 16, color: primary),
          ),
        ],
      ),
    );
  }

  Widget _carrosselServicos(Color primary) {
    final lista = controllerLocalizacao.servicosPorCategoria.toList();
    if (lista.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
            title: 'Serviços disponíveis',
            icon: Icons.room_service_rounded,
            color: primary),
        SizedBox(
          height: 140, // Reduzido de 180 para 140
          child: PageView.builder(
            controller: _servicosPageController,
            physics: const BouncingScrollPhysics(),
            itemCount: lista.length,
            itemBuilder: (_, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _cardServicoCarrossel(lista[index], primary),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _cardServicoCarrossel(FornecedorServicoDetalhadoDto s, Color primary) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Positioned.fill(child: _servicoImagem(s, primary)),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.85)
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: _GlassBadge(
                  icon: Icons.category_rounded,
                  label: s.nomeSubcategoria ?? s.nomeCategoria ?? 'Serviço'),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.nomeServico ?? 'Serviço',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                  ),
                  Text(
                    s.nomeFornecedor ?? 'Fornecedor',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        color: Colors.white70, fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(child: _precoServico(s)),
                      SizedBox(
                        height: 26, // Botão compacto
                        child: ElevatedButton(
                          onPressed: () {
                            Get.to(() => ServicoDetalheScreen(servico: s));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: primary,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Ver',
                              style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _servicoImagem(FornecedorServicoDetalhadoDto s, Color primary) {
    if (s.imagemUrl != null && s.imagemUrl!.isNotEmpty) {
      return CachedNetworkImage(imageUrl: s.imagemUrl!, fit: BoxFit.cover);
    }
    return Container(
        color: primary.withValues(alpha: 0.1),
        child: const Icon(Icons.image, color: Colors.white, size: 24));
  }

  Widget _precoServico(FornecedorServicoDetalhadoDto s) {
    final v = (s.precoPromocao ?? 0.0) > 0 ? s.precoPromocao! : s.preco;
    if (v <= 0) {
      return Text('Sob consulta',
          style: GoogleFonts.poppins(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700));
    }
    return Text('R\$ ${Biblioteca.formatarValorDecimal(v)}',
        style: GoogleFonts.poppins(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700));
  }

  Widget _loadingState(Color primary) => const Center(
      child: Padding(
          padding: EdgeInsets.all(40), child: CircularProgressIndicator()));

  Widget _mensagemVazia(Color primary) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text("Nenhum fornecedor",
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.grey.shade500)),
        ),
      );

  void _abrirDetalheFornecedor(FornecedorDetalhadoDto f) {
    Get.to(() => FornecedorDetalheScreen(
        fornecedorDetalhado: categoriaSelecionada != null
            ? f.copyWith(
                categoriaId: categoriaSelecionada!.id,
                categoriaNome: categoriaSelecionada!.nome)
            : f,
        selecionouCategoria: categoriaSelecionada != null));
  }
}

// -----------------------------------------------------
// COMPONENTES AUXILIARES
// -----------------------------------------------------

class _IACardFornecedorCompacto extends StatelessWidget {
  final FornecedorRecomendacaoModel recomendacao;
  final Color primary;
  final VoidCallback onTap;

  const _IACardFornecedorCompacto({
    required this.recomendacao,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final score = recomendacao.score.clamp(0, 100).toStringAsFixed(0);
    final motivo = recomendacao.motivos.isNotEmpty
        ? recomendacao.motivos.first
        : 'Compatível com seu evento';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 218,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primary.withValues(alpha: 0.10)),
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 46,
                  height: 46,
                  child: CircularProgressIndicator(
                    value: recomendacao.score.clamp(0, 100) / 100,
                    strokeWidth: 4,
                    color: primary,
                    backgroundColor: primary.withValues(alpha: 0.12),
                  ),
                ),
                Text(
                  '$score%',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recomendacao.nomeFornecedor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: const Color(0xFF1F2937),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    motivo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 9.5,
                      height: 1.15,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NeedChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color primary;
  final Color? iconColor;
  final VoidCallback onTap;

  const _NeedChip(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.primary,
      this.iconColor,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // Menor
        decoration: BoxDecoration(
          color: selected ? primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? primary : Colors.grey.shade200),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: primary.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected ? Colors.white : iconColor ?? primary,
                size: 12),
            const SizedBox(width: 4),
            Text(label,
                style: GoogleFonts.poppins(
                    color: selected ? Colors.white : Colors.black87,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const _SectionHeader(
      {required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937))),
        ],
      ),
    );
  }
}

class _FornecedorPremiumCard extends StatelessWidget {
  final FornecedorDetalhadoDto fornecedorDetalhado;
  final double media;
  final Color primary;
  final CategoriaServicoModel? categoriaSelecionada;
  final VoidCallback onTap;

  const _FornecedorPremiumCard(
      {required this.fornecedorDetalhado,
      required this.media,
      required this.primary,
      this.categoriaSelecionada,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final f = fornecedorDetalhado.fornecedor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 85, // Imagem mantida mais fina
              width: double.infinity,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CachedNetworkImage(
                        imageUrl: f.bannerUrl ?? '',
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                            color: Colors.grey.shade100,
                            child: const Icon(Icons.store, color: Colors.grey)),
                      ),
                    ),
                    Positioned.fill(
                        child: Container(
                            color: Colors.black.withValues(alpha: 0.25))),
                    Positioned(
                        top: 6, right: 6, child: _RatingBadge(media: media)),
                    Positioned(
                      bottom: 6,
                      left: 8,
                      right: 8,
                      child: Text(
                        f.razaoSocial,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 🔥 SOLUÇÃO AQUI: O Expanded garante que o texto não "vaze" o limite do Card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoriaSelecionada?.nome ??
                          fornecedorDetalhado.categoriaNome,
                      style: GoogleFonts.poppins(
                          color: primary,
                          fontSize: 9,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),

                    // O Flexible ajuda a cortar a descrição suavemente se a altura estiver muito apertada
                    Flexible(
                      child: Text(
                        f.descricao ?? 'Fornecedor parceiro.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                            height: 1.2),
                      ),
                    ),

                    const Spacer(), // Empurra a distância para a parte inferior do card

                    if (fornecedorDetalhado.distanciaKm != null)
                      Row(
                        children: [
                          Icon(Icons.place,
                              size: 10, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(
                            '${fornecedorDetalhado.distanciaKm!.toStringAsFixed(1)} km',
                            style: GoogleFonts.poppins(
                                fontSize: 9,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FornecedorListCard extends StatelessWidget {
  final FornecedorDetalhadoDto fornecedorDetalhado;
  final double media;
  final Color primary;
  final CategoriaServicoModel? categoriaSelecionada;
  final VoidCallback onTap;

  const _FornecedorListCard(
      {required this.fornecedorDetalhado,
      required this.media,
      required this.primary,
      this.categoriaSelecionada,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final f = fornecedorDetalhado.fornecedor;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: f.bannerUrl ?? '',
                width: 54, // Mais compacto (era 70)
                height: 54,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                    width: 54,
                    height: 54,
                    color: Colors.grey.shade100,
                    child:
                        const Icon(Icons.store, size: 20, color: Colors.grey)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    f.razaoSocial,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937)),
                  ),
                  Text(
                    categoriaSelecionada?.nome ??
                        fornecedorDetalhado.categoriaNome,
                    style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: primary,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  if (fornecedorDetalhado.distanciaKm != null)
                    Row(
                      children: [
                        Icon(Icons.place,
                            size: 10, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          '${fornecedorDetalhado.distanciaKm!.toStringAsFixed(1)} km',
                          style: GoogleFonts.poppins(
                              fontSize: 9, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            _RatingBadge(media: media, dark: false),
          ],
        ),
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final double media;
  final bool dark;
  const _RatingBadge({required this.media, this.dark = true});

  @override
  Widget build(BuildContext context) {
    final h = media > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: dark ? Colors.black54 : Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(h ? Icons.star_rounded : Icons.fiber_new,
              size: 10,
              color: h ? Colors.amber.shade400 : Colors.amber.shade700),
          const SizedBox(width: 2),
          Text(
            h ? media.toStringAsFixed(1) : 'Novo',
            style: GoogleFonts.poppins(
                color: dark ? Colors.white : Colors.amber.shade900,
                fontSize: 9,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _GlassBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _GlassBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: Colors.white),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _CategoriasHeaderDelegateBuilder extends SliverPersistentHeaderDelegate {
  static const double extent = 48;

  final Widget child;

  _CategoriasHeaderDelegateBuilder({required this.child});

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _CategoriasHeaderDelegateBuilder oldDelegate) {
    return oldDelegate.child != child;
  }
}
