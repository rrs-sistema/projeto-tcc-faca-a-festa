import 'package:app_faca_festa/core/utils/form_validators.dart';
import 'package:flutter_test/flutter_test.dart';

/// Garante as mensagens usadas nas evidências da apresentação.
void main() {
  test('login e recuperação de senha', () {
    expect(FormValidators.email(''), 'Informe o e-mail');
    expect(FormValidators.email('email-invalido'),
        'Digite um e-mail válido (ex: contato@email.com)');
    expect(FormValidators.email('a b@email.com'),
        'O e-mail não pode conter espaços');
    expect(FormValidators.senhaLogin(''), 'Informe a senha');
    expect(FormValidators.senhaLogin('123'),
        'A senha deve ter pelo menos 6 caracteres');
    expect(FormValidators.senha('abcdef'),
        'A senha deve conter pelo menos um número');
    expect(FormValidators.confirmarSenha('outra', senha: 'abcdef'),
        'As senhas não coincidem');
    expect(FormValidators.codigoVerificacao('12'),
        'Informe o código de verificação com 6 dígitos');
  });

  test('cadastros da festa', () {
    expect(FormValidators.titulo('', campo: 'o título do evento'),
        'Informe o título do evento');
    expect(FormValidators.data('', campo: 'a data do evento'),
        'Informe a data do evento');
    expect(FormValidators.hora('', campo: 'a hora do evento'),
        'Informe a hora do evento');
    expect(FormValidators.dinheiro('', campo: 'o custo estimado', maiorQue: 1),
        'Informe o custo estimado');
    expect(FormValidators.nomeCompleto('', campo: 'o nome do responsável'),
        'Informe o nome do responsável');
    expect(FormValidators.razaoSocial(''),
        'Informe a razão social da empresa');
    expect(FormValidators.telefone('1099999999'), 'Informe um DDD válido');
    expect(FormValidators.uf('XX'), 'Informe uma UF válida');
    expect(FormValidators.titulo('', campo: 'o nome do presente', minimo: 2),
        'Informe o nome do presente');
    expect(FormValidators.obrigatorio('', campo: 'a chave PIX'),
        'Informe a chave PIX');
    expect(
      FormValidators.descricao('ab',
          campo: 'as observações', obrigatorio: false, minimo: 3),
      'As observações deve ter pelo menos 3 caracteres',
    );
    expect(FormValidators.nomePessoa('', campo: 'o nome do convidado'),
        'Informe o nome do convidado');
    expect(FormValidators.telefone('1198888', obrigatorio: false),
        'Informe um telefone válido com DDD (10 ou 11 dígitos)');
    expect(FormValidators.titulo('', campo: 'o título', minimo: 2),
        'Informe o título');
    expect(FormValidators.titulo('', campo: 'o nome do grupo', minimo: 2),
        'Informe o nome do grupo');
    expect(FormValidators.titulo('', campo: 'o título da tarefa'),
        'Informe o título da tarefa');
  });

  test('formatos de e-mail, senha, telefone, CPF, CNPJ e CEP', () {
    expect(FormValidators.telefone('11888887777'),
        'Celular deve começar com 9 após o DDD');
    expect(FormValidators.cpf('11111111111'),
        'CPF inválido. Verifique e tente novamente.');
    expect(FormValidators.cnpj('00000000000000'),
        'CNPJ inválido. Verifique e tente novamente.');
    expect(FormValidators.cep('00000000'), 'Informe um CEP válido');
  });
}
