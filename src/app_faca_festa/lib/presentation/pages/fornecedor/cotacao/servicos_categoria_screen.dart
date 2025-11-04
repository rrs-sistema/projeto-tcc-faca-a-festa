import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';

import './../../../../data/models/DTO/fornecedor_servico_detalhado_dto.dart';
import './../../../../controllers/fornecedor_localizacao_controller.dart';
import './../../../../controllers/tema/event_theme_controller.dart';
import '../components/abrir_nova_cotacao_bottom_sheet.dart';
import './../../../../controllers/app_controller.dart';

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
  Widget build(BuildContext context) {
    final gradient = themeController.gradient.value;
    final primary = themeController.primaryColor.value;
    final isCelular = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Column(
          children: [
            Text(
              'Cotação de Serviços',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.white),
            ),
            Text(
              widget.nomeCategoria,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
            ),
          ],
        ),
        flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
      ),

      // 🔹 SafeArea evita que o topo sobreponha o AppBar
      body: SafeArea(
        top: true,
        bottom: false,
        child: Obx(() {
          final servicos = fornecedorController.servicosFornecedor;
          if (servicos.isEmpty) return _mensagemVazia();

          return Stack(
            children: [
              // 🔹 Padding ajustado
              Padding(
                padding: const EdgeInsets.only(bottom: 100, top: 10),
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  itemCount: servicos.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isCelular ? 1 : 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: isCelular ? 2.3 : 0.9,
                  ),
                  itemBuilder: (_, i) {
                    final s = servicos[i];
                    final selecionado = selecionados.contains(s.id);
                    return _cardServico(s, selecionado, primary, gradient, isCelular)
                        .animate()
                        .fadeIn(duration: 350.ms, delay: (i * 90).ms)
                        .slideY(begin: 0.08, end: 0);
                  },
                ),
              ),

              // 🔹 Botão flutuante fixo no final
              Positioned(
                bottom: 30,
                left: 20,
                right: 20,
                child: AnimatedOpacity(
                  opacity: selecionados.isNotEmpty ? 1 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.request_quote_rounded, color: Colors.white),
                    label: Text(
                      'Solicitar Cotação (${selecionados.length})',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 10,
                      shadowColor: primary.withValues(alpha: 0.4),
                    ),
                    onPressed: () => _abrirBottomSheet(servicos, primary),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _cardServico(
    FornecedorServicoDetalhadoDto servicoDetalho,
    bool selecionado,
    Color primary,
    LinearGradient gradient,
    bool isCelular,
  ) {
    return GestureDetector(
      onTap: () {
        selecionado ? selecionados.remove(servicoDetalho.id) : selecionados.add(servicoDetalho.id);
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: selecionado
              ? gradient
              : const LinearGradient(
                  colors: [Colors.white, Color(0xFFF9F9F9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          boxShadow: [
            BoxShadow(
              color: selecionado
                  ? primary.withValues(alpha: 0.35)
                  : Colors.grey.withValues(alpha: 0.12),
              blurRadius: selecionado ? 16 : 8,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: selecionado ? primary : Colors.grey.shade300,
            width: selecionado ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
                  child: CachedNetworkImage(
                    imageUrl: servicoDetalho.imagemUrl ?? '',
                    width: isCelular ? 120 : 140,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.grey.shade200),
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.image_not_supported_rounded, color: Colors.grey, size: 40),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                servicoDetalho.nomeServico ?? 'Serviço sem nome',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: selecionado ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            if (selecionado)
                              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          servicoDetalho.descricaoServico ?? 'Sem descrição disponível',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: selecionado ? Colors.white70 : Colors.grey.shade600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          servicoDetalho.precoPromocao != null && servicoDetalho.precoPromocao! > 0
                              ? "R\$ ${servicoDetalho.precoPromocao!.toStringAsFixed(2)} (Promoção)"
                              : "R\$ ${servicoDetalho.preco.toStringAsFixed(2)}",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: selecionado ? Colors.white : primary,
                            fontSize: 13.5,
                          ),
                        ),
                        if (servicoDetalho.nomeSubcategoria?.isNotEmpty ?? false)
                          Text(
                            servicoDetalho.nomeSubcategoria!,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: selecionado ? Colors.white70 : Colors.grey.shade500,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Botão de exclusão elegante
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text('Excluir serviço',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600, color: Colors.black87)),
                      content: Text(
                        'Tem certeza que deseja excluir "${servicoDetalho.nomeServico}"?',
                        style: GoogleFonts.poppins(fontSize: 13.5),
                      ),
                      actions: [
                        TextButton(
                          child: Text('Cancelar', style: GoogleFonts.poppins(color: Colors.grey)),
                          onPressed: () => Get.back(result: false),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => Get.back(result: true),
                          child: Text('Excluir', style: GoogleFonts.poppins(color: Colors.white)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    fornecedorController.removerServico(servicoDetalho.idProdutoServico,
                        servicoDetalho.idFornecedor, servicoDetalho.idSubcategoria ?? '');
                    Get.snackbar(
                      'Serviço removido',
                      '"${servicoDetalho.nomeServico}" foi excluído com sucesso.',
                      backgroundColor: Colors.white,
                      colorText: Colors.black87,
                      icon:
                          Icon(Icons.delete_forever_rounded, color: primary.withValues(alpha: 0.8)),
                      snackPosition: SnackPosition.BOTTOM,
                      margin: const EdgeInsets.all(16),
                    );
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 6,
                        offset: const Offset(1, 3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(6),
                  child:
                      const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirBottomSheet(List<FornecedorServicoDetalhadoDto> servicos, Color primary) {
    final selecionadosServicos = servicos.where((s) => selecionados.contains(s.id)).toList();
    if (selecionadosServicos.isEmpty) return;

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
        servicosSelecionados: selecionadosServicos,
        primary: primary,
        onCotacaoFinalizada: () {
          selecionados.clear();
          appController.limparServicosSelecionados();
        },
      ),
    );
  }

  Widget _mensagemVazia() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.design_services_rounded, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            Text(
              'Nenhum serviço encontrado',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            Text(
              'Tente outra categoria ou fornecedor',
              style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      );
}
