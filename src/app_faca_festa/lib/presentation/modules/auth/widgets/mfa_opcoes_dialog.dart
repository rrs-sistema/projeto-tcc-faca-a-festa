import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:app_faca_festa/domain/entities/resultados_operacao.dart';
import 'package:app_faca_festa/domain/repositories/autenticacao_repository.dart';

class MfaOpcoesDialog extends StatefulWidget {
  const MfaOpcoesDialog({
    super.key,
    required this.autenticacao,
    required this.autorizacao,
    required this.emailAtivo,
    required this.totpAtivo,
  });

  final AutenticacaoRepository autenticacao;
  final String autorizacao;
  final bool emailAtivo;
  final bool totpAtivo;

  @override
  State<MfaOpcoesDialog> createState() => _MfaOpcoesDialogState();
}

class _MfaOpcoesDialogState extends State<MfaOpcoesDialog> {
  final _codigo = TextEditingController();
  late bool _emailAtivo = widget.emailAtivo;
  late bool _totpAtivo = widget.totpAtivo;
  InicioTotpMfa? _autenticador;
  CodigoEmailMfa? _email;
  List<String> _codigos = const [];
  bool _ocupado = false;
  bool _copiado = false;
  String? _erro;

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _executar<T>(
    Future<T> Function() operacao,
    void Function(T) aplicar,
  ) async {
    if (_ocupado) return;
    setState(() {
      _ocupado = true;
      _erro = null;
    });
    try {
      final resultado = await operacao();
      if (mounted) setState(() => aplicar(resultado));
    } catch (erro) {
      if (mounted) {
        setState(() => _erro = erro is AutenticacaoException
            ? erro.mensagem ?? 'Não foi possível concluir. Tente novamente.'
            : 'Não foi possível concluir. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _confirmarMetodo() async {
    final codigo = _codigo.text.trim();
    if (codigo.length != 6) {
      setState(() => _erro = 'Informe o código de 6 dígitos.');
      return;
    }
    final porEmail = _email != null;
    final confirmar = porEmail
        ? widget.autenticacao.confirmarEmailMfa
        : widget.autenticacao.confirmarTotpMfa;
    await _executar(
      () => confirmar(codigo, autorizacao: widget.autorizacao),
      (_) {
        if (porEmail) {
          _emailAtivo = true;
        } else {
          _totpAtivo = true;
        }
        _voltar();
      },
    );
  }

  Future<void> _enviarEmail() => _executar(
        () => widget.autenticacao
            .solicitarCodigoEmailMfa(autorizacao: widget.autorizacao),
        (resultado) => _email = resultado,
      );

  void _voltar() {
    _autenticador = null;
    _email = null;
    _codigo.clear();
    _erro = null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.autorizacao.isEmpty) {
      return PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Opções de segurança indisponíveis'),
          content: const Text(
            'Seu código de login foi confirmado. A configuração dos métodos '
            'e a geração dos códigos de recuperação dependem da atualização '
            'do serviço de segurança.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entrar agora'),
            ),
          ],
        ),
      );
    }
    final configurando = _autenticador != null || _email != null;
    final exibindoCodigos = _codigos.isNotEmpty;
    return PopScope(
      canPop: false,
      child: AlertDialog(
        scrollable: true,
        title: Text(exibindoCodigos
            ? 'Guarde seus códigos de recuperação'
            : 'Opções de segurança'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (exibindoCodigos) ...[
                const Text(
                  'Guarde a lista em um local seguro fora do e-mail. Cada '
                  'código só funciona uma vez. A lista aparece apenas agora.',
                ),
                const SizedBox(height: 16),
                SelectableText(
                  _codigos.join('\n'),
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ] else if (configurando) ...[
                if (_autenticador case final dados?) ...[
                  const Text(
                    'Escaneie o QR Code no Google Authenticator ou cadastre a chave no app.',
                  ),
                  if (_totpAtivo)
                    const Text(
                      'O autenticador anterior funciona até você confirmar o novo.',
                    ),
                  Center(
                    child: SizedBox.square(
                      // O AlertDialog mede o conteúdo antes do LayoutBuilder do QR.
                      dimension: 160,
                      child: QrImageView(data: dados.otpauthUrl),
                    ),
                  ),
                  SelectableText(dados.secret, textAlign: TextAlign.center),
                ],
                if (_email case final dados?) ...[
                  Text([dados.mensagem, dados.emailMascarado].join('\n')),
                  TextButton(
                    onPressed: _ocupado ? null : _enviarEmail,
                    child: const Text('Reenviar código'),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: _codigo,
                  enabled: !_ocupado,
                  decoration: const InputDecoration(labelText: 'Código'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onSubmitted: (_) => _confirmarMetodo(),
                ),
              ] else ...[
                if (_totpAtivo) const Text('App autenticador ativo'),
                OutlinedButton(
                  onPressed: _ocupado
                      ? null
                      : () => _executar(
                            () => widget.autenticacao.iniciarTotpMfa(
                              autorizacao: widget.autorizacao,
                            ),
                            (resultado) => _autenticador = resultado,
                          ),
                  child: Text(_totpAtivo
                      ? 'Substituir app autenticador'
                      : 'Adicionar app autenticador'),
                ),
                if (_emailAtivo) const Text('Código por e-mail ativo'),
                if (!_emailAtivo)
                  OutlinedButton(
                    onPressed: _ocupado ? null : _enviarEmail,
                    child: const Text('Adicionar código por e-mail'),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Use um código de recuperação se perder acesso aos métodos '
                  'cadastrados. Gerar uma nova lista invalida a anterior.',
                ),
                TextButton(
                  onPressed: _ocupado
                      ? null
                      : () => _executar(
                            () =>
                                widget.autenticacao.gerarCodigosRecuperacaoMfa(
                              widget.autorizacao,
                            ),
                            (resultado) => _codigos = resultado,
                          ),
                  child: const Text('Gerar códigos de recuperação'),
                ),
              ],
              if (_ocupado) const LinearProgressIndicator(),
              if (_erro case final mensagem?)
                Text(mensagem,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ),
        ),
        actions: [
          if (exibindoCodigos)
            TextButton(
              onPressed: () async {
                await Clipboard.setData(
                    ClipboardData(text: _codigos.join('\n')));
                if (mounted) setState(() => _copiado = true);
              },
              child: Text(_copiado ? 'Códigos copiados' : 'Copiar códigos'),
            ),
          if (configurando) ...[
            TextButton(
              onPressed: _ocupado ? null : () => setState(_voltar),
              child: const Text('Voltar'),
            ),
            FilledButton(
              onPressed: _ocupado ? null : _confirmarMetodo,
              child: const Text('Confirmar método'),
            ),
          ] else
            FilledButton(
              onPressed: _ocupado ? null : () => Navigator.of(context).pop(),
              child: Text(
                  exibindoCodigos ? 'Já guardei, entrar' : 'Concluir e entrar'),
            ),
        ],
      ),
    );
  }
}
