part of '../pages/area/presentes_section.dart';

extension _PresentesPixDialog on _PresentesSectionState {
  void _mostrarPixQrModal({
    required String nome,
    required dynamic valorInicial,
    required String chavePix,
    required Color primary,
    String? nomeRecebedor,
    String? cidadeRecebedor,
  }) {
    final valorSugerido = _moneyValue(valorInicial);
    final valorController = TextEditingController(
      text: valorSugerido > 0 ? NumericInput.dinheiro(valorSugerido) : '',
    );
    final hasPix = chavePix.trim().isNotEmpty;
    final recebedor = (nomeRecebedor ?? '').trim().isEmpty
        ? nome
        : nomeRecebedor!.trim();
    final cidade = (cidadeRecebedor ?? '').trim();

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.20),
                    blurRadius: 34,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  final valorDigitado = _moneyValue(valorController.text);
                  final valorLivre = valorDigitado <= 0;
                  String? payload;
                  String? erroPayload;

                  if (hasPix) {
                    try {
                      payload = PixBrCode.gerar(
                        chave: chavePix,
                        nomeRecebedor: recebedor,
                        cidade: cidade.isEmpty ? null : cidade,
                        valor: valorLivre ? null : valorDigitado,
                        identificador: '***',
                        descricao: nome,
                      );
                    } catch (e) {
                      erroPayload = 'Não foi possível montar o PIX com essa chave.';
                      debugPrint('PIX BR Code: $e');
                    }
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primary,
                                primary.withValues(alpha: 0.70),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.35),
                                blurRadius: 22,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.pix_rounded,
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Presentear com carinho',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nome,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        _GiftValueField(
                          primary: primary,
                          controller: valorController,
                          onChanged: (_) => setModalState(() {}),
                        ),
                        const SizedBox(height: 8),
                        _PixValorHint(
                          primary: primary,
                          valorLivre: valorLivre,
                        ),
                        const SizedBox(height: 12),
                        if (payload != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                  color: primary.withValues(alpha: 0.14)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: QrImageView(
                              data: payload,
                              size: 156,
                              backgroundColor: Colors.white,
                            ),
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                  color: Colors.orange.withValues(alpha: 0.22)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded,
                                    color: Colors.orange),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    erroPayload ??
                                        'A chave PIX ainda não foi cadastrada pelo organizador.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.orange.shade900,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 14),
                        Text(
                          payload != null
                              ? (valorLivre
                                  ? 'Escaneie o QR ou copie o código. No app do banco, informe o valor que desejar.'
                                  : 'Escaneie o QR ou copie o código PIX para pagar o valor indicado no app do banco.')
                              : 'Assim que o organizador cadastrar a chave, você poderá contribuir por aqui.',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            color: Colors.grey.shade600,
                            height: 1.35,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.copy_rounded,
                                color: Colors.white, size: 18),
                            label: Text(valorLivre
                                ? 'Copiar PIX (valor livre)'
                                : 'Copiar código PIX'),
                            onPressed: payload != null
                                ? () {
                                    Clipboard.setData(
                                        ClipboardData(text: payload!));
                                    Get.back();
                                    Get.snackbar(
                                      'PIX copiado ✨',
                                      valorLivre
                                          ? 'Cole no app do banco e digite o valor que quiser.'
                                          : 'Cole no app do banco para concluir o pagamento.',
                                      backgroundColor: Colors.green.shade600,
                                      colorText: Colors.white,
                                      snackPosition: SnackPosition.BOTTOM,
                                      margin: const EdgeInsets.all(14),
                                      borderRadius: 16,
                                      icon: const Icon(
                                          Icons.check_circle_rounded,
                                          color: Colors.white),
                                    );
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              disabledBackgroundColor: Colors.grey.shade300,
                              foregroundColor: Colors.white,
                              iconColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              textStyle: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Get.back(),
                          child: Text(
                            'Agora não',
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    ).whenComplete(valorController.dispose);
  }
}

class _GiftValueField extends StatelessWidget {
  final Color primary;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const _GiftValueField({
    required this.primary,
    required this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Text(
            'R\$',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                NumericInput.moeda(),
              ],
              onChanged: onChanged,
              style: GoogleFonts.poppins(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: primary,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Valor livre',
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Icon(Icons.edit_rounded, size: 16, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}

class _PixValorHint extends StatelessWidget {
  final Color primary;
  final bool valorLivre;

  const _PixValorHint({required this.primary, required this.valorLivre});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          valorLivre ? Icons.all_inclusive_rounded : Icons.lock_rounded,
          size: 14,
          color: primary.withValues(alpha: 0.75),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            valorLivre
                ? 'Valor livre: o banco vai pedir o montante na hora do pagamento.'
                : 'Valor fixo no QR. Apague o campo para voltar ao valor livre.',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey.shade600,
              height: 1.3,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

double _moneyValue(dynamic value, {double fallback = 0.0}) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();

  return NumericInput.parse(value.toString()) ?? fallback;
}
