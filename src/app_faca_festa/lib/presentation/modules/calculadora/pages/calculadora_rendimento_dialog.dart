import 'package:app_faca_festa/core/utils/numeric_input.dart';
import 'package:flutter/material.dart';
import 'package:app_faca_festa/domain/services/referencia_porcao_service.dart';

class CalculadoraRendimentoDialog extends StatefulWidget {
  final String unidade;
  const CalculadoraRendimentoDialog({super.key, required this.unidade});
  @override
  State<CalculadoraRendimentoDialog> createState() => _RendimentoState();
}

class _RendimentoState extends State<CalculadoraRendimentoDialog> {
  final entrada = TextEditingController(), saida = TextEditingController();
  String? erro;
  @override
  void dispose() {
    entrada.dispose();
    saida.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        insetPadding: const EdgeInsets.all(16),
        title: const Text('Rendimento medido da receita'),
        content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text(
              'Meça o mesmo alimento antes e depois do preparo. Use a mesma unidade. Não inclua molho ou outros ingredientes apenas no peso final.'),
          const SizedBox(height: 16),
          TextField(
              controller: entrada,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [NumericInput.decimal()],
              decoration: InputDecoration(
                  labelText: 'Antes do preparo (${widget.unidade})')),
          TextField(
              controller: saida,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [NumericInput.decimal()],
              decoration:
                  InputDecoration(labelText: 'Pronto (${widget.unidade})')),
          if (erro != null)
            Text(erro!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ])),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () {
                final a = NumericInput.parse(entrada.text);
                final b = NumericInput.parse(saida.text);
                try {
                  ReferenciaPorcaoService.rendimentoMedido(a ?? 0, b ?? 0);
                  Navigator.pop(context, (entrada: a!, saida: b!));
                } on ArgumentError catch (e) {
                  setState(() => erro = e.message.toString());
                }
              },
              child: const Text('Usar rendimento medido'))
        ],
      );
}
