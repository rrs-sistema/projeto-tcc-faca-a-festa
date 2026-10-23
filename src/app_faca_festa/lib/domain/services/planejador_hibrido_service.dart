import '../entities/contexto_servico_planejador.dart';
import '../entities/referencia_contextual.dart';
import '../entities/estimativa_financeira.dart';
import '../entities/calculadora_festa_item.dart';
import 'consumo_observado_service.dart';
import 'proposta_refeicao_service.dart';
import 'prioridade_perguntas_service.dart';
import 'revisao_cardapio_service.dart';

class ResultadoPlanejadorHibrido {
  const ResultadoPlanejadorHibrido(
      this.principal,
      this.alternativa,
      this.perguntas,
      this.origens,
      this.pendencias,
      this.recomendacao,
      this.financeiroCompleto);
  final PropostaRefeicao principal;
  final PropostaRefeicao? alternativa;
  final List<PerguntaComImpacto> perguntas;
  final Map<String, String> origens;
  final List<String> pendencias;
  final String? recomendacao;
  final bool financeiroCompleto;
}

/// Recuperação, proposta e simulação são puras. Aplicação pertence ao repositório.
class PlanejadorHibridoService {
  const PlanejadorHibridoService();
  ResultadoPlanejadorHibrido gerar(
      {required ContextoServicoPlanejador contexto,
      required CatalogoContextual catalogo,
      Map<String, String> respostas = const {},
      Map<String, ResumoConsumoObservado> observados = const {},
      Map<String, ItemEstimativaFinanceira> basesObservadas = const {},
      required List<CalculadoraFestaItem> Function(PropostaRefeicao)
          calcular}) {
    final origens = <String, String>{};
    final objetivo = respostas['objetivo'] ?? contexto.objetivo;
    PropostaRefeicao montar(Map<String, String> r) {
      final perguntas = <PerguntaProposta>[], adotadas = <String>{};
      final regras = <ItemEstimativaFinanceira>[];
      perguntas.add(const PerguntaProposta(
          'objetivo',
          'O que deseja revisar neste serviço?',
          {
            '': 'Escolha um objetivo',
            'manter_receitas': 'Manter minhas receitas',
            'comparar_quantidades':
                'Comparar quantidades de referências compatíveis',
            'avaliar_custo': 'Avaliar o custo com preços conhecidos'
          },
          '',
          obrigatoria: true));
      final infraestrutura = <String, bool?>{...contexto.infraestrutura};
      final possiveis = catalogo.referencias
          .where((ref) =>
              contexto.itens.any((i) => !i.confirmado && ref.reconhece(i.nome)))
          .toList();
      for (final recurso in ContextoServicoPlanejador.recursos) {
        final resposta = r['infra_$recurso'];
        if (resposta != null) {
          infraestrutura[recurso] = resposta == 'sim'
              ? true
              : resposta == 'nao'
                  ? false
                  : null;
        }
        if (possiveis.any((ref) =>
            (ref.dados['infraestrutura'] as List? ?? []).contains(recurso))) {
          perguntas.add(PerguntaProposta(
              'infra_$recurso',
              'Há ${recurso.replaceAll('_', ' ')} para este serviço?',
              const {'': 'Ainda não declarado', 'sim': 'Sim', 'nao': 'Não'},
              '',
              obrigatoria: true));
        }
      }
      for (final item in contexto.itens.where((i) => i.confirmado)) {
        origens[item.idItem] =
            'Quantidade final confirmada preservada: ${item.quantidadeFinal} ${item.unidade}.';
      }
      for (final item in contexto.itens.where((i) => !i.confirmado)) {
        final existentes = contexto.regras
            .where((regra) =>
                (regra.premissas['id_evento'] == null ||
                    regra.premissas['id_evento'] == contexto.evento) &&
                (regra.premissas['id_cardapio'] == null ||
                    regra.premissas['id_cardapio'] == contexto.cardapio))
            .toList();
        final existente =
            const RevisaoCardapioService().regraPara(item, existentes);
        final atual = existente ?? basesObservadas[item.idItem];
        final propria = existente != null &&
            atual != null &&
            (atual.premissas['revisada_pelo_organizador'] == true ||
                atual.premissas['receita']?.toString().trim().isNotEmpty ==
                    true ||
                existentes.any((original) =>
                    original.id == atual.id &&
                    original.id == 'menu_${item.idCardapio}_${item.idItem}'));
        if (propria) {
          regras.add(atual);
          origens[item.idItem] = atual.premissas['origem'] ==
                  'preferencia_privada'
              ? 'Receita privada confirmada; preferência não é consumo observado.'
              : 'Decisão ou receita confirmada preservada.';
          continue;
        }
        final resumo = observados[item.idItem];
        if (atual != null && resumo?.podeAdotar == true) {
          perguntas.add(PerguntaProposta(
              'origem_${item.idItem}',
              'Qual base usar para ${item.nome}?',
              const {
                '': 'Escolha a origem',
                'observado': 'Oferecer consumo observado compatível',
                'referencia': 'Consultar referência aprovada'
              },
              '',
              obrigatoria: true));
          if (r['origem_${item.idItem}'] == 'observado') {
            final aplicada =
                const ConsumoObservadoService().aplicar(atual, resumo!);
            final adotada = aplicada.copyWith(
                id: 'menu_${item.idCardapio}_${item.idItem}',
                valorUnitarioMedio: 0,
                premissas: {
                  ...aplicada.premissas,
                  'id_evento': contexto.evento,
                  'id_cardapio': contexto.cardapio,
                  'id_item_cardapio': item.idItem,
                  'contexto_consumo': resumo.amostras.first.contexto
                });
            regras.add(adotada);
            adotadas.add(adotada.id);
            origens[item.idItem] =
                'Proposta de adoção de ${resumo.amostras.length} eventos privados compatíveis; exige confirmação.';
            continue;
          }
        }
        origens[item.idItem] =
            'Referência contextual, se houver cobertura; caso contrário, configuração manual pendente.';
      }
      final itensRevisar = contexto.itens.where((i) => !i.confirmado).toList();
      final cobertos = itensRevisar.every((i) => regras
          .any((regra) => regra.premissas['id_item_cardapio'] == i.idItem));
      if (cobertos) perguntas.removeWhere((q) => q.id.startsWith('infra_'));
      final base = cobertos
          ? PropostaRefeicao(
              regras,
              [],
              [],
              {
                for (final regra in regras)
                  regra.id:
                      '${origens[regra.premissas['id_item_cardapio']]} Fonte: ${regra.premissas['fonte'] ?? 'decisão do organizador'}.'
              },
              r,
              regras.map((regra) => regra.id).toSet())
          : const PropostaRefeicaoService().gerar(
              itens: contexto.itens.where((i) => !i.confirmado).toList(),
              regras: regras,
              catalogo: catalogo,
              contexto: {
                ...contexto.referencia,
                'infraestrutura': infraestrutura
              },
              respostas: r);
      return PropostaRefeicao(
          base.regras.map((regra) {
            final originais = contexto.regras.where((original) =>
                original.id == regra.id &&
                base.preservados.contains(regra.id) &&
                !adotadas.contains(regra.id));
            return originais.isEmpty ? regra : originais.first;
          }).toList(),
          [...perguntas, ...base.perguntas],
          base.pendencias,
          {
            ...base.motivos,
            for (final regra in base.regras)
              if (adotadas.contains(regra.id))
                regra.id:
                    'Consumo privado comparável oferecido para adoção; não é confiança calibrada.'
          },
          {...r, ...base.respostas},
          base.preservados.difference(adotadas));
    }

    final principal = montar(respostas), resultados = calcular(principal);
    final completo = resultados.isNotEmpty &&
        resultados.length == contexto.itens.length &&
        resultados
            .every((r) => r.valorUnitarioMedio > 0 && r.custoEstimado.isFinite);
    final pendencias = <String>[
      ...principal.pendencias,
      if (!ContextoServicoPlanejador.objetivos.contains(objetivo))
        'Confirme o objetivo antes de apresentar recomendação.',
      if (!completo)
        'Custo pendente: quantidade sustentada por referência pode ser calculada sem concluir a avaliação financeira.',
      if (contexto.grupos.isNotEmpty)
        'Necessidades alimentares exigem composição e preparo conferidos por destino; o nome não comprova adequação.',
    ];
    PropostaRefeicao? alternativa;
    if (objetivo == 'comparar_quantidades' && principal.regras.isNotEmpty) {
      for (final q
          in principal.perguntas.where((q) => q.id.startsWith('referencia_'))) {
        for (final opcao in q.opcoes.keys
            .where((k) => k.isNotEmpty && k != principal.respostas[q.id])) {
          final outra = montar({...principal.respostas, q.id: opcao});
          final valores = calcular(outra);
          if (outra.regras.length == principal.regras.length &&
              valores.length == resultados.length &&
              valores.any((v) => resultados.any((a) =>
                  a.idItemCardapio == v.idItemCardapio &&
                  a.unidade == v.unidade &&
                  (a.quantidade - v.quantidade).abs() > 1e-9))) {
            alternativa = outra;
            break;
          }
        }
        if (alternativa != null) break;
      }
    }
    final prioridades = const PrioridadePerguntasService().ordenar(
        proposta: principal,
        respostasExplicitas: respostas,
        gerar: montar,
        calcular: calcular);
    montar(respostas);
    return ResultadoPlanejadorHibrido(
        principal,
        alternativa,
        prioridades,
        origens,
        pendencias,
        ContextoServicoPlanejador.objetivos.contains(objetivo) &&
                principal.regras.isNotEmpty
            ? objetivo == 'comparar_quantidades'
                ? 'Comparação quantitativa com a mesma reserva e o mesmo público; não comprova economia.'
                : objetivo == 'avaliar_custo' && !completo
                    ? 'Prévia quantitativa; a conclusão financeira permanece pendente.'
                    : 'Manter as decisões e receitas já confirmadas, revisando apenas lacunas.'
            : null,
        completo);
  }
}
