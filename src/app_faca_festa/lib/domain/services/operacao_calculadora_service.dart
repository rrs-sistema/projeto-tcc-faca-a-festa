import 'agenda_servico_service.dart';
import '../entities/ocorrencia_servico.dart';
import '../entities/confirmacao_configuracao_calculadora.dart';
import 'publico_planejamento_service.dart';
import 'dart:convert';
import '../entities/contexto_servico_planejador.dart';
import 'package:collection/collection.dart';
import 'revisao_pos_evento_service.dart';
import '../entities/cardapio_item.dart';
import '../entities/convidados_equivalentes.dart';
import '../entities/estimativa_financeira.dart';
import '../entities/perfil_festa.dart';
import 'revisao_cardapio_service.dart';

/// Documento privado e transacional por evento. Não infere ingredientes pelo nome.
class OperacaoCalculadoraService {
  const OperacaoCalculadoraService();
  static Map<String, dynamic> mapa(dynamic valor) =>
      valor is Map ? Map<String, dynamic>.from(valor) : {};
  static List<Map<String, dynamic>> lista(dynamic valor) =>
      valor is List ? valor.map(mapa).toList() : [];
  static String destino(String refeicao, String item) =>
      jsonEncode([refeicao, item]);
  static double numero(dynamic n) {
    if (n is! num || !n.isFinite || n < 0 || n > 1000000) {
      throw ArgumentError(
          'Informe uma quantidade válida entre zero e um milhão.');
    }
    return n.toDouble();
  }

  static int inteiro(dynamic n) {
    final v = numero(n);
    if (v != v.truncateToDouble()) {
      throw ArgumentError('Informe pessoas inteiras.');
    }
    return v.toInt();
  }

  static const restricoes = {
    'vegetariano': 'Vegetariano',
    'vegano': 'Vegano',
    'leite': 'Sem leite',
    'gluten': 'Sem glúten',
    'ovos': 'Sem ovos',
    'amendoim': 'Sem amendoim',
    'outra': 'Outra necessidade',
  };
  Map<String, dynamic> refeicao(Map<String, dynamic> operacao, String id) => {
        ...mapa(mapa(operacao['refeicoes'])[id]),
        if (const AgendaServicoService().porCardapio(operacao, id)
            case final o?)
          'ocorrencia': o
      };
  ConvidadosEquivalentes publico(
      Map<String, dynamic> config, ConvidadosEquivalentes padrao) {
    final p = config['publico'];
    final extra = mapa(config['publico_extra']);
    int count(String k, int padrao) =>
        (p is Map ? inteiro(p[k]) : padrao) +
        (extra.isEmpty ? 0 : inteiro(extra[k]));
    return ConvidadosEquivalentes(
        adultos: count('adultos', padrao.adultos),
        criancas: count('criancas', padrao.criancas),
        bebes: count('bebes', padrao.bebes));
  }

  ItemEstimativaFinanceira regraComPublico(ItemEstimativaFinanceira regra,
      Map<String, dynamic> config, ConvidadosEquivalentes padrao) {
    final meta = Map<String, dynamic>.from(regra.premissas)
      ..remove('publico_refeicao')
      ..remove('destino_publico');
    if (config['ocorrencia'] is Map) {
      final o = OcorrenciaServico.fromMap(mapa(config['ocorrencia']));
      meta['id_ocorrencia'] = o.id;
      meta['duracao_servico_minutos'] = o.duracaoMinutos;
      meta['agenda_servico'] = o.toMap();
    }
    final destino = mapa(
        mapa(config['destinos_itens'])[regra.premissas['id_item_cardapio']]);
    if ((destino['modo'] ?? 'todos') == 'todos') {
      return regra.copyWith(premissas: meta);
    }
    final grupos = lista(config['grupos']);
    final ids = List<String>.from(destino['grupos'] as List? ?? []);
    final selecionados = destino['modo'] == 'demais'
        ? grupos
        : grupos.where((g) => ids.contains(g['id'])).toList();
    final p = publico(config, padrao);
    int contagem(String k, int total) {
      final grupo = selecionados.fold<int>(0, (s, g) => s + inteiro(g[k]));
      return destino['modo'] == 'demais'
          ? (total - grupo).clamp(0, total)
          : grupo;
    }

    meta['destino_publico'] = {'modo': destino['modo'], 'grupos': ids..sort()};
    meta['publico_refeicao'] = {
      'adultos': contagem('adultos', p.adultos),
      'criancas': contagem('criancas', p.criancas),
      'bebes': contagem('bebes', p.bebes)
    };
    return regra.copyWith(premissas: meta);
  }

  void validarRefeicao(Map<String, dynamic> config) {
    if (config['publico_extra'] != null) {
      final extra = mapa(config['publico_extra']);
      for (final k in ['adultos', 'criancas', 'bebes']) {
        inteiro(extra[k]);
      }
    }
    if (config['ocorrencia'] != null) {
      OcorrenciaServico.fromMap(mapa(config['ocorrencia']));
    }
    final p = config['publico'];
    if ((p != null && p is! Map) ||
        (config['grupos'] != null && config['grupos'] is! List) ||
        (config['servico'] != null &&
            !['refeicao', 'lanche'].contains(config['servico']))) {
      throw ArgumentError('Confira a configuração da refeição.');
    }
    if (p != null) {
      publico(config,
          const ConvidadosEquivalentes(adultos: 0, criancas: 0, bebes: 0));
    }
    final grupos = lista(config['grupos']);
    if (grupos.length > 12) {
      throw ArgumentError('Use até 12 grupos por refeição.');
    }
    final ids = <String>{};
    for (final g in grupos) {
      if ((g['id']?.toString() ?? '').isEmpty ||
          !ids.add(g['id'].toString()) ||
          (g['nome']?.toString().trim() ?? '').isEmpty ||
          g['restricoes'] is! List ||
          (g['restricoes'] as List).isEmpty ||
          (g['restricoes'] as List).any((r) => !restricoes.containsKey(r))) {
        throw ArgumentError(
            'Identifique o grupo e suas necessidades alimentares.');
      }
      for (final k in ['adultos', 'criancas', 'bebes']) {
        inteiro(g[k]);
      }
      if (['adultos', 'criancas', 'bebes']
              .fold<int>(0, (s, k) => s + inteiro(g[k])) ==
          0) {
        throw ArgumentError('Informe ao menos uma pessoa em cada grupo.');
      }
      for (final a in mapa(g['itens']).values) {
        final registro = mapa(a);
        numero(registro['quantidade']);
        if (registro['conferido'] is! bool) {
          throw ArgumentError('Confira ingredientes e preparo.');
        }
        if (registro['quantidade'] > 0 &&
            (registro['assinatura'] is! String ||
                registro['assinatura'].isEmpty)) {
          throw ArgumentError(
              'Revise a porção antes de destinar o alimento ao grupo.');
        }
      }
    }
    for (final destino in mapa(config['destinos_itens']).values) {
      final d = mapa(destino);
      if (!['todos', 'demais', 'grupos'].contains(d['modo']) ||
          (d['modo'] == 'grupos' &&
              (d['grupos'] is! List ||
                  (d['grupos'] as List).isEmpty ||
                  (d['grupos'] as List).any((id) => !ids.contains(id))))) {
        throw ArgumentError(
            'Confira quem consome cada item após alterar os grupos.');
      }
    }
    if (p is Map) {
      for (final k in ['adultos', 'criancas', 'bebes']) {
        if (grupos.fold<int>(0, (s, g) => s + inteiro(g[k])) >
            inteiro(p[k]) +
                (config['publico_extra'] is Map
                    ? inteiro(config['publico_extra'][k])
                    : 0)) {
          throw ArgumentError(
              'Os grupos não podem repetir pessoas nem superar o público da refeição.');
        }
      }
    }
  }

  Map<String, dynamic> aplicar(
      Map<String, dynamic> atual, Map<String, dynamic> acao) {
    if (atual['versao'] != null && atual['versao'] != 1) {
      throw StateError('Atualize o aplicativo antes de alterar esta operação.');
    }
    if (acao['tipo'] == 'configuracao_planejamento') {
      final comando = ConfirmacaoConfiguracaoCalculadora(
          id: acao['comando_id'] as String,
          revisaoEsperada: acao['revisao'] as int,
          alteracoes: mapa(acao['alteracoes']));
      final recibos =
          mapa(mapa(atual['configuracao_planejamento'])['confirmacoes']);
      if (recibos.containsKey(comando.id)) {
        if (recibos[comando.id] !=
            ConfirmacaoConfiguracaoCalculadora.assinatura(comando.alteracoes)) {
          throw StateError(
              'Esta confirmação já foi usada com outras escolhas.');
        }
        return mapa(jsonDecode(jsonEncode(atual)));
      }
    }
    if ((atual['revisao'] ?? 0) != acao['revisao']) {
      throw StateError(
          'O planejamento foi alterado em outro acesso. Reabra a tela e confira os dados.');
    }
    final novo = mapa(jsonDecode(jsonEncode(atual)));
    switch (acao['tipo']) {
      case 'configuracao_planejamento':
        final mudancas = mapa(acao['alteracoes']);
        final cfg = {...mapa(novo['configuracao_planejamento']), ...mudancas};
        validarConfiguracaoPublico(cfg);
        final recibos = mapa(cfg['confirmacoes']);
        recibos[acao['comando_id']] =
            ConfirmacaoConfiguracaoCalculadora.assinatura(mudancas);
        while (recibos.length > 20) {
          recibos.remove(recibos.keys.first);
        }
        cfg['confirmacoes'] = recibos;
        cfg['campos_alterados'] = mudancas.keys.toList();
        cfg['revisao'] = (atual['revisao'] as num? ?? 0).toInt() + 1;
        novo['configuracao_planejamento'] = cfg;
      case 'publico_planejamento':
        final mudancas = mapa(acao['alteracoes']);
        if (mudancas.isEmpty ||
            mudancas.keys.any((k) => ![
                  'base',
                  'base_confirmada',
                  'publico',
                  'lista_completude'
                ].contains(k))) {
          throw ArgumentError('Confira a escolha de público.');
        }
        final cfg = {...mapa(novo['configuracao_planejamento']), ...mudancas};
        validarConfiguracaoPublico(cfg);
        if (mudancas.containsKey('base') &&
            mudancas['base_confirmada'] != true) {
          throw ArgumentError('Confirme a fonte de público.');
        }
        cfg['campos_alterados'] = mudancas.keys.toList();
        cfg['revisao'] = (atual['revisao'] as num? ?? 0).toInt() + 1;
        novo['configuracao_planejamento'] = cfg;
      case 'regras':
        final recebidas = lista(acao['regras']);
        if (recebidas.isEmpty || recebidas.length > 60) {
          throw ArgumentError('Selecione até 60 ajustes para salvar.');
        }
        final exec = mapa(novo['execucao']);
        final regras = lista(exec['regras']);
        final anteriores = mapa(acao['anteriores']);
        final ids = <String>{};
        var mudou = false;
        for (final raw in recebidas) {
          final regra = ItemEstimativaFinanceira.fromPlanejamento(raw);
          if (regra.id.isEmpty ||
              regra.id.contains('/') ||
              !ids.add(regra.id) ||
              regra.nome.trim().isEmpty ||
              (numero(regra.quantidadePorConvidadoEquivalente) <= 0 &&
                  regra.selecionado) ||
              numero(regra.rendimento) <= 0 ||
              numero(regra.numeroServicos) <= 0) {
            throw ArgumentError('Confira a identificação e o consumo do item.');
          }
          numero(regra.valorUnitarioMedio);
          numero(regra.tamanhoEmbalagem);
          final indice = regras.indexWhere((r) => r['id'] == regra.id);
          final atual = indice < 0 ? null : regras[indice];
          if (const DeepCollectionEquality().equals(atual, raw)) continue;
          if (!anteriores.containsKey(regra.id) ||
              !const DeepCollectionEquality()
                  .equals(atual, anteriores[regra.id])) {
            throw StateError(
                'Este item foi alterado em outro acesso. Reabra o ajuste para conferir os valores.');
          }
          if (indice < 0) {
            regras.add(raw);
          } else {
            regras[indice] = raw;
          }
          mudou = true;
        }
        if (regras.length > 60) {
          throw ArgumentError('O evento já atingiu 60 regras de consumo.');
        }
        if (!mudou) return atual;
        novo['execucao'] = {
          ...exec,
          'regras': regras,
          'contexto_desatualizado': true
        };
      case 'revisao_pos_evento':
        novo['revisao_pos_evento'] = const RevisaoPosEventoService()
            .preparar(mapa(novo['revisao_pos_evento']), acao);
      case 'agenda':
        final o = OcorrenciaServico.fromMap(mapa(acao['ocorrencia']));
        novo.addAll(const AgendaServicoService().atualizar(novo, o));
        final config = {
          ...mapa(mapa(novo['refeicoes'])[o.cardapio]),
          ...mapa(acao['config'])
        }..remove('ocorrencia');
        validarRefeicao(config);
        novo['refeicoes'] = {...mapa(novo['refeicoes']), o.cardapio: config};
      case 'refeicao':
        final config = mapa(acao['config'])..remove('ocorrencia');
        validarRefeicao(config);
        final id = acao['id_cardapio']?.toString() ?? '';
        if (id.isEmpty) throw ArgumentError('Selecione uma refeição.');
        final refeicoes = mapa(novo['refeicoes']);
        refeicoes[id] = config;
        novo['refeicoes'] = refeicoes;
      case 'lote':
        final lotes = mapa(novo['lotes']);
        final id = acao['id_lote']?.toString() ?? '';
        final lote = mapa(acao['lote']);
        if (id.isEmpty ||
            (lote['nome']?.toString().trim() ?? '').isEmpty ||
            !['kg', 'L', 'un', 'cento', 'garrafa', 'pacote']
                .contains(lote['unidade']) ||
            !['cru', 'seco', 'pronto', 'não se aplica']
                .contains(lote['estado'])) {
          throw ArgumentError('Identifique o lote, a unidade e o estado.');
        }
        final anterior = mapa(lotes[id]);
        final reservas = mapa(anterior['reservas']);
        if (reservas.isNotEmpty &&
            ['nome', 'unidade', 'estado'].any((k) => anterior[k] != lote[k])) {
          throw StateError(
              'Libere as reservas antes de alterar a identificação do lote.');
        }
        if (reservas.values
                .fold<double>(0, (s, r) => s + numero(mapa(r)['quantidade'])) >
            numero(lote['total']) + 1e-9) {
          throw StateError(
              'O total não pode ser menor que as reservas existentes.');
        }
        lotes[id] = {...lote, 'reservas': reservas};
        if (lotes.length > 100) {
          throw StateError('Limite de 100 lotes por evento.');
        }
        novo['lotes'] = lotes;
      case 'reservar':
        final lotes = mapa(novo['lotes']);
        final id = acao['id_lote']?.toString() ?? '';
        if (!lotes.containsKey(id)) {
          throw StateError('O lote não está mais disponível.');
        }
        final lote = mapa(lotes[id]);
        final r = mapa(acao['reserva']);
        final ref = r['refeicao']?.toString() ?? '';
        final item = r['item']?.toString() ?? '';
        if (ref.isEmpty ||
            item.isEmpty ||
            (r['nome']?.toString() ?? '').isEmpty ||
            (r['publico']?.toString() ?? '').isEmpty) {
          throw ArgumentError('Selecione um item da refeição.');
        }
        final reservas = mapa(lote['reservas']);
        final qtd = numero(r['quantidade']);
        final chave = r['ingrediente'] == null
            ? destino(ref, item)
            : jsonEncode([ref, item, r['ingrediente']]);
        if (qtd == 0) {
          reservas.remove(chave);
        } else {
          reservas[chave] = r;
        }
        final reservado = reservas.values
            .fold<double>(0, (s, r) => s + numero(mapa(r)['quantidade']));
        if (reservado > numero(lote['total']) + 1e-9) {
          throw StateError(
              'Saldo insuficiente: outras refeições já reservaram parte deste lote.');
        }
        lotes[id] = {...lote, 'reservas': reservas};
        novo['lotes'] = lotes;
      default:
        throw ArgumentError('Operação desconhecida.');
    }
    novo['versao'] = 1;
    novo['revisao'] = (atual['revisao'] as num? ?? 0).toInt() + 1;
    return novo;
  }

  void validarConfiguracaoPublico(Map<String, dynamic> cfg) {
    ConfirmacaoConfiguracaoCalculadora.validar(cfg);
    if (cfg.containsKey('confirmacoes') &&
        (cfg['confirmacoes'] is! Map ||
            (cfg['confirmacoes'] as Map).length > 20 ||
            (cfg['confirmacoes'] as Map)
                .values
                .any((v) => v is! String || v.length > 5000))) {
      throw ArgumentError('Confirmações inválidas.');
    }

    if (cfg.containsKey('lista_completude') &&
            !CompletudeLista.values
                .any((e) => e.valor == cfg['lista_completude']) ||
        cfg.containsKey('base_confirmada') && cfg['base_confirmada'] is! bool ||
        cfg.containsKey('base') && basePublicoDoValor(cfg['base']) == null ||
        cfg['base_confirmada'] == true &&
            basePublicoDoValor(cfg['base']) == null) {
      throw ArgumentError('Configuração de público inválida.');
    }
    if (cfg.containsKey('publico')) {
      final p = cfg['publico'];
      if (p is! Map ||
          p.keys.any((k) => !['adultos', 'criancas', 'bebes'].contains(k))) {
        throw ArgumentError('Público manual inválido.');
      }
      for (final k in ['adultos', 'criancas', 'bebes']) {
        inteiro(p[k]);
      }
    }
    if (cfg['base'] == 'manual' &&
        cfg['base_confirmada'] == true &&
        cfg['publico'] is! Map) {
      throw ArgumentError('Informe o público manual confirmado.');
    }
  }

  void validarDocumento(Map<String, dynamic> documento) {
    if (documento['versao'] != null && documento['versao'] != 1) {
      throw ArgumentError(
          'Operação exige uma versão mais recente do aplicativo.');
    }
    if (documento['planejador'] != null &&
        (documento['planejador'] is! Map ||
            mapa(documento['planejador']).length > 20)) {
      throw ArgumentError('Planejador inválido.');
    }
    for (final d in mapa(documento['planejador']).values) {
      validarDecisaoServicoPlanejador(mapa(d));
    }
    const AgendaServicoService()
        .ler(documento['agenda'], evento: documento['id_evento']?.toString());
    if (documento['configuracao_planejamento'] != null &&
        documento['configuracao_planejamento'] is! Map) {
      throw ArgumentError('Configuração inválida.');
    }
    validarConfiguracaoPublico(mapa(documento['configuracao_planejamento']));
    for (final r in mapa(documento['refeicoes']).values) {
      validarRefeicao(mapa(r));
    }
    final lotes = mapa(documento['lotes']);
    for (final raw in lotes.values) {
      final l = mapa(raw);
      final reservas = mapa(l['reservas']);
      final total = numero(l['total']);
      final usado = reservas.values
          .fold<double>(0, (s, r) => s + numero(mapa(r)['quantidade']));
      if (usado > total + 1e-9 ||
          !['kg', 'L', 'un', 'cento', 'garrafa', 'pacote']
              .contains(l['unidade']) ||
          !['cru', 'seco', 'pronto', 'não se aplica'].contains(l['estado'])) {
        throw StateError('Estoque inconsistente. Confira lotes e reservas.');
      }
    }
  }

  double reservado(Map<String, dynamic> operacao, CardapioItem item,
      String unidade, String estado) {
    var total = 0.0;
    for (final raw in mapa(operacao['lotes']).values) {
      final lote = mapa(raw);
      final r =
          mapa(mapa(lote['reservas'])[destino(item.idCardapio, item.idItem)]);
      if (r.isEmpty) continue;
      final usado = mapa(lote['reservas'])
          .values
          .fold<double>(0, (s, a) => s + numero(mapa(a)['quantidade']));
      if (usado > numero(lote['total']) + 1e-9 ||
          r['refeicao'] != item.idCardapio ||
          r['item'] != item.idItem) {
        throw StateError(
            'O lote ou suas reservas estão inconsistentes. Confira o estoque central.');
      }
      if (RevisaoCardapioService.normalizar(r['nome'].toString()) !=
              RevisaoCardapioService.normalizar(item.nome) ||
          r['publico'] != item.publicoAlvo.name ||
          RevisaoCardapioService.unidade(lote['unidade'].toString()) !=
              RevisaoCardapioService.unidade(unidade) ||
          lote['estado'] != estado) {
        throw StateError(
            'Uma reserva usa identificação ou medida anterior. Libere-a e confira o lote.');
      }
      total += numero(r['quantidade']);
    }
    return total;
  }

  static String assinatura(ItemEstimativaFinanceira regra) {
    dynamic ordenar(dynamic v) {
      if (v is Map) {
        return {
          for (final k in (v.keys.map((k) => k.toString()).toList()..sort()))
            k: ordenar(v[k])
        };
      }
      if (v is List) return v.map(ordenar).toList();
      return v;
    }

    return jsonEncode(ordenar(regra.toPlanejamento()..remove('preco')));
  }

  List<String> analisarGrupos(
      Map<String, dynamic> config,
      List<ItemEstimativaFinanceira> regras,
      ConvidadosEquivalentes padrao,
      PerfilFesta perfil,
      int duracao,
      double? margem) {
    final avisos = <String>[];
    final pessoas = publico(config, padrao);
    final grupos = lista(config['grupos']);
    for (final k in ['adultos', 'criancas', 'bebes']) {
      final limite = switch (k) {
        'adultos' => pessoas.adultos,
        'criancas' => pessoas.criancas,
        _ => pessoas.bebes
      };
      if (grupos.fold<int>(0, (s, g) => s + inteiro(g[k])) > limite) {
        avisos.add('Grupos alimentares superam o público: confira $k.');
      }
    }
    final totais = <String, double>{};
    for (final g in grupos) {
      final cobertura = {'adultos': 0.0, 'criancas': 0.0, 'bebes': 0.0};
      final grupo = ConvidadosEquivalentes(
          adultos: inteiro(g['adultos']),
          criancas: inteiro(g['criancas']),
          bebes: inteiro(g['bebes']));
      final alocacoes = mapa(g['itens']);
      for (final entry in alocacoes.entries) {
        final a = mapa(entry.value);
        final qtd = numero(a['quantidade']);
        if (qtd == 0) continue;
        final candidatas = regras.where((r) =>
            r.selecionado && r.premissas['id_item_cardapio'] == entry.key);
        if (candidatas.length != 1 ||
            a['assinatura'] != assinatura(candidatas.single)) {
          avisos.add(
              '${g['nome']}: item ou porção alterado; confira a destinação.');
          continue;
        }
        final r = candidatas.single;
        final destinado = mapa(mapa(config['destinos_itens'])[entry.key]);
        if (destinado['modo'] == 'demais' ||
            (destinado['modo'] == 'grupos' &&
                !(destinado['grupos'] as List? ?? []).contains(g['id']))) {
          avisos.add(
              '${g['nome']}: ${r.nome} está destinado a outros participantes.');
          continue;
        }
        totais[r.id] = (totais[r.id] ?? 0) + qtd;
        if (a['conferido'] != true) {
          avisos.add(
              '${g['nome']}: confirme ingredientes, preparo e contato cruzado de ${r.nome}.');
          continue;
        }
        if (config['servico'] == 'lanche'
            ? r.tipoItem != 'bebida' &&
                r.premissas['papel_na_refeicao'] != 'bebida'
            : r.premissas['papel_na_refeicao'] == 'principal') {
          final necessidade = r
              .copyWith(
                  premissas: {...r.premissas, 'fator_composicao': 1.0}
                    ..remove('publico_refeicao'))
              .calcularQuantidadeComMargem(
                  convidados: grupo,
                  perfil: perfil,
                  duracaoHoras: duracao,
                  margemPersonalizada: margem);
          if (necessidade > 0) {
            for (final idade in cobertura.keys) {
              if (inteiro(g[idade]) > 0 &&
                  (RevisaoCardapioService.normalizar(r.publicoAlvo) ==
                          'todos' ||
                      RevisaoCardapioService.normalizar(r.publicoAlvo) ==
                          idade)) {
                cobertura[idade] = cobertura[idade]! + qtd / necessidade;
              }
            }
          }
        }
      }
      for (final idade in cobertura.keys) {
        if (inteiro(g[idade]) > 0 && cobertura[idade]! < 1 - 1e-9) {
          avisos.add(
              '${g['nome']}: porção de ${config['servico'] == 'lanche' ? 'alimento' : 'prato principal'} destinada ao grupo ainda insuficiente para $idade na referência configurada.');
        }
      }
    }
    for (final r in regras) {
      final necessidade = r.calcularQuantidadeComMargem(
          convidados: pessoas,
          perfil: perfil,
          duracaoHoras: duracao,
          margemPersonalizada: margem);
      if ((totais[r.id] ?? 0) > necessidade + 1e-9) {
        avisos.add(
            '${r.nome}: os grupos reservam mais que a quantidade calculada.');
      }
    }
    if (grupos.isNotEmpty) {
      final publicoBase = {
        'adultos': pessoas.adultos,
        'criancas': pessoas.criancas,
        'bebes': pessoas.bebes
      };
      for (final idade in publicoBase.keys) {
        final restantes = publicoBase[idade]! -
            grupos.fold<int>(0, (s, g) => s + inteiro(g[idade]));
        if (restantes <= 0) continue;
        final opcoes = regras.where((r) {
          final alvo = mapa(
              mapa(config['destinos_itens'])[r.premissas['id_item_cardapio']]);
          final papel = r.premissas['papel_na_refeicao'];
          return r.selecionado &&
              !r.descartavel &&
              (config['servico'] == 'lanche'
                  ? r.tipoItem != 'bebida' && papel != 'bebida'
                  : papel == 'principal') &&
              (r.publicoAlvo == 'todos' || r.publicoAlvo == idade) &&
              (alvo['modo'] ?? 'todos') != 'grupos';
        });
        if (opcoes.isEmpty) {
          avisos.add(
              'Demais participantes ($idade): falta uma opção de ${config['servico'] == 'lanche' ? 'alimento' : 'prato principal'} calculada para esse público.');
        }
      }
    }
    return avisos.toSet().toList();
  }
}
