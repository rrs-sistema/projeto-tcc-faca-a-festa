import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/presentation/modules/avaliacao/controllers/avaliacao_servico_controller.dart';
import './../../../../data/models/DTO/fornecedor_servico_detalhado_dto.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import './../components/abrir_nova_cotacao_bottom_sheet.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import './../../../widgets/confetti_background.dart';

class ServicoDetalheScreen extends StatefulWidget {
  final FornecedorServicoDetalhadoDto servico;
  const ServicoDetalheScreen({super.key, required this.servico});

  @override
  State<ServicoDetalheScreen> createState() => _ServicoDetalheScreenState();
}

class _ServicoDetalheScreenState extends State<ServicoDetalheScreen> {
  bool favorito = false;

  @override
  void initState() {
    super.initState();
    final avaliacaoController = Get.find<AvaliacaoServicoController>();
    avaliacaoController.carregarAvaliacoesServico(
      idFornecedor: widget.servico.idFornecedor,
      idServico: widget.servico.idProdutoServico,
    );
  }

  @override
  Widget build(BuildContext context) {
    final avaliacaoController = Get.find<AvaliacaoServicoController>();
    final themeController = Get.find<EventThemeController>();
    final appController = Get.find<AppController>();
    final primary = themeController.primaryColor.value;
    final servico = widget.servico;

    // Ajuste da barra de status para combinar com imagens escuras no topo
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 18),
            onPressed: () => Get.back(),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                favorito
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: favorito ? Colors.pinkAccent : Colors.white,
                size: 20,
              ),
              onPressed: () {
                setState(() => favorito = !favorito);
                if (favorito) {
                  HapticFeedback.mediumImpact();
                  Get.snackbar(
                    'Favoritado',
                    'Adicionado aos favoritos 💖',
                    backgroundColor: primary,
                    colorText: Colors.white,
                    snackPosition: SnackPosition.BOTTOM,
                    margin: const EdgeInsets.all(12),
                    duration: const Duration(seconds: 2),
                  );
                }
              },
            ),
          ),
        ],
      ),

      // 🔹 Barra Fixa Inferior (Substitui o FAB flutuante e economiza espaço na tela)
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).padding.bottom > 0
                ? MediaQuery.of(context).padding.bottom
                : 12),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4))
        ]),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.request_quote_rounded,
              color: Colors.white, size: 18),
          label: Text(
            'Solicitar Cotação',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          onPressed: () async {
            HapticFeedback.mediumImpact();
            await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => CotacaoNovaBottomSheet(
                tipoEventoNome: 'Cotação de ${servico.nomeServico}',
                fornecedoresSelecionados: [servico.idFornecedor],
                servicosSelecionados: [servico],
                primary: primary,
                onCotacaoFinalizada: () =>
                    appController.limparServicosSelecionados(),
              ),
            );
          },
        ),
      ),

      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 🎬 HEADER CINEMATOGRÁFICO MAIS COMPACTO
          SliverToBoxAdapter(
            child: Stack(
              alignment: Alignment.bottomLeft,
              children: [
                SizedBox(
                  height:
                      260, // 🔹 Altura reduzida para melhor visualização inicial
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: servico.imagemUrl?.isNotEmpty == true
                        ? servico.imagemUrl!
                        : 'https://firebasestorage.googleapis.com/v0/b/faca-a-festa.firebasestorage.app/o/static%2Fsem-foto.jpg?alt=media',
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(child: ConfettiBackground(seconds: 45)),
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.transparent
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (servico.nomeSubcategoria?.isNotEmpty ?? false)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            servico.nomeSubcategoria!,
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                        ),
                      Text(
                        servico.nomeServico ?? 'Serviço sem nome',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.storefront_rounded,
                              color: Colors.white70, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              servico.nomeFornecedor ??
                                  'Fornecedor não informado',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
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

          // 🌟 CONTEÚDO DETALHADO COMPACTO E LIMPO
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 Preço Otimizado
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.black.withValues(alpha: 0.04)),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 4))
                        ]),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle),
                          child: Icon(Icons.sell_rounded,
                              color: primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Valor estimado',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w600)),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    servico.precoPromocao != null &&
                                            servico.precoPromocao! > 0
                                        ? "R\$ ${servico.precoPromocao!.toStringAsFixed(2)}"
                                        : "R\$ ${servico.preco.toStringAsFixed(2)}",
                                    style: GoogleFonts.poppins(
                                        color: const Color(0xFF1F2937),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18),
                                  ),
                                  if (servico.precoPromocao != null &&
                                      servico.precoPromocao! > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 8, bottom: 2),
                                      child: Text(
                                        "R\$ ${servico.preco.toStringAsFixed(2)}",
                                        style: GoogleFonts.poppins(
                                            color: Colors.red.shade400,
                                            fontSize: 12,
                                            decoration:
                                                TextDecoration.lineThrough,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.05, end: 0),

                  const SizedBox(height: 20),

                  // 🔹 Descrição
                  _sectionTitle(
                      'Descrição', Icons.description_rounded, primary),
                  const SizedBox(height: 8),
                  Text(
                    servico.descricaoServico?.isNotEmpty == true
                        ? servico.descricaoServico!
                        : 'Sem descrição detalhada disponível para este serviço no momento.',
                    style: GoogleFonts.poppins(
                        fontSize: 13, height: 1.5, color: Colors.grey.shade700),
                  ),

                  const SizedBox(height: 20),
                  Divider(color: Colors.grey.shade200),
                  const SizedBox(height: 16),

                  // 🔹 Avaliações
                  _sectionTitle(
                      'Avaliações', Icons.star_rounded, Colors.amber.shade600),
                  const SizedBox(height: 8),
                  Obx(() {
                    final media = avaliacaoController.mediaServico.value;
                    final qtd = avaliacaoController.avaliacoesServico.length;
                    return Row(
                      children: [
                        ...buildStarRating(media, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          qtd > 0
                              ? "${media.toStringAsFixed(1)} • $qtd avaliações"
                              : "Ainda sem avaliações",
                          style: GoogleFonts.poppins(
                              color: Colors.grey.shade800,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    );
                  }),

                  const SizedBox(height: 20),
                  Divider(color: Colors.grey.shade200),
                  const SizedBox(height: 16),

                  // 🔹 Diferenciais
                  _sectionTitle(
                      'Diferenciais', Icons.workspace_premium_rounded, primary),
                  const SizedBox(height: 8),
                  Text(
                    'Equipe criativa e dedicada, excelente reputação em eventos anteriores e atendimento personalizado. Torne sua celebração inesquecível com este fornecedor! 🎉',
                    style: GoogleFonts.poppins(
                        fontSize: 13, height: 1.5, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> buildStarRating(double nota, {double size = 20}) {
    return List.generate(5, (i) {
      final index = i + 1;
      if (nota >= index) {
        return Icon(Icons.star_rounded, color: Colors.amber, size: size);
      }
      if (nota > index - 1) {
        return Icon(Icons.star_half_rounded, color: Colors.amber, size: size);
      }
      return Icon(Icons.star_border_rounded,
          color: Colors.grey.shade300, size: size);
    });
  }

  Widget _sectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1F2937)),
        ),
      ],
    );
  }
}
