import 'package:app_faca_festa/core/services/desktop_update_service.dart';
import 'package:app_faca_festa/presentation/widgets/desktop_update_overlay.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/pages/abrangencia_fornecedor_page.dart';
import 'package:app_faca_festa/presentation/modules/legal/pages/central_privacidade_screen.dart';
import 'package:app_faca_festa/presentation/modules/legal/pages/preferencias_notificacao_screen.dart';
import 'package:app_faca_festa/domain/entities/fornecedor.dart';
import 'package:app_faca_festa/core/utils/no_sqflite_cache_manager.dart';
import 'fornecedor_premium_layout.dart';

class HeaderSection extends StatelessWidget {
  const HeaderSection({
    super.key,
    required this.controller,
    required this.appController,
  });

  final FornecedorController controller;
  final AppController appController;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final fornecedor = controller.fornecedor.value;
      final ativo = fornecedor?.ativo ?? true;
      final apto = fornecedor?.aptoParaOperar ?? false;
      final nome = fornecedor?.razaoSocial.trim().isNotEmpty == true
          ? fornecedor!.razaoSocial.trim()
          : 'Fornecedor Faça a Festa';
      final contato =
          _contatoPrincipal(fornecedor?.email, fornecedor?.telefone);
      final categoria =
          _categoriaPrincipal(fornecedor) ?? 'Categoria não informada';
      final status = _statusText(ativo: ativo, apto: apto);
      final statusColor = _statusColor(ativo: ativo, apto: apto);

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
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
              color: const Color(0xFF111827).withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 620 ||
                MediaQuery.textScalerOf(context).scale(14) > 21;
            final conta = _menuConta(context);
            final identity = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LogoFornecedor(
                    url: fornecedor?.bannerUrl, size: compact ? 52 : 60),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(nome,
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: compact ? 18 : 21,
                            fontWeight: FontWeight.w700,
                            height: 1.3)),
                    const SizedBox(height: 4),
                    Text(contato,
                        style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: .8),
                            fontSize: 13,
                            height: 1.4)),
                    const SizedBox(height: 10),
                    Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _StatusChip(text: status, color: statusColor),
                          Text(categoria,
                              style: GoogleFonts.poppins(
                                  color: Colors.white.withValues(alpha: .8),
                                  fontSize: 12)),
                        ]),
                  ],
                )),
              ],
            );
            final botoes = [
              _HeaderAction(
                label: 'Área de atendimento',
                icon: Icons.map_outlined,
                onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                        builder: (_) => const AbrangenciaFornecedorPage())),
              ),
              _HeaderAction(
                label: 'Comunicados',
                icon: Icons.campaign_outlined,
                onPressed: () =>
                    Get.toNamed('/fornecedor/comunicados-operacao'),
              ),
              if (compact) conta,
            ];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (compact)
                  identity
                else
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: identity),
                    const SizedBox(width: 24),
                    conta,
                  ]),
                const SizedBox(height: 16),
                Divider(height: 1, color: Colors.white.withValues(alpha: .14)),
                const SizedBox(height: 12),
                if (compact)
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final botao in botoes) ...[
                          botao,
                          const SizedBox(height: 8),
                        ]
                      ])
                else
                  Wrap(spacing: 12, runSpacing: 8, children: botoes),
              ],
            );
          },
        ),
      );
    });
  }

  Widget _menuConta(BuildContext context) => PopupMenuButton<String>(
        tooltip: 'Abrir opções da conta',
        position: PopupMenuPosition.under,
        onSelected: (opcao) {
          switch (opcao) {
            case 'privacidade':
              Get.to(() => const CentralPrivacidadeScreen());
            case 'notificacoes':
              Get.to(() => PreferenciasNotificacaoScreen(
                  idUsuario:
                      appController.usuarioLogado.value?.idUsuario ?? ''));
            case 'auditoria':
              Get.toNamed('/fornecedor/auditoria');
            case 'atualizacoes':
              DesktopUpdateMenuButton.requests.value++;
            case 'sair':
              _confirmarLogout(context, appController);
          }
        },
        itemBuilder: (_) => [
          _opcaoConta(
              'privacidade', 'Privacidade e dados', Icons.privacy_tip_outlined),
          _opcaoConta('notificacoes', 'Preferências de notificações',
              Icons.notifications_outlined),
          _opcaoConta(
              'auditoria', 'Auditoria dos serviços', Icons.policy_outlined),
          if (DesktopUpdateService.supported)
            _opcaoConta('atualizacoes', 'Atualizações do aplicativo',
                Icons.system_update_alt_rounded),
          const PopupMenuDivider(),
          _opcaoConta('sair', 'Sair da conta', Icons.logout_rounded),
        ],
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: .22)),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.account_circle_outlined, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Flexible(
                child: Text('Minha conta',
                    style: TextStyle(color: Colors.white, fontSize: 13))),
            SizedBox(width: 8),
            Icon(Icons.expand_more_rounded, color: Colors.white, size: 20),
          ]),
        ),
      );

  PopupMenuItem<String> _opcaoConta(
          String valor, String rotulo, IconData icone) =>
      PopupMenuItem(
          value: valor,
          height: 52,
          child: Row(children: [
            Icon(icone, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(rotulo)),
          ]));

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

  static String? _categoriaPrincipal(Fornecedor? fornecedor) {
    if (fornecedor == null || fornecedor.categorias.isEmpty) return null;

    for (final item in fornecedor.categorias) {
      final nome = item.nomeCategoria.trim();
      if (nome.isNotEmpty) return nome;
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
            : _placeholder(),
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

class _HeaderAction extends StatelessWidget {
  const _HeaderAction(
      {required this.label, required this.icon, required this.onPressed});
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.white.withValues(alpha: .06),
          side: BorderSide(color: Colors.white.withValues(alpha: .22)),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 20, color: Colors.white),
          const SizedBox(width: 10),
          Flexible(child: Text(label, style: const TextStyle(fontSize: 13))),
        ]),
      );
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
