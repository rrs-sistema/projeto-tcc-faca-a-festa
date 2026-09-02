import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../../data/models/DTO/fornecedor_servico_detalhado_dto.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_localizacao_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import '../components/abrir_nova_cotacao_bottom_sheet.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import './../../../../core/utils/biblioteca.dart';

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
  State<ServicosParaCotacaoScreen> createState() =>
      _ServicosParaCotacaoScreenState();
}

class _ServicosParaCotacaoScreenState extends State<ServicosParaCotacaoScreen> {
  final themeController = Get.find<EventThemeController>();
  final fornecedorController = Get.find<FornecedorLocalizacaoController>();
  final appController = Get.find<AppController>();
  final RxSet<String> selecionados = <String>{}.obs;
  final RxMap<String, double> valoresPorChave = <String, double>{}.obs;

  double get _totalSelecionado =>
      valoresPorChave.values.fold<double>(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    final gradient = themeController.gradient.value;
    final primary = themeController.primaryColor.value;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          flexibleSpace:
              Container(decoration: BoxDecoration(gradient: gradient)),
          title: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
                onPressed: () => Get.back(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Cotação de Serviços',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            fontSize: 15)),
                    Text(widget.nomeCategoria,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.85))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // 🔹 Barra Inferior Inteligente
      bottomNavigationBar: Obx(() {
        if (selecionados.isEmpty) return const SizedBox.shrink();
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).padding.bottom > 0
                ? MediaQuery.of(context).padding.bottom
                : 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4))
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: () => _abrirBottomSheet(
                fornecedorController.servicosFornecedor, primary),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.request_quote_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Cotar ${selecionados.length} item(ns) • R\$ ${Biblioteca.formatarValorDecimal(_totalSelecionado)}',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontSize: 13),
                ),
              ],
            ),
          ),
        );
      }),

      body: Obx(() {
        final servicos = fornecedorController.servicosFornecedor;
        if (servicos.isEmpty) return _mensagemVazia();

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          itemCount: servicos.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final s = servicos[i];
            return Obx(() {
              final chave = '${s.id}_${s.idFornecedor}';
              final selecionado = selecionados.contains(chave);

              return Dismissible(
                key: ValueKey(chave),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Icon(Icons.delete_outline_rounded,
                      color: Colors.red.shade400, size: 26),
                ),
                confirmDismiss: (_) async {
                  HapticFeedback.selectionClick();
                  return await Biblioteca.showConfirmDialog(
                    context,
                    title: 'Remover serviço?',
                    message:
                        'Deseja remover "${s.nomeServico}" da visualização?',
                    confirmLabel: 'Remover',
                    color: Colors.red,
                    onConfirm: () async => Future.value(true),
                  );
                },
                onDismissed: (_) async {
                  final itemRemovido = s;
                  final indexRemovido = i;

                  setState(() {
                    fornecedorController.servicosFornecedor
                        .removeAt(indexRemovido);
                    selecionados.remove(chave);
                    valoresPorChave.remove(chave);
                  });

                  await Future.delayed(const Duration(milliseconds: 50));
                  HapticFeedback.lightImpact();

                  Get.snackbar(
                    'Serviço ocultado',
                    '${itemRemovido.nomeServico ?? "Item"} removido.',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: const Color(0xFF1F2937),
                    colorText: Colors.white,
                    margin: const EdgeInsets.all(12),
                    borderRadius: 12,
                    duration: const Duration(seconds: 3),
                    mainButton: TextButton(
                      onPressed: () {
                        setState(() {
                          fornecedorController.servicosFornecedor
                              .insert(indexRemovido, itemRemovido);
                        });
                      },
                      child: Text('Desfazer',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              color: Colors.blueAccent.shade100)),
                    ),
                  );
                },
                // 🔹 Layout de Lista (Horizontal)
                child: _cardServicoLista(s, selecionado, primary)
                    .animate()
                    .fadeIn(duration: 300.ms, delay: (i * 50).ms)
                    .slideX(begin: 0.05, end: 0),
              );
            });
          },
        );
      }),
    );
  }

  // 🔹 Design em Lista (Perfeito para celular e escaneabilidade)
  Widget _cardServicoLista(
      FornecedorServicoDetalhadoDto s, bool selecionado, Color primary) {
    final fotoUrl = s.imagemUrl?.isNotEmpty == true
        ? s.imagemUrl!
        : 'https://firebasestorage.googleapis.com/v0/b/faca-a-festa.firebasestorage.app/o/static%2Fsem-foto.jpg?alt=media';

    return GestureDetector(
      onTap: () {
        final chave = '${s.id}_${s.idFornecedor}';
        if (selecionados.contains(chave)) {
          selecionados.remove(chave);
          valoresPorChave.remove(chave);
        } else {
          selecionados.add(chave);
          valoresPorChave[chave] = s.precoEfetivo;
        }
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: selecionado ? primary.withValues(alpha: 0.04) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selecionado
                  ? primary.withValues(alpha: 0.5)
                  : Colors.black.withValues(alpha: 0.05),
              width: selecionado ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ]),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📸 Imagem
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 90,
                height: 90,
                child: CachedNetworkImage(
                  imageUrl: fotoUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // 🧾 Informações
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.nomeServico ?? 'Serviço sem nome',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: const Color(0xFF1F2937)),
                        ),
                      ),
                      Icon(
                        selecionado
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color: selecionado ? primary : Colors.grey.shade400,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.descricaoServico ?? 'Sem descrição.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey.shade600, height: 1.3),
                  ),
                  const SizedBox(height: 6),

                  // 💸 Preço e Fornecedor
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.storefront_rounded,
                                size: 12, color: primary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                s.nomeFornecedor ?? 'Fornecedor',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (s.precoPromocao != null && s.precoPromocao! > 0)
                            Text(
                              "R\$ ${Biblioteca.formatarValorDecimal(s.preco)}",
                              style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  color: Colors.grey.shade500,
                                  decoration: TextDecoration.lineThrough),
                            ),
                          Text(
                            "R\$ ${Biblioteca.formatarValorDecimal(s.precoEfetivo)}",
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1F2937),
                                fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirBottomSheet(
      List<FornecedorServicoDetalhadoDto> servicos, Color primary) {
    final selecionadosServicos = servicos.where((s) {
      final chave = '${s.id}_${s.idFornecedor}';
      return selecionados.contains(chave);
    }).toList();

    if (selecionadosServicos.isEmpty) return;

    final idsFornecedoresSelecionados = selecionadosServicos
        .map((s) => s.idFornecedor)
        .whereType<String>()
        .toSet()
        .toList();

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
            Icon(Icons.design_services_rounded,
                size: 50, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Nenhum serviço disponível',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: const Color(0xFF1F2937))),
            const SizedBox(height: 4),
            Text('Tente buscar outra categoria.',
                style: GoogleFonts.poppins(
                    color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
      );
}
