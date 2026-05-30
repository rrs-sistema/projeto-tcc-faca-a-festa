// ignore_for_file: use_build_context_synchronously
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../controllers/tema/event_theme_controller.dart';
import './../../../controllers/gift/gift_controller.dart';
import './../../../domain/entities/gift/gift.dart';
import './cadastrar_presente_page.dart';

class GerenciarPresentesPage extends GetView<GiftController> {
  final String eventoId;
  const GerenciarPresentesPage({super.key, required this.eventoId});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<EventThemeController>();
    final primary = themeController.primaryColor.value;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("Lista de Presentes",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800, fontSize: 16, color: const Color(0xFF1F2937))),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1F2937), size: 18),
          onPressed: () => Get.back(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        label: Text("Novo Presente",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 12)),
        icon: const Icon(Icons.add_rounded, size: 18),
        onPressed: () => abrirDialogCadastrarPresente(context),
      ),
      body: Obx(() {
        if (controller.gifts.isEmpty) return _buildEmptyState(primary);

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: controller.gifts.length,
          physics: const BouncingScrollPhysics(),
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final gift = controller.gifts[index];
            return _GiftTile(
              gift: gift,
              primary: primary,
              onEdit: () => abrirDialogCadastrarPresente(context, presente: gift.toModel()),
              onDelete: () => _confirmarExclusao(context, gift),
            );
          },
        );
      }),
    );
  }

  Widget _buildEmptyState(Color primary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration:
                BoxDecoration(color: primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.redeem_rounded, size: 40, color: primary),
          ),
          const SizedBox(height: 16),
          Text("Sua lista está vazia",
              style: GoogleFonts.poppins(
                  color: const Color(0xFF1F2937), fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text("Toque no botão abaixo para começar.",
              style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 12)),
        ],
      ),
    );
  }

  void _confirmarExclusao(BuildContext context, Gift gift) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Remover Presente",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
        content: Text("Deseja realmente remover '${gift.nome}'?",
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700)),
        actions: [
          TextButton(
              onPressed: () => Get.back(),
              child: Text("Cancelar", style: GoogleFonts.poppins(fontSize: 12))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              controller.excluirPresente(gift.id);
              Get.back();
            },
            child: Text("Excluir", style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _GiftTile extends StatelessWidget {
  final Gift gift;
  final Color primary;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GiftTile(
      {required this.gift, required this.primary, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isColetivo = gift.tipo == GiftType.coletivo;
    final isFisico = gift.tipo == GiftType.fisico;
    final temFoto = gift.imagem != null && gift.imagem!.trim().isNotEmpty;
    final reservado = gift.status == GiftStatus.reservado;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagem ou Ícone
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade100)),
            child: (isFisico && temFoto)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.network(gift.imagem!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Icon(Icons.image_not_supported, color: primary, size: 20)))
                : Icon(
                    isColetivo
                        ? Icons.groups_rounded
                        : (gift.tipo == GiftType.pix
                            ? Icons.pix_rounded
                            : Icons.inventory_2_rounded),
                    color: primary,
                    size: 20),
          ),
          const SizedBox(width: 12),

          // Info Central
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: Text(gift.nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: const Color(0xFF1F2937)))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: reservado
                              ? Colors.orange.withValues(alpha: 0.1)
                              : Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(reservado ? "Reservado" : "Disponível",
                          style: GoogleFonts.poppins(
                              color: reservado ? Colors.orange.shade800 : Colors.green.shade800,
                              fontSize: 9,
                              fontWeight: FontWeight.w700)),
                    )
                  ],
                ),
                Text(gift.tipo.name.capitalizeFirst!,
                    style: GoogleFonts.poppins(
                        color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),

                // Valores
                if (isColetivo) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          "R\$ ${gift.valorArrecadado.toStringAsFixed(2)} / R\$ ${gift.metaValor?.toStringAsFixed(2)}",
                          style: GoogleFonts.poppins(
                              fontSize: 10, fontWeight: FontWeight.w600, color: primary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (gift.metaValor ?? 0) > 0
                          ? (gift.valorArrecadado / gift.metaValor!).clamp(0.0, 1.0)
                          : 0,
                      backgroundColor: Colors.grey.shade200,
                      color: primary,
                      minHeight: 4,
                    ),
                  ),
                ] else if (!isFisico) ...[
                  Text("Valor Sugerido: R\$ ${gift.valor?.toStringAsFixed(2) ?? '0.00'}",
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 11, color: primary)),
                ],
              ],
            ),
          ),

          // Ações (Edição/Exclusão) super discretas
          Column(
            children: [
              IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  icon: const Icon(Icons.edit_rounded, size: 16, color: Colors.blueGrey),
                  onPressed: onEdit),
              IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                  onPressed: onDelete),
            ],
          )
        ],
      ),
    );
  }
}
