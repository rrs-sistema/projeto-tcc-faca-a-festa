import 'package:flutter_test/flutter_test.dart';

import 'package:app_faca_festa/domain/services/acompanhamento_partes_service.dart';

void main() {
  const svc = AcompanhamentoPartesService();

  test('Ana declara 4k: pendência e fornecedor sem caixa', () {
    final c = svc.cenarioAnaDebora(
      declarado: 400000,
      confirmado: 0,
      repasseConfirmado: 0,
    );
    expect(c['nivel_antes'], 'declarado');
    expect(c['admin_pendencia'], isTrue);
    expect(c['fornecedor_caixa_antes'], 0);
  });

  test('após confirmação saldo 6k; alocado não é caixa fornecedor', () {
    final c = svc.cenarioAnaDebora(
      declarado: 400000,
      confirmado: 400000,
      repasseConfirmado: 0,
    );
    expect(c['a_pagar_apos'], 600000);
    expect(c['trata_alocado_como_caixa'], isFalse);
  });

  test('5% desconto e repasse parcial 3k → saldo previsto 6500', () {
    final c = svc.cenarioAnaDebora(
      confirmado: 400000,
      repasseConfirmado: 300000,
    );
    expect(c['direito_liquido'], 950000);
    expect(c['saldo_previsto_repasse'], 650000);
  });

  test('acesso cruzado negado', () {
    final a = svc.acessoCruzado(
      idFornecedorContrato: 'debora',
      idFornecedorConsulta: 'outro',
      idContratanteContrato: 'ana',
      idClienteConsulta: 'outra',
    );
    expect(a.fornecedorEstranho, isTrue);
    expect(a.clienteEstranho, isTrue);
  });

  test('execução: abrir detalhe não aceita; CTAs bloqueados', () {
    expect(svc.podeAceitarOuContestar('nao_iniciado'), isFalse);
    expect(svc.podeAceitarOuContestar('entrega_informada'), isTrue);
    expect(svc.podeInformarEntrega('entrega_informada'), isFalse);
    for (final cta in AcompanhamentoPartesService.ctasIntegracaoAusente) {
      expect(svc.ctaProibidoSemIntegracao(cta), isTrue);
      expect(svc.acoesPermitidasSemIntegracao().contains(cta), isFalse);
    }
  });
}
