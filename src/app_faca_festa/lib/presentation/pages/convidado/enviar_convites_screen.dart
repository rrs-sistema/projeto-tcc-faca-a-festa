import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import './../../../controllers/convidado/convidado_controller.dart';
import './../../../controllers/evento_controller.dart';
import './../../../controllers/tema/event_theme_controller.dart';
import './../../../core/utils/convite_compartilhar.dart';
import './../../../data/models/model.dart';
import './../../../data/services/convite/enviar_convites_por_email_service.dart';
import './components/abrir_adicionar_convidado.dart';

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
  final RxMap<String, Convidado> _selecionados = <String, Convidado>{}.obs;

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
              'Convites',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              'Copiar e compartilhar o link',
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: Colors.white, size: 22),
            tooltip: 'Recarregar',
            onPressed: () =>
                _carregarConvidadosDoEventoAtual(mostrarSnack: true),
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
                  child: Icon(Icons.mark_email_read_rounded,
                      color: primary, size: 20),
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
                      Text(
                          'Copie, compartilhe ou envie o link por e-mail. O convidado abre e entra na área.',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: const Color(0xFF6B7280))),
                    ],
                  ),
                ),
                _SelectionCounter(
                    selected: selecionados, total: total, color: primary),
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
            hintText: 'Buscar convidado...',
            hintStyle:
                GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade500),
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
            contentPadding:
                const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
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
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w600),
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
              label: Text(
                  todosSelecionados ? 'Limpar visíveis' : 'Selecionar visíveis',
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
            primary: primary,
            onAdd: () => abrirDialogAdicionarConvidado(context, primary));
      }

      return RefreshIndicator(
        color: primary,
        onRefresh: () async =>
            _carregarConvidadosDoEventoAtual(mostrarSnack: true),
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
                  onCopiar: () => _copiarLinks([convidado]),
                  onCompartilhar: () => _compartilharLinks([convidado]),
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
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
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
                              child: Text(
                                  '${_selecionados.length} selecionados',
                                  style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13))),
                          TextButton.icon(
                            onPressed: _selecionados.clear,
                            icon: const Icon(Icons.close_rounded,
                                size: 16, color: Colors.white),
                            label: const Text('Limpar',
                                style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.zero),
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
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12))),
                              icon: const Icon(Icons.link_rounded, size: 16),
                              label: Text('Copiar link',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13)),
                              onPressed: () => _copiarLinks(
                                _selecionados.values.toList(growable: false),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: primary,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12))),
                              icon: const Icon(Icons.share_rounded, size: 16),
                              label: Text('Compartilhar',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13)),
                              onPressed: () => _compartilharLinks(
                                _selecionados.values.toList(growable: false),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.email_outlined, size: 16),
                          label: Text(
                            'Enviar por e-mail',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          onPressed: _confirmarEnvioEmail,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : const SizedBox.shrink(key: ValueKey('empty-send-bar')),
      );
    });
  }

  List<Convidado> _listaParaEnvio() => convidadoController.listaFiltrada;

  String _chaveConvidado(Convidado convidado) {
    final id = convidado.idConvidado.trim();
    if (id.isNotEmpty) return id;

    final email = convidado.email?.trim().toLowerCase() ?? '';
    final nome = convidado.nome.trim().toLowerCase();
    final grupo = convidado.nomeGrupo?.trim().toLowerCase() ?? '';

    return 'sem_id|$nome|$email|$grupo';
  }

  bool _isSelecionado(Convidado convidado) {
    final chave = _chaveConvidado(convidado);
    return _selecionados.containsKey(chave);
  }

  void _toggleSelecionado(Convidado convidado) {
    final chave = _chaveConvidado(convidado);

    if (_selecionados.containsKey(chave)) {
      _selecionados.remove(chave);
    } else {
      _selecionados[chave] = convidado;
    }

    _selecionados.refresh();
  }

  void _alternarSelecaoVisivel({
    required List<Convidado> lista,
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

  Future<List<Convidado>> _prepararConvites(List<Convidado> convidados) async {
    if (convidados.isEmpty) return const [];
    return convidadoController.garantirLinksConvite(convidados);
  }

  Future<void> _copiarLinks(List<Convidado> convidados) async {
    final evento = eventoController.eventoAtualEntidade;
    if (evento == null || evento.idEvento.trim().isEmpty) return;
    try {
      final preparados = await _prepararConvites(convidados);
      if (preparados.isEmpty) return;

      final texto = convidadoController.textoCompartilhamento(
        convidados: preparados,
        evento: evento,
      );
      await Clipboard.setData(ClipboardData(text: texto));
      Get.snackbar(
        preparados.length == 1 ? 'Link copiado' : 'Links copiados',
        'Cole e envie pelo canal que preferir. O convidado abre o link, autentica e entra na área.',
        backgroundColor: themeController.primaryColor.value,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível copiar o link: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
    }
  }

  Future<void> _compartilharLinks(List<Convidado> convidados) async {
    final evento = eventoController.eventoAtualEntidade;
    if (evento == null || evento.idEvento.trim().isEmpty) return;
    try {
      final preparados = await _prepararConvites(convidados);
      if (preparados.isEmpty) return;

      final texto = convidadoController.textoCompartilhamento(
        convidados: preparados,
        evento: evento,
      );
      final nomeEvento =
          evento.nomeEvento.trim().isEmpty ? 'Convite' : 'Convite — ${evento.nomeEvento.trim()}';
      final resultado = await compartilharTextoConvite(
        texto: texto,
        assunto: nomeEvento,
      );
      if (resultado == ResultadoCompartilhamento.copiou) {
        Get.snackbar(
          'Link copiado',
          'O compartilhar nativo precisa de um restart do app. O texto do convite já foi copiado.',
          backgroundColor: themeController.primaryColor.value,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(12),
          borderRadius: 12,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível abrir o compartilhamento: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
    }
  }

  Future<void> _confirmarEnvioEmail() async {
    final selecionados = _selecionados.values.toList(growable: false);
    final comEmail = selecionados.where((item) => item.temEmail).length;
    final semEmail = selecionados.length - comEmail;
    if (comEmail == 0) {
      Get.snackbar(
        'Sem e-mail',
        'Cadastre o e-mail dos convidados para enviar o convite.',
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
      );
      return;
    }

    final confirmar = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Enviar convites?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        content: Text(
          semEmail == 0
              ? 'Vamos enviar o link do convite para $comEmail convidado(s) por e-mail.'
              : 'Vamos enviar para $comEmail convidado(s). $semEmail sem e-mail serão ignorados.',
          style: GoogleFonts.poppins(fontSize: 12, height: 1.4),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Get.back(result: true),
            icon: const Icon(Icons.email_outlined, size: 16),
            label: const Text('Enviar', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      EasyLoading.show(status: 'Enviando convites...');
      final resultado =
          await convidadoController.enviarConvitesPorEmail(selecionados);
      EasyLoading.dismiss();

      if (resultado.enviados == 0) {
        Get.snackbar(
          'Nenhum e-mail enviado',
          'Os selecionados estão sem e-mail válido.',
          backgroundColor: Colors.orange.shade700,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(12),
        );
        return;
      }

      final extra = <String>[];
      if (resultado.semEmail.isNotEmpty) {
        extra.add('${resultado.semEmail.length} sem e-mail');
      }
      if (resultado.falhas.isNotEmpty) {
        extra.add('${resultado.falhas.length} falharam');
      }
      Get.snackbar(
        resultado.enviados == 1
            ? 'Convite enviado'
            : '${resultado.enviados} convites enviados',
        extra.isEmpty ? 'O link foi enviado por e-mail.' : extra.join(' · '),
        backgroundColor: themeController.primaryColor.value,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
      );
      _selecionados.clear();
    } on EnviarConvitesPorEmailException catch (erro) {
      EasyLoading.dismiss();
      Get.snackbar(
        'Não enviou',
        erro.toString(),
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
    } catch (_) {
      EasyLoading.dismiss();
      Get.snackbar(
        'Erro',
        'Não foi possível enviar os convites.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
    }
  }

  Future<void> _carregarConvidadosDoEventoAtual(
      {bool mostrarSnack = false}) async {
    final idEvento = eventoController.eventoAtualEntidade?.idEvento;
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
  final Convidado convidado;
  final bool selected;
  final Color primary;
  final VoidCallback onTap;
  final VoidCallback onCopiar;
  final VoidCallback onCompartilhar;
  const _InviteGuestCard({
    super.key,
    required this.convidado,
    required this.selected,
    required this.primary,
    required this.onTap,
    required this.onCopiar,
    required this.onCompartilhar,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getCorStatus(convidado.status);
    final initial = convidado.nome.trim().isEmpty
        ? '?'
        : convidado.nome.trim()[0].toUpperCase();
    final email = convidado.email?.trim().isNotEmpty == true
        ? convidado.email!.trim()
        : 'Sem e-mail';
    final grupo = convidado.nomeGrupo?.trim().isNotEmpty == true
        ? convidado.nomeGrupo!.trim()
        : 'Sem grupo';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: selected ? primary.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: selected
                ? primary.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.04),
            width: selected ? 1.2 : 1),
        boxShadow: [
          BoxShadow(
              color: selected
                  ? primary.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.03),
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
                backgroundColor:
                    selected ? primary : statusColor.withValues(alpha: 0.12),
                child: selected
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 20)
                    : Text(initial,
                        style: GoogleFonts.poppins(
                            color: statusColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 16)),
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
                        Icon(Icons.email_outlined,
                            size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(
                            child: Text(email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: const Color(0xFF6B7280)))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _InviteChip(
                            label: grupo,
                            icon: Icons.group_outlined,
                            color: primary),
                        _InviteChip(
                            label: _getStatusLabel(convidado.status),
                            icon: _getStatusIcon(convidado.status),
                            color: statusColor),
                        _InviteChip(
                            label: convidado.contaVinculada ? 'Conta vinculada' : 'Link gerado',
                            icon: convidado.contaVinculada
                                ? Icons.verified_user_rounded
                                : Icons.link_rounded,
                            color: convidado.contaVinculada ? Colors.teal.shade700 : primary),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Copiar link',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: Icon(Icons.copy_rounded, size: 18, color: Colors.grey.shade700),
                    onPressed: onCopiar,
                  ),
                  IconButton(
                    tooltip: 'Compartilhar',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: Icon(Icons.share_rounded, size: 18, color: Colors.grey.shade700),
                    onPressed: onCompartilhar,
                  ),
                ],
              ),
              Checkbox(
                  value: selected,
                  activeColor: primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
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
  const _InviteChip(
      {required this.label, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.poppins(
                  color: color, fontSize: 9, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _SelectionCounter extends StatelessWidget {
  final int selected;
  final int total;
  final Color color;
  const _SelectionCounter(
      {required this.selected, required this.total, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text('$selected/$total',
              style: GoogleFonts.poppins(
                  color: color, fontWeight: FontWeight.w900, fontSize: 12)),
          Text('seleção',
              style: GoogleFonts.poppins(
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                  fontSize: 9)),
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
                      'Cadastre convidados para gerar o link e compartilhar.',
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
                        icon: const Icon(Icons.add_rounded, size: 17, color: Colors.white),
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
