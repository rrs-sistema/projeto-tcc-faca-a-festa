import 'package:flutter_test/flutter_test.dart';

import 'package:app_faca_festa/domain/entities/evento_admin.dart';
import 'package:app_faca_festa/domain/services/kit_servicos_por_tipo.dart';
import 'package:app_faca_festa/domain/services/lead_evento_score_service.dart';

void main() {
  const score = LeadEventoScoreService();
  const kit = KitServicosPorTipo();
  final agora = DateTime(2026, 11, 17);

  EventoAdmin base({
    String tipo = 'Formatura',
    String? cidade = 'Curitiba',
    DateTime? data,
    int convidados = 40,
    int cotacoes = 0,
    int eventosOrg = 1,
    double? custo,
    String status = 'planejamento',
  }) {
    return EventoAdmin(
      id: 'e1',
      nome: 'Teste',
      tipoNome: tipo,
      organizador: 'Org',
      cidade: cidade,
      data: data ?? DateTime(2026, 12, 1),
      totalConvidados: convidados,
      totalCotacoes: cotacoes,
      eventosDoOrganizador: eventosOrg,
      custoEstimado: custo,
      status: status,
    );
  }

  test('lead sem cotação com público e cidade próxima recebe prioridade alta',
      () {
    final evento = base(
      data: DateTime(2026, 12, 1),
      convidados: 55,
      cotacoes: 0,
    );
    final s = score.calcular(evento, agora: agora);
    expect(s, greaterThanOrEqualTo(70));
    expect(score.faixaPrioridade(s), 'Alta');
  });

  test('evento sem sinais relevantes fica com score baixo', () {
    final evento = EventoAdmin(
      id: 'e2',
      nome: 'Vazio',
      tipoNome: 'Tipo não informado',
      organizador: '-',
      status: 'planejamento',
    );
    final s = score.calcular(evento, agora: agora);
    expect(s, lessThan(45));
    expect(score.faixaPrioridade(s), 'Baixa');
  });

  test('organizador recorrente aumenta o score', () {
    final unico = score.calcular(base(eventosOrg: 1), agora: agora);
    final recorrente = score.calcular(base(eventosOrg: 3), agora: agora);
    expect(recorrente, greaterThan(unico));
  });

  test('kit de serviços varia por tipo', () {
    expect(kit.sugerir('Corporativo'), contains('Buffet / coffee break'));
    expect(kit.sugerir('Formatura'), contains('Fotografia e vídeo'));
    expect(kit.sugerir('15 anos'), contains('Decoração temática'));
  });
}
