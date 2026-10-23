import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:app_faca_festa/core/utils/tema_festa_capa_url.dart';
import 'package:app_faca_festa/presentation/widgets/tema_capa_imagem.dart';

void main() {
  test('tema sem imagem não presume arquivo no Storage', () {
    expect(TemaFestaCapaUrl.capaEfetiva(idTema: 'tropical_chique'), isNull);
    expect(
        TemaFestaCapaUrl.capaEfetiva(
            idTema: 'tropical_chique', imagemCapaUrl: '  '),
        isNull);
    expect(
        TemaFestaCapaUrl.capaEfetiva(
            idTema: 'tema', imagemCapaUrl: 'https://example.com/capa.jpg'),
        'https://example.com/capa.jpg');
  });
  for (final url in [null, '', '  ', 'capa.jpg', 'https:///capa.jpg']) {
    testWidgets('capa inválida $url usa fallback sem provedor de rede',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: TemaCapaImagem(url: url, fallback: const Text('Sem imagem'))));
      expect(find.text('Sem imagem'), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
