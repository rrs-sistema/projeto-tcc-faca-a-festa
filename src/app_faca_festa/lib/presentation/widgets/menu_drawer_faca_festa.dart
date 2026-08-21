// ignore_for_file: use_build_context_synchronously
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/inspiracao/inspiracao_controller.dart';
import '../../controllers/usuario/usuario_controller.dart';
import '../pages/calculadora/calculadora_itens_admin_page.dart';
import '../pages/inspiracao/inspiracao_admin_page.dart';
import '../pages/inspiracao/minhas_referencias_evento_screen.dart';
import './../pages/evento/seletor_evento_bottom_sheet.dart';
import './../../controllers/tema/event_theme_controller.dart';
import './../pages/usuario/edit_usuario_screen.dart';
import './../../controllers/evento_controller.dart';
import './../../controllers/app_controller.dart';
import './../../core/utils/biblioteca.dart';

class MenuDrawerFacaFesta extends StatelessWidget {
  final Future<void> Function() onLogout;

  MenuDrawerFacaFesta({super.key, required this.onLogout});

  final themeController = Get.find<EventThemeController>();
  final appController = Get.find<AppController>();
  final eventoController = Get.find<EventoController>();
  final usuarioController = Get.find<UsuarioController>();
  final inspiracaoController = Get.find<InspiracaoController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final gradient = themeController.gradient.value;
      final primary = themeController.primaryColor.value;
      final icon = themeController.icon.value;
      final tituloCabecalho = themeController.tituloCabecalho.value;
      final evento = eventoController.eventoAtualEntidade;
      final eventoTitulo = _resolverTituloEvento(evento, tituloCabecalho);
      final nomeUsuario =
          appController.usuarioLogado.value?.nome.split(' ').first ??
              'Organizador';

      return Drawer(
        width: _drawerWidth(context),
        backgroundColor: const Color(0xFFF8FAFC),
        child: Column(
          children: [
            _buildHeader(
              context: context,
              gradient: gradient,
              primary: primary,
              icon: icon,
              titulo: 'Olá, $nomeUsuario 👋',
              eventoTitulo: eventoTitulo,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                children: [
                  _sectionTitle('Principal'),
                  _menuItem(
                    Icons.event_note_rounded,
                    'Meu Evento',
                    subtitle: evento == null
                        ? 'Cadastre ou escolha um evento'
                        : eventoController.eventosDoUsuario.length > 1
                            ? '$eventoTitulo • ${eventoController.eventosDoUsuario.length} eventos'
                            : eventoTitulo,
                    color: primary,
                    onTap: _abrirSeletorEvento,
                  ),
                  _menuItem(
                    Icons.person_outline_rounded,
                    'Meu Perfil',
                    subtitle: 'Dados da conta',
                    color: primary,
                    onTap: () {
                      Get.back();
                      Future.delayed(const Duration(milliseconds: 120), () {
                        Get.to(() => const EditUsuarioScreen());
                      });
                    },
                  ),
                  _menuItem(
                    Icons.wallet_giftcard_rounded,
                    'Gerenciar Presentes',
                    subtitle: 'Sugestões e lista de presentes',
                    color: primary,
                    onTap: () {
                      Get.back();
                      Get.toNamed(
                        '/gerenciarPresentes',
                        arguments: {
                          'eventoId': evento?.idEvento,
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _sectionTitle('Planejamento'),
                  _menuItem(
                    Icons.collections_bookmark_outlined,
                    'Minhas Referências',
                    subtitle: _resumoReferenciasDrawer(),
                    color: primary,
                    onTap: () => _abrirMinhasReferencias(),
                  ),
                  if (_deveExibirAdminCalculadora()) ...[
                    const SizedBox(height: 10),
                    _sectionTitle('Administração'),
                    _menuItem(
                      Icons.lightbulb_outline_rounded,
                      'Gerenciar Inspirações',
                      subtitle: 'Cadastre, publique e destaque ideias',
                      color: primary,
                      badgeText: 'Admin',
                      onTap: () => _abrirIdeiasEInspiracoesAdmin(),
                    ),
                    _menuItem(
                      Icons.tune_rounded,
                      'Itens da Calculadora',
                      subtitle: 'Catálogo e regras por evento',
                      color: primary,
                      badgeText: 'Admin',
                      onTap: () => _abrirCalculadoraItensAdmin(),
                    ),
                  ],
                  const SizedBox(height: 10),
                  _sectionTitle('Social'),
                  _menuItem(
                    Icons.people_alt_outlined,
                    'Comunidade',
                    subtitle: 'Em breve',
                    color: primary,
                    enabled: false,
                  ),
                ],
              ),
            ),
            _buildFooter(context, primary),
          ],
        ),
      );
    });
  }

  double _drawerWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width >= 900) {
      return 310;
    }

    if (width >= 600) {
      return 300;
    }

    return width * 0.84;
  }

  Widget _buildHeader({
    required BuildContext context,
    required LinearGradient gradient,
    required Color primary,
    required IconData icon,
    required String titulo,
    required String eventoTitulo,
  }) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, topPadding + 14, 16, 14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.20),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 27,
              color: primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.24),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.event_available_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          eventoTitulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 2, 6, 6),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: const Color(0xFF94A3B8),
        ),
      ),
    );
  }

  Widget _menuItem(
    IconData icon,
    String title, {
    String? subtitle,
    Color? color,
    VoidCallback? onTap,
    bool enabled = true,
    String? badgeText,
  }) {
    final itemColor = color ?? const Color(0xFF64748B);
    final effectiveOpacity = enabled ? 1.0 : 0.52;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: enabled ? onTap : null,
          child: Ink(
            padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: enabled ? 1 : 0.65),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.025),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: itemColor.withValues(alpha: 0.10 * effectiveOpacity),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: itemColor.withValues(alpha: 0.95 * effectiveOpacity),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 13.2,
                                height: 1.15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B).withValues(
                                  alpha: effectiveOpacity,
                                ),
                              ),
                            ),
                          ),
                          if (badgeText != null &&
                              badgeText.trim().isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: itemColor.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                badgeText,
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: itemColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (subtitle != null && subtitle.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 10.7,
                            height: 1.15,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B).withValues(
                              alpha: effectiveOpacity,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: const Color(0xFFCBD5E1).withValues(
                    alpha: effectiveOpacity,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, Color primary) {
    final saindo = appController.encerrandoSessao.value;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _footerButton(
                icon: Icons.color_lens_outlined,
                label: 'Tema',
                backgroundColor: primary.withValues(alpha: 0.10),
                foregroundColor: primary,
                onPressed: saindo
                    ? null
                    : () {
                        Get.snackbar(
                          'Tema da festa',
                          'O visual segue o tema escolhido no cadastro do evento.',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _footerButton(
                icon: Icons.logout_rounded,
                label: 'Sair',
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red.shade500,
                loading: saindo,
                onPressed: saindo
                    ? null
                    : () async {
                        await Biblioteca.showConfirmDialog(
                          context,
                          title: 'Encerramento da sessão!',
                          message: 'Deseja realmente encerrar sua sessão?',
                          confirmLabel: 'Encerrar',
                          color: primary,
                          onConfirm: () async {
                            await onLogout();
                            return true;
                          },
                        );
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footerButton({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
    required VoidCallback? onPressed,
    bool loading = false,
  }) {
    return SizedBox(
      height: 42,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: backgroundColor,
          disabledForegroundColor: foregroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: foregroundColor,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 17),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _abrirSeletorEvento() {
    Get.back();
    Future.delayed(const Duration(milliseconds: 160), () {
      final context = Get.context;
      if (context == null) return;
      showSeletorEventoBottomSheet(context);
    });
  }

  Future<void> _abrirCalculadoraItensAdmin() async {
    Get.to(
      () => CalculadoraItensAdminPage(),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 260),
    );
  }

  void _abrirIdeiasEInspiracoesAdmin() {
    Get.to(
      () => const InspiracaoAdminPage(),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 260),
    );
  }

  Future<void> _abrirMinhasReferencias() async {
    final evento = eventoController.eventoAtualEntidade;
    final usuarioId = _resolverUsuarioIdAtual();

    if (evento == null) {
      EasyLoading.showInfo(
        'Selecione ou cadastre um evento antes de acessar suas referências.',
      );
      return;
    }

    if (usuarioId.isEmpty) {
      EasyLoading.showInfo(
        'Não foi possível identificar o usuário logado.',
      );
      return;
    }

    await inspiracaoController.configurarContextoEvento(
      eventoId: evento.idEvento,
      userId: usuarioId,
    );

    Get.back();

    await Future.delayed(const Duration(milliseconds: 120));

    Get.to(
      () => MinhasReferenciasEventoScreen(
        eventoId: evento.idEvento,
        userId: usuarioId,
      ),
      arguments: {
        'eventoId': evento.idEvento,
        'idEvento': evento.idEvento,
        'userId': usuarioId,
        'idUsuario': usuarioId,
      },
    );
  }

  String _resolverUsuarioIdAtual() {
    try {
      final dynamic usuario = (appController as dynamic).usuarioLogado.value;
      final id = (usuario?.idUsuario ?? usuario?.id ?? '').toString().trim();

      if (id.isNotEmpty) return id;
    } catch (_) {}

    try {
      final dynamic usuario =
          (usuarioController as dynamic).usuarioLogado.value;
      final id = (usuario?.idUsuario ?? usuario?.id ?? '').toString().trim();

      if (id.isNotEmpty) return id;
    } catch (_) {}

    try {
      final dynamic usuario = (usuarioController as dynamic).usuarioAtual.value;
      final id = (usuario?.idUsuario ?? usuario?.id ?? '').toString().trim();

      if (id.isNotEmpty) return id;
    } catch (_) {}

    return '';
  }

  String _resumoReferenciasDrawer() {
    final referencias = inspiracaoController.referenciasEvento.where((ref) {
      return ref.ativo && !ref.deletado;
    }).toList();

    final total = referencias.length;

    if (total == 0) {
      return 'Nenhuma referência salva';
    }

    final aprovadas =
        referencias.where((ref) => ref.status == 'aprovada').length;

    final pendentes = referencias.where((ref) {
      return ref.status == 'salva' ||
          ref.status == 'em_analise' ||
          ref.status == 'orcar';
    }).length;

    if (aprovadas > 0 && pendentes > 0) {
      return '$total salvas • $aprovadas aprovadas • $pendentes pendentes';
    }

    if (aprovadas > 0) {
      return '$total salvas • $aprovadas aprovadas';
    }

    if (pendentes > 0) {
      return '$total salvas • $pendentes pendentes';
    }

    return '$total referências salvas';
  }

  String _resolverTituloEvento(dynamic evento, String fallback) {
    if (evento == null) {
      return 'Nenhum evento selecionado';
    }

    final candidatos = <String>[];

    try {
      candidatos.add((evento.nomeEvento ?? '').toString());
    } catch (_) {}

    try {
      candidatos.add((evento.nome ?? '').toString());
    } catch (_) {}

    try {
      candidatos.add((evento.titulo ?? '').toString());
    } catch (_) {}

    try {
      candidatos.add((evento.descricao ?? '').toString());
    } catch (_) {}

    for (final candidato in candidatos) {
      final value = candidato.trim();

      if (value.isNotEmpty) {
        return value;
      }
    }

    return fallback.trim().isEmpty ? 'Evento selecionado' : fallback;
  }

  bool _deveExibirAdminCalculadora() {
    try {
      return appController.usuarioLogado.value?.tipo == 'A';
    } catch (_) {
      return false;
    }
  }
}
