import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../data/models/DTO/servico_cotado_dto.dart';
import './../../../../../controllers/app_controller.dart';
import './../../../../../data/models/model.dart';

class ServicoCardHorizontal extends StatelessWidget {
  final ServicoProdutoModel servico;
  final String? fotoUrl;
  final Color primary;
  final Gradient gradient;
  final String fornecedorId;
  final BuildContext context;

  const ServicoCardHorizontal({
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _imagem(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  servico.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  servico.descricao ?? 'Sem descrição',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                _botaoOrcar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagem() => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        child: CachedNetworkImage(
          imageUrl: fotoUrl ?? '',
          height: 90,
          width: double.infinity,
          fadeInDuration: const Duration(milliseconds: 400),
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            color: Colors.grey.shade50,
            alignment: Alignment.center,
            child: const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (_, __, ___) => Container(
            height: 90,
            color: Colors.grey.shade50,
            child: Icon(Icons.image_not_supported_outlined, size: 24, color: Colors.grey.shade300),
          ),
        ),
      );

  Widget _botaoOrcar() => SizedBox(
        width: double.infinity,
        height: 32,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            padding: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          onPressed: () {
            final appController = Get.find<AppController>();
            final servicoCotado =
                ServicoCotadoDto(idProduto: servico.id, nomeProduto: servico.nome);

            if (appController.isServicoSelecionado(servico.id)) {
              appController.removerServico(servico.id);
              Get.snackbar('Removido', 'Serviço removido da lista de cotação.',
                  backgroundColor: Colors.grey.shade900, colorText: Colors.white);
            } else {
              appController.adicionarServico(servicoCotado);
              Get.snackbar('Adicionado', 'Serviço adicionado à lista de cotação.',
                  backgroundColor: primary, colorText: Colors.white);
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_shopping_cart_rounded, size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                'Orçar',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
}
