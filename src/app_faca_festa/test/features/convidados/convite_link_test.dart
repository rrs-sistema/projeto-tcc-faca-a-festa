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

  test('returns null when the invite path is missing', () {
    expect(
      ConviteLink.tokenDaUrl(Uri.parse('https://faca-a-festa.web.app/#/role')),
      isNull,
    );
  });
}
