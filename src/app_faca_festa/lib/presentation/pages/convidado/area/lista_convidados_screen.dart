import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../../controllers/convidado/convidado_controller.dart';
import './../../../../controllers/event_theme_controller.dart';
import './../../../../data/models/model.dart';

class ListaConvidadosScreen extends StatefulWidget {
  const ListaConvidadosScreen({super.key});

  @override
  State<ListaConvidadosScreen> createState() => _ListaConvidadosScreenState();
}

class _ListaConvidadosScreenState extends State<ListaConvidadosScreen> {
  final themeController = Get.find<EventThemeController>();
  final convidadoController = Get.find<ConvidadoController>();

  final RxString _filtroStatus = 'todos'.obs; // 🔹 Novo filtro reativo

  @override
  Widget build(BuildContext context) {
    final gradient = themeController.gradient.value;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          'Convidados do Evento',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
      ),
      body: Column(
        children: [
          _buildResumo(convidadoController),
          _buildSearchAndFilter(convidadoController),
          const SizedBox(height: 4),
          Expanded(
            child: Obx(() {
              // 🔹 Aplica filtro de status + busca
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
                    style: GoogleFonts.poppins(color: Colors.black54),
                  ),
                );
              }

              return ListView.separated(
                itemCount: lista.length,
                separatorBuilder: (_, __) => Divider(color: Colors.grey.shade300, height: 1),
                itemBuilder: (context, index) {
                  final convidado = lista[index];
                  final corStatus = _getCorStatus(convidado.status);

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(left: BorderSide(color: corStatus, width: 5)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: corStatus.withValues(alpha: 0.15),
                        child: Icon(Icons.person, color: corStatus),
                      ),
                      title: Text(
                        convidado.nome,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        '${convidado.email ?? 'Sem e-mail'} • ${convidado.contato}',
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: Colors.grey.shade700),
                        onSelected: (value) async {
                          switch (value) {
                            case 'confirmar':
                              await convidadoController.atualizarStatus(
                                  convidado.idConvidado, StatusConvidado.confirmado);
                              _mostrarSnack('Convidado confirmado', convidado.nome, Colors.green);
                              break;
                            case 'pendente':
                              await convidadoController.atualizarStatus(
                                  convidado.idConvidado, StatusConvidado.pendente);
                              _mostrarSnack('Marcado como pendente', convidado.nome, Colors.orange);
                              break;
                            case 'recusar':
                              await convidadoController.atualizarStatus(
                                  convidado.idConvidado, StatusConvidado.recusado);
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

  /// 🔹 Campo de busca + filtro de status
  Widget _buildSearchAndFilter(ConvidadoController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // 🔹 Campo de busca ocupa 70% do espaço
          Expanded(
            flex: 7,
            child: TextField(
              onChanged: (value) => controller.termoBusca.value = value,
              decoration: InputDecoration(
                hintText: 'Buscar por nome ou e-mail...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 🔹 Dropdown ocupa o espaço restante de forma segura
          Flexible(
            flex: 4,
            child: Obx(() => DropdownButtonFormField<String>(
                  value: _filtroStatus.value,
                  isExpanded: true, // 🔹 evita overflow interno do dropdown
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'todos', child: Text('Todos')),
                    DropdownMenuItem(value: 'confirmados', child: Text('Confirmados')),
                    DropdownMenuItem(value: 'pendentes', child: Text('Pendentes')),
                    DropdownMenuItem(value: 'recusados', child: Text('Recusados')),
                  ],
                  onChanged: (value) {
                    _filtroStatus.value = value ?? 'todos';
                  },
                )),
          ),
        ],
      ),
    );
  }

  /// 🔹 Resumo de convidados no topo
  Widget _buildResumo(ConvidadoController controller) {
    return Obx(() {
      final total = controller.totalConvidados;
      final confirmados = controller.totalConfirmados;
      final pendentes = controller.totalPendentes;
      final recusados = controller.totalRecusados;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _resumoItem('✔ Confirmados', confirmados, Colors.green.shade700),
              _resumoItem('⏳ Pendentes', pendentes, Colors.orange.shade700),
              _resumoItem('❌ Recusados', recusados, Colors.red.shade700),
              _resumoItem('👥 Total', total, Colors.blueGrey.shade700),
            ],
          ),
        ),
      );
    });
  }

  Widget _resumoItem(String label, int valor, Color cor) {
    return Column(
      children: [
        Text(
          "$valor",
          style: GoogleFonts.poppins(
            color: cor,
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
