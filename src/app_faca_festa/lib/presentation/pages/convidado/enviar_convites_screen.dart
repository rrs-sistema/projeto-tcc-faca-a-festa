import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../controllers/event_theme_controller.dart';
import './../../../controllers/app_controller.dart';

class EnviarConvitesScreen extends StatefulWidget {
  const EnviarConvitesScreen({super.key});

  @override
  State<EnviarConvitesScreen> createState() => _EnviarConvitesScreenState();
}

class _EnviarConvitesScreenState extends State<EnviarConvitesScreen> {
  final themeController = Get.find<EventThemeController>();
  final appController = Get.find<AppController>();
  final TextEditingController _searchController = TextEditingController();
  final RxList<Map<String, dynamic>> _convidados = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _selecionados = <Map<String, dynamic>>[].obs;

  @override
  void initState() {
    super.initState();
    _convidados.addAll([
      {'nome': 'Maria Silva', 'email': 'maria@email.com', 'telefone': '(41) 98888-1234'},
      {'nome': 'João Pereira', 'email': 'joao@email.com', 'telefone': '(41) 97777-4321'},
      {'nome': 'Fernanda Costa', 'email': 'fernanda@email.com', 'telefone': '(41) 96666-2222'},
      {'nome': 'Lucas Oliveira', 'email': 'lucas@email.com', 'telefone': '(41) 95555-1111'},
    ]);
  }

  void _simularEnvio(String tipo) {
    final nomes = _selecionados.map((e) => e['nome']).join(', ');
    Get.snackbar(
      'Convites $tipo enviados',
      'Convites enviados para: $nomes',
      backgroundColor: themeController.primaryColor.value,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradient = themeController.gradient.value;
    final primary = themeController.primaryColor.value;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Lista de Convidados',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            tooltip: 'Recarregar',
            onPressed: () => Get.snackbar(
              'Atualizado',
              'Lista de convidados atualizada com sucesso',
              backgroundColor: primary,
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
            ),
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
          transitionBuilder: (child, animation) => SizeTransition(
            sizeFactor: animation,
            axisAlignment: -1.0,
            child: child,
          ),
          child: temSelecionados
              ? Container(
                  key: const ValueKey('botoes'),
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
                    child: Row(
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
                            label: const Text(
                              "Enviar por E-mail",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            onPressed: () => _simularEnvio("por E-mail"),
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
                            label: const Text(
                              "Enviar por SMS",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            onPressed: () => _simularEnvio("por SMS"),
                          ),
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
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (context) {
              final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
              return FractionallySizedBox(
                  heightFactor: keyboardOpen ? 0.70 : 0.85, child: _buildAddGuestDialog(primary));
            },
          );
        },
        label: Text(
          'Novo Convidado',
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
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
      onChanged: (query) {
        _convidados.refresh(); // futura integração com busca real
      },
    );
  }

  /// ✅ Corrigido: seleção funciona porque agora compara por 'nome'
  Widget _buildGuestList(Color primary) {
    return Obx(() {
      if (_convidados.isEmpty) {
        return Center(
          child: Text(
            'Nenhum convidado cadastrado ainda',
            style: GoogleFonts.poppins(color: Colors.black54),
          ),
        );
      }

      return ListView.separated(
        itemCount: _convidados.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final convidado = _convidados[index];
          final selecionado = _selecionados.any((e) => e['nome'] == convidado['nome']);

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: selecionado ? primary : Colors.grey.shade300,
              child: Icon(Icons.person, color: selecionado ? Colors.white : Colors.black54),
            ),
            title: Text(convidado['nome'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            subtitle: Text(convidado['email'], style: GoogleFonts.poppins(fontSize: 13)),
            trailing: Obx(() {
              final estaSelecionado = _selecionados.any((e) => e['nome'] == convidado['nome']);
              return Checkbox(
                activeColor: primary,
                value: estaSelecionado,
                onChanged: (v) {
                  if (v == true) {
                    if (!_selecionados.any((e) => e['nome'] == convidado['nome'])) {
                      _selecionados.add(convidado);
                    }
                  } else {
                    _selecionados.removeWhere((e) => e['nome'] == convidado['nome']);
                  }

                  // 🔹 força atualização da lista (garante rebuild do item)
                  _selecionados.refresh();
                },
              );
            }),
            onTap: () {
              // ✅ permite selecionar tocando na linha também
              final jaSelecionado = _selecionados.any((e) => e['nome'] == convidado['nome']);
              if (jaSelecionado) {
                _selecionados.removeWhere((e) => e['nome'] == convidado['nome']);
              } else {
                _selecionados.add(convidado);
              }
            },
          );
        },
      );
    });
  }

  Widget _buildAddGuestDialog(Color primary) {
    final nomeCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    final gradient = themeController.gradient.value;

    return Container(
      width: double.infinity, // 🔹 agora ocupa 100% da tela
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cabeçalho com ícone e título
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person_add_alt_1,
                    color: Colors.white.withValues(alpha: 0.9), size: 40),
              ),
              const SizedBox(height: 12),
              Text(
                "Adicionar Convidado",
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 24),

              // Campos no card branco
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
                child: Column(
                  children: [
                    _buildInputField(
                      controller: nomeCtrl,
                      label: "Nome do convidado",
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: emailCtrl,
                      label: "E-mail",
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: telCtrl,
                      label: "Telefone",
                      icon: Icons.phone_outlined,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 5,
                        ),
                        onPressed: () {
                          if (nomeCtrl.text.isNotEmpty) {
                            _convidados.add({
                              'nome': nomeCtrl.text,
                              'email': emailCtrl.text,
                              'telefone': telCtrl.text,
                            });
                            Get.back();
                            Get.snackbar('Convidado adicionado', nomeCtrl.text,
                                backgroundColor: primary, colorText: Colors.white);
                          } else {
                            Get.snackbar(
                              'Preencha o nome',
                              'O campo nome é obrigatório',
                              backgroundColor: Colors.redAccent.shade200,
                              colorText: Colors.white,
                            );
                          }
                        },
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: Text(
                          'Salvar Convidado',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Botão cancelar
              TextButton.icon(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
                label: Text(
                  "Cancelar",
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔹 Campo de entrada customizado
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
        prefixIcon: Icon(icon, color: Colors.pinkAccent.shade200),
        filled: true,
        fillColor: Colors.grey.shade50,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.pink.shade300, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
