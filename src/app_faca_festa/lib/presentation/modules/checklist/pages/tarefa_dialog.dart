import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:app_faca_festa/core/utils/form_validators.dart';
import 'package:app_faca_festa/domain/entities/convidado.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';

Future<void> showTarefaDialog({
  required BuildContext context,
  required EventThemeController themeController,
  required String? idUsuarioLogado,
  String? idEvento,
  String? tituloInicial,
  String? descricaoInicial,
  DateTime? dataInicial,
  Convidado? responsavelInicial,
  required List<Convidado> usuarios,
  bool isEdit = false,
  required Future<String?> Function(
    String titulo,
    String descricao,
    DateTime? data,
    Convidado responsavel,
  ) onSave,
}) async {
  final tituloController = TextEditingController(text: tituloInicial ?? '');
  final descricaoController =
      TextEditingController(text: descricaoInicial ?? '');
  final formKey = GlobalKey<FormState>();
  final RxBool salvando = false.obs;
  final usuariosElegiveis = _deduplicarElegiveis(
    usuarios.where((item) => item.podeSerResponsavelTarefa),
  );
  String? erroResponsavel;
  DateTime? dataSelecionada = dataInicial;
  var responsavelSelecionado = _responsavelInicial(
    usuariosElegiveis,
    responsavelInicial,
    idUsuarioLogado,
    manterSomenteInformado: isEdit,
  );

  final primary = themeController.primaryColor.value;
  final gradient = themeController.gradient.value;
  const background = Color(0xFFF8FAFC);
  const textDark = Color(0xFF1F2937);
  const textMuted = Color(0xFF64748B);

  Future<void> salvar(
    BuildContext modalContext,
    void Function(void Function()) setState,
  ) async {
    if (salvando.value) return;
    final formValido = formKey.currentState?.validate() ?? false;
    if (!formValido || responsavelSelecionado == null) {
      setState(() {
        erroResponsavel = responsavelSelecionado == null
            ? 'Escolha quem faz esta tarefa'
            : null;
      });
      return;
    }

    final titulo = tituloController.text.trim();
    try {
      salvando.value = true;
      final erro = await onSave(
        titulo,
        descricaoController.text.trim(),
        dataSelecionada,
        responsavelSelecionado!,
      );
      if (erro != null && erro.isNotEmpty) {
        Get.snackbar(
          'Erro',
          'Não foi possível salvar a tarefa.',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(12),
          borderRadius: 12,
        );
        return;
      }

      FocusManager.instance.primaryFocus?.unfocus();
      HapticFeedback.lightImpact();
      if (modalContext.mounted) {
        Navigator.of(modalContext).pop();
      }
      Get.snackbar(
        isEdit ? 'Tarefa atualizada' : 'Tarefa adicionada',
        titulo,
        backgroundColor: primary,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
        icon: const Icon(Icons.check_circle_outline_rounded,
            color: Colors.white),
      );
    } finally {
      salvando.value = false;
    }
  }

  Widget buildDragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
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
                  isEdit ? Icons.edit_note_rounded : Icons.task_alt_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit ? 'Editar tarefa' : 'Nova tarefa',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEdit
                          ? 'Ajuste o que falta, o prazo e quem faz.'
                          : 'Anote o que falta até o dia da festa.',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 12,
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

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputAction textInputAction = TextInputAction.next,
    int maxLines = 1,
    bool autofocus = false,
    String? Function(String?)? validator,
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
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        autofocus: autofocus,
        textCapitalization: textCapitalization,
        textInputAction: textInputAction,
        maxLines: maxLines,
        validator: validator,
        style: GoogleFonts.poppins(
          color: textDark,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          alignLabelWithHint: maxLines > 1,
          labelStyle: GoogleFonts.poppins(
            color: textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          hintStyle:
              GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 12),
          prefixIcon: Column(
            mainAxisAlignment: maxLines > 1
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.only(top: maxLines > 1 ? 16.0 : 0),
                child: Icon(icon, color: primary, size: 20),
              ),
            ],
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: primary, width: 1.2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
          ),
          errorStyle: const TextStyle(fontSize: 11, height: 0.9),
          errorMaxLines: 2,
        ),
      ),
    );
  }

  try {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        final teclado = MediaQuery.viewInsetsOf(modalContext).bottom;
        final base = MediaQuery.paddingOf(modalContext).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: teclado),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              color: background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: StatefulBuilder(
              builder: (context, setState) {
                Future<void> escolherData() async {
                  final agora = DateTime.now();
                  final inicio = DateTime(2000);
                  final fim = DateTime(2100);
                  var inicial = dataSelecionada ?? agora;
                  if (inicial.isBefore(inicio)) inicial = inicio;
                  if (inicial.isAfter(fim)) inicial = fim;
                  final novaData = await showDatePicker(
                    context: modalContext,
                    initialDate: inicial,
                    firstDate: inicio,
                    lastDate: fim,
                    locale: const Locale('pt', 'BR'),
                    helpText: 'Escolher prazo',
                    cancelText: 'Cancelar',
                    confirmText: 'Ok',
                  );
                  if (novaData == null) return;
                  setState(() {
                    dataSelecionada = DateTime(
                      novaData.year,
                      novaData.month,
                      novaData.day,
                    );
                  });
                }

                return Form(
                  key: formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        buildHeader(),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            16,
                            16,
                            8 + (teclado > 0 ? 0 : base),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildTextField(
                                controller: tituloController,
                                label: 'O que fazer',
                                hint: 'Ex.: Cotar o vestido',
                                icon: Icons.edit_outlined,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                autofocus: true,
                                validator: (v) => FormValidators.titulo(
                                  v,
                                  campo: 'o que fazer',
                                ),
                              ),
                              buildTextField(
                                controller: descricaoController,
                                label: 'Detalhe',
                                hint: 'Opcional',
                                icon: Icons.notes_outlined,
                                maxLines: 3,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                textInputAction: TextInputAction.newline,
                                validator: (v) => FormValidators.descricao(
                                  v,
                                  campo: 'o detalhe',
                                  minimo: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Prazo',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: textDark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _PrazoChip(
                                    rotulo: 'Sem prazo',
                                    selecionado: dataSelecionada == null,
                                    primary: primary,
                                    onTap: () => setState(
                                      () => dataSelecionada = null,
                                    ),
                                  ),
                                  _PrazoChip(
                                    rotulo: 'Hoje',
                                    selecionado: _mesmoDia(
                                      dataSelecionada,
                                      DateTime.now(),
                                    ),
                                    primary: primary,
                                    onTap: () => setState(
                                      () => dataSelecionada = _hoje(),
                                    ),
                                  ),
                                  _PrazoChip(
                                    rotulo: 'Amanhã',
                                    selecionado: _mesmoDia(
                                      dataSelecionada,
                                      DateTime.now()
                                          .add(const Duration(days: 1)),
                                    ),
                                    primary: primary,
                                    onTap: () => setState(
                                      () => dataSelecionada =
                                          _hoje().add(const Duration(days: 1)),
                                    ),
                                  ),
                                  _PrazoChip(
                                    rotulo: _rotuloOutraData(dataSelecionada),
                                    selecionado:
                                        _dataPersonalizada(dataSelecionada),
                                    primary: primary,
                                    icone: Icons.calendar_today_outlined,
                                    onTap: escolherData,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Quem faz',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: textDark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (usuariosElegiveis.isEmpty)
                                Text(
                                  'Ninguém com conta no app ainda. A pessoa precisa entrar com o mesmo e-mail do convite.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    height: 1.35,
                                    color: textMuted,
                                  ),
                                )
                              else
                                for (final usuario in usuariosElegiveis) ...[
                                  _PessoaTile(
                                    usuario: usuario,
                                    voce: _ehUsuario(usuario, idUsuarioLogado),
                                    selecionado: responsavelSelecionado !=
                                            null &&
                                        usuario.mesmoIdentificador(
                                          responsavelSelecionado!,
                                        ),
                                    primary: primary,
                                    onTap: () => setState(() {
                                      responsavelSelecionado = usuario;
                                      erroResponsavel = null;
                                    }),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              if (erroResponsavel != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    erroResponsavel!,
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFFB91C1C),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Obx(() {
                                final isSaving = salvando.value;
                                return SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primary,
                                      disabledBackgroundColor:
                                          primary.withValues(alpha: 0.45),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: isSaving
                                        ? null
                                        : () => salvar(modalContext, setState),
                                    icon: isSaving
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.check_circle_outline_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                    label: Text(
                                      isSaving ? 'Salvando...' : 'Salvar tarefa',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: TextButton(
                                  onPressed: () {
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                    Navigator.of(modalContext).pop();
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: textMuted,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    'Cancelar',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  } finally {
    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.delayed(const Duration(milliseconds: 350));
    tituloController.dispose();
    descricaoController.dispose();
  }
}

class _PrazoChip extends StatelessWidget {
  const _PrazoChip({
    required this.rotulo,
    required this.selecionado,
    required this.primary,
    required this.onTap,
    this.icone,
  });

  final String rotulo;
  final bool selecionado;
  final Color primary;
  final VoidCallback onTap;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selecionado ? primary.withValues(alpha: 0.1) : Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selecionado ? primary : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icone != null) ...[
                Icon(
                  icone,
                  size: 16,
                  color: selecionado ? primary : const Color(0xFF4B5563),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                rotulo,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selecionado ? primary : const Color(0xFF374151),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PessoaTile extends StatelessWidget {
  const _PessoaTile({
    required this.usuario,
    required this.voce,
    required this.selecionado,
    required this.primary,
    required this.onTap,
  });

  final Convidado usuario;
  final bool voce;
  final bool selecionado;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nome = usuario.nome.trim();
    return Material(
      color: selecionado ? primary.withValues(alpha: 0.08) : Colors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selecionado ? primary : Colors.grey.shade200,
                width: selecionado ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      selecionado ? primary : const Color(0xFFE5E7EB),
                  child: Text(
                    _iniciais(nome),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selecionado
                          ? Colors.white
                          : const Color(0xFF374151),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      if (voce)
                        Text(
                          'Você',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: primary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (selecionado)
                  Icon(Icons.check_circle_rounded, color: primary, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Convidado? _responsavelInicial(
  List<Convidado> lista,
  Convidado? inicial,
  String? idUsuarioLogado, {
  required bool manterSomenteInformado,
}) {
  if (inicial != null) {
    for (final item in lista) {
      if (item.mesmoIdentificador(inicial)) return item;
    }
    if (inicial.podeSerResponsavelTarefa) return inicial;
  }
  if (manterSomenteInformado) return null;
  final id = idUsuarioLogado?.trim() ?? '';
  if (id.isNotEmpty) {
    for (final item in lista) {
      if (_ehUsuario(item, id)) return item;
    }
  }
  if (lista.length == 1) return lista.first;
  return null;
}

bool _ehUsuario(Convidado usuario, String? idUsuario) {
  final id = idUsuario?.trim() ?? '';
  if (id.isEmpty) return false;
  return usuario.idConvidado.trim() == id || usuario.idUsuario?.trim() == id;
}

DateTime _hoje() {
  final agora = DateTime.now();
  return DateTime(agora.year, agora.month, agora.day);
}

bool _mesmoDia(DateTime? data, DateTime outra) {
  if (data == null) return false;
  return data.year == outra.year &&
      data.month == outra.month &&
      data.day == outra.day;
}

bool _dataPersonalizada(DateTime? data) {
  if (data == null) return false;
  final hoje = _hoje();
  final amanha = hoje.add(const Duration(days: 1));
  return !_mesmoDia(data, hoje) && !_mesmoDia(data, amanha);
}

String _rotuloOutraData(DateTime? data) {
  if (!_dataPersonalizada(data)) return 'Outra data';
  return DateFormat('dd/MM/yyyy').format(data!);
}

String _iniciais(String nome) {
  final partes =
      nome.split(RegExp(r'\s+')).where((parte) => parte.isNotEmpty).toList();
  if (partes.isEmpty) return '?';
  String letra(String parte) {
    final runas = parte.runes;
    if (runas.isEmpty) return '';
    return String.fromCharCode(runas.first).toUpperCase();
  }

  if (partes.length == 1) return letra(partes.first);
  return '${letra(partes.first)}${letra(partes.last)}';
}

List<Convidado> _deduplicarElegiveis(Iterable<Convidado> origem) {
  final vistos = <String>{};
  final resultado = <Convidado>[];
  for (final item in origem) {
    final id = item.idConvidado.trim();
    final chave =
        id.isNotEmpty ? 'id:$id' : 'email:${item.emailNormalizadoEfetivo}';
    if (chave.endsWith(':') || !vistos.add(chave)) continue;
    resultado.add(item);
  }
  return resultado;
}
