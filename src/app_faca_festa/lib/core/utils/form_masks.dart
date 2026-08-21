import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Máscaras reutilizáveis para telefone, dinheiro e números.
class FormMasks {
  FormMasks._();

  /// Celular brasileiro: DDD + 9 dígitos, ex. (44) 99999-9999.
  static const mascaraCelular = '(##) #####-####';

  /// Telefone fixo: DDD + 8 dígitos, ex. (44) 3333-4444.
  static const mascaraFixo = '(##) ####-####';

  static MaskTextInputFormatter telefone({String? initialText}) {
    final local = telefoneLocal(initialText);
    return MaskTextInputFormatter(
      mask: _mascaraTelefone(local),
      filter: {'#': RegExp(r'[0-9]')},
      initialText: local,
    );
  }

  static String telefoneLocal(String? value) {
    var digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('55') &&
        (digits.length == 12 || digits.length == 13)) {
      digits = digits.substring(2);
    }
    if (digits.length > 11) {
      digits = digits.substring(digits.length - 11);
    }
    return digits;
  }

  static void atualizarTelefone(
    MaskTextInputFormatter mask,
    String value, {
    TextEditingController? controller,
  }) {
    final nova = _mascaraTelefone(value);
    if (mask.getMask() == nova) return;

    final formatado = mask.updateMask(mask: nova);
    if (controller != null && controller.text != formatado.text) {
      controller.value = formatado;
    }
  }

  static void aplicarTelefone({
    required TextEditingController controller,
    required MaskTextInputFormatter mask,
    required String value,
  }) {
    final local = telefoneLocal(value);
    mask.updateMask(mask: _mascaraTelefone(local));
    controller.value = mask.formatEditUpdate(
      const TextEditingValue(),
      TextEditingValue(text: local),
    );
  }

  static CurrencyTextInputFormatter dinheiro() {
    return CurrencyTextInputFormatter.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
      enableNegative: false,
    );
  }

  static List<TextInputFormatter> inteiro({int maxDigits = 6}) {
    return [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(maxDigits),
    ];
  }

  /// Usa máscara de celular (9 dígitos após o DDD) por padrão, para aceitar
  /// o nono dígito em todos os estados. Só troca para fixo quando o número
  /// já está completo com 8 dígitos e não é celular.
  static String _mascaraTelefone(String value) {
    final local = telefoneLocal(value);
    final ehFixoCompleto =
        local.length == 10 && local.length >= 3 && local[2] != '9';
    return ehFixoCompleto ? mascaraFixo : mascaraCelular;
  }
}
