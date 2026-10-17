import 'package:app_faca_festa/core/utils/numeric_input.dart';
import 'package:flutter/material.dart';

class CalculadoraLimiteOrcamentoDialog extends StatefulWidget {
  final double? valor;
  const CalculadoraLimiteOrcamentoDialog({super.key, this.valor});

  @override
  State<CalculadoraLimiteOrcamentoDialog> createState() => _LimiteState();
}

class _LimiteState extends State<CalculadoraLimiteOrcamentoDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _campo;

  @override
  void initState() {
    super.initState();
    _campo = TextEditingController(
        text: widget.valor == null ? '' : NumericInput.dinheiro(widget.valor!));
  }

  @override
  void dispose() {
    _campo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Limite total da festa'),
        content: Form(
            key: _form,
            child: TextFormField(
                controller: _campo,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [NumericInput.moeda()],
                decoration: const InputDecoration(
                    labelText: 'Valor em R\$',
                    helperText: 'Deixe vazio para retirar o limite.'),
                validator: (texto) {
                  if (texto == null || texto.trim().isEmpty) return null;
                  final valor = NumericInput.parse(texto);
                  return valor == null || !valor.isFinite || valor <= 0
                      ? 'Informe um valor maior que zero'
                      : null;
                })),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () {
                if (_form.currentState!.validate()) {
                  Navigator.pop(
                      context, NumericInput.parse(_campo.text) ?? -1.0);
                }
              },
              child: const Text('Aplicar')),
        ],
      );
}
