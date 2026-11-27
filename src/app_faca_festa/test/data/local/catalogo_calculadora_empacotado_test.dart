import 'package:app_faca_festa/data/local/catalogo_calculadora_empacotado.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(CatalogoCalculadoraEmpacotado.limparParaTeste);

  test('o catálogo vai junto com o app e abre sem internet', () async {
    final itens = await CatalogoCalculadoraEmpacotado.carregar();
    expect(itens, isNotEmpty);
    expect(itens.every((i) => i.ativo), isTrue);
    final ordens = [for (final i in itens) i.ordem];
    expect(ordens, [...ordens]..sort());
  });

  test('tipo sem itens próprios usa a base "todos"', () async {
    final itens =
        await CatalogoCalculadoraEmpacotado.doTipo('tipo_que_nao_existe');
    expect(itens, isNotEmpty);
    expect(itens.every((i) => i.tipoEvento == 'todos'), isTrue);
  });

  test('perfil sem itens marcados volta aos itens do tipo', () async {
    final semPerfil = await CatalogoCalculadoraEmpacotado.doTipo('todos');
    final perfilInexistente = await CatalogoCalculadoraEmpacotado.doTipo(
        'todos',
        perfilFestaKey: 'perfil_inexistente');
    expect(perfilInexistente.length, semPerfil.length);
  });
}
