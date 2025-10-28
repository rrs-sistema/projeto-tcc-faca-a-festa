import 'package:app_faca_festa/data/models/DTO/fornecedor_servico_detalhado_dto.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../controllers/evento_controller.dart';
import '../../../../../controllers/fornecedor_localizacao_controller.dart';
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
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          imagensCarousel(),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(servico.nome,
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(servico.descricao ?? 'Sem descrição disponível.',
                    style: GoogleFonts.poppins(
                        fontSize: 13.5, color: Colors.black87.withValues(alpha: 0.7), height: 1.5)),
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
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          color: Colors.grey.shade200,
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported_outlined, size: 60, color: Colors.grey),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              );
            },
            options: CarouselOptions(
              height: 200,
              autoPlay: urls!.length > 1,
              viewportFraction: 1.0,
              enableInfiniteScroll: urls!.length > 1,
              autoPlayInterval: const Duration(seconds: 4),
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
            ),
          ),

          // 🔹 Gradiente sutil sobre as imagens
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withValues(alpha: 0.25), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),

          // 🔹 Indicadores de posição (bolinhas)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                urls!.length,
                (i) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _botaoOrcamento(String label) => ElevatedButton.icon(
      icon: const Icon(Icons.request_quote_rounded, color: Colors.white, size: 18),
      label: Text(label,
          style:
              GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        backgroundColor: primary,
        shadowColor: primary.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () {
        final fornecedorLocalizacaoController = Get.find<FornecedorLocalizacaoController>();
        final eventoController = Get.find<EventoController>();
        final appController = Get.find<AppController>();
        final servicoCotado = ServicoCotadoDto(idProduto: servico.id, nomeProduto: servico.nome);

        if (appController.isServicoSelecionado(servico.id)) {
          appController.removerServico(servico.id);
          Get.snackbar('Removido', 'Serviço removido da lista de cotação.',
              backgroundColor: Colors.orange, colorText: Colors.white);
        } else {
          final servico = fornecedorLocalizacaoController.servicosFornecedor
              .where((s) => s.idFornecedor == fornecedorId)
              .first;

          appController.adicionarServico(servicoCotado);
          Get.bottomSheet(
            CotacaoNovaBottomSheet(
              tipoEventoNome: eventoController.tipoEventoAtual.value?.nome ?? '',
              fornecedoresSelecionados: [fornecedorId],
              servicosSelecionados: [
                FornecedorServicoDetalhadoDto(
                    idFornecedorServico: fornecedorId,
                    idFornecedor: fornecedorId,
                    idProdutoServico: servico.idProdutoServico,
                    preco: servico.preco,
                    nomeServico: servico.nomeServico,
                    descricaoServico: servico.descricaoServico,
                    idSubcategoria: servico.idSubcategoria,
                    imagemUrl: servico.imagemUrl,
                    nomeCategoria: servico.nomeCategoria,
                    nomeSubcategoria: servico.nomeSubcategoria,
                    precoPromocao: servico.precoPromocao)
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
      });
}
