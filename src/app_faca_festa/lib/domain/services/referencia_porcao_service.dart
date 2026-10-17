import '../entities/estimativa_financeira.dart';
import 'revisao_cardapio_service.dart';

class ReferenciaPorcao {
  final String id, nome, papel, estado, fonte;
  final List<String> aliases;
  final double minimo, maximo;
  final UnidadeEstimativa unidade;
  final String contexto, verificadoEm;
  const ReferenciaPorcao(this.id, this.nome, this.aliases, this.papel,
      this.estado, this.minimo, this.maximo, this.fonte,
      {this.unidade = UnidadeEstimativa.quilo,
      this.contexto = 'Refeição com papel e estado indicados',
      this.verificadoEm = '2026-10-16'});
}

/// Referências culinárias contextuais. Ausência de contexto não gera um número.
class ReferenciaPorcaoService {
  const ReferenciaPorcaoService();
  static const fonteCristal =
      'https://cristalalimentos.com.br/quanto-preparar-como-calcular-arroz-feijao-e-macarrao-sem-desperdicio/';
  static const fonteChurrasco =
      'https://www.assai.com.br/blog/churrasco-no-assai-atacadista';
  static const fonteSenar =
      'https://www.sistemafaep.org.br/wp-content/uploads/2026/01/PR.0391-A-arte-do-churrasco-basico_web.pdf#page=13';
  static const fonteBrasileira =
      'https://padariabrasileira.com.br/wp-content/uploads/2023/11/V7_cardapio_encomenda_19x22cm_FINAL.pdf#page=11';
  static const referencias = [
    ReferenciaPorcao(
        'brasileira_salgados_festa_v1',
        'Salgados pequenos — festa de 3 a 4 horas',
        ['salgados pequenos', 'salgadinhos'],
        'outro',
        'pronto',
        8,
        10,
        fonteBrasileira,
        unidade: UnidadeEstimativa.unidade,
        contexto:
            'Coquetel/festa de 3 a 4 horas sem as combinações de lanches da tabela. Total das variedades, não por sabor.'),
    ReferenciaPorcao(
        'brasileira_salgados_empresarial_v1',
        'Salgados pequenos — evento de 30 a 40 minutos',
        ['salgados pequenos', 'salgadinhos'],
        'outro',
        'pronto',
        6,
        8,
        fonteBrasileira,
        unidade: UnidadeEstimativa.unidade,
        contexto:
            'Serviço empresarial de 30 a 40 minutos. Não equivale a uma festa de várias horas; total das variedades.'),
    ReferenciaPorcao(
        'brasileira_frios_tabua_v1',
        'Tábua de frios e queijos',
        ['tabua de frios', 'frios e queijos'],
        'outro',
        'pronto',
        .10,
        .12,
        fonteBrasileira,
        contexto:
            'Tábua incluindo queijos; total dos frios. Não aplicar a cada variedade nem substituir silenciosamente as combinações com pães/lanches da fonte.'),
    ReferenciaPorcao(
        'senar_churrasco_assado_total_2025_v1',
        'Churrasco — total de carnes já assadas',
        ['churrasco', 'carnes do churrasco'],
        'principal',
        'pronto',
        .30,
        .35,
        fonteSenar,
        contexto:
            'SENAR-PR, 2025, p. 11: total de carnes assadas por adulto. Não usar essa porção para cada corte. A compra crua exige rendimento medido da mistura; não usamos as perdas genéricas da fonte como medição da sua receita.'),
    ReferenciaPorcao(
        'brasileira_bolo_festa_v1',
        'Bolo de festa servido',
        ['bolo', 'bolo de festa', 'bolo de aniversario'],
        'outro',
        'pronto',
        .10,
        .15,
        fonteBrasileira,
        contexto:
            'Bolo pronto por participante que comerá bolo; faixa da tabela de eventos. O aplicativo não reduz automaticamente presenças.'),
    ReferenciaPorcao(
        'assai_agua_churrasco_curto_v1',
        'Água — churrasco curto/médio',
        ['agua', 'agua mineral'],
        'bebida',
        'pronto',
        .5,
        .5,
        fonteChurrasco,
        unidade: UnidadeEstimativa.litro,
        contexto:
            'Churrasco de curta/média duração; água por participante. A fonte não define horas nem pesos para crianças/bebês.'),
    ReferenciaPorcao('assai_agua_churrasco_longo_v1', 'Água — churrasco longo',
        ['agua', 'agua mineral'], 'bebida', 'pronto', 1, 1, fonteChurrasco,
        unidade: UnidadeEstimativa.litro,
        contexto:
            'Churrasco de longa duração; a fonte não define um limite de horas. Confirme que este contexto corresponde ao serviço.'),
    ReferenciaPorcao(
        'assai_refrigerante_churrasco_v1',
        'Refrigerante — churrasco',
        ['refrigerante'],
        'bebida',
        'pronto',
        1,
        1,
        fonteChurrasco,
        unidade: UnidadeEstimativa.litro,
        contexto:
            'Churrasco com outras bebidas. Porção da bebida no serviço inteiro; não aplicar separadamente a cada sabor.'),
    ReferenciaPorcao('cristal_arroz_acompanhamento_v1', 'Arroz', ['arroz'],
        'acompanhamento', 'cru', .05, .06, fonteCristal),
    ReferenciaPorcao('cristal_feijao_acompanhamento_v1', 'Feijão', ['feijao'],
        'acompanhamento', 'cru', .05, .07, fonteCristal),
    ReferenciaPorcao('cristal_massa_principal_v1', 'Macarrão', ['macarrao'],
        'principal', 'seco', .10, .10, fonteCristal),
    ReferenciaPorcao(
        'barilla_massa_seca_v1',
        'Massa seca (guia Barilla)',
        ['penne', 'fusilli', 'farfalle', 'spaghetti', 'espaguete', 'macarrao'],
        'principal',
        'seco',
        .08,
        .08,
        'https://www.barilla.com/pt-br/ajuda-com/novidades/guia-medidor-de-massa'),
    ReferenciaPorcao(
        'brasileira_docinhos_mesa_v1',
        'Docinhos da mesa (total de variedades)',
        ['docinhos', 'doces de festa'],
        'outro',
        'pronto',
        5,
        5,
        fonteBrasileira,
        unidade: UnidadeEstimativa.unidade),
  ];

  List<ReferenciaPorcao> buscar(String nome, String papel) => referencias
      .where((r) =>
          r.papel == papel &&
          r.aliases.contains(RevisaoCardapioService.normalizar(nome)))
      .toList();

  static double rendimentoMedido(double entrada, double saida) {
    if (!entrada.isFinite || !saida.isFinite || entrada <= 0 || saida <= 0) {
      throw ArgumentError(
          'Informe pesos medidos maiores que zero, na mesma unidade.');
    }
    return saida / entrada;
  }

  ItemEstimativaFinanceira aplicar(
      {required ItemEstimativaFinanceira item,
      required ReferenciaPorcao referencia,
      required double porcao,
      required String estadoDestino,
      double? pesoBase,
      double? pesoPronto}) {
    if (!buscar(item.nome, referencia.papel).contains(referencia) ||
        !porcao.isFinite ||
        porcao < referencia.minimo ||
        porcao > referencia.maximo ||
        item.unidade != referencia.unidade) {
      throw ArgumentError(
          'Referência incompatível com item, porção ou unidade.');
    }
    var fator = 1.0;
    if (estadoDestino != referencia.estado) {
      if (estadoDestino != 'pronto' || pesoBase == null || pesoPronto == null) {
        throw ArgumentError('A conversão para pronto exige rendimento medido.');
      }
      fator = rendimentoMedido(pesoBase, pesoPronto);
    }
    final mudouCompra =
        (item.premissas['estado_compra'] ?? item.premissas['estado']) !=
                estadoDestino ||
            item.rendimento != 1;
    return item.copyWith(
        valorUnitarioMedio: mudouCompra ? 0 : item.valorUnitarioMedio,
        quantidadePorConvidadoEquivalente: porcao * fator,
        premissas: {
          ...item.premissas,
          'referencia_contextual': referencia.id, 'referencia_versao': 1,
          'referencia_contexto': referencia.contexto,
          'referencia_verificada_em': referencia.verificadoEm,
          'origem': 'referencia_contextual', 'fonte': referencia.fonte,
          'papel_na_refeicao': referencia.papel, 'estado': estadoDestino,
          'estado_compra': estadoDestino,
          'unidade_consumo': referencia.unidade.label,
          'referencia_unidade_consumo': referencia.unidade.label,
          'nome_referencia': item.nome,
          'consumo_min': referencia.minimo * fator,
          'consumo_max': referencia.maximo * fator,
          'referencia_estado_original': referencia.estado,
          'rendimento_preparo_referencia': fator,
          if (pesoBase != null && pesoPronto != null) ...{
            'peso_base_medido': pesoBase,
            'peso_pronto_medido': pesoPronto,
          },
          // A referência já é expressa na medida de compra escolhida.
          'rendimento': 1.0, 'dividir_grupo': false,
          'ajustar_por_duracao': false, 'ajustar_por_perfil': false,
          'revisada_pelo_organizador': true,
        });
  }
}
