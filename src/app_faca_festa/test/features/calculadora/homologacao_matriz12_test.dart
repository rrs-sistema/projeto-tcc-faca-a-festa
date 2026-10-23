import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/domain/entities/cardapio.dart';
import 'package:app_faca_festa/domain/entities/ocorrencia_servico.dart';
import 'package:app_faca_festa/domain/entities/referencia_contextual.dart';
import 'package:app_faca_festa/domain/services/plano_evento_service.dart';
import 'plano_evento_test.dart' show calculo;

void main() {
  // As decisões de formato vêm do organizador/referência, nunca do tipo da festa.
  for (final tipo in [
    'Festa Infantil',
    'Casamento',
    'Corporativo',
    'Retiro',
    'Churrasco',
    'Serviço livre'
  ]) {
    test('QA12 $tipo: sem referência escolhida não fabrica serviço ou porção',
        () {
      final plano = const PlanoEventoService().gerar(
          calculo: calculo(pessoas: 40).copyWith(tipoEvento: tipo),
          cardapios: [],
          itensPorCardapio: {},
          regras: [],
          catalogo: CatalogoContextual([]));
      expect(plano.destinos, isEmpty);
      expect(plano.itensCalculados, 0);
      expect(plano.pendencias.join(), contains('modelo aprovado'));
    });
  }
  for (final (tipo, quantidade, dias) in [
    ('Corporativo', 3, 1),
    ('Retiro', 4, 2)
  ]) {
    test(
        'QA12 $tipo: $quantidade ocorrências em $dias dia(s), públicos por destino',
        () {
      final agenda = [
        for (var i = 0; i < quantidade; i++)
          OcorrenciaServico(
              id: 'servico_$i',
              evento: 'evento',
              modelo: 'modelo',
              cardapio: 'servico_$i',
              titulo: 'Serviço sintético $i',
              dataLocal: i < 2
                  ? '2026-10-21'
                  : (dias == 2 ? '2026-10-22' : '2026-10-21'),
              horaLocal: i.isEven ? '09:00' : '15:00',
              fuso: 'America/Sao_Paulo',
              duracaoMinutos: 30)
      ];
      for (final o in agenda) {
        o.validar(
            inicioEvento: DateTime(2026, 10, 21),
            fimEvento: DateTime(2026, 10, 20 + dias));
      }
      final plano = const PlanoEventoService().gerar(
          calculo: calculo(pessoas: 40).copyWith(tipoEvento: tipo),
          cardapios: [
            const Cardapio(
                idEvento: 'evento',
                idCardapio: 'modelo',
                titulo: 'Modelo excluído da execução',
                somenteModelo: true),
            for (final o in agenda)
              Cardapio(
                  idEvento: 'evento',
                  idCardapio: o.cardapio,
                  titulo: o.titulo,
                  escopo: EscopoCardapio.refeicao)
          ],
          itensPorCardapio: {},
          regras: [],
          catalogo: CatalogoContextual([]),
          operacao: {
            'agenda': agenda.map((o) => o.toMap()).toList(),
            'refeicoes': {
              for (var i = 0; i < agenda.length; i++)
                agenda[i].cardapio: {
                  'ocorrencia': agenda[i].toMap(),
                  'publico': {'adultos': 10 + i, 'criancas': i, 'bebes': 0}
                }
            }
          });
      expect(plano.destinos.length, quantidade);
      expect(plano.destinos.map((d) => d.cardapio.idCardapio).toSet().length,
          quantidade);
      expect(plano.destinos.map((d) => d.pessoas).toList(),
          [for (var i = 0; i < quantidade; i++) 10 + 2 * i]);
      expect(plano.itensCalculados, 0);
      expect(agenda.map((o) => o.dataLocal).toSet().length, dias);
    });
  }
}
