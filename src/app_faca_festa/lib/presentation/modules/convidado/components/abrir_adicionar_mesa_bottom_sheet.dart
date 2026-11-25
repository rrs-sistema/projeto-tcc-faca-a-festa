import 'package:app_faca_festa/core/utils/numeric_input.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/core/utils/form_validators.dart';
import 'package:app_faca_festa/domain/entities/grupo_convidado.dart';
import 'package:app_faca_festa/domain/entities/mesa_evento.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/grupo_convidado_controller.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/mesa_evento_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'show_cadastro_bottom_sheet.dart';

Future<void> abrirAdicionarMesaBottomSheet({
  required BuildContext context,
  required String idEvento,
  required MesaEventoController controller,
  required GrupoConvidadoController grupoController,
  required EventThemeController themeController,
  MesaEvento? mesa,
}) {
  return showCadastroBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (context) => _AdicionarMesaFormContent(
      idEvento: idEvento,
      controller: controller,
      grupoController: grupoController,
      themeController: themeController,
      mesa: mesa,
    ),
  );
}

class _AdicionarMesaFormContent extends StatefulWidget {
  final String idEvento;
  final MesaEventoController controller;
  final GrupoConvidadoController grupoController;
  final EventThemeController themeController;
  final MesaEvento? mesa;

  const _AdicionarMesaFormContent({
    required this.idEvento,
    required this.controller,
    required this.grupoController,
    required this.themeController,
    this.mesa,
  });

  @override
  State<_AdicionarMesaFormContent> createState() =>
      _AdicionarMesaFormContentState();
}

class _AdicionarMesaFormContentState extends State<_AdicionarMesaFormContent> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _numeroCtrl;
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _capacidadeCtrl;
  String? _idGrupoSelecionado;
  bool _salvando = false;
  bool _nomeEditadoManual = false;

  bool get _editando => widget.mesa != null;

  int get _proximoNumero {
    final usados = widget.controller.mesas.map((m) => m.numeroMesa).toSet();
    var n = 1;
    while (usados.contains(n)) {
      n++;
    }
    return n;
  }

  @override
  void initState() {
    super.initState();
    final mesa = widget.mesa;
    final numeroInicial = mesa?.numeroMesa ?? _proximoNumero;
    _numeroCtrl = TextEditingController(text: numeroInicial.toString());
    _nomeCtrl = TextEditingController(
      text: mesa?.nomeMesa ?? 'Mesa $numeroInicial',
    );
    _capacidadeCtrl = TextEditingController(
      text: (mesa?.capacidadeAssentos ??
              MesaEventoController.capacidadePadraoSeed)
          .toString(),
    );
    _idGrupoSelecionado = mesa?.idGrupo;
    _nomeEditadoManual = mesa != null;
    _numeroCtrl.addListener(_aoMudarNumero);
  }

  void _aoMudarNumero() {
    if (_nomeEditadoManual || _editando) return;
    final n = int.tryParse(_numeroCtrl.text.trim());
    if (n == null) return;
    final sugerido = 'Mesa $n';
    if (_nomeCtrl.text != sugerido) {
      _nomeCtrl.value = TextEditingValue(
        text: sugerido,
        selection: TextSelection.collapsed(offset: sugerido.length),
      );
    }
  }

  @override
  void dispose() {
    _numeroCtrl.removeListener(_aoMudarNumero);
    _numeroCtrl.dispose();
    _nomeCtrl.dispose();
    _capacidadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final primary = widget.themeController.primaryColor.value;
    final grupos = widget.grupoController.grupos.toList();

    return FractionallySizedBox(
      heightFactor: 0.88,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: bottomInset + 16,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 50,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Header(
                    title: _editando ? 'Editar mesa' : 'Nova mesa',
                    subtitle: _editando
                        ? 'Ajuste número, lugares e vínculo'
                        : 'Espelho do salão físico alugado',
                    icon: _editando
                        ? Icons.edit_rounded
                        : Icons.table_restaurant_rounded,
                    color: primary,
                  ),
                  const SizedBox(height: 10),
                  Divider(
                    height: 1,
                    color:
                        theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Identificação',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _textField(
                            controller: _numeroCtrl,
                            label: 'Número da mesa',
                            icon: Icons.table_bar_outlined,
                            requiredField: true,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              final erro = FormValidators.inteiroNaoNegativo(
                                v,
                                campo: 'o número da mesa',
                                obrigatorio: true,
                              );
                              if (erro != null) return erro;
                              final n = int.tryParse(v!.trim()) ?? 0;
                              if (n < 1) return 'Informe um número a partir de 1.';
                              final conflito = widget.controller.mesas.any(
                                (m) =>
                                    m.numeroMesa == n &&
                                    m.idMesa != widget.mesa?.idMesa,
                              );
                              if (conflito) {
                                return 'Já existe uma mesa com este número.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _textField(
                            controller: _nomeCtrl,
                            label: 'Nome da mesa',
                            icon: Icons.badge_outlined,
                            requiredField: true,
                            onChanged: (_) => _nomeEditadoManual = true,
                            validator: (v) => FormValidators.titulo(
                              v,
                              campo: 'o nome da mesa',
                              minimo: 2,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Capacidade física',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _textField(
                            controller: _capacidadeCtrl,
                            label: 'Assentos',
                            icon: Icons.event_seat_outlined,
                            requiredField: true,
                            keyboardType: TextInputType.number,
                            helper:
                                'Quantidade de lugares nesta mesa no salão.',
                            validator: (v) {
                              final erro = FormValidators.inteiroNaoNegativo(
                                v,
                                campo: 'a capacidade',
                                obrigatorio: true,
                              );
                              if (erro != null) return erro;
                              final n = int.tryParse(v!.trim()) ?? 0;
                              if (n < 1) {
                                return 'Informe pelo menos 1 assento.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            children: [6, 8, 10, 12]
                                .map(
                                  (n) => ChoiceChip(
                                    label: Text('$n lugares'),
                                    selected: _capacidadeCtrl.text.trim() ==
                                        n.toString(),
                                    onSelected: (_) {
                                      setState(() {
                                        _capacidadeCtrl.text = n.toString();
                                      });
                                    },
                                    selectedColor:
                                        primary.withValues(alpha: 0.18),
                                    labelStyle: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF374151),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Organização (opcional)',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sugere um grupo social, sem misturar com a mesa física.',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Builder(
                            builder: (context) {
                              final porId = <String, GrupoConvidado>{
                                for (final g in grupos) g.idGrupo: g,
                              };
                              final itens =
                                  porId.values.toList(growable: false);
                              final idAtual = _idGrupoSelecionado?.trim();
                              final valueSeguro = idAtual != null &&
                                      idAtual.isNotEmpty &&
                                      porId.containsKey(idAtual)
                                  ? idAtual
                                  : null;
                              if (_idGrupoSelecionado != null &&
                                  valueSeguro == null) {
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  if (!mounted) return;
                                  if (_idGrupoSelecionado != null) {
                                    setState(() => _idGrupoSelecionado = null);
                                  }
                                });
                              }
                              return DropdownButtonFormField<String?>(
                                value: valueSeguro,
                                decoration: _inputDecoration(
                                  label: 'Grupo sugerido',
                                  icon: Icons.groups_outlined,
                                ),
                                items: [
                                  const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text('Nenhum'),
                                  ),
                                  ...itens.map(
                                    (GrupoConvidado g) =>
                                        DropdownMenuItem<String?>(
                                      value: g.idGrupo,
                                      child: Text(g.nome),
                                    ),
                                  ),
                                ],
                                onChanged: (value) => setState(
                                  () => _idGrupoSelecionado = value,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                  _FooterActions(
                    isSaving: _salvando,
                    onSubmit: _salvar,
                    primaryColor: primary,
                    submitLabel: _editando ? 'Salvar alterações' : 'Criar mesa',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool requiredField = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? helper,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      inputFormatters: keyboardType == TextInputType.number
          ? NumericInput.inteiro
          : null,
      style: GoogleFonts.poppins(fontSize: 13),
      decoration: _inputDecoration(
        label: requiredField ? '$label *' : label,
        icon: icon,
        helper: helper,
      ),
      validator: validator,
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? helper,
  }) {
    return InputDecoration(
      labelText: label,
      helperText: helper,
      helperMaxLines: 2,
      labelStyle: GoogleFonts.poppins(fontSize: 13),
      helperStyle: GoogleFonts.poppins(
        fontSize: 10,
        color: const Color(0xFF6B7280),
      ),
      prefixIcon: Icon(icon, size: 18),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: widget.themeController.primaryColor.value,
          width: 1.2,
        ),
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);

    try {
      final numero = int.parse(_numeroCtrl.text.trim());
      final capacidade = int.parse(_capacidadeCtrl.text.trim());
      final nome = _nomeCtrl.text.trim();
      final grupo = widget.grupoController.grupos.firstWhereOrNull(
        (g) => g.idGrupo == _idGrupoSelecionado,
      );

      final cor = widget.themeController.primaryColor.value;
      final corHex =
          '#${cor.r.toInt().toRadixString(16).padLeft(2, '0')}'
          '${cor.g.toInt().toRadixString(16).padLeft(2, '0')}'
          '${cor.b.toInt().toRadixString(16).padLeft(2, '0')}'.toUpperCase();

      final existente = widget.mesa;
      if (existente != null) {
        // Edição: nunca cria documento novo — só atualiza o ID existente.
        await widget.controller.atualizarMesa(
          existente.copyWith(
            numeroMesa: numero,
            nomeMesa: nome,
            capacidadeAssentos: capacidade,
            idGrupo: grupo?.idGrupo,
            nomeGrupo: grupo?.nome,
            limparGrupo: grupo == null,
            corHex: corHex,
          ),
        );
      } else {
        final conflito = widget.controller.mesas.any(
          (m) => m.numeroMesa == numero,
        );
        if (conflito) {
          throw StateError('Já existe uma mesa com o número $numero.');
        }
        // ID estável por número: evita duplicar seed (4/6) com timestamp.
        await widget.controller.adicionarMesa(
          MesaEvento(
            idMesa: MesaEventoController.idMesaInicial(widget.idEvento, numero),
            idEvento: widget.idEvento,
            numeroMesa: numero,
            nomeMesa: nome,
            capacidadeAssentos: capacidade,
            idGrupo: grupo?.idGrupo,
            nomeGrupo: grupo?.nome,
            corHex: corHex,
          ),
        );
      }
      if (mounted) Get.back<void>();
    } catch (e) {
      final detalhe = e is StateError
          ? e.message
          : 'Verifique os dados e tente novamente.';
      Get.snackbar(
        _editando
            ? 'Não foi possível atualizar a mesa'
            : 'Não foi possível salvar a mesa',
        detalhe,
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

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _Header({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FooterActions extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onSubmit;
  final Color primaryColor;
  final String submitLabel;

  const _FooterActions({
    required this.isSaving,
    required this.onSubmit,
    required this.primaryColor,
    required this.submitLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isSaving ? null : () => Get.back<void>(),
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Cancelar', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: isSaving ? null : onSubmit,
            icon: isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_outlined, size: 16),
            label: Text(
              isSaving ? 'Salvando...' : submitLabel,
              style: const TextStyle(fontSize: 13),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
