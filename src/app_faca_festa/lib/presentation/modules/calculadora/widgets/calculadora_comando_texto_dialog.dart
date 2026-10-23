import 'calculadora_modal.dart';
import 'package:app_faca_festa/domain/entities/confirmacao_configuracao_calculadora.dart';
import 'calculadora_entrada_inteligente_dialog.dart';
import 'package:flutter/material.dart';
import '../controllers/calculadora_festa_controller.dart';
import 'package:app_faca_festa/domain/services/comando_texto_calculadora_service.dart';

class CalculadoraComandoTextoDialog extends StatefulWidget {
  const CalculadoraComandoTextoDialog({super.key, required this.controller});
  final CalculadoraFestaController controller;
  @override
  State<CalculadoraComandoTextoDialog> createState() => _TextoState();
}

class _TextoState extends State<CalculadoraComandoTextoDialog> {
  final texto = TextEditingController();
  List<ComandoTextoCalculadora>? comandos;
  String? assinatura, erro;
  bool salvando = false;
  ConfirmacaoConfiguracaoCalculadora? tentativa;
  late final String sessao;
  @override
  void initState() {
    super.initState();
    sessao = widget.controller.sessaoPlanejador;
  }

  void conferirSessao() {
    if (sessao != widget.controller.sessaoPlanejador) {
      throw StateError(
          'O evento ou a sessão mudou. Feche e reabra o planejamento.');
    }
  }

  @override
  void dispose() {
    texto.dispose();
    super.dispose();
  }

  void interpretar() {
    tentativa = null;
    try {
      conferirSessao();
      final resultado =
          const ComandoTextoCalculadoraService().interpretar(texto.text);
      FocusScope.of(context).unfocus();
      setState(() {
        comandos = resultado;
        assinatura = widget.controller.assinaturaProposta;
        erro = null;
      });
    } catch (e) {
      setState(() {
        comandos = null;
        erro = e.toString().replaceFirst('Invalid argument(s): ', '');
      });
    }
  }

  Future<void> aplicar() async {
    if (salvando) return;
    setState(() {
      salvando = true;
      erro = null;
    });
    try {
      conferirSessao();
      tentativa ??=
          widget.controller.prepararComandosTexto(comandos!, assinatura!);
      await widget.controller.confirmarConfiguracao(tentativa!);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        erro = e.toString();
      });
    } finally {
      if (mounted) setState(() => salvando = false);
    }
  }

  Future<void> abrirIA() async {
    try {
      conferirSessao();
    } catch (e) {
      setState(() => erro = e.toString().replaceFirst('Bad state: ', ''));
      return;
    }
    FocusScope.of(context).unfocus();
    final aplicado = await showDialog<bool>(
        context: context,
        builder: (_) => CalculadoraEntradaInteligenteDialog(
            controller: widget.controller, textoInicial: texto.text));
    if (aplicado == true &&
        mounted &&
        sessao == widget.controller.sessaoPlanejador) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final teclado = MediaQuery.viewInsetsOf(context).bottom > 0;
    return PopScope(
        canPop: !salvando,
        child: CalculadoraModal(
            titulo: 'Planejar por texto',
            icone: Icons.edit_note_rounded,
            ocupado: salvando,
            onFechar: () => Navigator.pop(context),
            rodape: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton.icon(
                          style: FilledButton.styleFrom(
                              backgroundColor: scheme.primary,
                              foregroundColor: scheme.onPrimary,
                              iconColor: scheme.onPrimary,
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14))),
                          onPressed: salvando
                              ? null
                              : comandos == null
                                  ? interpretar
                                  : aplicar,
                          icon: Icon(comandos == null
                              ? Icons.preview_outlined
                              : Icons.check_rounded),
                          label: Text(comandos == null
                              ? 'Preparar ajustes'
                              : 'Usar estes ajustes')),
                      if (!teclado)
                        TextButton(
                            onPressed:
                                salvando ? null : () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                                minimumSize: const Size.fromHeight(48)),
                            child: const Text('Cancelar')),
                    ])),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!teclado) ...[
                    Text('Descreva sua festa',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface)),
                    const SizedBox(height: 6),
                    Text(
                        'Informe quem vai participar, a duração ou o perfil da festa. Você revisa os ajustes antes de aplicar.',
                        style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: texto,
                    enabled: !salvando,
                    minLines: teclado ? 2 : 4,
                    maxLines: teclado ? 2 : 6,
                    maxLength: 1500,
                    textCapitalization: TextCapitalization.sentences,
                    scrollPadding: const EdgeInsets.all(24),
                    onChanged: (_) => setState(() {
                      comandos = null;
                      tentativa = null;
                      erro = null;
                    }),
                    decoration: InputDecoration(
                      counterText: teclado ? '' : null,
                      labelText: 'O que deseja planejar?',
                      alignLabelWithHint: true,
                      hintText:
                          'Ex.: 30 adultos e 8 crianças, 6 horas, perfil padrão.',
                      filled: true,
                      fillColor: scheme.surface,
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: scheme.outlineVariant)),
                    ),
                  ),
                  if (erro != null)
                    Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Semantics(
                            liveRegion: true,
                            child: Text(erro!,
                                style: TextStyle(
                                    color: scheme.error, fontSize: 13)))),
                  if (comandos != null) ...[
                    const SizedBox(height: 16),
                    Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: .07),
                            borderRadius: BorderRadius.circular(14)),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Confira os ajustes',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: scheme.onSurface)),
                              const SizedBox(height: 12),
                              for (final comando in comandos!)
                                Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                              Icons
                                                  .check_circle_outline_rounded,
                                              size: 18,
                                              color: scheme.primary),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(comando.resumo)),
                                        ])),
                              Text(
                                  widget.controller.possuiEventoVinculado
                                      ? 'Confirma estas escolhas no planejamento do evento. Compras, pagamentos e quantidades finais continuam separados.'
                                      : 'Aplica à estimativa do cadastro. Confira a confirmação de armazenamento antes de sair.',
                                  style: const TextStyle(
                                      fontSize: 14, height: 1.5)),
                            ])),
                  ] else ...[
                    const SizedBox(height: 8),
                    Text('Também aceita: “usar convidados não recusados”.',
                        style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: scheme.onSurfaceVariant)),
                  ],
                  const Divider(height: 28),
                  Text('Quer informar compras ou preços?',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface)),
                  const SizedBox(height: 4),
                  Text(
                      'Use a IA para interpretar quantidades, valores ou documentos e revisar as sugestões.',
                      style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: scheme.onSurfaceVariant)),
                  Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                          onPressed: salvando ? null : abrirIA,
                          icon:
                              const Icon(Icons.auto_awesome_outlined, size: 18),
                          style: TextButton.styleFrom(
                              foregroundColor: scheme.primary,
                              iconColor: scheme.primary,
                              minimumSize: const Size(48, 48)),
                          label: const Text('Interpretar com IA'))),
                ])));
  }
}
