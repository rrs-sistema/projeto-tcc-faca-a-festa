import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/app/routes/app_route_args.dart';
import 'package:app_faca_festa/data/local/convite_co_organizador_pendente.dart';
import 'package:app_faca_festa/data/services/co_organizador/co_organizador_service.dart';
import 'package:app_faca_festa/data/services/functions/financeiro_callable_gateway.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_controller.dart';
import 'package:app_faca_festa/presentation/modules/cotacao/controllers/cotacao_controller.dart';

/// Aceite de convite para co-organizar um evento.
class ConviteCoOrganizadorPage extends StatefulWidget {
  const ConviteCoOrganizadorPage({super.key});

  @override
  State<ConviteCoOrganizadorPage> createState() =>
      _ConviteCoOrganizadorPageState();
}

class _ConviteCoOrganizadorPageState extends State<ConviteCoOrganizadorPage> {
  final _service = CoOrganizadorService();
  DetalheConviteCoOrganizador? _detalhe;
  String? _erro;
  bool _carregando = true;
  bool _aceitando = false;
  bool _autoAceiteTentado = false;

  String get _token {
    final param = (Get.parameters['token'] ?? '').trim();
    if (param.isNotEmpty) return param;
    final args = Get.arguments;
    if (args is Map && args['token'] != null) {
      return args['token'].toString().trim();
    }
    if (args is String) return args.trim();
    return TokenConviteCoOrganizador.ler() ?? '';
  }

  @override
  void initState() {
    super.initState();
    final token = _token;
    if (token.isNotEmpty) {
      TokenConviteCoOrganizador.guardar(token);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_carregar());
    });
  }

  Future<void> _carregar() async {
    final token = _token;
    if (token.isEmpty) {
      setState(() {
        _carregando = false;
        _erro = 'Link de convite inválido.';
      });
      return;
    }
    TokenConviteCoOrganizador.guardar(token);
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final detalhe = await _service.consultar(token);
      if (!mounted) return;
      setState(() {
        _detalhe = detalhe;
        _carregando = false;
      });
      // Já aceito: abre o evento em vez de deixar o usuário no limbo.
      if (detalhe.status == 'aceito' && detalhe.idEvento.isNotEmpty) {
        unawaited(_abrirEventoJaAceito(detalhe.idEvento));
        return;
      }
      // Voltou do login (1x): aceita sozinho sem pedir login de novo.
      if (detalhe.pendente) {
        unawaited(_tentarAceiteAutomaticoAposLogin());
      }
    } on FinanceiroCallableException catch (e) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erro = e.message ?? e.code;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erro = 'Não foi possível abrir este convite.';
      });
    }
  }

  /// Aguarda a sessão completar após o login e aceita o convite uma vez.
  Future<void> _tentarAceiteAutomaticoAposLogin() async {
    if (_autoAceiteTentado || _aceitando) return;
    final usuario = await _aguardarUsuarioOrganizador();
    if (!mounted || usuario == null) return;
    _autoAceiteTentado = true;
    await _aceitar(silenciosoSeSemUsuario: false);
  }

  Future<dynamic> _aguardarUsuarioOrganizador() async {
    final app = Get.find<AppController>();
    for (var i = 0; i < 20; i++) {
      final usuario = app.usuarioLogado.value;
      if (usuario != null &&
          (usuario.tipo ?? '').trim().toUpperCase() == 'O') {
        return usuario;
      }
      await Future<void>.delayed(const Duration(milliseconds: 150));
      if (!mounted) return null;
    }
    return null;
  }

  Future<void> _abrirEventoJaAceito(String idEvento) async {
    final app = Get.find<AppController>();
    final usuario = await _aguardarUsuarioOrganizador() ??
        app.usuarioLogado.value;
    if (usuario == null) return;
    TokenConviteCoOrganizador.limpar();
    if (!Get.isRegistered<EventoController>()) return;
    final eventos = Get.find<EventoController>();
    await eventos.carregarEventosDoUsuario(usuario.idUsuario, forcar: true);
    await eventos.selecionarEventoPorId(idEvento);
    if (Get.isRegistered<CotacaoController>()) {
      Get.find<CotacaoController>().ouvirMinhasCotacoes();
    }
    if (!mounted) return;
    Get.offAllNamed('/HomeEventScreen');
  }

  Future<void> _irParaLogin() async {
    final token = _token;
    if (token.isNotEmpty) {
      TokenConviteCoOrganizador.guardar(token);
    }
    Get.snackbar(
      'Entre na sua conta',
      'Faça login como organizador com o e-mail do convite. '
          'Depois o convite será aceito automaticamente.',
      snackPosition: SnackPosition.BOTTOM,
    );
    // offAll evita voltar para a tela antiga sem sessão e pedir login 2x.
    Get.offAllNamed(
      '/login',
      arguments: const AuthFluxoArgs(tipo: 'O'),
    );
  }

  Future<void> _aceitar({bool silenciosoSeSemUsuario = false}) async {
    if (_aceitando) return;
    final app = Get.find<AppController>();
    var usuario = app.usuarioLogado.value;
    if (usuario == null) {
      usuario = await _aguardarUsuarioOrganizador();
    }
    if (usuario == null) {
      if (silenciosoSeSemUsuario) return;
      await _irParaLogin();
      return;
    }
    if ((usuario.tipo ?? '').trim().toUpperCase() != 'O') {
      Get.snackbar(
        'Conta incompatível',
        'Este convite é para uma conta de organizador.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _aceitando = true);
    try {
      final idEvento = await _service.aceitar(_token);
      TokenConviteCoOrganizador.limpar();

      // Aceite ok: navega mesmo se a abertura do evento falhar depois.
      if (Get.isRegistered<EventoController>()) {
        try {
          final eventos = Get.find<EventoController>();
          await eventos.carregarEventosDoUsuario(
            usuario.idUsuario,
            forcar: true,
          );
          if (idEvento.isNotEmpty) {
            await eventos.selecionarEventoPorId(idEvento);
          }
          if (Get.isRegistered<CotacaoController>()) {
            Get.find<CotacaoController>().ouvirMinhasCotacoes();
          }
        } catch (e, s) {
          debugPrint('⚠️ [ConviteCoOrg] Pós-aceite: $e\n$s');
        }
      }

      if (!mounted) return;
      Get.snackbar(
        'Pronto',
        'Você agora organiza este evento junto.',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.offAllNamed('/HomeEventScreen');
    } on FinanceiroCallableException catch (e) {
      debugPrint('❌ [ConviteCoOrg] Callable: ${e.code} ${e.message}');
      Get.snackbar(
        'Não foi possível aceitar',
        e.message?.trim().isNotEmpty == true ? e.message! : e.code,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e, s) {
      debugPrint('❌ [ConviteCoOrg] Aceite: $e\n$s');
      Get.snackbar(
        'Não foi possível aceitar',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) setState(() => _aceitando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF0F766E);
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDFA),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF134E4A), Color(0xFFF0FDFA)],
            stops: [0.0, 0.42],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: _carregando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : _erro != null
                        ? _ErroCard(mensagem: _erro!, onRetry: _carregar)
                        : _CartaoConvite(
                            detalhe: _detalhe!,
                            aceitando: _aceitando,
                            onAceitar: () => unawaited(_aceitar()),
                            primary: teal,
                          ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CartaoConvite extends StatelessWidget {
  const _CartaoConvite({
    required this.detalhe,
    required this.aceitando,
    required this.onAceitar,
    required this.primary,
  });

  final DetalheConviteCoOrganizador detalhe;
  final bool aceitando;
  final VoidCallback onAceitar;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final pendente = detalhe.pendente;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'FAÇA A FESTA',
          style: GoogleFonts.poppins(
            letterSpacing: 2.4,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Organizar juntos',
          textAlign: TextAlign.center,
          style: GoogleFonts.fraunces(
            fontSize: 36,
            height: 1.1,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 28),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                detalhe.nomeEvento.isEmpty
                    ? 'Convite de co-organização'
                    : detalhe.nomeEvento,
                textAlign: TextAlign.center,
                style: GoogleFonts.fraunces(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                pendente
                    ? 'Você foi convidado(a) a organizar este evento com os mesmos poderes de planejamento, contratação e pagamento.'
                    : 'Este convite está ${detalhe.status}.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  height: 1.45,
                  color: const Color(0xFF475569),
                ),
              ),
              if (detalhe.email.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Use a conta com o e-mail\n${detalhe.email}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      height: 1.4,
                      color: const Color(0xFF334155),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              if (pendente)
                FilledButton(
                  onPressed: aceitando ? null : onAceitar,
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: aceitando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Aceitar e organizar juntos',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                )
              else
                OutlinedButton(
                  onPressed: () => Get.offAllNamed('/HomeEventScreen'),
                  child: const Text('Ir para minha conta'),
                ),
              TextButton(
                onPressed: () => Get.offAllNamed('/role'),
                child: Text(
                  'Agora não',
                  style: GoogleFonts.poppins(color: const Color(0xFF64748B)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErroCard extends StatelessWidget {
  const _ErroCard({required this.mensagem, required this.onRetry});

  final String mensagem;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.link_off_rounded, size: 40, color: Color(0xFF0F766E)),
          const SizedBox(height: 12),
          Text(
            mensagem,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Tentar de novo')),
        ],
      ),
    );
  }
}
