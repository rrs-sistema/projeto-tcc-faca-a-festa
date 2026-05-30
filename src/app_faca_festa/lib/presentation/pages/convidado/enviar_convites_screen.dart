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
  final RxMap<String, ConvidadoModel> _selecionados = <String, ConvidadoModel>{}.obs;

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
        toolbarHeight: 68, // 🔹 Mais Fino
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
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              'Selecione e envie',
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
            tooltip: 'Recarregar',
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
          elevation: 6,
          onPressed: () async {
            FocusManager.instance.primaryFocus?.unfocus();

            await abrirDialogAdicionarConvidado(context, primary);
          },
          label: Text(
            'Novo',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          icon: const Icon(
            Icons.person_add_alt_1_rounded,
            size: 18,
          ),
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
        margin: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.mark_email_read_rounded, color: primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Convite digital',
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF111827))),
                      Text('Selecione e envie em lote.',
                          style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF6B7280))),
                    ],
                  ),
                ),
                _SelectionCounter(selected: selecionados, total: total, color: primary),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 6, // 🔹 Fino
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
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Buscar para envio...',
            hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade500),
            prefixIcon: Icon(Icons.search_rounded, color: primary, size: 20),
            suffixIcon: Obx(() {
              final termo = convidadoController.termoBusca.value.trim();
              if (termo.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () {
                  _searchController.clear();
                  convidadoController.termoBusca.value = '';
                },
              );
            }),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
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
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                totalSelecionado == 0
                    ? '$totalVisivel disponíveis'
                    : '$totalSelecionado selecionados',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: const Color(0xFF6B7280), fontWeight: FontWeight.w600),
              ),
            ),
            TextButton.icon(
              onPressed: totalVisivel == 0
                  ? null
                  : () {
                      _alternarSelecaoVisivel(
                        lista: lista,
                        todosSelecionados: todosSelecionados,
                      );
                    },
              icon: Icon(
                  todosSelecionados
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  size: 18),
              label: Text(todosSelecionados ? 'Limpar visíveis' : 'Selecionar visíveis',
                  style: const TextStyle(fontSize: 12)),
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
            primary: primary, onAdd: () => abrirDialogAdicionarConvidado(context, primary));
      }

      return RefreshIndicator(
        color: primary,
        onRefresh: () async => _carregarConvidadosDoEventoAtual(mostrarSnack: true),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 120),
          itemCount: lista.length,
          itemBuilder: (context, index) {
            final convidado = lista[index];
            final chave = _chaveConvidado(convidado);

            return Obx(() {
              final selecionado = _isSelecionado(convidado);

              return Padding(
                key: ValueKey('invite_guest_$chave'),
                padding: const EdgeInsets.only(bottom: 8), // 🔹 Compacto
                child: _InviteGuestCard(
                  key: ValueKey('invite_guest_card_$chave'),
                  convidado: convidado,
                  selected: selecionado,
                  primary: primary,
                  onTap: () => _toggleSelecionado(convidado),
                ),
              );
            });
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.16),
                        blurRadius: 18,
                        offset: const Offset(0, -8))
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: Text('${_selecionados.length} selecionados',
                                  style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13))),
                          TextButton.icon(
                            onPressed: _selecionados.clear,
                            icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                            label: const Text('Limpar', style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.white, padding: EdgeInsets.zero),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: primary,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12))),
                              icon: const Icon(Icons.email_outlined, size: 16),
                              label: Text('E-mail',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w800, fontSize: 13)),
                              onPressed: () => _confirmarEnvio('por E-mail'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: primary,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12))),
                              icon: const Icon(Icons.sms_outlined, size: 16),
                              label: Text('SMS',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w800, fontSize: 13)),
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

  List<ConvidadoModel> _listaParaEnvio() => convidadoController.listaFiltrada;

  String _chaveConvidado(ConvidadoModel convidado) {
    final id = convidado.idConvidado.trim();
    if (id.isNotEmpty) return id;

    final email = convidado.email?.trim().toLowerCase() ?? '';
    final nome = convidado.nome.trim().toLowerCase();
    final grupo = convidado.nomeGrupo?.trim().toLowerCase() ?? '';

    return 'sem_id|$nome|$email|$grupo';
  }

  bool _isSelecionado(ConvidadoModel convidado) {
    final chave = _chaveConvidado(convidado);
    return _selecionados.containsKey(chave);
  }

  void _toggleSelecionado(ConvidadoModel convidado) {
    final chave = _chaveConvidado(convidado);

    if (_selecionados.containsKey(chave)) {
      _selecionados.remove(chave);
    } else {
      _selecionados[chave] = convidado;
    }

    _selecionados.refresh();
  }

  void _alternarSelecaoVisivel({
    required List<ConvidadoModel> lista,
    required bool todosSelecionados,
  }) {
    if (todosSelecionados) {
      for (final convidado in lista) {
        _selecionados.remove(_chaveConvidado(convidado));
      }
    } else {
      for (final convidado in lista) {
        _selecionados[_chaveConvidado(convidado)] = convidado;
      }
    }

    _selecionados.refresh();
  }

  Future<void> _confirmarEnvio(String tipo) async {
    if (_selecionados.isEmpty) return;
    final confirmar = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Enviar $tipo?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Text('Deseja enviar convites para ${_selecionados.length} convidados?',
            style: GoogleFonts.poppins(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancelar')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: themeController.primaryColor.value,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () => Get.back(result: true),
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Enviar'),
          ),
        ],
      ),
    );
    if (confirmar == true) await _executarEnvio(tipo);
  }

  Future<void> _executarEnvio(String tipo) async {
    final evento = eventoController.eventoAtual.value;
    if (evento == null || evento.idEvento.trim().isEmpty) return;
    try {
      await convidadoController.enviarConvitesSelecionados(
        convidadosSelecionados: _selecionados.values.toList(growable: false),
        evento: evento,
        tipoEnvio: tipo,
      );
      Get.snackbar('Convites enviados!', 'Os convites foram disparados com sucesso.',
          backgroundColor: themeController.primaryColor.value,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(12),
          borderRadius: 12);
      _selecionados.clear();
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível enviar: $e',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(12));
    }
  }

  Future<void> _carregarConvidadosDoEventoAtual({bool mostrarSnack = false}) async {
    final idEvento = eventoController.eventoAtual.value?.idEvento;
    if (idEvento == null || idEvento.trim().isEmpty) return;
    await convidadoController.escutarConvidados(idEvento);
    if (mostrarSnack) {
      Get.snackbar('Atualizado', 'Lista sincronizada.',
          backgroundColor: themeController.primaryColor.value,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(12),
          borderRadius: 12);
    }
  }
}

class _InviteGuestCard extends StatelessWidget {
  final ConvidadoModel convidado;
  final bool selected;
  final Color primary;
  final VoidCallback onTap;
  const _InviteGuestCard(
      {super.key,
      required this.convidado,
      required this.selected,
      required this.primary,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getCorStatus(convidado.status);
    final initial = convidado.nome.trim().isEmpty ? '?' : convidado.nome.trim()[0].toUpperCase();
    final email =
        convidado.email?.trim().isNotEmpty == true ? convidado.email!.trim() : 'Sem e-mail';
    final grupo =
        convidado.nomeGrupo?.trim().isNotEmpty == true ? convidado.nomeGrupo!.trim() : 'Sem grupo';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: selected ? primary.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: selected ? primary.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.04),
            width: selected ? 1.2 : 1),
        boxShadow: [
          BoxShadow(
              color:
                  selected ? primary.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12), // 🔹 Compacto
          child: Row(
            children: [
              CircleAvatar(
                radius: 20, // 🔹 Menor
                backgroundColor: selected ? primary : statusColor.withValues(alpha: 0.12),
                child: selected
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                    : Text(initial,
                        style: GoogleFonts.poppins(
                            color: statusColor, fontWeight: FontWeight.w900, fontSize: 16)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(convidado.nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: const Color(0xFF111827))),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.email_outlined, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(
                            child: Text(email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                    fontSize: 11, color: const Color(0xFF6B7280)))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
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
              Checkbox(
                  value: selected,
                  activeColor: primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  onChanged: (_) => onTap()),
            ],
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.poppins(color: color, fontSize: 9, fontWeight: FontWeight.w800)),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text('$selected/$total',
              style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.w900, fontSize: 12)),
          Text('seleção',
              style: GoogleFonts.poppins(
                  color: const Color(0xFF6B7280), fontWeight: FontWeight.w600, fontSize: 9)),
        ],
      ),
    );
  }
}

class _EmptyInviteState extends StatelessWidget {
  final Color primary;
  final Future<void> Function() onAdd;

  const _EmptyInviteState({
    required this.primary,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Center(
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 380),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.04),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.mark_email_unread_rounded,
                        color: primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Nenhum convidado',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cadastre convidados para enviar os convites do evento.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        height: 1.25,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 38,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          FocusManager.instance.primaryFocus?.unfocus();
                          await onAdd();
                        },
                        icon: const Icon(Icons.add_rounded, size: 17),
                        label: Text(
                          'Adicionar',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
