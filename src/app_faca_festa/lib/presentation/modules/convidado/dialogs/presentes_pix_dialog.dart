part of '../pages/area/presentes_section.dart';

extension _PresentesPixDialog on _PresentesSectionState {
  void _mostrarPixQrModal({
    required String nome,
    required dynamic valorInicial,
    required String chavePix,
    required Color primary,
  }) {
    final valorSugerido = _moneyValue(valorInicial);
    final valorController = TextEditingController(
      text: valorSugerido > 0
          ? valorSugerido.toStringAsFixed(2).replaceAll('.', ',')
          : '',
    );
    final hasPix = chavePix.trim().isNotEmpty;

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
              child: SingleChildScrollView(
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
                    ),
                    const SizedBox(height: 12),
                    if (hasPix)
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
                          data: chavePix,
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
                      hasPix
                          ? 'Escaneie o QR Code ou copie a chave PIX para finalizar no app do seu banco.'
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
                        label: const Text('Copiar chave PIX'),
                        onPressed: hasPix
                            ? () {
                                Clipboard.setData(
                                    ClipboardData(text: chavePix));
                                Get.back();
                                Get.snackbar(
                                  'PIX copiado ✨',
                                  'Agora é só colar a chave no app do seu banco.',
                                  backgroundColor: Colors.green.shade600,
                                  colorText: Colors.white,
                                  snackPosition: SnackPosition.BOTTOM,
                                  margin: const EdgeInsets.all(14),
                                  borderRadius: 16,
                                  icon: const Icon(Icons.check_circle_rounded,
                                      color: Colors.white),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          disabledBackgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.white,
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GiftValueField extends StatelessWidget {
  final Color primary;
  final TextEditingController controller;

  const _GiftValueField({required this.primary, required this.controller});

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
                FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
              ],
              style: GoogleFonts.poppins(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: primary,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '0,00',
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

double _moneyValue(dynamic value, {double fallback = 0.0}) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();

  var raw = value.toString().replaceAll('R\$', '').replaceAll(' ', '').trim();

  if (raw.contains(',')) {
    raw = raw.replaceAll('.', '').replaceAll(',', '.');
  } else {
    raw = raw.replaceAll(RegExp(r'[^0-9.-]'), '');
  }

  return double.tryParse(raw) ?? fallback;
}
