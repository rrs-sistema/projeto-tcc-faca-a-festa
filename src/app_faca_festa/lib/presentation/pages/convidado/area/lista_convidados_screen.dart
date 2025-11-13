import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../../controllers/convidado/convidado_controller.dart';
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

  final RxString _filtroStatus = 'todos'.obs;

  @override
  Widget build(BuildContext context) {
    final gradient = themeController.gradient.value;
    final primary = themeController.primaryColor.value;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      // ===========================================================
      // 🎨 APPBAR COM TEMA
      // ===========================================================
      appBar: AppBar(
        toolbarHeight: 90,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: gradient),
        ),
        title: Text(
          'Convidados do Evento',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 14,
                color: Colors.black.withValues(alpha: 0.25),
              )
            ],
          ),
        ),
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),

      body: Column(
        children: [
          _buildResumo(convidadoController, primary), // <-- passou primary
          _buildSearchAndFilter(convidadoController, primary),
          const SizedBox(height: 4),

          Expanded(
            child: Obx(() {
              final listaBase = convidadoController.listaFiltrada;

              final lista = _filtroStatus.value == 'todos'
                  ? listaBase
                  : listaBase.where((c) {
                      switch (_filtroStatus.value) {
                        case 'confirmados':
                          return c.status == StatusConvidado.confirmado;
                        case 'pendentes':
                          return c.status == StatusConvidado.pendente;
                        case 'recusados':
                          return c.status == StatusConvidado.recusado;
                        default:
                          return true;
                      }
                    }).toList();

              if (convidadoController.carregando.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (lista.isEmpty) {
                return Center(
                  child: Text(
                    'Nenhum convidado encontrado.',
                    style: GoogleFonts.poppins(
                      color: Colors.black54,
                      fontSize: 15,
                    ),
                  ),
                );
              }

              // ===========================================================
              // 🧾 LISTA DE CONVIDADOS COM TEMA
              // ===========================================================
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 55),
                itemCount: lista.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final convidado = lista[index];
                  final corStatus = _getCorStatus(convidado.status);

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border(
                        left: BorderSide(
                          color: corStatus,
                          width: 6,
                        ),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),

                      // =======================================================
                      // 🎭 AVATAR ELEGANTE
                      // =======================================================
                      leading: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: primary, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: corStatus.withValues(alpha: 0.15),
                          child: Icon(Icons.person_rounded, color: corStatus),
                        ),
                      ),

                      // =======================================================
                      // ✏️ NOME + INFO
                      // =======================================================
                      title: Text(
                        convidado.nome,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 15.5,
                          color: Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        '${convidado.email ?? 'Sem e-mail'} • ${convidado.contato}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),

                      // =======================================================
                      // ⋮ MENU COM TEMA
                      // =======================================================
                      trailing: PopupMenuButton<String>(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                        onSelected: (value) async {
                          switch (value) {
                            case 'confirmar':
                              await convidadoController.atualizarStatus(
                                convidado.idConvidado,
                                StatusConvidado.confirmado,
                              );
                              _mostrarSnack('Convidado confirmado', convidado.nome, Colors.green);
                              break;

                            case 'pendente':
                              await convidadoController.atualizarStatus(
                                convidado.idConvidado,
                                StatusConvidado.pendente,
                              );
                              _mostrarSnack('Marcado como pendente', convidado.nome, Colors.orange);
                              break;

                            case 'recusar':
                              await convidadoController.atualizarStatus(
                                convidado.idConvidado,
                                StatusConvidado.recusado,
                              );
                              _mostrarSnack('Convite recusado', convidado.nome, Colors.redAccent);
                              break;

                            case 'excluir':
                              await convidadoController.excluirConvidado(convidado.idConvidado);
                              _mostrarSnack('Convidado excluído', convidado.nome, Colors.red);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'confirmar',
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_outline, color: Colors.green.shade700),
                                const SizedBox(width: 8),
                                const Text('Confirmar presença'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'pendente',
                            child: Row(
                              children: [
                                Icon(Icons.hourglass_bottom, color: Colors.orange.shade700),
                                const SizedBox(width: 8),
                                const Text('Marcar como pendente'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'recusar',
                            child: Row(
                              children: [
                                Icon(Icons.cancel_outlined, color: Colors.red.shade700),
                                const SizedBox(width: 8),
                                const Text('Recusar convite'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'excluir',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, color: Colors.redAccent.shade200),
                                const SizedBox(width: 8),
                                const Text('Excluir convidado'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // 🔍 BUSCA + FILTRO COM TEMA
  // ===============================================================
  Widget _buildSearchAndFilter(ConvidadoController controller, Color primary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 7,
            child: TextField(
              onChanged: (value) => controller.termoBusca.value = value,
              decoration: InputDecoration(
                hintText: 'Buscar por nome ou e-mail...',
                prefixIcon: Icon(Icons.search_rounded, color: primary),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: primary.withValues(alpha: 0.2)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            flex: 4,
            child: Obx(() {
              return DropdownButtonFormField<String>(
                value: _filtroStatus.value,
                isExpanded: true,
                icon: Icon(Icons.filter_alt_rounded, color: primary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: primary.withValues(alpha: 0.2)),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'todos', child: Text('Todos')),
                  DropdownMenuItem(value: 'confirmados', child: Text('Confirmados')),
                  DropdownMenuItem(value: 'pendentes', child: Text('Pendentes')),
                  DropdownMenuItem(value: 'recusados', child: Text('Recusados')),
                ],
                onChanged: (value) => _filtroStatus.value = value ?? 'todos',
              );
            }),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // 📊 RESUMO COM TEMA
  // ===============================================================
  Widget _buildResumo(ConvidadoController controller, Color primary) {
    return Obx(() {
      final total = controller.totalConvidados;
      final confirmados = controller.totalConfirmados;
      final pendentes = controller.totalPendentes;
      final recusados = controller.totalRecusados;

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primary.withValues(alpha: 0.14),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _resumoCard("✔ Confirmados", confirmados, Colors.green.shade700),
            _resumoCard("⏳ Pendentes", pendentes, Colors.orange.shade700),
            _resumoCard("❌ Recusados", recusados, Colors.red.shade700),
            _resumoCard("👥 Total", total, primary),
          ],
        ),
      );
    });
  }

  Widget _resumoCard(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          "$value",
          style: GoogleFonts.poppins(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ===============================================================
  // 🎨 COR POR STATUS
  // ===============================================================
  Color _getCorStatus(StatusConvidado status) {
    switch (status) {
      case StatusConvidado.confirmado:
        return Colors.green.shade600;
      case StatusConvidado.pendente:
        return Colors.orange.shade600;
      case StatusConvidado.recusado:
        return Colors.red.shade600;
    }
  }

  // ===============================================================
  // 🍰 SNACK
  // ===============================================================
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
