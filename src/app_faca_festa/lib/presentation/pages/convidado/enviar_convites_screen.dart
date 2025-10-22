import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../controllers/convidado/grupo_convidado_controller.dart';
import '../../widgets/custom_input_field.dart';
import './../../../controllers/convidado/convidado_controller.dart';
import './../../../controllers/event_theme_controller.dart';
import './../../../controllers/evento_controller.dart';
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
  final _searchController = TextEditingController();
  final RxList<ConvidadoModel> _selecionados = <ConvidadoModel>[].obs;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    final idEvento = eventoController.eventoAtual.value?.idEvento;
    if (idEvento != null && idEvento.isNotEmpty) {
      convidadoController.escutarConvidados(idEvento);
    }
  }

  void _enviarConvites(String tipo) {
    if (_selecionados.isEmpty) {
      Get.snackbar('Nenhum convidado selecionado', 'Selecione ao menos um convidado.',
          backgroundColor: Colors.orangeAccent, colorText: Colors.white);
      return;
    }

    final nomes = _selecionados.map((c) => c.nome).join(', ');
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

    // 🔹 Após envio, limpa seleção
    _selecionados.clear();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = themeController.gradient.value;
    final primary = themeController.primaryColor.value;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Envio de Convites',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            tooltip: 'Recarregar lista',
            onPressed: () {
              final idEvento = eventoController.eventoAtual.value?.idEvento;
              if (idEvento != null && idEvento.isNotEmpty) {
                convidadoController.escutarConvidados(idEvento);
                Get.snackbar('Atualizado', 'Lista sincronizada com o Firebase',
                    backgroundColor: primary, colorText: Colors.white);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSearchBar(primary),
            const SizedBox(height: 16),
            Expanded(child: _buildGuestList(primary)),
          ],
        ),
      ),
      bottomNavigationBar: Obx(() {
        final temSelecionados = _selecionados.isNotEmpty;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: temSelecionados
              ? Container(
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 20),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${_selecionados.length} convidados selecionados",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: primary,
                                  elevation: 4,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: const Icon(Icons.email_outlined),
                                label: const Text("Enviar por E-mail"),
                                onPressed: () async {
                                  await convidadoController.enviarNovosConvidados();
                                  _enviarConvites("por E-mail");
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: primary,
                                  elevation: 4,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: const Icon(Icons.sms_outlined),
                                label: const Text("Enviar por SMS"),
                                onPressed: () async {
                                  await convidadoController.enviarNovosConvidados();
                                  _enviarConvites("por SMS");
                                },
                                //() => _enviarConvites("por SMS"),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        onPressed: () => _abrirDialogAdicionarConvidado(context, primary),
        label: Text(
          'Adicionar Convidado',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar(Color primary) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: "Buscar convidado...",
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (query) => convidadoController.termoBusca.value = query,
    );
  }

  Widget _buildGuestList(Color primary) {
    return Obx(() {
      final lista = convidadoController.novosConvidados; // convidados adicionados localmente
      if (lista.isEmpty) {
        return Center(
          child: Text(
            'Nenhum convidado adicionado ainda',
            style: GoogleFonts.poppins(color: Colors.black54),
          ),
        );
      }

      return ListView.separated(
        itemCount: lista.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final convidado = lista[index];
          final selecionado = _selecionados.any(
            (e) => e.idConvidado == convidado.idConvidado,
          );

          return ListTile(
            leading: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selecionado ? primary : Colors.grey.shade300,
              ),
              child: Icon(Icons.person, color: selecionado ? Colors.white : Colors.black54),
            ),
            title: Text(
              convidado.nome,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  convidado.email ?? 'Sem e-mail',
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.group_outlined, size: 13, color: Colors.teal.shade400),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        convidado.grupoMesa?.isNotEmpty == true
                            ? convidado.grupoMesa!
                            : 'Sem grupo definido',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          color: Colors.teal.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Checkbox(
              activeColor: primary,
              value: selecionado,
              onChanged: (v) {
                if (v == true) {
                  _selecionados.addIf(
                    !_selecionados.any((e) => e.idConvidado == convidado.idConvidado),
                    convidado,
                  );
                } else {
                  _selecionados.removeWhere((e) => e.idConvidado == convidado.idConvidado);
                }
                _selecionados.refresh();
              },
            ),
            onTap: () {
              if (selecionado) {
                _selecionados.removeWhere((e) => e.idConvidado == convidado.idConvidado);
              } else {
                _selecionados.add(convidado);
              }
            },
          );
        },
      );
    });
  }

  void _abrirDialogAdicionarConvidado(BuildContext context, Color primary) {
    final nomeCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    final gradient = themeController.gradient.value;
    final grupoController = Get.find<GrupoConvidadoController>();
    final RxString grupoSelecionado = ''.obs;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: Container(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Icon(Icons.person_add_alt_1, size: 40, color: Colors.white),
                    const SizedBox(height: 12),
                    Text(
                      "Adicionar Convidado",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 24),
                    CustomInputField(
                      label: "Nome",
                      icon: Icons.person_outline,
                      controller: nomeCtrl,
                      color: Colors.pinkAccent,
                    ),

                    CustomInputField(
                      label: "Telefone",
                      icon: Icons.phone_outlined,
                      controller: telCtrl,
                      color: Colors.pinkAccent,
                    ),

                    CustomInputField(
                      label: "E-mail",
                      icon: Icons.email_outlined,
                      controller: emailCtrl,
                      color: Colors.pinkAccent,
                    ),

                    // 🔹 Campo dropdown com os grupos vindos do controller
                    Obx(() {
                      final grupos = grupoController.grupos;
                      if (grupoController.carregando.value) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (grupos.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.info_outline, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                "Nenhum grupo cadastrado ainda",
                                style: GoogleFonts.poppins(color: Colors.black54, fontSize: 13),
                              ),
                            ],
                          ),
                        );
                      }

                      return DropdownButtonFormField<String>(
                        value: grupoSelecionado.value.isEmpty ? null : grupoSelecionado.value,
                        decoration: InputDecoration(
                          labelText: "Grupo / Mesa",
                          labelStyle: GoogleFonts.poppins(color: Colors.black54),
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.group_outlined, color: Colors.pinkAccent),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: grupos
                            .map((g) => DropdownMenuItem(
                                  value: g.nome,
                                  child: Text(g.nome, style: GoogleFonts.poppins(fontSize: 14)),
                                ))
                            .toList(),
                        onChanged: (v) => grupoSelecionado.value = v ?? '',
                      );
                    }),

                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 30),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: Text("Salvar", style: GoogleFonts.poppins(color: Colors.white)),
                      onPressed: () async {
                        if (nomeCtrl.text.isEmpty) {
                          Get.snackbar('Atenção', 'Informe o nome do convidado',
                              backgroundColor: Colors.redAccent, colorText: Colors.white);
                          return;
                        }

                        if (grupoSelecionado.value.isEmpty) {
                          Get.snackbar('Atenção', 'Selecione um grupo para o convidado',
                              backgroundColor: Colors.redAccent, colorText: Colors.white);
                          return;
                        }

                        final idEvento = eventoController.eventoAtual.value?.idEvento ?? '';
                        final novo = ConvidadoModel(
                          idConvidado: _uuid.v4(),
                          idEvento: idEvento,
                          nome: nomeCtrl.text,
                          contato: telCtrl.text,
                          email: emailCtrl.text,
                          grupoMesa: grupoSelecionado.value,
                          status: StatusConvidado.pendente,
                          adulto: true,
                        );

                        convidadoController.adicionarNovoConvidadoLocal(novo);
                        _selecionados.add(novo);

                        Get.back();
                        Get.snackbar('Convidado adicionado', nomeCtrl.text,
                            backgroundColor: primary, colorText: Colors.white);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
                    )
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
