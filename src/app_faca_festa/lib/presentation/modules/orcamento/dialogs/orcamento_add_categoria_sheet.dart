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
        'Orçamento adicionado',
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
                      'Adicionar ao orçamento',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Descreva o gasto e o custo estimado.',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 11,
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

  Widget buildSectionTitle({required IconData icon, required String title}) {
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
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: primary, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 4),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
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
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
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
          )
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        textInputAction: textInputAction,
        maxLines: maxLines,
        inputFormatters: inputFormatters,
        validator: validator,
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
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.60,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controllerScroll) {
            return Container(
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                color: background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  buildHeader(),
                  Expanded(
                    child: Form(
                      key: formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: ListView(
                        controller: controllerScroll,
                        padding: EdgeInsets.fromLTRB(
                          16,
                          16,
                          16,
                          MediaQuery.of(modalContext).viewInsets.bottom + 16,
                        ),
                        children: [
                          buildSectionTitle(
                            icon: Icons.edit_note_rounded,
                            title: 'Detalhes do Orçamento',
                          ),
                          buildTextField(
                            controller: nomeCtrl,
                            label: 'Descrição do gasto',
                            hint: 'Ex: Decoração, DJ, Bebidas...',
                            icon: Icons.category_outlined,
                            textCapitalization: TextCapitalization.sentences,
                            maxLines: 2,
                            validator: (v) => FormValidators.descricao(
                              v,
                              campo: 'a descrição do gasto',
                              obrigatorio: true,
                              minimo: 3,
                            ),
                          ),
                          buildTextField(
                            controller: custoEstimadoCtrl,
                            label: 'Custo estimado (R\$)',
                            hint: 'R\$ 0,00',
                            icon: Icons.savings_outlined,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            textInputAction: TextInputAction.done,
                            inputFormatters: [dinheiroMask],
                            validator: (v) => FormValidators.dinheiro(
                              v,
                              campo: 'o custo estimado',
                            ),
                          ),
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
                                  isSaving ? 'Salvando...' : 'Salvar orçamento',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
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
                                Navigator.of(modalContext).pop();
                              },
                              icon: const Icon(Icons.close_rounded, size: 18),
                              label: Text(
                                'Cancelar',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: textMuted,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
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
      },
    );
  } finally {
    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.delayed(const Duration(milliseconds: 350));
    nomeCtrl.dispose();
    custoEstimadoCtrl.dispose();
  }
}
