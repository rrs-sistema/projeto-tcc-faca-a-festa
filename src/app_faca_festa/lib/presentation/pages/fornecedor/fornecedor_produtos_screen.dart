import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../controllers/event_theme_controller.dart';
import './../../../core/utils/biblioteca.dart';
import './../../../data/models/model.dart';

import 'package:app_faca_festa/controllers/fornecedor_controller.dart';
import 'package:app_faca_festa/controllers/app_controller.dart';
import './../../dialogs/show_novo_orcamento_bottom_sheet.dart';

class FornecedorProdutosScreen extends StatefulWidget {
  final FornecedorModel fornecedor;
  const FornecedorProdutosScreen({super.key, required this.fornecedor});

  @override
  State<FornecedorProdutosScreen> createState() => _FornecedorProdutosScreenState();
}

class _FornecedorProdutosScreenState extends State<FornecedorProdutosScreen> {
  final RxSet<String> selecionados = <String>{}.obs; // 🔹 IDs dos serviços selecionados
  final fornecedorController = Get.find<FornecedorController>();
  final appController = Get.find<AppController>();

  @override
  void initState() {
    super.initState();
    _carregarProdutos();
  }

  Future<void> _carregarProdutos() async {
    // 🔹 Carrega todos os serviços vinculados a este fornecedor
    fornecedorController.escutarServicosFornecedor(widget.fornecedor.idFornecedor);
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<EventThemeController>();
    final gradient = themeController.gradient.value;
    final primary = themeController.primaryColor.value;

    return Obx(() {
      final servicos = fornecedorController.servicosFornecedor
          .where((s) => s.idFornecedor == widget.fornecedor.idFornecedor)
          .toList();

      if (fornecedorController.carregando.value) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      // 🔹 Mapeia cada vínculo com seu produto do catálogo
      final List<Map<String, dynamic>> produtos = servicos.map((fs) {
        final produto = fornecedorController.buscarServicoPorId(fs.idProdutoServico);
        return {
          'id_servico': fs.idFornecedorServico,
          'nome': produto?.nome ?? 'Serviço sem nome',
          'preco': fs.preco,
          'descricao': produto?.descricao ?? '',
          'imagem': fornecedorController.fotosServico
              .firstWhereOrNull((f) => f.idProdutoServico == fs.idProdutoServico)
              ?.url,
        };
      }).toList();

      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Catálogo de ${widget.fornecedor.razaoSocial}',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: 16,
            ),
          ),
          centerTitle: true,
          flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
        ),

        // === GRID DE PRODUTOS ===
        body: produtos.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Text(
                    'Este fornecedor ainda não possui produtos cadastrados.',
                    style: GoogleFonts.poppins(fontSize: 15, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: GridView.builder(
                  itemCount: produtos.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 18,
                    childAspectRatio: 0.65,
                  ),
                  itemBuilder: (context, index) {
                    final p = produtos[index];
                    final selecionado = selecionados.contains(p['id_servico']);
                    return GestureDetector(
                      onTap: () {
                        if (selecionado) {
                          selecionados.remove(p['id_servico']);
                        } else {
                          selecionados.add(p['id_servico']);
                        }
                      },
                      child: _produtoCard(p, primary, gradient, selecionado),
                    );
                  },
                ),
              ),

        // === BOTÃO FIXO DE COTAÇÃO ===
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: selecionados.isEmpty
            ? null
            : ElevatedButton.icon(
                icon: const Icon(Icons.request_quote_rounded, color: Colors.white),
                label: Text(
                  'Cotar (${selecionados.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                  backgroundColor: primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 6,
                ),
                onPressed: () async {
                  // 🔹 Abre o BottomSheet de cotação passando os serviços selecionados
                  for (var idServico in selecionados) {
                    final servico = fornecedorController.servicosFornecedor
                        .firstWhereOrNull((s) => s.idFornecedorServico == idServico);
                    if (servico != null) {
                      await showNovoOrcamentoBottomSheet(
                        context: context,
                        idEvento: appController.eventoModel.value?.idEvento ?? '',
                        idFornecedor: widget.fornecedor.idFornecedor,
                        servico: servico,
                        statusInicial: StatusOrcamento.emNegociacao,
                      );
                    }
                  }
                },
              ),
      );
    });
  }

  // === Card de produto com estado visual de seleção ===
  Widget _produtoCard(
    Map<String, dynamic> p,
    Color primary,
    LinearGradient gradient,
    bool selecionado,
  ) {
    final isTablet = Biblioteca.isTablet(context);
    final preco = (p['preco'] as double?) ?? 0.0;
    final imagem = p['imagem'] ??
        'https://cdn-icons-png.flaticon.com/512/2921/2921822.png'; // 🔹 fallback imagem

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: selecionado ? primary.withValues(alpha: 0.05) : Colors.white,
        border: Border.all(
          color: selecionado ? primary : Colors.grey.shade300,
          width: selecionado ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  imagem,
                  height: isTablet ? 320 : 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p['nome'] ?? 'Sem nome',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'R\$ ${preco.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 🔹 Indicador visual de seleção
          Positioned(
            top: 8,
            right: 8,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: selecionado ? gradient : null,
                border: Border.all(
                  color: selecionado ? Colors.transparent : Colors.grey.shade400,
                  width: 1.2,
                ),
                color: selecionado ? null : Colors.white,
              ),
              child: Icon(
                selecionado ? Icons.check_rounded : Icons.add_rounded,
                color: selecionado ? Colors.white : Colors.grey.shade500,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
