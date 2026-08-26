import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../../controllers/convidado/grupo_convidado_controller.dart';
import './../../../../core/utils/form_validators.dart';
import './../../../../data/models/convidado/grupo_convidado_model.dart';
import './../../../../controllers/tema/event_theme_controller.dart';
import 'show_cadastro_bottom_sheet.dart';

Future<void> abrirAdicionarGrupoBottomSheet({
  required BuildContext context,
  required String idEvento,
  required GrupoConvidadoController controller,
  GrupoConvidado? grupo,
}) {
  return showCadastroBottomSheet<void>(
    context: context,
    builder: (context) => _AdicionarGrupoFormContent(
      idEvento: idEvento,
      controller: controller,
      grupo: grupo,
    ),
  );
}

class _AdicionarGrupoFormContent extends StatefulWidget {
  final String idEvento;
  final GrupoConvidadoController controller;
  final GrupoConvidado? grupo;

  const _AdicionarGrupoFormContent({
    required this.idEvento,
    required this.controller,
    this.grupo,
  });

  @override
  State<_AdicionarGrupoFormContent> createState() =>
      _AdicionarGrupoFormContentState();
}

class _AdicionarGrupoFormContentState
    extends State<_AdicionarGrupoFormContent> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _numeroMesaCtrl;
  late final TextEditingController _descCtrl;

  late String _corSelecionada;
  late String _iconeSelecionado;
  bool _salvando = false;

  final cores = [
    '#0F766E',
    '#FF7BAC',
    '#FF6F91',
    '#FFD36E',
    '#8ED1C7',
    '#A493E8',
    '#6EC3F4',
    '#F5A3C7',
    '#E4C1F9',
    '#D9ED92',
  ];

  final icones = {
    'group': Icons.group_rounded,
    'family': Icons.family_restroom_rounded,
    'star': Icons.star_rounded,
    'favorite': Icons.favorite_rounded,
    'chair': Icons.chair_rounded,
    'cake': Icons.cake_rounded,
    'music': Icons.music_note_rounded,
    'work': Icons.work_rounded,
  };

  bool get _editando => widget.grupo != null;

  @override
  void initState() {
    super.initState();
    final theme = Get.find<EventThemeController>();
    final grupo = widget.grupo;
    _nomeCtrl = TextEditingController(text: grupo?.nome ?? '');
    _numeroMesaCtrl = TextEditingController();
    _descCtrl = TextEditingController(text: grupo?.descricao ?? '');
    _corSelecionada = (grupo?.corHex ?? theme.primaryColor.value.toHex())
        .trim()
        .toUpperCase();
    if (_corSelecionada.isEmpty) {
      _corSelecionada = theme.primaryColor.value.toHex();
    }
    if (!cores.any((hex) => hex.toUpperCase() == _corSelecionada)) {
      cores.insert(0, _corSelecionada);
    }
    final icone = (grupo?.icone ?? 'group').trim();
    _iconeSelecionado = icones.containsKey(icone) ? icone : 'group';
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _numeroMesaCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final primaryColor = Get.find<EventThemeController>().primaryColor.value;

    return FractionallySizedBox(
      heightFactor: 0.88,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding:
                EdgeInsets.only(left: 16, right: 16, bottom: bottomInset + 16),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 50,
                        height: 4,
                        decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _Header(
                      title: _editando ? 'Editar grupo' : 'Novo grupo',
                      subtitle: _editando
                          ? 'Atualize nome, cor e ícone'
                          : 'Organize seus convidados',
                      icon: _editando
                          ? Icons.edit_rounded
                          : Icons.group_add_rounded,
                      color: primaryColor,
                    ),
                    const SizedBox(height: 10),
                    Divider(
                        height: 1,
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    _textField(
                      controller: _nomeCtrl,
                      label: 'Nome do grupo',
                      icon: Icons.badge_outlined,
                      requiredField: true,
                      validator: (v) => FormValidators.titulo(
                        v,
                        campo: 'o nome do grupo',
                        minimo: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _textField(
                      controller: _numeroMesaCtrl,
                      label: 'Número da mesa (opcional)',
                      icon: Icons.table_bar_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) => FormValidators.inteiroNaoNegativo(
                        v,
                        campo: 'o número da mesa',
                        obrigatorio: false,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _textField(
                      controller: _descCtrl,
                      label: 'Descrição (opcional)',
                      icon: Icons.notes_rounded,
                      maxLines: 2,
                      validator: (v) => FormValidators.descricao(
                        v,
                        campo: 'a descrição',
                        obrigatorio: false,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Cor do grupo',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          cores.map((hex) => _buildColorOption(hex)).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text('Ícone',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: icones.entries
                          .map((entry) => _buildIconOption(
                              entry.key, entry.value, primaryColor))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                    _FooterActions(
                      isSaving: _salvando,
                      onSubmit: _salvar,
                      primaryColor: primaryColor,
                      submitLabel: _editando ? 'Salvar alterações' : 'Salvar',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorOption(String hex) {
    final color = Color(int.parse(hex.replaceAll('#', '0xff')));
    final selected = _corSelecionada.toUpperCase() == hex.toUpperCase();
    return GestureDetector(
      onTap: () => setState(() => _corSelecionada = hex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
              color: selected ? Colors.black54 : Colors.transparent,
              width: selected ? 2 : 0),
        ),
        child: selected
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : null,
      ),
    );
  }

  Widget _buildIconOption(String key, IconData icon, Color primaryColor) {
    final selected = _iconeSelecionado == key;
    return GestureDetector(
      onTap: () => setState(() => _iconeSelecionado = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected
              ? primaryColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: selected ? primaryColor : Colors.grey.shade300),
        ),
        child: Icon(icon,
            color: selected ? primaryColor : Colors.black54, size: 22),
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
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: requiredField ? '$label *' : label,
        labelStyle: const TextStyle(fontSize: 13),
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        errorMaxLines: 2,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      ),
      validator: validator ??
          (requiredField
              ? (value) => FormValidators.titulo(value, campo: label.toLowerCase(), minimo: 2)
              : null),
    );
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);

    try {
      final agora = DateTime.now();
      final descricao =
          _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim();
      final existente = widget.grupo;

      if (existente != null) {
        final atualizado = GrupoConvidado(
          idGrupo: existente.idGrupo,
          idEvento: existente.idEvento,
          nome: _nomeCtrl.text.trim(),
          descricao: descricao,
          icone: _iconeSelecionado,
          corHex: _corSelecionada,
          totalConvidados: existente.totalConvidados,
          totalAdultos: existente.totalAdultos,
          totalCriancas: existente.totalCriancas,
          totalBebes: existente.totalBebes,
          totalConfirmados: existente.totalConfirmados,
          dataCadastro: existente.dataCadastro,
          dataAtualizacao: agora,
        );
        await widget.controller.atualizarGrupo(atualizado);
      } else {
        final novo = GrupoConvidado(
          idGrupo: DateTime.now().millisecondsSinceEpoch.toString(),
          idEvento: widget.idEvento,
          nome: _nomeCtrl.text.trim(),
          descricao: descricao,
          icone: _iconeSelecionado,
          corHex: _corSelecionada,
          totalConvidados: 0,
          totalAdultos: 0,
          totalCriancas: 0,
          totalBebes: 0,
          totalConfirmados: 0,
          dataCadastro: agora,
          dataAtualizacao: agora,
        );
        await widget.controller.adicionarGrupo(novo);
      }
      if (mounted) Get.back<void>();
    } catch (e) {
      Get.snackbar(
        _editando
            ? 'Não foi possível atualizar o grupo'
            : 'Não foi possível salvar o grupo',
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

// =========================================================================
// WIDGETS COMPARTILHADOS (Você pode mover para um arquivo separado se quiser)
// =========================================================================

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _Header(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800, fontSize: 16)),
              Text(subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
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
  const _FooterActions(
      {required this.isSaving,
      required this.onSubmit,
      required this.primaryColor,
      this.submitLabel = 'Salvar'});

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
                    borderRadius: BorderRadius.circular(12))),
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
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_outlined, size: 16),
            label: Text(isSaving ? 'Salvando...' : submitLabel,
                style: const TextStyle(fontSize: 13)),
            style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
          ),
        ),
      ],
    );
  }
}

extension ColorToHex on Color {
  String toHex({bool leadingHashSign = true}) {
    final buffer = StringBuffer();
    if (leadingHashSign) buffer.write('#');
    buffer.write((r.toInt()).toRadixString(16).padLeft(2, '0'));
    buffer.write((g.toInt()).toRadixString(16).padLeft(2, '0'));
    buffer.write((b.toInt()).toRadixString(16).padLeft(2, '0'));
    return buffer.toString().toUpperCase();
  }
}
