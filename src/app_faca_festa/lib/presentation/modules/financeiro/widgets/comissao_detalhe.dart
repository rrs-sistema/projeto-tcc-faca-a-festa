import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/core/utils/numeric_input.dart';
import '../controllers/comissao_plataforma_controller.dart';
import 'comissao_modal.dart';

class ComissaoDetalhe extends StatefulWidget {
  const ComissaoDetalhe({
    super.key,
    required this.controller,
    required this.obrigacao,
    required this.accent,
  });

  final ComissaoPlataformaController controller;
  final Map<String, dynamic> obrigacao;
  final Color accent;

  @override
  State<ComissaoDetalhe> createState() => _ComissaoDetalheState();
}

class _ComissaoDetalheState extends State<ComissaoDetalhe> {
  final _valor = TextEditingController();
  String? _erro;
  bool _salvando = false;
  ComissaoPlataformaController get c => widget.controller;
  String get _id =>
      (widget.obrigacao['id_obrigacao'] ?? widget.obrigacao['id'] ?? '')
          .toString();

  @override
  void initState() {
    super.initState();
    final saldo = ComissaoPlataformaController.saldoDe(widget.obrigacao);
    if (saldo > 0) {
      _valor.text = (saldo / 100).toStringAsFixed(2).replaceAll('.', ',');
    }
  }

  @override
  void dispose() {
    _valor.dispose();
    super.dispose();
  }

  String _dinheiro(int centavos) => NumericInput.dinheiro(centavos / 100);

  Future<void> _registrar() async {
    final reais = NumericInput.parseMoeda(_valor.text);
    if (reais == null ||
        !reais.isFinite ||
        reais <= 0 ||
        (reais * 100).round() <= 0) {
      setState(() => _erro = 'Informe um valor maior que zero.');
      return;
    }
    setState(() {
      _salvando = true;
      _erro = null;
    });
    final resultado = await c.liquidar(
      idObrigacao: _id,
      valorCentavos: (reais * 100).round(),
    );
    if (!mounted) return;
    if (resultado != null) {
      Navigator.pop(context);
      Get.snackbar('Recebimento registrado',
          'Registro manual concluído. Não confirma transferência bancária.',
          snackPosition: SnackPosition.BOTTOM);
    } else {
      setState(() {
        _salvando = false;
        _erro = c.erro.value.isEmpty
            ? 'Não foi possível registrar. Tente novamente.'
            : c.erro.value;
      });
    }
  }

  Widget _linha(String label, String value, {bool destaque = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: LayoutBuilder(builder: (context, box) {
        final texto = Text(value,
            style: GoogleFonts.poppins(
                fontSize: destaque ? 18 : 14,
                color: const Color(0xFF111827),
                fontWeight: destaque ? FontWeight.w700 : FontWeight.w600));
        final titulo = Text(label,
            style: GoogleFonts.poppins(
                fontSize: 13, color: const Color(0xFF475569)));
        if (box.maxWidth < 300 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.3) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [titulo, const SizedBox(height: 4), texto],
          );
        }
        return Row(children: [
          Expanded(child: titulo),
          const SizedBox(width: 16),
          texto
        ]);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final busy = c.enviando.value || _salvando;
      // Usa a cobrança mais recente após uma atualização do extrato.
      final o = _id.isEmpty
          ? widget.obrigacao
          : c.obrigacoes.firstWhereOrNull((item) =>
                  (item['id_obrigacao'] ?? item['id'])?.toString() == _id) ??
              widget.obrigacao;
      final saldo = ComissaoPlataformaController.saldoDe(o);
      final ajustes = saldo -
          ComissaoPlataformaController.valorOriginalDe(o) +
          ComissaoPlataformaController.valorLiquidadoDe(o);
      final base = ComissaoPlataformaController.baseElegivelCentavosDe(o);
      final bps = ComissaoPlataformaController.percentualBpsAplicadoDe(o);
      final taxa = bps == null
          ? 'Não informada'
          : '${(bps / 100).toStringAsFixed(bps % 100 == 0 ? 0 : 2).replaceAll('.', ',')}%';
      final evento = (o['id_evento'] ?? o['idEvento'] ?? '').toString();
      final contrato = (o['id_contrato'] ?? o['idContrato'] ?? '').toString();
      return PopScope(
        canPop: !busy,
        child: ComissaoModal(
          titulo: 'Detalhe da cobrança',
          subtitulo: 'Comissão vinculada à contratação',
          icone: Icons.receipt_long_outlined,
          accent: widget.accent,
          ocupado: busy,
          footer: c.isAdmin
              ? FilledButton.icon(
                  onPressed: busy || _id.isEmpty ? null : _registrar,
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.accent,
                    foregroundColor: Colors.white,
                    iconColor: Colors.white,
                    minimumSize: const Size(48, 52),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                  ),
                  icon: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_rounded, size: 20),
                  label: Text(busy ? 'Registrando…' : 'Registrar recebimento',
                      textAlign: TextAlign.center),
                )
              : OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: widget.accent,
                      minimumSize: const Size(48, 50)),
                  child: const Text('Fechar detalhes'),
                ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: widget.accent.withValues(alpha: .06),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          saldo < 0
                              ? 'Crédito no extrato'
                              : c.isAdmin
                                  ? 'Saldo a receber'
                                  : 'Saldo desta cobrança',
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: const Color(0xFF475569))),
                      const SizedBox(height: 6),
                      Text(_dinheiro(saldo),
                          style: GoogleFonts.poppins(
                              fontSize: 32,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111827))),
                      const SizedBox(height: 14),
                      ComissaoStatus(
                          status: o['status']?.toString(), pagador: !c.isAdmin),
                    ]),
              ),
              const SizedBox(height: 20),
              Text('Composição do valor',
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              _linha('Comissão gerada',
                  _dinheiro(ComissaoPlataformaController.valorOriginalDe(o))),
              if (ajustes != 0) _linha('Ajustes', _dinheiro(ajustes)),
              _linha('Pagamentos registrados',
                  _dinheiro(ComissaoPlataformaController.valorLiquidadoDe(o))),
              const Divider(height: 16),
              _linha(saldo < 0 ? 'Saldo em crédito' : 'Saldo', _dinheiro(saldo),
                  destaque: true),
              const SizedBox(height: 20),
              Text('Taxa aplicada',
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              _linha('Taxa desta contratação', taxa),
              if (base != null) _linha('Base de cálculo', _dinheiro(base)),
              Text(
                  'A taxa é a registrada na geração desta cobrança. Alterações posteriores não recalculam este valor.',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      height: 1.5,
                      color: const Color(0xFF64748B))),
              if (evento.isNotEmpty ||
                  contrato.isNotEmpty ||
                  _id.isNotEmpty) ...[
                const SizedBox(height: 20),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 12),
                  title: Text('Referências da cobrança',
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  children: [
                    for (final entry in {
                      'Evento': evento,
                      'Contrato': contrato,
                      'Cobrança': _id
                    }.entries)
                      if (entry.value.isNotEmpty)
                        Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: SelectableText(
                                    '${entry.key}: ${entry.value}',
                                    style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: const Color(0xFF475569))))),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12)),
                child: Text(
                    c.isAdmin
                        ? 'Registro manual de recebimento. Informe o valor recebido; o registro não confirma transferência bancária.'
                        : 'Os pagamentos são registrados pela plataforma. Este extrato não confirma transferência bancária.',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        height: 1.5,
                        color: const Color(0xFF475569))),
              ),
              if (c.isAdmin) ...[
                const SizedBox(height: 20),
                TextField(
                  controller: _valor,
                  enabled: !busy,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.done,
                  scrollPadding: const EdgeInsets.all(32),
                  onChanged: (_) {
                    if (_erro != null) setState(() => _erro = null);
                  },
                  decoration: InputDecoration(
                    labelText: 'Valor recebido',
                    prefixText: 'R\$ ',
                    errorText: _erro,
                    errorMaxLines: 4,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}
