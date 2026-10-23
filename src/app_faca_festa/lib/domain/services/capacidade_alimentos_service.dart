import 'plano_evento_service.dart';
import 'rendimento_referencia_service.dart';

class CustoAlimentosPlano {
  const CustoAlimentosPlano(this.conhecido, this.pendencias);
  final double conhecido;
  final List<String> pendencias;
  bool get completo => pendencias.isEmpty;
}

class CapacidadeAlimentos {
  const CapacidadeAlimentos(
      {this.pessoas, this.custo, this.motivo, this.limiteBusca = false});
  final int? pessoas;
  final double? custo;
  final String? motivo;
  final bool limiteBusca;
}

/// Compra integral dos alimentos deste cenário. Não calcula saldo financeiro,
/// não desconta estoque/serviços e não considera o limite do evento verba alimentar.
class CapacidadeAlimentosService {
  const CapacidadeAlimentosService();
  CustoAlimentosPlano custear(PlanoInicialEvento plano,
      {required bool consultaCompleta}) {
    final pendencias = <String>{};
    var custo = 0.0;
    if (!consultaCompleta) pendencias.add('Consulta do evento incompleta.');
    if (plano.destinos.isEmpty) {
      pendencias.add('Não há alimentos neste cenário.');
    }
    for (final d in plano.destinos) {
      final idsComRegra =
          d.proposta.regras.map((r) => r.premissas['id_item_cardapio']).toSet();
      if (d.itens.isEmpty ||
          d.itens.any((i) => !idsComRegra.contains(i.idItem)) ||
          d.resultados.length !=
              d.proposta.regras.where((r) => r.selecionado).length) {
        pendencias
            .add('${d.cardapio.titulo}: faltam quantidades ou referências.');
      }
      if (d.pendencias.isNotEmpty && d.proposta.pendencias.isNotEmpty) {
        pendencias
            .add('${d.cardapio.titulo}: confira as pendências da proposta.');
      }
      for (final r in d.resultados) {
        final regras = d.proposta.regras
            .where((p) => p.premissas['id_item_cardapio'] == r.idItemCardapio);
        if (regras.length != 1) {
          pendencias.add('${r.nome}: referência ambígua.');
          continue;
        }
        final regra = regras.single;
        if (!r.quantidade.isFinite || r.quantidade < 0) {
          pendencias.add('${r.nome}: quantidade inválida.');
          continue;
        }
        final estado = regra.premissas['estado'];
        final compra = regra.premissas['estado_compra'] ?? estado;
        if (!regra.descartavel &&
            (regra.premissas['proposta_apenas_servir'] == true ||
                !['cru', 'seco', 'pronto'].contains(compra) ||
                (estado != compra &&
                    regra.premissas['rendimento_medido'] != true &&
                    !const RendimentoReferenciaService().valida(regra)))) {
          pendencias.add('${r.nome}: medida de compra pendente.');
          continue;
        }
        if (!regra.precoCompativel ||
            !r.valorUnitarioMedio.isFinite ||
            r.valorUnitarioMedio <= 0 ||
            !r.custoEstimado.isFinite ||
            r.custoEstimado < 0) {
          pendencias.add('${r.nome}: preço compatível pendente.');
          continue;
        }
        custo += r.custoEstimado;
      }
    }
    if (!custo.isFinite) {
      pendencias.add('Custo fora do intervalo de cálculo.');
      custo = 0;
    }
    return CustoAlimentosPlano(custo, List.unmodifiable(pendencias));
  }

  CapacidadeAlimentos simular(
      {required double verba,
      required PlanoInicialEvento Function(int adultos) gerar,
      required bool consultaCompleta,
      bool publicoEspecifico = false,
      int teto = 10000}) {
    if (!verba.isFinite || verba <= 0 || teto < 1 || teto > 10000) {
      throw ArgumentError(
          'Informe verba positiva e limite de busca de até 10.000 pessoas.');
    }
    if (publicoEspecifico) {
      return const CapacidadeAlimentos(
          motivo:
              'Há públicos ou grupos específicos. A capacidade não pode ser extrapolada como um único público de adultos.');
    }
    final cache = <int, CustoAlimentosPlano>{};
    CustoAlimentosPlano custo(int n) => cache.putIfAbsent(n, () {
          final plano = gerar(n);
          if (plano.destinos
              .any((d) => d.publicoEspecifico || d.pessoas != n)) {
            return const CustoAlimentosPlano(0, [
              'Há públicos ou serviços específicos; não é possível extrapolar a capacidade de adultos.'
            ]);
          }
          return custear(plano, consultaCompleta: consultaCompleta);
        });
    final unidade = custo(1);
    if (!unidade.completo || unidade.conhecido <= 0) {
      return CapacidadeAlimentos(
          motivo: unidade.pendencias.isEmpty
              ? 'Custo por cenário indisponível.'
              : unidade.pendencias.join('\n'));
    }
    var menor = 0, maior = teto;
    while (menor < maior) {
      final meio = (menor + maior + 1) ~/ 2;
      final c = custo(meio);
      if (!c.completo) {
        return CapacidadeAlimentos(motivo: c.pendencias.join('\n'));
      }
      if (c.conhecido <= verba + 1e-9) {
        menor = meio;
      } else {
        maior = meio - 1;
      }
    }
    return CapacidadeAlimentos(
        pessoas: menor,
        custo: menor == 0 ? 0 : custo(menor).conhecido,
        limiteBusca: menor == teto);
  }
}
