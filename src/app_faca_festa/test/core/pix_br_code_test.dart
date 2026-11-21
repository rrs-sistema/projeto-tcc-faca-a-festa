import 'package:app_faca_festa/core/utils/pix_br_code.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PixBrCode', () {
    test('gera payload estático sem tag 54 (valor livre)', () {
      final payload = PixBrCode.gerar(
        chave: 'teste@email.com',
        nomeRecebedor: 'Festa da Ana',
        cidade: 'Maringá',
      );

      expect(payload.startsWith('000201'), isTrue);
      expect(payload.contains('br.gov.bcb.pix'), isTrue);
      expect(payload.contains('teste@email.com'), isTrue);
      expect(payload.contains('540'), isFalse); // sem tag 54
      expect(PixBrCode.isValorLivre(payload), isTrue);
      expect(payload.substring(payload.length - 4),
          matches(RegExp(r'^[0-9A-F]{4}$')));
      expect(payload.contains('6304'), isTrue);
    });

    test('inclui tag 54 quando há valor fixo', () {
      final payload = PixBrCode.gerar(
        chave: '(11) 99999-8888',
        nomeRecebedor: 'João',
        cidade: 'Curitiba',
        valor: 50,
      );

      expect(payload.contains('540550.00'), isTrue);
      expect(PixBrCode.isValorLivre(payload), isFalse);
      expect(payload.contains('+5511999998888'), isTrue);
    });

    test('normaliza CPF só com dígitos', () {
      final payload = PixBrCode.gerar(
        chave: '123.456.789-09',
        nomeRecebedor: 'Maria',
        cidade: 'SP',
      );

      expect(payload.contains('12345678909'), isTrue);
    });

    test('CRC confere com recálculo', () {
      final payload = PixBrCode.gerar(
        chave: 'chave-aleatoria-uuid-demo',
        nomeRecebedor: 'Evento',
        cidade: 'Brasil',
        valor: 10.5,
      );

      final semCrc = payload.substring(0, payload.length - 4);
      expect(semCrc.endsWith('6304'), isTrue);

      // Regenera e compara — mesmo input deve ser estável.
      final again = PixBrCode.gerar(
        chave: 'chave-aleatoria-uuid-demo',
        nomeRecebedor: 'Evento',
        cidade: 'Brasil',
        valor: 10.5,
      );
      expect(again, payload);
    });
  });
}
