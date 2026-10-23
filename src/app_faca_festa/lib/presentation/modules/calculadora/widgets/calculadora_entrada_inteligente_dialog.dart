import 'calculadora_modal.dart';
import 'dart:convert';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import '../controllers/calculadora_festa_controller.dart';

class CalculadoraEntradaInteligenteDialog extends StatefulWidget {
  const CalculadoraEntradaInteligenteDialog(
      {super.key,
      required this.controller,
      this.textoInicial = '',
      this.selecionarArquivo});
  final CalculadoraFestaController controller;
  final String textoInicial;
  final Future<XFile?> Function()? selecionarArquivo;
  @override
  State<CalculadoraEntradaInteligenteDialog> createState() => _EntradaState();
}

class _EntradaState extends State<CalculadoraEntradaInteligenteDialog> {
  late final texto = TextEditingController(text: widget.textoInicial);
  Map<String, dynamic>? anexo, proposta;
  String? nomeArquivo, erro, assinatura;
  final selecionadas = <String>{};
  bool ocupada = false, documento = false, conferiuDuplicidade = false;
  late final String sessao;
  @override
  void initState() {
    super.initState();
    sessao = widget.controller.sessaoPlanejador;
  }

  void conferirSessao() {
    if (sessao != widget.controller.sessaoPlanejador) {
      throw StateError('O evento ou a sessão mudou. Feche e reabra a leitura.');
    }
  }

  @override
  void dispose() {
    texto.dispose();
    super.dispose();
  }

  void invalidar() {
    proposta = null;
    selecionadas.clear();
    conferiuDuplicidade = false;
    erro = null;
  }

  Future<void> escolher() async {
    try {
      conferirSessao();
      final arquivo = await (widget.selecionarArquivo?.call() ??
          openFile(acceptedTypeGroups: [
            const XTypeGroup(label: 'Documento', extensions: [
              'pdf',
              'png',
              'jpg',
              'jpeg',
              'webp',
              'txt'
            ], mimeTypes: [
              'application/pdf',
              'image/png',
              'image/jpeg',
              'image/webp',
              'text/plain'
            ], uniformTypeIdentifiers: [
              'com.adobe.pdf',
              'public.image',
              'public.plain-text'
            ])
          ]));
      if (arquivo == null || !mounted) return;
      if (await arquivo.length() > 4194304) {
        throw StateError('Selecione um arquivo de até 4 MB.');
      }
      final bytes = await arquivo.readAsBytes();
      if (!mounted) return;
      conferirSessao();
      final ext = arquivo.name.toLowerCase().split('.').last;
      final tipo = {
        'pdf': 'application/pdf',
        'png': 'image/png',
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'webp': 'image/webp'
      }[ext];
      if (tipo == null && ext != 'txt') {
        throw StateError('Use PDF, PNG, JPEG, WebP ou texto.');
      }
      if (ext == 'txt' && utf8.decode(bytes).length > 16000) {
        throw StateError('Separe o texto em trechos de até 16 mil caracteres.');
      }
      setState(() {
        invalidar();
        documento = true;
        nomeArquivo = arquivo.name;
        anexo =
            tipo == null ? null : {'mime': tipo, 'base64': base64Encode(bytes)};
        if (tipo == null) texto.text = utf8.decode(bytes);
      });
    } catch (e) {
      if (mounted) setState(() => erro = e.toString());
    }
  }

  Future<void> ler() async {
    if (ocupada) return;
    setState(() {
      ocupada = true;
      erro = null;
      proposta = null;
    });
    try {
      conferirSessao();
      final c = widget.controller, antes = widget.controller.assinaturaProposta;
      final p = await c.interpretarEntradaAssistente(texto.text,
          anexo: anexo, documento: documento);
      if (!mounted) return;
      conferirSessao();
      if (antes != c.assinaturaProposta) {
        throw StateError('O planejamento mudou. Faça a leitura novamente.');
      }
      setState(() {
        proposta = p;
        assinatura = antes;
        selecionadas.clear();
        conferiuDuplicidade = false;
        selecionadas.addAll((p['acoes'] as List).map((a) => a['id'] as String));
      });
    } catch (e) {
      if (mounted) {
        setState(() => erro = e.toString().replaceFirst('Bad state: ', ''));
      }
    } finally {
      if (mounted) setState(() => ocupada = false);
    }
  }

  Future<void> aplicar() async {
    if (ocupada || proposta == null) return;
    setState(() {
      ocupada = true;
      erro = null;
    });
    try {
      conferirSessao();
      await widget.controller.aplicarEntradaAssistente(
          proposta!, selecionadas.toList()..sort(), assinatura!,
          conferiuDuplicidade: conferiuDuplicidade);
      if (mounted && sessao == widget.controller.sessaoPlanejador) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => erro = e.toString().replaceFirst('Bad state: ', ''));
      }
    } finally {
      if (mounted) setState(() => ocupada = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teclado = MediaQuery.viewInsetsOf(context).bottom > 0;
    final acoes = proposta?['acoes'] as List? ?? [],
        perguntas = proposta?['perguntas'] as List? ?? [];
    final aviso = proposta?['aviso_duplicidade'];
    return PopScope(
        canPop: !ocupada,
        child: CalculadoraModal(
          titulo: 'Leitura inteligente',
          icone: Icons.auto_awesome_outlined,
          ocupado: ocupada,
          onFechar: () => Navigator.pop(context),
          rodape: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextButton(
                    onPressed: ocupada ? null : ler,
                    child: Text(ocupada ? 'Aguarde…' : 'Preparar leitura')),
                FilledButton(
                    onPressed: ocupada ||
                            proposta == null ||
                            selecionadas.isEmpty ||
                            (aviso != null && !conferiuDuplicidade)
                        ? null
                        : aplicar,
                    child: Text('Aplicar ${selecionadas.length} ação(ões)'))
              ]),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                    'Descreva o que mudou ou anexe uma receita, cotação, nota ou comprovante. Confira o conjunto antes de gravar.'),
                const SizedBox(height: 12),
                TextField(
                    controller: texto,
                    enabled: !ocupada,
                    minLines: teclado ? 1 : 3,
                    maxLines: teclado ? 3 : 7,
                    maxLength: 16000,
                    onChanged: (_) => setState(invalidar),
                    decoration: const InputDecoration(
                        labelText: 'Pedido e esclarecimentos',
                        hintText:
                            'Comprei 5 kg de arroz cru para o almoço. O preço é R\$ 6 por kg.')),
                OutlinedButton.icon(
                    onPressed: ocupada ? null : escolher,
                    icon: const Icon(Icons.attach_file),
                    label: Text(nomeArquivo ?? 'Anexar documento ou foto')),
                if (nomeArquivo != null)
                  TextButton(
                      onPressed: ocupada
                          ? null
                          : () => setState(() {
                                nomeArquivo = null;
                                anexo = null;
                                documento = false;
                                invalidar();
                              }),
                      child: const Text('Remover anexo')),
                if (anexo == null)
                  SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Texto colado de um documento'),
                      value: documento,
                      onChanged: ocupada
                          ? null
                          : (v) => setState(() {
                                documento = v;
                                invalidar();
                              })),
                const Text(
                    'Ao preparar a leitura, o conteúdo e o contexto necessário são enviados à IA. O arquivo original não é guardado no planejamento.',
                    style: TextStyle(fontSize: 12)),
                if (proposta != null) ...[
                  const Divider(height: 24),
                  Text('${proposta!['resumo']}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  if ((proposta!['ja_registradas'] as num? ?? 0) > 0)
                    Text(
                        '${proposta!['ja_registradas']} ação(ões) deste documento já registrada(s), sem nova inclusão.'),
                  if (acoes.isEmpty)
                    const Text('Nenhuma nova ação pronta para aplicar.'),
                  for (final a in acoes)
                    CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: selecionadas.contains(a['id']),
                        onChanged: ocupada
                            ? null
                            : (v) => setState(() {
                                  if (v == true) {
                                    selecionadas.add(a['id']);
                                  } else {
                                    selecionadas.remove(a['id']);
                                  }
                                }),
                        title: Text('${a['descricao']}'),
                        subtitle: Text('Trecho: ${a['evidencia']}')),
                  if (acoes.any((a) => a['receita'] != null))
                    ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text('Conferir ingredientes extraídos'),
                        children: [
                          for (final a
                              in acoes.where((a) => a['receita'] != null)) ...[
                            Text('${a['descricao']}'),
                            Text(
                                'Rendimento: ${a['receita']['rendimento']} ${a['receita']['unidade']} (${a['receita']['estado']})'),
                            for (final i in a['receita']['ingredientes'])
                              Text(
                                  '${i['nome']}: ${i['quantidade']} ${i['unidade']} (${i['estado']})'),
                          ]
                        ]),
                  if (perguntas.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Ainda precisa esclarecer',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    for (final p in perguntas)
                      Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('• $p')),
                    const Text(
                        'Esclareça no pedido e prepare novamente, ou aplique apenas as ações prontas selecionadas.',
                        style: TextStyle(fontSize: 12))
                  ],
                  if (aviso != null)
                    CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: conferiuDuplicidade,
                        onChanged: ocupada
                            ? null
                            : (v) =>
                                setState(() => conferiuDuplicidade = v == true),
                        title: Text('$aviso'),
                        subtitle: const Text(
                            'Conferi que as ações selecionadas ainda não foram lançadas.')),
                ],
                if (erro != null)
                  Text(erro!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
              ]),
        ));
  }
}
