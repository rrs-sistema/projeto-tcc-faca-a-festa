// ignore_for_file: use_build_context_synchronously
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

import './../../../controllers/tema/event_theme_controller.dart';
import './../../../controllers/evento_cadastro_controller.dart';
import './../../widgets/button/botao_cancelar.dart';
import './../../widgets/button/botao_salvar.dart';
import './../../widgets/custom_input_field.dart';
import './../endereco/endereco_section.dart';
import './evento_preview_titulo_widget.dart';
import './../../../data/models/model.dart';

Future<void> showCadastroEventoBottomSheet(
  BuildContext context, {
  EventoModel? eventoParaEdicao,
}) async {
  final controller = Get.find<EventoCadastroController>();
  final theme = Get.find<EventThemeController>();
  EasyLoading.show(status: 'Carregando informações...');
  // 🔹 Carrega tipos de evento antes de abrir o formulário

  await controller.carregarTiposEvento();

  // 🔹 Se estiver editando, carrega os dados do evento
  if (eventoParaEdicao != null) {
    controller.carregarEvento(eventoParaEdicao);
  } else {
    controller.limpar(manterEndereco: true); // 👈 mantém o endereço que você setou antes
  }

  // 🔹 Define cores baseadas no tipo atual (ou padrão)
  Color corPrincipal = theme.primaryColor.value;
  Color corSecundaria = theme.secondaryColor.value.withValues(alpha: 0.03);

  final tipoNormalizado = controller.tipoEventoModel.value?.nome
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-zá-úà-ùãõâêîôûç\s]'), '')
          .trim() ??
      '';

  EasyLoading.dismiss();
  // ===============================
  // 🔹 ABRE O BOTTOM SHEET
  // ===============================
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: theme.primaryColor.value,
    builder: (context) {
      return FractionallySizedBox(
        heightFactor: 0.92,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                corSecundaria.withValues(alpha: 0.9),
                Colors.white,
                corPrincipal.withValues(alpha: 0.05),
              ],
              stops: const [0.0, 0.6, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                left: 14,
                right: 14,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Center(
                        child: Container(
                          width: 60,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Obx(() => EventoPreviewTituloWidget(
                            tipoEvento: tipoNormalizado,
                            nomeEvento: controller.nomeEventoPreview.value,
                            corPrincipal: corPrincipal,
                          )),
                      ..._buildCamposPorTipo(corPrincipal, controller),
                      const SizedBox(height: 32),
                      Obx(() => Column(
                            children: [
                              BotaoSalvar(
                                texto: controller.isEditando
                                    ? 'Atualizar evento'
                                    : 'Salvar e continuar',
                                icon: Icon(
                                  controller.isEditando
                                      ? Icons.update_rounded
                                      : Icons.check_circle_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                                onPressed: () async {
                                  if (!controller.carregando.value) {
                                    EasyLoading.show(status: 'Processando...');
                                    await controller.salvarEvento();
                                    EasyLoading.dismiss();
                                  }
                                },
                              ),
                              const SizedBox(height: 20),
                              BotaoCancelar(texto: 'Fechar', onPressed: () => Get.back()),
                            ],
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

List<Widget> _buildCamposPorTipo(
  Color corPrincipal,
  EventoCadastroController controller,
) {
  final tipoNormalizado = controller.tipoEventoModel.value?.nome
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-zá-úà-ùãõâêîôûç\s]'), '')
      .trim();
  return [
    CustomInputField(
      label: "Título do evento",
      icon: Icons.celebration,
      controller: controller.nomeEvento,
      color: corPrincipal,
      titleColor: corPrincipal,
      validator: (v) => v == null || v.trim().isEmpty ? "Informe o nome do evento" : null,
      onChanged: (p0) {
        controller.nomeEventoPreview.value = p0;
        controller.atualizarPreview();
      },
      //(_) => controller.atualizarPreview(),
    ),

    if (tipoNormalizado == 'aniversário' || tipoNormalizado == 'aniversario') ...[
      CustomInputField(
        label: "Nome do(a) aniversariante",
        icon: Icons.cake_rounded,
        controller: controller.nomePessoalPrincipal,
        color: corPrincipal,
        titleColor: corPrincipal,
        validator: (v) => v!.isEmpty ? "Informe o nome do(a) aniversariante" : null,
        onChanged: (_) => controller.atualizarPreview(),
      ),
    ],

    if (tipoNormalizado == 'formatura' || tipoNormalizado == 'evento formatura') ...[
      CustomInputField(
        label: "Nome do(a) formando(a)",
        icon: Icons.school_rounded,
        controller: controller.nomePessoalPrincipal,
        color: corPrincipal,
        titleColor: corPrincipal,
        validator: (v) => v!.isEmpty ? "Informe o nome do(a) formando(a)" : null,
        onChanged: (_) => controller.atualizarPreview(),
      ),
    ],
    if (tipoNormalizado == 'corporativo' || tipoNormalizado == 'evento corporativo') ...[
      CustomInputField(
        label: "Nome da empresa ou setor",
        icon: Icons.business_rounded,
        controller: controller.nomePessoalPrincipal,
        color: corPrincipal,
        titleColor: corPrincipal,
        validator: (v) => v!.isEmpty ? "Informe o nome da empresa ou setor" : null,
        onChanged: (_) => controller.atualizarPreview(),
      ),
    ],

    if (tipoNormalizado == 'casamento') ...[
      CustomInputField(
        label: "Nome da noiva",
        icon: Icons.female,
        controller: controller.nomeNoiva,
        color: corPrincipal,
        titleColor: corPrincipal,
        validator: (v) => v!.isEmpty ? "Informe o nome da noiva" : null,
        onChanged: (_) => controller.atualizarPreview(),
      ),
      CustomInputField(
        label: "Nome do noivo",
        icon: Icons.male,
        controller: controller.parceiro,
        color: corPrincipal,
        titleColor: corPrincipal,
        validator: (v) => v!.isEmpty ? "Informe o nome do noivo" : null,
        onChanged: (_) => controller.atualizarPreview(),
      ),
      const SizedBox(height: 12),
      Divider(color: corPrincipal.withValues(alpha: 0.3)),
      const SizedBox(height: 12),
      Text("💡 Em resumo",
          style: GoogleFonts.poppins(
            color: corPrincipal,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          )),
      const SizedBox(height: 12),
      Obx(() => DropdownButtonFormField<String>(
            value:
                controller.tipoCerimonia.value.isNotEmpty ? controller.tipoCerimonia.value : null,
            decoration: InputDecoration(
              labelText: "Tipo de cerimônia",
              labelStyle: GoogleFonts.poppins(color: corPrincipal),
              prefixIcon: Icon(Icons.church, color: corPrincipal),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: corPrincipal, width: 1.5),
                borderRadius: BorderRadius.circular(14),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'civil', child: Text('Civil')),
              DropdownMenuItem(value: 'religiosa', child: Text('Religiosa')),
              DropdownMenuItem(value: 'religiosa_civil', child: Text('Religiosa + Civil')),
              DropdownMenuItem(value: 'simbolica', child: Text('Simbólica')),
              DropdownMenuItem(value: 'ao_ar_livre', child: Text('Ao ar livre')),
            ],
            onChanged: (v) => controller.tipoCerimonia.value = v ?? '',
            validator: (v) => v == null || v.isEmpty ? "Selecione o tipo de cerimônia" : null,
          )),

      const SizedBox(height: 10),
      Divider(color: corPrincipal.withValues(alpha: 0.3)),
      const SizedBox(height: 10),

      // === Estilo do casamento (com opções pré-definidas)
      Obx(() => DropdownButtonFormField<String>(
            value: controller.estiloCasamento.value.isNotEmpty
                ? controller.estiloCasamento.value
                : null,
            decoration: InputDecoration(
              labelText: "Estilo do casamento",
              labelStyle: GoogleFonts.poppins(color: corPrincipal),
              prefixIcon: Icon(Icons.palette, color: corPrincipal),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: corPrincipal, width: 1.5),
                borderRadius: BorderRadius.circular(14),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'classico', child: Text('Clássico')),
              DropdownMenuItem(value: 'rustico', child: Text('Rústico')),
              DropdownMenuItem(value: 'praia', child: Text('Praia')),
              DropdownMenuItem(value: 'campo', child: Text('Campo')),
              DropdownMenuItem(value: 'boho', child: Text('Boho')),
              DropdownMenuItem(value: 'moderno', child: Text('Moderno')),
              DropdownMenuItem(value: 'industrial', child: Text('Industrial')),
              DropdownMenuItem(value: 'minimalista', child: Text('Minimalista')),
            ],
            onChanged: (v) => controller.estiloCasamento.value = v ?? '',
            validator: (v) => v == null || v.isEmpty ? "Selecione o estilo do casamento" : null,
          )),

      const SizedBox(height: 8),
      _buildCampoPadrinhos(corPrincipal, controller),
      const SizedBox(height: 10),
    ],

    if (tipoNormalizado == 'festa infantil') ...[
      CustomInputField(
        label: "Nome da criança",
        icon: Icons.child_care,
        controller: controller.nomeNoiva,
        color: corPrincipal,
        titleColor: corPrincipal,
        validator: (v) => v!.isEmpty ? "Informe o nome da criança" : null,
        onChanged: (_) => controller.atualizarPreview(),
      ),
      CustomInputField(
        label: "Idade",
        icon: Icons.cake,
        controller: controller.idade,
        color: corPrincipal,
        titleColor: corPrincipal,
        keyboardType: TextInputType.number,
        onChanged: (_) => controller.atualizarPreview(),
      ),
      CustomInputField(
        label: "Tema da festa",
        icon: Icons.star,
        controller: controller.tema,
        color: corPrincipal,
        titleColor: corPrincipal,
        onChanged: (_) => controller.atualizarPreview(),
      ),
    ],

    /// Campos comuns
    const SizedBox(height: 10),
    CustomInputField(
      label: "Data do evento",
      icon: Icons.calendar_month,
      controller: controller.dataFesta,
      color: corPrincipal,
      titleColor: corPrincipal,
      readOnly: true,
      enabled: true,
      onTap: () async {
        final hoje = DateTime.now();
        final picked = await showDatePicker(
          context: Get.context!,
          initialDate: hoje.add(const Duration(days: 30)),
          firstDate: hoje.add(const Duration(days: 7)),
          lastDate: DateTime(hoje.year + 5),
          locale: const Locale('pt', 'BR'),
          initialEntryMode: DatePickerEntryMode.calendarOnly,
        );
        if (picked != null) {
          controller.dataFesta.text = DateFormat('dd/MM/yyyy', 'pt_BR').format(picked);
        }
      },
      validator: (v) => v!.isEmpty ? "Selecione a data do evento" : null,
    ),
    CustomInputField(
      label: "Hora do evento",
      icon: Icons.access_time,
      controller: controller.horaFesta,
      color: corPrincipal,
      titleColor: corPrincipal,
      readOnly: true,
      onTap: () async {
        final picked = await showTimePicker(
          context: Get.context!,
          initialTime: TimeOfDay.now(),
        );
        if (picked != null) {
          controller.horaFesta.text =
              "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
        }
      },
      validator: (v) => v!.isEmpty ? "Informe a hora" : null,
    ),

    Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_awesome_rounded, color: corPrincipal, size: 26),
              Text(
                "Quanto deseja investir na sua alegria",
                style: GoogleFonts.poppins(
                  color: corPrincipal,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ],
    ),
    const SizedBox(height: 8),
    // === Custo estimado ===
    CustomInputField(
      label: "Custo estimado (R\$)",
      hintlabel: 'Informe o custo estimado',
      icon: Icons.attach_money,
      controller: controller.custoEstimado,
      color: corPrincipal,
      titleColor: corPrincipal,
      type: InputType.money,
      onChanged: (v) {
        controller.atualizarPreview();
      },
    ),

    EnderecoSection(
      cor: corPrincipal,
      controller: controller.enderecoController.value,
      titulo: 'Endereço do evento',
    ),
  ];
}

Widget _buildCampoPadrinhos(Color cor, EventoCadastroController controller) {
  final padrinhoController = TextEditingController();

  return Obx(() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                cor.withValues(alpha: 0.9),
                cor.withValues(alpha: 0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: padrinhoController,
                    decoration: InputDecoration(
                      labelText: "💖 Padrinhos / Nome do casal",
                      labelStyle: GoogleFonts.poppins(color: cor),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: cor),
                      ),
                    ),
                    onSubmitted: (v) {
                      controller.addPadrinho(v);
                      padrinhoController.clear();
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle, color: cor),
                  onPressed: () {
                    controller.addPadrinho(padrinhoController.text);
                    padrinhoController.clear();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: controller.padrinhos.map((p) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        cor.withValues(alpha: 0.5),
                        cor.withValues(alpha: 0.3),
                        cor.withValues(alpha: 0.2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Chip(
                    backgroundColor: cor.withValues(alpha: 0.9), // 👈 usa o gradiente do container
                    labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                    label: Text(
                      p,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    deleteIcon: const Icon(Icons.delete, color: Colors.white, size: 20),
                    onDeleted: () => controller.removePadrinho(p),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ));
}
