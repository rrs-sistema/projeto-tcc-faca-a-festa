import 'package:flutter/material.dart';
import 'package:app_faca_festa/domain/services/importacao_receita_texto_service.dart';
import 'package:uuid/uuid.dart';
import 'package:app_faca_festa/core/utils/numeric_input.dart';
import 'package:app_faca_festa/domain/services/ficha_tecnica_calculadora_service.dart';
import 'package:app_faca_festa/domain/services/operacao_calculadora_service.dart';

class CalculadoraFichaTecnicaDialog extends StatefulWidget {
  const CalculadoraFichaTecnicaDialog(
      {super.key,
      required this.prato,
      required this.unidade,
      required this.estado,
      this.inicial});
  final String prato, unidade, estado;
  final Map<String, dynamic>? inicial;
  @override
  State<CalculadoraFichaTecnicaDialog> createState() => _Estado();
}

class _Ingrediente {
  _Ingrediente(Map<String, dynamic> v)
      : id = v['id'] ?? const Uuid().v4(),
        nome = TextEditingController(text: v['nome'] ?? ''),
        quantidade = TextEditingController(
            text: v['quantidade'] == null
                ? ''
                : NumericInput.quantidade(v['quantidade'])),
        unidade = v['unidade'] ?? 'kg',
        estado = v['estado'] ?? 'cru';
  final String id;
  final TextEditingController nome, quantidade;
  String unidade, estado;
  void dispose() {
    nome.dispose();
    quantidade.dispose();
  }
}

class _Estado extends State<CalculadoraFichaTecnicaDialog> {
  final form = GlobalKey<FormState>();
  late final rendimento = TextEditingController(
      text: widget.inicial?['rendimento'] == null
          ? ''
          : NumericInput.quantidade(widget.inicial!['rendimento']));
  late final List<_Ingrediente> itens =
      OperacaoCalculadoraService.lista(widget.inicial?['ingredientes'])
          .map(_Ingrediente.new)
          .toList();
  final removidos = <_Ingrediente>[];
  Future<void> importar() async {
    final texto = TextEditingController();
    String? erro;
    final ficha = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, atualizar) => AlertDialog(
                  title: const Text('Colar minha receita'),
                  content: SizedBox(
                      width: 480,
                      child: SingleChildScrollView(
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                            Text(
                                'Use o rendimento em ${widget.unidade} (${widget.estado}) e medidas reais da sua receita. Exemplo de formato:'),
                            const Text(
                                'Rende 1 kg pronto\n1 kg de frutas (pronto)',
                                style: TextStyle(fontSize: 12)),
                            const SizedBox(height: 12),
                            TextField(
                                controller: texto,
                                minLines: 4,
                                maxLines: 10,
                                maxLength: 6000,
                                decoration: const InputDecoration(
                                    labelText: 'Receita com medidas')),
                            if (erro != null)
                              Text(erro!,
                                  style: TextStyle(
                                      color: Theme.of(ctx).colorScheme.error)),
                          ]))),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancelar')),
                    FilledButton(
                        onPressed: () {
                          try {
                            final f = const ImportacaoReceitaTextoService()
                                .interpretar(texto.text,
                                    prato: widget.prato,
                                    unidade: widget.unidade,
                                    estado: widget.estado);
                            Navigator.pop(ctx, f);
                          } catch (e) {
                            atualizar(() => erro = e.toString());
                          }
                        },
                        child: const Text('Preparar ficha'))
                  ],
                )));
    await Future<void>.delayed(const Duration(milliseconds: 300));
    texto.dispose();
    if (!mounted) return;
    if (ficha != null) {
      setState(() {
        removidos.addAll(itens);
        itens.clear();
        itens.addAll(OperacaoCalculadoraService.lista(ficha['ingredientes'])
            .map(_Ingrediente.new));
        rendimento.text = NumericInput.quantidade(ficha['rendimento']);
      });
    }
  }

  @override
  void dispose() {
    rendimento.dispose();
    for (final i in [...itens, ...removidos]) {
      i.dispose();
    }
    super.dispose();
  }

  String? positivo(String? s) => (NumericInput.parse(s) ?? 0) > 0 &&
          (NumericInput.parse(s) ?? 0) <= 1000000
      ? null
      : 'Informe um valor maior que zero';
  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Ingredientes da receita',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
                child: Form(
                    key: form,
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(widget.prato,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          Text(
                              'Informe quanto esta receita rende em ${widget.unidade} (${widget.estado}) e os ingredientes usados nesse rendimento. A ficha será escalada pelo plano, sem converter estados ou unidades automaticamente.',
                              style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                              onPressed: importar,
                              icon: const Icon(Icons.content_paste_outlined),
                              label: const Text('Colar receita com medidas')),
                          const SizedBox(height: 12),
                          TextFormField(
                              controller: rendimento,
                              decoration: InputDecoration(
                                  labelText:
                                      'A receita rende (${widget.unidade})',
                                  border: const OutlineInputBorder()),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [NumericInput.decimal()],
                              validator: positivo),
                          for (final i in itens)
                            Card(
                                margin: const EdgeInsets.only(top: 12),
                                child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(children: [
                                      Row(children: [
                                        Expanded(
                                            child: TextFormField(
                                                controller: i.nome,
                                                decoration:
                                                    const InputDecoration(
                                                        labelText:
                                                            'Ingrediente'),
                                                validator: (v) =>
                                                    (v?.trim() ?? '').isEmpty
                                                        ? 'Informe o nome'
                                                        : null)),
                                        IconButton(
                                            tooltip: 'Remover ingrediente',
                                            onPressed: () => setState(() {
                                                  itens.remove(i);
                                                  removidos.add(i);
                                                }),
                                            icon: const Icon(Icons.close))
                                      ]),
                                      TextFormField(
                                          controller: i.quantidade,
                                          decoration: const InputDecoration(
                                              labelText:
                                                  'Quantidade na receita'),
                                          inputFormatters: [
                                            NumericInput.decimal()
                                          ],
                                          keyboardType: const TextInputType
                                              .numberWithOptions(decimal: true),
                                          validator: positivo),
                                      DropdownButtonFormField<String>(
                                          isExpanded: true,
                                          value: i.unidade,
                                          decoration: const InputDecoration(
                                              labelText: 'Unidade'),
                                          items: FichaTecnicaCalculadoraService
                                              .unidades
                                              .map((u) => DropdownMenuItem(
                                                  value: u, child: Text(u)))
                                              .toList(),
                                          onChanged: (v) =>
                                              setState(() => i.unidade = v!)),
                                      DropdownButtonFormField<String>(
                                          isExpanded: true,
                                          value: i.estado,
                                          decoration: const InputDecoration(
                                              labelText:
                                                  'Estado do ingrediente'),
                                          items: FichaTecnicaCalculadoraService
                                              .estados
                                              .map((u) => DropdownMenuItem(
                                                  value: u, child: Text(u)))
                                              .toList(),
                                          onChanged: (v) =>
                                              setState(() => i.estado = v!)),
                                    ]))),
                          TextButton.icon(
                              onPressed: itens.length >= 20
                                  ? null
                                  : () => setState(
                                      () => itens.add(_Ingrediente({}))),
                              icon: const Icon(Icons.add),
                              label: const Text('Adicionar ingrediente')),
                          if (widget.inicial != null)
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, <String, dynamic>{}),
                                child: const Text('Remover ficha deste item')),
                        ])))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Voltar')),
          FilledButton(
              onPressed: itens.isEmpty
                  ? null
                  : () {
                      if (!form.currentState!.validate()) return;
                      Navigator.pop(context, {
                        'versao': 1,
                        'prato': widget.prato,
                        'unidade': widget.unidade,
                        'estado': widget.estado,
                        'rendimento': NumericInput.parse(rendimento.text),
                        'ingredientes': [
                          for (final i in itens)
                            {
                              'id': i.id,
                              'nome': i.nome.text.trim(),
                              'quantidade':
                                  NumericInput.parse(i.quantidade.text),
                              'unidade': i.unidade,
                              'estado': i.estado
                            }
                        ]
                      });
                    },
              child: const Text('Usar ficha'))
        ],
      );
}
