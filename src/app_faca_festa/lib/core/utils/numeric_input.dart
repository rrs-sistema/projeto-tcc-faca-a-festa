import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/services.dart';

/// Moeda segue a entrada em centavos do cadastro rápido de referência.
/// Quantidades mantêm até seis casas para não arredondar porções e rendimentos.
class NumericInput {
  NumericInput._();

  static TextInputFormatter decimal({int casas = 6}) =>
      _DecimalFormatter(casas: casas);
  static TextInputFormatter moeda() => _CurrencyFormatter();
  static List<TextInputFormatter> get inteiro =>
      [FilteringTextInputFormatter.digitsOnly];

  static final RegExp _espacos = RegExp(r'[\s\u00A0\u202F\u2007\u2009\uFEFF]');

  /// Tira símbolo e espaços (inclusive o espaço inseparável do `NumberFormat`).
  static String limpar(String? value) =>
      (value ?? '').replaceAll('R\$', '').replaceAll(_espacos, '');

  static double? parse(String? value) {
    var text = limpar(value);
    if (text.isEmpty) return null;
    if ((value ?? '').contains('R\$') &&
        !text.contains(',') &&
        RegExp(r'^\d{1,3}(?:\.\d{3})+$').hasMatch(text)) {
      text = text.replaceAll('.', '');
    }
    if (text.contains(',')) {
      if (!RegExp(r'^\d+(?:\.\d{3})*,\d*$').hasMatch(text) &&
          !RegExp(r'^\d*,\d+$').hasMatch(text)) {
        return null;
      }
      text = text.replaceAll('.', '').replaceAll(',', '.');
    }
    if (!RegExp(r'^\d+(?:\.\d*)?$').hasMatch(text) &&
        !RegExp(r'^\.\d+$').hasMatch(text)) {
      return null;
    }
    final result = double.tryParse(text);
    return result != null && result.isFinite ? result : null;
  }

  static double? parseMoeda(String? value) {
    final text = (value ?? '').trim();
    if (RegExp(r'^\d{1,3}(?:\.\d{3})+$').hasMatch(text)) {
      return parse('R\$ $text');
    }
    return parse(value);
  }

  static String dinheiro(num value) {
    final parts = value.toStringAsFixed(2).split('.');
    final whole = parts.first
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
    return 'R\$ $whole,${parts.last}';
  }

  static String quantidade(num value) => value.toString().replaceAll('.', ',');
}

/// O pacote cuida da máscara e do deslocamento de centavos. Este adaptador
/// apenas trata o símbolo/espaços dos valores já carregados e entradas inválidas.
class _CurrencyFormatter extends TextInputFormatter {
  final _delegate = CurrencyTextInputFormatter.currency(
      locale: 'pt_BR', symbol: '', decimalDigits: 2, enableNegative: false);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (!newValue.composing.isCollapsed) return newValue;
    final raw = NumericInput.limpar(newValue.text);
    if (raw.isEmpty) return const TextEditingValue();
    if (!RegExp(r'^[\d.,]+$').hasMatch(raw)) return oldValue;
    if (!RegExp(r'^\d+(?:[.,]\d*)?$').hasMatch(raw) &&
        !RegExp(r'^\d{1,3}(?:\.\d{3})+(?:,\d*)?$').hasMatch(raw)) {
      return oldValue;
    }
    final digits =
        raw.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^0+'), '');
    if (digits.length > 14) return oldValue;
    if (RegExp(r'^0+$').hasMatch(raw.replaceAll(RegExp(r'\D'), ''))) {
      if (oldValue.selection.isCollapsed &&
          oldValue.text.isNotEmpty &&
          newValue.text ==
              oldValue.text.substring(0, oldValue.text.length - 1)) {
        return const TextEditingValue();
      }
      const text = 'R\$ 0,00';
      return const TextEditingValue(
          text: text, selection: TextSelection.collapsed(offset: text.length));
    }
    // O pacote rejeita espaços, inclusive os do prefixo de um valor existente.
    final previous = NumericInput.limpar(oldValue.text);
    final result = _delegate.formatEditUpdate(
        TextEditingValue(
            text: previous,
            selection: TextSelection.collapsed(offset: previous.length)),
        TextEditingValue(
            text: raw, selection: TextSelection.collapsed(offset: raw.length)));
    if (result.text.isEmpty) return const TextEditingValue();
    final text = 'R\$ ${NumericInput.limpar(result.text)}';
    return TextEditingValue(
        text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

/// Quantidades são decimais naturais, não valores em centavos. Não acrescenta
/// zeros nem move o cursor entre inteiros e frações enquanto o usuário digita.
class _DecimalFormatter extends TextInputFormatter {
  final int casas;
  _DecimalFormatter({required this.casas});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (!newValue.composing.isCollapsed) return newValue;
    final raw = newValue.text.trim();
    if (raw.isEmpty) return const TextEditingValue();
    if (!RegExp(r'^[\d.,]+$').hasMatch(raw)) return oldValue;
    var text = raw;
    final grouped = text.contains(',');
    if (grouped) {
      if (!RegExp(r'^\d*(?:\.\d{3})*,\d*$').hasMatch(text)) return oldValue;
      text = text.replaceAll('.', '');
    } else {
      text = text.replaceAll('.', ',');
    }
    if (!RegExp('^\\d*(?:,\\d{0,$casas})?\$').hasMatch(text)) return oldValue;
    if (text.startsWith(',')) text = '0$text';
    if (text.split(',').first.length > 12) return oldValue;
    int offset(int position) {
      if (position < 0) return text.length;
      final before =
          newValue.text.substring(0, position.clamp(0, newValue.text.length));
      final removed = grouped ? '.'.allMatches(before).length : 0;
      final added = raw.startsWith(',') || raw.startsWith('.') ? 1 : 0;
      return (position - removed + added).clamp(0, text.length);
    }

    return TextEditingValue(
        text: text,
        selection: TextSelection(
            baseOffset: offset(newValue.selection.baseOffset),
            extentOffset: offset(newValue.selection.extentOffset)));
  }
}
