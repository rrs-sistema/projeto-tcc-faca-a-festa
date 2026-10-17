import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_faca_festa/core/utils/form_validators.dart';
import 'package:app_faca_festa/domain/entities/convidado.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:intl/intl.dart';
import 'responsavel_picker.dart';

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
  required Future<String?> Function(String, String, DateTime?, Convidado)
      onSave,
}) async {
  final vistos = <String>{};
  final pessoas = usuarios
      .where((p) =>
          p.podeSerResponsavelTarefa &&
          p.idEvento == idEvento &&
          vistos.add(p.idConvidado))
      .toList();
  await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFFF7F9F8),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      clipBehavior: Clip.antiAlias,
      builder: (_) => _TarefaForm(
          primary: themeController.primaryColor.value,
          pessoas: pessoas,
          idUsuarioLogado: idUsuarioLogado,
          isEdit: isEdit,
          tituloInicial: tituloInicial,
          descricaoInicial: descricaoInicial,
          dataInicial: dataInicial,
          responsavelInicial: responsavelInicial,
          onSave: onSave));
}

class _TarefaForm extends StatefulWidget {
  const _TarefaForm(
      {required this.primary,
      required this.pessoas,
      required this.idUsuarioLogado,
      required this.isEdit,
      required this.onSave,
      this.tituloInicial,
      this.descricaoInicial,
      this.dataInicial,
      this.responsavelInicial});
  final Color primary;
  final List<Convidado> pessoas;
  final String? idUsuarioLogado, tituloInicial, descricaoInicial;
  final bool isEdit;
  final DateTime? dataInicial;
  final Convidado? responsavelInicial;
  final Future<String?> Function(String, String, DateTime?, Convidado) onSave;
  @override
  State<_TarefaForm> createState() => _TarefaFormState();
}

class _TarefaFormState extends State<_TarefaForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _titulo, _descricao;
  DateTime? _data;
  Convidado? _responsavel;
  bool _salvando = false, _validar = false;
  String? _erro;
  @override
  void initState() {
    super.initState();
    _titulo = TextEditingController(text: widget.tituloInicial);
    _descricao = TextEditingController(text: widget.descricaoInicial);
    _data = widget.dataInicial;
    for (final p in widget.pessoas) {
      if (p.idConvidado == widget.responsavelInicial?.idConvidado) {
        _responsavel = p;
        break;
      }
    }
    if (!widget.isEdit && _responsavel == null) {
      for (final p in widget.pessoas) {
        if (widget.idUsuarioLogado != null &&
            (p.idUsuario == widget.idUsuarioLogado ||
                p.idConvidado == widget.idUsuarioLogado)) {
          _responsavel = p;
          break;
        }
      }
      if (_responsavel == null && widget.pessoas.length == 1) {
        _responsavel = widget.pessoas.first;
      }
    }
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descricao.dispose();
    super.dispose();
  }

  Future<void> _escolherResponsavel() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final p = await showResponsavelPicker(
        context: context,
        pessoas: widget.pessoas,
        primary: widget.primary,
        selecionadoId: _responsavel?.idConvidado,
        idUsuarioLogado: widget.idUsuarioLogado);
    if (!mounted || p == null) return;
    setState(() {
      _responsavel = p;
      _erro = null;
    });
  }

  Future<void> _escolherData() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final inicio = DateTime(2000), fim = DateTime(2100);
    final atual = _data ?? DateTime.now();
    final data = await showDatePicker(
        context: context,
        initialDate: atual.isBefore(inicio)
            ? inicio
            : atual.isAfter(fim)
                ? fim
                : atual,
        firstDate: inicio,
        lastDate: fim,
        locale: const Locale('pt', 'BR'),
        helpText: 'Prazo da tarefa',
        cancelText: 'Cancelar',
        confirmText: 'Selecionar');
    if (!mounted || data == null) return;
    setState(() => _data = data);
  }

  Future<void> _salvar() async {
    if (_salvando) return;
    setState(() {
      _validar = true;
      _erro = null;
    });
    final valido = _form.currentState!.validate();
    if (_responsavel == null) {
      setState(() => _erro = 'Escolha o responsável pela tarefa.');
      return;
    }
    if (!valido) return;
    setState(() => _salvando = true);
    try {
      final erro = await widget.onSave(
          _titulo.text.trim(), _descricao.text.trim(), _data, _responsavel!);
      if (!mounted) return;
      if (erro != null && erro.isNotEmpty) {
        setState(() => _erro = 'Não foi possível salvar. Tente novamente.');
        return;
      }
      FocusManager.instance.primaryFocus?.unfocus();
      HapticFeedback.lightImpact();
      Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _erro = 'Não foi possível salvar. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hoje = DateUtils.dateOnly(DateTime.now()),
        amanha =
            DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 1));
    final personalizada = _data != null &&
        !DateUtils.isSameDay(_data, hoje) &&
        !DateUtils.isSameDay(_data, amanha);
    return PopScope(
      canPop: !_salvando,
      child: Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * .9),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(height: 10),
                Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                        color: const Color(0xFFD7DDD9),
                        borderRadius: BorderRadius.circular(4))),
                Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
                    child: Row(children: [
                      Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: widget.primary.withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.task_alt_rounded,
                              color: widget.primary)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(
                                widget.isEdit ? 'Editar tarefa' : 'Nova tarefa',
                                style: const TextStyle(
                                    fontSize: 21, fontWeight: FontWeight.w700)),
                            const Text('O que fazer, por quem e até quando.',
                                style: TextStyle(
                                    fontSize: 12, color: Color(0xFF66736B)))
                          ])),
                      IconButton(
                          tooltip: 'Cancelar',
                          onPressed:
                              _salvando ? null : () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded)),
                    ])),
                Flexible(
                  child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                      child: Form(
                          key: _form,
                          autovalidateMode: _validar
                              ? AutovalidateMode.onUserInteraction
                              : AutovalidateMode.disabled,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('O que precisa ser feito?'),
                                TextFormField(
                                    controller: _titulo,
                                    enabled: !_salvando,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    textInputAction: TextInputAction.next,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600),
                                    decoration: _decoration(
                                        'Ex.: Montar a equipe da cozinha'),
                                    validator: (v) => FormValidators.titulo(v,
                                        campo: 'o que fazer')),
                                const SizedBox(height: 18),
                                _label('Detalhes', opcional: true),
                                TextFormField(
                                    controller: _descricao,
                                    enabled: !_salvando,
                                    minLines: 2,
                                    maxLines: 4,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    decoration: _decoration(
                                        'Informações para realizar a tarefa'),
                                    validator: (v) => FormValidators.descricao(
                                        v,
                                        campo: 'o detalhe',
                                        minimo: 1)),
                                const SizedBox(height: 18),
                                _label('Responsável'),
                                Material(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    child: InkWell(
                                        onTap:
                                            _salvando || widget.pessoas.isEmpty
                                                ? null
                                                : _escolherResponsavel,
                                        borderRadius: BorderRadius.circular(14),
                                        child: Container(
                                            padding: const EdgeInsets.all(14),
                                            decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: const Color(
                                                        0xFFE0E6E2)),
                                                borderRadius:
                                                    BorderRadius.circular(14)),
                                            child: Row(children: [
                                              CircleAvatar(
                                                  backgroundColor: widget
                                                      .primary
                                                      .withValues(alpha: .1),
                                                  foregroundColor:
                                                      widget.primary,
                                                  child: _responsavel == null
                                                      ? const Icon(Icons
                                                          .person_outline_rounded)
                                                      : Text(
                                                          iniciaisResponsavel(
                                                              _responsavel!
                                                                  .nome),
                                                          style: const TextStyle(
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700))),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                  child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                    Text(
                                                        _responsavel?.nome ??
                                                            'Escolher uma pessoa',
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 15)),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                        widget.pessoas.isEmpty
                                                            ? 'Cadastre convidados no evento'
                                                            : _responsavel ==
                                                                    null
                                                                ? 'Busque por nome ou grupo'
                                                                : 'Toque para trocar',
                                                        style: const TextStyle(
                                                            fontSize: 12,
                                                            color: Color(
                                                                0xFF66736B)))
                                                  ])),
                                              Icon(Icons.chevron_right_rounded,
                                                  color: widget.primary),
                                            ])))),
                                const SizedBox(height: 18),
                                _label('Prazo', opcional: true),
                                Wrap(spacing: 8, runSpacing: 8, children: [
                                  _prazo('Sem prazo', _data == null,
                                      () => setState(() => _data = null)),
                                  _prazo(
                                      'Hoje',
                                      DateUtils.isSameDay(_data, hoje),
                                      () => setState(() => _data = hoje)),
                                  _prazo(
                                      'Amanhã',
                                      DateUtils.isSameDay(_data, amanha),
                                      () => setState(() => _data = amanha)),
                                  _prazo(
                                      personalizada
                                          ? DateFormat('dd/MM/yyyy')
                                              .format(_data!)
                                          : 'Escolher data',
                                      personalizada,
                                      _escolherData,
                                      icone: Icons.calendar_today_outlined),
                                ]),
                              ]))),
                ),
                Container(
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      border:
                          Border(top: BorderSide(color: Color(0xFFE6EBE8)))),
                  child: SafeArea(
                      top: false,
                      child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            if (_erro != null)
                              Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Semantics(
                                      liveRegion: true,
                                      child: Text(_erro!,
                                          style: const TextStyle(
                                              color: Color(0xFFB91C1C))))),
                            SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                        backgroundColor: widget.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14))),
                                    onPressed: _salvando ? null : _salvar,
                                    icon: _salvando
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2))
                                        : const Icon(Icons.check_rounded),
                                    label: Text(
                                        _salvando
                                            ? 'Salvando…'
                                            : 'Salvar tarefa',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16)))),
                          ]))),
                ),
              ]))),
    );
  }

  Widget _label(String texto, {bool opcional = false}) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(opcional ? '$texto (opcional)' : texto,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF47574D))));
  InputDecoration _decoration(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF7B877F)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.all(14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE0E6E2))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: widget.primary, width: 1.5)));
  Widget _prazo(String texto, bool selecionado, VoidCallback onTap,
          {IconData? icone}) =>
      ChoiceChip(
          label: Text(texto),
          selected: selecionado,
          avatar: icone == null ? null : Icon(icone, size: 16),
          onSelected: _salvando ? null : (_) => onTap(),
          selectedColor: widget.primary.withValues(alpha: .1),
          backgroundColor: Colors.white,
          labelStyle: TextStyle(
              color: selecionado ? widget.primary : const Color(0xFF47574D),
              fontSize: 13,
              fontWeight: FontWeight.w600),
          side: BorderSide(
              color: selecionado ? widget.primary : const Color(0xFFE0E6E2)),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)));
}
