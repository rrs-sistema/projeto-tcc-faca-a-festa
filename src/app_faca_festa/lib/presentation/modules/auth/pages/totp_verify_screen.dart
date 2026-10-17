import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/modules/auth/controllers/totp_mfa_controller.dart';
import 'package:app_faca_festa/presentation/modules/auth/widgets/auth_festa_brand.dart';
import 'package:app_faca_festa/presentation/widgets/festa_app_bar.dart';

class TotpVerifyScreen extends StatefulWidget {
  const TotpVerifyScreen({
    super.key,
    required this.controller,
    required this.themeController,
  });

  final TotpMfaController controller;
  final EventThemeController themeController;

  @override
  State<TotpVerifyScreen> createState() => _TotpVerifyScreenState();
}

class _TotpVerifyScreenState extends State<TotpVerifyScreen> {
  static const _esperaReenvio = 30;

  late final TotpMfaController controller;
  late final TextEditingController codigoCtrl;
  late final FocusNode _focoCodigo;
  Timer? _timerReenvio;
  Worker? _quandoPararEnvio;
  var _segundosReenvio = 0;
  var _confirmando = false;
  String? _erro;

  bool get _porEmail =>
      controller.metodoLogin.value == TotpMfaController.etapaEmail;

  @override
  void initState() {
    super.initState();
    controller = widget.controller;
    codigoCtrl = TextEditingController();
    _focoCodigo = FocusNode()..addListener(_atualizarFoco);
    if (controller.metodoLogin.value == TotpMfaController.etapaEmail) {
      _segundosReenvio = _esperaReenvio;
      _armarTimerReenvio();
    }
    _quandoPararEnvio = ever<bool>(controller.enviandoEmail, (enviando) {
      if (!enviando) _agendarFoco();
    });
    _agendarFoco();
  }

  void _agendarFoco() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _pedirFoco());
    Future<void>.delayed(const Duration(milliseconds: 180), _pedirFoco);
  }

  void _pedirFoco() {
    if (!mounted || _confirmando || controller.carregando.value) return;
    if (!_focoCodigo.canRequestFocus) return;
    FocusScope.of(context).requestFocus(_focoCodigo);
  }

  void _atualizarFoco() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timerReenvio?.cancel();
    _quandoPararEnvio?.dispose();
    _focoCodigo.removeListener(_atualizarFoco);
    _focoCodigo.dispose();
    codigoCtrl.dispose();
    super.dispose();
  }

  void _iniciarEsperaReenvio() {
    _timerReenvio?.cancel();
    setState(() => _segundosReenvio = _esperaReenvio);
    _armarTimerReenvio();
  }

  void _armarTimerReenvio() {
    _timerReenvio?.cancel();
    _timerReenvio = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_segundosReenvio <= 1) {
        timer.cancel();
        setState(() => _segundosReenvio = 0);
        return;
      }
      setState(() => _segundosReenvio -= 1);
    });
  }

  Future<void> _confirmar() async {
    if (_confirmando || controller.carregando.value) return;
    final digitos = codigoCtrl.text.replaceAll(RegExp(r'\D'), '');
    controller.codigo.value = digitos;
    if (digitos.length != 6) {
      setState(() {
        _erro = _porEmail
            ? 'Digite os 6 números que chegaram no e-mail'
            : 'Digite os 6 números do app autenticador';
      });
      _focoCodigo.requestFocus();
      return;
    }
    setState(() {
      _erro = null;
      _confirmando = true;
    });
    try {
      await controller.verificarLogin();
    } finally {
      if (mounted) setState(() => _confirmando = false);
    }
  }

  Future<void> _reenviar() async {
    if (_segundosReenvio > 0 || controller.enviandoEmail.value) return;
    codigoCtrl.clear();
    controller.codigo.value = '';
    setState(() => _erro = null);
    await controller.solicitarCodigoEmail(silencioso: true);
    if (!mounted) return;
    _iniciarEsperaReenvio();
    _agendarFoco();
  }

  void _aoDigitar(String valor) {
    controller.codigo.value = valor;
    setState(() => _erro = null);
    if (valor.length == 6) _confirmar();
  }

  @override
  Widget build(BuildContext context) {
    const accent = AuthFestaBrand.rosaIcone;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: FestaSystemUi.fundoClaro,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF3F8),
        body: Obx(() {
          final porEmail = _porEmail;
          final destino = controller.emailMascarado.value;
          final ocupado = _confirmando || controller.carregando.value;
          return AuthFestaShell(
            scrollable: true,
            title: porEmail ? 'Confira seu e-mail' : 'Código do autenticador',
            titleHighlight: porEmail ? 'e-mail' : 'autenticador',
            subtitle: porEmail
                ? 'Enviamos um código de 6 números para você entrar'
                : 'Abra o app autenticador e use o código que está na tela',
            mostrarProvaSocial: false,
            mostrarCreditos: false,
            mostrarPrivacidade: true,
            footerLink: AuthFestaContaButton(
              prefixo: 'Quer usar outra conta? ',
              acao: 'Sair',
              onTap: controller.sair,
            ),
            child: AuthFestaCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (porEmail) ...[
                    _DestinoEmail(
                      destino: destino,
                      enviando:
                          controller.enviandoEmail.value && destino.isEmpty,
                    ),
                    const SizedBox(height: 18),
                  ],
                  _CaixasCodigo(
                    controller: codigoCtrl,
                    focusNode: _focoCodigo,
                    enabled: !ocupado,
                    erro: _erro,
                    onChanged: _aoDigitar,
                    onSubmitted: _confirmar,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: ocupado ? null : _confirmar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        disabledBackgroundColor: accent.withValues(alpha: 0.55),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: ocupado
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.3,
                              ),
                            )
                          : Text(
                              'Confirmar e entrar',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  if (porEmail) ...[
                    const SizedBox(height: 14),
                    Text(
                      'Não chegou?',
                      style: GoogleFonts.poppins(
                        color: AuthFestaBrand.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _segundosReenvio > 0
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              'Reenviar código em 0:${_segundosReenvio.toString().padLeft(2, '0')}',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF6B7280),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : TextButton(
                            onPressed: controller.enviandoEmail.value
                                ? null
                                : _reenviar,
                            style: TextButton.styleFrom(
                              minimumSize: const Size(48, 44),
                              foregroundColor: accent,
                              iconColor: accent,
                            ),
                            child: Text(
                              'Reenviar código',
                              style: GoogleFonts.poppins(
                                color: accent,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                    Text(
                      'Se não aparecer, olhe também a pasta de spam.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF9CA3AF),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 14),
                    Text(
                      'O código muda sozinho. Use o que aparece agora no app.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF9CA3AF),
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _DestinoEmail extends StatelessWidget {
  const _DestinoEmail({
    required this.destino,
    required this.enviando,
  });

  final String destino;
  final bool enviando;

  @override
  Widget build(BuildContext context) {
    const accent = AuthFestaBrand.rosaIcone;
    final texto = destino.isEmpty
        ? (enviando ? 'Enviando o código...' : 'E-mail da sua conta')
        : destino;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0F6),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.mark_email_read_outlined,
                size: 18,
                color: accent,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  texto,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF111827),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Você pode colar o código ou digitar número por número.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: AuthFestaBrand.muted,
            fontSize: 12.5,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _CaixasCodigo extends StatelessWidget {
  const _CaixasCodigo({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onChanged,
    required this.onSubmitted,
    this.erro,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final String? erro;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    const accent = AuthFestaBrand.rosaIcone;
    final digitos = controller.text;
    final ativo = digitos.length.clamp(0, 5);
    final temErro = erro != null;

    return Column(
      children: [
        SizedBox(
          height: 58,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: enabled,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  enableSuggestions: false,
                  autocorrect: false,
                  showCursor: false,
                  maxLength: 6,
                  style: const TextStyle(
                    color: Colors.transparent,
                    fontSize: 1,
                  ),
                  cursorColor: Colors.transparent,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: const InputDecoration(
                    hintText: 'Código de 6 dígitos',
                    hintStyle: TextStyle(
                      color: Colors.transparent,
                      fontSize: 1,
                    ),
                    counterText: '',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: onChanged,
                  onSubmitted: (_) => onSubmitted(),
                ),
              ),
              ExcludeSemantics(
                child: IgnorePointer(
                  child: Row(
                    children: [
                      for (var i = 0; i < 6; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: _CaixaDigito(
                            digito: i < digitos.length ? digitos[i] : '',
                            foco: focusNode.hasFocus &&
                                digitos.length < 6 &&
                                i == ativo,
                            erro: temErro,
                            destaque: accent,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (temErro) ...[
          const SizedBox(height: 8),
          Text(
            erro!,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: const Color(0xFFDC2626),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }
}

class _CaixaDigito extends StatelessWidget {
  const _CaixaDigito({
    required this.digito,
    required this.foco,
    required this.erro,
    required this.destaque,
  });

  final String digito;
  final bool foco;
  final bool erro;
  final Color destaque;

  @override
  Widget build(BuildContext context) {
    final preenchida = digito.isNotEmpty;
    final corBorda = erro
        ? const Color(0xFFDC2626)
        : (foco || preenchida ? destaque : const Color(0xFFE7E5E8));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: preenchida ? const Color(0xFFFFF5F9) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: corBorda,
          width: foco || erro ? 2 : 1.4,
        ),
      ),
      child: digito.isNotEmpty
          ? Text(
              digito,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
                height: 1,
              ),
            )
          : (foco ? const _CursorCodigo() : const SizedBox.shrink()),
    );
  }
}

class _CursorCodigo extends StatefulWidget {
  const _CursorCodigo();

  @override
  State<_CursorCodigo> createState() => _CursorCodigoState();
}

class _CursorCodigoState extends State<_CursorCodigo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _piscada;

  @override
  void initState() {
    super.initState();
    _piscada = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _piscada.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _piscada,
      child: Container(
        width: 2,
        height: 24,
        color: const Color(0xFF111827),
      ),
    );
  }
}
