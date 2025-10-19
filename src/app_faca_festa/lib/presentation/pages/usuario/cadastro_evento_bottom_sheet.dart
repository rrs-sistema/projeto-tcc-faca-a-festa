// ignore_for_file: use_build_context_synchronously

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

import './../../../controllers/evento_cadastro_controller.dart';
import './../../widgets/custom_input_field.dart';
import './../endereco/endereco_section.dart';
import './../../../data/models/model.dart';

Future<void> showCadastroEventoBottomSheet(
  BuildContext context, {
  EventoModel? eventoParaEdicao,
}) async {
  final controller = Get.find<EventoCadastroController>();

  // 🔹 Carrega tipos de evento antes de abrir o formulário
  await controller.carregarTiposEvento();

  // 🔹 Se estiver editando, carrega os dados do evento
  if (eventoParaEdicao != null) {
    controller.carregarEvento(eventoParaEdicao);
  } else {
    controller.limpar();
  }

  // 🔹 Define cores baseadas no tipo atual (ou padrão)
  Color corPrincipal;
  Color corSecundaria;
  String emoji;

  final tipoNormalizado = controller.tipoEventoModel.value?.nome
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-zá-úà-ùãõâêîôûç\s]'), '')
          .trim() ??
      '';

  switch (tipoNormalizado) {
    case 'casamento':
      corPrincipal = const Color(0xFFE91E63);
      corSecundaria = const Color(0xFFFCE4EC);
      emoji = '💍';
      break;
    case 'festa infantil':
      corPrincipal = const Color(0xFFFF9800);
      corSecundaria = const Color(0xFFFFF3E0);
      emoji = '🎈';
      break;
    case 'chá de bebê':
      corPrincipal = const Color(0xFF03A9F4);
      corSecundaria = const Color(0xFFE1F5FE);
      emoji = '🍼';
      break;
    case 'aniversário':
      corPrincipal = const Color(0xFF9C27B0);
      corSecundaria = const Color(0xFFF3E5F5);
      emoji = '🎂';
      break;
    default:
      corPrincipal = const Color(0xFF009688);
      corSecundaria = const Color(0xFFE0F2F1);
      emoji = '🎉';
  }

  // ===============================
  // 🔹 ABRE O BOTTOM SHEET
  // ===============================
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return FractionallySizedBox(
        heightFactor: 0.92,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [corSecundaria, Colors.white],
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

                      /// === Preview dinâmico ===
                      Obx(() => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [corPrincipal.withValues(alpha: 0.15), Colors.white],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: corPrincipal.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(emoji, style: const TextStyle(fontSize: 38)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    controller.nomeEventoPreview.value.isEmpty
                                        ? 'Seu evento aparecerá aqui...'
                                        : controller.nomeEventoPreview.value,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: corPrincipal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),

                      ..._buildCamposPorTipo(corPrincipal, controller),

                      const SizedBox(height: 32),

                      /// === Botão de ação ===
                      Obx(() => Center(
                            child: ElevatedButton.icon(
                              icon: controller.carregando.value
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(
                                      controller.isEditando
                                          ? Icons.update
                                          : Icons.check_circle_outline,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                              label: Text(
                                controller.isEditando ? 'Atualizar evento' : 'Salvar e continuar',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: controller.carregando.value
                                  ? null
                                  : () => controller.salvarEvento(),
                            ),
                          )),

                      const SizedBox(height: 20),
                      Center(
                        child: TextButton.icon(
                          icon: const Icon(Icons.close, color: Colors.redAccent),
                          label: const Text('Cancelar'),
                          onPressed: () => Get.back(),
                        ),
                      ),
                      const SizedBox(height: 16),
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
  final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  return [
    Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Obx(() {
        final tipos = controller.tiposEvento;
        final tipoSelecionado = controller.tipoEventoModel.value;

        return DropdownButtonFormField<String>(
          value: tipoSelecionado?.idTipoEvento.isNotEmpty == true
              ? tipoSelecionado!.idTipoEvento
              : null,
          decoration: InputDecoration(
            labelText: "Tipo de evento",
            labelStyle: GoogleFonts.poppins(color: corPrincipal),
            prefixIcon: Icon(Icons.category, color: corPrincipal),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: corPrincipal, width: 1.5),
              borderRadius: BorderRadius.circular(14),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          items: tipos.map((t) {
            return DropdownMenuItem(
              value: t.idTipoEvento, // ✅ agora o value é o ID
              child: Text(t.nome),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) {
              final tipo = tipos.firstWhereOrNull((e) => e.idTipoEvento == v);
              controller.tipoEventoModel.value = tipo;
              controller.atualizarPreview();
            }
          },
          validator: (v) => v == null || v.isEmpty ? "Selecione o tipo de evento" : null,
        );
      }),
    ),

    if (tipoNormalizado == 'casamento') ...[
      CustomInputField(
        label: "Nome da noiva",
        icon: Icons.female,
        controller: controller.nome,
        color: corPrincipal,
        validator: (v) => v!.isEmpty ? "Informe o nome da noiva" : null,
        onChanged: (_) => controller.atualizarPreview(),
      ),
      CustomInputField(
        label: "Nome do noivo",
        icon: Icons.male,
        controller: controller.parceiro,
        color: corPrincipal,
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
        controller: controller.nome,
        color: corPrincipal,
        validator: (v) => v!.isEmpty ? "Informe o nome da criança" : null,
        onChanged: (_) => controller.atualizarPreview(),
      ),
      CustomInputField(
        label: "Idade",
        icon: Icons.cake,
        controller: controller.idade,
        color: corPrincipal,
        keyboardType: TextInputType.number,
        onChanged: (_) => controller.atualizarPreview(),
      ),
      CustomInputField(
        label: "Tema da festa",
        icon: Icons.star,
        controller: controller.tema,
        color: corPrincipal,
        onChanged: (_) => controller.atualizarPreview(),
      ),
    ],

// === Custo estimado ===
    CustomInputField(
      label: "Custo estimado (R\$)",
      icon: Icons.attach_money,
      controller: controller.custoEstimado,
      color: corPrincipal,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (v) {
        if (v == null || v.isEmpty) return "Informe o custo estimado";

        // 🔹 Remove símbolos de moeda e espaços
        final limpo = v
            .replaceAll('R\$', '')
            .replaceAll('r\$', '')
            .replaceAll('.', '')
            .replaceAll(',', '.')
            .trim();

        final valor = double.tryParse(limpo);
        if (valor == null || valor <= 0) return "Valor inválido";
        return null;
      },
      onChanged: (v) {
        // Remove tudo que não for número
        final numeric = v.replaceAll(RegExp(r'[^0-9]'), '');
        if (numeric.isEmpty) {
          controller.custoEstimado.text = '';
          return;
        }

        // Converte centavos → reais
        final valor = double.parse(numeric) / 100;

        // Atualiza formatado, mantendo o cursor no final
        controller.custoEstimado.value = TextEditingValue(
          text: currencyFormat.format(valor),
          selection: TextSelection.collapsed(
            offset: currencyFormat.format(valor).length,
          ),
        );

        controller.atualizarPreview();
      },
    ),

    /// Campos comuns
    CustomInputField(
      label: "Data do evento",
      icon: Icons.calendar_month,
      controller: controller.dataFesta,
      color: corPrincipal,
      readOnly: true,
      onTap: () async {
        final hoje = DateTime.now();
        final picked = await showDatePicker(
          context: Get.context!,
          initialDate: hoje.add(const Duration(days: 30)),
          firstDate: hoje,
          lastDate: DateTime(hoje.year + 2),
          locale: const Locale('pt', 'BR'),
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

    EnderecoSection(
      cor: Colors.pink.shade700,
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
          Text("💖 Padrinhos",
              style: GoogleFonts.poppins(
                color: cor,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: controller.padrinhos.map((p) {
              return Chip(
                label: Text(p, style: const TextStyle(color: Colors.white)),
                backgroundColor: cor,
                deleteIcon: const Icon(Icons.close, color: Colors.white70, size: 18),
                onDeleted: () => controller.removePadrinho(p),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: padrinhoController,
                  decoration: InputDecoration(
                    labelText: "Nome do casal / padrinho",
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
        ],
      ));
}
