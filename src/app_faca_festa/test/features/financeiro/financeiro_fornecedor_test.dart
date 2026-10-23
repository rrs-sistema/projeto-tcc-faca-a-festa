import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/domain/entities/financeiro/custo_interno_fornecedor.dart';
import 'package:app_faca_festa/domain/services/resumo_financeiro_fornecedor_service.dart';

void main() {
  const svc = ResumoFinanceiroFornecedorService();

  test('contrato 10k recebido 4k: a receber 6k independente dos custos', () {
    final r = svc.calcular(
      idFornecedor: 'f1',
      vendas: const [
        VendaFornecedorFato(
          id: 'v1',
          idEvento: 'e1',
          valorContratado: 10000,
          recebidoConfirmado: 4000,
        ),
      ],
      custos: const [
        CustoFornecedorFato(id: 'c1', idEvento: 'e1', incorrido: 3000),
      ],
    );
    expect(r.contratado, 10000);
    expect(r.recebido, 4000);
    expect(r.aReceber, 6000);
    expect(r.custoRealizado, 3000);
  });

  test('custos 3k + restantes 2k = custo direto previsto 5k', () {
    final r = svc.calcular(
      idFornecedor: 'f1',
      vendas: const [
        VendaFornecedorFato(
          id: 'v1',
          idEvento: 'e1',
          valorContratado: 10000,
          recebidoConfirmado: 0,
        ),
      ],
      custos: const [
        CustoFornecedorFato(
          id: 'c1',
          idEvento: 'e1',
          incorrido: 3000,
          restantePrevisto: 2000,
        ),
      ],
      comissaoInformada: 0,
      taxasInformadas: 0,
      tributosInformados: 0,
    );
    expect(r.custoRealizado, 3000);
    expect(r.custoRestantePrevisto, 2000);
    expect(r.custoDiretoPrevisto, 5000);
    expect(r.outrasDespesasAusentes, isTrue);
  });

  test('consumo de material comprado antes: custo sem nova saída de caixa', () {
    final r = svc.calcular(
      idFornecedor: 'f1',
      vendas: const [],
      custos: const [
        CustoFornecedorFato(
          id: 'c1',
          idEvento: 'e1',
          incorrido: 1500,
          desembolsoCaixa: 0,
          origem: 'estoque_consumo',
        ),
      ],
    );
    expect(r.custoRealizado, 1500);
    expect(r.saidasCaixa, 0);
    expect(OrigemCustoInterno.estoqueConsumo.geraSaidaCaixa, isFalse);
  });

  test('adiantamento afeta caixa sem virar receita realizada automática', () {
    final r = svc.calcular(
      idFornecedor: 'f1',
      vendas: const [
        VendaFornecedorFato(
          id: 'v1',
          idEvento: 'e-futuro',
          valorContratado: 10000,
          recebidoConfirmado: 2000,
          adiantamentoCaixa: 2000,
          receitaRealizada: 0,
          execucaoConfirmada: false,
        ),
      ],
    );
    expect(r.recebido, 2000);
    expect(r.adiantamentosCaixa, 2000);
    expect(r.receitaRealizada, 0);
    expect(r.entradasCaixa, 2000);
  });

  test('margem de contribuição não é rotulada como lucro líquido', () {
    final r = svc.calcular(
      idFornecedor: 'f1',
      vendas: const [
        VendaFornecedorFato(
          id: 'v1',
          idEvento: 'e1',
          valorContratado: 10000,
          recebidoConfirmado: 10000,
          receitaRealizada: 10000,
          execucaoConfirmada: true,
        ),
      ],
      custos: const [
        CustoFornecedorFato(id: 'c1', idEvento: 'e1', incorrido: 4000),
      ],
      comissaoInformada: 500,
      taxasInformadas: 0,
      tributosInformados: 0,
    );
    expect(r.margemContribuicao, 6000); // receita - custo direto
    expect(r.resultadoDiretoRealizado, 5500); // - comissão
    expect(r.formulaResultado.contains('lucro líquido'), isFalse);
  });
}
