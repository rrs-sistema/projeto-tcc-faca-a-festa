// ignore_for_file: use_build_context_synchronously

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

import './../../../core/utils/form_masks.dart';
import './../../../core/utils/form_validators.dart';
import './../../../controllers/tema/event_theme_controller.dart';
import './../../../controllers/tema/tema_festa_controller.dart';
import './../../../controllers/evento_cadastro_controller.dart';
import './../endereco/endereco_section.dart';
import './evento_preview_titulo_widget.dart';
import './tema_festa_selector.dart';
import './../../../data/models/model.dart';
import '../calculadora/calculadora_festa_screen.dart';

Future<void> showCadastroEventoBottomSheet(
  BuildContext context, {
  EventoModel? eventoParaEdicao,
}) async {
  final controller = Get.find<EventoCadastroController>();
  final theme = Get.find<EventThemeController>();
  EasyLoading.show(status: 'A carregar informações...');

  await controller.carregarTiposEvento();
  if (Get.isRegistered<TemaFestaController>()) {
    await Get.find<TemaFestaController>().carregar();
  }

  if (eventoParaEdicao != null) {
    controller.carregarEvento(eventoParaEdicao);
  } else {
    controller.limpar(manterEndereco: true);
  }

  final primary = theme.primaryColor.value;
  final dinheiroMask = FormMasks.dinheiro();

  final tipoNormalizado = controller.tipoEventoSelecionado.value?.nome
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-zá-úà-ùãõâêîôûç\s]'), '')
          .trim() ??
      '';

  EasyLoading.dismiss();

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return FractionallySizedBox(
        heightFactor: 0.90, // Altura ideal para o teclado e visibilidade
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                // 🔹 Cabeçalho Compacto
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.celebration_rounded, color: primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              controller.isEditando ? 'Editar Evento' : 'Novo Evento',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF111827),
                              ),
                            ),
                            Text(
                              'Preencha as informações da festa.',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close_rounded, size: 22),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                ),
                Divider(color: Colors.grey.shade200, height: 1),

                // 🔹 Formulário Rolável
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(
                      left: 10,
                      right: 10,
                      top: 10,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                    ),
                    child: Form(
                      key: controller.formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Obx(() => EventoPreviewTituloWidget(
                                tipoEvento: tipoNormalizado,
                                nomeEvento: controller.nomeEventoPreview.value,
                                corPrincipal: primary,
                              )),
                          const SizedBox(height: 10),
                          ..._buildCamposPorTipo(
                            primary,
                            controller,
                            eventoParaEdicao,
                            context,
                            dinheiroMask,
                          ),
                          const SizedBox(height: 10),
                          _buildAcoes(primary, controller),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// ============================================================================
// 🔹 Geração Condicional de Campos
// ============================================================================
List<Widget> _buildCamposPorTipo(
  Color primary,
  EventoCadastroController controller,
  EventoModel? eventoParaEdicao,
  BuildContext context,
  TextInputFormatter dinheiroMask,
) {
  final tipoNormalizado = controller.tipoEventoSelecionado.value?.nome
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-zá-úà-ùãõâêîôûç\s]'), '')
      .trim();
  final tokenTipo = controller.tokenTipoEvento;

  return [
    _SectionCard(
      title: 'Informações Básicas',
      icon: Icons.info_outline_rounded,
      child: Column(
        children: [
          _CompactInputField(
            label: "Título do evento",
            icon: Icons.celebration_rounded,
            controller: controller.nomeEvento,
            validator: (v) => FormValidators.titulo(v, campo: 'o título do evento'),
            onChanged: (p0) {
              controller.nomeEventoPreview.value = p0;
              controller.atualizarPreview();
            },
          ),
          if (tipoNormalizado == 'aniversario' || tipoNormalizado == 'aniversário') ...[
            const SizedBox(height: 8),
            _CompactInputField(
              label: "Nome do(a) aniversariante",
              icon: Icons.cake_rounded,
              controller: controller.nomePessoalPrincipal,
              validator: (v) => FormValidators.nomePessoa(
                v,
                campo: 'o nome do(a) aniversariante',
              ),
              onChanged: (_) => controller.atualizarPreview(),
            ),
            const SizedBox(height: 10),
            TemaFestaSelector(primary: primary, obrigatorio: true),
          ],
          if (tipoNormalizado == 'formatura' || tipoNormalizado == 'eventoformatura') ...[
            const SizedBox(height: 8),
            _CompactInputField(
              label: "Nome do(a) formando(a)",
              icon: Icons.school_rounded,
              controller: controller.nomePessoalPrincipal,
              validator: (v) => FormValidators.nomePessoa(
                v,
                campo: 'o nome do(a) formando(a)',
              ),
              onChanged: (_) => controller.atualizarPreview(),
            ),
            const SizedBox(height: 10),
            TemaFestaSelector(primary: primary),
          ],
          if (tokenTipo.contains('corporativo')) ...[
            const SizedBox(height: 8),
            _CompactInputField(
              label: "Empresa ou setor",
              icon: Icons.business_rounded,
              controller: controller.nomePessoalPrincipal,
              validator: (v) => FormValidators.titulo(
                v,
                campo: 'a empresa ou setor',
                minimo: 2,
              ),
              onChanged: (_) => controller.atualizarPreview(),
            ),
            const SizedBox(height: 10),
            TemaFestaSelector(primary: primary),
          ],
          if (tokenTipo.contains('cha')) ...[
            const SizedBox(height: 10),
            TemaFestaSelector(primary: primary),
          ],
          if (tipoNormalizado == 'festainfantil' || tipoNormalizado == 'festa infantil') ...[
            const SizedBox(height: 8),
            _CompactInputField(
              label: "Nome da criança",
              icon: Icons.child_care_rounded,
              controller: controller.nomeNoiva, // reaproveitado do modelo
              validator: (v) => FormValidators.nomePessoa(
                v,
                campo: 'o nome da criança',
              ),
              onChanged: (_) => controller.atualizarPreview(),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _CompactInputField(
                    label: "Idade",
                    icon: Icons.cake_rounded,
                    controller: controller.idade,
                    keyboardType: TextInputType.number,
                    inputFormatters: FormMasks.inteiro(maxDigits: 3),
                    validator: (v) => FormValidators.idade(v, obrigatorio: true, maximo: 17),
                    onChanged: (_) => controller.atualizarPreview(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TemaFestaSelector(primary: primary, obrigatorio: true),
          ],
        ],
      ),
    ),
    const SizedBox(height: 10),
    if (tipoNormalizado == 'casamento') ...[
      _SectionCard(
        title: 'Noivos e Cerimônia',
        icon: Icons.favorite_rounded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _CompactInputField(
                    label: "Nome da noiva(o)",
                    icon: Icons.female_rounded,
                    controller: controller.nomeNoiva,
                    validator: (v) => FormValidators.nomePessoa(
                      v,
                      campo: 'o nome da noiva(o)',
                    ),
                    onChanged: (_) => controller.atualizarPreview(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CompactInputField(
                    label: "Nome do noivo(a)",
                    icon: Icons.male_rounded,
                    controller: controller.parceiro,
                    validator: (v) => FormValidators.nomePessoa(
                      v,
                      campo: 'o nome do noivo(a)',
                    ),
                    onChanged: (_) => controller.atualizarPreview(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Obx(() => DropdownButtonFormField<String>(
                        isExpanded:
                            true, // 🔹 Adicionado para evitar overflow (Garante que o texto encolhe)
                        value: controller.tipoCerimonia.value.isNotEmpty
                            ? controller.tipoCerimonia.value
                            : null,
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                        decoration: InputDecoration(
                          labelText: "Cerimônia",
                          labelStyle: GoogleFonts.poppins(fontSize: 11),
                          prefixIcon: const Icon(Icons.church_rounded, size: 16),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'civil',
                              child: Text('Civil', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(
                              value: 'religiosa',
                              child: Text('Religiosa', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(
                              value: 'religiosa_civil',
                              child: Text('Religiosa + Civil', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(
                              value: 'simbolica',
                              child: Text('Simbólica', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(
                              value: 'ao_ar_livre',
                              child: Text('Ao ar livre', overflow: TextOverflow.ellipsis)),
                        ],
                        onChanged: (v) => controller.tipoCerimonia.value = v ?? '',
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Selecione o tipo de cerimônia' : null,
                      )),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Obx(() => DropdownButtonFormField<String>(
                        isExpanded: true, // 🔹 Adicionado para evitar overflow
                        value: controller.estiloCasamento.value.isNotEmpty
                            ? controller.estiloCasamento.value
                            : null,
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                        decoration: InputDecoration(
                          labelText: "Estilo",
                          labelStyle: GoogleFonts.poppins(fontSize: 11),
                          prefixIcon: const Icon(Icons.palette_rounded, size: 16),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'classico',
                              child: Text('Clássico', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(
                              value: 'rustico',
                              child: Text('Rústico', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(
                              value: 'praia',
                              child: Text('Praia', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(
                              value: 'campo',
                              child: Text('Campo', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(
                              value: 'boho', child: Text('Boho', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(
                              value: 'moderno',
                              child: Text('Moderno', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(
                              value: 'industrial',
                              child: Text('Industrial', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(
                              value: 'minimalista',
                              child: Text('Minimalista', overflow: TextOverflow.ellipsis)),
                        ],
                        onChanged: (v) => controller.estiloCasamento.value = v ?? '',
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Selecione o estilo do casamento' : null,
                      )),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TemaFestaSelector(primary: primary),
            const SizedBox(height: 10),
            _buildCampoPadrinhos(primary, controller),
          ],
        ),
      ),
      const SizedBox(height: 10),
    ],
    _SectionCard(
      title: 'Planeamento',
      icon: Icons.event_note_rounded,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _CompactInputField(
                  label: "Data do evento",
                  icon: Icons.calendar_month_rounded,
                  controller: controller.dataFesta,
                  readOnly: true,
                  onTap: () async {
                    final hoje = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
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
                  validator: (v) => FormValidators.data(v, campo: 'a data do evento'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CompactInputField(
                  label: "Hora",
                  icon: Icons.access_time_rounded,
                  controller: controller.horaFesta,
                  readOnly: true,
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) {
                      controller.horaFesta.text =
                          "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                    }
                  },
                  validator: (v) => FormValidators.hora(v, campo: 'a hora do evento'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _CompactInputField(
            label: "Custo estimado (R\$)",
            icon: Icons.attach_money_rounded,
            controller: controller.custoEstimado,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [dinheiroMask],
            validator: (v) => FormValidators.dinheiro(
              v,
              campo: 'o custo estimado',
              maiorQue: 1,
            ),
            onChanged: (v) => controller.atualizarPreview(),
          ),
        ],
      ),
    ),
    const SizedBox(height: 10),
    _buildSecaoConvidadosEstimados(primary, controller),
    const SizedBox(height: 10),
    _buildBotaoCalculadoraFesta(primary, controller, eventoParaEdicao),
    const SizedBox(height: 10),
    Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: EnderecoSection(
        cor: primary,
        controller: controller.enderecoController.value,
        titulo: 'Endereço do evento',
      ),
    ),
  ];
}

// ============================================================================
// 🔹 Secções Específicas
// ============================================================================
Widget _buildCampoPadrinhos(Color primary, EventoCadastroController controller) {
  final padrinhoController = TextEditingController();

  return Obx(() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: padrinhoController,
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: "💖 Nome dos padrinhos / casal",
                      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 11),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: (v) {
                      if (v.trim().isNotEmpty) controller.addPadrinho(v);
                      padrinhoController.clear();
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle_rounded, color: primary, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    if (padrinhoController.text.trim().isNotEmpty) {
                      controller.addPadrinho(padrinhoController.text);
                    }
                    padrinhoController.clear();
                  },
                ),
              ],
            ),
          ),
          if (controller.padrinhos.isNotEmpty) const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: controller.padrinhos.map((p) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      p,
                      style: GoogleFonts.poppins(
                          color: primary, fontWeight: FontWeight.w600, fontSize: 10),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => controller.removePadrinho(p),
                      child: Icon(Icons.close_rounded, color: primary, size: 12),
                    )
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ));
}

Widget _buildSecaoConvidadosEstimados(Color primary, EventoCadastroController controller) {
  void atualizarTotal() {
    final adultos = _parseIntText(controller.totalAdultos.text);
    final criancas = _parseIntText(controller.totalCriancas.text);
    final bebes = _parseIntText(controller.totalBebes.text);
    final total = adultos + criancas + bebes;

    controller.totalConvidados.text = total.toString();
    controller.atualizarPreview();
  }

  // Atualiza assim que constrói a view
  atualizarTotal();

  return _SectionCard(
    title: 'Estimativa de convidados',
    icon: Icons.groups_rounded,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'A quantidade total será calculada automaticamente.',
          style: GoogleFonts.poppins(
            color: Colors.grey.shade600,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _CompactInputField(
                label: 'Adultos',
                icon: Icons.person_rounded,
                controller: controller.totalAdultos,
                keyboardType: TextInputType.number,
                inputFormatters: FormMasks.inteiro(maxDigits: 5),
                validator: (v) {
                  final erro = FormValidators.inteiroNaoNegativo(
                    v,
                    campo: 'os adultos',
                  );
                  if (erro != null) return erro;
                  final total = _parseIntText(controller.totalAdultos.text) +
                      _parseIntText(controller.totalCriancas.text) +
                      _parseIntText(controller.totalBebes.text);
                  if (total < 1) {
                    return 'Informe pelo menos 1 convidado';
                  }
                  return null;
                },
                onChanged: (_) => atualizarTotal(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CompactInputField(
                label: 'Crianças',
                icon: Icons.child_care_rounded,
                controller: controller.totalCriancas,
                keyboardType: TextInputType.number,
                inputFormatters: FormMasks.inteiro(maxDigits: 5),
                validator: (v) => FormValidators.inteiroNaoNegativo(
                  v,
                  campo: 'as crianças',
                ),
                onChanged: (_) => atualizarTotal(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CompactInputField(
                label: 'Bebés',
                icon: Icons.baby_changing_station_rounded,
                controller: controller.totalBebes,
                keyboardType: TextInputType.number,
                inputFormatters: FormMasks.inteiro(maxDigits: 5),
                validator: (v) => FormValidators.inteiroNaoNegativo(
                  v,
                  campo: 'os bebês',
                ),
                onChanged: (_) => atualizarTotal(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _CompactInputField(
          label: 'Total de convidados',
          icon: Icons.summarize_rounded,
          controller: controller.totalConvidados,
          readOnly: true,
          enabled: false,
        ),
      ],
    ),
  );
}

Widget _buildBotaoCalculadoraFesta(
    Color primary, EventoCadastroController controller, EventoModel? eventoParaEdicao) {
  final idEvento = eventoParaEdicao?.idEvento.trim() ?? '';
  final eventoJaSalvo = idEvento.isNotEmpty;

  return _SectionCard(
    title: 'Assistente de Quantidades',
    icon: Icons.auto_graph_rounded,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eventoJaSalvo
              ? 'Recalcule os itens baseados na sua lista de convidados.'
              : 'Faça uma estimativa de comes e bebes para o evento.',
          style: GoogleFonts.poppins(
            color: Colors.grey.shade600,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 38,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: primary,
              side: BorderSide(color: primary.withValues(alpha: 0.45)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: EdgeInsets.zero,
            ),
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Get.to(
                () => CalculadoraFestaScreen(
                  idEvento: eventoJaSalvo ? idEvento : null,
                  tipoEvento: _resolverTipoEventoCalculadora(controller),
                  permitirEstimativaSemEvento: true,
                  adultosIniciais: _parseIntText(controller.totalAdultos.text),
                  criancasIniciais: _parseIntText(controller.totalCriancas.text),
                  bebesIniciais: _parseIntText(controller.totalBebes.text),
                ),
                fullscreenDialog: true,
              );
            },
            icon: const Icon(Icons.calculate_rounded, size: 18),
            label: Text(
              eventoJaSalvo ? 'Abrir calculadora da festa' : 'Calcular estimativa',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildAcoes(Color primary, EventoCadastroController controller) {
  return Obx(() {
    final salvando = controller.carregando.value;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: primary,
                side: BorderSide(color: primary.withValues(alpha: 0.55)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: EdgeInsets.zero,
              ),
              onPressed: () => Get.back(),
              icon: const Icon(Icons.close_rounded, size: 18),
              label: Text(
                'Cancelar',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: EdgeInsets.zero,
              ),
              onPressed: salvando
                  ? null
                  : () async {
                      final valido =
                          controller.formKey.currentState?.validate() ?? false;
                      if (!valido) return;
                      EasyLoading.show(status: 'A processar...');
                      try {
                        await controller.salvarEvento();
                      } finally {
                        EasyLoading.dismiss();
                      }
                    },
              icon: salvando
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(
                      controller.isEditando ? Icons.update_rounded : Icons.check_circle_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
              label: Text(
                controller.isEditando ? 'Atualizar' : 'Salvar',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
          ),
        ),
      ],
    );
  });
}

// ============================================================================
// 🔹 Componentes Auxiliares (Design System Idêntico à Calculadora)
// ============================================================================
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Theme.of(context).primaryColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _CompactInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;

  const _CompactInputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.keyboardType,
    this.validator,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      inputFormatters: inputFormatters,
      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 11),
        prefixIcon: Icon(icon, size: 16),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
        errorStyle: const TextStyle(fontSize: 9, height: 0.8),
        errorMaxLines: 2,
      ),
    );
  }
}

// Helpers
int _parseIntText(String? value) {
  final normalized = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '').trim();
  if (normalized.isEmpty) return 0;
  return int.tryParse(normalized) ?? 0;
}

String _resolverTipoEventoCalculadora(EventoCadastroController controller) {
  final tipoSelecionado =
      controller.tipoEventoSelecionado.value?.nome.trim() ?? '';
  if (tipoSelecionado.isNotEmpty) return tipoSelecionado;
  final nomeEvento = controller.nomeEvento.text.trim();
  if (nomeEvento.isNotEmpty) return nomeEvento;
  final preview = controller.nomeEventoPreview.value.trim();
  if (preview.isNotEmpty) return preview;
  return 'Evento';
}
