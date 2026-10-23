import 'package:app_faca_festa/data/datasources/remote/calculadora_festa_remote_datasource.dart';
import 'calculadora_criacao_inicial_test.dart' show BancoTx;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_faca_festa/domain/services/memoria_calculadora_service.dart';
import 'package:app_faca_festa/domain/services/operacao_calculadora_service.dart';
import 'package:app_faca_festa/domain/services/comando_texto_calculadora_service.dart';
import 'package:app_faca_festa/domain/services/importacao_receita_texto_service.dart';
import 'package:app_faca_festa/domain/services/avaliacao_autonomia_calculadora_service.dart';
import 'package:app_faca_festa/domain/repositories/memoria_calculadora_repository.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa.dart';
import 'package:app_faca_festa/domain/entities/estimativa_financeira.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import 'calculadora_criacao_jornada_test.dart' show AuthOwner;
import 'calculadora_jornada_test.dart' show RepoJornada, BaseJornada;
import 'calculadora_composicao_test.dart' show AiQA;
import 'plano_execucao_test.dart' show regraExec, itemExec;

class RepoMemoria extends RepoJornada implements MemoriaCalculadoraRepository {
  List<Map<String, dynamic>> memoria = [];
  @override
  Future<List<Map<String, dynamic>>> lerMemoriaCalculadora() async => memoria;
  @override
  Future<void> gravarMemoriaCalculadora(List<Map<String, dynamic>> receitas,
      {required List<Map<String, dynamic>> anteriores}) async {
    memoria = receitas;
  }
}

ItemEstimativaFinanceira receita() =>
    regraExec('almoco').copyWith(valorUnitarioMedio: 99, premissas: {
      ...regraExec('almoco').premissas,
      'receita': 'Arroz da família',
      'estado': 'cru',
      'papel_na_refeicao': 'acompanhamento'
    });

void main() {
  const memoria = MemoriaCalculadoraService();
  String contexto(
          {String tipo = 'Aniversário',
          int duracao = 4,
          List<String> itens = const ['Arroz']}) =>
      memoria.contexto(
          tipo: tipo, refeicao: 'Almoço', duracao: duracao, itens: itens);
  setUp(() {
    Get.testMode = true;
    Get.put<FirebaseAuth>(AuthOwner());
  });
  tearDown(() => Get.reset());

  test('memória guarda preferência explícita e remove preço e vínculos', () {
    final m = memoria.guardar(
        receita().copyWith(premissas: {
          ...receita().premissas,
          'eventos_observados': 3,
          'eventos_origem': ['evento_antigo']
        }),
        contexto());
    final r = memoria.recuperar(m,
        contexto: contexto(),
        nome: 'Arroz',
        id: 'novo',
        cardapio: 'novo_menu',
        item: 'novo_item',
        publico: 'todos',
        unidade: 'kg')!;
    expect(r.valorUnitarioMedio, 0);
    expect(r.premissas['id_cardapio'], 'novo_menu');
    expect(r.premissas['id_item_cardapio'], 'novo_item');
    expect(r.premissas['origem'], 'preferencia_privada');
    expect(r.quantidadePorConvidadoEquivalente,
        receita().quantidadePorConvidadoEquivalente);
    expect((m['regra'] as Map)['premissas'], isNot(contains('id_cardapio')));
    expect((m['regra'] as Map)['premissas'],
        isNot(contains('eventos_observados')));
    expect((m['regra'] as Map)['premissas'], isNot(contains('eventos_origem')));
  });
  test('memória não atravessa composição, duração, tipo ou unidade', () {
    final m = memoria.guardar(receita(), contexto());
    for (final c in [
      contexto(tipo: 'Casamento'),
      contexto(duracao: 8),
      contexto(itens: ['Arroz', 'Carne'])
    ]) {
      expect(
          memoria.recuperar(m,
              contexto: c,
              nome: 'Arroz',
              id: 'x',
              cardapio: 'm',
              item: 'i',
              publico: 'todos',
              unidade: 'kg'),
          isNull);
    }
    expect(
        memoria.recuperar(m,
            contexto: contexto(),
            nome: 'Arroz',
            id: 'x',
            cardapio: 'm',
            item: 'i',
            publico: 'todos',
            unidade: 'L'),
        isNull);
  });
  test(
      'receita não revisada ou com grupos/divisão não vira preferência automática',
      () {
    for (final extra in [
      {'revisada_pelo_organizador': false},
      {'dividir_grupo': true},
      {
        'publico_refeicao': {'adultos': 2}
      },
      {'estado': 'não informado'}
    ]) {
      expect(
          () => memoria.guardar(
              receita().copyWith(premissas: {...receita().premissas, ...extra}),
              contexto()),
          throwsStateError);
    }
  });
  test(
      'gravação da memória compara conteúdo sem depender da ordem das chaves ou representação numérica',
      () async {
    final banco = BancoTx();
    banco.dados['calculadora_preferencias/owner'] = {
      'versao': 1,
      'receitas': [
        {
          'nome': 'arroz',
          'regra': {'b': 2, 'a': 1}
        }
      ]
    };
    final remote =
        CalculadoraFestaRemoteDatasource(firestore: banco, auth: AuthOwner());
    final anteriores = <Map<String, dynamic>>[
      {
        'regra': {'a': 1.0, 'b': 2.0},
        'nome': 'arroz'
      }
    ];
    await remote.gravarMemoriaCalculadora([], anteriores: anteriores);
    expect(banco.dados['calculadora_preferencias/owner']!['receitas'], isEmpty);
    await expectLater(
        remote.gravarMemoriaCalculadora(anteriores, anteriores: anteriores),
        throwsStateError);
    expect(banco.dados['calculadora_preferencias/owner']!['receitas'], isEmpty);
  });
  test('memória distingue tipo de serviço e escopo', () {
    final a = memoria.contexto(
        tipo: 'Aniversário',
        refeicao: 'Almoço',
        duracao: 4,
        itens: ['Arroz'],
        escopo: 'refeicao',
        servico: 'refeicao');
    final b = memoria.contexto(
        tipo: 'Aniversário',
        refeicao: 'Almoço',
        duracao: 4,
        itens: ['Arroz'],
        escopo: 'refeicao',
        servico: 'lanche');
    final c = memoria.contexto(
        tipo: 'Aniversário',
        refeicao: 'Almoço',
        duracao: 4,
        itens: ['Arroz'],
        escopo: 'compartilhado',
        servico: 'refeicao');
    expect(a, isNot(b));
    expect(a, isNot(c));
  });
  test('contexto é insensível à ordem dos alimentos e distingue composições',
      () {
    expect(contexto(itens: ['Arroz', 'Feijão']),
        contexto(itens: ['Feijão', 'Arroz']));
    expect(contexto(itens: ['Arroz']),
        isNot(contexto(itens: ['Arroz', 'Feijão'])));
  });
  test(
      'controller reutiliza preferência, preserva ajuste atual e permite esquecer',
      () async {
    final repo = RepoMemoria();
    final c = CalculadoraFestaController(
        repository: repo,
        itensBaseRepository: BaseJornada(),
        aiService: AiQA());
    addTearDown(c.onClose);
    await c.prepararCalculadora(
        idEvento: 'evento',
        tipoEvento: 'Aniversário',
        base: BaseCalculoFesta.manual,
        adultosManuais: 20);
    c.atualizarCardapio([itemExec('almoco')],
        titulo: 'Almoço', disponivel: true);
    c.regrasManuais.assignAll([receita()]);
    await c.guardarPreferencia(receita());
    c.regrasManuais.clear();
    expect(c.regrasDaMemoria.single.premissas['origem'], 'preferencia_privada');
    c.regrasManuais
        .add(receita().copyWith(quantidadePorConvidadoEquivalente: .2));
    expect(
        c.regrasDisponiveis
            .firstWhere((r) => r.id == receita().id)
            .quantidadePorConvidadoEquivalente,
        .2);
    c.regrasManuais.clear();
    c.atualizarDuracao(8);
    expect(c.regrasDaMemoria, isEmpty);
    await c.esquecerPreferencias();
    expect(repo.memoria, isEmpty);
  });
  test(
      'revisão qualitativa persiste conclusão e reabertura sem inventar medidas',
      () {
    const service = OperacaoCalculadoraService();
    final r = service.aplicar({}, {
      'tipo': 'revisao_pos_evento',
      'revisao': 0,
      'id_cardapio': 'almoco',
      'itens': {'arroz': 'sobrou'},
      'concluir': true
    });
    expect(r['revisao_pos_evento']['almoco']['status'], 'concluida');
    expect(r['revisao_pos_evento']['almoco']['natureza'], 'qualitativa');
    expect(r.containsKey('consumo'), false);
    final editado = service.aplicar(r, {
      'tipo': 'revisao_pos_evento',
      'revisao': 1,
      'id_cardapio': 'almoco',
      'itens': {'arroz': 'nao_sei'},
      'concluir': false
    });
    expect(editado['revisao_pos_evento']['almoco']['status'], 'em_revisao');
    expect(
        () => service.aplicar(r, {'tipo': 'revisao_pos_evento', 'revisao': 0}),
        throwsStateError);
  });
  test('revisão rejeita conclusão vazia e resultado desconhecido', () {
    for (final itens in [
      {},
      {'x': 'consumiu 20 kg'}
    ]) {
      expect(
          () => const OperacaoCalculadoraService().aplicar({}, {
                'tipo': 'revisao_pos_evento',
                'revisao': 0,
                'id_cardapio': 'm',
                'itens': itens,
                'concluir': true
              }),
          throwsA(anything));
    }
  });
  test('texto interpreta conjunto e preserva necessidade de revisão', () {
    final commands = const ComandoTextoCalculadoraService().interpretar(
        'Planeje para 30 adultos e 8 crianças; duração de 6 horas; perfil padrão');
    expect(commands.map((c) => c.tipo), ['publico', 'duracao', 'perfil']);
    expect(commands.first.valores['criancas'], 8);
    expect(
        const ComandoTextoCalculadoraService()
            .interpretar('usar convidados não recusados')
            .single
            .tipo,
        'base');
  });
  test(
      'texto recusa ação desconhecida, ambiguidade, excesso e comandos financeiros',
      () {
    for (final texto in [
      'planeje para -30 adultos',
      'planeje para +30 adultos',
      'duração 0 horas',
      'perfil luxo',
      'comprar 10 kg',
      'pague o fornecedor',
      'perfil padrão; perfil premium',
      'planeje para 20 adultos; usar confirmados',
      'planeje para 20 adultos; e tudo mais'
    ]) {
      expect(() => const ComandoTextoCalculadoraService().interpretar(texto),
          throwsArgumentError,
          reason: texto);
    }
  });
  test(
      'texto não aplica proposta antiga nem aceita comando adulterado parcialmente',
      () async {
    final c = CalculadoraFestaController(
        repository: RepoJornada(),
        itensBaseRepository: BaseJornada(),
        aiService: AiQA());
    addTearDown(c.onClose);
    await c.prepararCalculadora(
        idEvento: 'evento',
        tipoEvento: 'Aniversário',
        base: BaseCalculoFesta.manual,
        adultosManuais: 20);
    final commands = const ComandoTextoCalculadoraService()
        .interpretar('planeje para 30 adultos; duração 6 horas');
    final assinatura = c.assinaturaProposta;
    c.atualizarDuracao(8);
    expect(
        () => c.aplicarComandosTexto(commands, assinatura), throwsStateError);
    expect(c.totalAdultos.value, 20);
    expect(
        () => c.aplicarComandosTexto(
            [...commands, const ComandoTextoCalculadora('pagar', {}, '')],
            c.assinaturaProposta),
        throwsStateError);
    expect(c.totalAdultos.value, 20);
    await c.aplicarComandosTexto(commands, c.assinaturaProposta);
    expect(c.totalAdultos.value, 30);
    expect(c.duracaoHoras.value, 6);
  });
  test('receita por texto reconhece decimais e conversões métricas explícitas',
      () {
    final f = const ImportacaoReceitaTextoService().interpretar(
        'Rende 2,5 kg pronto\n500 g de arroz (seco)\n1 L de água (pronto)',
        prato: 'Minha receita',
        unidade: 'kg',
        estado: 'pronto');
    expect(f['rendimento'], 2.5);
    expect(f['ingredientes'][0]['quantidade'], .5);
    expect(f['ingredientes'][0]['unidade'], 'kg');
    expect(f['ingredientes'][1]['estado'], 'pronto');
  });
  test('receita ambígua, incompleta ou incompatível não vira ficha parcial',
      () {
    for (final texto in [
      'Rende 2 kg pronto\num pouco de arroz',
      'Rende 2 L pronto\n1 kg arroz (seco)',
      'Rende 2 kg cru\n1 kg arroz (seco)',
      'Rende 2 kg pronto\n1.000 kg arroz (seco)',
      'Rende 2 kg pronto\n1 kg arroz (seco)\n2 kg arroz (seco)'
    ]) {
      expect(
          () => const ImportacaoReceitaTextoService().interpretar(texto,
              prato: 'Arroz', unidade: 'kg', estado: 'pronto'),
          throwsArgumentError);
    }
  });
  Map<String, dynamic> sessao(String modo, {int intervencoes = 10}) => {
        'origem': 'sessao_observada',
        'participante': 'p1',
        'cenario': 'completo',
        'tarefa': 'propor',
        'modo': modo,
        'versao_app': modo,
        'contexto_comparavel': 'caso1',
        'concluida': true,
        'validacao_quantidades': true,
        'sem_duplicidades': true,
        'sem_alterar_fatos': true,
        'intervencoes': intervencoes,
        'segundos_ativos': 30,
        'correcoes': 0,
        'erros': 0,
        'latencia_ia_ms': 0,
        'custo_ia': 0,
      };
  test('avaliação não declara 80% com amostra ou cobertura incompleta', () {
    final r = const AvaliacaoAutonomiaCalculadoraService()
        .avaliar([sessao('antes'), sessao('depois', intervencoes: 2)]);
    expect(r['reducao_percentual'], 80);
    expect(r['meta_80_no_piloto'], false);
    expect(r['cobertura_piloto_completa'], false);
  });
  test(
      'avaliação rejeita pares ausentes, contextos diferentes e métricas faltantes',
      () {
    for (final data in [
      [sessao('antes')],
      [
        sessao('antes'),
        {...sessao('depois'), 'contexto_comparavel': 'outro'}
      ],
      [
        sessao('antes'),
        {...sessao('depois'), 'custo_ia': null}
      ],
      [sessao('antes'), sessao('antes'), sessao('depois')],
    ]) {
      expect(() => const AvaliacaoAutonomiaCalculadoraService().avaliar(data),
          throwsArgumentError);
    }
  });
  test(
      'reduzir trabalho não passa na qualidade quando há erros ou alteração de fatos',
      () {
    final r = const AvaliacaoAutonomiaCalculadoraService().avaliar([
      sessao('antes'),
      {...sessao('depois', intervencoes: 0), 'sem_alterar_fatos': false}
    ]);
    expect(r['qualidade_preservada'], false);
    expect(r['meta_70_no_piloto'], false);
  });
}
