import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import 'package:app_faca_festa/core/legal/dossie_titular.dart';
import 'package:app_faca_festa/core/legal/dossie_titular_documento.dart';
import 'package:app_faca_festa/core/legal/politica_privacidade.dart';
import 'package:app_faca_festa/core/legal/preferencias_notificacao.dart';
import 'package:app_faca_festa/data/services/lgpd/lgpd_functions_client.dart';
import 'package:app_faca_festa/domain/repositories/perfil_usuario_repository.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/legal/widgets/indice_tratamentos.dart';
import 'package:app_faca_festa/presentation/modules/legal/widgets/meus_protocolos_lgpd.dart';
import 'package:app_faca_festa/presentation/modules/legal/pages/preferencias_notificacao_screen.dart';
import 'package:app_faca_festa/presentation/modules/legal/pages/privacidade_screen.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/modules/usuario/controllers/endereco_usuario_controller.dart';
import 'package:app_faca_festa/presentation/modules/usuario/controllers/usuario_controller.dart';
import 'package:app_faca_festa/presentation/modules/usuario/pages/edit_usuario_screen.dart';
import 'package:app_faca_festa/presentation/widgets/festa_app_bar.dart';

class CentralPrivacidadeScreen extends StatefulWidget {
  const CentralPrivacidadeScreen({super.key});

  static Route<void> rota() {
    return MaterialPageRoute<void>(
      builder: (_) => const CentralPrivacidadeScreen(),
      settings: const RouteSettings(name: '/privacidade/dados'),
    );
  }

  @override
  State<CentralPrivacidadeScreen> createState() => _CentralPrivacidadeScreenState();
}

class _CentralPrivacidadeScreenState extends State<CentralPrivacidadeScreen> {
  var _aba = 0;
  var _ocupado = false;

  EventThemeController? get _tema => Get.isRegistered<EventThemeController>()
      ? Get.find<EventThemeController>()
      : null;

  @override
  Widget build(BuildContext context) {
    final tema = _tema;
    if (tema == null) {
      final scheme = Theme.of(context).colorScheme;
      return _moldura(
        primary: scheme.primary,
        secondary: scheme.secondaryContainer,
        surface: const Color(0xFFF4F7F8),
        onPrimary: scheme.onPrimary,
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        tema: null,
      );
    }
    return Obx(
      () => _moldura(
        primary: tema.primaryColor.value,
        secondary: tema.secondaryColor.value,
        surface: tema.surfaceColor.value,
        onPrimary: tema.onPrimaryColor.value,
        gradient: tema.gradient.value,
        tema: tema,
      ),
    );
  }

  Widget _moldura({
    required Color primary,
    required Color secondary,
    required Color surface,
    required Color onPrimary,
    required Gradient gradient,
    required EventThemeController? tema,
  }) {
    final usuario = Get.isRegistered<AppController>()
        ? Get.find<AppController>().usuarioLogado.value
        : null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: FestaSystemUi.fundoEscuro,
      child: Scaffold(
        backgroundColor: surface,
        appBar: FestaAppBar(
          titulo: 'Dados protegidos',
          themeController: tema,
          gradient: gradient,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: _SeletorAbas(
                aba: _aba,
                primary: primary,
                onPrimary: onPrimary,
                onChanged: (aba) => setState(() => _aba = aba),
              ),
            ),
            Expanded(
              child: _aba == 0
                  ? _Direitos(
                      primary: primary,
                      secondary: secondary,
                      aoExportar: () => _exportarDossie(context),
                      aoCorrigir: () => _abrirPerfil(context),
                      aoRevogar: () => _revogarAvisos(context, usuario?.idUsuario ?? ''),
                      aoAnonimizar: () => _pedirRegistro(
                        context,
                        tipo: 'anonimizacao',
                        titulo: 'Anonimizar ou bloquear',
                        texto:
                            'O pedido pede para anonimizar ou bloquear dados da conta enquanto a exclusão não ocorre. A conta continua ativa até a execução. Você recebe um protocolo.',
                        resumo: 'Solicitação de anonimização ou bloqueio dos dados da conta.',
                      ),
                      aoOpor: () => _pedirRegistro(
                        context,
                        tipo: 'oposicao',
                        titulo: 'Registrar oposição',
                        texto:
                            'A oposição vale para tratamento baseado em legítimo interesse, como auditoria e reputação. O pedido fica registrado para análise e não apaga a conta na hora.',
                        resumo: 'Oposição a tratamento baseado em legítimo interesse.',
                      ),
                      aoExcluir: () => _pedirRegistro(
                        context,
                        tipo: 'exclusao',
                        titulo: 'Solicitar exclusão',
                        texto:
                            'O pedido elimina a conta, o perfil, os eventos em que você é o organizador, convidados desses eventos, cotações, mensagens, fotos enviadas e o token de aviso. Cópias de segurança e logs de auditoria podem levar um prazo adicional. A conta não é apagada neste instante: o pedido fica registrado para execução.',
                        resumo: 'Solicitação de eliminação da conta e dos dados associados.',
                      ),
                      aoLerPolitica: () => Navigator.of(context).push(PrivacidadeScreen.rota()),
                    )
                  : IndiceTratamentos(
                      primary: primary,
                      secondary: secondary,
                      onPrimary: onPrimary,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportarDossie(BuildContext context) async {
    if (_ocupado) return;
    final usuario = Get.isRegistered<AppController>()
        ? Get.find<AppController>().usuarioLogado.value
        : null;
    if (usuario == null) {
      _aviso(context, 'Entre na sua conta para exportar o dossiê do titular.');
      return;
    }
    final preferencias = PreferenciasNotificacaoStore().ler(usuario.idUsuario);
    _ocupado = true;
    EasyLoading.show(status: 'Preparando seu dossiê...');
    try {
      String texto;
      try {
        texto = await LgpdFunctionsClient().exportarDossie();
      } on LgpdFunctionsException {
        texto = montarDossieTitular(
          usuario: usuario,
          preferencias: preferencias,
        );
      }
      await _registrar(
        idUsuario: usuario.idUsuario,
        tipo: 'acesso',
        resumo: 'Exportação do dossiê do titular.',
        nome: usuario.nome,
        email: usuario.email,
      );
      final pdf = await gerarPdfDossieTitular(texto);
      await EasyLoading.dismiss();
      await Share.shareXFiles(
        [
          XFile.fromData(
            pdf,
            mimeType: 'application/pdf',
            name: 'dossie-lgpd-faca-festa.pdf',
          ),
        ],
        subject: 'Dossiê LGPD — Faça a Festa',
        fileNameOverrides: const ['dossie-lgpd-faca-festa.pdf'],
      );
    } finally {
      if (EasyLoading.isShow) await EasyLoading.dismiss();
      _ocupado = false;
    }
  }

  Future<void> _revogarAvisos(BuildContext context, String idUsuario) async {
    if (_ocupado) return;
    if (idUsuario.isEmpty) {
      _aviso(context, 'Entre na sua conta para alterar os avisos.');
      return;
    }
    final usuario = Get.isRegistered<AppController>()
        ? Get.find<AppController>().usuarioLogado.value
        : null;
    _ocupado = true;
    EasyLoading.show(status: 'Abrindo avisos...');
    try {
      await _registrar(
        idUsuario: idUsuario,
        tipo: 'revogacao',
        resumo: 'Abertura das preferências para revogar avisos neste aparelho.',
        nome: usuario?.nome ?? '',
        email: usuario?.email ?? '',
      );
    } finally {
      await EasyLoading.dismiss();
      _ocupado = false;
    }
    if (!context.mounted) return;
    Get.to(() => PreferenciasNotificacaoScreen(idUsuario: idUsuario));
  }

  void _abrirPerfil(BuildContext context) {
    if (!Get.isRegistered<AppController>() ||
        Get.find<AppController>().usuarioLogado.value == null) {
      _aviso(context, 'Entre na sua conta e abra Meu perfil para corrigir os dados.');
      return;
    }
    if (!Get.isRegistered<UsuarioController>() ||
        !Get.isRegistered<EnderecoUsuarioController>() ||
        !Get.isRegistered<EventThemeController>()) {
      _aviso(
        context,
        'A correção de nome, contato e endereço está em Meu perfil, no menu da conta.',
      );
      return;
    }
    Get.to(
      () => EditUsuarioScreen(
        userController: Get.find<UsuarioController>(),
        enderecoController: Get.find<EnderecoUsuarioController>(),
        themeController: Get.find<EventThemeController>(),
      ),
    );
  }

  Future<void> _pedirRegistro(
    BuildContext context, {
    required String tipo,
    required String titulo,
    required String texto,
    required String resumo,
  }) async {
    if (_ocupado) return;
    final usuario = Get.isRegistered<AppController>()
        ? Get.find<AppController>().usuarioLogado.value
        : null;
    if (usuario == null) {
      _aviso(context, 'Entre na sua conta para registrar o pedido.');
      return;
    }
    var confirmando = false;
    final confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(
            titulo,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
          content: Text(
            texto,
            style: GoogleFonts.poppins(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: confirmando ? null : () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.primary,
              ),
              onPressed: confirmando
                  ? null
                  : () {
                      setLocal(() => confirmando = true);
                      Navigator.of(dialogContext).pop(true);
                    },
              child: confirmando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Registrar pedido'),
            ),
          ],
        ),
      ),
    );
    if (confirmar != true || !context.mounted) return;
    _ocupado = true;
    EasyLoading.show(status: 'Registrando pedido...');
    String? protocolo;
    try {
      protocolo = await _registrar(
        idUsuario: usuario.idUsuario,
        tipo: tipo,
        resumo: resumo,
        nome: usuario.nome,
        email: usuario.email,
      );
    } finally {
      await EasyLoading.dismiss();
      _ocupado = false;
    }
    if (!context.mounted) return;
    _aviso(
      context,
      protocolo == null
          ? 'Não foi possível registrar o pedido agora. Tente de novo em instantes.'
          : 'Pedido registrado. Protocolo $protocolo.',
    );
  }

  Future<String?> _registrar({
    required String idUsuario,
    required String tipo,
    required String resumo,
    String nome = '',
    String email = '',
  }) async {
    if (!Get.isRegistered<PerfilUsuarioRepository>()) return null;
    try {
      return await Get.find<PerfilUsuarioRepository>().registrarSolicitacaoTitular(
        idUsuario: idUsuario,
        tipo: tipo,
        resumo: resumo,
        nome: nome,
        email: email,
      );
    } catch (_) {
      return null;
    }
  }

  void _aviso(BuildContext context, String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }
}

class _SeletorAbas extends StatelessWidget {
  const _SeletorAbas({
    required this.aba,
    required this.primary,
    required this.onPrimary,
    required this.onChanged,
  });

  final int aba;
  final Color primary;
  final Color onPrimary;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _abaBotao(0, 'Meus direitos', Icons.verified_user_outlined),
          _abaBotao(1, 'Telas e campos', Icons.grid_view_rounded),
        ],
      ),
    );
  }

  Widget _abaBotao(int indice, String rotulo, IconData icone) {
    final ativa = aba == indice;
    return Expanded(
      child: Material(
        color: ativa ? primary : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onChanged(indice),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icone, size: 18, color: ativa ? onPrimary : primary),
                const SizedBox(width: 6),
                Text(
                  rotulo,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ativa ? onPrimary : const Color(0xFF334155),
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

class _Direitos extends StatelessWidget {
  const _Direitos({
    required this.primary,
    required this.secondary,
    required this.aoExportar,
    required this.aoCorrigir,
    required this.aoRevogar,
    required this.aoAnonimizar,
    required this.aoOpor,
    required this.aoExcluir,
    required this.aoLerPolitica,
  });

  final Color primary;
  final Color secondary;
  final VoidCallback aoExportar;
  final VoidCallback aoCorrigir;
  final VoidCallback aoRevogar;
  final VoidCallback aoAnonimizar;
  final VoidCallback aoOpor;
  final VoidCallback aoExcluir;
  final VoidCallback aoLerPolitica;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
      children: [
        Text(
          'O que você pode fazer',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Política ${PoliticaPrivacidade.versao}. Toque na ação. O restante fica com a equipe.',
          style: GoogleFonts.poppins(fontSize: 13, height: 1.4, color: const Color(0xFF64748B)),
        ),
        const SizedBox(height: 14),
        _Acao(
          primary: primary,
          secondary: secondary,
          icone: Icons.download_rounded,
          titulo: 'Acessar e levar meus dados',
          subtitulo: 'Dossiê da conta, eventos e convidados.',
          onTap: aoExportar,
        ),
        _Acao(
          primary: primary,
          secondary: secondary,
          icone: Icons.edit_outlined,
          titulo: 'Corrigir cadastro',
          subtitulo: 'Nome, contato e endereço em Meu perfil.',
          onTap: aoCorrigir,
        ),
        _Acao(
          primary: primary,
          secondary: secondary,
          icone: Icons.notifications_none_rounded,
          titulo: 'Revogar avisos',
          subtitulo: 'Convite, cotação, chat e avaliação.',
          onTap: aoRevogar,
        ),
        _Acao(
          primary: primary,
          secondary: secondary,
          icone: Icons.article_outlined,
          titulo: 'Ler a política',
          subtitulo: 'Texto completo, ${PoliticaPrivacidade.atualizacao}.',
          onTap: aoLerPolitica,
        ),
        const SizedBox(height: 8),
        Text(
          'Pedidos analisados pela equipe',
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: primary),
        ),
        const SizedBox(height: 8),
        _Acao(
          primary: primary,
          secondary: secondary,
          icone: Icons.visibility_off_outlined,
          titulo: 'Anonimizar ou bloquear',
          subtitulo: 'Gera protocolo. A conta segue ativa.',
          onTap: aoAnonimizar,
        ),
        _Acao(
          primary: primary,
          secondary: secondary,
          icone: Icons.front_hand_outlined,
          titulo: 'Registrar oposição',
          subtitulo: 'Contesta tratamento por legítimo interesse.',
          onTap: aoOpor,
        ),
        _Acao(
          primary: primary,
          secondary: secondary,
          icone: Icons.delete_outline_rounded,
          titulo: 'Solicitar exclusão',
          subtitulo: 'A conta só sai quando o pedido é executado.',
          onTap: aoExcluir,
          destaque: true,
        ),
        const SizedBox(height: 12),
        const MeusProtocolosLgpd(),
        _Limites(primary: primary, secondary: secondary),
      ],
    );
  }
}

class _Acao extends StatelessWidget {
  const _Acao({
    required this.primary,
    required this.secondary,
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
    this.destaque = false,
  });

  final Color primary;
  final Color secondary;
  final IconData icone;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: destaque ? primary.withValues(alpha: 0.35) : secondary,
              ),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: secondary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icone, color: primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          subtitulo,
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            height: 1.3,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: primary.withValues(alpha: 0.7)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Limites extends StatelessWidget {
  const _Limites({
    required this.primary,
    required this.secondary,
  });

  final Color primary;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: secondary),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          iconColor: primary,
          collapsedIconColor: primary,
          title: Text(
            'Prazos e limites',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          subtitle: Text(
            'O que a equipe ainda declara nesta versão.',
            style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B)),
          ),
          children: [
            Text(
              'Criança e bebê entram só com o primeiro nome, sem documento, informados pelo responsável. Exclusão, anonimização e oposição geram protocolo e a conta só é apagada na execução. Logs de auditoria saem depois de 365 dias. A cópia local em SQLite ainda não é criptografada. Convite por e-mail e avaliação por push seguem a preferência da conta. A petição à ANPD continua disponível.',
              style: GoogleFonts.poppins(fontSize: 13, height: 1.45, color: const Color(0xFF334155)),
            ),
          ],
        ),
      ),
    );
  }
}
