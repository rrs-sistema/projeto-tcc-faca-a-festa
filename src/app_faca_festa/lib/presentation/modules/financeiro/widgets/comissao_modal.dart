import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// O mesmo conteúdo usa diálogo no desktop e painel no celular.
Future<void> mostrarComissaoModal({
  required BuildContext context,
  required WidgetBuilder builder,
}) async {
  if (MediaQuery.sizeOf(context).width >= 720) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: builder(ctx),
        ),
      ),
    );
  } else {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: (MediaQuery.sizeOf(ctx).height -
                    MediaQuery.viewInsetsOf(ctx).bottom -
                    MediaQuery.paddingOf(ctx).top) *
                .94,
          ),
          child: builder(ctx),
        ),
      ),
    );
  }
}

class ComissaoModal extends StatelessWidget {
  const ComissaoModal({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.icone,
    required this.accent,
    required this.child,
    this.footer,
    this.ocupado = false,
  });

  final String titulo;
  final String subtitulo;
  final IconData icone;
  final Color accent;
  final Widget child;
  final Widget? footer;
  final bool ocupado;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icone, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        )),
                    const SizedBox(height: 4),
                    Text(subtitulo,
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: const Color(0xFF64748B))),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Fechar',
                onPressed: ocupado ? null : () => Navigator.pop(context),
                style: IconButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    foregroundColor: const Color(0xFF475569)),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        Flexible(
          fit: FlexFit.loose,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: child,
          ),
        ),
        if (footer != null) ...[
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          SafeArea(
            top: false,
            child: Padding(padding: const EdgeInsets.all(16), child: footer),
          ),
        ],
      ],
    );
  }
}

class ComissaoStatus extends StatelessWidget {
  const ComissaoStatus({super.key, required this.status, this.pagador = false});

  final String? status;
  final bool pagador;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status?.toLowerCase()) {
      'previsao' => (
          'Previsão',
          const Color(0xFF475569),
          Icons.visibility_outlined
        ),
      'gerada' => (
          'Gerada',
          const Color(0xFF4338CA),
          Icons.receipt_long_outlined
        ),
      'a_vencer' => (
          'A vencer',
          const Color(0xFF92400E),
          Icons.schedule_rounded
        ),
      'vencida' => ('Vencida', const Color(0xFFBE123C), Icons.error_outline),
      'recebida' => (
          pagador ? 'Pagamento registrado' : 'Recebida',
          const Color(0xFF166534),
          Icons.check_circle_outline,
        ),
      'estornada' => ('Estornada', const Color(0xFF475569), Icons.undo_rounded),
      _ => (
          'Situação não informada',
          const Color(0xFF475569),
          Icons.help_outline
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Wrap(
        spacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
