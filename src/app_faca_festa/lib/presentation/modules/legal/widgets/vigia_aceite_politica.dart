import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/core/legal/politica_privacidade.dart';
import 'package:app_faca_festa/domain/repositories/perfil_usuario_repository.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_rotas_sessao.dart';
import 'package:app_faca_festa/presentation/modules/legal/pages/privacidade_screen.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';

/// Pede novo aceite quando a conta está numa versão antiga da política.
class VigiaAceitePolitica extends StatefulWidget {
  const VigiaAceitePolitica({super.key, required this.child});

  final Widget child;

  @override
  State<VigiaAceitePolitica> createState() => _VigiaAceitePoliticaState();
}

class _VigiaAceitePoliticaState extends State<VigiaAceitePolitica> {
  Worker? _worker;
  var _dialogAberto = false;
  var _ligado = false;
  var _geracao = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ligar());
  }

  @override
  void dispose() {
    _geracao++;
    _worker?.dispose();
    super.dispose();
  }

  void _ligar() {
    if (!mounted || _ligado) return;
    if (!Get.isRegistered<AppController>()) {
      Future<void>.delayed(const Duration(seconds: 1), _ligar);
      return;
    }
    _ligado = true;
    final app = Get.find<AppController>();
    _worker = everAll([app.usuarioLogado, app.carregando], (_) => _agendar());
    _agendar();
  }

  void _agendar() {
    final geracao = ++_geracao;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || geracao != _geracao) return;
      _avaliar();
    });
  }

  bool _rotaPronta(AppController app) {
    if (app.carregando.value) return false;
    final rota = Get.currentRoute;
    return AppRotasSessao.destinoEstavel(rota) ||
        AppRotasSessao.usuarioJaNavegando(
          rota,
          temUsuario: app.usuarioLogado.value != null,
        );
  }

  Future<void> _avaliar() async {
    if (!mounted || _dialogAberto || !Get.isRegistered<AppController>()) return;
    final app = Get.find<AppController>();
    if (!_rotaPronta(app)) return;
    final usuario = app.usuarioLogado.value;
    if (usuario == null) return;
    if (usuario.versaoPoliticaPrivacidade == PoliticaPrivacidade.versao) return;

    _dialogAberto = true;
    final aceitou = await Get.dialog<bool>(
      const _DialogoAceiteVigente(),
      barrierDismissible: false,
    );
    if (!mounted) return;
    if (aceitou == null) {
      _dialogAberto = false;
      _agendar();
      return;
    }

    if (aceitou == true) {
      final agora = DateTime.now();
      EasyLoading.show(status: 'Salvando aceite...');
      try {
        if (Get.isRegistered<PerfilUsuarioRepository>()) {
          await Get.find<PerfilUsuarioRepository>().registrarAceitePolitica(
            idUsuario: usuario.idUsuario,
            aceiteEm: agora,
            versao: PoliticaPrivacidade.versao,
          );
        }
        Get.find<AppController>().usuarioLogado.value = usuario.copyWith(
          aceitePrivacidadeEm: agora,
          versaoPoliticaPrivacidade: PoliticaPrivacidade.versao,
        );
      } finally {
        if (EasyLoading.isShow) EasyLoading.dismiss();
      }
    } else if (aceitou == false) {
      await Get.find<AppController>().logout();
    }
    _dialogAberto = false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _DialogoAceiteVigente extends StatelessWidget {
  const _DialogoAceiteVigente();

  @override
  Widget build(BuildContext context) {
    final tema = Get.isRegistered<EventThemeController>()
        ? Get.find<EventThemeController>()
        : null;
    if (tema == null) {
      final scheme = Theme.of(context).colorScheme;
      return _cartao(
        context,
        primary: scheme.primary,
        onPrimary: scheme.onPrimary,
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    }
    return Obx(
      () => _cartao(
        context,
        primary: tema.primaryColor.value,
        onPrimary: tema.onPrimaryColor.value,
        gradient: tema.gradient.value,
      ),
    );
  }

  Widget _cartao(
    BuildContext context, {
    required Color primary,
    required Color onPrimary,
    required Gradient gradient,
  }) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.privacy_tip_rounded, color: onPrimary, size: 28),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Política atualizada',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: onPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Atualizada em ${PoliticaPrivacidade.atualizacao}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Para continuar nesta conta, confirme a nova versão da política de privacidade. Você pode ler o texto antes de aceitar.',
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        height: 1.45,
                        color: const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: onPrimary,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => Get.back(result: true),
                      child: Text(
                        'Aceitar e continuar',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primary,
                        minimumSize: const Size.fromHeight(48),
                        side: BorderSide(color: primary.withValues(alpha: 0.45)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).push(PrivacidadeScreen.rota()),
                      icon: const Icon(Icons.menu_book_outlined, size: 18),
                      label: Text(
                        'Ler a política',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14.5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        minimumSize: const Size.fromHeight(44),
                      ),
                      onPressed: () => Get.back(result: false),
                      child: Text(
                        'Sair da conta',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
