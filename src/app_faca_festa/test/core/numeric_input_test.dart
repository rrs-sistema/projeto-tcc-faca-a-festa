import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/core/utils/numeric_input.dart';
import 'package:app_faca_festa/core/utils/form_masks.dart';
import 'package:app_faca_festa/core/utils/form_validators.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/pages/calculadora_limite_orcamento_dialog.dart';

TextEditingValue value(String text, [int? cursor]) => TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: cursor ?? text.length));
TextEditingValue digitar(TextEditingValue old, String text) => value(
    old.text.replaceRange(old.selection.start, old.selection.end, text),
    old.selection.start + text.length);

void main() {
  test('moeda segue a referência: 2, 23 e 3300 são centavos', () {
    final f = FormMasks.dinheiro();
    var atual = value('');
    atual = f.formatEditUpdate(atual, digitar(atual, '2'));
    expect(atual.text, 'R\$ 0,02');
    atual = f.formatEditUpdate(atual, digitar(atual, '3'));
    expect(atual.text, 'R\$ 0,23');
    expect(NumericInput.parseMoeda(atual.text), .23);
    expect(f.formatEditUpdate(value(''), value('3300')).text, 'R\$ 33,00');
  });

  test('digitação contínua passa por centavos, reais e milhares', () {
    final f = NumericInput.moeda();
    var atual = value('');
    for (final c in '12345678'.split('')) {
      atual = f.formatEditUpdate(atual, digitar(atual, c));
      expect(atual.selection.baseOffset, atual.text.length);
    }
    expect(atual.text, 'R\$ 123.456,78');
    expect(NumericInput.parseMoeda(atual.text), 123456.78);
  });

  test('apagar reduz centavos sem travar no símbolo ou nos zeros', () {
    final f = NumericInput.moeda();
    var atual = value('R\$ 33,00');
    final expected = ['R\$ 3,30', 'R\$ 0,33', 'R\$ 0,03', ''];
    for (final result in expected) {
      atual = f.formatEditUpdate(
          atual, value(atual.text.substring(0, atual.text.length - 1)));
      expect(atual.text, result);
    }
    expect(f.formatEditUpdate(value('R\$ 1,00'), value('')).text, '');
  });

  test('zero inicial e espaço inseparável legado aceitam digitação', () {
    final f = NumericInput.moeda();
    for (final inicial in ['R\$ 0,00', 'R\$\u00a00,00']) {
      var atual = value(inicial);
      atual = f.formatEditUpdate(atual, digitar(atual, '5'));
      expect(atual.text, 'R\$ 0,05');
      atual = f.formatEditUpdate(atual, digitar(atual, '0'));
      expect(atual.text, 'R\$ 0,50');
    }
  });

  test('colagem de moeda formatada e substituição total conservam o valor', () {
    final f = NumericInput.moeda();
    for (final input in ['123456', '1.234,56', 'R\$ 1.234,56', '1234.56']) {
      expect(f.formatEditUpdate(value(''), value(input)).text, 'R\$ 1.234,56');
    }
    final selecionado = const TextEditingValue(
        text: 'R\$ 50,00',
        selection: TextSelection(baseOffset: 0, extentOffset: 8));
    expect(f.formatEditUpdate(selecionado, value('23')).text, 'R\$ 0,23');
  });

  test('preço carregado e edição de dígito no meio usam a mesma máscara', () {
    final f = NumericInput.moeda();
    expect(f.formatEditUpdate(value('R\$ 33,00'), value('R\$ 33,005')).text,
        'R\$ 330,05');
    expect(
        f.formatEditUpdate(value('R\$ 33,00', 4), value('R\$ 93,00', 4)).text,
        'R\$ 93,00');
  });

  test('moeda rejeita texto inválido e valores além da precisão segura', () {
    final f = NumericInput.moeda();
    final antigo = value('R\$ 33,00');
    for (final input in [
      '-5',
      'NaN',
      'Infinity',
      '1e3',
      'abc',
      '1,,2',
      '1.2.3',
      '123456789012345'
    ]) {
      expect(f.formatEditUpdate(antigo, value(input)), antigo);
    }
  });

  test('quantidade não usa entrada em centavos nem acrescenta zeros', () {
    final f = NumericInput.decimal();
    var atual = value('');
    for (final c in '33,50'.split('')) {
      atual = f.formatEditUpdate(atual, digitar(atual, c));
    }
    expect(atual.text, '33,50');
    expect(f.formatEditUpdate(value(''), value('33')).text, '33');
    expect(f.formatEditUpdate(value(''), value('0.125')).text, '0,125');
    expect(f.formatEditUpdate(value(''), value(',5')).text, '0,5');
  });

  test('porções preservam seis casas e colagem com milhar brasileiro', () {
    final f = NumericInput.decimal();
    var atual = value('');
    for (final c in '0,000125'.split('')) {
      atual = f.formatEditUpdate(atual, digitar(atual, c));
    }
    expect(atual.text, '0,000125');
    expect(NumericInput.parse(atual.text), .000125);
    expect(f.formatEditUpdate(value(''), value('1.234,567')).text, '1234,567');
  });

  test('quantidade conserva cursor e seleção para corrigir a fração', () {
    final f = NumericInput.decimal();
    final result = f.formatEditUpdate(value('12,50', 4), value('12,30', 4));
    expect(result.text, '12,30');
    expect(result.selection.baseOffset, 4);
    const selected = TextEditingValue(
        text: '12,30',
        selection: TextSelection(baseOffset: 3, extentOffset: 5));
    expect(f.formatEditUpdate(result, selected).selection, selected.selection);
    expect(f.formatEditUpdate(result, value('')).text, '');
    for (final input in ['-1', 'NaN', '1,,2', '0,1234567']) {
      expect(f.formatEditUpdate(result, value(input)), result);
    }
  });

  test('inteiro permite somente dígitos e preserva zeros à esquerda', () {
    expect(
        NumericInput.inteiro.single
            .formatEditUpdate(value(''), value('0012abc'))
            .text,
        '0012');
  });

  test('parser distingue exibição de moeda da entrada em centavos', () {
    for (final input in ['R\$ 1.234,56', '1234,56', '1234.56']) {
      expect(NumericInput.parse(input), 1234.56);
      expect(FormValidators.parseDinheiro(input), 1234.56);
    }
    expect(FormValidators.parseDinheiro(NumericInput.dinheiro(33)), 33);
    expect(NumericInput.parse('0,000125'), .000125);
    for (final input in ['', '-1', 'NaN', '1,2,3', 'abc', '1e309']) {
      expect(NumericInput.parse(input), isNull);
    }
  });

  testWidgets('tela usa digitação em centavos e salva o número em reais',
      (tester) async {
    double? salvo;
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () async {
                      salvo = await showDialog<double>(
                          context: context,
                          builder: (_) =>
                              const CalculadoraLimiteOrcamentoDialog(
                                  valor: 8500));
                    },
                    child: const Text('Abrir'))))));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    final campo = find.byType(TextFormField);
    expect(tester.widget<TextFormField>(campo).controller!.text,
        NumericInput.dinheiro(8500));
    await tester.enterText(campo, '');
    for (final c in '3300'.split('')) {
      final controller = tester.widget<TextFormField>(campo).controller!;
      tester.testTextInput.updateEditingValue(digitar(controller.value, c));
      await tester.pump();
    }
    expect(tester.widget<TextFormField>(campo).controller!.text, 'R\$ 33,00');
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();
    expect(salvo, 33);
  });
}
