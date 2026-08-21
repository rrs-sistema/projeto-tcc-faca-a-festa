import 'package:br_validators/br_validators.dart';
import 'package:email_validator/email_validator.dart';
import 'package:intl/intl.dart';

/// Validações de formulário reutilizáveis, com mensagens específicas por campo.
class FormValidators {
  FormValidators._();

  static const Set<String> ufsBrasil = {
    'AC',
    'AL',
    'AP',
    'AM',
    'BA',
    'CE',
    'DF',
    'ES',
    'GO',
    'MA',
    'MT',
    'MS',
    'MG',
    'PA',
    'PB',
    'PR',
    'PE',
    'PI',
    'RJ',
    'RN',
    'RS',
    'RO',
    'RR',
    'SC',
    'SP',
    'SE',
    'TO',
  };

  static String somenteDigitos(String? value) =>
      (value ?? '').replaceAll(RegExp(r'\D'), '');

  static String? obrigatorio(String? value, {required String campo}) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe $campo';
    }
    return null;
  }

  static String? nomeCompleto(
    String? value, {
    String campo = 'o nome completo (nome e sobrenome)',
    bool obrigatorio = true,
  }) {
    final texto = value?.trim() ?? '';
    if (texto.isEmpty) {
      return obrigatorio ? 'Informe $campo' : null;
    }

    final partes = texto
        .split(RegExp(r'\s+'))
        .where((parte) => parte.isNotEmpty)
        .toList();

    if (partes.length < 2) {
      return 'Informe nome e sobrenome';
    }

    final nomeValido = RegExp(r"^[A-Za-zÀ-ÿ'’.\-]+$");
    for (final parte in partes) {
      if (parte.length < 2) {
        return 'Cada parte do nome deve ter pelo menos 2 letras';
      }
      if (!nomeValido.hasMatch(parte)) {
        return 'Use apenas letras no nome (sem números ou símbolos)';
      }
    }

    if (texto.length > 80) {
      return 'O nome deve ter no máximo 80 caracteres';
    }

    return null;
  }

  static String? razaoSocial(String? value, {bool obrigatorio = true}) {
    final texto = value?.trim() ?? '';
    if (texto.isEmpty) {
      return obrigatorio ? 'Informe a razão social da empresa' : null;
    }
    if (texto.length < 3) {
      return 'A razão social deve ter pelo menos 3 caracteres';
    }
    if (texto.length > 120) {
      return 'A razão social deve ter no máximo 120 caracteres';
    }
    return null;
  }

  static String? email(String? value, {bool obrigatorio = true}) {
    final texto = value?.trim() ?? '';
    if (texto.isEmpty) {
      return obrigatorio ? 'Informe o e-mail' : null;
    }
    if (texto.contains(' ')) {
      return 'O e-mail não pode conter espaços';
    }
    if (!texto.contains('@') || !texto.contains('.')) {
      return 'Digite um e-mail válido (ex: contato@email.com)';
    }
    if (!EmailValidator.validate(texto)) {
      return 'Digite um e-mail válido (ex: contato@email.com)';
    }
    return null;
  }

  static String? senha(String? value, {bool obrigatorio = true}) {
    final texto = value ?? '';
    if (texto.isEmpty) {
      return obrigatorio ? 'Informe a senha' : null;
    }
    if (texto.contains(' ')) {
      return 'A senha não pode conter espaços';
    }
    if (texto.length < 6) {
      return 'A senha deve ter pelo menos 6 caracteres';
    }
    if (texto.length > 72) {
      return 'A senha deve ter no máximo 72 caracteres';
    }
    if (!RegExp(r'[A-Za-zÀ-ÿ]').hasMatch(texto)) {
      return 'A senha deve conter pelo menos uma letra';
    }
    if (!RegExp(r'\d').hasMatch(texto)) {
      return 'A senha deve conter pelo menos um número';
    }
    return null;
  }

  static String? cpf(String? value, {bool obrigatorio = true}) {
    final texto = value?.trim() ?? '';
    final digitos = somenteDigitos(texto);
    if (digitos.isEmpty) {
      return obrigatorio ? 'Informe o CPF' : null;
    }
    if (digitos.length != 11) {
      return 'Informe um CPF com 11 dígitos';
    }
    if (!_digitosVariados(digitos) || !BRValidators.validateCPF(digitos)) {
      return 'CPF inválido. Verifique e tente novamente.';
    }
    return null;
  }

  static String? cnpj(String? value, {bool obrigatorio = true}) {
    final texto = value?.trim() ?? '';
    final digitos = somenteDigitos(texto);
    if (digitos.isEmpty) {
      return obrigatorio ? 'Informe o CNPJ da empresa' : null;
    }
    if (digitos.length != 14) {
      return 'Informe um CNPJ com 14 dígitos';
    }
    if (!_digitosVariados(digitos) || !BRValidators.validateCNPJ(digitos)) {
      return 'CNPJ inválido. Verifique e tente novamente.';
    }
    return null;
  }

  static String? cpfOuCnpj(String? value, {bool obrigatorio = true}) {
    final digitos = somenteDigitos(value);
    if (digitos.isEmpty) {
      return obrigatorio ? 'Informe o CPF ou CNPJ' : null;
    }
    if (digitos.length <= 11) {
      return cpf(value, obrigatorio: obrigatorio);
    }
    return cnpj(value, obrigatorio: obrigatorio);
  }

  static String? telefone(String? value, {bool obrigatorio = true}) {
    final digitos = somenteDigitos(value);
    if (digitos.isEmpty) {
      return obrigatorio ? 'Informe o telefone com DDD' : null;
    }
    if (digitos.length < 10 || digitos.length > 11) {
      return 'Informe um telefone válido com DDD (10 ou 11 dígitos)';
    }

    final ddd = int.tryParse(digitos.substring(0, 2)) ?? 0;
    if (ddd < 11) {
      return 'Informe um DDD válido';
    }

    if (digitos.length == 11 && digitos[2] != '9') {
      return 'Celular deve começar com 9 após o DDD';
    }

    if (!_digitosVariados(digitos.substring(2))) {
      return 'Informe um telefone válido';
    }

    return null;
  }

  static String? cep(String? value, {bool obrigatorio = true}) {
    final digitos = somenteDigitos(value);
    if (digitos.isEmpty) {
      return obrigatorio ? 'Informe o CEP' : null;
    }
    if (digitos.length != 8) {
      return 'Informe um CEP válido com 8 dígitos';
    }
    if (!_digitosVariados(digitos)) {
      return 'Informe um CEP válido';
    }
    return null;
  }

  static String? logradouro(String? value, {bool obrigatorio = true}) {
    final texto = value?.trim() ?? '';
    if (texto.isEmpty) {
      return obrigatorio ? 'Informe o logradouro' : null;
    }
    if (texto.length < 3) {
      return 'O logradouro deve ter pelo menos 3 caracteres';
    }
    return null;
  }

  static String? numeroEndereco(String? value, {bool obrigatorio = true}) {
    final texto = value?.trim() ?? '';
    if (texto.isEmpty) {
      return obrigatorio ? 'Informe o número (ou S/N)' : null;
    }
    return null;
  }

  static String? bairro(String? value, {bool obrigatorio = true}) {
    final texto = value?.trim() ?? '';
    if (texto.isEmpty) {
      return obrigatorio ? 'Informe o bairro' : null;
    }
    if (texto.length < 2) {
      return 'Informe um bairro válido';
    }
    return null;
  }

  static String? cidade(String? value, {bool obrigatorio = true}) {
    final texto = value?.trim() ?? '';
    if (texto.isEmpty) {
      return obrigatorio ? 'Informe a cidade' : null;
    }
    if (texto.length < 2) {
      return 'Informe uma cidade válida';
    }
    if (!RegExp(r"^[A-Za-zÀ-ÿ'’.\-\s]+$").hasMatch(texto)) {
      return 'Use apenas letras no nome da cidade';
    }
    return null;
  }

  static String? uf(String? value, {bool obrigatorio = true}) {
    final texto = (value ?? '').trim().toUpperCase();
    if (texto.isEmpty) {
      return obrigatorio ? 'Informe a UF' : null;
    }
    if (texto.length != 2) {
      return 'A UF deve ter 2 letras';
    }
    if (!ufsBrasil.contains(texto)) {
      return 'Informe uma UF válida';
    }
    return null;
  }

  static String? descricaoServicos(String? value, {bool obrigatorio = false}) {
    final texto = value?.trim() ?? '';
    if (texto.isEmpty) {
      return obrigatorio ? 'Informe a descrição dos serviços' : null;
    }
    if (texto.length < 10) {
      return 'Descreva os serviços com pelo menos 10 caracteres';
    }
    return null;
  }

  static String? nomePessoa(
    String? value, {
    String campo = 'o nome',
    bool obrigatorio = true,
  }) {
    final texto = value?.trim() ?? '';
    if (texto.isEmpty) {
      return obrigatorio ? 'Informe $campo' : null;
    }
    if (texto.length < 2) {
      return 'Informe um nome com pelo menos 2 letras';
    }
    if (!RegExp(r"^[A-Za-zÀ-ÿ'’.\-\s]+$").hasMatch(texto)) {
      return 'Use apenas letras no nome';
    }
    if (texto.length > 80) {
      return 'O nome deve ter no máximo 80 caracteres';
    }
    return null;
  }

  static String? titulo(
    String? value, {
    String campo = 'o título',
    int minimo = 3,
    int maximo = 80,
  }) {
    final texto = value?.trim() ?? '';
    if (texto.isEmpty) {
      return 'Informe $campo';
    }
    if (texto.length < minimo) {
      return '${_capitalizar(campo)} deve ter pelo menos $minimo caracteres';
    }
    if (texto.length > maximo) {
      return '${_capitalizar(campo)} deve ter no máximo $maximo caracteres';
    }
    return null;
  }

  static String? descricao(
    String? value, {
    String campo = 'a descrição',
    bool obrigatorio = false,
    int minimo = 5,
    int maximo = 500,
  }) {
    final texto = value?.trim() ?? '';
    if (texto.isEmpty) {
      return obrigatorio ? 'Informe $campo' : null;
    }
    if (texto.length < minimo) {
      return '${_capitalizar(campo)} deve ter pelo menos $minimo caracteres';
    }
    if (texto.length > maximo) {
      return '${_capitalizar(campo)} deve ter no máximo $maximo caracteres';
    }
    return null;
  }

  static String? data(
    String? value, {
    String campo = 'a data',
    bool obrigatorio = true,
  }) {
    final texto = value?.trim() ?? '';
    if (texto.isEmpty) {
      return obrigatorio ? 'Informe $campo' : null;
    }
    try {
      final parsed = DateFormat('dd/MM/yyyy', 'pt_BR').parseStrict(texto);
      if (parsed.year < 2000 || parsed.year > 2100) {
        return 'Informe uma data válida';
      }
    } catch (_) {
      return 'Informe $campo no formato dd/MM/aaaa';
    }
    return null;
  }

  static String? hora(
    String? value, {
    String campo = 'a hora',
    bool obrigatorio = true,
  }) {
    final texto = value?.trim() ?? '';
    if (texto.isEmpty) {
      return obrigatorio ? 'Informe $campo' : null;
    }
    final match = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').firstMatch(texto);
    if (match == null) {
      return 'Informe $campo no formato HH:mm';
    }
    return null;
  }

  static double parseDinheiro(String? value) {
    final texto = (value ?? '')
        .replaceAll('R\$', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim();
    return double.tryParse(texto) ?? 0.0;
  }

  static String? dinheiro(
    String? value, {
    bool obrigatorio = true,
    double maiorQue = 0,
    String campo = 'o valor',
  }) {
    final texto = value?.trim() ?? '';
    final vazio = texto.isEmpty ||
        texto.replaceAll(RegExp(r'[\sR\$]'), '') == '0,00' ||
        texto.replaceAll(RegExp(r'[\sR\$]'), '') == '0.00';
    if (vazio) {
      return obrigatorio ? 'Informe $campo' : null;
    }
    final valor = parseDinheiro(texto);
    if (valor <= maiorQue) {
      final minimo = maiorQue.toStringAsFixed(2).replaceAll('.', ',');
      return '${_capitalizar(campo)} deve ser maior que R\$ $minimo';
    }
    return null;
  }

  static String? inteiroNaoNegativo(
    String? value, {
    String campo = 'a quantidade',
    bool obrigatorio = false,
    int maximo = 9999,
  }) {
    final texto = value?.trim() ?? '';
    if (texto.isEmpty) {
      return obrigatorio ? 'Informe $campo' : null;
    }
    final numero = int.tryParse(somenteDigitos(texto));
    if (numero == null) {
      return 'Informe $campo com números';
    }
    if (numero < 0) {
      return '${_capitalizar(campo)} não pode ser negativo';
    }
    if (numero > maximo) {
      return '${_capitalizar(campo)} deve ser no máximo $maximo';
    }
    return null;
  }

  static String? idade(
    String? value, {
    bool obrigatorio = false,
    int maximo = 120,
  }) {
    return inteiroNaoNegativo(
      value,
      campo: 'a idade',
      obrigatorio: obrigatorio,
      maximo: maximo,
    );
  }

  static String _capitalizar(String texto) {
    if (texto.isEmpty) return texto;
    return '${texto[0].toUpperCase()}${texto.substring(1)}';
  }

  static bool _digitosVariados(String digitos) {
    if (digitos.isEmpty) return false;
    return digitos.split('').toSet().length > 1;
  }
}
