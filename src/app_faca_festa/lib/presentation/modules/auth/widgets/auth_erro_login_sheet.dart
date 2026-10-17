import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/presentation/modules/auth/widgets/auth_festa_brand.dart';

class AvisoLogin {
  const AvisoLogin({
    required this.titulo,
    required this.mensagem,
    this.icone = Icons.error_outline_rounded,
    this.oferecerRedefinirSenha = false,
  });

  final String titulo;
  final String mensagem;
  final IconData icone;
  final bool oferecerRedefinirSenha;
}

/// Aviso de falha no login, no lugar do toast central.
Future<void> mostrarErroLoginSheet({
  String? codigo,
  String? titulo,
  String? mensagem,
}) {
  final aviso = (titulo != null && mensagem != null)
      ? AvisoLogin(titulo: titulo, mensagem: mensagem)
      : avisoLoginDeCodigo(codigo ?? '');

  if (Get.isBottomSheetOpen == true) return Future.value();

  return Get.bottomSheet<void>(
    _ErroLoginSheet(aviso: aviso),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xFF111827).withValues(alpha: 0.45),
  );
}

AvisoLogin avisoLoginDeCodigo(String codigo) {
  switch (codigo) {
    case 'wrong-password':
    case 'invalid-credential':
    case 'INVALID_LOGIN_CREDENTIALS':
    case 'user-not-found':
    case 'ERROR_WRONG_PASSWORD':
    case 'ERROR_USER_NOT_FOUND':
    case 'ERROR_INVALID_CREDENTIAL':
      return const AvisoLogin(
        titulo: 'E-mail ou senha não conferem',
        mensagem:
            'Confira o que você digitou. Se não lembrar a senha, dá para criar uma nova.',
        icone: Icons.lock_outline_rounded,
        oferecerRedefinirSenha: true,
      );
    case 'invalid-email':
    case 'ERROR_INVALID_EMAIL':
      return const AvisoLogin(
        titulo: 'E-mail inválido',
        mensagem:
            'Esse e-mail não está no formato certo. Use um endereço como nome@email.com.',
        icone: Icons.alternate_email_rounded,
      );
    case 'user-disabled':
    case 'ERROR_USER_DISABLED':
      return const AvisoLogin(
        titulo: 'Conta desativada',
        mensagem:
            'Esta conta não pode entrar agora. Se achar que é um engano, fale com o suporte.',
        icone: Icons.person_off_outlined,
      );
    case 'too-many-requests':
    case 'ERROR_TOO_MANY_REQUESTS':
      return const AvisoLogin(
        titulo: 'Muitas tentativas',
        mensagem:
            'Por segurança, o acesso foi pausado por alguns minutos. Tente de novo daqui a pouco.',
        icone: Icons.hourglass_bottom_rounded,
      );
    case 'network-request-failed':
      return const AvisoLogin(
        titulo: 'Sem conexão',
        mensagem:
            'Não conseguimos falar com o servidor. Verifique a internet e tente outra vez.',
        icone: Icons.wifi_off_rounded,
      );
    case 'account-exists-with-different-credential':
      return const AvisoLogin(
        titulo: 'Essa conta usa outro acesso',
        mensagem:
            'Este e-mail já está cadastrado de outro jeito. Tente entrar com Google ou com a senha.',
        icone: Icons.account_circle_outlined,
      );
    case 'interrupted':
      return const AvisoLogin(
        titulo: 'O Google interrompeu o login',
        mensagem: 'O acesso com Google não foi concluído. Tente novamente.',
        icone: Icons.login_rounded,
      );
    case 'clientConfigurationError':
    case 'providerConfigurationError':
      return const AvisoLogin(
        titulo: 'Google indisponível',
        mensagem: 'O login com Google não está configurado neste aplicativo.',
      );
    case 'google-token-not-found':
    case 'google-sign-in-unsupported':
    case 'google-unexpected-error':
      return const AvisoLogin(
        titulo: 'Google indisponível',
        mensagem: 'O login com Google não funciona neste dispositivo.',
      );
    default:
      return const AvisoLogin(
        titulo: 'Não foi possível entrar',
        mensagem:
            'Algo impediu o acesso agora. Confira os dados e tente de novo em instantes.',
      );
  }
}

class _ErroLoginSheet extends StatelessWidget {
  const _ErroLoginSheet({required this.aviso});

  final AvisoLogin aviso;

  void _fechar() {
    if (Get.isBottomSheetOpen == true) Get.back();
  }

  void _redefinirSenha() {
    _fechar();
    Get.toNamed('/forgotPassword');
  }

  @override
  Widget build(BuildContext context) {
    const accent = AuthFestaBrand.rosaIcone;
    final inferior = MediaQuery.viewPaddingOf(context).bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.fromLTRB(22, 12, 22, 18 + inferior),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF0F6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(aviso.icone, color: accent, size: 28),
                ),
                const SizedBox(height: 14),
                Text(
                  aviso.titulo,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: AuthFestaBrand.titulo,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  aviso.mensagem,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF6B7280),
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _fechar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Tentar de novo',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (aviso.oferecerRedefinirSenha) ...[
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: _redefinirSenha,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 44),
                      foregroundColor: accent,
                      iconColor: accent,
                    ),
                    child: Text(
                      'Esqueci minha senha',
                      style: GoogleFonts.poppins(
                        color: accent,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
