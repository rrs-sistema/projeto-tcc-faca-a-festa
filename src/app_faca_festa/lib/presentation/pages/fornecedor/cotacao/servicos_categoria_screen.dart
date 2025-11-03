// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';

import '../../../../data/models/DTO/fornecedor_servico_detalhado_dto.dart';
import '../components/abrir_nova_cotacao_bottom_sheet.dart';
import '../../../../controllers/tema/event_theme_controller.dart';
import './../../../../controllers/app_controller.dart';

import './../../../../controllers/fornecedor_localizacao_controller.dart';

class ServicosCategoriaScreen extends StatefulWidget {
  final String idCategoria;
  final String nomeCategoria;
  final List<String> fornecedoresSelecionados;

  const ServicosCategoriaScreen({
    super.key,
    required this.idCategoria,
    required this.nomeCategoria,
    required this.fornecedoresSelecionados,
  });

  @override
  State<ServicosCategoriaScreen> createState() => _ServicosCategoriaScreenState();
}

class _ServicosCategoriaScreenState extends State<ServicosCategoriaScreen> {
  final themeController = Get.find<EventThemeController>();
  final fornecedorController = Get.find<FornecedorLocalizacaoController>();
  final appController = Get.find<AppController>();

  final RxSet<String> selecionados = <String>{}.obs;

  @override
  void initState() {
    super.initState();

    // 🔹 Escuta serviços dos fornecedores selecionados na categoria escolhida
    fornecedorController.escutarServicosFornecedor(
      widget.fornecedoresSelecionados[0],
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradient = themeController.gradient.value;
    final primary = themeController.primaryColor.value;
    final bool isCelular = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          'Serviços - ${widget.nomeCategoria}',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (fornecedorController.carregandoServicosFornecedor.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final servicos = fornecedorController.servicosFornecedor;

        if (servicos.isEmpty) {
          return _mensagemVazia();
        }

        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 90),
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                itemCount: servicos.length,
                physics: const BouncingScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isCelular ? 1 : 2,
                  mainAxisSpacing: 15,
                  crossAxisSpacing: 15,
                  childAspectRatio: isCelular ? 2.3 : 0.85,
                ),
                itemBuilder: (context, index) {
                  final servico = servicos[index];
                  final selecionado = selecionados.contains(servico.id);

                  return GestureDetector(
                    onTap: () {
                      if (selecionado) {
                        selecionados.remove(servico.id);
                        HapticFeedback.lightImpact();
                      } else {
                        selecionados.add(servico.id);
                        HapticFeedback.mediumImpact();
                      }
                    },
                    child: _cardServico(servico, selecionado, primary, gradient, isCelular),
                  );
                },
              ),
            ),

            // 🔹 Botão fixo para cotar
            if (selecionados.isNotEmpty)
              Positioned(
                bottom: 55,
                left: 16,
                right: 16,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.request_quote_rounded, color: Colors.white),
                  label: Text(
                    'Fazer Cotação (${selecionados.length})',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 8,
                  ),
                  onPressed: () {
                    final servicosSelecionados =
                        servicos.where((s) => selecionados.contains(s.id)).toList();

                    if (servicosSelecionados.isEmpty) return;

                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                      ),
                      builder: (_) => CotacaoNovaBottomSheet(
                        tipoEventoNome: widget.nomeCategoria,
                        fornecedoresSelecionados: widget.fornecedoresSelecionados,
                        servicosSelecionados: servicosSelecionados,
                        primary: primary,
                        onCotacaoFinalizada: () {
                          selecionados.clear();
                          appController.limparServicosSelecionados();
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      }),
    );
  }

  // ==========================================================
  // === CARD DE SERVIÇO
  // ==========================================================
  Widget _cardServico(
    FornecedorServicoDetalhadoDto s,
    bool selecionado,
    Color primary,
    LinearGradient gradient,
    bool isCelular,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        gradient: selecionado ? gradient : null,
        color: selecionado ? null : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selecionado ? primary : Colors.grey.shade200,
          width: selecionado ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: selecionado ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            child: s.imagemUrl != null && s.imagemUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: s.imagemUrl!,
                    width: isCelular ? 120 : 140,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.grey.shade200),
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.image, size: 50, color: Colors.grey),
                  )
                : Container(
                    width: isCelular ? 120 : 140,
                    color: Colors.grey.shade100,
                    child: const Icon(Icons.image_outlined, color: Colors.grey, size: 40),
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // 🧩 evita o overflow vertical
                children: [
                  Text(
                    s.nomeServico ?? 'Serviço sem nome',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: selecionado ? Colors.white : Colors.black87,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    // 🧩 permite quebrar texto grande sem estourar o espaço
                    child: Text(
                      s.descricaoServico ?? 'Sem descrição disponível',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: selecionado ? Colors.white70 : Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.precoPromocao != null && s.precoPromocao! > 0
                        ? "R\$ ${s.precoPromocao!.toStringAsFixed(2)} (Promoção)"
                        : "R\$ ${s.preco.toStringAsFixed(2)}",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: selecionado ? Colors.white : primary,
                      fontSize: 13,
                    ),
                  ),
                  if (s.nomeSubcategoria != null && s.nomeSubcategoria!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      s.nomeSubcategoria!,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: selecionado ? Colors.white70 : Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // === MENSAGEM VAZIA
  // ==========================================================
  Widget _mensagemVazia() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 120),
        child: Column(
          children: [
            Icon(Icons.design_services_rounded, size: 70, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Nenhum serviço encontrado',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tente selecionar outro fornecedor ou categoria',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
