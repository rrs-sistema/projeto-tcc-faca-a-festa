import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/biblioteca.dart';
import '../../../../../controllers/fornecedor/fornecedor_localizacao_controller.dart';
import '../../../../../controllers/servico/servico_produto_controller.dart';
import './../../../../../core/utils/no_sqflite_cache_manager.dart';
import '../../../../../controllers/fornecedor/fornecedor_controller.dart';
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
        Text(
          fornecedor.razaoSocial,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: ativo ? Colors.black87 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 6),
        if (!ativo)
          _statusChip(
            label: 'Desativado',
            color: Colors.red.shade700,
            background: Colors.red.shade50,
            icon: Icons.block_rounded,
          )
        else if (aprovado)
          _statusChip(
            label: 'Apto para operar',
            color: Colors.green.shade700,
            background: Colors.green.shade50,
            icon: Icons.verified_rounded,
          )
        else
          _statusChip(
            label: 'Aguardando aprovação',
            color: Colors.orange.shade800,
            background: Colors.orange.shade50,
            icon: Icons.pending_actions_rounded,
          ),
        const SizedBox(height: 6),

        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            if (controller.cidadeDoFornecedor(fornecedor).isNotEmpty)
              _miniChip(Icons.location_on_outlined, controller.cidadeDoFornecedor(fornecedor)),
            _miniChip(
              Icons.design_services_outlined,
              '${controller.servicosDoFornecedor(fornecedor)} serviços',
            ),
            if (fornecedor.totalAvaliacoes > 0)
              _miniChip(
                Icons.star_rounded,
                '${fornecedor.mediaAvaliacoes.toStringAsFixed(1)} (${fornecedor.totalAvaliacoes})',
              ),
            _miniChip(
              Icons.calendar_today_outlined,
              DateFormat('dd/MM/yyyy').format(fornecedor.dataCadastro),
            ),
            ...controller.nomesCategoriasDoFornecedor(fornecedor).take(3).map(
                  (nome) => _miniChip(Icons.category_outlined, nome),
                ),
          ],
        ),
        const SizedBox(height: 6),

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

        if (!aprovado && ativo)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _confirmarAprovar(context),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: Text(
                  'Aprovar para operar',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),

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

              if (aprovado) ...[
                _actionButton(
                  icon: Icons.cancel_outlined,
                  label: 'Reprovar',
                  color: Colors.deepOrange,
                  bgColor: Colors.orange.shade50,
                  borderColor: Colors.orange.shade300,
                  onTap: () => _confirmarReprovar(context),
                ),
                const SizedBox(width: 10),
              ],

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
                  final fornecedorLocalizacaoController = FornecedorLocalizacaoController.to;
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

  Widget _miniChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: primary),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
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

  Widget _statusChip({
    required String label,
    required Color color,
    required Color background,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarAprovar(BuildContext context) {
    return Biblioteca.showConfirmDialog(
      context,
      title: 'Aprovar fornecedor',
      message:
          'Deseja aprovar ${fornecedor.razaoSocial} para operar? O próximo acesso do fornecedor abrirá a home operacional.',
      confirmLabel: 'Aprovar',
      color: Colors.green.shade700,
      onConfirm: () async {
        final ok = await controller.aprovarFornecedor(_idDocumento);
        if (ok) {
          Get.snackbar(
            'Fornecedor aprovado',
            '${fornecedor.razaoSocial} já pode operar no próximo login.',
            backgroundColor: Colors.green.shade700,
            colorText: Colors.white,
          );
        } else {
          Get.snackbar(
            'Não foi possível aprovar',
            'Tente novamente em instantes.',
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
          );
        }
        return ok;
      },
    );
  }

  Future<void> _confirmarReprovar(BuildContext context) {
    return Biblioteca.showConfirmDialog(
      context,
      title: 'Reprovar fornecedor',
      message:
          'Remover a aprovação de ${fornecedor.razaoSocial}? O fornecedor deixará de acessar a home operacional.',
      confirmLabel: 'Reprovar',
      color: Colors.deepOrange,
      onConfirm: () async {
        final ok = await controller.reprovarFornecedor(_idDocumento);
        if (ok) {
          Get.snackbar(
            'Aprovação removida',
            '${fornecedor.razaoSocial} ficou em análise e não opera até nova aprovação.',
            backgroundColor: Colors.orange.shade700,
            colorText: Colors.white,
          );
        } else {
          Get.snackbar(
            'Não foi possível reprovar',
            'Tente novamente em instantes.',
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
          );
        }
        return ok;
      },
    );
  }

  String get _idDocumento {
    final idFornecedor = fornecedor.idFornecedor.trim();
    if (idFornecedor.isNotEmpty) return idFornecedor;
    return fornecedor.idUsuario.trim();
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
