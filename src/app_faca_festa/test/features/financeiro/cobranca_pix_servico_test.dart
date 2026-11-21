import 'package:app_faca_festa/domain/entities/cobranca_pix_servico.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lê a cobrança Pix devolvida pela function', () {
    final cobranca = CobrancaPixServico.fromMap({
      'reutilizada': true,
      'aviso': 'Há um Pix em aberto.',
      'cobranca': {
        'id': 'abc',
        'status': 'APPROVED',
        'valorCentavos': 315000,
        'copiaCola': '000201',
        'qrCodeBase64': '',
        'nomeServico': 'Decoração',
      },
    });

    expect(cobranca.id, 'abc');
    expect(cobranca.confirmado, isTrue);
    expect(cobranca.reutilizada, isTrue);
    expect(cobranca.valorCentavos, 315000);
    expect(cobranca.aviso, 'Há um Pix em aberto.');
    expect(cobranca.nomeServico, 'Decoração');
  });
}
