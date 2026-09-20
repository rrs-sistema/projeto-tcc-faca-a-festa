import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/app/routes/app_route_args.dart';
import 'package:app_faca_festa/core/utils/convite_link.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/auth/widgets/auth_festa_brand.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_cadastro_controller.dart';
import 'package:app_faca_festa/presentation/widgets/festa_app_bar.dart';

class RoleSelectorScreen extends StatelessWidget {
  const RoleSelectorScreen({
    super.key,
    required this.eventoCadastroController,
  });

  final EventoCadastroController eventoCadastroController;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: FestaSystemUi.fundoClaro,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF3F8),
        body: AuthFestaShell(
          title: 'Como você quer participar?',
          titleHighlight: 'participar?',
          mostrarProvaSocial: false,
          mostrarCreditos: false,
          child: Column(
            children: [
              _RoleChoiceCard(
                title: 'Sou Organizador',
                description:
                    'Crie sua conta para planejar listas, orçamentos e fornecedores',
                icon: Icons.event_available_rounded,
                accent: AuthFestaBrand.rosaIcone,
                onTap: () {
                  eventoCadastroController.limpar(manterEndereco: false);
                  Get.toNamed(
                    '/register',
                    arguments: const AuthFluxoArgs(tipo: 'O'),
                  );
                },
              ),
              const SizedBox(height: 10),
              _RoleChoiceCard(
                title: 'Sou Fornecedor',
                description:
                    'Crie sua conta para oferecer buffet, decoração, foto e música',
                icon: Icons.storefront_rounded,
                accent: AuthFestaBrand.roxoIcone,
                onTap: () {
                  eventoCadastroController.limpar(manterEndereco: false);
                  Get.toNamed(
                    '/register',
                    arguments: const AuthFluxoArgs(tipo: 'F'),
                  );
                },
              ),
              const SizedBox(height: 8),
              _ConviteAcao(
                onTap: () => _abrirDialogoConvite(context),
              ),
              const SizedBox(height: 4),
              _EntrarContaButton(
                onTap: () => Get.toNamed('/login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _abrirDialogoConvite(BuildContext context) async {
  final token = await showDialog<String>(
    context: context,
    builder: (dialogContext) => const _ConviteLinkDialog(),
  );
  if (token == null || token.isEmpty) return;
  Get.find<AppController>().guardarTokenConvite(token);
  await Get.offAllNamed(ConviteLink.rotaConvite(token));
}

class _RoleChoiceCard extends StatelessWidget {
  const _RoleChoiceCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 0,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: accent.withValues(alpha: 0.08),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF0E6EC), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF111827).withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                Container(
                  height: 2,
                  width: double.infinity,
                  color: accent.withValues(alpha: 0.55),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.poppins(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                                color: AuthFestaBrand.titulo,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              description,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                height: 1.3,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFFD1D5DB),
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConviteAcao extends StatelessWidget {
  const _ConviteAcao({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          foregroundColor: AuthFestaBrand.titulo,
        ),
        child: Text.rich(
          TextSpan(
            text: 'Recebeu o convite por e-mail? ',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B7280),
            ),
            children: [
              TextSpan(
                text: 'Colar o link',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AuthFestaBrand.rosa,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _EntrarContaButton extends StatelessWidget {
  const _EntrarContaButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          side: const BorderSide(color: Color(0xFFF0E6EC)),
          foregroundColor: AuthFestaBrand.rosa,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text.rich(
          TextSpan(
            text: 'Já tem uma conta? ',
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B7280),
            ),
            children: [
              TextSpan(
                text: 'Entrar',
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AuthFestaBrand.rosa,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ConviteLinkDialog extends StatefulWidget {
  const _ConviteLinkDialog();

  @override
  State<_ConviteLinkDialog> createState() => _ConviteLinkDialogState();
}

class _ConviteLinkDialogState extends State<_ConviteLinkDialog> {
  final _campo = TextEditingController();
  String? _erro;

  @override
  void dispose() {
    _campo.dispose();
    super.dispose();
  }

  Future<void> _colar() async {
    final dados = await Clipboard.getData(Clipboard.kTextPlain);
    final texto = dados?.text?.trim() ?? '';
    if (texto.isEmpty) return;
    setState(() {
      _campo.text = texto;
      _erro = null;
    });
  }

  void _abrir() {
    final token = ConviteLink.tokenDeTexto(_campo.text);
    if (token == null) {
      setState(() {
        _erro =
            'Não reconhecemos esse link. Cole o endereço que veio no e-mail do convite.';
      });
      return;
    }
    Navigator.of(context).pop(token);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Convite por e-mail',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: AuthFestaBrand.titulo,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'No e-mail da festa, toque em Abrir convite. Se o app já estiver aberto, copie o link abaixo do botão e cole aqui.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.35,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _campo,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _abrir(),
            decoration: InputDecoration(
              hintText: 'https://…/convite/…',
              errorText: _erro,
              suffixIcon: IconButton(
                tooltip: 'Colar',
                onPressed: _colar,
                icon: const Icon(Icons.content_paste_rounded),
              ),
            ),
            onChanged: (_) {
              if (_erro == null) return;
              setState(() => _erro = null);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _abrir,
          style: FilledButton.styleFrom(
            backgroundColor: AuthFestaBrand.rosa,
          ),
          child: const Text('Abrir convite'),
        ),
      ],
    );
  }
}
