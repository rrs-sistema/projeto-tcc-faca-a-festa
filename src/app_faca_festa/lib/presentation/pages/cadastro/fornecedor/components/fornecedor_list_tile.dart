import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/biblioteca.dart';
import './../../../../../controllers/fornecedor_localizacao_controller.dart';
import './../../../../../controllers/servico_produto_controller.dart';
import './../../../../../core/utils/no_sqflite_cache_manager.dart';
import './../../../../../controllers/fornecedor_controller.dart';
import './../../servico/servico_produto_list_screen.dart';
import './../../../../../data/models/model.dart';
import './territorio_atendimento_screen.dart';

class FornecedorListTile extends StatelessWidget {
  final FornecedorModel fornecedor;
  final FornecedorController controller;
  final bool isCelular;
  final Color primary;

  const FornecedorListTile({
    super.key,
    required this.fornecedor,
    required this.controller,
    required this.isCelular,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final ativo = fornecedor.ativo;
    final aprovado = fornecedor.aptoParaOperar;
    final telefoneLimpo = fornecedor.telefone.replaceAll(RegExp(r'[^0-9]'), '');
    final linkWhatsapp = 'https://wa.me/55$telefoneLimpo?text=Olá, ${fornecedor.razaoSocial}! 👋\n'
        'Sou administrador do Faça a Festa e gostaria de conversar sobre seus serviços.';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: ativo ? Colors.white : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          if (ativo)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBanner(),
            const SizedBox(width: 14),
            Expanded(
              child: _buildInfo(context, linkWhatsapp, aprovado, ativo),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner() {
    final url = fornecedor.bannerUrl?.trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: isCelular ? 70 : 100,
        height: isCelular ? 70 : 100,
        color: Colors.grey.shade200, // fundo base
        child: (url != null && url.isNotEmpty)
            ? CachedNetworkImage(
                imageUrl: url,
                cacheManager: AdaptiveCacheManager.instance,
                fit: BoxFit.cover,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
                errorWidget: (_, __, ___) {
                  debugPrint('❌ Erro ao carregar imagem: $url');
                  return _bannerPlaceholder();
                },
                fadeInDuration: const Duration(milliseconds: 250),
              )
            : _bannerPlaceholder(),
      ),
    );
  }

  Widget _bannerPlaceholder() => Container(
        color: Colors.grey.shade300,
        alignment: Alignment.center,
        child: const Icon(Icons.image_rounded, color: Colors.white54, size: 32),
      );

  Widget _buildInfo(BuildContext context, String linkWhatsapp, bool aprovado, bool ativo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔹 Nome e status
        Row(
          children: [
            Expanded(
              child: Text(
                fornecedor.razaoSocial,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: ativo ? Colors.black87 : Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(width: 4),
            if (!ativo)
              Tooltip(
                message: 'Fornecedor desativado',
                child: const Icon(Icons.block_rounded, color: Colors.redAccent, size: 20),
              )
            else if (aprovado)
              Tooltip(
                message: 'Fornecedor aprovado',
                child: Icon(Icons.verified_rounded, color: Colors.green.shade600, size: 20),
              )
            else
              Tooltip(
                message: 'Aguardando aprovação',
                child:
                    const Icon(Icons.pending_actions_rounded, color: Colors.orangeAccent, size: 20),
              ),
          ],
        ),
        const SizedBox(height: 4),

        // 🔹 Descrição
        Text(
          fornecedor.descricao?.isNotEmpty == true ? fornecedor.descricao! : 'Sem descrição',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey.shade700,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 6),

        // 🔹 Contato
        _infoLine(Icons.email_outlined, fornecedor.email),
        const SizedBox(height: 4),
        _infoLine(Icons.phone, fornecedor.telefone),
        const SizedBox(height: 8),

        // 🔹 Ações
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const SizedBox(width: 8), // margem inicial opcional

              _actionButton(
                icon: FontAwesomeIcons.whatsapp,
                label: 'WhatsApp',
                color: Colors.green.shade600,
                bgColor: Colors.green.shade50,
                borderColor: Colors.green.shade400,
                onTap: () async {
                  final uri = Uri.parse(linkWhatsapp);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    Get.snackbar(
                      'Ops!',
                      'Não foi possível abrir o WhatsApp.',
                      backgroundColor: Colors.orange.shade400,
                      colorText: Colors.white,
                      snackPosition: SnackPosition.TOP,
                    );
                  }
                },
              ),
              const SizedBox(width: 10),
              _actionButton(
                icon: Icons.design_services_outlined,
                label: 'Serviços',
                color: Colors.indigo.shade700,
                bgColor: Colors.indigo.shade50,
                borderColor: Colors.indigo.shade300,
                onTap: () async {
                  final servicoProdutoController = Get.put(ServicoProdutoController());
                  // 🔹 Chama apenas o carregamento se quiser pré-aquecer os dados
                  await servicoProdutoController.toggleListenerFornecedor(
                      idFornecedor: fornecedor.idFornecedor);
                  //await servicoProdutoController.buscarServicosDoFornecedorPeloAdmin(fornecedor.idFornecedor);

                  // 🔹 Abre a tela de lista de serviços (a mesma que o admin usa)
                  Get.to(() => ServicoProdutoListScreen(fornecedorId: fornecedor.idFornecedor));
                },
              ),

              const SizedBox(width: 10),

              // 🔸 Aprovação e Ativação
              if (!aprovado)
                _actionButton(
                    icon: Icons.check_circle_outline,
                    label: 'Aprovar',
                    color: Colors.blue.shade800,
                    bgColor: Colors.blue.shade50,
                    borderColor: Colors.blue.shade300,
                    onTap: () => Biblioteca.showConfirmDialog(
                          context,
                          title: 'Aprovar fornecedor!',
                          message: 'Deseja realmente aprovar ${fornecedor.razaoSocial}?',
                          confirmLabel: 'Aprovar',
                          color: Colors.deepOrange,
                          onConfirm: () async {
                            await controller.aprovarFornecedor(fornecedor.idFornecedor);
                            Get.snackbar('Sucesso', 'Fornecedor aprovado com sucesso!',
                                backgroundColor: Colors.blue.shade600, colorText: Colors.white);
                            return true;
                          },
                        ))
              else
                _actionButton(
                    icon: Icons.cancel_outlined,
                    label: 'Desaprovar',
                    color: Colors.deepOrange,
                    bgColor: Colors.orange.shade50,
                    borderColor: Colors.orange.shade300,
                    onTap: () => Biblioteca.showConfirmDialog(
                          context,
                          title: 'Desaprovar fornecedor!',
                          message: 'Deseja remover a aprovação de ${fornecedor.razaoSocial}?',
                          confirmLabel: 'Desativar',
                          color: Colors.deepOrange,
                          onConfirm: () async {
                            await controller.reprovarFornecedor(fornecedor.idFornecedor);
                            Get.snackbar('Alteração salva', 'Fornecedor marcado como não aprovado.',
                                backgroundColor: Colors.orange.shade700, colorText: Colors.white);
                            return true;
                          },
                        )),
              const SizedBox(width: 10),

              if (ativo)
                _actionButton(
                  icon: Icons.lock_outline,
                  label: 'Desativar',
                  color: Colors.redAccent,
                  bgColor: Colors.red.shade50,
                  borderColor: Colors.red.shade300,
                  onTap: () => Biblioteca.showConfirmDialog(
                    context,
                    title: 'Desativar fornecedor!',
                    message: 'Tem certeza que deseja desativar ${fornecedor.razaoSocial}?',
                    confirmLabel: 'Desativar',
                    color: Colors.red,
                    onConfirm: () async {
                      await controller.desativarFornecedor(fornecedor.idFornecedor);
                      Get.snackbar(
                          'Fornecedor desativado', 'O fornecedor foi desativado com sucesso.',
                          backgroundColor: Colors.redAccent, colorText: Colors.white);
                      return true;
                    },
                  ),
                )
              else
                _actionButton(
                  icon: Icons.lock_open_outlined,
                  label: 'Ativar',
                  color: Colors.green.shade800,
                  bgColor: Colors.green.shade50,
                  borderColor: Colors.green.shade400,
                  onTap: () => Biblioteca.showConfirmDialog(
                    context,
                    title: 'Ativar fornecedor!',
                    message: 'Deseja reativar o fornecedor ${fornecedor.razaoSocial}?',
                    confirmLabel: 'Ativar',
                    color: Colors.green,
                    onConfirm: () async {
                      await controller.ativarFornecedor(fornecedor.idFornecedor);
                      Get.snackbar('Fornecedor ativado', 'O fornecedor foi reativado com sucesso.',
                          backgroundColor: Colors.green.shade700, colorText: Colors.white);
                      return true;
                    },
                  ),
                ),
              const SizedBox(width: 8),

              // 🔹 Adicionar Território
              _actionButton(
                icon: Icons.map_outlined,
                label: 'Território',
                color: Colors.teal.shade700,
                bgColor: Colors.teal.shade50,
                borderColor: Colors.teal.shade300,
                onTap: () async {
                  final fornecedorLocalizacaoController =
                      Get.put(FornecedorLocalizacaoController());
                  final territorio = fornecedorLocalizacaoController.territoriosFornecedores
                      .firstWhereOrNull((t) => t.idFornecedor == fornecedor.idFornecedor);
                  await showAddTerritorioBottomSheet(context, fornecedor.idFornecedor,
                      existente: territorio);
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoLine(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.blueGrey),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
