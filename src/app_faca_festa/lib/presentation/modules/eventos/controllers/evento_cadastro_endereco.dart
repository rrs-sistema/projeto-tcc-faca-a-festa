part of 'evento_cadastro_controller.dart';

extension EventoCadastroEndereco on EventoCadastroController {
  bool _enderecoTemAlgumCampoPreenchido(EnderecoUsuario endereco) {
    // Não considera a UF sozinha, porque o controller inicia com "PR" por padrão.
    return endereco.cep.trim().isNotEmpty ||
        endereco.logradouro.trim().isNotEmpty ||
        endereco.numero.trim().isNotEmpty ||
        (endereco.complemento?.trim().isNotEmpty ?? false) ||
        (endereco.bairro?.trim().isNotEmpty ?? false) ||
        (endereco.nomeCidade?.trim().isNotEmpty ?? false);
  }

  bool _validarCamposEndereco(EnderecoUsuario endereco) {
    _logEndereco(endereco, origem: '_validarCamposEndereco');

    // ------------------------------
    // 🔹 Endereço
    // ------------------------------
    if (endereco.cep.trim().isEmpty) {
      _log('FALHA endereço: CEP vazio.');
      _showError('Informe o CEP');
      return false;
    }
    if (endereco.logradouro.trim().isEmpty) {
      _log('FALHA endereço: logradouro vazio.');
      _showError('Informe o endereço completo');
      return false;
    }
    if (endereco.numero.trim().isEmpty) {
      _log('FALHA endereço: número vazio.');
      _showError('Informe o número do endereço');
      return false;
    }
    if (endereco.bairro == null || endereco.bairro!.trim().isEmpty) {
      _log('FALHA endereço: bairro vazio.');
      _showError('Informe o bairro');
      return false;
    }
    if (endereco.uf == null || endereco.uf!.trim().isEmpty) {
      _log('FALHA endereço: UF vazia.');
      _showError('Informe o estado (UF)');
      return false;
    }
    if (endereco.nomeCidade == null || endereco.nomeCidade!.trim().isEmpty) {
      _log('FALHA endereço: cidade vazia.');
      _showError('Informe a cidade');
      return false;
    }

    _log('Endereço validado com sucesso.');
    return true;
  }

  void _logEndereco(EnderecoUsuario endereco, {required String origem}) {
    _log(
      'Endereço [$origem]: '
      'cep="${endereco.cep}" | '
      'logradouro="${endereco.logradouro}" | '
      'numero="${endereco.numero}" | '
      'bairro="${endereco.bairro}" | '
      'cidade="${endereco.nomeCidade}" | '
      'uf="${endereco.uf}" | '
      'complemento="${endereco.complemento}"',
    );
  }
}
