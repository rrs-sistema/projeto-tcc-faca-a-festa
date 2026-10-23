import 'dart:convert';
import 'dart:math' as math;
import '../entities/referencia_contextual.dart';
import 'package:uuid/uuid.dart';
import '../entities/calculadora_festa.dart';
import '../entities/convidado.dart';
import '../entities/cardapio.dart';
import '../entities/cardapio_item.dart';
import '../entities/estimativa_financeira.dart';
import 'ficha_tecnica_calculadora_service.dart';
import 'operacao_calculadora_service.dart';
import 'plano_evento_service.dart';
import 'lista_compras_calculadora_service.dart';
import 'revisao_cardapio_service.dart';
import 'composicao_refeicao_service.dart';

String assinaturaExecucao(dynamic valor) {
  dynamic ordenar(dynamic v) {
    if (v is Map) {
      final keys = v.keys.map((k) => k.toString()).toList()..sort();
      return {for (final k in keys) k: ordenar(v[k])};
    }
    if (v is List) return v.map(ordenar).toList();
    return v;
  }

  return jsonEncode(ordenar(valor));
}

class ContextoExecucaoPlano {
  const ContextoExecucaoPlano(
      {required this.evento,
      required this.fontes,
      required this.operacao,
      required this.cardapios,
      required this.itens,
      required this.compromissos,
      required this.tarefas,
      this.recibosRecuperados = const []});
  final List<String> recibosRecuperados;
  final String evento;

  /// Fontes normalizadas pelo adaptador. Inclui documentos ausentes como null.
  final Map<String, Map<String, dynamic>?> fontes;
  final Map<String, dynamic> operacao;
  final List<Cardapio> cardapios;
  final Map<String, List<CardapioItem>> itens;
  final List<Map<String, dynamic>> compromissos;
  final Map<String, Map<String, dynamic>> tarefas;
}

class PropostaExecucaoPlano {
  const PropostaExecucaoPlano(
      {required this.pedido,
      required this.contexto,
      required this.alteracoes,
      required this.operacao,
      required this.regras,
      required this.compras,
      required this.reservas,
      required this.pendencias,
      required this.mudancas,
      required this.publico});
  final String pedido;
  final ContextoExecucaoPlano contexto;
  final Map<String, Map<String, dynamic>> alteracoes;
  final Map<String, dynamic> operacao, publico;
  final List<ItemEstimativaFinanceira> regras;
  final List<Map<String, dynamic>> compras, reservas;
  final List<String> pendencias, mudancas;
  String get assinatura => assinaturaExecucao({
        'fontes': contexto.fontes,
        'alteracoes': alteracoes,
        'operacao': operacao,
        'publico': publico,
        'regras': regras.map((r) => r.toPlanejamento()).toList(),
        'compras': compras
      });
}

/// Prepara ações verificáveis. Não faz compra, pagamento nem contratação.
class PlanoExecucaoService {
  const PlanoExecucaoService();
  PropostaExecucaoPlano gerar(
      {required String pedido,
      required ContextoExecucaoPlano contexto,
      required CalculadoraFesta calculo,
      required List<ItemEstimativaFinanceira> regras,
      CatalogoContextual? catalogo,
      bool declararSemCompras = false,
      bool criarTarefas = true}) {
    final cadastro = contexto.fontes['evento/${contexto.evento}'];
    if (calculo.baseCalculo != BaseCalculoFesta.manual && cadastro != null) {
      var convidados = contexto.fontes.entries
          .where((e) => e.key.startsWith('convidado/') && e.value != null)
          .map((e) => e.value!)
          .toList();
      final haConvidados = convidados.isNotEmpty;
      if (calculo.baseCalculo == BaseCalculoFesta.apenasConfirmados) {
        convidados = convidados
            .where((c) =>
                StatusConvidado.fromString(c['status']) ==
                StatusConvidado.confirmado)
            .toList();
      }
      if (calculo.baseCalculo == BaseCalculoFesta.naoRecusados) {
        convidados = convidados
            .where((c) =>
                StatusConvidado.fromString(c['status']) !=
                StatusConvidado.recusado)
            .toList();
      }
      final usarLista = calculo.baseCalculo != BaseCalculoFesta.previstos &&
          (convidados.isNotEmpty ||
              calculo.baseCalculo == BaseCalculoFesta.apenasConfirmados ||
              haConvidados);
      TipoConvidado tipo(Map<String, dynamic> c) => c['tipo_convidado'] == null
          ? TipoConvidado.fromLegacyAdulto(c['adulto'])
          : TipoConvidado.fromString(c['tipo_convidado']);
      int total(String campo, TipoConvidado idade) => usarLista
          ? convidados.where((c) => tipo(c) == idade).length
          : OperacaoCalculadoraService.inteiro(cadastro[campo] ?? 0);
      var adultos = total('total_adultos', TipoConvidado.adulto);
      final criancas = total('total_criancas', TipoConvidado.crianca),
          bebes = total('total_bebes', TipoConvidado.bebe);
      if (!usarLista && adultos + criancas + bebes == 0) {
        adultos = OperacaoCalculadoraService.inteiro(
            cadastro['total_convidados'] ?? 0);
      }
      calculo = calculo.copyWith(
          totalAdultos: adultos, totalCriancas: criancas, totalBebes: bebes);
    }
    if (contexto.evento != calculo.idEvento ||
        contexto.cardapios.isEmpty ||
        calculo.totalConvidados <= 0 ||
        pedido.isEmpty) {
      throw StateError(
          'Selecione um evento com público e cardápio para organizar a execução.');
    }
    const motor = OperacaoCalculadoraService();
    motor.validarDocumento(contexto.operacao);
    final op = OperacaoCalculadoraService.mapa(
        jsonDecode(jsonEncode(contexto.operacao)));
    final lotes = OperacaoCalculadoraService.mapa(op['lotes']);
    final alteracoes = <String, Map<String, dynamic>>{};
    final pendencias = <String>[], mudancas = <String>[];
    var demandaCompleta = true;
    final reservas = <Map<String, dynamic>>[];
    final titulos = {
      for (final m in contexto.cardapios) m.idCardapio: m.titulo
    };
    final compras = <String, Map<String, dynamic>>{};
    final tarefas = <String, Map<String, dynamic>>{};
    final usadas = <ItemEstimativaFinanceira>[];
    final plano = const PlanoEventoService().gerar(
        catalogo: catalogo,
        calculo: calculo,
        cardapios: contexto.cardapios,
        itensPorCardapio: contexto.itens,
        regras: regras,
        operacao: contexto.operacao);
    final anterior =
        OperacaoCalculadoraService.mapa(contexto.operacao['execucao']);
    final publico = {
      'adultos': calculo.totalAdultos,
      'criancas': calculo.totalCriancas,
      'bebes': calculo.totalBebes,
      'base': calculo.baseCalculo.name
    };
    if (anterior.isNotEmpty &&
        assinaturaExecucao(anterior['publico']) !=
            assinaturaExecucao(publico)) {
      mudancas.add(
          'Público alterado desde a última aplicação: compras e reservas foram recalculadas. Contratos e pagamentos não mudam.');
    }
    final redistribuir = <String>{};
    for (final d in plano.destinos) {
      final config = motor.refeicao(op, d.cardapio.idCardapio);
      for (final item in d.itens) {
        final rs = d.proposta.regras
            .where((r) =>
                r.selecionado && r.premissas['id_item_cardapio'] == item.idItem)
            .toList();
        final resultados =
            d.resultados.where((r) => r.idItemCardapio == item.idItem).toList();
        if (rs.length != 1 ||
            resultados.length != 1 ||
            rs.single.premissas['unidade_original'] != null ||
            RevisaoCardapioService.unidade(rs.single.unidade.label) !=
                RevisaoCardapioService.unidade(item.unidade)) {
          continue;
        }
        try {
          const FichaTecnicaCalculadoraService().validar(rs.single);
        } catch (_) {
          continue;
        }
        final a = const ListaComprasCalculadoraService().analisar(
            resultado: resultados.single,
            regra: rs.single,
            cardapio: d.itens,
            compromissos: contexto.compromissos,
            convidados: motor.publico(config, calculo.convidadosEquivalentes),
            perfil: calculo.perfilFesta,
            duracao: calculo.duracaoHoras,
            margem: calculo.margemPersonalizada,
            estoqueReservado: 0,
            exigirEstoqueCentral: true,
            desdobrarFicha: true);
        if (!a.precisaConferir ||
            (declararSemCompras &&
                item.disponibilidade == null &&
                a.situacao == SituacaoCompra.informarDisponibilidade)) {
          final chavePreparo =
              assinaturaExecucao(['preparo', item.idCardapio, item.idItem]);
          final comprometido = contexto.tarefas.values.any((t) =>
              t['calculadora_origem'] == 'execucao_v1' &&
              t['calculadora_chave'] == chavePreparo &&
              (t['status'] != 'a_fazer' ||
                  t['calculadora_assinatura'] !=
                      assinaturaExecucao({
                        'titulo': t['titulo'],
                        'descricao': t['descricao']
                      })));
          if (comprometido) {
            pendencias.add(
                '${item.nome}: reservas de preparo iniciado, concluído ou editado foram preservadas; confira o estoque físico antes de liberá-las.');
          } else {
            redistribuir.add(OperacaoCalculadoraService.destino(
                item.idCardapio, item.idItem));
          }
        }
      }
    }
    for (final e in lotes.entries.toList()) {
      final l = OperacaoCalculadoraService.mapa(e.value),
          rs = OperacaoCalculadoraService.mapa(
              OperacaoCalculadoraService.mapa(e.value)['reservas']);
      rs.removeWhere((_, raw) {
        final r = OperacaoCalculadoraService.mapa(raw);
        return r['origem'] == 'execucao_v1' &&
            redistribuir.contains(OperacaoCalculadoraService.destino(
                r['refeicao'].toString(), r['item'].toString()));
      });
      l['reservas'] = rs;
      lotes[e.key] = l;
    }
    double reservar(
        {required CardapioItem item,
        required String nome,
        required String unidade,
        required String estado,
        required double necessidade,
        required String publicoChave,
        String? ingrediente,
        bool permitir = true}) {
      var restante = necessidade;
      final chave = ingrediente == null
          ? OperacaoCalculadoraService.destino(item.idCardapio, item.idItem)
          : jsonEncode([item.idCardapio, item.idItem, ingrediente]);
      for (final id in (lotes.keys.toList()..sort())) {
        final l = OperacaoCalculadoraService.mapa(lotes[id]);
        final rs = OperacaoCalculadoraService.mapa(l['reservas']);
        final existente = OperacaoCalculadoraService.mapa(rs[chave]);
        final compativel = RevisaoCardapioService.normalizar(
                    l['nome']?.toString() ?? '') ==
                RevisaoCardapioService.normalizar(nome) &&
            RevisaoCardapioService.unidade(l['unidade']?.toString() ?? '') ==
                RevisaoCardapioService.unidade(unidade) &&
            l['estado'] == estado;
        if (existente.isNotEmpty) {
          if (!compativel ||
              existente['publico'] != item.publicoAlvo.name ||
              existente['nome'] != nome) {
            throw StateError(
                'Uma reserva manual de $nome precisa de conferência antes de organizar o conjunto.');
          }
          restante = math.max(
              0,
              restante -
                  OperacaoCalculadoraService.numero(existente['quantidade']));
          continue;
        }
        if (!permitir || !compativel || restante <= 1e-9) continue;
        final usado = rs.values.fold<double>(
            0,
            (s, r) =>
                s +
                OperacaoCalculadoraService.numero(
                    OperacaoCalculadoraService.mapa(r)['quantidade']));
        final qtd = math.min(
            restante,
            math.max(
                0.0, OperacaoCalculadoraService.numero(l['total']) - usado));
        if (qtd <= 1e-9) continue;
        final r = {
          'refeicao': item.idCardapio,
          'item': item.idItem,
          'nome': nome,
          'publico': item.publicoAlvo.name,
          'quantidade': qtd,
          'origem': 'execucao_v1',
          'publico_chave': publicoChave,
          if (ingrediente != null) 'ingrediente': ingrediente
        };
        rs[chave] = r;
        l['reservas'] = rs;
        lotes[id] = l;
        reservas.add({
          'lote': id,
          'nome': nome,
          'quantidade': qtd,
          'unidade': unidade,
          'refeicao': item.idCardapio,
          'titulo_refeicao': titulos[item.idCardapio] ?? 'Refeição'
        });
        restante -= qtd;
      }
      return math.max(0, restante);
    }

    void tarefa(String chave, String titulo, String descricao) {
      if (!criarTarefas) return;
      final id =
          'calc_exec_${contexto.evento}_${const Uuid().v5(Namespace.url.value, chave)}';
      final existente = contexto.tarefas[id];
      if (existente != null &&
          (existente['calculadora_origem'] != 'execucao_v1' ||
              existente['status'] != 'a_fazer' ||
              existente['calculadora_assinatura'] !=
                  assinaturaExecucao({
                    'titulo': existente['titulo'],
                    'descricao': existente['descricao']
                  }))) {
        pendencias.add(
            'Tarefa preservada: ${existente['titulo']}. Já iniciada, concluída ou editada; confira a nova demanda.');
        return;
      }
      final texto = {'titulo': titulo, 'descricao': descricao};
      tarefas[id] = {
        'id_tarefa': id,
        'id_evento': contexto.evento,
        ...texto,
        'calculadora_origem': 'execucao_v1',
        'calculadora_chave': chave,
        'calculadora_assinatura': assinaturaExecucao(texto),
        'calculadora_sem_demanda': false,
        if (existente == null) ...{
          'status': 'a_fazer',
          'id_responsavel': null,
          'data_prevista': null
        }
      };
    }

    void material(CardapioItem item, String nome, String unidade, String estado,
        double quantidade, String publicoChave,
        {String? ingrediente, double embalagem = 0, bool permitir = true}) {
      final falta = reservar(
          item: item,
          nome: nome,
          unidade: unidade,
          estado: estado,
          necessidade: quantidade,
          publicoChave: publicoChave,
          ingrediente: ingrediente,
          permitir: permitir);
      final chave = assinaturaExecucao([
        RevisaoCardapioService.normalizar(nome),
        unidade,
        estado,
        publicoChave
      ]);
      final linha = compras.putIfAbsent(
          chave,
          () => {
                'chave': chave,
                'nome': nome,
                'unidade': unidade,
                'estado': estado,
                'quantidade': 0.0,
                'destinos': <String>[],
                'destinos_ids': <Map<String, dynamic>>[],
                'embalagem': embalagem
              });
      // Embalagens diferentes não são extrapoladas para outro produto.
      if (linha['embalagem'] != embalagem) linha['embalagem'] = 0.0;
      linha['quantidade'] = (linha['quantidade'] as num).toDouble() + falta;
      (linha['destinos'] as List)
          .add('${titulos[item.idCardapio] ?? 'Refeição'} · ${item.nome}');
      (linha['destinos_ids'] as List).add({
        'cardapio': item.idCardapio,
        'item': item.idItem,
        if (ingrediente != null) 'ingrediente': ingrediente,
      });
    }

    for (final d in plano.destinos) {
      if (d.sugerido) continue;
      pendencias.addAll(d.pendencias);
      final config = motor.refeicao(op, d.cardapio.idCardapio);
      final grupos = OperacaoCalculadoraService.lista(config['grupos']);
      final publicos =
          OperacaoCalculadoraService.mapa(config['destinos_itens']);
      final compostas =
          const ComposicaoRefeicaoService().compor(d.proposta.regras);
      for (final item in d.itens) {
        final candidatas = compostas
            .where((r) =>
                r.premissas['id_item_cardapio'] == item.idItem && r.selecionado)
            .toList();
        final resultados =
            d.resultados.where((r) => r.idItemCardapio == item.idItem).toList();
        if (candidatas.length != 1 || resultados.length != 1) {
          pendencias.add(
              '${item.nome}: falta uma regra selecionada para incluir na execução.');
          demandaCompleta = false;
          continue;
        }
        final regra = candidatas.single;
        final resultado = resultados.single;
        if (regra.premissas['unidade_original'] != null ||
            RevisaoCardapioService.unidade(regra.unidade.label) !=
                RevisaoCardapioService.unidade(item.unidade)) {
          pendencias.add(
              '${item.nome}: confira a mudança de unidade na proposta da refeição antes de executar.');
          demandaCompleta = false;
          continue;
        }
        usadas.add(regra);
        final path = 'cardapios/${item.idCardapio}/itens/${item.idItem}';
        alteracoes[path] = {'quantidade_sugerida': resultado.quantidade};
        if ((item.quantidadeSugerida - resultado.quantidade).abs() > .000001) {
          mudancas.add(
              '${d.cardapio.titulo} · ${item.nome}: ${item.quantidadeSugerida} → ${resultado.quantidadeFormatada} sugeridos.');
        }
        final analise = const ListaComprasCalculadoraService().analisar(
            resultado: resultado,
            regra: regra,
            cardapio: d.itens,
            compromissos: contexto.compromissos,
            convidados: motor.publico(config, calculo.convidadosEquivalentes),
            perfil: calculo.perfilFesta,
            duracao: calculo.duracaoHoras,
            margem: calculo.margemPersonalizada,
            estoqueReservado: 0,
            exigirEstoqueCentral: true,
            desdobrarFicha: true);
        if (analise.situacao == SituacaoCompra.incluido) {
          pendencias.add(
              '${item.nome}: entrega a conferir com ${analise.servicos.join(', ')}; nenhuma compra ou reserva adicional proposta.');
          continue;
        }
        if (analise.precisaConferir &&
            !(item.disponibilidade == null &&
                declararSemCompras &&
                analise.situacao == SituacaoCompra.informarDisponibilidade)) {
          pendencias.add('${item.nome}: ${analise.orientacao}');
          demandaCompleta = false;
          continue;
        }
        final estado =
            (regra.premissas['estado_compra'] ?? regra.premissas['estado'])
                .toString();
        if (item.disponibilidade == null && declararSemCompras) {
          alteracoes[path]!['disponibilidade'] = {
            'nome': item.nome,
            'unidade': item.unidade,
            'publico': item.publicoAlvo.name,
            'estado': estado,
            'comprado': 0.0,
            'estoque': 0.0
          };
        }
        final necessidade = math.max(
            0.0,
            (item.quantidadeFinal > 0
                    ? item.quantidadeFinal
                    : (resultado.quantidadeNecessaria ??
                        resultado.quantidade)) -
                (item.disponibilidade?.comprado ?? 0));
        if (item.quantidadeFinal > 0) {
          mudancas.add(
              '${d.cardapio.titulo} · ${item.nome}: mantida a quantidade final de ${_q(item.quantidadeFinal)} ${item.unidade} para compra/preparo; a referência é apenas sugestão.');
        }
        final alvo = OperacaoCalculadoraService.mapa(publicos[item.idItem]);
        final especial =
            grupos.isNotEmpty || (alvo['modo'] ?? 'todos') != 'todos';
        final publicoChave = especial
            ? assinaturaExecucao([item.idCardapio, item.idItem, config])
            : item.publicoAlvo.name;
        if (especial) {
          pendencias.add(
              '${item.nome}: estoque de público com necessidades específicas exige conferência; não foi destinado automaticamente.');
        }
        Map<String, dynamic>? ficha;
        try {
          ficha = const FichaTecnicaCalculadoraService().validar(regra);
        } catch (e) {
          pendencias.add(e.toString());
          demandaCompleta = false;
          continue;
        }
        if (ficha == null) {
          material(item, item.nome, resultado.unidade, estado, necessidade,
              publicoChave,
              embalagem: regra.tamanhoEmbalagem, permitir: !especial);
        } else {
          final preparar = reservar(
              item: item,
              nome: item.nome,
              unidade: item.unidade,
              estado: estado,
              necessidade: necessidade,
              publicoChave: publicoChave,
              permitir: !especial);
          if (preparar > 1e-9) {
            for (final i
                in OperacaoCalculadoraService.lista(ficha['ingredientes'])) {
              material(
                  item,
                  i['nome'],
                  i['unidade'],
                  i['estado'],
                  preparar /
                      OperacaoCalculadoraService.numero(ficha['rendimento']) *
                      OperacaoCalculadoraService.numero(i['quantidade']),
                  publicoChave,
                  ingrediente: i['id'],
                  permitir: !especial);
            }
            tarefa(
                assinaturaExecucao(['preparo', item.idCardapio, item.idItem]),
                'Preparar ${item.nome}',
                '${d.cardapio.titulo}: preparar ${_q(preparar)} ${item.unidade} (${ficha['estado']}). Ficha informada pelo organizador; conferir rendimento e preparo.');
          }
        }
      }
    }
    for (final linha in compras.values) {
      final qtd = (linha['quantidade'] as num).toDouble();
      final embalagem = (linha['embalagem'] as num).toDouble();
      final passo = ['kg', 'L'].contains(linha['unidade']) ? 100.0 : 1.0;
      final arredondado = embalagem > 0
          ? (qtd / embalagem - 1e-9).ceil() * embalagem
          : (qtd * passo - 1e-9).ceil() / passo;
      linha['quantidade'] = math.max(0.0, arredondado);
      if (arredondado > 0) {
        tarefa(
            assinaturaExecucao(['compra', linha['chave']]),
            'Comprar ${linha['nome']}',
            '${_q(arredondado)} ${linha['unidade']} · ${linha['estado']}. Destinos: ${(linha['destinos'] as List).join('; ')}. Compra ainda não realizada.');
      }
    }
    if (criarTarefas && demandaCompleta) {
      for (final entry in contexto.tarefas.entries) {
        final t = entry.value;
        if (t['calculadora_origem'] == 'execucao_v1' &&
            !tarefas.containsKey(entry.key) &&
            t['status'] == 'a_fazer' &&
            t['calculadora_sem_demanda'] != true &&
            t['calculadora_assinatura'] ==
                assinaturaExecucao(
                    {'titulo': t['titulo'], 'descricao': t['descricao']})) {
          final texto = {
            'titulo': 'Revisar tarefa sem demanda atual',
            'descricao':
                '${t['titulo']}: o plano atual não gera esta demanda. Confira antes de executar; a tarefa não foi marcada como concluída.'
          };
          tarefas[entry.key] = {
            ...texto,
            'calculadora_sem_demanda': true,
            'calculadora_assinatura': assinaturaExecucao(texto)
          };
        }
      }
    }
    for (final e in tarefas.entries) {
      alteracoes['tarefa/${e.key}'] = e.value;
    }
    for (final entry
        in OperacaoCalculadoraService.mapa(contexto.operacao['lotes'])
            .entries) {
      final antes = OperacaoCalculadoraService.mapa(
          OperacaoCalculadoraService.mapa(entry.value)['reservas']);
      final depois = OperacaoCalculadoraService.mapa(
          OperacaoCalculadoraService.mapa(lotes[entry.key])['reservas']);
      for (final r in antes.entries) {
        final reserva = OperacaoCalculadoraService.mapa(r.value);
        if (reserva['origem'] != 'execucao_v1') continue;
        final liberado =
            OperacaoCalculadoraService.numero(reserva['quantidade']) -
                (OperacaoCalculadoraService.mapa(depois[r.key])['quantidade']
                        as num? ??
                    0);
        if (liberado > 1e-9) {
          mudancas.add(
              'Liberar ${_q(liberado)} ${OperacaoCalculadoraService.mapa(entry.value)['unidade']} do lote ${OperacaoCalculadoraService.mapa(entry.value)['nome']} antes destinado a ${reserva['nome']}.');
        }
      }
    }
    final comprasAnteriores =
        OperacaoCalculadoraService.lista(anterior['compras']);
    for (final l in compras.values) {
      final antigas =
          comprasAnteriores.where((a) => a['chave'] == l['chave']).toList();
      final antes = antigas.isEmpty
          ? 0.0
          : (antigas.first['quantidade'] as num).toDouble();
      if (anterior.isNotEmpty &&
          ((l['quantidade'] as num) - antes).abs() > 1e-9) {
        mudancas.add(
            'Compra de ${l['nome']}: ${_q(antes)} → ${_q(l['quantidade'])} ${l['unidade']}.');
      }
    }
    for (final l in comprasAnteriores.where((a) =>
        !compras.containsKey(a['chave']) && (a['quantidade'] as num) > 0)) {
      if (demandaCompleta) {
        mudancas.add(
            'Compra de ${l['nome']} sem demanda neste plano; confira tarefas anteriores.');
      }
    }
    op['lotes'] = lotes;
    op['versao'] = 1;
    op['revisao'] = (contexto.operacao['revisao'] as num? ?? 0).toInt() + 1;
    motor.validarDocumento(op);
    if (alteracoes.length > 100 || usadas.length > 60) {
      throw StateError(
          'O plano excede o limite desta revisão. Reduza os destinos antes de aplicar.');
    }
    return PropostaExecucaoPlano(
        pedido: pedido,
        contexto: contexto,
        alteracoes: alteracoes,
        operacao: op,
        regras: usadas,
        compras: compras.values.toList(),
        reservas: reservas,
        pendencias: pendencias.toSet().toList(),
        mudancas: mudancas,
        publico: publico);
  }

  static String _q(num n) => n.toStringAsFixed(2).replaceAll('.', ',');
}
