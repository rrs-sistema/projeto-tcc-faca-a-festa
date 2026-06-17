import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../controllers/app_controller.dart';
import '../../../../controllers/fornecedor/fornecedor_controller.dart';
import './../../../../core/utils/no_sqflite_cache_manager.dart';

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FornecedorController>();
    final appController = Get.find<AppController>();

    return Obx(() {
      final fornecedor = controller.fornecedor.value;
      final apto = fornecedor?.aptoParaOperar ?? false;
      final ativo = fornecedor?.ativo ?? true;

      final statusColor = !ativo
          ? const Color(0xFFFF6B6B)
          : apto
              ? const Color(0xFF3CE48C)
              : const Color(0xFFFFC857);
      final statusText = !ativo
          ? 'Inativo'
          : apto
              ? 'Operacional'
              : 'Em análise';

      final categoriaPrincipal = _categoriaPrincipal(fornecedor?.categorias);
      final eventoPrincipal = fornecedor?.tipoEventoNomes.isNotEmpty == true
          ? fornecedor!.tipoEventoNomes.first
          : null;

      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isPhone = width < 560;
          final isVerySmall = width < 360;

          return Container(
            width: double.infinity,
            padding: EdgeInsets.all(isPhone ? 14 : 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isPhone ? 24 : 28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF17153A),
                  Color(0xFF351A52),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF111827).withValues(alpha: 0.22),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isPhone ? 24 : 28),
              child: Stack(
                children: [
                  Positioned(
                    right: isPhone ? -46 : -32,
                    top: isPhone ? -50 : -42,
                    child: _Glow(
                      size: isPhone ? 138 : 168,
                      color: const Color(0xFFFF4FD8).withValues(alpha: 0.14),
                    ),
                  ),
                  Positioned(
                    right: isPhone ? 44 : 110,
                    bottom: isPhone ? -66 : -62,
                    child: _Glow(
                      size: isPhone ? 128 : 150,
                      color: const Color(0xFF3BD4FF).withValues(alpha: 0.12),
                    ),
                  ),
                  isPhone
                      ? _PhoneHeaderContent(
                          fornecedorNome:
                              fornecedor?.razaoSocial ?? 'Fornecedor Faça a Festa',
                          fornecedorEmail:
                              fornecedor?.email ?? 'Contato não disponível',
                          logoUrl: fornecedor?.bannerUrl,
                          statusText: statusText,
                          statusColor: statusColor,
                          categoriaPrincipal: categoriaPrincipal,
                          eventoPrincipal: eventoPrincipal,
                          isTopCategoria: fornecedor?.isTopCategoria ?? false,
                          isVerySmall: isVerySmall,
                          onLogout: () => _confirmarLogout(context, appController),
                        )
                      : _WideHeaderContent(
                          fornecedorNome:
                              fornecedor?.razaoSocial ?? 'Fornecedor Faça a Festa',
                          fornecedorEmail:
                              fornecedor?.email ?? 'Contato não disponível',
                          logoUrl: fornecedor?.bannerUrl,
                          statusText: statusText,
                          statusColor: statusColor,
                          categoriaPrincipal: categoriaPrincipal,
                          eventoPrincipal: eventoPrincipal,
                          isTopCategoria: fornecedor?.isTopCategoria ?? false,
                          onLogout: () => _confirmarLogout(context, appController),
                        ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  String? _categoriaPrincipal(List<Map<String, dynamic>>? categorias) {
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
    BuildContext context,
    AppController appController,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Encerrar sessão',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
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
              backgroundColor: const Color(0xFF111827),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sair', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await appController.logoutFornecedor();
    }
  }
}

class _PhoneHeaderContent extends StatelessWidget {
  final String fornecedorNome;
  final String fornecedorEmail;
  final String? logoUrl;
  final String statusText;
  final Color statusColor;
  final String? categoriaPrincipal;
  final String? eventoPrincipal;
  final bool isTopCategoria;
  final bool isVerySmall;
  final VoidCallback onLogout;

  const _PhoneHeaderContent({
    required this.fornecedorNome,
    required this.fornecedorEmail,
    required this.logoUrl,
    required this.statusText,
    required this.statusColor,
    required this.categoriaPrincipal,
    required this.eventoPrincipal,
    required this.isTopCategoria,
    required this.isVerySmall,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LogoFornecedor(url: logoUrl, size: isVerySmall ? 52 : 58),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fornecedorNome,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: isVerySmall ? 15.5 : 17,
                      height: 1.08,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.45,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fornecedorEmail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.70),
                      fontSize: isVerySmall ? 11.5 : 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _LogoutButton(onPressed: onLogout),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatusChip(text: statusText, color: statusColor),
            if (categoriaPrincipal != null)
              _InfoChip(
                text: categoriaPrincipal!,
                icon: Icons.category_outlined,
              ),
            if (eventoPrincipal != null)
              _InfoChip(
                text: eventoPrincipal!,
                icon: Icons.celebration_outlined,
              ),
            if (isTopCategoria)
              const _InfoChip(
                text: 'Top categoria',
                icon: Icons.workspace_premium_outlined,
              ),
          ],
        ),
      ],
    );
  }
}

class _WideHeaderContent extends StatelessWidget {
  final String fornecedorNome;
  final String fornecedorEmail;
  final String? logoUrl;
  final String statusText;
  final Color statusColor;
  final String? categoriaPrincipal;
  final String? eventoPrincipal;
  final bool isTopCategoria;
  final VoidCallback onLogout;

  const _WideHeaderContent({
    required this.fornecedorNome,
    required this.fornecedorEmail,
    required this.logoUrl,
    required this.statusText,
    required this.statusColor,
    required this.categoriaPrincipal,
    required this.eventoPrincipal,
    required this.isTopCategoria,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _LogoFornecedor(url: logoUrl, size: 72),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fornecedorNome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.45,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                fornecedorEmail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.70),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatusChip(text: statusText, color: statusColor),
                  if (categoriaPrincipal != null)
                    _InfoChip(
                      text: categoriaPrincipal!,
                      icon: Icons.category_outlined,
                    ),
                  if (eventoPrincipal != null)
                    _InfoChip(
                      text: eventoPrincipal!,
                      icon: Icons.celebration_outlined,
                    ),
                  if (isTopCategoria)
                    const _InfoChip(
                      text: 'Top categoria',
                      icon: Icons.workspace_premium_outlined,
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _LogoutButton(onPressed: onLogout),
      ],
    );
  }
}

class _LogoFornecedor extends StatelessWidget {
  final String? url;
  final double size;

  const _LogoFornecedor({this.url, this.size = 68});

  @override
  Widget build(BuildContext context) {
    final imageUrl = url ?? '';

    return Container(
      height: size,
      width: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(size >= 70 ? 20 : 17),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size >= 70 ? 17 : 14),
        child: imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                cacheManager: AdaptiveCacheManager.instance,
                fit: BoxFit.cover,
                memCacheHeight: 220,
                memCacheWidth: 220,
                placeholder: (_, __) => const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
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
          size: size * 0.44,
        ),
      );
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _LogoutButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: SizedBox(
          height: 40,
          width: 40,
          child: Icon(
            Icons.logout_rounded,
            color: Colors.white.withValues(alpha: 0.82),
            size: 21,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String text;
  final IconData icon;

  const _InfoChip({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 165),
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

class _Glow extends StatelessWidget {
  final double size;
  final Color color;

  const _Glow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
