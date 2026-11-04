import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/data/models/avaliacao/avaliacao_model.dart';
import 'package:app_faca_festa/data/models/fornecedor/avaliacao_servico_model.dart';
import 'package:app_faca_festa/data/models/fornecedor/fornecedor_model.dart';
import 'package:app_faca_festa/data/models/servico_produto/fornecedor_produto_servico_model.dart';
import 'package:app_faca_festa/data/services/fornecedor_ai_service.dart';

void main() {
  test('legado permanece legível sem selo, data inventada ou nota não finita',
      () {
    final a = AvaliacaoModel.fromMap(
        {'id': 'antiga', 'nota': double.nan, 'comentario': 'Crítica original'});
    expect(a.verificada, false);
    expect(a.nota, 0);
    expect(a.comentario, 'Crítica original');
    expect(a.data.millisecondsSinceEpoch, 0);
    final b =
        AvaliacaoServicoModel.fromMap({'nota': 5, 'id_contrato': 'aparente'});
    expect(b.verificada, false);
    expect(
        AvaliacaoModel.fromMap({
          'schema': 2,
          'verificada': true,
          'id_contrato': 'aparente',
          'nota': 5
        }).verificada,
        false);
  });
  test('schema e moderação distinguem comentário verificado do histórico', () {
    final d = {
      'schema': 2,
      '_integridade_confirmada': true,
      'verificada': true,
      'nota': 4,
      'id_contrato': 'c',
      'comentario': 'Boa entrega'
    };
    final a = AvaliacaoModel.fromMap(d);
    expect(a.verificada, true);
    expect(a.idContrato, 'c');
    expect(a.copyWith().verificada, true);
    expect(AvaliacaoModel.fromMap({...d, 'moderacao': 'oculta'}).verificada,
        false);
  });
  test('cadastro lê somente agregado verificado e não tenta regravá-lo', () {
    final legado = FornecedorModel.fromMap({
      'media_avaliacoes': 5,
      'totalAvaliacoes': 99,
      'is_top_categoria': true
    });
    expect(legado.totalAvaliacoes, 0);
    expect(legado.mediaAvaliacoes, 0);
    expect(legado.isTopCategoria, false);
    final f = FornecedorModel.fromMap({
      'reputacao_verificada': {'schema': 2, 'media': 4.5, 'quantidade': 2}
    });
    expect(f.mediaAvaliacoes, 4.5);
    expect(f.totalAvaliacoes, 2);
    expect(f.toMap().containsKey('media_avaliacoes'), false);
    expect(f.toMap().containsKey('total_avaliacoes'), false);
  });
  test('serviço usa seu agregado separado do fornecedor e do legado', () {
    final s = FornecedorProdutoServicoModel.fromMap({
      'media_servico': 5,
      'total_avaliacoes_servico': 99,
      'reputacao_verificada': {'schema': 2, 'media': 2, 'quantidade': 1}
    });
    expect(s.mediaServico, 2);
    expect(s.totalAvaliacoesServico, 1);
    expect(s.toMap().containsKey('media_servico'), false);
  });
  test('resumo inteligente mantém o mesmo agregado, sem contar histórico', () {
    final f = FornecedorModel.fromMap({
      'reputacao_verificada': {'schema': 2, 'media': 4, 'quantidade': 1}
    });
    final r = FornecedorAiService()
        .gerarResumoSimplesReputacao(fornecedor: f, avaliacoes: [
      AvaliacaoServicoModel.fromMap({'nota': 1, 'comentario': 'Legado'})
    ]);
    expect(r.mediaGeral, 4);
    expect(r.totalAvaliacoes, 1);
  });
}
