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

          final nomeConvidado = widget.convidado.nome.split(' ').first;
          final mensagemBoasVindas = 'Bem-vindo(a), $nomeConvidado! 🎉';

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
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewPadding.bottom > 0
              ? MediaQuery.of(context).viewPadding.bottom
              : 0, // 🔹 Sem padding desnecessário em Androids com barra nativa fina
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
      {'icon': Icons.info_outline, 'label': 'Infos'}, // 🔹 Texto encurtado
      {'icon': Icons.card_giftcard, 'label': 'Presentes'},
      {'icon': Icons.event_available, 'label': 'Confirmação'},
      {'icon': Icons.task_alt_rounded, 'label': 'Tarefas'},
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      height: 56, // 🔹 Extremamente fina (era 68)
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: cor.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        backgroundBlendMode: BlendMode.overlay,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // 🔹 Compacto
                  decoration: BoxDecoration(
                    gradient: selected ? gradientActive : null,
                    color: selected ? cor.withValues(alpha: 0.08) : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          item['icon'] as IconData,
                          size: selected ? 22 : 20, // 🔹 Ícones menores
                          color:
                              selected ? Colors.white : Colors.grey.shade600.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: GoogleFonts.poppins(
                          fontSize: selected ? 10.0 : 9.0, // 🔹 Fonte menor
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color:
                              selected ? Colors.white : Colors.grey.shade700.withValues(alpha: 0.9),
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

    final confirmado = convidado.status == StatusConvidado.confirmado;
    final naoVai = convidado.status == StatusConvidado.recusado;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16), // 🔹 Compacto
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            confirmado
                ? Icons.check_circle_outline
                : naoVai
                    ? Icons.cancel_outlined
                    : Icons.event_available,
            size: 60, // 🔹 Ícone menor (era 90)
            color: theme.primaryColor.value,
          ),
          const SizedBox(height: 12),
          Text(
            confirmado
                ? '🎉 Confirmado'
                : naoVai
                    ? '😢 Não comparecerá'
                    : 'Sua Presença',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            confirmado
                ? 'Aguardamos você com alegria! 💖'
                : naoVai
                    ? 'Sentiremos sua falta.'
                    : 'Por favor, confirme se poderá participar.',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (!confirmado && !naoVai)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                    label: const Text('Confirmar Presença'),
                    onPressed: () => convidadoController.atualizarStatusPresenca(
                        convidado, StatusConvidado.confirmado),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor.value,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12), // 🔹 Botão mais fino
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                      textStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Não Poderei Ir'),
                    onPressed: () => convidadoController.atualizarStatusPresenca(
                        convidado, StatusConvidado.recusado),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade800,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: GoogleFonts.poppins(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
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
