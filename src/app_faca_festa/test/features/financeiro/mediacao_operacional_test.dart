import 'package:flutter_test/flutter_test.dart';

import 'package:app_faca_festa/domain/entities/financeiro/mediacao_operacional.dart';
import 'package:app_faca_festa/domain/services/mediacao_operacional_service.dart';

void main() {
  const svc = MediacaoOperacionalService();

  test('identifica partes e dimensões financeiras separadas', () {
    final fin = svc.calcularDimensoes(
      valorContratadoCentavos: 1000000,
      recebidoAlocadoCentavos: 400000,
      repassadoConfirmadoCentavos: 0,
    );
    expect(fin.aReceberClienteCentavos, 600000);
    expect(fin.pendenteRepasseCentavos, 400000);
    expect(fin.repassadoConfirmadoCentavos, 0);
    final linha = LinhaCentralContratacao(
      idContrato: 'c1',
      idOrcamento: 'o1',
      idEvento: 'e1',
      nomeEvento: 'Festa Ana',
      nomeContratante: 'Maria',
      nomeFornecedor: 'Buffet Sol',
      nomeServico: 'Coffee',
      valorContratadoCentavos: fin.valorContratadoCentavos,
      recebidoClienteCentavos: fin.recebidoClienteAlocadoCentavos,
      repassadoCentavos: fin.repassadoConfirmadoCentavos,
      aReceberClienteCentavos: fin.aReceberClienteCentavos,
      pendenteRepasseCentavos: fin.pendenteRepasseCentavos,
      estadoComercial: 'contratado',
      estadoExecucao: 'nao_iniciado',
      casoAberto: false,
      pendencias: const [],
      identidadeIncompleta: false,
    );
    expect(linha.rotuloContratante, 'Maria');
    expect(linha.rotuloFornecedor, 'Buffet Sol');
    expect(linha.rotuloServico, 'Coffee');
  });

  test('bloqueio/recomendação só no contrato alvo', () {
    final escopo = svc.escopoBloqueio(
      idContratoAlvo: 'c-buffet',
      idsContratosDoEvento: const ['c-buffet', 'c-som'],
    );
    expect(escopo.afetados, ['c-buffet']);
    expect(escopo.naoAfetados, ['c-som']);
    final r = svc.aplicarRecomendacao(
      motivo: 'revisar buffet',
      politicaRetencaoAtiva: false,
    );
    expect(r.somenteRecomendacao, isTrue);
    expect(r.retencaoAplicada, isFalse);
  });

  test('nota interna não vaza para cliente nem exportação', () {
    final regs = [
      RegistroMediacaoView(
        id: '1',
        tipo: 'nota_interna',
        visibilidade: VisibilidadeRegistroMediacao.interna,
        texto: 'secreto',
        autorId: 'a',
        criadoEm: '1',
        efeitoFinanceiroExecutado: false,
      ),
      RegistroMediacaoView(
        id: '2',
        tipo: 'info_compartilhavel',
        visibilidade: VisibilidadeRegistroMediacao.compartilhavel,
        texto: 'ok',
        autorId: 'a',
        criadoEm: '2',
        efeitoFinanceiroExecutado: false,
      ),
    ];
    final cliente = svc.filtrarRegistrosPorPapel(
      registros: regs,
      papel: 'cliente',
      caps: [CapacidadeMediacao.consultaComercial],
    );
    expect(cliente.length, 1);
    expect(cliente.first.texto, 'ok');
    expect(svc.registrosParaExportacao(regs).length, 1);
    final admin = svc.filtrarRegistrosPorPapel(
      registros: regs,
      papel: 'admin',
      caps: svc.capacidadesParaTipo('A'),
    );
    expect(admin.length, 2);
  });

  test('fechar caso não gera efeitos financeiros', () {
    expect(svc.efeitosFinanceirosAoFechar(), isEmpty);
  });

  test('fornecedor só vê o próprio vínculo', () {
    expect(
      svc.casoVisivelParaVinculo(
        idContratanteCaso: 'cli',
        idFornecedorCaso: 'forn-A',
        papel: 'fornecedor',
        uid: 'op',
        idFornecedorOperador: 'forn-A',
      ),
      isTrue,
    );
    expect(
      svc.casoVisivelParaVinculo(
        idContratanteCaso: 'cli',
        idFornecedorCaso: 'forn-A',
        papel: 'fornecedor',
        uid: 'op',
        idFornecedorOperador: 'forn-B',
      ),
      isFalse,
    );
  });
}
