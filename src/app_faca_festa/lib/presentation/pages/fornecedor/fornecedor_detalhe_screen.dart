import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/no_sqflite_cache_manager.dart';
import './../../../data/models/DTO/fornecedor_detalhado_model.dart';
import './../../../controllers/event_theme_controller.dart';
import 'components/abrir_cotacao_bottom_sheet.dart';

class FornecedorDetalheScreen extends StatelessWidget {
  final FornecedorDetalhadoModel fornecedorDetalhado;
  const FornecedorDetalheScreen({super.key, required this.fornecedorDetalhado});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<EventThemeController>();
    final gradient = themeController.gradient.value;
    final primary = themeController.primaryColor.value;

    final fornecedor = fornecedorDetalhado.fornecedor;
    final territorio = fornecedorDetalhado.territorio;
    final distancia = fornecedorDetalhado.distanciaKm;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          fornecedor.razaoSocial,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === Cabeçalho ===
            // === Cabeçalho com banner ===
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: fornecedor.bannerUrl != null && fornecedor.bannerUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: fornecedor.bannerUrl!,
                      cacheManager: AdaptiveCacheManager.instance,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: Colors.grey.shade300),
                      errorWidget: (_, __, ___) => _bannerPlaceholder(primary),
                      fadeInDuration: const Duration(milliseconds: 300),
                    )
                  : _bannerPlaceholder(primary),
            ),
            const SizedBox(height: 20),

            Center(
              child: Text(
                fornecedor.razaoSocial,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: primary,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // === Informações gerais ===
            _infoTile(Icons.person_outline, "Responsável: ${fornecedor.idUsuario}"),
            _infoTile(Icons.call_outlined, fornecedor.telefone),
            _infoTile(Icons.email_outlined, fornecedor.email),

            if (territorio?.descricao != null && territorio!.descricao!.isNotEmpty)
              _infoTile(Icons.map_outlined, territorio.descricao!),

            if (distancia != null)
              _infoTile(
                Icons.location_on_outlined,
                '${distancia.toStringAsFixed(1)} km de distância',
              ),

            const SizedBox(height: 20),

            // === Descrição ===
            Text(
              'Descrição do fornecedor',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              fornecedor.descricao ??
                  'Este fornecedor ainda não adicionou uma descrição detalhada sobre seus serviços.',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54, height: 1.5),
            ),

            const SizedBox(height: 30),

            // === Botão de orçamento ===
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.request_quote_rounded, color: Colors.white),
                label: const Text(
                  'Solicitar Orçamento',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 6,
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => CotacaoBottomSheet(
                      fornecedoresSelecionados: [fornecedor.idFornecedor],
                      primary: primary,
                      gradient: gradient,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bannerPlaceholder(Color primary) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: 0.4),
            primary.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.image_rounded, color: Colors.white54, size: 36),
      ),
    );
  }

  Widget _infoTile(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
