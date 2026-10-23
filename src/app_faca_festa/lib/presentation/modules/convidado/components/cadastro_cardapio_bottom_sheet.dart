// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/presentation/modules/convidado/controllers/cardapio_controller.dart';
import 'package:app_faca_festa/core/utils/form_validators.dart';
import 'package:app_faca_festa/domain/entities/cardapio.dart';
import 'cardapio_visual_options.dart';

class CadastroCardapioBottomSheet extends StatefulWidget {
  final String idEvento;
  final CardapioController controller;
  final Color primaryColor;

  const CadastroCardapioBottomSheet({
    super.key,
    required this.idEvento,
    required this.controller,
    required this.primaryColor,
  });

  @override
  State<CadastroCardapioBottomSheet> createState() =>
      _CadastroCardapioBottomSheetState();
}

class _CadastroCardapioBottomSheetState
    extends State<CadastroCardapioBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tituloCtrl;

  IconData _iconeSelecionado = Icons.restaurant_menu_rounded;
  Color _corSelecionada = const Color(0xFF0D9488);
  bool _salvando = false;
  EscopoCardapio _escopo = EscopoCardapio.refeicao;
  PublicoAlvoCardapio _publico = PublicoAlvoCardapio.todos;

  @override
  void initState() {
    super.initState();
    _tituloCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    super.dispose();
  }

  void _aplicarPreset(CardapioPreset p) {
    setState(() {
      _tituloCtrl.text = p.titulo;
      _iconeSelecionado = p.icone;
      _corSelecionada = p.cor;
      _escopo = p.escopo;
    });
  }

  InputDecoration _decoracao(String label, {String? hint, IconData? icone}) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
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
                        child: Icon(Icons.menu_book_rounded,
                            color: primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Novo cardápio',
                                style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800)),
                            Text('Comece por um modelo ou personalize',
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
                          _Aviso(
                            cor: primary,
                            texto:
                                'Criar o cardápio não agenda serviços. Depois, use a Agenda de refeições para marcar data e horário.',
                          ),
                          const SizedBox(height: 16),
                          Text('Sugestões rápidas',
                              style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text('Toque para preencher título, ícone e tipo.',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final p in CardapioVisualOptions.presets)
                                _PresetChip(
                                  preset: p,
                                  selecionado: _tituloCtrl.text.trim() ==
                                          p.titulo &&
                                      _iconeSelecionado.codePoint ==
                                          p.icone.codePoint,
                                  onTap: _salvando
                                      ? null
                                      : () => _aplicarPreset(p),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _tituloCtrl,
                            enabled: !_salvando,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600),
                            decoration: _decoracao('Título',
                                hint: 'Ex.: Almoço do sábado',
                                icone: Icons.text_fields_rounded),
                            validator: (value) => FormValidators.titulo(value,
                                campo: 'o título', minimo: 2),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 18),
                          Text('Tipo do cardápio',
                              style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          for (final e in EscopoCardapio.values)
                            if (e != EscopoCardapio.naoDefinido)
                              _OpcaoEscopo(
                                titulo:
                                    CardapioVisualOptions.labelEscopoCurto(e),
                                ajuda: CardapioVisualOptions.ajudaEscopo(e),
                                selecionado: _escopo == e,
                                cor: primary,
                                onTap: _salvando
                                    ? null
                                    : () => setState(() => _escopo = e),
                              ),
                          const SizedBox(height: 14),
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
                                _IconeOpcao(
                                  icone: icon,
                                  selecionado: _iconeSelecionado.codePoint ==
                                      icon.codePoint,
                                  cor: primary,
                                  onTap: _salvando
                                      ? null
                                      : () => setState(
                                          () => _iconeSelecionado = icon),
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
                                _CorOpcao(
                                  cor: color,
                                  selecionado: CardapioVisualOptions.mesmaCor(
                                      _corSelecionada, color),
                                  onTap: _salvando
                                      ? null
                                      : () => setState(
                                          () => _corSelecionada = color),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
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
                        flex: 1,
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
      final novo = Cardapio(
        idCardapio: DateTime.now().millisecondsSinceEpoch.toString(),
        idEvento: widget.idEvento,
        titulo: _tituloCtrl.text.trim(),
        escopo: _escopo,
        icone: _iconeSelecionado.codePoint.toString(),
        corHex: CardapioVisualOptions.corParaHex(_corSelecionada),
        publicoAlvo: _publico,
        totalItens: 0,
        totalComidas: 0,
        totalBebidas: 0,
        totalSobremesas: 0,
        ativo: true,
      );
      await widget.controller.adicionarCardapio(novo);
      Get.back();
    } catch (_) {
      Get.snackbar(
        'Não foi possível salvar o cardápio',
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

class _Aviso extends StatelessWidget {
  const _Aviso({required this.cor, required this.texto});
  final Color cor;
  final String texto;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.info_outline_rounded, size: 18, color: cor),
        const SizedBox(width: 10),
        Expanded(
            child: Text(texto,
                style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: Theme.of(context).colorScheme.onSurface))),
      ]));
}

class _PresetChip extends StatelessWidget {
  const _PresetChip(
      {required this.preset,
      required this.selecionado,
      required this.onTap});
  final CardapioPreset preset;
  final bool selecionado;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: selecionado
          ? preset.cor.withValues(alpha: 0.14)
          : const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(
              color: selecionado ? preset.cor : const Color(0xFFE2E8F0),
              width: selecionado ? 1.5 : 1)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(preset.icone, size: 16, color: preset.cor),
            const SizedBox(width: 6),
            Text(preset.titulo,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: selecionado
                        ? preset.cor
                        : const Color(0xFF334155))),
          ]),
        ),
      ),
    );
  }
}

class _OpcaoEscopo extends StatelessWidget {
  const _OpcaoEscopo(
      {required this.titulo,
      required this.ajuda,
      required this.selecionado,
      required this.cor,
      required this.onTap});
  final String titulo, ajuda;
  final bool selecionado;
  final Color cor;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selecionado ? cor.withValues(alpha: 0.1) : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
                color: selecionado ? cor : const Color(0xFFE2E8F0),
                width: selecionado ? 1.6 : 1)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(children: [
              Icon(
                  selecionado
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: selecionado ? cor : const Color(0xFF94A3B8),
                  size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: selecionado
                                ? cor
                                : const Color(0xFF0F172A))),
                    const SizedBox(height: 2),
                    Text(ajuda,
                        style: const TextStyle(
                            fontSize: 12,
                            height: 1.3,
                            color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _IconeOpcao extends StatelessWidget {
  const _IconeOpcao(
      {required this.icone,
      required this.selecionado,
      required this.cor,
      required this.onTap});
  final IconData icone;
  final bool selecionado;
  final Color cor;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: selecionado ? cor.withValues(alpha: 0.14) : const Color(0xFFF8FAFC),
      shape: CircleBorder(
          side: BorderSide(
              color: selecionado ? cor : const Color(0xFFE2E8F0),
              width: selecionado ? 2 : 1)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icone,
              size: 22,
              color: selecionado ? cor : const Color(0xFF64748B)),
        ),
      ),
    );
  }
}

class _CorOpcao extends StatelessWidget {
  const _CorOpcao(
      {required this.cor, required this.selecionado, required this.onTap});
  final Color cor;
  final bool selecionado;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: cor,
      shape: CircleBorder(
          side: BorderSide(
              color: selecionado ? const Color(0xFF0F172A) : Colors.white,
              width: selecionado ? 2.5 : 1)),
      elevation: selecionado ? 2 : 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 36,
          height: 36,
          child: selecionado
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
              : null,
        ),
      ),
    );
  }
}
