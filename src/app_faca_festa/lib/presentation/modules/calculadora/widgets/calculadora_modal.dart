import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Cabeçalho, rolagem e ações compartilhados.
///
/// Evita o ciclo teclado sobe/desce: o [Dialog] Material encolhe com
/// `viewInsets` e um corpo `Flexible` pode zerar altura, desmontar o
/// [TextField] e disparar `hideTextInput`. Aqui o IME não altera a altura do
/// cartão; só acrescenta padding no scroll.
class CalculadoraModal extends StatelessWidget {
  const CalculadoraModal(
      {super.key,
      required this.titulo,
      required this.icone,
      required this.child,
      this.subtitulo,
      this.rodape,
      this.onFechar,
      this.onVoltar,
      this.ocupado = false});
  final String titulo;
  final String? subtitulo;
  final IconData icone;
  final Widget child;
  final Widget? rodape;
  final VoidCallback? onFechar, onVoltar;
  final bool ocupado;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context), cores = tema.colorScheme;
    final mq = MediaQuery.of(context);
    final teclado = mq.viewInsets.bottom;
    final alturaTela = mq.size.height;
    final larguraTela = mq.size.width;
    final escala = mq.textScaler.scale(16);
    final compacto =
        alturaTela < 520 || (alturaTela < 700 && escala > 22);
    // Altura do cartão baseada na tela cheia — não muda ao abrir o IME.
    final alturaCartao = math.min(820.0, alturaTela - 24);
    final larguraCartao = math.min(620.0, larguraTela - 24);

    final tituloWidget =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(titulo,
          style:
              tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
      if (subtitulo != null) ...[
        const SizedBox(height: 4),
        Text(subtitulo!, style: tema.textTheme.bodyMedium)
      ],
    ]);

    final controles = Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(children: [
          if (onVoltar != null)
            IconButton(
                tooltip: 'Voltar',
                onPressed: ocupado ? null : onVoltar,
                icon: const Icon(Icons.arrow_back_rounded))
          else
            Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(icone, color: cores.primary)),
          const SizedBox(width: 8),
          if (compacto) const Spacer() else Expanded(child: tituloWidget),
          if (onFechar != null)
            IconButton(
                tooltip: 'Fechar',
                onPressed: ocupado ? null : onFechar,
                icon: const Icon(Icons.close_rounded)),
        ]));

    final acoes = rodape == null
        ? null
        : Material(
            color: cores.surface,
            child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    border:
                        Border(top: BorderSide(color: cores.outlineVariant))),
                child: rodape));

    // Zera viewInsets para o Dialog não aplicar AnimatedPadding do IME
    // (encolhe o filho e derruba o foco). O teclado só vira padding no scroll.
    return MediaQuery(
      data: mq.copyWith(viewInsets: EdgeInsets.zero),
      child: Theme(
        data: tema.copyWith(
          iconTheme: IconThemeData(color: cores.onSurface),
          filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                  backgroundColor: cores.primary,
                  foregroundColor: cores.onPrimary,
                  iconColor: cores.onPrimary,
                  minimumSize: const Size(48, 48))),
          textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                  foregroundColor: cores.primary,
                  iconColor: cores.primary,
                  minimumSize: const Size(48, 48))),
          outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                  foregroundColor: cores.primary,
                  iconColor: cores.primary,
                  minimumSize: const Size(48, 48))),
        ),
        child: Dialog(
            insetPadding: const EdgeInsets.all(12),
            backgroundColor: cores.surface,
            surfaceTintColor: Colors.transparent,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
            child: SizedBox(
                width: larguraCartao,
                height: alturaCartao,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      controles,
                      Divider(height: 1, color: cores.outlineVariant),
                      Expanded(
                          child: SingleChildScrollView(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        if (compacto) ...[
                                          tituloWidget,
                                          const SizedBox(height: 16),
                                        ],
                                        child,
                                      ])))),
                      if (acoes != null) acoes,
                      // Reserva a faixa do IME sem encolher/desmontar o corpo.
                      SizedBox(height: teclado),
                    ]))),
      ),
    );
  }
}

/// Banner informativo no padrão Agenda / Regra de consumo.
class CalculadoraModalBanner extends StatelessWidget {
  const CalculadoraModalBanner({
    super.key,
    required this.texto,
    this.icone = Icons.info_outline_rounded,
  });

  final String texto;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    final cor = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 18, color: cor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bloco de seção com título + descrição curta.
class CalculadoraModalSecao extends StatelessWidget {
  const CalculadoraModalSecao({
    super.key,
    required this.titulo,
    required this.descricao,
    required this.filhos,
  });

  final String titulo;
  final String descricao;
  final List<Widget> filhos;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          if (descricao.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              descricao,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          ...filhos,
        ],
      ),
    );
  }
}

InputDecoration calculadoraModalCampo(
  BuildContext context,
  String label,
  IconData icon, {
  String? hint,
  String? suffix,
}) {
  final scheme = Theme.of(context).colorScheme;
  return InputDecoration(
    labelText: label,
    hintText: hint,
    suffixText: suffix,
    prefixIcon: Icon(icon, size: 20, color: scheme.primary),
    filled: true,
    fillColor: scheme.surfaceContainerLowest,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: scheme.outlineVariant),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: scheme.primary, width: 2),
    ),
    errorMaxLines: 3,
  );
}

Widget calculadoraModalRodape({
  required BuildContext context,
  required String confirmar,
  required VoidCallback? onConfirmar,
  VoidCallback? onCancelar,
  String cancelar = 'Cancelar',
  IconData? iconeConfirmar,
  String? dica,
  bool ocupado = false,
}) {
  final scheme = Theme.of(context).colorScheme;
  final tecladoAberto = MediaQuery.viewInsetsOf(context).bottom > 0;
  return Padding(
    padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (dica != null && dica.isNotEmpty) ...[
          Text(
            dica,
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: ocupado ? null : onConfirmar,
            icon: ocupado
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(iconeConfirmar ?? Icons.check_rounded),
            label: Text(
              confirmar,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        if (onCancelar != null && !tecladoAberto)
          SizedBox(
            width: double.infinity,
            child: TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: ocupado ? null : onCancelar,
              child: Text(cancelar),
            ),
          ),
      ],
    ),
  );
}
