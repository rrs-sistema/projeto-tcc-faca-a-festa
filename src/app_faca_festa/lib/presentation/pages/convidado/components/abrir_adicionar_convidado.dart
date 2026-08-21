import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/agenda_contatos.dart';
import '../../../../core/utils/form_masks.dart';
import '../../../../core/utils/form_validators.dart';
import '../../../../controllers/convidado/convidado_controller.dart';
import '../../../../data/services/convite/enviar_convites_por_email_service.dart';
import '../../../../controllers/convidado/grupo_convidado_controller.dart';
import '../../../../controllers/evento_controller.dart';
import '../../../../controllers/tema/event_theme_controller.dart';
import '../../../../data/models/convidado/grupo_convidado_model.dart';
import '../../../../data/models/model.dart';
import 'buscar_contato_agenda_sheet.dart';
import 'show_cadastro_bottom_sheet.dart';

Future<void> abrirDialogAdicionarConvidado(
  BuildContext context,
  Color primary, {
  Convidado? convidado,
}) {
  return showCadastroBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (_) => _AdicionarConvidadoSheet(
      primary: primary,
      convidado: convidado,
    ),
  );
}

class _AdicionarConvidadoSheet extends StatefulWidget {
  const _AdicionarConvidadoSheet({
    required this.primary,
    this.convidado,
  });

  final Color primary;
  final Convidado? convidado;

  @override
  State<_AdicionarConvidadoSheet> createState() =>
      _AdicionarConvidadoSheetState();
}

class _AdicionarConvidadoSheetState extends State<_AdicionarConvidadoSheet> {
  final themeController = Get.find<EventThemeController>();
  final eventoController = Get.find<EventoController>();
  final convidadoController = Get.find<ConvidadoController>();
  final grupoController = Get.find<GrupoConvidadoController>();

  final uuid = const Uuid();

  late final TextEditingController nomeCtrl;
  late final TextEditingController emailCtrl;
  late final TextEditingController telCtrl;
  late final MaskTextInputFormatter telefoneMask;
  final _formKey = GlobalKey<FormState>();
  var _autovalidateMode = AutovalidateMode.disabled;
  late final RxString idGrupoSelecionado;
  late final Rx<TipoConvidado> tipoConvidado;
  late final RxBool cuidadoEspecial;
  late final RxBool enviarPorEmail;
  late final RxBool salvando;

  Color get primary => widget.primary;
  Convidado? get convidado => widget.convidado;
  bool get editando => convidado != null;

  @override
  void initState() {
    super.initState();
    nomeCtrl = TextEditingController(text: convidado?.nome ?? '');
    emailCtrl = TextEditingController(text: convidado?.email ?? '');
    telefoneMask = FormMasks.telefone(initialText: convidado?.contato ?? '');
    telCtrl = TextEditingController(text: telefoneMask.getMaskedText());
    idGrupoSelecionado = (convidado?.idGrupo ?? '').obs;
    tipoConvidado = (convidado?.tipoConvidado ?? TipoConvidado.adulto).obs;
    cuidadoEspecial = (convidado?.cuidadoEspecial ?? false).obs;
    enviarPorEmail = false.obs;
    salvando = false.obs;

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
  }

  LinearGradient get gradient => themeController.gradient.value;
  static const background = Color(0xFFF8FAFC);
  static const textDark = Color(0xFF1F2937);
  static const textMuted = Color(0xFF64748B);

  @override
  void dispose() {
    nomeCtrl.dispose();
    emailCtrl.dispose();
    telCtrl.dispose();
    idGrupoSelecionado.close();
    tipoConvidado.close();
    cuidadoEspecial.close();
    enviarPorEmail.close();
    salvando.close();
    super.dispose();
  }

  void showSnack(
      {required String title, required String message, required Color color}) {
    Get.snackbar(
      title,
      message,
      backgroundColor: color,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      icon: Icon(
        color == Colors.redAccent
            ? Icons.error_outline_rounded
            : Icons.check_circle_outline_rounded,
        color: Colors.white,
      ),
    );
  }

  GrupoConvidado? grupoSelecionadoAtual() {
    final idGrupo = idGrupoSelecionado.value.trim();
    if (idGrupo.isEmpty) return null;
    for (final grupo in grupoController.grupos) {
      if (grupo.idGrupo == idGrupo) return grupo;
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
    setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final nome = nomeCtrl.text.trim();
    final contato = telCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final grupo = grupoSelecionadoAtual();
    if (grupo == null) {
      showSnack(
          title: 'Atenção',
          message: 'Selecione um grupo.',
          color: Colors.redAccent);
      return;
    }
    final idEvento = eventoController.eventoAtualEntidade?.idEvento ?? '';
    if (idEvento.isEmpty) {
      showSnack(
          title: 'Atenção',
          message: 'Nenhum evento selecionado.',
          color: Colors.redAccent);
      return;
    }

    try {
      salvando.value = true;
      final agora = DateTime.now();
      final convidadoEditando = widget.convidado;

      if (convidadoEditando != null) {
        final atualizado = convidadoEditando.copyWith(
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
        await _fecharAposSalvar(
          titulo: 'Convidado atualizado',
          nome: nome,
          email: email,
          convidado: atualizado,
        );
        return;
      }

      final id = uuid.v4();
      final novo = Convidado(
        idConvidado: id,
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
        conviteToken: id,
        conviteStatus: 'link_gerado',
      );

      await convidadoController.adicionarConvidado(novo);
      await _fecharAposSalvar(
        titulo: 'Convidado adicionado',
        nome: nome,
        email: email,
        convidado: novo,
      );
    } catch (e) {
      showSnack(
          title: 'Erro',
          message: 'Não foi possível salvar: $e',
          color: Colors.redAccent);
    } finally {
      if (mounted) salvando.value = false;
    }
  }

  Future<void> _fecharAposSalvar({
    required String titulo,
    required String nome,
    required String email,
    required Convidado convidado,
  }) async {
    final tentouEmail = enviarPorEmail.value;
    final enviouEmail = await _enviarEmailSeMarcado(convidado);

    if (!mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop();
    if (tentouEmail && !enviouEmail) return;
    showSnack(
      title: titulo,
      message: enviouEmail ? 'Convite enviado para $email' : nome,
      color: primary,
    );
  }

  Future<bool> _enviarEmailSeMarcado(Convidado convidado) async {
    if (!enviarPorEmail.value) return false;
    try {
      final resultado =
          await convidadoController.enviarConvitesPorEmail([convidado]);
      if (resultado.enviados > 0) return true;
      showSnack(
        title: 'Cadastro salvo',
        message: 'O convite não pôde ser enviado por e-mail.',
        color: Colors.orange.shade700,
      );
    } on EnviarConvitesPorEmailException catch (erro) {
      showSnack(
        title: 'Cadastro salvo',
        message: erro.toString(),
        color: Colors.orange.shade700,
      );
    } catch (_) {
      showSnack(
        title: 'Cadastro salvo',
        message: 'O convite não pôde ser enviado por e-mail.',
        color: Colors.orange.shade700,
      );
    }
    return false;
  }

  Future<void> buscarNaAgenda() async {
    if (!agendaDoCelularDisponivel()) {
      showSnack(
        title: 'Agenda do celular',
        message:
            'No celular você busca na agenda, a mesma lista que o WhatsApp usa.',
        color: Colors.orange.shade700,
      );
      return;
    }
    final contato = await abrirBuscaContatoAgenda(
      context: context,
      primary: primary,
    );
    if (contato == null || !mounted) return;
    nomeCtrl.text = contato.nome;
    FormMasks.aplicarTelefone(
      controller: telCtrl,
      mask: telefoneMask,
      value: contato.telefonePrincipal,
    );
    if ((contato.email ?? '').isNotEmpty) {
      emailCtrl.text = contato.email!;
    }
    setState(() {});
  }

  Widget buildBotaoAgenda() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: buscarNaAgenda,
          icon: const Icon(Icons.contacts_outlined, size: 18),
          label: Text(
            'Buscar na agenda',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            side: BorderSide(color: primary.withValues(alpha: 0.35)),
            backgroundColor: primary.withValues(alpha: 0.06),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildDragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(999)),
      ),
    );
  }

  Widget buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildDragHandle(),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.30)),
                ),
                child: Icon(
                    editando
                        ? Icons.manage_accounts_rounded
                        : Icons.person_add_alt_1_rounded,
                    color: Colors.white,
                    size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      editando ? 'Editar convidado' : 'Novo convidado',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          height: 1.1,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      editando
                          ? 'Atualize os dados e grupo.'
                          : 'Cadastre e organize para a lista.',
                      style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 11,
                          height: 1.35,
                          fontWeight: FontWeight.w500),
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

  Widget buildSectionTitle(
      {required IconData icon, required String title, String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: primary, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        color: textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w800)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.poppins(
                          color: textMuted,
                          fontSize: 10,
                          height: 1.35,
                          fontWeight: FontWeight.w500)),
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
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        textInputAction: textInputAction,
        inputFormatters: inputFormatters,
        validator: validator,
        onChanged: onChanged,
        style: GoogleFonts.poppins(
            color: textDark, fontSize: 13, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: GoogleFonts.poppins(
              color: textMuted, fontSize: 12, fontWeight: FontWeight.w500),
          hintStyle:
              GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 12),
          prefixIcon: Icon(icon, color: primary, size: 20),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primary, width: 1.2)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.2)),
          errorStyle: const TextStyle(fontSize: 11, height: 0.9),
          errorMaxLines: 2,
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
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 130,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: selected ? primary : Colors.grey.shade200,
                width: selected ? 1.5 : 1),
            boxShadow: [
              BoxShadow(
                  color: selected
                      ? primary.withValues(alpha: 0.20)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.18)
                            : primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8)),
                    child: Icon(tipoConvidadoIcon(tipo),
                        color: selected ? Colors.white : primary, size: 16),
                  ),
                  const Spacer(),
                  if (selected)
                    const Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 16),
                ],
              ),
              const SizedBox(height: 8),
              Text(tipoConvidadoLabel(tipo),
                  style: GoogleFonts.poppins(
                      color: foreground,
                      fontSize: 12,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(tipoConvidadoDescricao(tipo),
                  style: GoogleFonts.poppins(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.88)
                          : textMuted,
                      fontSize: 10,
                      height: 1.25,
                      fontWeight: FontWeight.w500)),
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            SizedBox(
                width: 18,
                height: 18,
                child:
                    CircularProgressIndicator(strokeWidth: 2, color: primary)),
            const SizedBox(width: 10),
            Text('Carregando...',
                style: GoogleFonts.poppins(color: textMuted, fontSize: 12))
          ]),
        );
      }
      if (grupos.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFDE68A))),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded,
                color: Color(0xFFD97706), size: 18),
            const SizedBox(width: 8),
            Expanded(
                child: Text('Nenhum grupo cadastrado.',
                    style: GoogleFonts.poppins(
                        color: const Color(0xFF92400E),
                        fontSize: 11,
                        fontWeight: FontWeight.w600)))
          ]),
        );
      }
      final selectedValue = idGrupoSelecionado.value.trim().isEmpty
          ? null
          : idGrupoSelecionado.value.trim();
      final valueExists = selectedValue == null ||
          grupos.any((g) => g.idGrupo == selectedValue);

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: DropdownButtonFormField<String>(
          value: valueExists ? selectedValue : null,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Grupo',
            helperText: 'Famílias, amigos, mesas.',
            labelStyle: GoogleFonts.poppins(color: textMuted, fontSize: 12),
            helperStyle: GoogleFonts.poppins(color: textMuted, fontSize: 10),
            prefixIcon: Icon(Icons.group_outlined, color: primary, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: primary, width: 1.2)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.redAccent)),
            errorStyle: const TextStyle(fontSize: 11, height: 0.9),
          ),
          icon:
              Icon(Icons.keyboard_arrow_down_rounded, color: primary, size: 20),
          items: grupos
              .map((g) => DropdownMenuItem(
                  value: g.idGrupo,
                  child: Text(g.nome,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          color: textDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w600))))
              .toList(),
          onChanged: (v) => idGrupoSelecionado.value = v ?? '',
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Selecione um grupo'
              : null,
        ),
      );
    });
  }

  Widget buildEnviarEmailCheck() {
    return Obx(() {
      final marcado = enviarPorEmail.value;
      return InkWell(
        onTap: () => enviarPorEmail.value = !marcado,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(
            color: marcado ? primary.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: marcado
                    ? primary.withValues(alpha: 0.45)
                    : Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                    color: marcado ? primary : primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.mark_email_read_outlined,
                    color: marcado ? Colors.white : primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Enviar convite por e-mail',
                        style: GoogleFonts.poppins(
                            color: textDark,
                            fontSize: 13,
                            fontWeight: FontWeight.w800)),
                    Text('Dispara o link logo após salvar.',
                        style: GoogleFonts.poppins(
                            color: textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Checkbox(
                value: marcado,
                activeColor: primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
                onChanged: (v) => enviarPorEmail.value = v ?? false,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget buildCareSwitch() {
    return Obx(() {
      return InkWell(
        onTap: () => cuidadoEspecial.value = !cuidadoEspecial.value,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                cuidadoEspecial.value ? const Color(0xFFECFDF5) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: cuidadoEspecial.value
                    ? const Color(0xFF34D399)
                    : Colors.grey.shade200,
                width: 1),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                    color: cuidadoEspecial.value
                        ? const Color(0xFF10B981)
                        : primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.health_and_safety_rounded,
                    color: cuidadoEspecial.value ? Colors.white : primary,
                    size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cuidado especial',
                        style: GoogleFonts.poppins(
                            color: textDark,
                            fontSize: 13,
                            fontWeight: FontWeight.w800)),
                    Text('Atenção específica.',
                        style: GoogleFonts.poppins(
                            color: textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Switch.adaptive(
                  value: cuidadoEspecial.value,
                  activeColor: primary,
                  onChanged: (v) => cuidadoEspecial.value = v),
            ],
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.60,
      maxChildSize: 0.95,
      expand: false,
      shouldCloseOnMinExtent: false,
      builder: (_, controllerScroll) {
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
              color: background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            children: [
              buildHeader(),
              Expanded(
                child: Form(
                  key: _formKey,
                  autovalidateMode: _autovalidateMode,
                  child: ListView(
                  controller: controllerScroll,
                  padding: EdgeInsets.fromLTRB(16, 16, 16,
                      MediaQuery.of(context).viewInsets.bottom + 16),
                  children: [
                    buildSectionTitle(
                        icon: Icons.badge_outlined,
                        title: 'Dados do convidado'),
                    buildBotaoAgenda(),
                    buildTextField(
                        controller: nomeCtrl,
                        label: 'Nome',
                        icon: Icons.person_outline_rounded,
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => FormValidators.nomePessoa(
                              v,
                              campo: 'o nome do convidado',
                            )),
                    buildTextField(
                        controller: telCtrl,
                        label: 'Telefone',
                        hint: '(00) 00000-0000',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [telefoneMask],
                        validator: (v) => FormValidators.telefone(
                              v,
                              obrigatorio: false,
                            ),
                        onChanged: (v) => FormMasks.atualizarTelefone(
                              telefoneMask,
                              v,
                              controller: telCtrl,
                            )),
                    Obx(() {
                      final exigirEmail = enviarPorEmail.value;
                      return buildTextField(
                          controller: emailCtrl,
                          label: 'E-mail',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          validator: (v) => FormValidators.email(
                                v,
                                obrigatorio: exigirEmail,
                              ));
                    }),
                    const SizedBox(height: 4),
                    buildEnviarEmailCheck(),
                    const SizedBox(height: 10),
                    buildSectionTitle(
                        icon: Icons.groups_2_outlined, title: 'Classificação'),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(children: [
                        buildTipoCard(TipoConvidado.adulto),
                        const SizedBox(width: 8),
                        buildTipoCard(TipoConvidado.crianca),
                        const SizedBox(width: 8),
                        buildTipoCard(TipoConvidado.bebe)
                      ]),
                    ),
                    const SizedBox(height: 12),
                    buildGroupDropdown(),
                    const SizedBox(height: 12),
                    buildCareSwitch(),
                    const SizedBox(height: 20),
                    Obx(() {
                      final isSaving = salvando.value;
                      return SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              disabledBackgroundColor:
                                  primary.withValues(alpha: 0.45),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14))),
                          onPressed: isSaving ? null : salvarConvidado,
                          icon: isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: Colors.white,
                                  size: 18),
                          label: Text(
                              isSaving
                                  ? 'Salvando...'
                                  : editando
                                      ? 'Salvar'
                                      : 'Cadastrar',
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800)),
                        ),
                      );
                    }),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: TextButton.icon(
                        onPressed: () {
                          FocusManager.instance.primaryFocus?.unfocus();
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: Text('Cancelar',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                        style: TextButton.styleFrom(
                            foregroundColor: textMuted,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14))),
                      ),
                    ),
                    const SizedBox(height: 35),
                  ],
                ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
