import 'dart:convert';
import 'dart:io';
import 'package:app_faca_festa/domain/services/piloto_autonomia_calculadora_service.dart';
import 'package:app_faca_festa/domain/services/observacao_autonomia_calculadora.dart';
import 'piloto_autonomia_store.dart';

const piloto = PilotoAutonomiaCalculadoraService();
String? perguntar(String mensagem) {
  stdout.write('$mensagem ');
  return stdin.readLineSync();
}

bool? simNao(String mensagem) => switch (
        perguntar('$mensagem [s/n; Enter = pendente]')?.trim().toLowerCase()) {
      's' => true,
      'n' => false,
      _ => null,
    };
const encoder = JsonEncoder.withIndent('  ');
void main(List<String> args) {
  if (args.length < 2) {
    ajuda();
    exitCode = 64;
    return;
  }
  try {
    final cmd = args[0], store = PilotoAutonomiaStore(args[1]);
    if (cmd == 'criar' && args.length == 5) {
      store.salvar(piloto.criar(args[2], args[3], int.parse(args[4])),
          revisaoAnterior: null);
      stdout.writeln(
          'Roteiro criado sem resultados. Defina os 16 casos antes de observá-los.');
      return;
    }
    var estudo = store.ler();
    if (cmd == 'caso' && args.length == 5) {
      final criterio = perguntar('Critério de aceite fixado antes da sessão:');
      if (criterio == null) return;
      final novo =
          piloto.definirCaso(estudo, args[2], args[3], args[4], criterio);
      store.salvar(novo, revisaoAnterior: estudo['revisao'] as int);
      stdout.writeln('Caso salvo. Ele ficará fixo após a primeira observação.');
    } else if (cmd == 'observar' && args.length == 6) {
      observar(store, estudo, args[2], args[3], args[4], args[5]);
    } else if (cmd == 'status' && args.length == 2) {
      final status = piloto.progresso(estudo),
          faltantes = status['faltantes'] as List;
      stdout.writeln(
          'Casos definidos: ${status['casos_definidos']}/16. Sessões finalizadas: ${status['sessoes_finalizadas']}/${status['sessoes_previstas']}.');
      stdout.writeln(
          'Interrompidas e retomáveis: ${status['sessoes_interrompidas']}.');
      if (status['resultado'] != null) {
        stdout.writeln(encoder.convert(status['resultado']));
      } else {
        stdout.writeln(status['impedimento']);
        stdout.writeln(
            'Próximas pendências: ${encoder.convert(faltantes.take(4).toList())}');
      }
    } else if (cmd == 'exportar' && args.length == 2) {
      // Exportar também os registros incompletos: não melhorar a meta omitindo-os.
      stdout.writeln(encoder.convert(estudo['sessoes']));
    } else {
      ajuda();
      exitCode = 64;
    }
  } catch (e) {
    stderr.writeln('Não concluído: $e');
    exitCode = 1;
  }
}

void observar(PilotoAutonomiaStore store, Map<String, dynamic> estudo,
    String participante, String cenario, String tarefa, String modo) {
  final caso = (estudo['casos'] as Map)['$cenario|$tarefa'];
  if (caso is! Map) {
    throw StateError('Defina o caso e o critério de aceite primeiro.');
  }
  final versao = estudo['versao_$modo'];
  final anteriores = (estudo['sessoes'] as List)
      .where((s) =>
          s['participante'] == participante &&
          s['cenario'] == cenario &&
          s['tarefa'] == tarefa &&
          s['modo'] == modo)
      .toList();
  final dados = anteriores.isEmpty
      ? <String, dynamic>{
          'origem': 'sessao_observada',
          'participante': participante,
          'cenario': cenario,
          'tarefa': tarefa,
          'modo': modo,
          'versao_app': versao,
          'contexto_comparavel': caso['contexto'],
          'intervencoes': 0,
          'segundos_ativos': 0,
          'correcoes': 0,
          'erros': 0,
        }
      : Map<String, dynamic>.from(anteriores.single as Map);
  if (dados['estado_observacao'] == 'finalizada') {
    throw StateError('Esta sessão já foi finalizada e preservada.');
  }
  if (dados['cronometro_ativo'] == true) {
    dados['medicao_completa'] = false;
    stderr.writeln(
        'O processo anterior terminou durante a contagem. O intervalo sem checkpoint não será inventado; esta medição fica marcada como incompleta.');
  }
  stdout.writeln('Versão: $versao. Caso: ${caso['contexto']}.');
  stdout.writeln(PilotoAutonomiaCalculadoraService.instrucoes[tarefa]);
  stdout.writeln('Critério fixado: ${caso['criterio']}');
  if (simNao(
          'Você está observando este participante, nesta versão e neste caso de teste?') !=
      true) {
    return;
  }
  final relogio = Stopwatch()..start();
  final observacao = ObservacaoAutonomiaCalculadora(
      dados: dados, relogio: () => relogio.elapsed);
  void salvar(Map<String, dynamic> sessao) {
    final novo = piloto.registrar(estudo, sessao);
    store.salvar(novo, revisaoAnterior: estudo['revisao'] as int);
    estudo = novo;
  }

  observacao.retomar();
  salvar(
      observacao.checkpoint()); // Validar ordem e persistir o cronômetro ativo.
  stdout.writeln(
      'i = intervenção; c = correção (já conta intervenção); e = erro; p = pausa; r = retomar; f = finalizar; q = salvar e sair.');
  while (true) {
    final cmd = perguntar(observacao.ativa ? 'Observando >' : 'Pausado >')
        ?.trim()
        .toLowerCase();
    if (cmd == null || cmd == 'q') {
      observacao.pausar();
      salvar(observacao.checkpoint());
      stdout.writeln(
          'Observação interrompida e salva. Nenhum resultado foi presumido.');
      return;
    }
    if (cmd == 'f') {
      observacao.pausar();
      salvar(observacao.checkpoint());
      final concluida = simNao(
              'A tarefa foi concluída? Preserve também tentativas malsucedidas.'),
          quantidades = simNao('Quantidades conferidas contra o critério?'),
          duplicidades = simNao('Sem duplicidades?'),
          fatos = simNao('Compras, contratos e pagamentos preservados?'),
          usouIA = simNao('Houve chamada de IA nesta tarefa?');
      final custo = usouIA == false
          ? 0.0
          : double.tryParse((perguntar(
                      'Custo medido de IA (mesma moeda do estudo; Enter = pendente):') ??
                  '')
              .replaceAll(',', '.'));
      final latencia = usouIA == false
          ? 0
          : int.tryParse(
              perguntar('Latência medida de IA em ms (Enter = pendente):') ??
                  '');
      try {
        salvar({
          ...observacao.checkpoint(),
          'estado_observacao': 'finalizada',
          'concluida': concluida,
          'validacao_quantidades': quantidades,
          'sem_duplicidades': duplicidades,
          'sem_alterar_fatos': fatos,
          'custo_ia': usouIA == null ? null : custo,
          'latencia_ia_ms': usouIA == null ? null : latencia
        });
        stdout.writeln(
            'Observação finalizada. O resultado informado, inclusive falha, foi preservado.');
        return;
      } catch (e) {
        stderr.writeln('A observação continua salva como pendente: $e');
        // Permanecer pausado: preencher o questionário não é tempo da tarefa.
      }
      continue;
    }
    try {
      switch (cmd) {
        case 'i':
          observacao.contar('intervencoes');
        case 'c':
          observacao.contar('correcoes');
        case 'e':
          observacao.contar('erros');
        case 'p':
          observacao.pausar();
        case 'r':
          observacao.retomar();
        default:
          stdout.writeln('Use i, c, e, p, r, f ou q.');
          continue;
      }
    } on ArgumentError catch (e) {
      stderr.writeln(e);
      continue;
    } on StateError catch (e) {
      stderr.writeln(e);
      continue;
    }
    salvar(observacao.checkpoint());
    final resumo = observacao.checkpoint();
    stdout.writeln(
        '${resumo['intervencoes']} intervenções · ${resumo['correcoes']} correções · ${resumo['erros']} erros · ${resumo['segundos_ativos']} s ativos');
  }
}

void ajuda() => stdout.writeln(
    '''Coleta local do observador, sem acesso ao evento real ou ao Firebase.
dart run tool/piloto_autonomia_calculadora.dart criar ARQUIVO VERSAO_ANTES VERSAO_DEPOIS PARTICIPANTES
dart run tool/piloto_autonomia_calculadora.dart caso ARQUIVO CENARIO TAREFA CONTEXTO
dart run tool/piloto_autonomia_calculadora.dart observar ARQUIVO PARTICIPANTE CENARIO TAREFA antes|depois
dart run tool/piloto_autonomia_calculadora.dart status ARQUIVO
dart run tool/piloto_autonomia_calculadora.dart exportar ARQUIVO
Cenários: tipo_orcamento, tipo_orcamento_publico, tipo_orcamento_cardapio, completo.
Tarefas: propor, ajustar, comprar, revisar. Participantes: p01, p02, ...
Cada edição concluída ou decisão explícita conta uma intervenção; uma correção usa c, sem i adicional.''');
