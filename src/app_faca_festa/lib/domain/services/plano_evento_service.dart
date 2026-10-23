import '../entities/ocorrencia_servico.dart';
import 'memoria_calculadora_service.dart';
import '../entities/calculadora_festa.dart';
import '../entities/calculadora_festa_item.dart';
import '../entities/cardapio.dart';
import '../entities/cardapio_item.dart';
import '../entities/estimativa_financeira.dart';
import '../entities/convidados_equivalentes.dart';
import 'calculadora_festa_service.dart';
import 'composicao_refeicao_service.dart';
import 'operacao_calculadora_service.dart';
import 'proposta_refeicao_service.dart';
import '../entities/referencia_contextual.dart';

enum FormatoPlanoInicial { automatico, lanche, churrasco, coquetel, refeicao }

class DestinoPlanoEvento {
  const DestinoPlanoEvento(
      {required this.cardapio,
      required this.proposta,
      required this.resultados,
      required this.pessoas,
      required this.itens,
      required this.pendencias,
      this.sugerido = false,
      this.publicoEspecifico = false});
  final Cardapio cardapio;
  final PropostaRefeicao proposta;
  final List<CalculadoraFestaItem> resultados;
  final List<CardapioItem> itens;
  final List<String> pendencias;
  final int pessoas;
  final bool sugerido;
  final bool publicoEspecifico;
}

class PlanoInicialEvento {
  const PlanoInicialEvento(
      {required this.destinos,
      required this.pendencias,
      required this.publicoInformado,
      required this.orcamento,
      required this.tipoEvento});
  final List<DestinoPlanoEvento> destinos;
  final List<String> pendencias;
  final bool publicoInformado;
  final double? orcamento;
  final String tipoEvento;
  int get itensCalculados =>
      destinos.fold(0, (n, d) => n + d.resultados.length);
}

/// Prévia do conjunto, sem selecionar outro cardápio no editor e sem gravar.
/// Reutiliza as referências e receitas disponíveis, sem preços inventados.
class PlanoEventoService {
  const PlanoEventoService();

  PlanoInicialEvento gerar({
    required CalculadoraFesta calculo,
    required List<Cardapio> cardapios,
    required Map<String, List<CardapioItem>> itensPorCardapio,
    required List<ItemEstimativaFinanceira> regras,
    Map<String, dynamic> operacao = const {},
    Map<String, Map<String, String>> respostas = const {},
    bool consultaCompleta = true,
    FormatoPlanoInicial formato = FormatoPlanoInicial.automatico,
    CatalogoContextual? catalogo,
    String? modeloReferencia,
  }) {
    const motor = OperacaoCalculadoraService();
    final existentes = cardapios
        .where((c) =>
            c.ativo && !c.somenteModelo && c.idEvento == calculo.idEvento)
        .toList();
    final semCardapio = existentes.isEmpty;
    final haModelos = cardapios.any(
        (c) => c.ativo && c.somenteModelo && c.idEvento == calculo.idEvento);
    final escolhido = formato;
    final modelosCompativeis =
        catalogo?.modelos.where((r) => r.chave == modeloReferencia).toList() ??
            <ReferenciaContextual>[];
    final modeloPublicado =
        modelosCompativeis.length == 1 ? modelosCompativeis.single : null;
    final temFormato = catalogo == null
        ? escolhido != FormatoPlanoInicial.automatico
        : modeloPublicado != null;
    final modelos = switch (escolhido) {
      FormatoPlanoInicial.churrasco => {
          'carne': 'Churrasco',
          'arroz': 'Arroz',
          'massa': 'Macarrão'
        },
      FormatoPlanoInicial.coquetel => {
          'salgados': 'Salgadinhos',
          'bolo': 'Bolo',
          'docinhos': 'Docinhos'
        },
      FormatoPlanoInicial.refeicao => {
          'arroz': 'Arroz',
          'feijao': 'Feijão',
          'massa': 'Macarrão'
        },
      _ => {'dog': 'Cachorro-quente', 'frutas': 'Frutas'},
    };
    final titulo = switch (escolhido) {
      FormatoPlanoInicial.churrasco => 'Churrasco sugerido',
      FormatoPlanoInicial.coquetel => 'Coquetel sugerido',
      FormatoPlanoInicial.refeicao => 'Refeição sugerida',
      _ => 'Lanche sugerido',
    };
    final sugerido = Cardapio(
        idCardapio: 'previa_evento',
        idEvento: calculo.idEvento,
        titulo: modeloPublicado?.nome ?? titulo,
        escopo: EscopoCardapio.refeicao);
    final destinos = <DestinoPlanoEvento>[];
    final pendencias = <String>[
      if (haModelos && existentes.isEmpty)
        'Há modelos disponíveis. Adicione ocorrências à agenda; o modelo não conta como serviço.',
      if (!consultaCompleta)
        'A consulta do evento está incompleta. A prévia pode omitir itens; atualize antes de decidir.',
      if (calculo.totalConvidados <= 0)
        'Escolha o público para transformar as porções em quantidades. Orçamento sozinho não determina quantas pessoas atender.',
      if (semCardapio && consultaCompleta)
        temFormato
            ? 'Modelo escolhido para revisão. Criar depende da sua confirmação.'
            : 'Escolha um modelo aprovado ou mantenha um cardápio livre. O tipo do evento não determina o formato.',
      if (catalogo?.aviso.isNotEmpty == true) catalogo!.aviso,
      if (calculo.orcamentoDisponivel == null)
        'Orçamento não definido: a proposta é quantitativa.',
      'O cabimento no orçamento depende da verba de alimentação, dos demais serviços e dos custos compatíveis. Preço ausente permanece pendente.',
    ];
    for (final original in semCardapio
        ? (consultaCompleta && !haModelos && temFormato
            ? [sugerido]
            : <Cardapio>[])
        : existentes) {
      final config = motor.refeicao(operacao, original.idCardapio);
      final o = config['ocorrencia'];
      final menu = o is Map
          ? original.copyWith(
              titulo: OcorrenciaServico.fromMap(Map<String, dynamic>.from(o))
                  .resumo)
          : original;
      final itens = semCardapio && modeloPublicado != null
          ? <CardapioItem>[
              for (final (index, m)
                  in (modeloPublicado.dados['itens'] as List).indexed)
                CardapioItem(
                    idItem: 'sugestao_$index',
                    idEvento: calculo.idEvento,
                    idCardapio: menu.idCardapio,
                    nome: m['nome'],
                    publicoAlvo: PublicoAlvoCardapio.values.firstWhere((p) =>
                        p.name == modeloPublicado.lista('publicos').first),
                    tipo: TipoItemCardapio.values
                        .firstWhere((t) => t.name == m['tipo']))
            ]
          : semCardapio
              ? <CardapioItem>[
                  for (final entry in modelos.entries)
                    CardapioItem(
                        idItem: 'sugestao_${entry.key}',
                        idEvento: calculo.idEvento,
                        idCardapio: menu.idCardapio,
                        nome: entry.value,
                        tipo: entry.key == 'bolo'
                            ? TipoItemCardapio.bolo
                            : entry.key == 'docinhos'
                                ? TipoItemCardapio.sobremesa
                                : TipoItemCardapio.comida),
                ]
              : (itensPorCardapio[menu.idCardapio] ?? const <CardapioItem>[])
                  .where((i) =>
                      i.idEvento == calculo.idEvento &&
                      i.idCardapio == menu.idCardapio)
                  .toList();
      motor.validarRefeicao(config);
      final publicoPadrao = ConvidadosEquivalentes(
          adultos: calculo.totalAdultos,
          criancas: calculo.totalCriancas,
          bebes: calculo.totalBebes);
      final publico = motor.publico(config, publicoPadrao);
      final publicos = <String, String>{};
      final destinosItens =
          OperacaoCalculadoraService.mapa(config['destinos_itens']);
      for (final item in itens) {
        final d = OperacaoCalculadoraService.mapa(destinosItens[item.idItem]);
        final grupos = List<String>.from(d['grupos'] as List? ?? [])..sort();
        publicos[item.idItem] = '${d['modo'] ?? 'todos'}:${grupos.join(',')}';
      }
      // As respostas persistidas pertencem ao destino, nunca ao nome do alimento.
      final salvas = <String, String>{};
      for (final r in regras
          .where((r) => r.premissas['id_cardapio'] == menu.idCardapio)) {
        final v = r.premissas['proposta_respostas'];
        if (v is Map) {
          salvas.addAll(v.map((k, v) => MapEntry(k.toString(), v.toString())));
        }
      }
      final proposta = const PropostaRefeicaoService().gerar(
          catalogo: catalogo,
          contexto: {
            if (config['servico'] != null) 'servico': config['servico'],
            if (o is Map && o['formato'] != 'nao_definido')
              'formato': o['formato'],
            if (o is Map && o['hora_local'] != null)
              'hora_local': o['hora_local'],
            if (o is Map && o['duracao_minutos'] != null)
              'duracao_minutos': o['duracao_minutos'],
            if (modeloPublicado != null) ...{
              'servico': modeloPublicado.lista('servicos').single,
              'formato': modeloPublicado.lista('formatos').single
            },
          },
          itens: itens,
          // Regras de uma receita de outro destino não são candidatas por nome.
          regras: regras
              .where((r) =>
                  (r.premissas['id_evento'] == null ||
                      r.premissas['id_evento'] == calculo.idEvento) &&
                  (r.premissas['id_cardapio'] == null ||
                      r.premissas['id_cardapio'] == menu.idCardapio) &&
                  (r.premissas['origem'] != 'preferencia_privada' ||
                      (r.premissas['memoria_contexto'] ==
                              const MemoriaCalculadoraService().contexto(
                                  tipo: calculo.tipoEvento,
                                  refeicao: menu.titulo,
                                  duracao: calculo.duracaoHoras,
                                  escopo: menu.escopo.name,
                                  servico: config['servico']?.toString() ??
                                      'refeicao',
                                  itens: itens.map((i) => i.nome)) &&
                          OperacaoCalculadoraService.lista(config['grupos'])
                              .isEmpty &&
                          destinosItens.isEmpty)))
              .toList(),
          comporRefeicao: menu.escopo == EscopoCardapio.refeicao ||
              menu.escopo == EscopoCardapio.naoDefinido,
          respostas: {...salvas, ...?respostas[menu.idCardapio]},
          publicosDosItens: publicos);
      final locais = proposta.regras
          .map((r) => motor.regraComPublico(
              modeloPublicado == null
                  ? r
                  : r.copyWith(premissas: {
                      ...r.premissas,
                      'modelo_snapshot': modeloPublicado.dados
                    }),
              config,
              publicoPadrao))
          .toList();
      final compostas = const ComposicaoRefeicaoService().compor(locais);
      final resultados = const CalculadoraFestaService().calcularItens(
          calculo: calculo.copyWith(
              totalAdultos: publico.adultos,
              totalCriancas: publico.criancas,
              totalBebes: publico.bebes),
          itensBase: compostas);
      destinos.add(DestinoPlanoEvento(
          cardapio: menu,
          proposta: PropostaRefeicao(
              locais,
              proposta.perguntas,
              proposta.pendencias,
              proposta.motivos,
              proposta.respostas,
              proposta.preservados),
          resultados: resultados,
          pessoas: publico.totalInformado,
          itens: itens,
          sugerido: semCardapio,
          publicoEspecifico: config['publico'] != null ||
              OperacaoCalculadoraService.lista(config['grupos']).isNotEmpty ||
              destinosItens.values.any((d) =>
                  OperacaoCalculadoraService.mapa(d)['modo'] != 'todos') ||
              menu.escopo == EscopoCardapio.compartilhado,
          pendencias: [
            ...proposta.pendencias,
            if (config['ocorrencia'] == null && !semCardapio)
              'Agenda em aberto: complete data, horário e duração deste serviço quando souber.',
            if (config['ocorrencia'] is Map &&
                config['ocorrencia']['duracao_minutos'] == null &&
                locais.any((r) => r.ajustarPorDuracao))
              'Duração do serviço em aberto: porções sem ajuste de tempo, sem usar a duração global.',
            ...motor.analisarGrupos(
                config,
                compostas,
                publicoPadrao,
                calculo.perfilFesta,
                calculo.duracaoHoras,
                calculo.margemPersonalizada),
            if (!semCardapio && !itensPorCardapio.containsKey(menu.idCardapio))
              'Itens ainda não carregados.',
            if (itens.isEmpty) 'Cardápio sem itens para calcular.',
            if (semCardapio && escolhido == FormatoPlanoInicial.refeicao)
              'Base de acompanhamentos: escolha também o prato principal e os vegetais.',
            if (semCardapio)
              'Bebidas, demais serviços e necessidades alimentares ainda precisam ser considerados.',
            if (menu.escopo == EscopoCardapio.compartilhado)
              'Serviço compartilhado: confirme os destinos; a prévia não multiplica pela quantidade de refeições.',
            if (menu.escopo == EscopoCardapio.naoDefinido)
              'Escopo ainda não definido. Confira se este cardápio representa uma refeição.',
          ]));
    }
    return PlanoInicialEvento(
        destinos: List.unmodifiable(destinos),
        pendencias: List.unmodifiable(pendencias),
        publicoInformado: calculo.totalConvidados > 0,
        orcamento: calculo.orcamentoDisponivel,
        tipoEvento: calculo.tipoEvento);
  }
}
