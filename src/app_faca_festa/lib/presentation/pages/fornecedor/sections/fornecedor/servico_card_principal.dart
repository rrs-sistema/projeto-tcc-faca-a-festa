import 'package:app_faca_festa/data/models/DTO/fornecedor_servico_detalhado_dto.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../controllers/evento_controller.dart';
import '../../../../../controllers/fornecedor/fornecedor_localizacao_controller.dart';
import '../../../../../data/models/DTO/servico_cotado_dto.dart';
import '../../components/abrir_nova_cotacao_bottom_sheet.dart';
import './../../../../../controllers/app_controller.dart';
import './../../../../../data/models/model.dart';

class ServicoCardPrincipal extends StatelessWidget {
  final ServicoProdutoModel servico;
  final List<String>? urls;
  final Color primary;
  final Gradient gradient;
  final String fornecedorId;
  final BuildContext context;

  const ServicoCardPrincipal({
    super.key,
    required this.servico,
    required this.urls,
    required this.primary,
    required this.gradient,
    required this.fornecedorId,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          imagensCarousel(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  servico.nome,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  servico.descricao ?? 'Sem descrição disponível.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                _botaoOrcamento('Solicitar orçamento'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget imagensCarousel() {
    if (urls == null || urls!.isEmpty) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          color: Colors.grey.shade50,
        ),
        alignment: Alignment.center,
        child: Icon(Icons.image_not_supported_outlined, size: 40, color: Colors.grey.shade300),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: Stack(
        children: [
          CarouselSlider.builder(
            itemCount: urls!.length,
            itemBuilder: (context, index, _) {
              final url = urls![index];
              return CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 400),
                httpHeaders: const {"Connection": "keep-alive"},
                errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                imageBuilder: (context, imageProvider) => Image(
                  image: imageProvider,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              );
            },
            options: CarouselOptions(
              height: 180,
              autoPlay: urls!.length > 1,
              viewportFraction: 1.0,
              enableInfiniteScroll: urls!.length > 1,
              autoPlayInterval: const Duration(seconds: 4),
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
            ),
          ),

          // Gradiente sutil inferior para destacar indicadores
          Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withValues(alpha: 0.3), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.center,
              ),
            ),
          ),

          // Indicadores de posição (bolinhas) compactos
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                urls!.length,
                (i) => Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _botaoOrcamento(String label) => SizedBox(
        width: double.infinity,
        height: 42,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            elevation: 0, // Design Flat
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            final fornecedorLocalizacaoController = Get.find<FornecedorLocalizacaoController>();
            final eventoController = Get.find<EventoController>();
            final appController = Get.find<AppController>();
            final servicoCotado =
                ServicoCotadoDto(idProduto: servico.id, nomeProduto: servico.nome);

            if (appController.isServicoSelecionado(servico.id)) {
              appController.removerServico(servico.id);
              Get.snackbar('Removido', 'Serviço removido da lista de cotação.',
                  backgroundColor: Colors.grey.shade900, colorText: Colors.white);
            } else {
              final servico = fornecedorLocalizacaoController.servicosFornecedor
                  .where((s) => s.idFornecedor == fornecedorId)
                  .first;

              appController.adicionarServico(servicoCotado);
              Get.bottomSheet(
                CotacaoNovaBottomSheet(
                  tipoEventoNome:
                      eventoController.tipoEventoAtualEntidade?.nome ?? '',
                  fornecedoresSelecionados: [fornecedorId],
                  servicosSelecionados: [
                    FornecedorServicoDetalhadoDto(
                        id: fornecedorId,
                        idFornecedor: fornecedorId,
                        idProdutoServico: servico.idProdutoServico,
                        preco: servico.preco,
                        nomeServico: servico.nomeServico,
                        descricaoServico: servico.descricaoServico,
                        idSubcategoria: servico.idSubcategoria,
                        imagemUrl: servico.imagemUrl,
                        nomeCategoria: servico.nomeCategoria,
                        nomeSubcategoria: servico.nomeSubcategoria,
                        precoPromocao: servico.precoPromocao,
                        ativo: servico.ativo,
                        quantidade: 1)
                  ],
                  primary: primary,
                  onCotacaoFinalizada: () {
                    appController.limparServicosSelecionados();
                  },
                ),
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
              );
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.request_quote_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
}
