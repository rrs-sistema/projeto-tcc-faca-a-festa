import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui';

import './../../../../data/models/DTO/fornecedor_servico_detalhado_dto.dart';
import './../../../../controllers/fornecedor_localizacao_controller.dart';
import './../../../../controllers/tema/event_theme_controller.dart';
import '../components/abrir_nova_cotacao_bottom_sheet.dart';
import './../../../../controllers/app_controller.dart';

class ServicosParaCotacaoScreen extends StatefulWidget {
  final String idCategoria;
  final String nomeCategoria;
  final List<String> fornecedoresSelecionados;

  const ServicosParaCotacaoScreen({
    super.key,
    required this.idCategoria,
    required this.nomeCategoria,
    required this.fornecedoresSelecionados,
  });

  @override
  State<ServicosParaCotacaoScreen> createState() => _ServicosParaCotacaoScreenState();
}

class _ServicosParaCotacaoScreenState extends State<ServicosParaCotacaoScreen> {
  final themeController = Get.find<EventThemeController>();
  final fornecedorController = Get.find<FornecedorLocalizacaoController>();
  final appController = Get.find<AppController>();
  final RxSet<String> selecionados = <String>{}.obs;

  @override
  Widget build(BuildContext context) {
    final gradient = themeController.gradient.value;
    final primary = themeController.primaryColor.value;
    final isCelular = MediaQuery.of(context).size.width < 650;

    return Scaffold(
      extendBodyBehindAppBar: true,
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
            Text('Cotação de Serviços',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontSize: 17,
                )),
            Text(widget.nomeCategoria,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.white70,
                )),
          ],
        ),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(decoration: BoxDecoration(gradient: gradient)),
          ),
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          final servicos = fornecedorController.servicosFornecedor;
          if (servicos.isEmpty) return _mensagemVazia();

          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 100, top: 10),
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  itemCount: servicos.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isCelular ? 1 : 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: isCelular ? 2.4 : 1.1,
                  ),
                  itemBuilder: (_, i) {
                    final s = servicos[i];
                    return Obx(() {
                      final chave = '${s.id}_${s.idFornecedor}';
                      final selecionado = selecionados.contains(chave);

                      return Dismissible(
                        key: ValueKey('${s.id}_${s.idFornecedor}'),
                        direction: DismissDirection.horizontal,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.redAccent.shade700, Colors.redAccent.shade200],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.delete_forever_rounded,
                              color: Colors.white, size: 30),
                        ),

                        // 🧠 Confirma antes de apagar
                        confirmDismiss: (_) async {
                          HapticFeedback.selectionClick();
                          return await Get.dialog<bool>(
                            AlertDialog(
                              title: const Text('Remover serviço'),
                              content:
                                  Text('Deseja realmente remover "${s.nomeServico}" da lista?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Get.back(result: false),
                                  child: const Text('Cancelar'),
                                ),
                                ElevatedButton(
                                  style:
                                      ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                  onPressed: () => Get.back(result: true),
                                  child: const Text('Remover'),
                                ),
                              ],
                            ),
                          );
                        },

                        // 🪄 Quando o usuário confirmar o deslize
                        onDismissed: (_) async {
                          // Guarda referência para permitir “Desfazer”
                          final itemRemovido = s;
                          final index = i;

                          fornecedorController.servicosFornecedor.removeAt(index);
                          selecionados.remove(itemRemovido.id);
                          HapticFeedback.mediumImpact();

                          // 🎀 Snackbar elegante com “Desfazer”
                          Get.snackbar(
                            'Serviço removido',
                            '${itemRemovido.nomeServico ?? "Item"} foi removido.',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.white,
                            colorText: Colors.black87,
                            margin: const EdgeInsets.all(14),
                            borderRadius: 16,
                            duration: const Duration(seconds: 3),
                            mainButton: TextButton(
                              onPressed: () {
                                fornecedorController.servicosFornecedor.insert(index, itemRemovido);
                                Get.back(); // fecha snackbar
                                HapticFeedback.lightImpact();
                              },
                              child: Text(
                                'Desfazer',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.blueAccent.shade700,
                                ),
                              ),
                            ),
                          );
                        },

                        child: _cardServico(s, selecionado, primary, gradient, isCelular)
                            .animate()
                            .fadeIn(duration: 350.ms, delay: (i * 80).ms)
                            .slideY(begin: 0.05, end: 0),
                      );
                    });
                  },
                ),
              ),
              // 🔹 Floating Action Modern Button
              Obx(() => AnimatedPositioned(
                    duration: 400.ms,
                    curve: Curves.easeOut,
                    bottom: selecionados.isNotEmpty ? 40 : -80,
                    left: 20,
                    right: 20,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.request_quote_rounded, color: Colors.white),
                      label: Text(
                        'Solicitar Cotação (${selecionados.length})',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 12,
                        shadowColor: primary.withValues(alpha: 0.35),
                      ),
                      onPressed: () => _abrirBottomSheet(servicos, primary),
                    ),
                  )),
            ],
          );
        }),
      ),
    );
  }

  Widget _cardServico(
    FornecedorServicoDetalhadoDto s,
    bool selecionado,
    Color primary,
    LinearGradient gradient,
    bool isCelular,
  ) {
    final fotoUrl = s.imagemUrl?.isNotEmpty == true
        ? s.imagemUrl!
        : 'https://firebasestorage.googleapis.com/v0/b/faca-a-festa.firebasestorage.app/o/static%2Fsem-foto.jpg?alt=media';

    return GestureDetector(
      onTap: () {
        final chave = '${s.id}_${s.idFornecedor}';
        if (selecionados.contains(chave)) {
          selecionados.remove(chave);
        } else {
          selecionados.add(chave);
        }
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: selecionado
              ? gradient
              : const LinearGradient(
                  colors: [Colors.white, Color(0xFFF8F8F8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          border: Border.all(
            color: selecionado ? primary.withValues(alpha: 0.8) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: selecionado
                  ? primary.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: selecionado ? 16 : 8,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 📸 Imagem lateral
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(22)),
                  child: Stack(
                    children: [
                      CachedNetworkImage(
                        imageUrl: fotoUrl,
                        width: isCelular ? 120 : 150,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      // Overlay degradê sutil
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.15),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.1),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 🧾 Detalhes do serviço
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔹 Nome do serviço
                        Text(
                          s.nomeServico ?? 'Serviço sem nome',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: selecionado ? Colors.white : Colors.black87,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // ✨ Descrição
                        Text(
                          s.descricaoServico ?? 'Sem descrição disponível',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: selecionado ? Colors.white70 : Colors.grey.shade700,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // 👤 Nome do fornecedor
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 11,
                              backgroundColor: primary.withValues(alpha: 0.2),
                              child: const Icon(Icons.storefront_rounded, size: 14),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                s.nomeFornecedor ?? 'Fornecedor não informado',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: selecionado ? Colors.white70 : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        // 💸 Preço + categoria
                        Row(
                          children: [
                            // 💰 Preço destacado
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  s.precoPromocao != null && s.precoPromocao! > 0
                                      ? "R\$ ${s.precoPromocao!.toStringAsFixed(2)}"
                                      : "R\$ ${s.preco.toStringAsFixed(2)}",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    color: selecionado ? Colors.white : primary,
                                    fontSize: 14,
                                  ),
                                ),
                                if (s.precoPromocao != null && s.precoPromocao! > 0)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.orangeAccent.withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Promoção',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(width: 10),

                            // 🏷️ Subcategoria (trunca se for longa)
                            if (s.nomeSubcategoria?.isNotEmpty ?? false)
                              Expanded(
                                child: Text(
                                  s.nomeSubcategoria!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.end,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: selecionado ? Colors.white70 : Colors.grey.shade500,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // ✅ Ícone de seleção animado
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              top: 10,
              right: 10,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: selecionado ? 1 : 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(5),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: primary,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirBottomSheet(List<FornecedorServicoDetalhadoDto> servicos, Color primary) {
    final selecionadosServicos = servicos.where((s) {
      final chave = '${s.id}_${s.idFornecedor}';
      return selecionados.contains(chave);
    }).toList();

    if (selecionadosServicos.isEmpty) return;
    final idsFornecedoresSelecionados =
        selecionadosServicos.map((s) => s.idFornecedor).whereType<String>().toSet().toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CotacaoNovaBottomSheet(
        tipoEventoNome: widget.nomeCategoria,
        fornecedoresSelecionados: idsFornecedoresSelecionados,
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
            Icon(Icons.design_services_rounded, size: 90, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            Text(
              'Nenhum serviço disponível',
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
