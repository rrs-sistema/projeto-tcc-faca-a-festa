import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
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

  @override
  void initState() {
    super.initState();
    convidadoController.convidadoAtual.value = widget.convidado;
  }

  @override
  Widget build(BuildContext context) {
    final gradient = theme.gradient.value;
    final icon = theme.icon.value;
    

    final evento = widget.evento;
    final convidado = convidadoController.convidadoAtual.value;


    final titulo = evento.nomeEvento;

    final List<Widget> pages = [
      _buildInformacoesPage(evento),
      PresentesSection(evento: evento, theme: theme),
      _buildConfirmacaoPage(convidado),
      _buildTarefasPage(evento, convidado!),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                      padding: const EdgeInsets.all(8),
                      child: Icon(icon, color: Colors.white, size: 28),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.8,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
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
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => Get.find<AppController>().logout(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(Icons.logout, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      // ===========================================================
      // 💫 Corpo principal com boas-vindas + efeito de slide
      // ===========================================================
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: Obx(() {
          if (convidadoController.carregando.value) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          final nomeConvidado = widget.convidado.nome.split(' ').first;
          final mensagemBoasVindas = 'Bem-vindo(a), $nomeConvidado! 🎉';

          return Stack(
            children: [
              // 🔹 Fundo com gradiente translúcido
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

              // 🔹 Conteúdo principal com efeito slide-up
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                child: Container(
                  key: ValueKey(_selectedIndex),
                  margin: const EdgeInsets.only(top: 140),
                  decoration: BoxDecoration(
                    color: theme.secondaryColor.value.withValues(alpha: 0.95),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 15,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                        child: Column(
                          children: [
                            Text(
                              mensagemBoasVindas,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: theme.primaryColor.value,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Você foi convidado(a) para um momento especial!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(thickness: 0.8, indent: 20, endIndent: 20),
                      Expanded(child: pages[_selectedIndex]),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          children: [
                            Text(
                              'Organizado com 💕 pelo aplicativo',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '🎉 Faça a Festa',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
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

      // ===========================================================
      // 🎨 BottomBar flutuante moderna
      // ===========================================================
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewPadding.bottom > 0
              ? MediaQuery.of(context).viewPadding.bottom
              : 8,
        ),
        child: _buildAnimatedBottomBar(theme.primaryColor.value),
      ),
    );
  }

  Widget _buildAnimatedBottomBar(Color cor) {
    final gradientActive = LinearGradient(
      colors: [cor.withValues(alpha: 0.95), cor.withValues(alpha: 0.6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final itens = [
      {'icon': Icons.info_outline, 'label': 'Informações'},
      {'icon': Icons.card_giftcard, 'label': 'Presentes'},
      {'icon': Icons.event_available, 'label': 'Confirmação'},
      {'icon': Icons.task_alt_rounded, 'label': 'Tarefas'}, // 👈 nova aba
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      height: 68,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: cor.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        backgroundBlendMode: BlendMode.overlay,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(itens.length, (i) {
              final selected = _selectedIndex == i;
              final item = itens[i];

              return GestureDetector(
                onTap: () => setState(() => _selectedIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: selected ? gradientActive : null,
                    color: selected ? cor.withValues(alpha: 0.08) : Colors.transparent,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: cor.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          item['icon'] as IconData,
                          size: selected ? 30 : 25,
                          color:
                              selected ? Colors.white : Colors.grey.shade600.withValues(alpha: 0.9),
                          shadows: selected
                              ? [
                                  Shadow(
                                    color: cor.withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : [],
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: GoogleFonts.poppins(
                          fontSize: selected ? 13.0 : 11,
                          fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                          color:
                              selected ? Colors.white : Colors.grey.shade700.withValues(alpha: 0.9),
                          letterSpacing: selected ? 0.6 : 0.1,
                        ),
                        child: Text(item['label'] as String),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 🏠 Informações do Evento — layout moderno com animação
  // ============================================================
  Widget _buildInformacoesPage(EventoModel evento) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('evento').doc(evento.idEvento).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final tipo = eventoController.tipoEventoAtual.value?.nome ?? '';
        final nomeEvento = data['nome'] ?? 'Evento Especial';

        return SingleChildScrollView(
          key: const ValueKey('info'),
          padding: const EdgeInsets.fromLTRB(24, 5, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.poppins(fontSize: 22, color: Colors.black87),
                  children: [
                    if (tipo.isNotEmpty)
                      TextSpan(
                        text: '$tipo: ',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: theme.primaryColor.value,
                          fontSize: 16,
                        ),
                      ),
                    TextSpan(
                      text: nomeEvento,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
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
                        : 'local ainda não informado'),
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

  // ============================================================
  // ✅ Página de Confirmação com layout elegante
  // ============================================================
  Widget _buildConfirmacaoPage(ConvidadoModel? convidado) {
    if (convidado == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final confirmado = convidado.status == StatusConvidado.confirmado;
    final naoVai = convidado.status == StatusConvidado.recusado;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            confirmado
                ? Icons.check_circle_outline
                : naoVai
                    ? Icons.cancel_outlined
                    : Icons.event_available,
            size: 90,
            color: theme.primaryColor.value,
          ),
          const SizedBox(height: 20),
          Text(
            confirmado
                ? '🎉 Presença Confirmada'
                : naoVai
                    ? '😢 Você não poderá comparecer'
                    : 'Confirme sua presença!',
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            confirmado
                ? 'Aguardamos você com alegria! 💖'
                : naoVai
                    ? 'Sentiremos sua falta.'
                    : 'Por favor, confirme se você poderá participar.',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          if (!confirmado && !naoVai)
            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch, // 👈 faz os filhos usarem toda a largura
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                    label: const Text('Confirmar Presença'),
                    onPressed: () => convidadoController.atualizarStatusPresenca(
                        convidado, StatusConvidado.confirmado),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor.value,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 3,
                      textStyle: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Não Poderei Ir'),
                    onPressed: () => convidadoController.atualizarStatusPresenca(
                        convidado, StatusConvidado.recusado),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade800,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: GoogleFonts.poppins(fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

// ============================================================
// 🧾 Lista de Tarefas do Convidado
// ============================================================
  Widget _buildTarefasPage(EventoModel evento, ConvidadoModel convidado) {
    final primary = theme.primaryColor.value;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tarefa')
          .where('id_evento', isEqualTo: evento.idEvento)
          .where('id_responsavel', isEqualTo: convidado.idConvidado)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return _emptyState(
            icon: Icons.task_alt_rounded,
            message: 'Nenhuma tarefa atribuída 📋',
            subtitle: 'O organizador pode atribuir tarefas para você futuramente.',
          );
        }

        final tarefas =
            docs.map((d) => TarefaModel.fromMap(d.data() as Map<String, dynamic>)).toList();

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          itemCount: tarefas.length,
          itemBuilder: (context, i) {
            final tarefa = tarefas[i];
            return _tarefaCard(tarefa, primary);
          },
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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white70.withValues(alpha: 0.03),
            primary.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Cabeçalho com ícone e status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: corStatus.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Icon(iconeStatus, color: corStatus, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tarefa.titulo,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tarefa.status.label,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  color: Colors.white,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'a_fazer',
                      child: Row(
                        children: const [
                          Icon(Icons.pending_actions_rounded, color: Colors.orange, size: 20),
                          SizedBox(width: 12),
                          Text('A Fazer', style: TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'em_andamento',
                      child: Row(
                        children: const [
                          Icon(Icons.loop_rounded, color: Colors.blueAccent, size: 20),
                          SizedBox(width: 12),
                          Text('Em Andamento', style: TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'concluida',
                      child: Row(
                        children: const [
                          Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                          SizedBox(width: 12),
                          Text('Concluída', style: TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                  icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade800),
                )
              ],
            ),

            const SizedBox(height: 10),

            // 📝 Descrição
            if (tarefa.descricao?.isNotEmpty ?? false)
              Text(
                tarefa.descricao!,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),

            // 📅 Data prevista
            if (tarefa.dataPrevista != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 15, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Prazo: ${DateFormat('dd/MM/yyyy').format(tarefa.dataPrevista!)}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
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

      Get.snackbar(
        'Tarefa atualizada!',
        'Status definido como: ${status.label}',
        backgroundColor: Colors.green.withValues(alpha: 0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível atualizar a tarefa.',
        backgroundColor: Colors.redAccent.withValues(alpha: 0.85),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ============================================================
  // 🔹 Auxiliares visuais
  // ============================================================
  Widget _infoTile(IconData icon, String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Icon(icon, color: theme.primaryColor.value),
        title: Text(title,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black87)),
        subtitle:
            Text(value, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade800)),
      ),
    );
  }

  Widget _infoTileDataHora(DateTime? data, String? hora) {
    final color = theme.primaryColor.value;
    final dateFormat = DateFormat('dd/MM/yyyy');

    final dataFormatada = data != null ? dateFormat.format(data) : '--/--/----';
    final horaFormatada = (hora != null && hora.isNotEmpty) ? hora : 'a definir';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: color.withValues(alpha: 0.15),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 📅 Ícone à esquerda
            Container(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(Icons.event_rounded, color: color, size: 28),
            ),
            const SizedBox(width: 14),

            // 🧾 Conteúdo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data e Hora do Evento',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // 🔹 Data e hora lado a lado
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 16, color: color.withValues(alpha: 0.8)),
                      const SizedBox(width: 6),
                      Text(
                        dataFormatada,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Icon(Icons.access_time_rounded,
                          size: 16, color: color.withValues(alpha: 0.8)),
                      const SizedBox(width: 6),
                      Text(
                        horaFormatada,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: theme.primaryColor.value.withValues(alpha: 0.8)),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 10),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54)),
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
    } else {
      Get.snackbar(
        'Erro ao abrir mapa',
        'Não foi possível abrir o aplicativo de mapas.',
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
      );
    }
  }

  Widget _infoTileComAcao(
    IconData icon,
    String titulo,
    String valor, {
    VoidCallback? onTap,
  }) {
    final color = theme.primaryColor.value;
    final gradient = theme.gradient.value;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.65),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: color.withValues(alpha: 0.1),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // 🎨 Ícone com fundo translúcido
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      gradient.colors.first.withValues(alpha: 0.12),
                      gradient.colors.last.withValues(alpha: 0.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),

              // 🧾 Texto principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        letterSpacing: 0.6,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      valor,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              // 🎯 Botão de ação
              if (onTap != null)
                Container(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.navigation_rounded, color: color, size: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
