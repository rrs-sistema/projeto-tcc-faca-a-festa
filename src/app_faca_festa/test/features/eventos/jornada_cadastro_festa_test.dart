import 'package:app_faca_festa/domain/services/jornada_cadastro_festa.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cadastro da festa não oferece a calculadora', () {
    expect(
      JornadaCadastroFesta.mostraCalculadoraNoFormulario(festaJaSalva: false),
      isFalse,
    );
  });

  test('festa já salva pode abrir a calculadora no formulário', () {
    expect(
      JornadaCadastroFesta.mostraCalculadoraNoFormulario(festaJaSalva: true),
      isTrue,
    );
  });

  test('festa nova vai para a home, com ou sem estimativa', () {
    expect(
      JornadaCadastroFesta.depoisDeSalvar(criando: true),
      DestinoCadastroEvento.home,
    );
  });

  test('edição de uma festa já salva permanece na tela anterior', () {
    expect(
      JornadaCadastroFesta.depoisDeSalvar(criando: false),
      DestinoCadastroEvento.permanecer,
    );
  });

  test('estimativa do cadastro não mostra cardápio nem o passo de sugestões',
      () {
    expect(
      JornadaCadastroFesta.mostraCardapioNaCalculadora(
        estimativaSemEvento: true,
      ),
      isFalse,
    );
    expect(
      JornadaCadastroFesta.passosDaCalculadora(estimativaSemEvento: true),
      ['Pessoas', 'A festa', 'Estimativa'],
    );
  });

  test('calculadora da festa salva mantém cardápio e sugestões', () {
    expect(
      JornadaCadastroFesta.mostraCardapioNaCalculadora(
        estimativaSemEvento: false,
      ),
      isTrue,
    );
    expect(
      JornadaCadastroFesta.passosDaCalculadora(estimativaSemEvento: false),
      ['Pessoas', 'A festa', 'Sugestões'],
    );
  });
}
