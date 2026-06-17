import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'dart:ui';

import './../../../../controllers/convidado/convidado_controller.dart';
import './../../../../controllers/tema/event_theme_controller.dart';
import './../../../../controllers/evento_controller.dart';
import './../../../../controllers/app_controller.dart';
import './../../../widgets/confetti_background.dart';
import './../../../../data/models/model.dart';
import './presentes_section.dart';

class AreaConvidadoHomeScreen extends StatefulWidget {
  final ConvidadoModel convidado;
  final EventoModel evento;

  const AreaConvidadoHomeScreen({
    super.key,
    required this.convidado,
    required this.evento,
  });

  @override
  State<AreaConvidadoHomeScreen> createState() => _AreaConvidadoHomeScreenState();
}

class _AreaConvidadoHomeScreenState extends State<AreaConvidadoHomeScreen> {
  final convidadoController = Get.find<ConvidadoController>();
  final eventoController = Get.find<EventoController>();
  final theme = Get.find<EventThemeController>();

  int _selectedIndex = 0;
  StatusConvidado? _statusPresencaLocal;

  @override
  void initState() {
    super.initState();
    _statusPresencaLocal = widget.convidado.status;
    convidadoController.convidadoAtual.value = widget.convidado;
  }

  @override
  void didUpdateWidget(covariant AreaConvidadoHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.convidado.idConvidado != widget.convidado.idConvidado ||
        oldWidget.convidado.status != widget.convidado.status) {
      _statusPresencaLocal = widget.convidado.status;
      convidadoController.convidadoAtual.value = widget.convidado;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = theme.gradient.value;
    final icon = theme.icon.value;
    final evento = widget.evento;
    final titulo = evento.nomeEvento;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80), // 🔹 Altura reduzida (era 110)
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15), // 🔹 Sombra mais leve
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), // 🔹 Compacto
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Hero(
                    tag: 'temaIcon',
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(6), // 🔹 Ícone menor
                      child: Icon(icon, color: Colors.white, size: 22),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                        style: GoogleFonts.poppins(
                          fontSize: 15, // 🔹 Fonte menor
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.4,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.20),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          '${theme.tituloCabecalho.value} \n $titulo',
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                          maxLines: 2,
                        ),
                      ),
                    ),
                  ),
                  Tooltip(
                    message: 'Sair',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Get.find<AppController>().logout(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(6), // 🔹 Botão menor
                        child: const Icon(Icons.logout, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: Obx(() {
          if (convidadoController.carregando.value) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          final convidadoAtual = convidadoController.convidadoAtual.value ?? widget.convidado;
          final nomeConvidado = convidadoAtual.nome.split(' ').first;
          final mensagemBoasVindas = 'Bem-vindo(a), $nomeConvidado! 🎉';

          final pages = [
            _buildInformacoesPage(evento),
            PresentesSection(evento: evento, theme: theme),
            _buildConfirmacaoPage(convidadoAtual),
            _buildTarefasPage(evento, convidadoAtual),
          ];

          return Stack(
            children: [
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: 1,
                  duration: const Duration(milliseconds: 600),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          gradient.colors.first.withValues(alpha: 0.8),
                          gradient.colors.last.withValues(alpha: 0.6),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                child: Container(
                  key: ValueKey(_selectedIndex),
                  margin: const EdgeInsets.only(top: 100), // 🔹 Subiu a tela (era 140)
                  decoration: BoxDecoration(
                    color: theme.secondaryColor.value.withValues(alpha: 0.95),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)), // 🔹 Raio menor
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6), // 🔹 Compacto
                        child: Column(
                          children: [
                            Text(
                              mensagemBoasVindas,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 14, // 🔹 Fonte menor
                                fontWeight: FontWeight.w700,
                                color: theme.primaryColor.value,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Você foi convidado(a) para um momento especial!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 12, // 🔹 Fonte menor
                                color: Colors.grey.shade700,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(thickness: 0.5, indent: 16, endIndent: 16),
                      Expanded(child: pages[_selectedIndex]),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6), // 🔹 Compacto
                        child: Column(
                          children: [
                            Text(
                              'Organizado com 💕 pelo aplicativo',
                              style: GoogleFonts.poppins(
                                fontSize: 10, // 🔹 Fonte menor
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '🎉 Faça a Festa',
                              style: GoogleFonts.poppins(
                                fontSize: 13, // 🔹 Fonte menor
                                fontWeight: FontWeight.w700,
                                color: theme.primaryColor.value,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ConfettiBackground(seconds: 30),
            ],
          );
        }),
      ),
      bottomNavigationBar: _buildAnimatedBottomBar(theme.primaryColor.value),
    );
  }

  Widget _buildAnimatedBottomBar(Color cor) {
    final itens = [
      {'icon': Icons.celebration_rounded, 'label': 'Evento'},
      {'icon': Icons.card_giftcard_rounded, 'label': 'Presentes'},
      {'icon': Icons.how_to_reg_rounded, 'label': 'Presença'},
      {'icon': Icons.task_alt_rounded, 'label': 'Tarefas'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 26,
            spreadRadius: 0,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: 76,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: cor.withValues(alpha: 0.18),
                  width: 1.1,
                ),
              ),
              child: Row(
                children: List.generate(itens.length, (i) {
                  final selected = _selectedIndex == i;
                  final item = itens[i];

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(22),
                          splashColor: cor.withValues(alpha: 0.10),
                          highlightColor: cor.withValues(alpha: 0.06),
                          onTap: () => setState(() => _selectedIndex = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            height: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: selected
                                  ? LinearGradient(
                                      colors: [
                                        cor.withValues(alpha: 1),
                                        cor.withValues(alpha: 0.78),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: selected ? null : Colors.transparent,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: selected
                                    ? Colors.white.withValues(alpha: 0.45)
                                    : Colors.transparent,
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: cor.withValues(alpha: 0.28),
                                        blurRadius: 14,
                                        offset: const Offset(0, 6),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOutCubic,
                                  width: selected ? 30 : 28,
                                  height: selected ? 30 : 28,
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? Colors.white.withValues(alpha: 0.18)
                                        : cor.withValues(alpha: 0.10),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    item['icon'] as IconData,
                                    size: selected ? 20 : 19,
                                    color: selected ? Colors.white : cor.withValues(alpha: 0.92),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOutCubic,
                                  style: GoogleFonts.poppins(
                                    fontSize: selected ? 11.2 : 10.4,
                                    height: 1.0,
                                    fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                                    color: selected ? Colors.white : Colors.grey.shade800,
                                    letterSpacing: selected ? 0.1 : 0,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  child: Text(item['label'] as String),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInformacoesPage(EventoModel evento) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('evento').doc(evento.idEvento).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final tipo = eventoController.tipoEventoAtual.value?.nome ?? '';
        final nomeEvento = data['nome'] ?? 'Evento Especial';

        return SingleChildScrollView(
          key: const ValueKey('info'),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16), // 🔹 Compacto
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87), // 🔹 Menor
                  children: [
                    if (tipo.isNotEmpty)
                      TextSpan(
                        text: '$tipo: ',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: theme.primaryColor.value,
                          fontSize: 14,
                        ),
                      ),
                    TextSpan(
                      text: nomeEvento,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _infoTileDataHora(
                data['data'] is Timestamp ? (data['data'] as Timestamp).toDate() : null,
                data['hora'],
              ),
              _infoTileComAcao(
                Icons.location_on,
                'Local',
                evento.localEvento.isNotEmpty
                    ? evento.localEvento
                    : (evento.logradouro?.isNotEmpty == true
                        ? '${evento.logradouro}, ${evento.numero ?? ''}'
                        : 'Local a definir'),
                onTap: () => _abrirNoMapa(evento),
              ),
              _infoTile(Icons.message, 'Mensagem',
                  data['mensagem'] ?? 'Prepare-se para uma celebração especial! 💖'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConfirmacaoPage(ConvidadoModel? convidado) {
    if (convidado == null) return const Center(child: CircularProgressIndicator());

    // VERSÃO PREMIUM V2 - resposta sempre editável pelo convidado.
    final primary = theme.primaryColor.value;
    final statusAtual = _statusPresencaLocal ?? convidado.status;
    final confirmado = statusAtual == StatusConvidado.confirmado;
    final naoVai = statusAtual == StatusConvidado.recusado;
    final aguardando = !confirmado && !naoVai;

    final statusColor = confirmado
        ? Colors.green.shade600
        : naoVai
            ? Colors.redAccent.shade400
            : primary;

    final statusIcon = confirmado
        ? Icons.verified_rounded
        : naoVai
            ? Icons.event_busy_rounded
            : Icons.favorite_border_rounded;

    final statusLabel = confirmado
        ? 'Presença confirmada'
        : naoVai
            ? 'Ausência informada'
            : 'Aguardando resposta';

    final statusMessage = confirmado
        ? 'Que alegria! Sua presença está confirmada para este momento especial.'
        : naoVai
            ? 'Tudo certo. Se mudar de ideia, você pode confirmar presença agora.'
            : 'Responda abaixo para ajudar o organizador a preparar tudo com carinho.';

    return ListView(
      key: ValueKey('confirmacao_premium_v2_${statusAtual.name}'),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 112),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                statusColor.withValues(alpha: 0.06),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: statusColor.withValues(alpha: 0.16)),
            boxShadow: [
              BoxShadow(
                color: statusColor.withValues(alpha: 0.12),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: statusColor.withValues(alpha: 0.14)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 16, color: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      statusColor.withValues(alpha: 0.98),
                      statusColor.withValues(alpha: 0.62),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.28),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(statusIcon, color: Colors.white, size: 42),
              ),
              const SizedBox(height: 16),
              Text(
                aguardando ? 'Você vai participar?' : statusLabel,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 19,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                statusMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  height: 1.45,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: primary.withValues(alpha: 0.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(Icons.touch_app_rounded, color: primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Escolha sua resposta',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Você pode alterar sua decisão a qualquer momento. O organizador receberá a resposta mais recente.',
                style: GoogleFonts.poppins(
                  fontSize: 11.6,
                  height: 1.4,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              _presencaChoiceTile(
                selected: confirmado,
                icon: Icons.celebration_rounded,
                titulo: confirmado ? 'Estou confirmado' : 'Vou participar',
                subtitulo: confirmado
                    ? 'Sua presença já está registrada'
                    : 'Confirmar minha presença no evento',
                cor: Colors.green.shade600,
                onTap: () {
                  if (confirmado) {
                    _mostrarRespostaJaSelecionada('Sua presença já está confirmada.');
                    return;
                  }

                  _confirmarAlteracaoPresenca(
                    convidado: convidado,
                    novoStatus: StatusConvidado.confirmado,
                    titulo: naoVai ? 'Mudar para confirmado?' : 'Confirmar presença?',
                    mensagem: naoVai
                        ? 'Sua resposta será atualizada de “não poderei ir” para “vou participar”.'
                        : 'O organizador será avisado que você participará do evento.',
                    textoBotao: naoVai ? 'Sim, vou participar' : 'Confirmar presença',
                    icone: Icons.celebration_rounded,
                  );
                },
              ),
              const SizedBox(height: 10),
              _presencaChoiceTile(
                selected: naoVai,
                icon: Icons.event_busy_rounded,
                titulo: naoVai ? 'Não vou participar' : 'Não poderei ir',
                subtitulo: naoVai
                    ? 'Sua ausência já está registrada'
                    : 'Avisar que não conseguirá participar',
                cor: Colors.redAccent.shade400,
                onTap: () {
                  if (naoVai) {
                    _mostrarRespostaJaSelecionada('Sua ausência já está registrada.');
                    return;
                  }

                  _confirmarAlteracaoPresenca(
                    convidado: convidado,
                    novoStatus: StatusConvidado.recusado,
                    titulo: confirmado ? 'Cancelar presença?' : 'Informar ausência?',
                    mensagem: confirmado
                        ? 'Sua resposta será atualizada de “presença confirmada” para “não poderei ir”.'
                        : 'O organizador será avisado que você não poderá participar.',
                    textoBotao: confirmado ? 'Sim, cancelar presença' : 'Não poderei ir',
                    icone: Icons.event_busy_rounded,
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: primary.withValues(alpha: 0.10)),
          ),
          child: Row(
            children: [
              Icon(Icons.sync_rounded, size: 18, color: primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  confirmado
                      ? 'Mudou de ideia? Use “Não poderei ir” para cancelar sua presença.'
                      : naoVai
                          ? 'Mudou de ideia? Use “Vou participar” para confirmar sua presença.'
                          : 'Sua resposta ajuda na organização da festa, lista de convidados e preparativos.',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    height: 1.35,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _presencaChoiceTile({
    required bool selected,
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required Color cor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    colors: [
                      cor,
                      cor.withValues(alpha: 0.78),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: selected ? null : cor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? Colors.white.withValues(alpha: 0.36) : cor.withValues(alpha: 0.16),
            ),
            boxShadow: [
              BoxShadow(
                color: cor.withValues(alpha: selected ? 0.22 : 0.07),
                blurRadius: selected ? 18 : 10,
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
                  color: selected ? Colors.white.withValues(alpha: 0.18) : Colors.white,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.20)
                        : cor.withValues(alpha: 0.10),
                  ),
                ),
                child: Icon(icon, color: selected ? Colors.white : cor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: GoogleFonts.poppins(
                        fontSize: 13.4,
                        fontWeight: FontWeight.w900,
                        color: selected ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: GoogleFonts.poppins(
                        fontSize: 11.2,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color:
                            selected ? Colors.white.withValues(alpha: 0.90) : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withValues(alpha: 0.20) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: selected ? Colors.white : cor.withValues(alpha: 0.20)),
                ),
                child: Icon(
                  selected ? Icons.check_rounded : Icons.arrow_forward_rounded,
                  color: selected ? Colors.white : cor,
                  size: selected ? 18 : 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarRespostaJaSelecionada(String mensagem) {
    Get.snackbar(
      'Resposta atual',
      mensagem,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(14),
      borderRadius: 16,
      backgroundColor: Colors.white,
      colorText: Colors.black87,
      duration: const Duration(seconds: 2),
    );
  }

  void _salvarStatusPresenca(ConvidadoModel convidado, StatusConvidado novoStatus) {
    setState(() => _statusPresencaLocal = novoStatus);
    convidadoController.atualizarStatusPresenca(convidado, novoStatus);
  }

  void _confirmarAlteracaoPresenca({
    required ConvidadoModel convidado,
    required StatusConvidado novoStatus,
    required String titulo,
    required String mensagem,
    required String textoBotao,
    required IconData icone,
  }) {
    final isConfirmando = novoStatus == StatusConvidado.confirmado;
    final actionColor = isConfirmando ? Colors.green.shade600 : Colors.redAccent.shade400;

    Get.bottomSheet(
      SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 28,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icone, color: actionColor, size: 32),
              ),
              const SizedBox(height: 14),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                mensagem,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  height: 1.45,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(icone, size: 18, color: Colors.white),
                  label: Text(textoBotao),
                  onPressed: () {
                    Get.back();
                    _salvarStatusPresenca(convidado, novoStatus);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: actionColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
                    textStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Get.back(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('Manter resposta atual'),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildTarefasPage(EventoModel evento, ConvidadoModel convidado) {
    final primary = theme.primaryColor.value;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tarefa')
          .where('id_evento', isEqualTo: evento.idEvento)
          .where('id_responsavel', isEqualTo: convidado.idConvidado)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return _emptyState(
            icon: Icons.task_alt_rounded,
            message: 'Nenhuma tarefa 📋',
            subtitle: 'O organizador pode atribuir tarefas para você futuramente.',
          );
        }

        final tarefas =
            docs.map((d) => TarefaModel.fromMap(d.data() as Map<String, dynamic>)).toList();

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80), // 🔹 Compacto
          itemCount: tarefas.length,
          itemBuilder: (context, i) => _tarefaCard(tarefas[i], primary),
        );
      },
    );
  }

  Widget _tarefaCard(TarefaModel tarefa, Color primary) {
    final corStatus = switch (tarefa.status) {
      StatusTarefa.aFazer => Colors.orange.shade400,
      StatusTarefa.emAndamento => Colors.blue.shade400,
      StatusTarefa.concluida => Colors.green.shade600,
    };
    final iconeStatus = switch (tarefa.status) {
      StatusTarefa.aFazer => Icons.pending_actions_rounded,
      StatusTarefa.emAndamento => Icons.hourglass_bottom_rounded,
      StatusTarefa.concluida => Icons.verified_rounded,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10), // 🔹 Margem reduzida
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // 🔹 Raio menor
        border: Border.all(color: primary.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12), // 🔹 Padding reduzido
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: corStatus.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Icon(iconeStatus, color: corStatus, size: 20), // 🔹 Ícone menor
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tarefa.titulo,
                        style: GoogleFonts.poppins(
                          fontSize: 14, // 🔹 Fonte menor
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        tarefa.status.label,
                        style: GoogleFonts.poppins(
                          fontSize: 11, // 🔹 Fonte menor
                          fontWeight: FontWeight.w600,
                          color: corStatus,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Alterar status',
                  onSelected: (value) => _atualizarStatusTarefa(tarefa, value),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 3,
                  color: Colors.white,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                        value: 'a_fazer', child: Text('A Fazer', style: TextStyle(fontSize: 13))),
                    const PopupMenuItem(
                        value: 'em_andamento',
                        child: Text('Em Andamento', style: TextStyle(fontSize: 13))),
                    const PopupMenuItem(
                        value: 'concluida',
                        child: Text('Concluída', style: TextStyle(fontSize: 13))),
                  ],
                  icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade600, size: 20),
                )
              ],
            ),
            if (tarefa.descricao?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Text(
                tarefa.descricao!,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700, height: 1.3),
              ),
            ],
            if (tarefa.dataPrevista != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Prazo: ${DateFormat('dd/MM/yyyy').format(tarefa.dataPrevista!)}',
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _atualizarStatusTarefa(TarefaModel tarefa, String novoStatus) async {
    final status = StatusTarefa.fromString(novoStatus);
    try {
      await FirebaseFirestore.instance
          .collection('tarefa')
          .doc(tarefa.idTarefa)
          .update({'status': status.firestoreValue});
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível atualizar a tarefa.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10), // 🔹 Compacto
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        dense: true,
        leading: Icon(icon, color: theme.primaryColor.value, size: 20),
        title: Text(title,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
        subtitle:
            Text(value, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700)),
      ),
    );
  }

  Widget _infoTileDataHora(DateTime? data, String? hora) {
    final color = theme.primaryColor.value;
    final dataFormatada = data != null ? DateFormat('dd/MM/yyyy').format(data) : '--/--/----';
    final horaFormatada = (hora != null && hora.isNotEmpty) ? hora : 'a definir';

    return Container(
      margin: const EdgeInsets.only(bottom: 10), // 🔹 Compacto
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.event_rounded, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Data e Hora',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 11, color: Colors.grey.shade600)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 14, color: color.withValues(alpha: 0.8)),
                      const SizedBox(width: 4),
                      Text(dataFormatada,
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time_rounded,
                          size: 14, color: color.withValues(alpha: 0.8)),
                      const SizedBox(width: 4),
                      Text(horaFormatada,
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState({required IconData icon, required String message, String? subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 48, color: theme.primaryColor.value.withValues(alpha: 0.6)), // 🔹 Menor
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54)),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _abrirNoMapa(EventoModel evento) async {
    final endereco = [evento.logradouro, evento.numero, evento.bairro, evento.nomeCidade, evento.uf]
        .where((e) => e != null && e.toString().trim().isNotEmpty)
        .join(', ');
    final destino = endereco.isNotEmpty
        ? endereco
        : (evento.localEvento.isNotEmpty ? evento.localEvento : 'Local do evento');
    final url = Uri.encodeFull('https://www.google.com/maps/search/?api=1&query=$destino');

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Widget _infoTileComAcao(IconData icon, String titulo, String valor, {VoidCallback? onTap}) {
    final color = theme.primaryColor.value;
    return Container(
      margin: const EdgeInsets.only(bottom: 10), // 🔹 Compacto
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36, height: 36, // 🔹 Ícone menor
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo.toUpperCase(),
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                            color: Colors.grey.shade600)),
                    const SizedBox(height: 2),
                    Text(valor,
                        style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                  ],
                ),
              ),
              if (onTap != null)
                Container(
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.navigation_rounded, color: color, size: 16),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
