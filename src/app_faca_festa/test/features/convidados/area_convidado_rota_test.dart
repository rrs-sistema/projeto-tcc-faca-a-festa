import 'package:flutter_test/flutter_test.dart';

import 'package:app_faca_festa/app/routes/app_route_args.dart';
import 'package:app_faca_festa/app/routes/area_convidado_rota.dart';
import 'package:app_faca_festa/domain/entities/convidado.dart';
import 'package:app_faca_festa/domain/entities/evento.dart';

void main() {
  final convidado = Convidado(
    idConvidado: 'c1',
    idEvento: 'e1',
    nome: 'Silvio',
    contato: '44999999999',
    dataCadastro: DateTime(2026, 9, 18),
    dataAtualizacao: DateTime(2026, 9, 18),
  );
  final evento = Evento(
    idEvento: 'e1',
    idTipoEvento: 't1',
    idUsuario: 'u1',
    nomeEvento: '15 anos da Kamilly',
    localEvento: 'Salão',
    data: DateTime(2026, 10, 10),
  );

  setUp(() => AreaConvidadoArgs.limpar());

  test('abre a área quando os argumentos da rota existem', () {
    expect(
      AreaConvidadoRota.resolver(
        arguments: AreaConvidadoArgs(convidado: convidado, evento: evento),
      ),
      AreaConvidadoDestino.area,
    );
  });

  test('abre a área pelos controllers se o GetX perder os argumentos', () {
    expect(
      AreaConvidadoRota.resolver(
        convidadoAtual: convidado,
        eventoAtual: evento,
      ),
      AreaConvidadoDestino.area,
    );
  });

  test('abre a área pela sessão em memória', () {
    AreaConvidadoArgs.guardar(
      AreaConvidadoArgs(convidado: convidado, evento: evento),
    );
    expect(
      AreaConvidadoRota.resolver(),
      AreaConvidadoDestino.area,
    );
  });

  test('reabre o convite quando só resta o token', () {
    expect(
      AreaConvidadoRota.resolver(token: 'cf89bbba-55fc-4db8-ae67-adc1ffda4f82'),
      AreaConvidadoDestino.reabrirConvite,
    );
  });

  test('não derruba a rota com tela cinza quando falta tudo', () {
    expect(
      AreaConvidadoRota.resolver(),
      AreaConvidadoDestino.naoEncontrado,
    );
  });
}
