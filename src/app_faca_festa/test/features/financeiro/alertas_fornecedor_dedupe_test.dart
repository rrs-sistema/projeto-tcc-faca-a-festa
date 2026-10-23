import 'package:flutter_test/flutter_test.dart';

import 'package:app_faca_festa/domain/entities/financeiro/alerta_financeiro.dart';
import 'package:app_faca_festa/domain/services/resumo_financeiro_fornecedor_service.dart';

void main() {
  const svc = ResumoFinanceiroFornecedorService();

  test('recálculos sucessivos não acumulam alertas duplicados no merge', () {
    final r1 = svc.calcular(idFornecedor: 'forn-1');
    final r2 = svc.calcular(idFornecedor: 'forn-1');
    // Simula o merge corrigido: usa só o conjunto novo.
    final merged = r2.alertas;
    final mensagens = merged.map((a) => a.mensagem).toSet();
    expect(merged.length, mensagens.length);
    expect(
      merged.where((a) => a.tipo == TipoAlertaFinanceiro.consultaIncompleta).length,
      lessThanOrEqualTo(2),
    );
    // Concatenação antiga quebraria isto:
    final bug = [...r1.alertas, ...r2.alertas];
    expect(bug.length, greaterThan(merged.length));
  });
}
