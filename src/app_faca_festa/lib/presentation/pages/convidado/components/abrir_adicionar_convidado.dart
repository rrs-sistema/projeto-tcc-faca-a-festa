import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../../../controllers/convidado/convidado_controller.dart';
import '../../../../controllers/convidado/grupo_convidado_controller.dart';
import '../../../../controllers/evento_controller.dart';
import '../../../../controllers/tema/event_theme_controller.dart';
import '../../../../data/models/convidado/grupo_convidado_model.dart';
import '../../../../data/models/model.dart';

void abrirDialogAdicionarConvidado(
  BuildContext context,
  Color primary, {
  ConvidadoModel? convidado,
}) {
  final themeController = Get.find<EventThemeController>();
  final eventoController = Get.find<EventoController>();
  final convidadoController = Get.find<ConvidadoController>();
  final grupoController = Get.find<GrupoConvidadoController>();

  final uuid = const Uuid();
  final bool editando = convidado != null;

  final nomeCtrl = TextEditingController(text: convidado?.nome ?? '');
  final emailCtrl = TextEditingController(text: convidado?.email ?? '');
  final telCtrl = TextEditingController(text: convidado?.contato ?? '');

  final RxString idGrupoSelecionado = (convidado?.idGrupo ?? '').obs;
  final Rx<TipoConvidado> tipoConvidado = (convidado?.tipoConvidado ?? TipoConvidado.adulto).obs;
  final RxBool cuidadoEspecial = (convidado?.cuidadoEspecial ?? false).obs;
  final RxBool salvando = false.obs;

  final gradient = themeController.gradient.value;
  const background = Color(0xFFF8FAFC);
  const textDark = Color(0xFF1F2937);
  const textMuted = Color(0xFF64748B);

  final nomeGrupoInicial = convidado?.nomeGrupo?.trim();

  if (idGrupoSelecionado.value.trim().isEmpty &&
      nomeGrupoInicial != null &&
      nomeGrupoInicial.isNotEmpty) {
    final nomeGrupo = nomeGrupoInicial.toLowerCase();

    for (final grupo in grupoController.grupos) {
      if (grupo.nome.trim().toLowerCase() == nomeGrupo) {
        idGrupoSelecionado.value = grupo.idGrupo;
        break;
      }
    }
  }

  void showSnack({
    required String title,
    required String message,
    required Color color,
  }) {
    Get.snackbar(
      title,
      message,
      backgroundColor: color,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 16,
      icon: Icon(
        color == Colors.redAccent
            ? Icons.error_outline_rounded
            : Icons.check_circle_outline_rounded,
        color: Colors.white,
      ),
    );
  }

  GrupoConvidadoModel? grupoSelecionadoAtual() {
    final idGrupo = idGrupoSelecionado.value.trim();
    if (idGrupo.isEmpty) return null;

    for (final grupo in grupoController.grupos) {
      if (grupo.idGrupo == idGrupo) {
        return grupo;
      }
    }

    return null;
  }

  String tipoConvidadoLabel(TipoConvidado tipo) {
    switch (tipo) {
      case TipoConvidado.adulto:
        return 'Adulto';
      case TipoConvidado.crianca:
        return 'Criança';
      case TipoConvidado.bebe:
        return 'Bebê';
    }
  }

  String tipoConvidadoDescricao(TipoConvidado tipo) {
    switch (tipo) {
      case TipoConvidado.adulto:
        return 'Consumo e assento padrão';
      case TipoConvidado.crianca:
        return 'Cálculo infantil no buffet';
      case TipoConvidado.bebe:
        return 'Não ocupa assento comum';
    }
  }

  IconData tipoConvidadoIcon(TipoConvidado tipo) {
    switch (tipo) {
      case TipoConvidado.adulto:
        return Icons.person_rounded;
      case TipoConvidado.crianca:
        return Icons.child_care_rounded;
      case TipoConvidado.bebe:
        return Icons.baby_changing_station_rounded;
    }
  }

Future<void> salvarConvidado() async {
    if (salvando.value) return;

    final nome = nomeCtrl.text.trim();
    final contato = telCtrl.text.trim();
    final email = emailCtrl.text.trim();

    if (nome.isEmpty) {
      showSnack(
        title: 'Atenção',
        message: 'Informe o nome do convidado.',
        color: Colors.redAccent,
      );
      return;
    }

    final grupo = grupoSelecionadoAtual();

    if (grupo == null) {
      showSnack(
        title: 'Atenção',
        message: 'Selecione um grupo para organizar o convidado.',
        color: Colors.redAccent,
      );
      return;
    }

    final idEvento = eventoController.eventoAtual.value?.idEvento ?? '';

    if (idEvento.isEmpty) {
      showSnack(
        title: 'Atenção',
        message: 'Nenhum evento selecionado para vincular o convidado.',
        color: Colors.redAccent,
      );
      return;
    }

    try {
      salvando.value = true;

      final agora = DateTime.now();

      if (editando) {
        final atualizado = convidado.copyWith(
          nome: nome,
          contato: contato,
          email: email,
          idGrupo: grupo.idGrupo,
          nomeGrupo: grupo.nome,
          tipoConvidado: tipoConvidado.value,
          ocupaAssento: tipoConvidado.value != TipoConvidado.bebe,
          cuidadoEspecial: cuidadoEspecial.value,
          dataAtualizacao: agora,
        );

        await convidadoController.atualizarConvidado(atualizado);

        Get.back();

        showSnack(
          title: 'Convidado atualizado',
          message: nome,
          color: primary,
        );

        return;
      }

      final novo = ConvidadoModel(
        idConvidado: uuid.v4(),
        idEvento: idEvento,
        nome: nome,
        contato: contato,
        email: email,
        status: StatusConvidado.pendente,
        tipoConvidado: tipoConvidado.value,
        idGrupo: grupo.idGrupo,
        nomeGrupo: grupo.nome,
        ocupaAssento: tipoConvidado.value != TipoConvidado.bebe,
        cuidadoEspecial: cuidadoEspecial.value,
        dataCadastro: agora,
        dataAtualizacao: agora,
      );

      await convidadoController.adicionarConvidado(novo);

      Get.back();

      showSnack(
        title: 'Convidado adicionado',
        message: nome,
        color: primary,
      );
    } catch (e) {
      showSnack(
        title: 'Erro',
        message: 'Não foi possível salvar o convidado: $e',
        color: Colors.redAccent,
      );
    } finally {
      salvando.value = false;
    }
  }
  
  Widget buildDragHandle() {
    return Center(
      child: Container(
        width: 48,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Widget buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildDragHandle(),
          const SizedBox(height: 22),
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.30),
                  ),
                ),
                child: Icon(
                  editando ? Icons.manage_accounts_rounded : Icons.person_add_alt_1_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      editando ? 'Editar convidado' : 'Novo convidado',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 22,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      editando
                          ? 'Atualize os dados, grupo e perfil do convidado.'
                          : 'Cadastre o convidado e organize por grupo para usar nas estatísticas e calculadora.',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildSectionTitle({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primary, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: textDark,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: textMuted,
                      fontSize: 12.2,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        textInputAction: textInputAction,
        style: GoogleFonts.poppins(
          color: textDark,
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: GoogleFonts.poppins(
            color: textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: GoogleFonts.poppins(
            color: Colors.grey.shade400,
            fontSize: 13,
          ),
          prefixIcon: Icon(icon, color: primary),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: primary, width: 1.4),
          ),
        ),
      ),
    );
  }

  Widget buildTipoCard(TipoConvidado tipo) {
    return Obx(() {
      final selected = tipoConvidado.value == tipo;
      final color = selected ? primary : Colors.white;
      final foreground = selected ? Colors.white : textDark;

      return InkWell(
        onTap: () => tipoConvidado.value = tipo,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 152,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? primary : Colors.grey.shade200,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? primary.withValues(alpha: 0.20)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: selected ? 20 : 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.18)
                          : primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      tipoConvidadoIcon(tipo),
                      color: selected ? Colors.white : primary,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  AnimatedOpacity(
                    opacity: selected ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                tipoConvidadoLabel(tipo),
                style: GoogleFonts.poppins(
                  color: foreground,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tipoConvidadoDescricao(tipo),
                style: GoogleFonts.poppins(
                  color: selected ? Colors.white.withValues(alpha: 0.88) : textMuted,
                  fontSize: 11.5,
                  height: 1.25,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget buildGroupDropdown() {
    return Obx(() {
      final grupos = grupoController.grupos;

      if (grupoController.carregando.value) {
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Carregando grupos...',
                style: GoogleFonts.poppins(
                  color: textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }

      if (grupos.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFFD97706),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Nenhum grupo cadastrado para este evento. Crie um grupo antes de adicionar convidados.',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF92400E),
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      final selectedValue =
          idGrupoSelecionado.value.trim().isEmpty ? null : idGrupoSelecionado.value.trim();

      final valueExists = selectedValue == null || grupos.any((g) => g.idGrupo == selectedValue);

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: DropdownButtonFormField<String>(
          value: valueExists ? selectedValue : null,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Grupo do convidado',
            helperText: 'Usado para organizar famílias, amigos e mesas.',
            labelStyle: GoogleFonts.poppins(
              color: textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            helperStyle: GoogleFonts.poppins(
              color: textMuted,
              fontSize: 11.5,
            ),
            prefixIcon: Icon(Icons.group_outlined, color: primary),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: primary, width: 1.4),
            ),
          ),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: primary),
          items: grupos.map((g) {
            return DropdownMenuItem<String>(
              value: g.idGrupo,
              child: Text(
                g.nome,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
          onChanged: (v) => idGrupoSelecionado.value = v ?? '',
        ),
      );
    });
  }

  Widget buildCareSwitch() {
    return Obx(() {
      return InkWell(
        onTap: () => cuidadoEspecial.value = !cuidadoEspecial.value,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cuidadoEspecial.value ? const Color(0xFFECFDF5) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: cuidadoEspecial.value ? const Color(0xFF34D399) : Colors.grey.shade200,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: cuidadoEspecial.value
                      ? const Color(0xFF10B981)
                      : primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.health_and_safety_rounded,
                  color: cuidadoEspecial.value ? Colors.white : primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cuidado especial',
                      style: GoogleFonts.poppins(
                        color: textDark,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Marque quando o convidado precisar de atenção específica.',
                      style: GoogleFonts.poppins(
                        color: textMuted,
                        fontSize: 12,
                        height: 1.25,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: cuidadoEspecial.value,
                activeColor: primary,
                onChanged: (v) => cuidadoEspecial.value = v,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget buildSummaryCard() {
    return Obx(() {
      final tipo = tipoConvidado.value;
      final grupo = grupoSelecionadoAtual();

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primary.withValues(alpha: 0.12),
              primary.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primary.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(tipoConvidadoIcon(tipo), color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tipoConvidadoLabel(tipo),
                    style: GoogleFonts.poppins(
                      color: textDark,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    grupo == null
                        ? 'Selecione um grupo para concluir o cadastro.'
                        : 'Grupo: ${grupo.nome}',
                    style: GoogleFonts.poppins(
                      color: textMuted,
                      fontSize: 12.5,
                      height: 1.25,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (modalContext) {
      return DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.60,
        maxChildSize: 0.97,
        expand: false,
        builder: (_, controllerScroll) {
          return Container(
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              color: background,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                buildHeader(),
                Expanded(
                  child: ListView(
                    controller: controllerScroll,
                    padding: EdgeInsets.fromLTRB(
                      20,
                      20,
                      20,
                      MediaQuery.of(modalContext).viewInsets.bottom + 22,
                    ),
                    children: [
                      buildSectionTitle(
                        icon: Icons.badge_outlined,
                        title: 'Dados do convidado',
                        subtitle: 'Informe os dados principais para contato e identificação.',
                      ),
                      buildTextField(
                        controller: nomeCtrl,
                        label: 'Nome do convidado',
                        hint: 'Ex.: Maria Silva',
                        icon: Icons.person_outline_rounded,
                        textCapitalization: TextCapitalization.words,
                      ),
                      buildTextField(
                        controller: telCtrl,
                        label: 'Telefone ou WhatsApp',
                        hint: '(00) 00000-0000',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      buildTextField(
                        controller: emailCtrl,
                        label: 'E-mail',
                        hint: 'email@exemplo.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 12),
                      buildSectionTitle(
                        icon: Icons.groups_2_outlined,
                        title: 'Classificação',
                        subtitle:
                            'Essas informações serão usadas nas mesas, estatísticas e calculadora inteligente.',
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            buildTipoCard(TipoConvidado.adulto),
                            const SizedBox(width: 10),
                            buildTipoCard(TipoConvidado.crianca),
                            const SizedBox(width: 10),
                            buildTipoCard(TipoConvidado.bebe),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      buildGroupDropdown(),
                      const SizedBox(height: 16),
                      buildCareSwitch(),
                      const SizedBox(height: 16),
                      buildSummaryCard(),
                      const SizedBox(height: 24),
                      Obx(() {
                        final isSaving = salvando.value;

                        return SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              disabledBackgroundColor: primary.withValues(alpha: 0.45),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            onPressed: isSaving ? null : salvarConvidado,
                            icon: isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.check_circle_outline_rounded,
                                    color: Colors.white,
                                  ),
                            label: Text(
                              isSaving
                                  ? 'Salvando...'
                                  : editando
                                      ? 'Salvar alterações'
                                      : 'Cadastrar convidado',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: TextButton.icon(
                          onPressed: () => Get.back(),
                          icon: const Icon(Icons.close_rounded),
                          label: Text(
                            'Cancelar',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: textMuted,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  ).whenComplete(() {
    nomeCtrl.dispose();
    emailCtrl.dispose();
    telCtrl.dispose();
  });
}
