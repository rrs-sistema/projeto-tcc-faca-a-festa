// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/presentation/modules/convidado/controllers/cardapio_controller.dart';
import 'package:app_faca_festa/core/utils/form_validators.dart';
import 'package:app_faca_festa/domain/entities/cardapio.dart';
import 'cardapio_visual_options.dart';

class EditarCardapioBottomSheet extends StatefulWidget {
  final Cardapio cardapio;
  final CardapioController controller;
  final Color primaryColor;

  const EditarCardapioBottomSheet({
    super.key,
    required this.cardapio,
    required this.controller,
    required this.primaryColor,
  });

  @override
  State<EditarCardapioBottomSheet> createState() =>
      _EditarCardapioBottomSheetState();
}

class _EditarCardapioBottomSheetState extends State<EditarCardapioBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tituloCtrl;
  late IconData _iconeSelecionado;
  late Color _corSelecionada;
  late EscopoCardapio _escopo;
  late PublicoAlvoCardapio _publico;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _escopo = widget.cardapio.escopo;
    _publico = widget.cardapio.publicoAlvo;
    _tituloCtrl = TextEditingController(text: widget.cardapio.titulo);
    _iconeSelecionado =
        CardapioVisualOptions.iconeDeValor(widget.cardapio.icone);
    _corSelecionada =
        CardapioVisualOptions.corDeHex(widget.cardapio.corHex);
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    super.dispose();
  }

  InputDecoration _decoracao(String label, {IconData? icone}) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      prefixIcon: icone == null ? null : Icon(icone, size: 20),
      filled: true,
      fillColor: const Color(0xFFF8FAF9),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: widget.primaryColor, width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final teclado = MediaQuery.viewInsetsOf(context).bottom;
    final primary = widget.primaryColor;
    final icones =
        CardapioVisualOptions.gradeComSelecionado(_iconeSelecionado);
    final cores = CardapioVisualOptions.coresComSelecionada(_corSelecionada);

    return FractionallySizedBox(
      heightFactor: 0.92,
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(bottom: teclado),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(999)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14)),
                        child: Icon(Icons.edit_note_rounded,
                            color: primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Editar cardápio',
                                style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800)),
                            Text('Ajuste título, tipo, ícone e cor',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _tituloCtrl,
                            enabled: !_salvando,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600),
                            decoration: _decoracao('Título',
                                icone: Icons.text_fields_rounded),
                            validator: (value) => FormValidators.titulo(value,
                                campo: 'o título', minimo: 2),
                          ),
                          const SizedBox(height: 18),
                          Text('Tipo do cardápio',
                              style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          for (final e in EscopoCardapio.values)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Material(
                                color: _escopo == e
                                    ? primary.withValues(alpha: 0.1)
                                    : Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(
                                        color: _escopo == e
                                            ? primary
                                            : const Color(0xFFE2E8F0),
                                        width: _escopo == e ? 1.6 : 1)),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: _salvando
                                      ? null
                                      : () => setState(() => _escopo = e),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 12),
                                    child: Row(children: [
                                      Icon(
                                          _escopo == e
                                              ? Icons.radio_button_checked
                                              : Icons.radio_button_off,
                                          color: _escopo == e
                                              ? primary
                                              : const Color(0xFF94A3B8),
                                          size: 22),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                CardapioVisualOptions
                                                    .labelEscopoCurto(e),
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: _escopo == e
                                                        ? primary
                                                        : const Color(
                                                            0xFF0F172A))),
                                            Text(
                                                CardapioVisualOptions
                                                    .ajudaEscopo(e),
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF64748B))),
                                          ],
                                        ),
                                      ),
                                    ]),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text('Público principal',
                              style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final p in PublicoAlvoCardapio.values)
                                ChoiceChip(
                                  label: Text(
                                      CardapioVisualOptions.labelPublico(p)),
                                  selected: _publico == p,
                                  onSelected: _salvando
                                      ? null
                                      : (_) => setState(() => _publico = p),
                                  selectedColor:
                                      primary.withValues(alpha: 0.14),
                                  labelStyle: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: _publico == p
                                          ? primary
                                          : const Color(0xFF334155)),
                                  side: BorderSide(
                                      color: _publico == p
                                          ? primary
                                          : const Color(0xFFCBD5E1)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text('Ícone',
                              style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (final icon in icones)
                                Material(
                                  color: _iconeSelecionado.codePoint ==
                                          icon.codePoint
                                      ? primary.withValues(alpha: 0.14)
                                      : const Color(0xFFF8FAFC),
                                  shape: CircleBorder(
                                      side: BorderSide(
                                          color: _iconeSelecionado
                                                      .codePoint ==
                                                  icon.codePoint
                                              ? primary
                                              : const Color(0xFFE2E8F0),
                                          width: _iconeSelecionado
                                                      .codePoint ==
                                                  icon.codePoint
                                              ? 2
                                              : 1)),
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    onTap: _salvando
                                        ? null
                                        : () => setState(
                                            () => _iconeSelecionado = icon),
                                    customBorder: const CircleBorder(),
                                    child: SizedBox(
                                      width: 46,
                                      height: 46,
                                      child: Icon(icon,
                                          size: 22,
                                          color: _iconeSelecionado
                                                      .codePoint ==
                                                  icon.codePoint
                                              ? primary
                                              : const Color(0xFF64748B)),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text('Cor',
                              style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (final color in cores)
                                Material(
                                  color: color,
                                  shape: CircleBorder(
                                      side: BorderSide(
                                          color: CardapioVisualOptions.mesmaCor(
                                                  _corSelecionada, color)
                                              ? const Color(0xFF0F172A)
                                              : Colors.white,
                                          width: CardapioVisualOptions.mesmaCor(
                                                  _corSelecionada, color)
                                              ? 2.5
                                              : 1)),
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    onTap: _salvando
                                        ? null
                                        : () => setState(
                                            () => _corSelecionada = color),
                                    customBorder: const CircleBorder(),
                                    child: SizedBox(
                                      width: 36,
                                      height: 36,
                                      child: CardapioVisualOptions.mesmaCor(
                                              _corSelecionada, color)
                                          ? const Icon(Icons.check_rounded,
                                              color: Colors.white, size: 18)
                                          : null,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _salvando ? null : () => Get.back<void>(),
                          style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14))),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _salvando ? null : _salvar,
                          icon: _salvando
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check_rounded, size: 18),
                          label: Text(_salvando ? 'Salvando…' : 'Salvar'),
                          style: FilledButton.styleFrom(
                              backgroundColor: primary,
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14))),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);

    try {
      final atualizado = Cardapio(
        idCardapio: widget.cardapio.idCardapio,
        idEvento: widget.cardapio.idEvento,
        titulo: _tituloCtrl.text.trim(),
        escopo: _escopo,
        icone: _iconeSelecionado.codePoint.toString(),
        corHex: CardapioVisualOptions.corParaHex(_corSelecionada),
        publicoAlvo: _publico,
        totalItens: widget.cardapio.totalItens,
        totalComidas: widget.cardapio.totalComidas,
        totalBebidas: widget.cardapio.totalBebidas,
        totalSobremesas: widget.cardapio.totalSobremesas,
        ativo: widget.cardapio.ativo,
        somenteModelo: widget.cardapio.somenteModelo,
        idModelo: widget.cardapio.idModelo,
      );
      await widget.controller.atualizarCardapio(atualizado);
      Get.back();
    } catch (_) {
      Get.snackbar(
        'Não foi possível atualizar o cardápio',
        'Verifique se você é o organizador deste evento e tente novamente.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }
}
