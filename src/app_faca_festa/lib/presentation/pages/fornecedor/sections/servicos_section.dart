import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../controllers/fornecedor_controller.dart';

class ServicosSection extends StatelessWidget {
  const ServicosSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FornecedorController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "🧾 Meus Serviços Cadastrados",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        Obx(() {
          final servicos = controller.servicosFornecedor;
          final catalogoServicos = controller.catalogoServicos;
          final fotoServicos = controller.fotosServico;
          if (servicos.isEmpty) {
            return Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                "Você ainda não cadastrou nenhum serviço.",
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade700,
                  fontSize: 14.5,
                ),
              ),
            );
          }

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: servicos.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final servForn = servicos[index];
              final servico =
                  catalogoServicos.firstWhereOrNull((s) => s.id == servForn.idProdutoServico);
              final fotoServico = fotoServicos
                  .firstWhereOrNull((s) => s.idProdutoServico == servForn.idProdutoServico);
              String imageUrl = 'https://images.unsplash.com/photo-1557804506-669a67965ba0';
              if (fotoServico != null && fotoServico.url.isNotEmpty) {
                imageUrl = fotoServico.url;
              }
              //catalogoServicos
              return _ServicoCard(
                nome: servico?.nome.capitalizeFirst ?? "Serviço",
                preco: servForn.preco,
                precoPromocional: servForn.precoPromocao,
                ativo: servForn.ativo,
                imageUrl: imageUrl,
                onEdit: () => Get.snackbar(
                  "Editar Serviço",
                  "Abrindo editor de ${servForn.idProdutoServico}...",
                  backgroundColor: Colors.green.shade600,
                  colorText: Colors.white,
                ),
                onToggle: (v) => Get.snackbar(
                  "Serviço ${v ? 'ativado' : 'desativado'}",
                  "Status atualizado com sucesso",
                  backgroundColor: Colors.green.shade700,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          );
        }),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () {
              Get.snackbar("Adicionar Serviço", "Abrindo formulário...",
                  backgroundColor: const Color(0xFF2E7D32), colorText: Colors.white);
            },
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            label: Text(
              "Adicionar Novo",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ServicoCard extends StatefulWidget {
  final String nome;
  final double preco;
  final double? precoPromocional;
  final bool ativo;
  final String imageUrl;
  final VoidCallback onEdit;
  final Function(bool) onToggle;

  const _ServicoCard({
    required this.nome,
    required this.preco,
    this.precoPromocional,
    required this.ativo,
    required this.imageUrl,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  State<_ServicoCard> createState() => _ServicoCardState();
}

class _ServicoCardState extends State<_ServicoCard> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final ativo = widget.ativo;

    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: hovered ? 0.12 : 0.06),
              blurRadius: hovered ? 10 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: widget.onEdit,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🔹 Imagem
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Stack(
                  children: [
                    Image.network(
                      widget.imageUrl,
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: ativo
                              ? Colors.green.withValues(alpha: 0.9)
                              : Colors.grey.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              ativo ? Icons.check_circle : Icons.pause_circle_filled,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              ativo ? "Ativo" : "Inativo",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 🔹 Corpo
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.nome,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (widget.precoPromocional != null)
                        Row(
                          children: [
                            Text(
                              "R\$ ${widget.preco.toStringAsFixed(2)}",
                              style: GoogleFonts.poppins(
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "R\$ ${widget.precoPromocional!.toStringAsFixed(2)}",
                              style: GoogleFonts.poppins(
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          "R\$ ${widget.preco.toStringAsFixed(2)}",
                          style: GoogleFonts.poppins(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: widget.onEdit,
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text("Editar"),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.teal.shade700,
                            ),
                          ),
                          Switch(
                            value: ativo,
                            activeColor: Colors.green.shade700,
                            onChanged: widget.onToggle,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
