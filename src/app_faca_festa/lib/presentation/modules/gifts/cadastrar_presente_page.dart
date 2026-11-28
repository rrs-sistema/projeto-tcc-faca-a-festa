import 'package:app_faca_festa/core/utils/numeric_input.dart';
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:app_faca_festa/presentation/widgets/festa_imagem_rede.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import 'package:app_faca_festa/core/utils/form_validators.dart';
import 'package:app_faca_festa/domain/entities/gift/gift.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'controllers/gift_controller.dart';

void abrirDialogCadastrarPresente(
  BuildContext context, {
  Gift? presente,
  required GiftController controller,
  required EventThemeController themeController,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CadastrarPresenteSheet(
      presente: presente,
      controller: controller,
      themeController: themeController,
    ),
  );
}

class _CadastrarPresenteSheet extends StatefulWidget {
  final Gift? presente;
  final GiftController controller;
  final EventThemeController themeController;

  const _CadastrarPresenteSheet({
    required this.presente,
    required this.controller,
    required this.themeController,
  });

  @override
  State<_CadastrarPresenteSheet> createState() =>
      _CadastrarPresenteSheetState();
}

class _CadastrarPresenteSheetState extends State<_CadastrarPresenteSheet> {
  final _uuid = const Uuid();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomeCtrl;
  late final TextEditingController _descricaoCtrl;
  late final TextEditingController _valorCtrl;
  late final TextEditingController _lojaCtrl;
  late final TextEditingController _linkCtrl;
  late final TextEditingController _pixCtrl;
  late final TextEditingController _metaCtrl;
  late final TextEditingController _imagemCtrl;

  late final Rx<GiftType> _tipoSelecionado;
  final RxBool _salvando = false.obs;
  late final RxString _urlPreview;

  bool get _editando => widget.presente != null;

  @override
  void initState() {
    super.initState();
    final presente = widget.presente;
    _nomeCtrl = TextEditingController(text: presente?.nome ?? '');
    _descricaoCtrl = TextEditingController(text: presente?.descricao ?? '');
    _valorCtrl = TextEditingController(text: _valueToField(presente?.valor));
    _lojaCtrl = TextEditingController(text: presente?.loja ?? '');
    _linkCtrl = TextEditingController(text: presente?.link ?? '');
    _pixCtrl = TextEditingController(text: presente?.pix ?? '');
    _metaCtrl = TextEditingController(text: _valueToField(presente?.metaValor));
    _imagemCtrl = TextEditingController(text: presente?.imagem ?? '');

    _tipoSelecionado = (presente?.tipo ?? GiftType.fisico).obs;
    _urlPreview = (presente?.imagem ?? '').obs;

    _imagemCtrl.addListener(_syncPreview);
  }

  void _syncPreview() => _urlPreview.value = _imagemCtrl.text.trim();

  @override
  void dispose() {
    _imagemCtrl.removeListener(_syncPreview);
    _nomeCtrl.dispose();
    _descricaoCtrl.dispose();
    _valorCtrl.dispose();
    _lojaCtrl.dispose();
    _linkCtrl.dispose();
    _pixCtrl.dispose();
    _metaCtrl.dispose();
    _imagemCtrl.dispose();
    super.dispose();
  }

  void _showSnack({
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
      margin: const EdgeInsets.all(12),
      borderRadius: 16,
      duration: const Duration(seconds: 3),
      icon: Icon(
        color == Colors.redAccent
            ? Icons.error_outline_rounded
            : Icons.check_circle_outline_rounded,
        color: Colors.white,
      ),
    );
  }

  Future<void> _salvar() async {
    if (_salvando.value) return;

    FocusManager.instance.primaryFocus?.unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      _showSnack(
        title: 'Atenção',
        message: 'Revise os campos obrigatórios antes de salvar.',
        color: Colors.redAccent,
      );
      return;
    }

    final primary = widget.themeController.primaryColor.value;
    final presente = widget.presente;

    _salvando.value = true;
    try {
      final tipo = _tipoSelecionado.value;
      final valor =
          tipo == GiftType.fisico ? 0.0 : _parseMoney(_valorCtrl.text);
      final meta =
          tipo == GiftType.coletivo ? _parseMoney(_metaCtrl.text) : 0.0;

      final model = Gift(
        id: _editando ? presente!.id : _uuid.v4(),
        nome: _nomeCtrl.text.trim(),
        descricao: _descricaoCtrl.text.trim(),
        tipo: tipo,
        valor: valor,
        loja: _lojaCtrl.text.trim(),
        link: _linkCtrl.text.trim(),
        pix: _pixCtrl.text.trim(),
        metaValor: meta,
        imagem: _imagemCtrl.text.trim(),
        categoria: presente?.categoria ?? 'geral',
        status: presente?.status ?? GiftStatus.disponivel,
        createdAt: presente?.createdAt ?? DateTime.now(),
      );

      if (_editando) {
        await widget.controller.atualizarPresente(model);
      } else {
        await widget.controller.criarPresente(model);
      }

      if (mounted) Navigator.of(context).pop();

      _showSnack(
        title: 'Tudo certo',
        message: _editando
            ? 'Presente atualizado com sucesso.'
            : 'Presente adicionado à lista.',
        color: primary,
      );
    } catch (e, s) {
      debugPrint('❌ Erro ao salvar presente: $e');
      debugPrintStack(stackTrace: s);
      _showSnack(
        title: 'Erro',
        message: 'Não foi possível salvar o presente agora.',
        color: Colors.redAccent,
      );
    } finally {
      if (mounted) _salvando.value = false;
    }
  }

  void _fechar() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.themeController.primaryColor.value;
    final gradient = widget.themeController.gradient.value;

    return PopScope(
      canPop: false,
      child: DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.62,
        maxChildSize: 0.97,
        expand: false,
        shouldCloseOnMinExtent: false,
        builder: (_, scrollController) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            child: Material(
              color: const Color(0xFFF6F8FC),
              child: Column(
                children: [
                  _GiftFormHeader(
                    gradient: gradient,
                    primary: primary,
                    editando: _editando,
                    onClose: _fechar,
                  ),
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        controller: scrollController,
                        padding: EdgeInsets.fromLTRB(
                          16,
                          16,
                          16,
                          MediaQuery.of(context).viewInsets.bottom + 18,
                        ),
                        children: [
                          Obx(
                            () => _GiftPreviewCard(
                              primary: primary,
                              tipo: _tipoSelecionado.value,
                              imageUrl: _urlPreview.value,
                              nome: _nomeCtrl.text.trim().isEmpty
                                  ? 'Prévia do presente'
                                  : _nomeCtrl.text.trim(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SectionTitle(
                            title: 'Formato do presente',
                            subtitle:
                                'Escolha como o convidado verá essa sugestão.',
                          ),
                          const SizedBox(height: 10),
                          Obx(
                            () => _GiftTypeSelector(
                              primary: primary,
                              selected: _tipoSelecionado.value,
                              onChanged: (value) =>
                                  _tipoSelecionado.value = value,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _SectionTitle(
                            title: 'Dados principais',
                            subtitle:
                                'Use nomes curtos e objetivos para facilitar a escolha.',
                          ),
                          const SizedBox(height: 10),
                          _PremiumTextField(
                            controller: _nomeCtrl,
                            primary: primary,
                            label: 'Nome do presente',
                            hint: 'Ex.: Fralda Pampers G',
                            icon: Icons.redeem_rounded,
                            textCapitalization: TextCapitalization.sentences,
                            validator: (value) => FormValidators.titulo(
                              value,
                              campo: 'o nome do presente',
                              minimo: 2,
                            ),
                            onChanged: (_) => _urlPreview.refresh(),
                          ),
                          const SizedBox(height: 10),
                          _PremiumTextField(
                            controller: _descricaoCtrl,
                            primary: primary,
                            label: 'Descrição curta',
                            hint:
                                'Opcional: cor, tamanho, observação ou preferência.',
                            icon: Icons.notes_rounded,
                            maxLines: 3,
                            textCapitalization: TextCapitalization.sentences,
                          ),
                          const SizedBox(height: 10),
                          Obx(
                            () => AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              child: _TipoCamposDinamicos(
                                key: ValueKey(_tipoSelecionado.value.name),
                                tipo: _tipoSelecionado.value,
                                primary: primary,
                                valorCtrl: _valorCtrl,
                                lojaCtrl: _lojaCtrl,
                                linkCtrl: _linkCtrl,
                                pixCtrl: _pixCtrl,
                                metaCtrl: _metaCtrl,
                                imagemCtrl: _imagemCtrl,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _GiftFormHint(primary: primary),
                        ],
                      ),
                    ),
                  ),
                  _GiftFormFooter(
                    primary: primary,
                    editando: _editando,
                    salvando: _salvando,
                    onCancel: _fechar,
                    onSave: _salvar,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GiftFormHeader extends StatelessWidget {
  final Gradient gradient;
  final Color primary;
  final bool editando;
  final VoidCallback onClose;

  const _GiftFormHeader({
    required this.gradient,
    required this.primary,
    required this.editando,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(gradient: gradient),
      child: Stack(
        children: [
          Positioned(
            right: -36,
            top: -40,
            child: _GlowCircle(size: 132, opacity: 0.12),
          ),
          Positioned(
            left: -44,
            bottom: -54,
            child: _GlowCircle(size: 118, opacity: 0.10),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 18),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18)),
                      ),
                      child: Icon(
                        editando
                            ? Icons.edit_note_rounded
                            : Icons.add_shopping_cart_rounded,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            editando ? 'Editar presente' : 'Novo presente',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Monte uma sugestão clara e elegante para o espaço dos convidados.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.86),
                              fontSize: 11.5,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onClose,
                      tooltip: 'Fechar',
                      icon:
                          const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GiftPreviewCard extends StatelessWidget {
  final Color primary;
  final GiftType tipo;
  final String imageUrl;
  final String nome;

  const _GiftPreviewCard({
    required this.primary,
    required this.tipo,
    required this.imageUrl,
    required this.nome,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5EAF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: primary.withValues(alpha: 0.10)),
            ),
            child: hasImage
                ? FestaImagemRede(
                    imageUrl,
                    erro: Icon(_tipoIcon(tipo), color: primary, size: 30),
                  )
                : Icon(_tipoIcon(tipo), color: primary, size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prévia no app',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF64748B),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  nome,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF111827),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                _MiniBadge(
                  label: _tipoLabel(tipo),
                  color: primary,
                  icon: _tipoIcon(tipo),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GiftTypeSelector extends StatelessWidget {
  final Color primary;
  final GiftType selected;
  final ValueChanged<GiftType> onChanged;

  const _GiftTypeSelector({
    required this.primary,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = GiftType.values;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: items.map((tipo) {
          final isSelected = selected == tipo;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onChanged(tipo),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 158,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? primary : const Color(0xFFE5EAF3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isSelected ? primary : Colors.black)
                          .withValues(alpha: isSelected ? 0.18 : 0.035),
                      blurRadius: isSelected ? 18 : 12,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.18)
                            : primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _tipoIcon(tipo),
                        color: isSelected ? Colors.white : primary,
                        size: 19,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _tipoLabel(tipo),
                      style: GoogleFonts.poppins(
                        color:
                            isSelected ? Colors.white : const Color(0xFF111827),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _tipoDescricao(tipo),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.82)
                            : const Color(0xFF64748B),
                        fontSize: 10.5,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TipoCamposDinamicos extends StatelessWidget {
  final GiftType tipo;
  final Color primary;
  final TextEditingController valorCtrl;
  final TextEditingController lojaCtrl;
  final TextEditingController linkCtrl;
  final TextEditingController pixCtrl;
  final TextEditingController metaCtrl;
  final TextEditingController imagemCtrl;

  const _TipoCamposDinamicos({
    super.key,
    required this.tipo,
    required this.primary,
    required this.valorCtrl,
    required this.lojaCtrl,
    required this.linkCtrl,
    required this.pixCtrl,
    required this.metaCtrl,
    required this.imagemCtrl,
  });

  @override
  Widget build(BuildContext context) {
    if (tipo == GiftType.fisico) {
      return Column(
        children: [
          _PremiumTextField(
            controller: imagemCtrl,
            primary: primary,
            label: 'URL da foto do produto',
            hint: 'Cole a URL da imagem, se tiver.',
            icon: Icons.image_search_rounded,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 10),
          _PremiumTextField(
            controller: lojaCtrl,
            primary: primary,
            label: 'Loja sugerida',
            hint: 'Ex.: Amazon, Magazine Luiza, Loja do bairro...',
            icon: Icons.storefront_rounded,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 10),
          _PremiumTextField(
            controller: linkCtrl,
            primary: primary,
            label: 'Link para compra',
            hint: 'Opcional: link direto do produto.',
            icon: Icons.shopping_cart_checkout_rounded,
            keyboardType: TextInputType.url,
          ),
        ],
      );
    }

    final isPixLivre = tipo == GiftType.pix;

    return Column(
      children: [
        _PremiumTextField(
          controller: valorCtrl,
          primary: primary,
          label: tipo == GiftType.coletivo
              ? 'Valor sugerido por contribuição'
              : (isPixLivre ? 'Valor sugerido (opcional)' : 'Valor sugerido'),
          hint: isPixLivre ? 'Deixe vazio para valor livre' : 'Ex.: 50,00',
          icon: Icons.payments_rounded,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) => FormValidators.dinheiro(
            value,
            // PIX simples: valor livre — o convidado escolhe no banco.
            obrigatorio: !isPixLivre,
            campo: 'o valor',
          ),
        ),
        if (isPixLivre) ...[
          const SizedBox(height: 8),
          _PixValorLivreHint(primary: primary),
        ],
        const SizedBox(height: 10),
        _PremiumTextField(
          controller: pixCtrl,
          primary: primary,
          label: 'Chave PIX',
          hint: 'CPF, e-mail, telefone ou chave aleatória.',
          icon: Icons.pix_rounded,
          keyboardType: TextInputType.text,
          validator: (value) => FormValidators.obrigatorio(
            value,
            campo: 'a chave PIX',
          ),
        ),
        if (tipo == GiftType.coletivo) ...[
          const SizedBox(height: 10),
          _PremiumTextField(
            controller: metaCtrl,
            primary: primary,
            label: 'Meta total',
            hint: 'Ex.: 600,00',
            icon: Icons.flag_rounded,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) => FormValidators.dinheiro(
              value,
              campo: 'a meta total',
            ),
          ),
        ],
      ],
    );
  }
}

class _PremiumTextField extends StatelessWidget {
  final TextEditingController controller;
  final Color primary;
  final String label;
  final String? hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const _PremiumTextField({
    required this.controller,
    required this.primary,
    required this.label,
    required this.icon,
    this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: keyboardType?.index == TextInputType.number.index
          ? [NumericInput.moeda()]
          : null,
      maxLines: maxLines,
      validator: validator,
      onChanged: onChanged,
      textCapitalization: textCapitalization,
      style: GoogleFonts.poppins(
        color: const Color(0xFF111827),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: maxLines > 1,
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: maxLines > 1 ? 34 : 0),
          child: Icon(icon, color: primary, size: 19),
        ),
        labelStyle: GoogleFonts.poppins(
          color: const Color(0xFF64748B),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: GoogleFonts.poppins(
          color: const Color(0xFF94A3B8),
          fontSize: 12,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE5EAF3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: primary, width: 1.35),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
      ),
    );
  }
}

class _GiftFormFooter extends StatelessWidget {
  final Color primary;
  final bool editando;
  final RxBool salvando;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _GiftFormFooter({
    required this.primary,
    required this.editando,
    required this.salvando,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
            top: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  'Cancelar',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF64748B),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Obx(() {
              final saving = salvando.value;
              return SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: saving ? null : onSave,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: primary,
                    disabledBackgroundColor: primary.withValues(alpha: 0.55),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_rounded,
                          color: Colors.white, size: 20),
                  label: Text(
                    saving
                        ? 'Salvando...'
                        : (editando ? 'Salvar' : 'Adicionar'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _GiftFormHint extends StatelessWidget {
  final Color primary;

  const _GiftFormHint({required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.tips_and_updates_rounded, color: primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Dica: quanto mais simples e direto for o presente, maior a chance do convidado escolher sem dúvida.',
              style: GoogleFonts.poppins(
                color: const Color(0xFF475569),
                fontSize: 11.5,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            color: const Color(0xFF111827),
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: GoogleFonts.poppins(
            color: const Color(0xFF64748B),
            fontSize: 11.2,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _MiniBadge(
      {required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final double opacity;

  const _GlowCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

String _valueToField(double? value) {
  if (value == null || value == 0) return '';
  return NumericInput.dinheiro(value);
}

double _parseMoney(String value) {
  return NumericInput.parse(value) ?? 0.0;
}

IconData _tipoIcon(GiftType tipo) {
  if (tipo == GiftType.pix) return Icons.pix_rounded;
  if (tipo == GiftType.coletivo) return Icons.groups_2_rounded;
  return Icons.card_giftcard_rounded;
}

String _tipoLabel(GiftType tipo) {
  if (tipo == GiftType.pix) return 'PIX';
  if (tipo == GiftType.coletivo) return 'Coletivo';
  return 'Físico';
}

String _tipoDescricao(GiftType tipo) {
  if (tipo == GiftType.pix) return 'Contribuição com valor livre ou sugerido';
  if (tipo == GiftType.coletivo) return 'Meta dividida entre convidados';
  return 'Produto, loja, foto e link';
}

class _PixValorLivreHint extends StatelessWidget {
  final Color primary;

  const _PixValorLivreHint({required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.pix_rounded, color: primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Com valor livre, o QR/copia-e-cola não trava o montante: cada convidado informa o valor no app do banco.',
              style: GoogleFonts.poppins(
                color: const Color(0xFF475569),
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
