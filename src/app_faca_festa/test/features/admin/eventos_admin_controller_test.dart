import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/presentation/modules/admin/controllers/eventos_admin_controller.dart';
import 'package:app_faca_festa/domain/entities/evento_admin.dart';
import 'package:app_faca_festa/domain/repositories/eventos_admin_repository.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_eventos_admin.dart';

void main() {
  late _EventosAdminRepositoryFake repository;
  late EventosAdminController controller;

  setUp(() {
    Get.testMode = true;
    repository = _EventosAdminRepositoryFake();
    controller = EventosAdminController(
      eventosAdmin: GerenciarEventosAdmin(repository),
    );
  });

  tearDown(Get.reset);

  test('loads events through the use case and keeps derived indicators',
      () async {
    repository.eventos = [
      _evento(
        id: 'evento-1',
        nome: 'Casamento Ana',
        tipoNome: 'Casamento',
        cidade: 'Maringa',
        status: 'confirmado',
        totalCotacoes: 1,
      ),
      _evento(
        id: 'evento-2',
        nome: 'Formatura Joao',
        tipoNome: 'Formatura',
        cidade: 'Londrina',
        status: 'finalizado',
      ),
    ];

    await controller.carregarEventosComTipo();

    expect(controller.eventos, hasLength(2));
    expect(controller.totalAtivos, 1);
    expect(controller.erro.value, isEmpty);
    expect(controller.carregando.value, isFalse);
  });

  test('filters events by name, type, city or organizer', () async {
    repository.eventos = [
      _evento(
        id: 'evento-1',
        nome: 'Casamento Ana',
        tipoNome: 'Casamento',
        cidade: 'Maringa',
        organizador: 'Ana Souza',
      ),
      _evento(
        id: 'evento-2',
        nome: 'Aniversario Pedro',
        tipoNome: 'Festa infantil',
        cidade: 'Curitiba',
        organizador: 'Pedro Lima',
      ),
    ];

    await controller.carregarEventosComTipo();
    controller.busca.value = 'infantil';

    expect(controller.eventosFiltrados, hasLength(1));
    expect(controller.eventosFiltrados.first.id, 'evento-2');
  });

  test('filtra fila sem cotação, follow-up e calcula conversões 30/60/90',
      () async {
    final em20 = DateTime.now().add(const Duration(days: 20));
    final em45 = DateTime.now().add(const Duration(days: 45));
    final em80 = DateTime.now().add(const Duration(days: 80));
    repository.eventos = [
      _evento(
        id: 'a',
        nome: 'Sem cotação 20d',
        status: 'planejamento',
        totalCotacoes: 0,
        totalConvidados: 40,
        cidade: 'Curitiba',
        tipoNome: 'Formatura',
        data: em20,
      ),
      _evento(
        id: 'b',
        nome: 'Com cotação 45d',
        status: 'planejamento',
        totalCotacoes: 2,
        totalConvidados: 20,
        cidade: 'Curitiba',
        tipoNome: 'Formatura',
        data: em45,
      ),
      _evento(
        id: 'c',
        nome: 'Follow-up 80d',
        status: 'planejamento',
        totalCotacoes: 0,
        eventosDoOrganizador: 2,
        cidade: 'Mandirituba',
        tipoNome: 'Corporativo',
        data: em80,
        followUp: const FollowUpComercial(marcado: true, nota: 'ligar'),
      ),
    ];

    await controller.carregarEventosComTipo();

    expect(controller.totalSemCotacao, 2);
    expect(controller.totalComCotacao, 1);
    expect(controller.taxaConversaoCotacao, closeTo(1 / 3, 0.001));
    expect(controller.quantidadeNaJanela(30), 1);
    expect(controller.conversaoNaJanela(30), 0);
    expect(controller.quantidadeNaJanela(60), 2);
    expect(controller.conversaoNaJanela(60), closeTo(0.5, 0.001));
    expect(controller.quantidadeNaJanela(90), 3);
    expect(controller.conversaoNaJanela(90), closeTo(1 / 3, 0.001));
    expect(controller.totalFollowUp, 1);

    controller.definirFiltro(FiltroComercialEvento.semCotacao);
    expect(controller.eventosFiltrados.map((e) => e.id), ['a', 'c']);

    controller.definirFiltro(FiltroComercialEvento.followUp);
    expect(controller.eventosFiltrados.map((e) => e.id), ['c']);

    final heatmap = controller.heatmapCidadeTipo;
    expect(heatmap, isNotEmpty);
    expect(
      heatmap.any((h) => h.cidade == 'Curitiba' && h.tipoNome == 'Formatura'),
      isTrue,
    );
  });

  test('marca follow-up e envia nudge via use case', () async {
    final evento = _evento(
      id: 'evento-1',
      nome: 'Formatura',
      status: 'planejamento',
      cidade: 'Curitiba',
      tipoNome: 'Formatura',
    );
    controller.eventos.assignAll([evento]);
    repository.sugestoes = [
      const FornecedorSugestaoAdmin(
        idFornecedor: 'f1',
        nomeFornecedor: 'Buffet X',
        score: 88,
        motivoPrincipal: 'Tipo e cidade',
      ),
    ];

    await controller.marcarFollowUp(evento, nota: 'Contatar amanhã');
    expect(controller.eventos.first.temFollowUp, isTrue);
    expect(repository.followUps, ['evento-1']);

    await controller.enviarNudge(evento);
    expect(controller.eventos.first.temNudge, isTrue);
    expect(repository.nudges, ['evento-1']);
    expect(controller.sugestoesPorEvento['evento-1'], hasLength(1));
  });

  test('ordena por score de lead decrescente', () async {
    repository.eventos = [
      _evento(
        id: 'fraco',
        nome: 'Fraco',
        status: 'planejamento',
        totalCotacoes: 1,
      ),
      _evento(
        id: 'forte',
        nome: 'Forte',
        status: 'planejamento',
        totalCotacoes: 0,
        totalConvidados: 60,
        cidade: 'Curitiba',
        data: DateTime.now().add(const Duration(days: 20)),
        eventosDoOrganizador: 2,
      ),
    ];

    await controller.carregarEventosComTipo();

    expect(controller.eventosFiltrados.first.id, 'forte');
    expect(
      controller.scoreDe(controller.eventosFiltrados.first),
      greaterThan(controller.scoreDe(controller.eventosFiltrados.last)),
    );
  });

  test('approves event through the use case', () async {
    final evento = _evento(id: 'evento-1', nome: 'Casamento Ana');

    await controller.acaoEvento('aprovar', evento);

    expect(repository.eventosAprovados, ['evento-1']);
  });

  test('deletes event through the use case and removes it locally', () async {
    controller.eventos.assignAll([
      _evento(id: 'evento-1', nome: 'Casamento Ana'),
      _evento(id: 'evento-2', nome: 'Formatura Joao'),
    ]);

    await controller.excluirEvento('evento-1');

    expect(repository.eventosExcluidos, ['evento-1']);
    expect(controller.eventos.map((e) => e.id), ['evento-2']);
  });

  test('stores user-facing loading error when repository fails', () async {
    repository.error = StateError('failure');

    await controller.carregarEventosComTipo();

    expect(controller.eventos, isEmpty);
    expect(controller.erro.value, startsWith('Erro ao carregar eventos:'));
    expect(controller.carregando.value, isFalse);
  });
}

EventoAdmin _evento({
  required String id,
  required String nome,
  String tipoNome = 'Casamento',
  String organizador = 'Organizador',
  String? cidade,
  String status = 'confirmado',
  int totalCotacoes = 0,
  int totalConvidados = 0,
  int eventosDoOrganizador = 1,
  DateTime? data,
  FollowUpComercial followUp = const FollowUpComercial(marcado: false),
  NudgeCotacao nudge = const NudgeCotacao(),
}) {
  return EventoAdmin(
    id: id,
    nome: nome,
    tipoNome: tipoNome,
    organizador: organizador,
    cidade: cidade,
    status: status,
    totalCotacoes: totalCotacoes,
    totalConvidados: totalConvidados,
    eventosDoOrganizador: eventosDoOrganizador,
    data: data,
    followUp: followUp,
    nudge: nudge,
  );
}

class _EventosAdminRepositoryFake implements EventosAdminRepository {
  List<EventoAdmin> eventos = [];
  final eventosAprovados = <String>[];
  final eventosExcluidos = <String>[];
  final followUps = <String>[];
  final nudges = <String>[];
  List<FornecedorSugestaoAdmin> sugestoes = const [];
  Object? error;

  @override
  Future<List<EventoAdmin>> listarEventosComTipo() async {
    final currentError = error;
    if (currentError != null) throw currentError;
    return eventos;
  }

  @override
  Future<void> aprovarEvento(String id) async {
    eventosAprovados.add(id);
  }

  @override
  Future<void> excluirEvento(String id) async {
    eventosExcluidos.add(id);
  }

  @override
  Future<List<FornecedorSugestaoAdmin>> sugerirFornecedores({
    required String idEvento,
    int limite = 5,
  }) async {
    return sugestoes.take(limite).toList();
  }

  @override
  Future<FollowUpComercial> marcarFollowUp({
    required String idEvento,
    String nota = '',
    DateTime? proximoContato,
  }) async {
    followUps.add(idEvento);
    return FollowUpComercial(
      marcado: true,
      em: DateTime.now(),
      nota: nota.isEmpty ? null : nota,
      proximoContato: proximoContato,
    );
  }

  @override
  Future<void> limparFollowUp(String idEvento) async {}

  @override
  Future<({NudgeCotacao nudge, List<FornecedorSugestaoAdmin> recomendacoes})>
      enviarNudgeOrganizador({
    required String idEvento,
    String? mensagem,
    bool gerarRecomendacoes = true,
  }) async {
    nudges.add(idEvento);
    return (
      nudge: NudgeCotacao(
        em: DateTime.now(),
        mensagem: mensagem ?? '',
        qtdFornecedores: sugestoes.length,
      ),
      recomendacoes: sugestoes,
    );
  }
}
