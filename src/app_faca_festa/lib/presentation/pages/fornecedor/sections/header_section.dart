import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import './../../../../core/utils/no_sqflite_cache_manager.dart';
import 'fornecedor_premium_layout.dart';

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FornecedorController>();
    final appController = Get.find<AppController>();

    return Obx(() {
      final fornecedor = controller.fornecedor.value;
      final ativo = fornecedor?.ativo ?? true;
      final apto = fornecedor?.aptoParaOperar ?? false;
      final nome = fornecedor?.razaoSocial.trim().isNotEmpty == true
          ? fornecedor!.razaoSocial.trim()
          : 'Fornecedor Faça a Festa';
      final contato =
          _contatoPrincipal(fornecedor?.email, fornecedor?.telefone);
      final categoria = _categoriaPrincipal(fornecedor?.categorias) ??
          'Categoria não informada';
      final status = _statusText(ativo: ativo, apto: apto);
      final statusColor = _statusColor(ativo: ativo, apto: apto);

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B1220),
              Color(0xFF151B3A),
              Color(0xFF2A1748),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF111827).withValues(alpha: 0.22),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 660;
            final verySmall = constraints.maxWidth < 380;

            final identity = Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _LogoFornecedor(
                    url: fornecedor?.bannerUrl, size: compact ? 54 : 64),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        nome,
                        maxLines: compact ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: verySmall
                              ? 14.5
                              : compact
                                  ? 16
                                  : 19,
                          fontWeight: FontWeight.w900,
                          height: 1.08,
                          letterSpacing: -0.35,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        contato,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: compact ? 11.5 : 12.5,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );

            final chips = Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusChip(text: status, color: statusColor),
                _InfoChip(text: categoria, icon: Icons.category_outlined),
              ],
            );

            final logout = _HeaderIconButton(
              tooltip: 'Sair',
              icon: Icons.logout_rounded,
              onPressed: () => _confirmarLogout(context, appController),
            );
            final auditoria = _HeaderIconButton(
              tooltip: 'Auditoria dos serviços',
              icon: Icons.policy_outlined,
              onPressed: () => Get.toNamed('/fornecedor/auditoria'),
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: identity),
                      const SizedBox(width: 8),
                      auditoria,
                      const SizedBox(width: 8),
                      logout,
                    ],
                  ),
                  const SizedBox(height: 12),
                  chips,
                ],
              );
            }

            return Row(
              children: [
                Expanded(flex: 5, child: identity),
                const SizedBox(width: 14),
                Expanded(
                    flex: 4,
                    child:
                        Align(alignment: Alignment.centerRight, child: chips)),
                const SizedBox(width: 12),
                auditoria,
                const SizedBox(width: 8),
                logout,
              ],
            );
          },
        ),
      );
    });
  }

  static String _contatoPrincipal(String? email, String? telefone) {
    final e = email?.trim() ?? '';
    final t = telefone?.trim() ?? '';
    if (e.isNotEmpty) return e;
    if (t.isNotEmpty) return t;
    return 'Contato não informado';
  }

  static String _statusText({required bool ativo, required bool apto}) {
    if (!ativo) return 'Inativo';
    if (apto) return 'Operacional';
    return 'Em análise';
  }

  static Color _statusColor({required bool ativo, required bool apto}) {
    if (!ativo) return const Color(0xFFFF6B6B);
    if (apto) return const Color(0xFF3CE48C);
    return const Color(0xFFFFC857);
  }

  static String? _categoriaPrincipal(List<Map<String, dynamic>>? categorias) {
    if (categorias == null || categorias.isEmpty) return null;

    for (final item in categorias) {
      final nome = (item['nome_categoria'] ??
              item['nomeCategoria'] ??
              item['categoria_nome'] ??
              item['categoriaNome'] ??
              item['nome'])
          ?.toString()
          .trim();
      if (nome != null && nome.isNotEmpty) return nome;
    }

    return null;
  }

  Future<void> _confirmarLogout(
      BuildContext context, AppController appController) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Encerrar sessão',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        content: Text(
          'Deseja realmente sair do painel do fornecedor?',
          style: GoogleFonts.poppins(fontSize: 13.5),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: FornecedorPremiumPalette.dark,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child:
                Text('Sair', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await appController.logoutFornecedor();
    }
  }
}

class _LogoFornecedor extends StatelessWidget {
  final String? url;
  final double size;

  const _LogoFornecedor({this.url, this.size = 64});

  @override
  Widget build(BuildContext context) {
    final imageUrl = url?.trim() ?? '';

    return Container(
      height: size,
      width: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(size >= 62 ? 20 : 17),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size >= 62 ? 17 : 14),
        child: imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                cacheManager: AdaptiveCacheManager.instance,
                fit: BoxFit.cover,
                memCacheHeight: 220,
                memCacheWidth: 220,
                placeholder: (_, __) => const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, __, ___) => _placeholder(),
              )
            : Image.asset(
                'assets/images/fornecedor_logo.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: Colors.white.withValues(alpha: 0.12),
        child: Icon(
          Icons.storefront_rounded,
          color: Colors.white,
          size: size * 0.42,
        ),
      );
}

class _HeaderIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: SizedBox(
            height: 40,
            width: 40,
            child: Icon(
              icon,
              color: Colors.white.withValues(alpha: 0.86),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return PremiumPill(text: text, color: color, icon: Icons.verified_rounded);
  }
}

class _InfoChip extends StatelessWidget {
  final String text;
  final IconData icon;

  const _InfoChip({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.82)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
