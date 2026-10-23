import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PedidoMediacao {
  const PedidoMediacao({required this.motivo, this.descricao});

  final String motivo;
  final String? descricao;
}

/// Sheet para o organizador/fornecedor pedir mediação com motivo e detalhes.
Future<PedidoMediacao?> showAbrirMediacaoSheet({
  required BuildContext context,
  required Color primary,
  String? tituloServico,
}) {
  return showModalBottomSheet<PedidoMediacao>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final inset = MediaQuery.viewInsetsOf(ctx).bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: inset),
        child: _AbrirMediacaoSheet(
          primary: primary,
          tituloServico: tituloServico,
          onFechar: () => Navigator.of(ctx).pop(),
          onConfirmar: (p) => Navigator.of(ctx).pop(p),
        ),
      );
    },
  );
}

class _AbrirMediacaoSheet extends StatefulWidget {
  const _AbrirMediacaoSheet({
    required this.primary,
    required this.onFechar,
    required this.onConfirmar,
    this.tituloServico,
  });

  final Color primary;
  final String? tituloServico;
  final VoidCallback onFechar;
  final ValueChanged<PedidoMediacao> onConfirmar;

  @override
  State<_AbrirMediacaoSheet> createState() => _AbrirMediacaoSheetState();
}

class _AbrirMediacaoSheetState extends State<_AbrirMediacaoSheet> {
  final _motivoCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _erro;

  @override
  void dispose() {
    _motivoCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _confirmar() {
    final motivo = _motivoCtrl.text.trim();
    if (motivo.length < 5) {
      setState(() => _erro = 'Descreva o motivo com pelo menos 5 caracteres.');
      return;
    }
    widget.onConfirmar(
      PedidoMediacao(
        motivo: motivo,
        descricao: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final servico = (widget.tituloServico ?? '').trim();
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
              'Abrir mediação',
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
                'A equipe da plataforma analisa o caso. Notas internas '
                'permanecem privadas. Informe o motivo com clareza.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  height: 1.35,
                  color: const Color(0xFF334155),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _motivoCtrl,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 120,
              decoration: InputDecoration(
                labelText: 'Motivo *',
                hintText: 'Ex.: divergência de valor / prazo / execução',
                errorText: _erro,
                counterText: '',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) {
                if (_erro != null) setState(() => _erro = null);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              textCapitalization: TextCapitalization.sentences,
              minLines: 3,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: 'Detalhes (opcional)',
                hintText: 'Contexto, datas, o que já tentou resolver…',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _confirmar,
              icon: const Icon(Icons.gavel_outlined, size: 18),
              label: Text(
                'Enviar solicitação',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: widget.primary,
                minimumSize: const Size(48, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: widget.onFechar,
              child: Text(
                'Cancelar',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
