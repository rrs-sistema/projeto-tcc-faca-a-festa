// ignore_for_file: use_build_context_synchronously

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

import '../../../../controllers/servico/servico_foto_controller.dart';
import './../../../../controllers/servico_produto_controller.dart';
import './../../../../core/utils/no_sqflite_cache_manager.dart';
import './../../../../controllers/event_theme_controller.dart';
import './../../../../controllers/fornecedor_controller.dart';
import './../fornecedor/fornecedor_servico_bottom_sheet.dart';
import './../../../../data/models/model.dart';

class FornecedorServicoListScreen extends StatefulWidget {
  final FornecedorModel fornecedor;
  const FornecedorServicoListScreen({super.key, required this.fornecedor});

  @override
  State<FornecedorServicoListScreen> createState() => _FornecedorServicoListScreenState();
}

class _FornecedorServicoListScreenState extends State<FornecedorServicoListScreen> {
  final fotoController = Get.put(ServicoFotoController());
  final controller = Get.put(FornecedorController());
  final servicoController = Get.put(ServicoProdutoController());
  final theme = Get.find<EventThemeController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final gradient = theme.gradient.value;
      final primary = theme.primaryColor.value;

      return Scaffold(
        appBar: AppBar(
          elevation: 4,
          automaticallyImplyLeading: false,
          flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
          title: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CircleAvatar(
                  radius: 20,
                  child:
                      widget.fornecedor.bannerUrl != null && widget.fornecedor.bannerUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: widget.fornecedor.bannerUrl!,
                              cacheManager: AdaptiveCacheManager.instance,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(color: Colors.grey.shade300),
                              errorWidget: (_, __, ___) => _bannerPlaceholder(primary),
                              memCacheHeight: 250,
                              memCacheWidth: 250,
                              fadeInDuration: const Duration(milliseconds: 250),
                            )
                          : _bannerPlaceholder(primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.fornecedor.razaoSocial,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Serviços oferecidos',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: Obx(() {
          // 🔹 Mostra carregamento geral
          if (servicoController.carregando.value || servicoController.carregando.value) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // 🔹 Nenhum serviço encontrado
          if (servicoController.servicosFornecedor.isEmpty) {
            return Center(
              child: Text(
                'Nenhum serviço cadastrado para este fornecedor',
                style: GoogleFonts.poppins(color: Colors.grey.shade600),
              ),
            );
          }

          // 🔹 Cache local para acesso rápido aos nomes
          final mapaServicos = {
            for (var s in servicoController.servicos) s.id: s.nome,
          };

          // 🔹 Lista de serviços
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: servicoController.servicosFornecedor.length,
            itemBuilder: (_, i) {
              final s = servicoController.servicosFornecedor[i];
              final nomeServico = mapaServicos[s.idProdutoServico] ?? 'Carregando...';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                child: ListTile(
                  title: Text(
                    nomeServico,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        'Preço: R\$ ${s.preco.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                      if (s.precoPromocao != null)
                        Text(
                          'Promoção: R\$ ${s.precoPromocao!.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        s.ativo ? 'Ativo' : 'Inativo',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: s.ativo ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.orange),
                    tooltip: 'Editar serviço',
                    onPressed: () async {
                      EasyLoading.show(status: 'Processando...');
                      await fotoController.carregarFotos(
                          widget.fornecedor.idFornecedor, s.idProdutoServico);
                      await EasyLoading.dismiss();
                      FornecedorProdutoServicoModel vinculo = FornecedorProdutoServicoModel(
                        id: s.idProdutoServico,
                        idProdutoServico: s.idProdutoServico,
                        idFornecedor: s.idFornecedor,
                        preco: s.preco,
                      );

                      showFornecedorServicoBottomSheet(
                        context,
                        widget.fornecedor.idFornecedor,
                        vinculo: vinculo,
                      );
                    },
                  ),
                ),
              );
            },
          );
        }),
        floatingActionButton: FloatingActionButton(
          backgroundColor: primary,
          onPressed: () =>
              showFornecedorServicoBottomSheet(context, widget.fornecedor.idFornecedor),
          child: const Icon(Icons.add),
        ),
      );
    });
  }

  // 🔸 Placeholder elegante e leve
  Widget _bannerPlaceholder(Color primary) {
    return Container(
      height: 110,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: 0.3),
            primary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.image_rounded, color: Colors.white54, size: 32),
      ),
    );
  }
}
