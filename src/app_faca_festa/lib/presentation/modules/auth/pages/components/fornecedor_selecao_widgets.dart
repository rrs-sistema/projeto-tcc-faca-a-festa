import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FornecedorOpcoesGrid extends StatelessWidget {
  const FornecedorOpcoesGrid({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final ampliado = MediaQuery.textScalerOf(context).scale(1) > 1.3;
        final colunas = ampliado || box.maxWidth < 480
            ? 1
            : box.maxWidth < 820
                ? 2
                : 3;
        final largura = (box.maxWidth - (colunas - 1) * 10) / colunas;
        return SizedBox(
            width: double.infinity,
            child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: children
                    .map((child) => SizedBox(width: largura, child: child))
                    .toList()));
      });
}

class FornecedorEscolha extends StatelessWidget {
  const FornecedorEscolha(
      {super.key,
      required this.titulo,
      required this.selecionado,
      required this.cor,
      required this.onPressed,
      this.icone,
      this.habilitado = true});
  final String titulo;
  final bool selecionado;
  final Color cor;
  final VoidCallback onPressed;
  final IconData? icone;
  final bool habilitado;

  @override
  Widget build(BuildContext context) => Semantics(
        checked: selecionado,
        child: TextButton(
          onPressed: habilitado ? onPressed : null,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF1F2937),
            backgroundColor:
                selecionado ? cor.withValues(alpha: .07) : Colors.white,
            padding: const EdgeInsets.all(14),
            minimumSize: const Size(48, 58),
            alignment: Alignment.centerLeft,
            side: BorderSide(
                color: selecionado ? cor : const Color(0xFFE2E8F0),
                width: selecionado ? 1.5 : 1),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Row(children: [
            if (icone != null) ...[
              Icon(icone, color: cor, size: 20),
              const SizedBox(width: 10)
            ],
            Expanded(
                child: Text(titulo,
                    softWrap: true,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        height: 1.4,
                        fontWeight:
                            selecionado ? FontWeight.w600 : FontWeight.w500))),
            const SizedBox(width: 10),
            Icon(
                selecionado
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                color: selecionado ? cor : const Color(0xFF94A3B8),
                size: 21),
          ]),
        ),
      );
}

class FornecedorSecaoSelecao extends StatelessWidget {
  const FornecedorSecaoSelecao(
      {super.key,
      required this.titulo,
      required this.descricao,
      required this.cor,
      required this.icone,
      required this.child,
      this.resumo});
  final String titulo;
  final String descricao;
  final Color cor;
  final IconData icone;
  final Widget child;
  final String? resumo;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: cor.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icone, color: cor, size: 21)),
            const SizedBox(width: 12),
            Expanded(
                child: Text(titulo,
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827)))),
          ]),
          const SizedBox(height: 12),
          Text(descricao,
              style: GoogleFonts.poppins(
                  fontSize: 12.5, height: 1.5, color: const Color(0xFF475569))),
          if (resumo != null) ...[
            const SizedBox(height: 10),
            Text(resumo!,
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w600, color: cor)),
          ],
          const SizedBox(height: 16),
          child,
        ]),
      );
}
