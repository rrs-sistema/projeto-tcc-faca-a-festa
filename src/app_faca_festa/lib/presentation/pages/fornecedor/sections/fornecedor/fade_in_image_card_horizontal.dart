import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/no_sqflite_cache_manager.dart';
import '../../../../../data/models/DTO/servico_cotado_dto.dart';
import './../../../../../controllers/app_controller.dart';
import './../../../../../data/models/model.dart';

class FadeInImageCardHorizontal extends StatelessWidget {
  final ServicoProdutoModel servico;
  final String fotoUrl;
  final Color primary;
  final Gradient gradient;
  final String fornecedorId;
  final BuildContext context;

  const FadeInImageCardHorizontal({
    super.key,
    required this.servico,
    required this.fotoUrl,
    required this.primary,
    required this.gradient,
    required this.fornecedorId,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 175,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _imagem(),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(servico.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 11.5)),
                const SizedBox(height: 4),
                Text(servico.descricao ?? 'Sem descrição',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        color: Colors.black87.withValues(alpha: 0.65), fontSize: 12.5)),
                const SizedBox(height: 10),
                _botaoOrcar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagem() => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: CachedNetworkImage(
          imageUrl: fotoUrl,
          cacheManager: AdaptiveCacheManager.instance,
          fadeInDuration: const Duration(milliseconds: 350),
          height: 100,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            color: Colors.grey.shade200,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
          errorWidget: (_, __, ___) => Container(
            color: Colors.grey.shade300,
            alignment: Alignment.center,
            child: const Icon(Icons.image_not_supported_outlined, size: 40, color: Colors.grey),
          ),
        ),
      );

  Widget _botaoOrcar() => ElevatedButton.icon(
        icon: const Icon(Icons.request_quote_rounded, size: 16, color: Colors.white),
        label: Text('Orçar Serviço',
            style: GoogleFonts.poppins(
                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () {
          final appController = Get.find<AppController>();
          final servicoCotado = ServicoCotadoDto(idProduto: servico.id, nomeProduto: servico.nome);

          if (appController.isServicoSelecionado(servico.id)) {
            appController.removerServico(servico.id);
            Get.snackbar('Removido', 'Serviço removido da lista de cotação.',
                backgroundColor: Colors.orange, colorText: Colors.white);
          } else {
            appController.adicionarServico(servicoCotado);
            Get.snackbar('Adicionado', 'Serviço adicionado à lista de cotação.',
                backgroundColor: Colors.green, colorText: Colors.white);
          }
        },
      );
}
