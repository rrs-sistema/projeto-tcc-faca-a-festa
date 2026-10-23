import '../entities/referencia_contextual.dart';
import '../entities/cardapio_item.dart';
import '../entities/estimativa_financeira.dart';
import 'proposta_refeicao_service.dart';
import 'revisao_cardapio_service.dart';

class PropostaCatalogoService {
  const PropostaCatalogoService();
  PropostaRefeicao gerar(
      {required List<CardapioItem> itens,
      required List<ItemEstimativaFinanceira> regras,
      required CatalogoContextual catalogo,
      Map<String, dynamic> contexto = const {},
      Map<String, String> respostas = const {}}) {
    final saida = <ItemEstimativaFinanceira>[],
        perguntas = <PerguntaProposta>[],
        pendencias = <String>[];
    final motivos = <String, String>{},
        escolhas = <String, String>{},
        preservados = <String>{};
    String escolher(String id, String titulo, Map<String, String> opcoes,
        [String inicial = '']) {
      perguntas.add(PerguntaProposta(
          id, titulo, {'': 'Escolha para continuar', ...opcoes}, inicial,
          obrigatoria: inicial.isEmpty && opcoes.isNotEmpty));
      final v = opcoes.containsKey(respostas[id]) ? respostas[id]! : inicial;
      escolhas[id] = v;
      return v;
    }

    final servico = contexto['servico']?.toString() ??
        escolher('servico', 'Qual serviço será oferecido?',
            {'refeicao': 'Refeição', 'lanche': 'Intervalo ou lanche'});
    final formato = contexto['formato']?.toString() ??
        escolher('formato', 'Como será servido?', {
          'buffet': 'Buffet',
          'empratado': 'Empratado',
          'volante': 'Volante',
          'autosservico': 'Autosserviço'
        });
    if (catalogo.aviso.isNotEmpty) pendencias.add(catalogo.aviso);
    String? periodo = contexto['periodo'];
    if (catalogo.referencias
        .any((r) => !r.lista('periodos').contains('qualquer'))) {
      periodo ??= escolher('periodo', 'Período do serviço',
          {'manha': 'Manhã', 'tarde': 'Tarde', 'noite': 'Noite'});
    }
    int? minutos = contexto['duracao_minutos'];
    if (minutos == null &&
        catalogo.referencias.any((r) =>
            r.dados['duracao_minima'] != null ||
            r.dados['duracao_maxima'] != null)) {
      perguntas.add(const PerguntaProposta('duracao',
          'Duração deste serviço em minutos (se conhecida)', {}, ''));
      escolhas['duracao'] = respostas['duracao'] ?? '';
      minutos = int.tryParse(escolhas['duracao']!);
    }
    bool contextoPropostaMudou(ItemEstimativaFinanceira atual) {
      final ctx = atual.premissas['contexto_referencia'];
      if (ctx is! Map) return false;
      final fmt = ctx['formato']?.toString();
      final svc = ctx['servico']?.toString();
      return (fmt != null && fmt.isNotEmpty && fmt != formato) ||
          (svc != null && svc.isNotEmpty && svc != servico);
    }

    for (final item in itens) {
      final atual = const RevisaoCardapioService().regraPara(item, regras);
      final receitaManual =
          atual?.premissas['receita']?.toString().trim().isNotEmpty == true;
      final ajusteOrganizador =
          atual?.premissas['origem']?.toString() == 'ajuste_organizador';
      final candidataPreservar = atual != null &&
          (receitaManual ||
              ajusteOrganizador ||
              atual.premissas['revisada_pelo_organizador'] == true ||
              atual.id == 'menu_${item.idCardapio}_${item.idItem}');
      // Receita/ajuste manual ficam; proposta de catálogo regenera se formato/serviço mudou.
      if (candidataPreservar &&
          (receitaManual ||
              ajusteOrganizador ||
              !contextoPropostaMudou(atual))) {
        saida.add(atual);
        preservados.add(atual.id);
        motivos[atual.id] =
            'Regra confirmada preservada. Versão nova exige revisão explícita em outra regra.';
        continue;
      }
      final obtencao =
          escolher('obtencao_${item.idItem}', 'Como obter ${item.nome}?', {
        'servir': 'Calcular somente o que será servido',
        'pronto': 'Comprar pronto',
        'preparar': 'Comprar insumos e preparar'
      });
      final candidatos = catalogo.referencias.where((r) =>
          r.tipo == 'porcao' &&
          r.reconhece(item.nome) &&
          (r.dados['infraestrutura'] as List? ?? []).every(
              (k) => (contexto['infraestrutura'] as Map? ?? {})[k] == true) &&
          r.compativel(
              servico: servico,
              formato: formato,
              publico: item.publicoAlvo.name,
              obtencao: obtencao,
              periodo: periodo,
              hora: contexto['hora_local'],
              minutos: minutos));
      final opcoes = {
        for (final r in candidatos)
          r.chave: '${r.nome} · v${r.versao} · ${r.dados['contexto']}'
      };
      final selecionada = escolher('referencia_${item.idItem}',
          'Referência compatível para ${item.nome}', opcoes);
      final refs = candidatos.where((r) => r.chave == selecionada).toList();
      if (refs.isEmpty) {
        pendencias.add(
            '${item.nome}: confirme serviço, formato e obtenção; sem cobertura compatível, defina sua receita livremente. Nenhum número foi presumido.');
        continue;
      }
      final ref = refs.single, d = ref.dados;
      final unidade =
          UnidadeEstimativa.values.firstWhere((u) => u.name == d['unidade']);
      if (!const RevisaoCardapioService().unidadeInicial(item) &&
          RevisaoCardapioService.unidade(item.unidade) !=
              RevisaoCardapioService.unidade(unidade.label)) {
        pendencias.add(
            '${item.nome}: unidade planejada incompatível; ajuste explicitamente.');
        continue;
      }
      if (obtencao != 'servir' &&
          (obtencao == 'pronto' &&
                  (d['estado_compra'] != 'pronto' ||
                      d['estado_consumo'] != 'pronto') ||
              obtencao == 'preparar' && d['estado_compra'] == 'pronto')) {
        pendencias.add(
            '${item.nome}: esta referência não converte peso servido em compra crua. Informe ficha e rendimento medido.');
        continue;
      }
      ReferenciaContextual? conversao;
      if (obtencao == 'preparar' && d['estado_consumo'] != d['estado_compra']) {
        final rendimentos = catalogo.referencias
            .where((r) =>
                r.tipo == 'rendimento' &&
                r.reconhece(item.nome) &&
                r.dados['unidade'] == d['unidade'] &&
                r.dados['estado_consumo'] == d['estado_consumo'] &&
                r.dados['estado_compra'] == d['estado_compra'] &&
                r.compativel(
                    servico: servico,
                    formato: formato,
                    publico: item.publicoAlvo.name,
                    obtencao: obtencao,
                    periodo: periodo,
                    hora: contexto['hora_local'],
                    minutos: minutos))
            .toList();
        final chave = escolher('rendimento_${item.idItem}',
            'Rendimento aprovado da receita de ${item.nome}', {
          for (final r in rendimentos)
            r.chave: '${r.nome} · v${r.versao} · ${r.dados['contexto']}'
        });
        final escolhidos = rendimentos.where((r) => r.chave == chave).toList();
        if (escolhidos.isEmpty) {
          pendencias.add(
              '${item.nome}: peso servido não é compra crua. Escolha rendimento aprovado compatível ou informe sua medição na receita.');
          continue;
        }
        conversao = escolhidos.single;
      }
      final id = 'menu_${item.idCardapio}_${item.idItem}';
      saida.add(ItemEstimativaFinanceira(
          id: id,
          nome: item.nome,
          categoria: item.tipo == TipoItemCardapio.bebida ? 'bebida' : 'comida',
          tipoItem: item.tipo.name,
          publicoAlvo: item.publicoAlvo.name,
          unidade: unidade,
          quantidadePorConvidadoEquivalente: (d['padrao'] as num).toDouble(),
          valorUnitarioMedio: 0,
          premissas: {
            'id_evento': item.idEvento,
            'id_cardapio': item.idCardapio,
            'id_item_cardapio': item.idItem,
            'origem': 'catalogo_contextual',
            'proposta_refeicao': 2,
            'referencia_snapshot': d,
            'referencia_id': ref.id,
            'referencia_versao': ref.versao,
            'fonte': d['fonte'],
            'papel_na_refeicao': d['papel'],
            'estado': d['estado_consumo'],
            'estado_compra':
                obtencao == 'servir' ? d['estado_consumo'] : d['estado_compra'],
            'proposta_apenas_servir': obtencao == 'servir',
            'rendimento': conversao?.dados['padrao'] ?? 1,
            if (conversao != null) ...{
              'rendimento_snapshot': conversao.dados,
              'rendimento_referencia': conversao.id,
              'rendimento_fonte': conversao.dados['fonte'],
              'rendimento_estimado': true,
            },
            'rendimento_medido': false,
            'consumo_min': d['minimo'],
            'consumo_max': d['maximo'],
            'peso_crianca': 1.0,
            'peso_bebe': 1.0,
            'ajustar_por_duracao': false,
            'ajustar_por_perfil': false,
            'numero_servicos': 1,
            'contexto_referencia': {
              'servico': servico,
              'formato': formato,
              'obtencao': obtencao,
              'periodo': periodo,
              'hora_local': contexto['hora_local'],
              'duracao_minutos': minutos,
            },
            'proposta_respostas': escolhas
          }));
      motivos[id] =
          '${ref.nome} v${ref.versao}: ${d['contexto']} Limites: ${d['limitacoes']} Fonte: ${d['fonte']}';
    }
    return PropostaRefeicao(
        saida, perguntas, pendencias, motivos, escolhas, preservados);
  }
}
