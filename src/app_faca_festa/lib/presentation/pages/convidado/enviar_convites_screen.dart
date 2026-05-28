import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../controllers/convidado/convidado_controller.dart';
import './../../../controllers/tema/event_theme_controller.dart';
import './../../../controllers/evento_controller.dart';
import './components/abrir_adicionar_convidado.dart';
import './../../../data/models/model.dart';

class EnviarConvitesScreen extends StatefulWidget {
  const EnviarConvitesScreen({super.key});

  @override
  State<EnviarConvitesScreen> createState() => _EnviarConvitesScreenState();
}

class _EnviarConvitesScreenState extends State<EnviarConvitesScreen> {
  final themeController = Get.find<EventThemeController>();
  final eventoController = Get.find<EventoController>();
  final convidadoController = Get.find<ConvidadoController>();

  final TextEditingController _searchController = TextEditingController();
  final RxList<ConvidadoModel> _selecionados = <ConvidadoModel>[].obs;

  @override
  void initState() {
    super.initState();
    _carregarConvidadosDoEventoAtual();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = themeController.gradient.value;
    final primary = themeController.primaryColor.value;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        toolbarHeight: 86,
        automaticallyImplyLeading: false,
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enviar convites',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 14,
                    color: Colors.black.withValues(alpha: 0.25),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Selecione os convidados e escolha o canal de envio',
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Recarregar lista',
            onPressed: () => _carregarConvidadosDoEventoAtual(mostrarSnack: true),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildInviteHeader(primary),
          _buildSearchBar(primary),
          _buildSelectionActions(primary),
          Expanded(child: _buildGuestList(primary)),
        ],
      ),
      bottomNavigationBar: _buildBottomSendBar(primary, gradient),
      floatingActionButton: Obx(() {
        if (_selecionados.isNotEmpty) return const SizedBox.shrink();

        return FloatingActionButton.extended(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 8,
          onPressed: () => abrirDialogAdicionarConvidado(context, primary),
          label: Text(
            'Novo convidado',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
          icon: const Icon(Icons.person_add_alt_1_rounded),
        );
      }),
    );
  }

  Widget _buildInviteHeader(Color primary) {
    return Obx(() {
      final lista = _listaParaEnvio();
      final total = lista.length;
      final selecionados = _selecionados.length;
      final progresso = total == 0 ? 0.0 : selecionados / total;

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.mark_email_read_rounded, color: primary, size: 27),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Convite digital do evento',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Marque os convidados que receberão o convite e envie em lote.',
                        style: GoogleFonts.poppins(
                          fontSize: 12.4,
                          height: 1.35,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                _SelectionCounter(
                  selected: selecionados,
                  total: total,
                  color: primary,
                ),
              ],
            ),
            const SizedBox(height: 13),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: progresso.clamp(0.0, 1.0),
                backgroundColor: primary.withValues(alpha: 0.10),
                valueColor: AlwaysStoppedAnimation<Color>(primary),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSearchBar(Color primary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Buscar convidado para envio...',
            hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade500),
            prefixIcon: Icon(Icons.search_rounded, color: primary),
            suffixIcon: Obx(() {
              final termo = convidadoController.termoBusca.value.trim();
              if (termo.isEmpty) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'Limpar busca',
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  _searchController.clear();
                  convidadoController.termoBusca.value = '';
                },
              );
            }),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (query) => convidadoController.termoBusca.value = query,
        ),
      ),
    );
  }

  Widget _buildSelectionActions(Color primary) {
    return Obx(() {
      final lista = _listaParaEnvio();
      final totalVisivel = lista.length;
      final totalSelecionado = _selecionados.length;
      final todosSelecionados = totalVisivel > 0 && lista.every(_isSelecionado);

      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                totalSelecionado == 0
                    ? '$totalVisivel convidados disponíveis para envio'
                    : '$totalSelecionado selecionados para envio',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: totalVisivel == 0
                  ? null
                  : () {
                      if (todosSelecionados) {
                        for (final convidado in lista) {
                          _selecionados
                              .removeWhere((item) => item.idConvidado == convidado.idConvidado);
                        }
                      } else {
                        for (final convidado in lista) {
                          if (!_isSelecionado(convidado)) {
                            _selecionados.add(convidado);
                          }
                        }
                      }
                      _selecionados.refresh();
                    },
              icon: Icon(
                todosSelecionados ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                size: 18,
              ),
              label: Text(todosSelecionados ? 'Limpar visíveis' : 'Selecionar visíveis'),
              style: TextButton.styleFrom(foregroundColor: primary),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildGuestList(Color primary) {
    return Obx(() {
      final lista = _listaParaEnvio();

      if (convidadoController.carregando.value) {
        return Center(child: CircularProgressIndicator(color: primary));
      }

      if (lista.isEmpty) {
        return _EmptyInviteState(
          primary: primary,
          onAdd: () => abrirDialogAdicionarConvidado(context, primary),
        );
      }

      return RefreshIndicator(
        color: primary,
        onRefresh: () async => _carregarConvidadosDoEventoAtual(mostrarSnack: true),
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 130),
          itemCount: lista.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final convidado = lista[index];
            final selecionado = _isSelecionado(convidado);

            return _InviteGuestCard(
              convidado: convidado,
              selected: selecionado,
              primary: primary,
              onTap: () => _toggleSelecionado(convidado),
            );
          },
        ),
      );
    });
  }

  Widget _buildBottomSendBar(Color primary, LinearGradient gradient) {
    return Obx(() {
      final temSelecionados = _selecionados.isNotEmpty;

      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: temSelecionados
            ? Container(
                key: const ValueKey('send-bar'),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 18,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.only(top: 12, left: 18, right: 18, bottom: 18),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${_selecionados.length} convidados selecionados',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _selecionados.clear,
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: const Text('Limpar'),
                            style: TextButton.styleFrom(foregroundColor: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: primary,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape:
                                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              icon: const Icon(Icons.email_outlined),
                              label: Text(
                                'E-mail',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
                              ),
                              onPressed: () => _confirmarEnvio('por E-mail'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: primary,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape:
                                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              icon: const Icon(Icons.sms_outlined),
                              label: Text(
                                'SMS',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
                              ),
                              onPressed: () => _confirmarEnvio('por SMS'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            : const SizedBox.shrink(key: ValueKey('empty-send-bar')),
      );
    });
  }

  List<ConvidadoModel> _listaParaEnvio() {
    return convidadoController.listaFiltrada;
  }

  bool _isSelecionado(ConvidadoModel convidado) {
    return _selecionados.any((item) => item.idConvidado == convidado.idConvidado);
  }

  void _toggleSelecionado(ConvidadoModel convidado) {
    if (_isSelecionado(convidado)) {
      _selecionados.removeWhere((item) => item.idConvidado == convidado.idConvidado);
    } else {
      _selecionados.add(convidado);
    }
    _selecionados.refresh();
  }

  Future<void> _confirmarEnvio(String tipo) async {
    if (_selecionados.isEmpty) {
      Get.snackbar(
        'Nenhum convidado selecionado',
        'Selecione ao menos um convidado para enviar o convite.',
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final confirmar = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Enviar convites $tipo?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Você está prestes a enviar convites para ${_selecionados.length} convidados selecionados.',
          style: GoogleFonts.poppins(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: themeController.primaryColor.value,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => Get.back(result: true),
            icon: const Icon(Icons.send_rounded, size: 18),
            label: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _executarEnvio(tipo);
    }
  }

  Future<void> _executarEnvio(String tipo) async {
    final evento = eventoController.eventoAtual.value;

    if (evento == null || evento.idEvento.trim().isEmpty) {
      Get.snackbar(
        'Evento não encontrado',
        'Selecione um evento antes de enviar os convites.',
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final selecionados = List<ConvidadoModel>.from(_selecionados);

    try {
      await convidadoController.enviarConvitesSelecionados(
        convidadosSelecionados: selecionados,
        evento: evento,
        tipoEnvio: tipo,
      );

      final nomes = selecionados.map((c) => c.nome).join(', ');

      Get.snackbar(
        'Convites $tipo enviados!',
        'Enviados para: $nomes',
        backgroundColor: themeController.primaryColor.value,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
        duration: const Duration(seconds: 3),
      );

      _selecionados.clear();
    } catch (e) {
      Get.snackbar(
        'Erro ao enviar',
        'Não foi possível enviar os convites: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
      );
    }
  }

  Future<void> _carregarConvidadosDoEventoAtual({
    bool mostrarSnack = false,
  }) async {
    final idEvento = eventoController.eventoAtual.value?.idEvento;

    if (idEvento == null || idEvento.trim().isEmpty) {
      return;
    }

    await convidadoController.escutarConvidados(idEvento);

    if (mostrarSnack) {
      Get.snackbar(
        'Atualizado',
        'Lista de convidados sincronizada.',
        backgroundColor: themeController.primaryColor.value,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
      );
    }
  }
}

class _InviteGuestCard extends StatelessWidget {
  final ConvidadoModel convidado;
  final bool selected;
  final Color primary;
  final VoidCallback onTap;

  const _InviteGuestCard({
    required this.convidado,
    required this.selected,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getCorStatus(convidado.status);
    final initial = convidado.nome.trim().isEmpty ? '?' : convidado.nome.trim()[0].toUpperCase();
    final email =
        convidado.email?.trim().isNotEmpty == true ? convidado.email!.trim() : 'Sem e-mail';
    final grupo = convidado.nomeGrupo?.trim().isNotEmpty == true
        ? convidado.nomeGrupo!.trim()
        : 'Sem grupo definido';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: selected ? primary.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: selected ? primary.withValues(alpha: 0.45) : Colors.black.withValues(alpha: 0.04),
          width: selected ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                selected ? primary.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? primary : statusColor.withValues(alpha: 0.12),
                  ),
                  child: Center(
                    child: selected
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 26)
                        : Text(
                            initial,
                            style: GoogleFonts.poppins(
                              color: statusColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        convidado.nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(Icons.email_outlined, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 12.2,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 7,
                        runSpacing: 6,
                        children: [
                          _InviteChip(label: grupo, icon: Icons.group_outlined, color: primary),
                          _InviteChip(
                              label: _getStatusLabel(convidado.status),
                              icon: _getStatusIcon(convidado.status),
                              color: statusColor),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Checkbox(
                  value: selected,
                  activeColor: primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  onChanged: (_) => onTap(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InviteChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _InviteChip({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 10.8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionCounter extends StatelessWidget {
  final int selected;
  final int total;
  final Color color;

  const _SelectionCounter({required this.selected, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$selected/$total',
            style: GoogleFonts.poppins(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          Text(
            'seleção',
            style: GoogleFonts.poppins(
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyInviteState extends StatelessWidget {
  final Color primary;
  final VoidCallback onAdd;

  const _EmptyInviteState({required this.primary, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.mark_email_unread_rounded, color: primary, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhum convidado disponível',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Cadastre convidados para iniciar o envio dos convites digitais do evento.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12.8,
                  height: 1.45,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: onAdd,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Adicionar convidado'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _getCorStatus(StatusConvidado status) {
  switch (status) {
    case StatusConvidado.confirmado:
      return Colors.green.shade700;
    case StatusConvidado.pendente:
      return Colors.orange.shade700;
    case StatusConvidado.recusado:
      return Colors.red.shade600;
  }
}

String _getStatusLabel(StatusConvidado status) {
  switch (status) {
    case StatusConvidado.confirmado:
      return 'Confirmado';
    case StatusConvidado.pendente:
      return 'Pendente';
    case StatusConvidado.recusado:
      return 'Recusou';
  }
}

IconData _getStatusIcon(StatusConvidado status) {
  switch (status) {
    case StatusConvidado.confirmado:
      return Icons.check_circle_rounded;
    case StatusConvidado.pendente:
      return Icons.pending_actions_rounded;
    case StatusConvidado.recusado:
      return Icons.cancel_rounded;
  }
}
