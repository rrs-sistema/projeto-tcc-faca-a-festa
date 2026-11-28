import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/data/models/orcamento/orcamento_model.dart';
import 'package:app_faca_festa/data/models/orcamento/orcamento_gasto_model.dart';

void main() {
  test('orçamento e gasto leem a execução e o serviço gravados na contratação',
      () {
    final orcamento = OrcamentoModel.fromMap({
      'id_orcamento': 'orc',
      'id_produto_servico': 'servico',
      'estado_execucao': 'entrega_informada',
      'contrato_financeiro': {
        'id_contrato': 'contrato',
        'estado_execucao': 'aceito'
      },
    }).copyWith();
    expect(orcamento.idServicoFornecido, 'servico');
    expect(orcamento.estadoExecucao, 'aceito');
    expect(orcamento.idContrato, 'contrato');
    final gasto = OrcamentoGastoModel.fromMap({
      'id_servico_contratado': 'servico',
      'nome_servico_contratado': 'Arco floral',
    });
    expect(gasto.idServicoContratado, 'servico');
    expect(gasto.nomeServicoContratado, 'Arco floral');
  });
}
