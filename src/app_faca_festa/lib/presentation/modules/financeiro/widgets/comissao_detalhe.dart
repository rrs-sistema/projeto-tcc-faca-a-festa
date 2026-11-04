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
  bool _registrando = false;
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
    final centavos = (reais * 100).round();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Conferir recebimento de comissão'),
        content: SingleChildScrollView(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ComissaoPlataformaController.nomeEventoDe(widget.obrigacao)),
            const SizedBox(height: 12),
            Text(
                'Pagador: ${ComissaoPlataformaController.nomePagadorDe(widget.obrigacao)}'),
            const SizedBox(height: 16),
            Text('Valor a registrar: ${_dinheiro(centavos)}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            const Text(
                'Confirme somente após conferir o recebimento. Esta ação atualiza o extrato e não realiza transferência bancária.'),
          ],
        )),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Voltar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmar registro')),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;
    setState(() {
      _salvando = true;
      _erro = null;
    });
    final resultado = await c.liquidar(
      idObrigacao: _id,
      valorCentavos: centavos,
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
          Flexible(child: texto)
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
          titulo:
              _registrando ? 'Registrar recebimento' : 'Detalhe da cobrança',
          subtitulo: 'Comissão vinculada à contratação',
          icone: Icons.receipt_long_outlined,
          accent: widget.accent,
          ocupado: busy,
          footer: c.isAdmin
              ? FilledButton.icon(
                  onPressed: busy || _id.isEmpty || saldo <= 0
                      ? null
                      : () {
                          if (_registrando) {
                            _registrar();
                          } else {
                            setState(() => _registrando = true);
                          }
                        },
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
                  label: Text(
                      busy
                          ? 'Registrando…'
                          : _registrando
                              ? 'Revisar recebimento'
                              : saldo <= 0
                                  ? 'Sem saldo a receber'
                                  : 'Registrar recebimento',
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
              if (_registrando) ...[
                TextButton.icon(
                  onPressed:
                      busy ? null : () => setState(() => _registrando = false),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Voltar aos detalhes'),
                ),
                _linha('Evento', ComissaoPlataformaController.nomeEventoDe(o)),
                _linha(
                    'Pagador', ComissaoPlataformaController.nomePagadorDe(o)),
                _linha('Saldo a receber', _dinheiro(saldo), destaque: true),
                const SizedBox(height: 16),
                TextField(
                  autofocus: true,
                  controller: _valor,
                  enabled: !busy,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Valor recebido',
                    prefixText: 'R\$ ',
                    helperText:
                        'Informe somente a comissão que você já conferiu.',
                    helperMaxLines: 3,
                    errorText: _erro,
                    errorMaxLines: 3,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                    'Na próxima etapa, revise o valor e o pagador antes de confirmar o registro.'),
              ] else ...[
                Text('Identificação da contratação',
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                _linha('Evento', ComissaoPlataformaController.nomeEventoDe(o)),
                _linha('Fornecedor',
                    ComissaoPlataformaController.nomeFornecedorDe(o)),
                _linha(
                    'Pagador', ComissaoPlataformaController.nomePagadorDe(o)),
                const SizedBox(height: 16),
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
                            status: ComissaoPlataformaController
                                .statusApresentacaoDe(o),
                            pagador: !c.isAdmin),
                      ]),
                ),
                const SizedBox(height: 20),
                Text('Composição do valor',
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                _linha('Comissão gerada',
                    _dinheiro(ComissaoPlataformaController.valorOriginalDe(o))),
                if (ajustes != 0) _linha('Ajustes', _dinheiro(ajustes)),
                _linha(
                    'Pagamentos registrados',
                    _dinheiro(
                        ComissaoPlataformaController.valorLiquidadoDe(o))),
                _linha('Retida em repasses',
                    _dinheiro(ComissaoPlataformaController.retidaDe(o))),
                _linha('Pagamento separado registrado',
                    _dinheiro(ComissaoPlataformaController.separadaDe(o))),
                if (ComissaoPlataformaController.retencaoPrevistaDe(o))
                  Text(
                      'Saldo previsto para retenção nos próximos repasses. Pagamento separado reduz a retenção; não é uma segunda cobrança.'),
                const Divider(height: 16),
                _linha(
                    saldo < 0 ? 'Saldo em crédito' : 'Saldo', _dinheiro(saldo),
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
                    title: Text('Códigos técnicos da cobrança',
                        style: GoogleFonts.poppins(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    children: [
                      for (final entry in {
                        'Evento': evento,
                        'Fornecedor':
                            (o['id_fornecedor'] ?? o['idFornecedor'] ?? '')
                                .toString(),
                        'Pagador': (o['id_pagador'] ?? o['idPagador'] ?? '')
                            .toString(),
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
                          ? 'Para registrar uma comissão já recebida, use Registrar recebimento. Você poderá conferir o valor antes de confirmar.'
                          : 'Os pagamentos são registrados pela plataforma. Este extrato não confirma transferência bancária.',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          height: 1.5,
                          color: const Color(0xFF475569))),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}
