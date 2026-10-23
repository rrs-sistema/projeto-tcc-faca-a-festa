import 'entrada_inteligente_test.dart' show EntradaRepo;
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_faca_festa/domain/entities/convidado.dart';
import 'package:app_faca_festa/domain/entities/evento.dart';
import 'package:app_faca_festa/domain/entities/cardapio.dart';
import 'package:app_faca_festa/domain/entities/contexto_planejamento_evento.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/cardapio_controller.dart';
import 'calculadora_jornada_test.dart'
    show RepoJornada, BaseJornada, CardapioQA;
import 'calculadora_composicao_test.dart' show AiQA;

class Usuario extends Fake implements User {
  @override
  String get uid => 'owner';
}

class Auth extends Fake implements FirebaseAuth {
  @override
  User get currentUser => Usuario();
}

class Fontes extends RepoJornada {
  final convidadosPendentes = <String, Completer<List<Convidado>>>{};
  final gastosVivos = StreamController<List<Map<String, dynamic>>>.broadcast();
  @override
  Future<List<Convidado>> listarConvidadosDoEvento(String id) =>
      (convidadosPendentes[id] = Completer<List<Convidado>>()).future;
  @override
  Stream<List<Map<String, dynamic>>> observarCompromissosDoEvento(String id) =>
      gastosVivos.stream;
}

class EscritaPendente extends RepoJornada {
  final resposta = Completer<Map<String, dynamic>>();
  @override
  Future<Map<String, dynamic>> alterarOperacaoEvento(
          String id, Map<String, dynamic> acao) =>
      resposta.future;
}

class Menus extends CardapioQA {
  final fontes = <String, StreamController<List<Cardapio>>>{};
  @override
  Stream<List<Cardapio>> observarCardapios(String id) =>
      (fontes[id] = StreamController<List<Cardapio>>.broadcast()).stream;
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put<FirebaseAuth>(Auth());
  });
  tearDown(() => Get.reset());
  test(
      'A tardio não altera B; financeiro falha independentemente e histórico fica isolado',
      () async {
    final repo = Fontes();
    final c = CalculadoraFestaController(
        aiService: AiQA(),
        repository: repo,
        itensBaseRepository: BaseJornada());
    addTearDown(c.onClose);
    addTearDown(repo.gastosVivos.close);
    final a = c.prepararCalculadora(
        idEvento: 'A', tipoEvento: 'Festa', baseConfirmada: true);
    final b = c.prepararCalculadora(
        idEvento: 'B', tipoEvento: 'Festa', baseConfirmada: true);
    expect(c.contextoEvento.fontes['publico']!.estado,
        EstadoFontePlanejamento.carregando);
    repo.convidadosPendentes['B']!.complete([]);
    await b;
    repo.convidadosPendentes['A']!.completeError(StateError('consulta negada'));
    await a;
    expect(c.idEventoAtual.value, 'B');
    expect(c.estadoConvidados.value, EstadoFontePlanejamento.vazia);
    c.baseCalculo.value = BaseCalculoFesta.manual;
    c.atualizarTotaisManuais(adultos: 42, criancas: 0, bebes: 0);
    c.sincronizarConvidados([]);
    expect(c.totalAdultos.value, 42);
    Evento evento(double limite) => Evento(
        idEvento: 'B',
        idUsuario: 'owner',
        idTipoEvento: 'festa',
        nomeEvento: 'Festa',
        localEvento: '',
        data: DateTime(2026),
        custoEstimado: limite);
    c.sincronizarEvento(evento(100));
    final antes = c.contextoEvento.assinatura;
    c.sincronizarEvento(evento(200));
    expect(c.orcamentoDisponivel.value, 200);
    expect(c.contextoEvento.assinatura, isNot(antes));
    expect(c.avisoContexto.value, isNotEmpty);
    final assinaturaVisual = c.contextoEvento.assinatura;
    c.sincronizarEvento(evento(200).copyWith(nomeEvento: 'Novo título'));
    expect(c.contextoEvento.assinatura, assinaturaVisual);
    repo.gastosVivos.addError(StateError('financeiro negado'));
    await Future<void>.delayed(Duration.zero);
    expect(c.contextoEvento.fontes['financeiro']!.estado,
        EstadoFontePlanejamento.erro);
    expect(c.estadoConvidados.value, EstadoFontePlanejamento.vazia);
    final novoPeriodo = evento(200).copyWith(data: DateTime(2026, 2));
    c.sincronizarEvento(novoPeriodo);
    expect(c.estadoEvento.value, EstadoFontePlanejamento.desatualizada);
    expect(c.contextoEvento.estimarQuantidades, isFalse);
    expect(c.calculoAtual.value, isNull);
    c.sincronizarEvento(novoPeriodo, aceitarPeriodo: true);
    expect(c.estadoEvento.value, EstadoFontePlanejamento.disponivel);
    c.usandoContextoHistorico.value = true;
    c.sincronizarEvento(evento(300));
    repo.gastosVivos.add([
      {'id': 'tardio'}
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(c.orcamentoDisponivel.value, 200);
    expect(c.compromissosOrcamento, isEmpty);
  });
  test(
      'gravação pendente aguarda confirmação e resposta antiga não muda nova sessão',
      () async {
    final repo = EscritaPendente();
    final c = CalculadoraFestaController(
        aiService: AiQA(),
        repository: repo,
        itensBaseRepository: BaseJornada());
    addTearDown(c.onClose);
    await c.prepararCalculadora(idEvento: 'A', tipoEvento: 'Festa');
    expect(c.contextoEvento.fontes['operacao']!.estado,
        EstadoFontePlanejamento.disponivel);
    await c.iniciarOperacaoEvento();
    await Future<void>.delayed(Duration.zero);
    final gravacao = c.alterarOperacao({'tipo': 'teste'});
    expect(c.contextoEvento.fontes['operacao']!.estado,
        EstadoFontePlanejamento.escritaPendente);
    await c.prepararCalculadora(idEvento: 'B', tipoEvento: 'Festa');
    repo.resposta.complete({'revisao': 99});
    await gravacao;
    expect(c.idEventoAtual.value, 'B');
    expect(c.operacaoEvento, isEmpty);
    expect(c.escritaContextoPendente.value, isFalse);
  });
  test('leitura inteligente antiga é rejeitada mesmo voltando ao mesmo evento',
      () async {
    final repo = EntradaRepo()..espera = Completer<Map<String, dynamic>>();
    final c = CalculadoraFestaController(
        aiService: AiQA(),
        repository: repo,
        itensBaseRepository: BaseJornada());
    addTearDown(c.onClose);
    await c.prepararCalculadora(idEvento: 'A', tipoEvento: 'Festa');
    final resposta = c.interpretarEntradaAssistente('comprei arroz');
    final rejeitada = expectLater(resposta, throwsStateError);
    await c.prepararCalculadora(idEvento: 'B', tipoEvento: 'Festa');
    await c.prepararCalculadora(idEvento: 'A', tipoEvento: 'Festa');
    repo.espera!.complete(repo.resposta);
    await rejeitada;
    expect(c.idEventoAtual.value, 'A');
    expect(repo.revisao, isNull);
  });
  test('consulta de cardápios negada não vira vazia; troca rápida descarta A',
      () async {
    final repo = Menus();
    final c = CardapioController(repository: repo);
    await c.escutarCardapios('A');
    final a = repo.fontes['A']!;
    final b = c.escutarCardapios('B');
    a.add([const Cardapio(idEvento: 'A', idCardapio: 'a', titulo: 'A')]);
    await b;
    repo.fontes['B']!.addError(StateError('negada'));
    await Future<void>.delayed(Duration.zero);
    expect(c.cardapios, isEmpty);
    expect(c.erro.value, isNotEmpty);
    await c.encerrarEscutas();
    for (final stream in repo.fontes.values) {
      await stream.close();
    }
  });
}
