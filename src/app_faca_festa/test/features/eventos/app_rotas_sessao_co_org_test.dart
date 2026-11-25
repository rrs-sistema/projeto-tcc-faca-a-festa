import 'package:flutter_test/flutter_test.dart';

import 'package:app_faca_festa/presentation/modules/app/controllers/app_rotas_sessao.dart';
import 'package:app_faca_festa/presentation/modules/eventos/home_organizador_copy.dart';

void main() {
  group('AppRotasSessao e co-organização', () {
    test('/welcome não prende a revalidação da sessão', () {
      expect(AppRotasSessao.destinoEstavel('/welcome'), isFalse);
      expect(
        AppRotasSessao.usuarioJaNavegando('/welcome', temUsuario: true),
        isFalse,
      );
      expect(AppRotasSessao.destinoEstavel('/HomeEventScreen'), isTrue);
    });

    test('copy do papel de co-organizador fica disponível na home', () {
      expect(HomeOrganizadorCopy.papelCoOrganizador, 'Co-organizador');
      expect(
        HomeOrganizadorCopy.papelCoOrganizadorDica,
        contains('junto com o dono'),
      );
    });
  });
}
