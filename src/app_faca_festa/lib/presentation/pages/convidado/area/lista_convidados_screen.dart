import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../components/abrir_adicionar_convidado.dart';
import '../enviar_convites_screen.dart';
import './../../../../controllers/convidado/convidado_controller.dart';
import '../../../../controllers/evento_controller.dart';
import '../../../../controllers/tema/event_theme_controller.dart';
import './../../../../data/models/model.dart';

class ListaConvidadosScreen extends StatefulWidget {
  const ListaConvidadosScreen({super.key});

  @override
  State<ListaConvidadosScreen> createState() => _ListaConvidadosScreenState();
}

class _ListaConvidadosScreenState extends State<ListaConvidadosScreen> {
  final themeController = Get.find<EventThemeController>();
  final convidadoController = Get.find<ConvidadoController>();
  final eventoController = Get.find<EventoController>();

  final TextEditingController _searchController = TextEditingController();
  final RxString _filtroStatus = 'todos'.obs;

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
        toolbarHeight: 88,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Lista de convidados',
              style: GoogleFonts.playfairDisplay(
                fontSize: 21,
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
              'Confirmações, contatos e grupos',
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.88),
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
            tooltip: 'Enviar convites',
            icon: const Icon(Icons.mark_email_read_rounded, color: Colors.white),
            onPressed: () => Get.to(() => const EnviarConvitesScreen()),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _buildBody(primary),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 8,
        onPressed: () => abrirDialogAdicionarConvidado(context, primary),
        label: Text(
          'Novo convidado',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        icon: const Icon(Icons.person_add_alt_1_rounded),
      ),
    );
  }

  Widget _buildBody(Color primary) {
    return Obx(() {
      final lista = _filtrarLista(convidadoController.listaFiltrada);
      final carregando = convidadoController.carregando.value;

      return RefreshIndicator(
        color: primary,
        onRefresh: () async => _carregarConvidadosDoEventoAtual(mostrarSnack: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(
              child: _buildResumo(convidadoController, primary),
            ),
            SliverToBoxAdapter(
              child: _buildSearchAndFilter(convidadoController, primary),
            ),
            if (carregando)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: primary),
                ),
              )
            else if (lista.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyGuestsState(
                  primary: primary,
                  onAdd: () => abrirDialogAdicionarConvidado(context, primary),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 110),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index.isOdd) {
                        return const SizedBox(height: 10);
                      }

                      final itemIndex = index ~/ 2;
                      final convidado = lista[itemIndex];

                      return _GuestCard(
                        convidado: convidado,
                        primary: primary,
                        onEdit: () => abrirDialogAdicionarConvidado(
                          context,
                          primary,
                          convidado: convidado,
                        ),
                        onConfirm: () => _atualizarStatus(
                          convidado,
                          StatusConvidado.confirmado,
                        ),
                        onPending: () => _atualizarStatus(
                          convidado,
                          StatusConvidado.pendente,
                        ),
                        onRefuse: () => _atualizarStatus(
                          convidado,
                          StatusConvidado.recusado,
                        ),
                        onDelete: () => _confirmarExclusao(convidado),
                      );
                    },
                    childCount: lista.isEmpty ? 0 : (lista.length * 2) - 1,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  List<ConvidadoModel> _filtrarLista(List<ConvidadoModel> listaBase) {
    if (_filtroStatus.value == 'todos') {
      return listaBase;
    }

    return listaBase.where((convidado) {
      switch (_filtroStatus.value) {
        case 'confirmados':
          return convidado.status == StatusConvidado.confirmado;
        case 'pendentes':
          return convidado.status == StatusConvidado.pendente;
        case 'recusados':
          return convidado.status == StatusConvidado.recusado;
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildSearchAndFilter(ConvidadoController controller, Color primary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        children: [
          Container(
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
              onChanged: (value) => controller.termoBusca.value = value,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Buscar por nome, e-mail ou contato...',
                hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade500),
                prefixIcon: Icon(Icons.search_rounded, color: primary),
                suffixIcon: Obx(() {
                  final termo = controller.termoBusca.value.trim();
                  if (termo.isEmpty) return const SizedBox.shrink();
                  return IconButton(
                    tooltip: 'Limpar busca',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _searchController.clear();
                      controller.termoBusca.value = '';
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
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: Obx(() {
              return ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChipButton(
                    label: 'Todos',
                    icon: Icons.people_alt_rounded,
                    selected: _filtroStatus.value == 'todos',
                    color: primary,
                    onTap: () => _filtroStatus.value = 'todos',
                  ),
                  _FilterChipButton(
                    label: 'Confirmados',
                    icon: Icons.check_circle_rounded,
                    selected: _filtroStatus.value == 'confirmados',
                    color: Colors.green.shade700,
                    onTap: () => _filtroStatus.value = 'confirmados',
                  ),
                  _FilterChipButton(
                    label: 'Pendentes',
                    icon: Icons.pending_actions_rounded,
                    selected: _filtroStatus.value == 'pendentes',
                    color: Colors.orange.shade700,
                    onTap: () => _filtroStatus.value = 'pendentes',
                  ),
                  _FilterChipButton(
                    label: 'Recusados',
                    icon: Icons.cancel_rounded,
                    selected: _filtroStatus.value == 'recusados',
                    color: Colors.red.shade600,
                    onTap: () => _filtroStatus.value = 'recusados',
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildResumo(ConvidadoController controller, Color primary) {
    return Obx(() {
      final total = controller.totalConvidados;
      final confirmados = controller.totalConfirmados;
      final pendentes = controller.totalPendentes;
      final recusados = controller.totalRecusados;
      final progresso = total == 0 ? 0.0 : confirmados / total;

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(Icons.fact_check_rounded, color: primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Painel de confirmações',
                        style: GoogleFonts.poppins(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      Text(
                        '${(progresso * 100).toStringAsFixed(0)}% da lista confirmada',
                        style: GoogleFonts.poppins(
                          fontSize: 12.3,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$confirmados/$total',
                  style: GoogleFonts.poppins(
                    color: primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _ResumoMiniCard('Total', total, Icons.people_alt_rounded, primary)),
                const SizedBox(width: 8),
                Expanded(
                    child: _ResumoMiniCard('Confirmados', confirmados, Icons.check_circle_rounded,
                        Colors.green.shade700)),
                const SizedBox(width: 8),
                Expanded(
                    child: _ResumoMiniCard('Pendentes', pendentes, Icons.pending_actions_rounded,
                        Colors.orange.shade700)),
                const SizedBox(width: 8),
                Expanded(
                    child: _ResumoMiniCard(
                        'Recusados', recusados, Icons.cancel_rounded, Colors.red.shade600)),
              ],
            ),
          ],
        ),
      );
    });
  }

  Future<void> _atualizarStatus(ConvidadoModel convidado, StatusConvidado status) async {
    await convidadoController.atualizarStatus(convidado.idConvidado, status);

    final titulo = switch (status) {
      StatusConvidado.confirmado => 'Presença confirmada',
      StatusConvidado.pendente => 'Convidado pendente',
      StatusConvidado.recusado => 'Convite recusado',
    };

    final cor = switch (status) {
      StatusConvidado.confirmado => Colors.green.shade700,
      StatusConvidado.pendente => Colors.orange.shade700,
      StatusConvidado.recusado => Colors.red.shade600,
    };

    _mostrarSnack(titulo, convidado.nome, cor);
  }

  Future<void> _confirmarExclusao(ConvidadoModel convidado) async {
    final confirmar = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          'Excluir convidado?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Deseja remover ${convidado.nome} da lista de convidados?',
          style: GoogleFonts.poppins(height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Get.back(result: true),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await convidadoController.excluirConvidado(convidado.idConvidado);
      _mostrarSnack('Convidado excluído', convidado.nome, Colors.red.shade600);
    }
  }

  void _carregarConvidadosDoEventoAtual({bool mostrarSnack = false}) {
    final idEvento = eventoController.eventoAtual.value?.idEvento;
    if (idEvento == null || idEvento.trim().isEmpty) {
      return;
    }

    convidadoController.escutarConvidados(idEvento);

    if (mostrarSnack) {
      Get.snackbar(
        'Lista atualizada',
        'Convidados sincronizados com sucesso.',
        backgroundColor: themeController.primaryColor.value,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
      );
    }
  }

  void _mostrarSnack(String titulo, String nome, Color cor) {
    Get.snackbar(
      titulo,
      nome,
      backgroundColor: cor,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
      duration: const Duration(seconds: 2),
    );
  }
}

class _GuestCard extends StatelessWidget {
  final ConvidadoModel convidado;
  final Color primary;
  final VoidCallback onEdit;
  final VoidCallback onConfirm;
  final VoidCallback onPending;
  final VoidCallback onRefuse;
  final VoidCallback onDelete;

  const _GuestCard({
    required this.convidado,
    required this.primary,
    required this.onEdit,
    required this.onConfirm,
    required this.onPending,
    required this.onRefuse,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getCorStatus(convidado.status);
    final statusLabel = _getStatusLabel(convidado.status);
    final initial = convidado.nome.trim().isEmpty ? '?' : convidado.nome.trim()[0].toUpperCase();
    final email =
        convidado.email?.trim().isNotEmpty == true ? convidado.email!.trim() : 'Sem e-mail';
    final contato = _asText(convidado.contato).trim().isNotEmpty
        ? _asText(convidado.contato).trim()
        : 'Sem contato';
    final grupo = convidado.nomeGrupo?.trim().isNotEmpty == true
        ? convidado.nomeGrupo!.trim()
        : 'Sem grupo definido';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: statusColor.withValues(alpha: 0.40), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: statusColor.withValues(alpha: 0.12),
                    child: Text(
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              convidado.nome,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w800,
                                fontSize: 15.2,
                                color: const Color(0xFF111827),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusChip(
                              label: statusLabel,
                              color: statusColor,
                              icon: _getStatusIcon(convidado.status)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _InfoLine(icon: Icons.email_outlined, text: email),
                      const SizedBox(height: 5),
                      _InfoLine(icon: Icons.phone_rounded, text: contato),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _StatusChip(label: grupo, color: primary, icon: Icons.group_outlined),
                          if (convidado.status == StatusConvidado.confirmado)
                            _StatusChip(
                                label: 'Presença garantida',
                                color: Colors.green.shade700,
                                icon: Icons.verified_rounded),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  color: Colors.white,
                  elevation: 10,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade600),
                  onSelected: (value) {
                    switch (value) {
                      case 'editar':
                        onEdit();
                        break;
                      case 'confirmar':
                        onConfirm();
                        break;
                      case 'pendente':
                        onPending();
                        break;
                      case 'recusar':
                        onRefuse();
                        break;
                      case 'excluir':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'editar',
                      child: _MenuItem(
                          icon: Icons.edit_outlined,
                          label: 'Editar convidado',
                          color: Colors.blue.shade700),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'confirmar',
                      child: _MenuItem(
                          icon: Icons.check_circle_outline,
                          label: 'Confirmar presença',
                          color: Colors.green.shade700),
                    ),
                    PopupMenuItem(
                      value: 'pendente',
                      child: _MenuItem(
                          icon: Icons.hourglass_bottom_rounded,
                          label: 'Marcar como pendente',
                          color: Colors.orange.shade700),
                    ),
                    PopupMenuItem(
                      value: 'recusar',
                      child: _MenuItem(
                          icon: Icons.cancel_outlined,
                          label: 'Recusar convite',
                          color: Colors.red.shade700),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'excluir',
                      child: _MenuItem(
                          icon: Icons.delete_outline_rounded,
                          label: 'Excluir convidado',
                          color: Colors.red.shade600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 12.4,
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 10.8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumoMiniCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _ResumoMiniCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.10)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 5),
          Text(
            '$value',
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: const Color(0xFF4B5563),
              fontSize: 9.7,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? color : Colors.black.withValues(alpha: 0.08)),
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: color.withValues(alpha: 0.20),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: selected ? Colors.white : color),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: selected ? Colors.white : const Color(0xFF374151),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MenuItem({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 9),
        Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _EmptyGuestsState extends StatelessWidget {
  final Color primary;
  final VoidCallback onAdd;

  const _EmptyGuestsState({required this.primary, required this.onAdd});

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
                child: Icon(Icons.person_add_alt_1_rounded, color: primary, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhum convidado encontrado',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Adicione convidados ou ajuste os filtros para visualizar a lista do evento.',
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
                icon: const Icon(Icons.add_rounded),
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

String _asText(Object? value) => value?.toString() ?? '';
