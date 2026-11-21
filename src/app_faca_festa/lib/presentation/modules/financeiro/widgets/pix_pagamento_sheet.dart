import 'dart:async';
import 'dart:convert';

import 'package:app_faca_festa/core/utils/form_validators.dart';
import 'package:app_faca_festa/core/utils/numeric_input.dart';
import 'package:app_faca_festa/domain/entities/cobranca_pix_servico.dart';
import 'package:app_faca_festa/domain/services/acompanhamento_partes_service.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/controllers/acompanhamento_partes_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Abre o Pix Asaas do serviço contratado. Retorna true quando o pagamento confirma.
Future<bool> mostrarPixPagamento({
  required BuildContext context,
  required Color primary,
  required VisaoOrganizadorContrato contrato,
  required AcompanhamentoPartesController controller,
  String? cpfPerfil,
}) {
  final wide = MediaQuery.sizeOf(context).width >= 720;
  Widget folha() => _PixPagamentoSheet(
        primary: primary,
        contrato: contrato,
        controller: controller,
        cpfPerfil: cpfPerfil,
      );
  if (wide) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final inset = MediaQuery.viewInsetsOf(ctx).bottom;
        final maxH = MediaQuery.sizeOf(ctx).height - inset - 40;
        return Padding(
          padding: EdgeInsets.only(bottom: inset),
          child: Dialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 440, maxHeight: maxH),
              child: folha(),
            ),
          ),
        );
      },
    ).then((v) => v == true);
  }
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final inset = MediaQuery.viewInsetsOf(ctx).bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: inset),
        child: folha(),
      );
    },
  ).then((v) => v == true);
}

class _PixPagamentoSheet extends StatefulWidget {
  const _PixPagamentoSheet({
    required this.primary,
    required this.contrato,
    required this.controller,
    this.cpfPerfil,
  });

  final Color primary;
  final VisaoOrganizadorContrato contrato;
  final AcompanhamentoPartesController controller;
  final String? cpfPerfil;

  @override
  State<_PixPagamentoSheet> createState() => _PixPagamentoSheetState();
}

class _PixPagamentoSheetState extends State<_PixPagamentoSheet> {
  late final TextEditingController _valorCtrl;
  late final TextEditingController _cpfCtrl;
  final _valorFocus = FocusNode();
  Timer? _consulta;
  CobrancaPixServico? _cobranca;
  bool _gerando = false;
  bool _copiado = false;
  String? _erro;

  bool get _temCpfPerfil => (widget.cpfPerfil ?? '').length == 11;

  int _valorInicial() {
    final aPagar = widget.contrato.aPagarCentavos;
    final entrada = widget.contrato.entradaSugeridaCentavos;
    if (widget.contrato.pagamentosRegistrados == 0 &&
        entrada != null &&
        entrada > 0 &&
        entrada <= aPagar) {
      return entrada;
    }
    return aPagar;
  }

  String _textoParcela() {
    final contrato = widget.contrato;
    final qual = contrato.pagamentosRegistrados == 0
        ? 'Este é o primeiro dos dois pagamentos possíveis.'
        : 'Esta é a segunda e última parcela.';
    final entrada = contrato.entradaSugeridaCentavos;
    final percentual = contrato.percentualEntradaSugerido;
    if (contrato.pagamentosRegistrados == 0 &&
        entrada != null &&
        percentual != null &&
        entrada > 0) {
      return '$qual O campo já vem com $percentual% '
          '(${NumericInput.dinheiro(entrada / 100.0)}), só como garantia '
          'pedida pelo fornecedor. Você pode alterar para qualquer valor '
          'até o saldo.';
    }
    return '$qual Pode ser qualquer valor até o saldo.';
  }

  @override
  void initState() {
    super.initState();
    final sugerido = widget.contrato.aPagarCentavos > 0
        ? NumericInput.dinheiro(_valorInicial() / 100.0)
        : '';
    _valorCtrl = TextEditingController(text: sugerido);
    _cpfCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _consulta?.cancel();
    _valorCtrl.dispose();
    _cpfCtrl.dispose();
    _valorFocus.dispose();
    super.dispose();
  }

  int? _centavos() {
    final reais = NumericInput.parseMoeda(_valorCtrl.text);
    if (reais == null || !reais.isFinite || reais <= 0) return null;
    final centavos = (reais * 100).round();
    if (centavos > widget.contrato.aPagarCentavos) return null;
    return centavos;
  }

  String? _cpfInformado() {
    if (_temCpfPerfil) return null;
    final erro = FormValidators.cpf(_cpfCtrl.text);
    if (erro != null) return null;
    return FormValidators.somenteDigitos(_cpfCtrl.text);
  }

  Future<void> _gerar() async {
    final centavos = _centavos();
    if (centavos == null) {
      setState(() => _erro =
          'Informe um valor até ${NumericInput.dinheiro(widget.contrato.aPagarCentavos / 100.0)}.');
      return;
    }
    if (!_temCpfPerfil && _cpfInformado() == null) {
      setState(() => _erro = FormValidators.cpf(_cpfCtrl.text) ??
          'Informe um CPF válido.');
      return;
    }
    setState(() {
      _gerando = true;
      _erro = null;
      _copiado = false;
    });
    final cobranca = await widget.controller.criarCobrancaPix(
      idOrcamento: widget.contrato.idOrcamento,
      valorCentavos: centavos,
      cpf: _cpfInformado(),
    );
    if (!mounted) return;
    setState(() {
      _gerando = false;
      _cobranca = cobranca;
      _erro = cobranca == null
          ? (widget.controller.erro.value.isEmpty
              ? 'Não foi possível gerar o Pix.'
              : widget.controller.erro.value)
          : null;
    });
    if (cobranca != null) _acompanhar(cobranca);
  }

  void _acompanhar(CobrancaPixServico cobranca) {
    _consulta?.cancel();
    if (cobranca.confirmado) {
      Navigator.of(context).pop(true);
      return;
    }
    if (cobranca.encerrado || cobranca.copiaCola.isEmpty) return;
    _consulta = Timer.periodic(const Duration(seconds: 8), (_) {
      unawaited(_consultar(cobranca.id));
    });
  }

  Future<void> _consultar(String id) async {
    final atual = await widget.controller.consultarCobrancaPix(
      id,
      silencioso: true,
    );
    if (!mounted || atual == null) return;
    setState(() => _cobranca = atual);
    if (atual.confirmado) {
      _consulta?.cancel();
      Navigator.of(context).pop(true);
    } else if (atual.encerrado) {
      _consulta?.cancel();
      setState(() => _erro =
          'Esse Pix não foi confirmado. Feche e gere um novo código.');
    }
  }

  Uint8List? _qrBytes(String bruto) {
    var dados = bruto.trim();
    if (dados.isEmpty) return null;
    final virgula = dados.indexOf(',');
    if (dados.startsWith('data:') && virgula >= 0) {
      dados = dados.substring(virgula + 1);
    }
    try {
      return base64Decode(dados.replaceAll(RegExp(r'\s'), ''));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final servico = (widget.contrato.nomeServico ?? '').trim();
    final cobranca = _cobranca;
    final qr = cobranca == null ? null : _qrBytes(cobranca.qrCodeBase64);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Text(
              'Pagar serviço com Pix',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111827),
              ),
            ),
            if (servico.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                servico,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'O valor vai para a plataforma Faça a Festa, não direto ao fornecedor. '
                'A confirmação chega pelo Asaas e libera o acompanhamento do pagamento.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  height: 1.35,
                  color: const Color(0xFF334155),
                ),
              ),
            ),
            if (cobranca == null || cobranca.copiaCola.isEmpty) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _valorCtrl,
                focusNode: _valorFocus,
                enabled: !_gerando,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                inputFormatters: [NumericInput.moeda()],
                decoration: const InputDecoration(
                  labelText: 'Valor do Pix',
                  hintText: 'Ex: R\$ 3.150,00',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _textoParcela(),
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  height: 1.35,
                  color: const Color(0xFF64748B),
                ),
              ),
              if (!_temCpfPerfil) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _cpfCtrl,
                  enabled: !_gerando,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'CPF do pagador',
                  ),
                ),
              ],
            ] else ...[
              const SizedBox(height: 16),
              Text(
                NumericInput.dinheiro(cobranca.valorCentavos / 100.0),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),
              if ((cobranca.aviso ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  cobranca.aviso!,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    height: 1.35,
                    color: const Color(0xFFB45309),
                  ),
                ),
              ],
              if (qr != null) ...[
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Image.memory(qr, width: 220, height: 220),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SelectableText(
                cobranca.copiaCola,
                style: GoogleFonts.poppins(fontSize: 12, height: 1.35),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: cobranca.copiaCola),
                  );
                  if (!mounted) return;
                  setState(() => _copiado = true);
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: Text(_copiado ? 'Código copiado' : 'Copiar código Pix'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Aguardando a confirmação do Asaas.',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (_erro != null) ...[
              const SizedBox(height: 10),
              Text(
                _erro!,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: const Color(0xFFB91C1C),
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (cobranca == null || cobranca.copiaCola.isEmpty)
              FilledButton.icon(
                onPressed: _gerando ? null : _gerar,
                icon: _gerando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.pix_rounded, size: 18),
                label: Text(
                  _gerando ? 'Gerando Pix...' : 'Gerar Pix',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: widget.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(48, 48),
                ),
              ),
            TextButton(
              onPressed: _gerando ? null : () => Navigator.of(context).pop(false),
              child: const Text('Fechar'),
            ),
          ],
        ),
      ),
    );
  }
}
