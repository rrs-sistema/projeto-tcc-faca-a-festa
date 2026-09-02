import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import '../components/abrir_adicionar_convidado.dart';
import '../enviar_convites_screen.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/convidado_controller.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import '../../../../data/services/convite/enviar_convites_por_email_service.dart';
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
  final RxBool _modoSelecao = false.obs;
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

    return Obx(() {
      final modoSelecao = _modoSelecao.value;
      final totalSelecionados = _selecionados.length;

      return Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        appBar: AppBar(
          toolbarHeight: 54, // Bem mais fino
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          flexibleSpace:
              Container(decoration: BoxDecoration(gradient: gradient)),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                modoSelecao ? 'Selecionar convites' : 'Lista de convidados',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16, // Fonte reduzida
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                        blurRadius: 10,
                        color: Colors.black.withValues(alpha: 0.25)),
                  ],
                ),
              ),
              Text(
                modoSelecao
                    ? (totalSelecionados == 0
                        ? 'Toque para marcar'
                        : '$totalSelecionados selecionados')
                    : 'Confirmações e contatos',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.88),
                ),
              ),
            ],
          ),
          leading: IconButton(
            tooltip: modoSelecao ? 'Cancelar seleção' : 'Voltar',
            icon: Icon(
                modoSelecao
                    ? Icons.close_rounded
                    : Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18),
            onPressed: () {
              if (modoSelecao) {
                _sairSelecao();
                return;
              }
              Get.back();
            },
          ),
          actions: [
            if (modoSelecao)
              IconButton(
                tooltip: 'Selecionar visíveis',
                icon: const Icon(Icons.select_all_rounded,
                    color: Colors.white, size: 20),
                onPressed: _alternarSelecaoVisivel,
              )
            else ...[
              IconButton(
                tooltip: 'Selecionar para e-mail',
                icon: const Icon(Icons.checklist_rounded,
                    color: Colors.white, size: 20),
                onPressed: () => _modoSelecao.value = true,
              ),
              IconButton(
                tooltip: 'Convites',
                icon: const Icon(Icons.mark_email_read_rounded,
                    color: Colors.white, size: 20),
                onPressed: () => Get.to(() => const EnviarConvitesScreen()),
              ),
            ],
          ],
        ),
        body: SafeArea(
          top: false,
          child: _buildBody(primary),
        ),
        bottomNavigationBar:
            modoSelecao ? _buildBarraEnvioEmail(primary, gradient) : null,
        floatingActionButton: modoSelecao
            ? null
            : FloatingActionButton.extended(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 4,
                onPressed: () =>
                    abrirDialogAdicionarConvidado(context, primary),
                label: Text(
                  'Novo',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700, fontSize: 12),
                ),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
              ),
      );
    });
  }

  Widget _buildBody(Color primary) {
    return Obx(() {
      final lista = _filtrarLista(convidadoController.listaFiltrada);
      final carregando = convidadoController.carregando.value;

      return RefreshIndicator(
        color: primary,
        onRefresh: () async =>
            _carregarConvidadosDoEventoAtual(mostrarSnack: true),
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
                padding: const EdgeInsets.fromLTRB(
                    8, 0, 8, 80), // Margens ainda menores
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index.isOdd) {
                        return const SizedBox(
                            height: 6); // Menos espaço entre cards
                      }

                      final itemIndex = index ~/ 2;
                      final convidado = lista[itemIndex];

                      return Obx(() {
                        final modoSelecao = _modoSelecao.value;
                        final selecionado = _isSelecionado(convidado);
                        return _GuestCard(
                          convidado: convidado,
                          primary: primary,
                          modoSelecao: modoSelecao,
                          selecionado: selecionado,
                          onToggleSelecao: () => _toggleSelecionado(convidado),
                          onLongPress: () => _entrarSelecao(convidado),
                          onEdit: () => abrirDialogAdicionarConvidado(
                            context,
                            primary,
                            convidado: convidado,
                          ),
                          onConfirm: () => _atualizarStatus(
                              convidado, StatusConvidado.confirmado),
                          onPending: () => _atualizarStatus(
                              convidado, StatusConvidado.pendente),
                          onRefuse: () => _atualizarStatus(
                              convidado, StatusConvidado.recusado),
                          onDelete: () => _confirmarExclusao(convidado),
                        );
                      });
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

  List<Convidado> _filtrarLista(List<Convidado> listaBase) {
    if (_filtroStatus.value == 'todos') return listaBase;

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
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6), // Muito compacto
      child: Column(
        children: [
          Container(
            height: 40, // Altura reduzida para barra de pesquisa
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => controller.termoBusca.value = value,
              textInputAction: TextInputAction.search,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Buscar por nome ou contato...',
                hintStyle: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.grey.shade500),
                prefixIcon:
                    Icon(Icons.search_rounded, color: primary, size: 18),
                suffixIcon: Obx(() {
                  final termo = controller.termoBusca.value.trim();
                  if (termo.isEmpty) return const SizedBox.shrink();
                  return IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16),
                    onPressed: () {
                      _searchController.clear();
                      controller.termoBusca.value = '';
                    },
                  );
                }),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 30, // Botões de filtro extremamente finos
            child: Obx(() {
              return ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChipButton(
                      label: 'Todos',
                      icon: Icons.people_alt_rounded,
                      selected: _filtroStatus.value == 'todos',
                      color: primary,
                      onTap: () => _filtroStatus.value = 'todos'),
                  _FilterChipButton(
                      label: 'Confirmados',
                      icon: Icons.check_circle_rounded,
                      selected: _filtroStatus.value == 'confirmados',
                      color: Colors.green.shade700,
                      onTap: () => _filtroStatus.value = 'confirmados'),
                  _FilterChipButton(
                      label: 'Pendentes',
                      icon: Icons.pending_actions_rounded,
                      selected: _filtroStatus.value == 'pendentes',
                      color: Colors.orange.shade700,
                      onTap: () => _filtroStatus.value = 'pendentes'),
                  _FilterChipButton(
                      label: 'Recusados',
                      icon: Icons.cancel_rounded,
                      selected: _filtroStatus.value == 'recusados',
                      color: Colors.red.shade600,
                      onTap: () => _filtroStatus.value = 'recusados'),
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
        margin: const EdgeInsets.fromLTRB(8, 8, 8, 0), // Margens super curtas
        padding: const EdgeInsets.all(10), // Padding otimizado
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8)),
                  child:
                      Icon(Icons.fact_check_rounded, color: primary, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Painel de confirmações',
                          style: GoogleFonts.poppins(
                              fontSize: 12, // Fonte reduzida
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF111827))),
                      Text(
                          '${(progresso * 100).toStringAsFixed(0)}% da lista confirmada',
                          style: GoogleFonts.poppins(
                              fontSize: 10, color: const Color(0xFF6B7280))),
                    ],
                  ),
                ),
                Text('$confirmados/$total',
                    style: GoogleFonts.poppins(
                        color: primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 4, // Barra super fina
                value: progresso.clamp(0.0, 1.0),
                backgroundColor: primary.withValues(alpha: 0.10),
                valueColor: AlwaysStoppedAnimation<Color>(primary),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: _ResumoMiniCard(
                        'Total', total, Icons.people_alt_rounded, primary)),
                const SizedBox(width: 4),
                Expanded(
                    child: _ResumoMiniCard('Confirm.', confirmados,
                        Icons.check_circle_rounded, Colors.green.shade700)),
                const SizedBox(width: 4),
                Expanded(
                    child: _ResumoMiniCard('Pend.', pendentes,
                        Icons.pending_actions_rounded, Colors.orange.shade700)),
                const SizedBox(width: 4),
                Expanded(
                    child: _ResumoMiniCard('Recus.', recusados,
                        Icons.cancel_rounded, Colors.red.shade600)),
              ],
            ),
          ],
        ),
      );
    });
  }

  Future<void> _atualizarStatus(
      Convidado convidado, StatusConvidado status) async {
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

  Future<void> _confirmarExclusao(Convidado convidado) async {
    final confirmar = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Excluir convidado?',
            style:
                GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 15)),
        content: Text('Deseja remover ${convidado.nome} da lista?',
            style: GoogleFonts.poppins(fontSize: 12)),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancelar')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Get.back(result: true),
            icon: const Icon(Icons.delete_outline_rounded, size: 14),
            label: const Text('Excluir', style: TextStyle(fontSize: 12)),
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
    final idEvento = eventoController.eventoAtualEntidade?.idEvento;
    if (idEvento == null || idEvento.trim().isEmpty) return;
    convidadoController.escutarConvidados(idEvento);
    if (mostrarSnack) {
      _mostrarSnack('Lista atualizada', 'Convidados sincronizados com sucesso.',
          themeController.primaryColor.value);
    }
  }

  void _mostrarSnack(String titulo, String nome, Color cor) {
    Get.snackbar(
      titulo,
      nome,
      backgroundColor: cor,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(10),
      borderRadius: 10,
      duration: const Duration(seconds: 2),
    );
  }

  String _chaveConvidado(Convidado convidado) {
    final id = convidado.idConvidado.trim();
    if (id.isNotEmpty) return id;
    return 'sem_id|${convidado.nome.trim().toLowerCase()}|${convidado.email?.trim().toLowerCase() ?? ''}';
  }

  bool _isSelecionado(Convidado convidado) {
    return _selecionados.containsKey(_chaveConvidado(convidado));
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

  void _entrarSelecao(Convidado convidado) {
    _modoSelecao.value = true;
    _selecionados[_chaveConvidado(convidado)] = convidado;
    _selecionados.refresh();
  }

  void _sairSelecao() {
    _modoSelecao.value = false;
    _selecionados.clear();
  }

  void _alternarSelecaoVisivel() {
    final lista = _filtrarLista(convidadoController.listaFiltrada);
    final todos = lista.isNotEmpty && lista.every(_isSelecionado);
    if (todos) {
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

  Widget _buildBarraEnvioEmail(Color primary, LinearGradient gradient) {
    return Obx(() {
      final total = _selecionados.length;
      final comEmail =
          _selecionados.values.where((convidado) => convidado.temEmail).length;
      return Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 16,
              offset: const Offset(0, -6),
            ),
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
                      total == 0
                          ? 'Marque os convidados'
                          : '$total selecionados · $comEmail com e-mail',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (total > 0)
                    TextButton(
                      onPressed: _selecionados.clear,
                      child: const Text('Limpar',
                          style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: total == 0 ? null : _confirmarEnvioEmail,
                  icon: const Icon(Icons.email_outlined, size: 18),
                  label: Text(
                    'Enviar convite por e-mail',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _confirmarEnvioEmail() async {
    final selecionados = _selecionados.values.toList(growable: false);
    final comEmail = selecionados.where((item) => item.temEmail).length;
    final semEmail = selecionados.length - comEmail;
    if (comEmail == 0) {
      _mostrarSnack(
        'Sem e-mail',
        'Cadastre o e-mail dos convidados para enviar o convite.',
        Colors.orange.shade700,
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
    await _enviarConvitesPorEmail(selecionados);
  }

  Future<void> _enviarConvitesPorEmail(List<Convidado> selecionados) async {
    try {
      EasyLoading.show(status: 'Enviando convites...');
      final resultado =
          await convidadoController.enviarConvitesPorEmail(selecionados);
      EasyLoading.dismiss();

      if (resultado.enviados == 0) {
        _mostrarSnack(
          'Nenhum e-mail enviado',
          resultado.semEmail.isNotEmpty
              ? 'Os selecionados estão sem e-mail válido.'
              : 'Não foi possível enviar agora.',
          Colors.orange.shade700,
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
      _mostrarSnack(
        resultado.enviados == 1
            ? 'Convite enviado'
            : '${resultado.enviados} convites enviados',
        extra.isEmpty ? 'O link foi enviado por e-mail.' : extra.join(' · '),
        themeController.primaryColor.value,
      );
      _sairSelecao();
    } on EnviarConvitesPorEmailException catch (erro) {
      EasyLoading.dismiss();
      _mostrarSnack('Não enviou', erro.toString(), Colors.red.shade600);
    } catch (_) {
      EasyLoading.dismiss();
      _mostrarSnack(
        'Erro',
        'Não foi possível enviar os convites.',
        Colors.red.shade600,
      );
    }
  }
}

class _GuestCard extends StatelessWidget {
  final Convidado convidado;
  final Color primary;
  final bool modoSelecao;
  final bool selecionado;
  final VoidCallback onToggleSelecao;
  final VoidCallback onLongPress;
  final VoidCallback onEdit, onConfirm, onPending, onRefuse, onDelete;

  const _GuestCard({
    required this.convidado,
    required this.primary,
    required this.modoSelecao,
    required this.selecionado,
    required this.onToggleSelecao,
    required this.onLongPress,
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
    final initial = convidado.nome.trim().isEmpty
        ? '?'
        : convidado.nome.trim()[0].toUpperCase();
    final email = convidado.email?.trim().isNotEmpty == true
        ? convidado.email!.trim()
        : 'Sem e-mail';
    final contato = _asText(convidado.contato).trim().isNotEmpty
        ? _asText(convidado.contato).trim()
        : 'Sem contato';
    final grupo = convidado.nomeGrupo?.trim().isNotEmpty == true
        ? convidado.nomeGrupo!.trim()
        : 'Sem grupo';

    return Container(
      decoration: BoxDecoration(
        color: selecionado ? primary.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selecionado
              ? primary.withValues(alpha: 0.4)
              : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: modoSelecao ? onToggleSelecao : onEdit,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(10), // Ultra compacto
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16, // Menor
                  backgroundColor: (modoSelecao && selecionado)
                      ? primary
                      : statusColor.withValues(alpha: 0.12),
                  child: modoSelecao && selecionado
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 16)
                      : Text(initial,
                          style: GoogleFonts.poppins(
                              color: statusColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 13)),
                ),
                const SizedBox(width: 8),
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
                                  fontSize: 13,
                                  color: const Color(0xFF111827)),
                            ),
                          ),
                          _StatusChip(
                              label: statusLabel,
                              color: statusColor,
                              icon: _getStatusIcon(convidado.status)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _InfoLine(icon: Icons.email_outlined, text: email),
                      if (modoSelecao && !convidado.temEmail) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Sem e-mail — será ignorado no envio',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 2),
                      _InfoLine(icon: Icons.phone_rounded, text: contato),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          _StatusChip(
                              label: grupo,
                              color: primary,
                              icon: Icons.group_outlined),
                          if (convidado.status == StatusConvidado.confirmado)
                            _StatusChip(
                                label: 'Confirmado',
                                color: Colors.green.shade700,
                                icon: Icons.verified_rounded),
                        ],
                      ),
                    ],
                  ),
                ),
                if (modoSelecao)
                  Checkbox(
                    value: selecionado,
                    activeColor: primary,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: (_) => onToggleSelecao(),
                  )
                else
                  SizedBox(
                    height:
                        24, // Limita altura da área do popup para alinhar perfeitamente
                    width: 24,
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      color: Colors.white,
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      icon: Icon(Icons.more_vert_rounded,
                          color: Colors.grey.shade600, size: 18),
                      onSelected: (value) {
                        if (value == 'editar') onEdit();
                        if (value == 'confirmar') onConfirm();
                        if (value == 'pendente') onPending();
                        if (value == 'recusar') onRefuse();
                        if (value == 'excluir') onDelete();
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                            height: 36,
                            value: 'editar',
                            child: _MenuItem(
                                icon: Icons.edit_outlined,
                                label: 'Editar',
                                color: Colors.blue.shade700)),
                        const PopupMenuDivider(height: 1),
                        PopupMenuItem(
                            height: 36,
                            value: 'confirmar',
                            child: _MenuItem(
                                icon: Icons.check_circle_outline,
                                label: 'Confirmar',
                                color: Colors.green.shade700)),
                        PopupMenuItem(
                            height: 36,
                            value: 'pendente',
                            child: _MenuItem(
                                icon: Icons.hourglass_bottom_rounded,
                                label: 'Pendente',
                                color: Colors.orange.shade700)),
                        PopupMenuItem(
                            height: 36,
                            value: 'recusar',
                            child: _MenuItem(
                                icon: Icons.cancel_outlined,
                                label: 'Recusar',
                                color: Colors.red.shade700)),
                        const PopupMenuDivider(height: 1),
                        PopupMenuItem(
                            height: 36,
                            value: 'excluir',
                            child: _MenuItem(
                                icon: Icons.delete_outline_rounded,
                                label: 'Excluir',
                                color: Colors.red.shade600)),
                      ],
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

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoLine({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: const Color(0xFF9CA3AF)), // Ícone menor
        const SizedBox(width: 4),
        Expanded(
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _StatusChip(
      {required this.label, required this.color, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 4, vertical: 2), // Chip mais justo
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      color: color, fontSize: 9, fontWeight: FontWeight.w700))),
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
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.1))),
      child: Column(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(height: 2),
          Text('$value',
              style: GoogleFonts.poppins(
                  color: color, fontSize: 12, fontWeight: FontWeight.w900)),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                  color: const Color(0xFF4B5563),
                  fontSize: 8,
                  fontWeight: FontWeight.w700)),
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
  const _FilterChipButton(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.color,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? color : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: selected ? color : Colors.black.withValues(alpha: 0.08)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: selected ? Colors.white : color),
              const SizedBox(width: 4),
              Text(label,
                  style: GoogleFonts.poppins(
                      color: selected ? Colors.white : const Color(0xFF374151),
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
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
  const _MenuItem(
      {required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(label,
            style:
                GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12)),
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
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle),
                  child: Icon(Icons.person_add_alt_1_rounded,
                      color: primary, size: 24)),
              const SizedBox(height: 10),
              Text('Nenhum convidado',
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF111827))),
              const SizedBox(height: 4),
              Text('Adicione convidados para visualizar a lista.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: const Color(0xFF6B7280))),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Adicionar', style: TextStyle(fontSize: 12)),
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
