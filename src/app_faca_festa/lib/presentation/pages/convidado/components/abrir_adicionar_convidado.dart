import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:get/get.dart';

import './../../../../controllers/convidado/grupo_convidado_controller.dart';
import './../../../../controllers/convidado/convidado_controller.dart';
import './../../../../controllers/tema/event_theme_controller.dart';
import './../../../../controllers/evento_controller.dart';
import './../../../widgets/custom_input_field.dart';
import './../../../../data/models/model.dart';

void abrirDialogAdicionarConvidado(
  BuildContext context,
  Color primary, {
  ConvidadoModel? convidado, // 🔥 Suporte à edição
}) {
  final themeController = Get.find<EventThemeController>();
  final eventoController = Get.find<EventoController>();
  final convidadoController = Get.find<ConvidadoController>();
  final grupoController = Get.find<GrupoConvidadoController>();

  final uuid = const Uuid();

  // 🔹 CONTROLADORES
  final nomeCtrl = TextEditingController(text: convidado?.nome ?? '');
  final emailCtrl = TextEditingController(text: convidado?.email ?? '');
  final telCtrl = TextEditingController(text: convidado?.contato ?? '');

  // 🔹 Estados reativos
  final RxString grupoSelecionado = (convidado?.grupoMesa ?? '').obs;
  final RxBool adulto = (convidado?.adulto ?? true).obs;
  final RxBool cuidadoEspecial = (convidado?.cuidadoEspecial ?? false).obs;

  final gradient = themeController.gradient.value;

  final bool editando = convidado != null;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.50,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controllerScroll) {
          return Container(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 28,
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: ListView(
                  controller: controllerScroll,
                  children: [
                    Center(
                      child: Icon(
                        editando ? Icons.edit : Icons.person_add_alt_1,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Center(
                      child: Text(
                        editando ? "Editar Convidado" : "Adicionar Convidado",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ------------------------- CAMPOS -------------------------
                    CustomInputField(
                      label: "Nome",
                      icon: Icons.person_outline,
                      controller: nomeCtrl,
                      color: Colors.white,
                    ),

                    CustomInputField(
                      label: "Telefone",
                      icon: Icons.phone_outlined,
                      controller: telCtrl,
                      type: InputType.phone,
                      color: Colors.white,
                    ),

                    CustomInputField(
                      label: "E-mail",
                      icon: Icons.email_outlined,
                      controller: emailCtrl,
                      type: InputType.email,
                      color: Colors.white,
                    ),

                    const SizedBox(height: 20),

                    // ---------------------- ADULTO / CRIANÇA ----------------------
                    Text(
                      "Tipo de convidado",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Obx(() {
                      return Row(
                        children: [
                          ChoiceChip(
                            label: Text("Adulto"),
                            selected: adulto.value,
                            onSelected: (_) => adulto.value = true,
                            selectedColor: primary,
                            labelStyle: TextStyle(
                              color: adulto.value ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(width: 12),
                          ChoiceChip(
                            label: Text("Criança"),
                            selected: !adulto.value,
                            onSelected: (_) => adulto.value = false,
                            selectedColor: primary,
                            labelStyle: TextStyle(
                              color: adulto.value ? Colors.black : Colors.white,
                            ),
                          ),
                        ],
                      );
                    }),

                    const SizedBox(height: 20),

                    // ---------------------- CUIDADO ESPECIAL ----------------------
                    Obx(() {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.health_and_safety, color: Colors.white),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Possui cuidado especial?",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Switch(
                              value: cuidadoEspecial.value,
                              activeColor: primary,
                              onChanged: (v) => cuidadoEspecial.value = v,
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 20),

                    // ------------------------- GRUPO -------------------------
                    Obx(() {
                      final grupos = grupoController.grupos;

                      if (grupoController.carregando.value) {
                        return const Center(child: CircularProgressIndicator());
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
                                  child: Text(
                                    g.nome,
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) => grupoSelecionado.value = v ?? '',
                      );
                    }),

                    const SizedBox(height: 24),

                    // ------------------------- BOTÃO SALVAR -------------------------
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: Text(
                          editando ? "Salvar alterações" : "Salvar",
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                        onPressed: () {
                          if (nomeCtrl.text.isEmpty) {
                            Get.snackbar("Atenção", "Informe o nome do convidado",
                                backgroundColor: Colors.redAccent, colorText: Colors.white);
                            return;
                          }

                          if (grupoSelecionado.value.isEmpty) {
                            Get.snackbar("Atenção", "Selecione um grupo",
                                backgroundColor: Colors.redAccent, colorText: Colors.white);
                            return;
                          }

                          final idEvento = eventoController.eventoAtual.value?.idEvento ?? '';

                          // ---------- EDITANDO ----------
                          if (editando) {
                            final atualizado = convidado.copyWith(
                              nome: nomeCtrl.text,
                              contato: telCtrl.text,
                              email: emailCtrl.text,
                              grupoMesa: grupoSelecionado.value,
                              adulto: adulto.value,
                              cuidadoEspecial: cuidadoEspecial.value,
                            );

                            convidadoController.atualizarConvidado(atualizado);

                            Get.back();
                            Get.snackbar(
                              'Convidado atualizado',
                              nomeCtrl.text,
                              backgroundColor: primary,
                              colorText: Colors.white,
                            );
                            return;
                          }

                          // ---------- ADICIONANDO ----------
                          final novo = ConvidadoModel(
                            idConvidado: uuid.v4(),
                            idEvento: idEvento,
                            nome: nomeCtrl.text,
                            contato: telCtrl.text,
                            email: emailCtrl.text,
                            grupoMesa: grupoSelecionado.value,
                            status: StatusConvidado.pendente,
                            adulto: adulto.value,
                            cuidadoEspecial: cuidadoEspecial.value,
                          );

                          convidadoController.adicionarNovoConvidadoLocal(novo);

                          Get.back();
                          Get.snackbar('Convidado adicionado', nomeCtrl.text,
                              backgroundColor: primary, colorText: Colors.white);
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ------------------------- CANCELAR -------------------------
                    OutlinedButton.icon(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close, color: Colors.white),
                      label: Text(
                        'Cancelar',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
