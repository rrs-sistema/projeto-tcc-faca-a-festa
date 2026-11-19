import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_faca_festa/domain/entities/usuario.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/auth/controllers/totp_mfa_controller.dart';
import 'package:app_faca_festa/presentation/modules/auth/pages/totp_setup_screen.dart';
import 'package:app_faca_festa/presentation/modules/auth/pages/totp_verify_screen.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/widgets/festa_app_bar.dart';

class SegurancaContaScreen extends StatefulWidget {
  const SegurancaContaScreen({
    super.key,
    required this.appController,
    required this.themeController,
  });

  final AppController appController;
  final EventThemeController themeController;

  @override
  State<SegurancaContaScreen> createState() => _SegurancaContaScreenState();
}

class _SegurancaContaScreenState extends State<SegurancaContaScreen> {
  late Future<Usuario?> _perfil = _carregar();
  bool _abrindo = false;

  Future<Usuario?> _carregar() {
    final uid = widget.appController.autenticacaoRepository.idUsuarioAtual;
    return uid == null
        ? Future.value()
        : widget.appController.obterUsuario(uid);
  }

  Future<void> _configurar(Usuario perfil) async {
    setState(() => _abrindo = true);
    const tag = 'seguranca-conta';
    final controller = Get.put(
      TotpMfaController(
        autenticacaoRepository: widget.appController.autenticacaoRepository,
        appController: widget.appController,
        perfilGestao: perfil,
      ),
      tag: tag,
    );
    try {
      await Get.to<void>(() => perfil.mfaEmailAtivo || perfil.mfaTotpAtivo
          ? TotpVerifyScreen(
              controller: controller, themeController: widget.themeController)
          : TotpSetupScreen(
              controller: controller, themeController: widget.themeController));
    } finally {
      Get.delete<TotpMfaController>(tag: tag);
      if (mounted) {
        setState(() {
          _abrindo = false;
          _perfil = _carregar();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: FestaAppBar(
            titulo: 'Segurança da conta',
            themeController: widget.themeController),
        body: FutureBuilder<Usuario?>(
          future: _perfil,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final perfil = snapshot.data;
            if (snapshot.hasError || perfil == null) {
              return Center(
                  child: TextButton(
                onPressed: () => setState(() => _perfil = _carregar()),
                child: const Text('Tentar carregar a segurança novamente'),
              ));
            }
            final obrigatoria = perfil.tipo == 'A' || perfil.tipo == 'F';
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                  child: SizedBox(
                width: 480,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      obrigatoria
                          ? 'A verificação em duas etapas é obrigatória para esta conta.'
                          : perfil.mfaLoginOpcional
                              ? 'Você ativou a verificação em duas etapas no login.'
                              : 'Sua conta entra diretamente. Ative a verificação em duas etapas se desejar proteção adicional.',
                    ),
                    const SizedBox(height: 16),
                    const Text(
                        'Confirme sua identidade para gerenciar os métodos, gerar códigos de recuperação ou alterar sua preferência.'),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _abrindo ? null : () => _configurar(perfil),
                      child: const Text('Configurar proteção'),
                    ),
                  ],
                ),
              )),
            );
          },
        ),
      );
}
