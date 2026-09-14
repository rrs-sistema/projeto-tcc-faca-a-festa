import 'package:flutter_test/flutter_test.dart';

import 'package:app_faca_festa/data/models/endereco/endereco_usuario.dart';
import 'package:app_faca_festa/domain/entities/endereco_usuario.dart';

void main() {
  group('enderecoPrincipalOuPrimeiro', () {
    test('escolhe o marcado como principal em lista de models', () {
      final List<EnderecoUsuario> enderecos = <EnderecoUsuarioModel>[
        _model(id: 'a', principal: false),
        _model(id: 'b', principal: true),
        _model(id: 'c', principal: false),
      ];

      expect(enderecoPrincipalOuPrimeiro(enderecos).id, 'b');
    });

    test('cai no primeiro quando nenhum e principal', () {
      final List<EnderecoUsuario> enderecos = <EnderecoUsuarioModel>[
        _model(id: 'a', principal: false),
        _model(id: 'b', principal: false),
      ];

      expect(enderecoPrincipalOuPrimeiro(enderecos).id, 'a');
    });

    test('firstWhere orElse quebra com List de EnderecoUsuarioModel', () {
      final List<EnderecoUsuario> enderecos = <EnderecoUsuarioModel>[
        _model(id: 'a', principal: true),
      ];

      expect(
        () => enderecos.firstWhere(
          (endereco) => endereco.principal,
          orElse: () => enderecos.first,
        ),
        throwsA(isA<TypeError>()),
      );
    });
  });
}

EnderecoUsuarioModel _model({
  required String id,
  required bool principal,
}) =>
    EnderecoUsuarioModel(
      id: id,
      idUsuario: 'usuario-1',
      idCidade: 1,
      cep: '87000000',
      logradouro: 'Rua A',
      numero: '10',
      principal: principal,
    );
