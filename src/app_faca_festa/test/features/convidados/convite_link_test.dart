import 'package:app_faca_festa/core/utils/convite_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds the public /convite/{token} url with hash routing', () {
    expect(
      ConviteLink.url('abc-123'),
      'https://faca-a-festa.web.app/#/convite/abc-123',
    );
  });

  test('returns empty when the token is missing', () {
    expect(ConviteLink.url('  '), isEmpty);
  });

  test('encodes the token and respects a custom origin', () {
    expect(
      ConviteLink.url('a b', origem: 'https://exemplo.com/'),
      'https://exemplo.com/#/convite/a%20b',
    );
  });

  test('reads the token from hash routing', () {
    expect(
      ConviteLink.tokenDaUrl(
        Uri.parse('https://faca-a-festa.web.app/#/convite/abc-123'),
      ),
      'abc-123',
    );
  });

  test('reads the token from the guest area hash', () {
    expect(
      ConviteLink.tokenDaUrl(
        Uri.parse(
          'https://faca-a-festa.web.app/#/areaconvidado/cf89bbba-55fc-4db8-ae67-adc1ffda4f82',
        ),
      ),
      'cf89bbba-55fc-4db8-ae67-adc1ffda4f82',
    );
  });

  test('builds the invite route with the token', () {
    expect(ConviteLink.rotaConvite('abc-123'), '/convite/abc-123');
    expect(ConviteLink.rotaConvite('  '), '/convite');
  });

  test('builds the guest area route with the token', () {
    expect(
      ConviteLink.rotaAreaConvidado('abc-123'),
      '/areaconvidado/abc-123',
    );
    expect(ConviteLink.rotaAreaConvidado('  '), '/areaconvidado');
  });

  test('returns null when the invite path is missing', () {
    expect(
      ConviteLink.tokenDaUrl(Uri.parse('https://faca-a-festa.web.app/#/role')),
      isNull,
    );
  });

  test('reads the token from pasted hash URL', () {
    expect(
      ConviteLink.tokenDeTexto(
        'https://faca-a-festa.web.app/#/convite/abc-123',
      ),
      'abc-123',
    );
  });

  test('reads the token from a message that contains the invite URL', () {
    expect(
      ConviteLink.tokenDeTexto(
        'Oi! Segue o convite: https://faca-a-festa.web.app/#/convite/abc-123 até logo',
      ),
      'abc-123',
    );
  });

  test('reads a raw token of at least 8 characters', () {
    expect(
      ConviteLink.tokenDeTexto('cf89bbba-55fc-4db8-ae67-adc1ffda4f82'),
      'cf89bbba-55fc-4db8-ae67-adc1ffda4f82',
    );
  });

  test('rejects pasted text without an invite', () {
    expect(ConviteLink.tokenDeTexto('  '), isNull);
    expect(ConviteLink.tokenDeTexto('abc'), isNull);
    expect(ConviteLink.tokenDeTexto('https://faca-a-festa.web.app/#/role'),
        isNull);
  });
}
