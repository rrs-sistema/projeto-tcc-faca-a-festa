import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import './../../../../domain/entities/gift/gift.dart';

class GiftCard extends StatelessWidget {
  final Gift gift;
  final VoidCallback? onAcao;

  const GiftCard({
    super.key,
    required this.gift,
    this.onAcao,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    // Variáveis de controle baseadas no seu novo Modelo
    final isDisponivel = gift.status == GiftStatus.disponivel;
    final isColetivo = gift.tipo == GiftType.coletivo;
    final isFisico = gift.tipo == GiftType.fisico;
    final isPix = gift.tipo == GiftType.pix;

    // Textos dinâmicos baseados no tipo do presente
    String labelBotao = "Reservar";
    if (!isDisponivel) {
      labelBotao =
          gift.status == GiftStatus.reservado ? "Reservado" : "Finalizado";
    } else if (isColetivo) {
      labelBotao = "Contribuir";
    } else if (isPix) {
      labelBotao = "Presentear";
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==============================================
          // 1. ÁREA DA IMAGEM E BADGES
          // ==============================================
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child:
                        (gift.imagem != null && gift.imagem!.trim().isNotEmpty)
                            ? CachedNetworkImage(
                                imageUrl: gift.imagem!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorWidget: (_, __, ___) =>
                                    _buildPlaceholder(primary),
                              )
                            : _buildPlaceholder(primary),
                  ),

                  // Película escura se não estiver disponível
                  if (!isDisponivel)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                        ),
                      ),
                    ),

                  // Badge de Status (Se reservado/comprado)
                  if (!isDisponivel)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade700,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4)
                          ],
                        ),
                        child: Text(
                          gift.status == GiftStatus.reservado
                              ? 'Reservado'
                              : 'Arrecadado',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),

                  // Badge do Tipo (Canto inferior esquerdo da imagem)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isColetivo
                                ? Icons.groups_rounded
                                : (isPix
                                    ? Icons.pix_rounded
                                    : Icons.inventory_2_rounded),
                            color: Colors.white,
                            size: 10,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            gift.tipo.name.toUpperCase(),
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ==============================================
          // 2. INFORMAÇÕES DO PRESENTE
          // ==============================================
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // NOME DO PRESENTE
                Text(
                  gift.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
                ),

                const SizedBox(height: 6),

                // EXIBIÇÃO DE VALORES (Dinâmico pelo Tipo)
                if (isColetivo) ...[
                  // Presente Coletivo (Vaquinha)
                  _buildProgressoVaquinha(primary),
                ] else if (isFisico) ...[
                  // Presente Físico (Pode ter nome da loja)
                  if (gift.loja != null && gift.loja!.isNotEmpty)
                    Text(
                      gift.loja!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500),
                    ),
                  _buildPrecoFixo(primary),
                ] else ...[
                  // PIX (Mostra só o valor fixo)
                  _buildPrecoFixo(primary),
                ],

                const SizedBox(height: 12),

                // ==============================================
                // 3. BOTÃO DE AÇÃO
                // ==============================================
                SizedBox(
                  width: double.infinity,
                  height: 34,
                  child: ElevatedButton(
                    onPressed: isDisponivel ? onAcao : null,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor:
                          isDisponivel ? primary : Colors.grey.shade200,
                      foregroundColor:
                          isDisponivel ? Colors.white : Colors.grey.shade500,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      labelBotao,
                      style: GoogleFonts.poppins(
                          fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Widget quando não tem imagem
  Widget _buildPlaceholder(Color primary) {
    return Center(
      child: Icon(Icons.redeem_rounded,
          color: primary.withValues(alpha: 0.3), size: 40),
    );
  }

  // Helper: Preço Fixo (Físico ou PIX)
  Widget _buildPrecoFixo(Color primary) {
    if (gift.valor != null && gift.valor! > 0) {
      return Text(
        "R\$ ${gift.valor!.toStringAsFixed(2).replaceAll('.', ',')}",
        style: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w800, color: primary),
      );
    }
    return Text(
      "Valor livre",
      style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.green.shade600),
    );
  }

  // Helper: Progresso (Coletivo)
  Widget _buildProgressoVaquinha(Color primary) {
    final meta =
        (gift.metaValor != null && gift.metaValor! > 0) ? gift.metaValor! : 1.0;
    final arrecadado = gift.valorArrecadado;
    final percent = (arrecadado / meta).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "R\$ ${arrecadado.toStringAsFixed(0)}",
              style: GoogleFonts.poppins(
                  fontSize: 11, fontWeight: FontWeight.w700, color: primary),
            ),
            Text(
              "Meta: R\$ ${gift.metaValor?.toStringAsFixed(0) ?? '0'}",
              style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 5,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(primary),
          ),
        ),
      ],
    );
  }
}
