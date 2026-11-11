import 'package:flutter/material.dart';
import 'package:app_faca_festa/presentation/widgets/operacao/operacao_surface.dart';

Future<bool?> mostrarAutorizacaoRepasseModal({
  required BuildContext context,
  required bool autorizar,
  required Future<bool> Function(String motivo) onConfirmar,
  String? fornecedor,
  String? servico,
}) {
  final formulario = _AutorizacaoRepasseForm(
    autorizar: autorizar,
    onConfirmar: onConfirmar,
    fornecedor: fornecedor,
    servico: servico,
  );
  if (MediaQuery.sizeOf(context).width >= 720) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: formulario,
        ),
      ),
    );
  }

  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    enableDrag: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: SafeArea(top: false, child: formulario),
    ),
  );
}

class _AutorizacaoRepasseForm extends StatefulWidget {
  const _AutorizacaoRepasseForm({
    required this.autorizar,
    required this.onConfirmar,
    this.fornecedor,
    this.servico,
  });

  final bool autorizar;
  final Future<bool> Function(String motivo) onConfirmar;
  final String? fornecedor;
  final String? servico;

  @override
  State<_AutorizacaoRepasseForm> createState() =>
      _AutorizacaoRepasseFormState();
}

class _AutorizacaoRepasseFormState extends State<_AutorizacaoRepasseForm> {
  final _form = GlobalKey<FormState>();
  final _motivo = TextEditingController();
  bool _validarAoEditar = false;
  bool _enviando = false;
  bool _falhou = false;

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    if (_enviando) return;
    if (!_form.currentState!.validate()) {
      if (!_validarAoEditar) setState(() => _validarAoEditar = true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _enviando = true;
      _falhou = false;
    });
    final bool registrado;
    try {
      registrado = await widget.onConfirmar(_motivo.text.trim());
    } catch (_) {
      if (mounted) _mostrarFalha();
      return;
    }
    if (!mounted) return;
    if (registrado) {
      Navigator.of(context).pop(true);
      return;
    }
    _mostrarFalha();
  }

  void _mostrarFalha() {
    setState(() {
      _enviando = false;
      _falhou = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cores = theme.colorScheme;
    final autorizar = widget.autorizar;
    final identificacao = [widget.fornecedor?.trim(), widget.servico?.trim()]
        .whereType<String>()
        .where((texto) => texto.isNotEmpty)
        .join(' · ');
    return PopScope<bool>(
      canPop: !_enviando,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          autovalidateMode: _validarAoEditar
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OperacaoHeading(
                title: autorizar
                    ? 'Autorizar pagamento antecipado'
                    : 'Revogar autorização antecipada',
                subtitle: identificacao.isEmpty ? null : identificacao,
                icon:
                    autorizar ? Icons.verified_user_outlined : Icons.lock_reset,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cores.surfaceContainerHighest.withValues(alpha: .55),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  autorizar
                      ? 'A administração poderá pagar o fornecedor antes do fim do evento se houver saldo conferido e nenhum bloqueio de mediação.'
                      : 'A administração deverá aguardar o fim do evento para pagar o fornecedor. Pagamentos já confirmados permanecem registrados.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: cores.onSurfaceVariant, height: 1.4),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _motivo,
                readOnly: _enviando,
                minLines: 2,
                maxLines: 3,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: autorizar
                      ? 'Motivo da autorização'
                      : 'Motivo da revogação',
                  alignLabelWithHint: true,
                  helperText: 'Mínimo de 10 caracteres',
                  helperMaxLines: 2,
                  errorMaxLines: 3,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (valor) => (valor?.trim().length ?? 0) < 10
                    ? 'Informe pelo menos 10 caracteres.'
                    : null,
              ),
              if (_falhou) ...[
                const SizedBox(height: 8),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    autorizar
                        ? 'Não foi possível registrar a autorização. Tente novamente.'
                        : 'Não foi possível revogar a autorização. Tente novamente.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: cores.error),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              OverflowBar(
                spacing: 8,
                overflowSpacing: 8,
                alignment: MainAxisAlignment.end,
                overflowAlignment: OverflowBarAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _enviando ? null : () => Navigator.of(context).pop(),
                    style:
                        TextButton.styleFrom(minimumSize: const Size(48, 48)),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: _enviando ? null : _confirmar,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      disabledBackgroundColor: cores.primaryContainer,
                      disabledForegroundColor: cores.onPrimaryContainer,
                    ),
                    child: _enviando
                        ? Wrap(
                            spacing: 8,
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: cores.onPrimaryContainer,
                                ),
                              ),
                              Semantics(
                                liveRegion: true,
                                child: Text(autorizar
                                    ? 'Registrando autorização…'
                                    : 'Revogando autorização…'),
                              ),
                            ],
                          )
                        : Text(autorizar
                            ? 'Autorizar pagamento'
                            : 'Revogar autorização'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
