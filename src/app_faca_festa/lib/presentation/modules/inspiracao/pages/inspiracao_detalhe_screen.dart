import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/avaliacao/controllers/avaliacao_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_localizacao_controller.dart';
import 'package:app_faca_festa/presentation/modules/inspiracao/controllers/inspiracao_controller.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/home_event_nav_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/domain/entities/fornecedor.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_detalhado.dart';
import 'package:app_faca_festa/domain/entities/inspiracao.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_cotacoes.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/pages/fornecedor_detalhe_screen.dart';

class InspiracaoDetalheScreen extends StatelessWidget {
  final Inspiracao inspiracao;
  final EventThemeController themeController;
  final InspiracaoController inspiracaoController;
  final HomeEventNavController homeEventNavController;
  final FornecedorController fornecedorController;
  final FornecedorLocalizacaoController fornecedorLocalizacaoController;
  final AvaliacaoServicoController avaliacaoController;
  final EventoController eventoController;
  final AppController appController;
  final GerenciarCotacoes cotacoes;

  const InspiracaoDetalheScreen({
    super.key,
    required this.inspiracao,
    required this.themeController,
    required this.inspiracaoController,
    required this.homeEventNavController,
    required this.fornecedorController,
    required this.fornecedorLocalizacaoController,
    required this.avaliacaoController,
    required this.eventoController,
    required this.appController,
    required this.cotacoes,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => _abrirGaleriaFotos(
              urls: [
                inspiracao.imagemUrl,
                ...inspiracao.galeriaUrls,
              ],
              indiceInicial: 0,
              titulo: inspiracao.titulo,
            ),
            child: Hero(
              tag: 'insp_${inspiracao.id}',
              child: _buildHeroImage(inspiracao.imagemUrl),
            ),
          ),
          Container(
            height: 400, // 🔹 Imagem de fundo ligeiramente menor[cite: 31]
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xCC000000),
                  Color(0x66000000),
                  Colors.transparent
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            top: 0,
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  _botaoFotoAcao(
                    tooltip: 'Fechar',
                    icon: Icons.close_rounded,
                    onPressed: () => Get.back(),
                  ),
                  const Spacer(),
                  Obx(() {
                    final atual = _resolverInspiracaoAtual(
                        inspiracaoController, inspiracao);
                    return _botaoFotoAcao(
                      tooltip: atual.favorito ? 'Favorita' : 'Marcar favorita',
                      icon: atual.favorito
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      iconColor:
                          atual.favorito ? Colors.amber : Colors.white,
                      onPressed: () =>
                          inspiracaoController.alternarFavorito(atual.id),
                    );
                  }),
                ],
              ),
            ),
          ),
          _FolhaDetalheInspiracao(
            host: this,
            onFechar: () => Get.back(),
            onAbrirFotos: (urls, indice) => _abrirGaleriaFotos(
              urls: urls,
              indiceInicial: indice,
              titulo: inspiracao.titulo,
            ),
          ),
        ],
      ),
    );
  }

  Widget _botaoFotoAcao({
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
    Color iconColor = Colors.white,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.42),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon, color: iconColor, size: 22),
        onPressed: onPressed,
      ),
    );
  }

  void _abrirGaleriaFotos({
    required List<String> urls,
    required int indiceInicial,
    required String titulo,
  }) {
    final limpas = urls.where((u) => u.trim().isNotEmpty).toList();
    if (limpas.isEmpty) return;
    Get.to(
      () => _GaleriaInspiracaoPage(
        urls: limpas,
        indiceInicial: indiceInicial.clamp(0, limpas.length - 1),
        titulo: titulo,
      ),
    );
  }

  Widget _buildAcoesPlanejamento({
    required InspiracaoController controller,
    required HomeEventNavController homeEventNavController,
    required Inspiracao inspiracao,
    required Color primary,
  }) {
    return Obx(() {
      final salva = controller.inspiracaoJaSalva(inspiracao.id);
      final checklist = controller.checklistJaCriado(inspiracao.id);
      final orcamento = controller.orcamentoJaCriado(inspiracao.id);

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primary.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: primary, size: 20),
                const SizedBox(width: 8),
                Text('Planejamento do evento',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1F2937))),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: salva
                    ? null
                    : () => controller.salvarInspiracaoNoEvento(inspiracao),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  elevation: 0,
                ),
                icon: Icon(
                    salva
                        ? Icons.bookmark_added_rounded
                        : Icons.bookmark_add_rounded,
                    size: 18,
                    color: salva ? Colors.grey.shade600 : Colors.white),
                label: Text(
                    salva ? 'Guardada no evento' : 'Guardar no evento',
                    style: GoogleFonts.poppins(
                        color: salva ? Colors.grey.shade600 : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: checklist
                        ? null
                        : () =>
                            controller.gerarChecklistDaInspiracao(inspiracao),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primary,
                      side: BorderSide(
                          color: checklist
                              ? Colors.grey.shade300
                              : primary.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: Icon(
                        checklist
                            ? Icons.check_circle_rounded
                            : Icons.checklist_rounded,
                        size: 16),
                    label: Text(checklist ? 'Checklist OK' : 'Checklist',
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: orcamento
                        ? null
                        : () =>
                            controller.gerarOrcamentoDaInspiracao(inspiracao),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primary,
                      side: BorderSide(
                          color: orcamento
                              ? Colors.grey.shade300
                              : primary.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: Icon(
                        orcamento
                            ? Icons.check_circle_rounded
                            : Icons.account_balance_wallet_rounded,
                        size: 16),
                    label: Text(orcamento ? 'Orçamento OK' : 'Orçamento',
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),

            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton.icon(
                  onPressed: homeEventNavController.irParaFornecedores,
                  icon:
                      Icon(Icons.storefront_rounded, size: 16, color: primary),
                  label: Text('Fornecedores',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: primary,
                          fontWeight: FontWeight.w700)),
                ),
                TextButton.icon(
                  onPressed: () => controller.adicionarReferenciaPessoal(),
                  icon: Icon(Icons.add_photo_alternate_rounded,
                      size: 16, color: Colors.grey.shade700),
                  label: Text('Sua Galeria',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _fornecedoresRelacionados(
    InspiracaoController controller,
    Inspiracao inspiracao,
    Color primary,
  ) {
    final fornecedores = controller.fornecedoresDaInspiracao(inspiracao);
    if (fornecedores.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Fornecedores desta ideia'),
        const SizedBox(height: 10),
        SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: fornecedores.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, index) {
              final fornecedor = fornecedores[index];
              final url = (fornecedor.bannerUrl ?? '').trim();
              return GestureDetector(
                onTap: () => Get.to(
                  () => FornecedorDetalheScreen(
                    selecionouCategoria: false,
                    fornecedorDetalhado: FornecedorDetalhado(
                      fornecedor: fornecedor,
                      categoriaId: _categoriaId(fornecedor),
                      categoriaNome: _categoriaNome(fornecedor),
                    ),
                    themeController: themeController,
                    fornecedorController: fornecedorController,
                    fornecedorLocalizacaoController:
                        fornecedorLocalizacaoController,
                    avaliacaoController: avaliacaoController,
                    eventoController: eventoController,
                    appController: appController,
                    cotacoes: cotacoes,
                  ),
                ),
                child: SizedBox(
                  width: 118,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          height: 78,
                          width: 118,
                          child: url.isEmpty
                              ? Container(
                                  color: primary.withValues(alpha: 0.08),
                                  child: Icon(Icons.storefront_rounded,
                                      color: primary, size: 26),
                                )
                              : Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.storefront_rounded,
                                        color: Colors.grey),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        fornecedor.razaoSocial,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  String _categoriaId(Fornecedor fornecedor) {
    if (fornecedor.categorias.isEmpty) return '';
    return fornecedor.categorias.first.idCategoria;
  }

  String _categoriaNome(Fornecedor fornecedor) {
    if (fornecedor.categorias.isEmpty) return '';
    return fornecedor.categorias.first.nomeCategoria;
  }

  Widget _descriptionCard(String descricao) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200)),
      child: Text(
        descricao.isEmpty ? 'Nenhuma descrição informada.' : descricao,
        style: GoogleFonts.poppins(
            fontSize: 12.5, height: 1.4, color: Colors.grey.shade700),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1F2937)));
  }

  Widget _infoChip(
      {required IconData icon, required String label, required Color primary}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: primary.withValues(alpha: 0.15))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: primary),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildHeroImage(String? url) {
    if (url == null || url.trim().isEmpty) {
      return Container(
          width: double.infinity,
          height: 400,
          color: Colors.grey.shade200,
          child: const Icon(Icons.image_not_supported_rounded,
              color: Colors.white, size: 40));
    }
    return Image.network(url,
        width: double.infinity,
        height: 400,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
            width: double.infinity,
            height: 400,
            color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image_rounded,
                color: Colors.white, size: 40)));
  }

  Widget _galleryImage(String url) {
    if (url.trim().isEmpty) {
      return Container(
          width: 120,
          color: Colors.grey.shade200,
          child: const Icon(Icons.image_not_supported_rounded));
    }
    return Image.network(url,
        width: 120,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
            width: 120,
            color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image_rounded)));
  }

  Inspiracao _resolverInspiracaoAtual(
      InspiracaoController controller, Inspiracao fallback) {
    for (final item in controller.todasInspiracoes) {
      if (item.id == fallback.id) return item;
    }
    return fallback;
  }

  Color _parseColor(String value) {
    var text = value.trim();
    if (text.isEmpty) return Colors.grey.shade300;
    if (text.startsWith('#')) {
      text = text.replaceFirst('#', '');
      if (text.length == 6) text = 'FF$text';
    } else if (text.startsWith('0x')) {
      text = text.substring(2);
    }
    final parsed = int.tryParse(text, radix: 16);
    return parsed == null ? Colors.grey.shade300 : Color(parsed);
  }
}

class _FolhaDetalheInspiracao extends StatefulWidget {
  const _FolhaDetalheInspiracao({
    required this.host,
    required this.onFechar,
    required this.onAbrirFotos,
  });

  final InspiracaoDetalheScreen host;
  final VoidCallback onFechar;
  final void Function(List<String> urls, int indice) onAbrirFotos;

  @override
  State<_FolhaDetalheInspiracao> createState() => _FolhaDetalheInspiracaoState();
}

class _FolhaDetalheInspiracaoState extends State<_FolhaDetalheInspiracao> {
  bool _fechando = false;

  InspiracaoDetalheScreen get host => widget.host;

  void _fechar() {
    if (_fechando) return;
    _fechando = true;
    widget.onFechar();
  }

  List<String> _fotos(Inspiracao atual) {
    final urls = <String>[];
    void add(String value) {
      final url = value.trim();
      if (url.isEmpty || urls.contains(url)) return;
      urls.add(url);
    }

    add(atual.imagemUrl);
    for (final item in atual.galeriaUrls) {
      add(item);
    }
    return urls;
  }

  @override
  Widget build(BuildContext context) {
    final primary = host.themeController.primaryColor.value;

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        if (notification.extent <= 0.20) {
          _fechar();
        }
        return false;
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.58,
        minChildSize: 0.16,
        maxChildSize: 0.95,
        snap: true,
        snapSizes: const [0.16, 0.58, 0.95],
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -4))
              ],
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              physics: const BouncingScrollPhysics(),
              child: Obx(() {
                final atual = host._resolverInspiracaoAtual(
                    host.inspiracaoController, host.inspiracao);
                host.inspiracaoController.fornecedoresRelacionados.length;
                final categoria = (atual.categoria ?? '').trim();
                final estilo = atual.estilo.trim();
                final estiloDuplicado = estilo.isNotEmpty &&
                    estilo.toLowerCase() == categoria.toLowerCase();
                final fotos = _fotos(atual);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            atual.titulo,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                              color: const Color(0xFF111827),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Fechar',
                          onPressed: _fechar,
                          color: const Color(0xFF1F2937),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () => host.inspiracaoController
                          .alternarFavorito(atual.id),
                      style: TextButton.styleFrom(
                        foregroundColor: atual.favorito
                            ? Colors.amber.shade800
                            : const Color(0xFF4B5563),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: Icon(
                        atual.favorito
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 18,
                      ),
                      label: Text(
                        atual.favorito ? 'Favorita' : 'Marcar favorita',
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (categoria.isNotEmpty)
                          host._infoChip(
                              icon: Icons.category_rounded,
                              label: categoria,
                              primary: primary),
                        if (estilo.isNotEmpty && !estiloDuplicado)
                          host._infoChip(
                              icon: Icons.palette_rounded,
                              label: estilo,
                              primary: primary),
                        if (atual.faixaCusto.isNotEmpty)
                          host._infoChip(
                              icon: Icons.payments_rounded,
                              label: atual.faixaCusto,
                              primary: primary),
                      ],
                    ),
                    const SizedBox(height: 14),
                    host._descriptionCard(atual.descricao),
                    const SizedBox(height: 16),
                    if (atual.tags.isNotEmpty) ...[
                      host._sectionTitle('Tags'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: atual.tags
                            .map((tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.grey.shade300)),
                                child: Text(tag,
                                    style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w600))))
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (atual.galeriaUrls.isNotEmpty) ...[
                      host._sectionTitle('Mais fotos'),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: atual.galeriaUrls.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (_, i) {
                            final url = atual.galeriaUrls[i];
                            final indice = fotos.indexOf(url.trim());
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => widget.onAbrirFotos(
                                  fotos,
                                  indice < 0 ? i + 1 : indice,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: host._galleryImage(url),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (atual.paletaCores.isNotEmpty) ...[
                      host._sectionTitle('Paleta de cores'),
                      const SizedBox(height: 10),
                      Row(
                        children: atual.paletaCores
                            .map((cor) => Expanded(
                                child: Container(
                                    height: 32,
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                        color: host._parseColor(cor),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.black
                                                .withValues(alpha: 0.05))))))
                            .toList(),
                      ),
                      const SizedBox(height: 20),
                    ],
                    host._fornecedoresRelacionados(
                        host.inspiracaoController, atual, primary),
                    host._buildAcoesPlanejamento(
                        controller: host.inspiracaoController,
                        homeEventNavController: host.homeEventNavController,
                        inspiracao: atual,
                        primary: primary),
                    const SizedBox(height: 30),
                  ],
                );
              }),
            ),
          );
        },
      ),
    );
  }
}

class _GaleriaInspiracaoPage extends StatefulWidget {
  const _GaleriaInspiracaoPage({
    required this.urls,
    required this.indiceInicial,
    required this.titulo,
  });

  final List<String> urls;
  final int indiceInicial;
  final String titulo;

  @override
  State<_GaleriaInspiracaoPage> createState() => _GaleriaInspiracaoPageState();
}

class _GaleriaInspiracaoPageState extends State<_GaleriaInspiracaoPage> {
  late final PageController _pageController;
  late int _indice;

  @override
  void initState() {
    super.initState();
    _indice = widget.indiceInicial;
    _pageController = PageController(initialPage: _indice);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.urls.length > 1
              ? '${widget.titulo}  ${_indice + 1}/${widget.urls.length}'
              : widget.titulo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.urls.length,
        onPageChanged: (value) => setState(() => _indice = value),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: Image.network(
                widget.urls[index],
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image_rounded,
                  color: Colors.white54,
                  size: 48,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
