import 'package:app_faca_festa/domain/services/evento_leitura_confirmada.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('consulta confirmada publica todos os eventos', () {
    final publicacao = EventoLeituraConfirmada.daConsulta<String>(
      escritaPendente: false,
      documentos: const [
        EventoEmTransito(valor: 'formatura', escritaPendente: false),
        EventoEmTransito(valor: 'casamento', escritaPendente: false),
      ],
    );

    expect(publicacao.omitida, isFalse);
    expect(publicacao.eventos, ['formatura', 'casamento']);
  });

  test('consulta confirmada sem eventos publica lista vazia', () {
    final publicacao = EventoLeituraConfirmada.daConsulta<String>(
      escritaPendente: false,
      documentos: const [],
    );

    expect(publicacao.omitida, isFalse);
    expect(publicacao.eventos, isEmpty);
  });

  test('escrita pendente da consulta inteira é omitida', () {
    final publicacao = EventoLeituraConfirmada.daConsulta<String>(
      escritaPendente: true,
      documentos: const [
        EventoEmTransito(valor: 'formatura', escritaPendente: true),
      ],
    );

    expect(publicacao.omitida, isTrue);
    expect(publicacao.eventos, isNull);
  });

  test('um documento pendente omite a consulta, sem lista parcial', () {
    final publicacao = EventoLeituraConfirmada.daConsulta<String>(
      escritaPendente: false,
      documentos: const [
        EventoEmTransito(valor: 'evento-antigo', escritaPendente: false),
        EventoEmTransito(valor: 'formatura-nova', escritaPendente: true),
      ],
    );

    expect(publicacao.omitida, isTrue);
    expect(publicacao.eventos, isNull);
  });

  test('sem servidor, o evento criado no aparelho aparece na lista', () async {
    final recebidas = await EventoLeituraConfirmada.listasConfirmadas(
      Stream.fromIterable(const [
        ConsultaEventos(
          escritaPendente: true,
          semServidor: true,
          documentos: [
            EventoEmTransito(valor: 'evento-antigo', escritaPendente: false),
            EventoEmTransito(valor: 'criado-offline', escritaPendente: true),
          ],
        ),
      ]),
    ).toList();

    expect(recebidas, [
      ['evento-antigo', 'criado-offline'],
    ]);
  });

  test('listasConfirmadas só emite o snapshot depois do commit', () async {
    final recebidas = await EventoLeituraConfirmada.listasConfirmadas(
      Stream.fromIterable(const [
        ConsultaEventos(
          escritaPendente: true,
          documentos: [
            EventoEmTransito(valor: 'formatura-nova', escritaPendente: true),
          ],
        ),
        ConsultaEventos(
          escritaPendente: false,
          documentos: [
            EventoEmTransito(valor: 'formatura-nova', escritaPendente: false),
          ],
        ),
        ConsultaEventos(
          escritaPendente: true,
          documentos: [
            EventoEmTransito(valor: 'formatura-nova', escritaPendente: false),
            EventoEmTransito(valor: 'edicao', escritaPendente: true),
          ],
        ),
        ConsultaEventos(
          escritaPendente: false,
          documentos: [],
        ),
      ]),
    ).toList();

    expect(recebidas, [
      ['formatura-nova'],
      <String>[],
    ]);
  });

  test('ultimo confirmado não vira nulo enquanto a escrita está pendente',
      () async {
    final recebidos = await EventoLeituraConfirmada.ultimosConfirmados(
      Stream.fromIterable(const [
        ConsultaEventos(
          escritaPendente: true,
          documentos: [
            EventoEmTransito(valor: 'formatura-nova', escritaPendente: true),
          ],
        ),
        ConsultaEventos(
          escritaPendente: false,
          documentos: [
            EventoEmTransito(valor: 'formatura-nova', escritaPendente: false),
          ],
        ),
        ConsultaEventos(
          escritaPendente: false,
          documentos: [],
        ),
      ]),
    ).toList();

    expect(recebidos, ['formatura-nova', null]);
  });
}
