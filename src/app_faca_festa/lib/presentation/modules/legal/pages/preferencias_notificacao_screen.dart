import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/core/legal/preferencias_notificacao.dart';
import 'package:app_faca_festa/domain/repositories/perfil_usuario_repository.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/widgets/festa_app_bar.dart';

class PreferenciasNotificacaoScreen extends StatefulWidget {
  const PreferenciasNotificacaoScreen({
    super.key,
    required this.idUsuario,
    PreferenciasNotificacaoStore? store,
  }) : _store = store;

  final String idUsuario;
  final PreferenciasNotificacaoStore? _store;

  @override
  State<PreferenciasNotificacaoScreen> createState() =>
      _PreferenciasNotificacaoScreenState();
}

class _PreferenciasNotificacaoScreenState
    extends State<PreferenciasNotificacaoScreen> {
  late final PreferenciasNotificacaoStore _store;
  late PreferenciasNotificacao _preferencias;
  var _carregando = true;
  var _salvando = false;

  @override
  void initState() {
    super.initState();
    _store = widget._store ?? PreferenciasNotificacaoStore();
    _preferencias = _store.ler(widget.idUsuario);
    _carregarDaConta();
  }

  Future<void> _carregarDaConta() async {
    final id = widget.idUsuario.trim();
    try {
      if (id.isEmpty || !Get.isRegistered<FirebaseFirestore>()) return;
      final doc = await Get.find<FirebaseFirestore>().collection('usuarios').doc(id).get();
      final mapa = doc.data()?['preferencias_notificacao'];
      if (mapa is! Map || !mounted) return;
      final remota = PreferenciasNotificacao.fromMap(mapa);
      _store.salvar(id, remota);
      setState(() => _preferencias = remota);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _atualizar(PreferenciasNotificacao preferencias) async {
    if (_salvando || _carregando) return;
    setState(() {
      _preferencias = preferencias;
      _salvando = true;
    });
    _store.salvar(widget.idUsuario, preferencias);
    final id = widget.idUsuario.trim();
    EasyLoading.show(status: 'Salvando avisos...');
    try {
      if (id.isNotEmpty && Get.isRegistered<PerfilUsuarioRepository>()) {
        await Get.find<PerfilUsuarioRepository>().salvarPreferenciasNotificacao(
          idUsuario: id,
          preferencias: preferencias.toMap(),
        );
      }
    } catch (_) {
    } finally {
      await EasyLoading.dismiss();
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Get.isRegistered<EventThemeController>()
        ? Get.find<EventThemeController>()
        : null;
    final primary = tema?.primaryColor.value ?? Theme.of(context).colorScheme.primary;
    final surface = tema?.surfaceColor.value ?? const Color(0xFFF4F7F8);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: FestaSystemUi.fundoEscuro,
      child: Scaffold(
        backgroundColor: surface,
        appBar: FestaAppBar(
          titulo: 'Avisos',
          themeController: tema,
        ),
        body: _carregando
            ? const Center(child: CircularProgressIndicator())
            : ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text(
              'Escolha o que quer receber',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A escolha fica na sua conta. Convite por e-mail e avaliação por push só saem se a opção estiver ligada.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.45,
                color: const Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 16),
            _opcao(
              titulo: 'Convites',
              subtitulo: 'Confirmação de presença e novos convites',
              valor: _preferencias.convites,
              cor: primary,
              onChanged: _salvando
                  ? null
                  : (valor) => _atualizar(_preferencias.copyWith(convites: valor)),
            ),
            _opcao(
              titulo: 'Cotações',
              subtitulo: 'Pedidos de preço e respostas de fornecedores',
              valor: _preferencias.cotacoes,
              cor: primary,
              onChanged: _salvando
                  ? null
                  : (valor) => _atualizar(_preferencias.copyWith(cotacoes: valor)),
            ),
            _opcao(
              titulo: 'Chat',
              subtitulo: 'Mensagens entre organizador e fornecedor',
              valor: _preferencias.chat,
              cor: primary,
              onChanged: _salvando
                  ? null
                  : (valor) => _atualizar(_preferencias.copyWith(chat: valor)),
            ),
            _opcao(
              titulo: 'Avaliações',
              subtitulo: 'Aviso quando alguém avalia o serviço',
              valor: _preferencias.avaliacoes,
              cor: primary,
              onChanged: _salvando
                  ? null
                  : (valor) => _atualizar(_preferencias.copyWith(avaliacoes: valor)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _opcao({
    required String titulo,
    required String subtitulo,
    required bool valor,
    required Color cor,
    required ValueChanged<bool>? onChanged,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFF0E6EC)),
      ),
      child: SwitchListTile(
        value: valor,
        activeColor: cor,
        onChanged: onChanged,
        title: Text(
          titulo,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          subtitulo,
          style: GoogleFonts.poppins(fontSize: 12.5, color: const Color(0xFF6B7280)),
        ),
      ),
    );
  }
}
