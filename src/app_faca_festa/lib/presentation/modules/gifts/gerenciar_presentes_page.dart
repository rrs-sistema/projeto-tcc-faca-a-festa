// ignore_for_file: use_build_context_synchronously
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
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
    final gradient = themeController.gradient.value;
    final primary = themeController.primaryColor.value;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("Lista de Presentes",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.white,
        foregroundColor: primary,
        elevation: 4,
        label: Text("Novo Presente", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_shopping_cart),
        onPressed: () => abrirDialogCadastrarPresente(context),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          bottom: false,
          child: Obx(() {
            if (controller.gifts.isEmpty) return _buildEmptyState();

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: controller.gifts.length,
              physics: const BouncingScrollPhysics(),
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
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: FadeInUp(
        // Se tiver biblioteca de animação, senão use Column pura
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.redeem, size: 64, color: Colors.white54),
            ),
            const SizedBox(height: 24),
            Text("Sua lista está vazia",
                style: GoogleFonts.poppins(
                    color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Toque no botão abaixo para começar",
                style: TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  void _confirmarExclusao(BuildContext context, Gift gift) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Remover Presente", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("Deseja realmente remover '${gift.nome}'?"),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              controller.excluirPresente(gift.id);
              Get.back();
            },
            child: const Text("Excluir", style: TextStyle(color: Colors.white)),
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

  const _GiftTile({
    required this.gift,
    required this.primary,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isColetivo = gift.tipo == GiftType.coletivo;
    final isFisico = gift.tipo == GiftType.fisico;
    // Verifica se existe link de imagem válido
    final temFoto = gift.imagem != null && gift.imagem!.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onEdit,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Prioriza a imagem se for físico e houver link, senão ícone
                      (isFisico && temFoto) ? _buildProductImage() : _buildIconContainer(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(gift.nome,
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black87)),
                            _buildSubtitleRow(),
                          ],
                        ),
                      ),
                      _buildStatusBadge(),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Lógica de valores conforme solicitado
                  if (isColetivo) _buildProgressSection() else if (!isFisico) _buildSimplePrice(),

                  const Divider(height: 24),
                  _buildFooterActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget para renderizar a imagem do produto com tratamento de erro
  Widget _buildProductImage() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Image.network(
          gift.imagem!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildIconContainer(isError: true),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: primary.withValues(alpha: 0.5))),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSubtitleRow() {
    final temLinkLoja = gift.link != null && gift.link!.isNotEmpty;
    return Row(
      children: [
        Text(gift.tipo.name.capitalizeFirst!,
            style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        if (temLinkLoja) ...[
          const SizedBox(width: 6),
          Icon(Icons.link, size: 12, color: primary.withValues(alpha: 0.6)),
        ]
      ],
    );
  }

  Widget _buildIconContainer({bool isError = false}) {
    IconData icon;
    if (isError) {
      icon = Icons.image_not_supported_outlined;
    } else {
      switch (gift.tipo) {
        case GiftType.pix:
          icon = Icons.pix;
          break;
        case GiftType.coletivo:
          icon = Icons.groups_outlined;
          break;
        default:
          icon = Icons.inventory_2_outlined;
      }
    }
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: isError ? Colors.grey : primary, size: 24),
    );
  }

  Widget _buildStatusBadge() {
    final bool reservado = gift.status == GiftStatus.reservado;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:
            reservado ? Colors.orange.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        reservado ? "Reservado" : "Disponível",
        style: TextStyle(
            color: reservado ? Colors.orange[800] : Colors.green[800],
            fontSize: 10,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildProgressSection() {
    final percent = (gift.metaValor ?? 0) > 0 ? (gift.valorArrecadado / gift.metaValor!) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Progresso da Meta", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            Text("${(percent * 100).toStringAsFixed(0)}%",
                style: TextStyle(fontWeight: FontWeight.bold, color: primary)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: percent.clamp(0.0, 1.0),
          backgroundColor: Colors.grey[200],
          color: primary,
          minHeight: 8,
          borderRadius: BorderRadius.circular(10),
        ),
        const SizedBox(height: 4),
        Text("R\$ ${gift.valorArrecadado.toStringAsFixed(2)} arrecadados",
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSimplePrice() {
    return Row(
      children: [
        Text("Valor Sugerido: ", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        Text("R\$ ${gift.valor?.toStringAsFixed(2) ?? '0.00'}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildFooterActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("Criado em ${gift.createdAt.day}/${gift.createdAt.month}",
            style: TextStyle(color: Colors.grey[400], fontSize: 11)),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blueGrey),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
              onPressed: onDelete,
            ),
          ],
        )
      ],
    );
  }
}
