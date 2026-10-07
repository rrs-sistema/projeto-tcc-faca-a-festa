part of '../pages/orcamento_screen.dart';

Future<void> showAddOrcamentoBottomSheet(
  BuildContext context,
  String idEvento, {
  required EventThemeController themeController,
  required OrcamentoController orcamentoController,
  required String? idSolicitante,
}) async {
  final nomeCtrl = TextEditingController();
  final custoEstimadoCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final dinheiroMask = FormMasks.dinheiro();
  final RxBool salvando = false.obs;

  final primary = themeController.primaryColor.value;
  final gradient = themeController.gradient.value;

  // Cores exatas do padrão
  const background = Color(0xFFF8FAFC);
  const textDark = Color(0xFF1F2937);
  const textMuted = Color(0xFF64748B);

  Future<void> salvarOrcamento(BuildContext modalContext) async {
    if (salvando.value) return;
    if (!(formKey.currentState?.validate() ?? false)) return;

    final descricao = nomeCtrl.text.trim();
    final custoTexto = custoEstimadoCtrl.text.trim();

    try {
      salvando.value = true;
      final double custo = FormValidators.parseDinheiro(custoTexto);

      final resultado =
          await orcamentoController.validarCriacaoOrcamento(custo);

      if (!resultado.$1) {
        Get.snackbar(
          resultado.$2 ?? 'Erro ao criar orçamento',
          'Excedente: R\$ ${Biblioteca.formatarValorDecimal(resultado.$3)}\n'
          'Limite: R\$ ${Biblioteca.formatarValorDecimal(resultado.$4)}',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(12),
          borderRadius: 12,
        );
        salvando.value = false;
        return;
      }

      EasyLoading.show(status: 'Salvando...');

      final novo = Orcamento(
        idOrcamento: DateTime.now().millisecondsSinceEpoch.toString(),
        idEvento: idEvento,
        idServicoFornecido: null,
        idSolicitante: idSolicitante,
        custoEstimado: custo,
        anotacoes: descricao,
        status: StatusOrcamento.pendente,
      );

      await orcamentoController.criarOrcamento(novo);

      FocusManager.instance.primaryFocus?.unfocus();
      EasyLoading.dismiss();

      if (modalContext.mounted) {
        Navigator.of(modalContext).pop();
      }

      Get.snackbar(
        'Item adicionado',
        descricao,
        backgroundColor: primary,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
        icon:
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
      );
    } catch (e) {
      EasyLoading.dismiss();
      Get.snackbar(
        'Erro',
        'Não foi possível salvar o orçamento.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
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
                child: const Icon(Icons.attach_money_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Novo item',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Entra no previsto. O pagamento você registra depois, no item.',
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
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputAction textInputAction = TextInputAction.next,
    int maxLines = 1,
    bool autofocus = false,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String)? onFieldSubmitted,
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
          )
        ],
      ),
      child: TextFormField(
        controller: controller,
        autofocus: autofocus,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        textInputAction: textInputAction,
        maxLines: maxLines,
        inputFormatters: inputFormatters,
        validator: validator,
        onFieldSubmitted: onFieldSubmitted,
        style: GoogleFonts.poppins(
            color: textDark, fontSize: 13, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: GoogleFonts.poppins(
              color: textMuted, fontSize: 12, fontWeight: FontWeight.w500),
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
            child: Form(
              key: formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildHeader(),
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8 + (teclado > 0 ? 0 : base)),
                      child: Column(
                        children: [
                          buildTextField(
                            controller: nomeCtrl,
                            label: 'Nome do item',
                            hint: 'Ex.: passagens, decoração, bolo',
                            icon: Icons.sell_outlined,
                            textCapitalization: TextCapitalization.sentences,
                            autofocus: true,
                            validator: (v) => FormValidators.descricao(
                              v,
                              campo: 'o nome do item',
                              obrigatorio: true,
                              minimo: 3,
                            ),
                          ),
                          buildTextField(
                            controller: custoEstimadoCtrl,
                            label: 'Valor previsto',
                            hint: 'R\$ 0,00',
                            icon: Icons.payments_outlined,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            textInputAction: TextInputAction.done,
                            inputFormatters: [dinheiroMask],
                            onFieldSubmitted: (_) =>
                                salvarOrcamento(modalContext),
                            validator: (v) => FormValidators.dinheiro(
                              v,
                              campo: 'o valor previsto',
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
                                    : () => salvarOrcamento(modalContext),
                                icon: isSaving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white),
                                      )
                                    : const Icon(
                                        Icons.check_circle_outline_rounded,
                                        color: Colors.white,
                                        size: 18),
                                label: Text(
                                  isSaving ? 'Salvando...' : 'Salvar item',
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
                                FocusManager.instance.primaryFocus?.unfocus();
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
                                    fontWeight: FontWeight.w600, fontSize: 14),
                              ),
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
      },
    );
  } finally {
    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.delayed(const Duration(milliseconds: 350));
    nomeCtrl.dispose();
    custoEstimadoCtrl.dispose();
  }
}
