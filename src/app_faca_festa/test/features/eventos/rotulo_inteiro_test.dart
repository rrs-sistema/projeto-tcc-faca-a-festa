import 'package:app_faca_festa/presentation/widgets/rotulo_inteiro.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pede mais largura só quando o zoom esmagaria o nome', () {
    expect(
      RotuloInteiro.pedeMaisLargura(natural: 100, disponivel: 80),
      isFalse,
    );
    expect(
      RotuloInteiro.pedeMaisLargura(natural: 100, disponivel: 70),
      isTrue,
    );
    expect(
      RotuloInteiro.pedeMaisLargura(natural: 100, disponivel: 0),
      isTrue,
    );
  });

  test('tamanho compartilhado iguala o grupo sem cortar a última letra', () {
    expect(
      RotuloInteiro.tamanhoCompartilhado(
        larguraNatural: 90,
        disponivel: 120,
        tamanhoVisual: 13,
      ),
      isNull,
    );
    final ajustado = RotuloInteiro.tamanhoCompartilhado(
      larguraNatural: 100,
      disponivel: 80,
      tamanhoVisual: 13,
    );
    expect(ajustado, isNotNull);
    expect(ajustado!, lessThan(13));
    expect(ajustado, greaterThan(13 * fatorRotuloMinimo * 0.9));
    expect(
      RotuloInteiro.tamanhoCompartilhado(
        larguraNatural: 100,
        disponivel: 70,
        tamanhoVisual: 13,
      ),
      isNull,
    );
  });

  testWidgets('nome longo permanece numa linha quando a coluna é estreita',
      (tester) async {
    const estilo = TextStyle(fontSize: 16, fontWeight: FontWeight.w700);
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(
            width: 72,
            child: RotuloInteiro('Fornecedores', style: estilo),
          ),
        ),
      ),
    );

    final texto = tester.widget<Text>(find.text('Fornecedores'));
    expect(texto.maxLines, 1);
    expect(texto.softWrap, isFalse);
    expect(texto.data, 'Fornecedores');
    final largura = _larguraPintada(tester, texto);
    expect(largura, lessThanOrEqualTo(72));
    expect(largura, greaterThan(40));
    expect(
      tester.renderObject<RenderParagraph>(find.text('Fornecedores')).didExceedMaxLines,
      isFalse,
    );
  });

  testWidgets('zoom aumenta o nome enquanto ele cabe e não o parte',
      (tester) async {
    const estilo = TextStyle(fontSize: 16, fontWeight: FontWeight.w700);

    Future<double> larguraDaLinha(double escala, double caixa) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(escala)),
            child: Center(
              child: SizedBox(
                width: caixa,
                child: const RotuloInteiro('Confirmados', style: estilo),
              ),
            ),
          ),
        ),
      );
      final texto = tester.widget<Text>(find.text('Confirmados'));
      expect(texto.maxLines, 1);
      expect(texto.softWrap, isFalse);
      expect(texto.data, 'Confirmados');
      expect(
        tester.renderObject<RenderParagraph>(find.text('Confirmados')).didExceedMaxLines,
        isFalse,
      );
      return _larguraPintada(tester, texto);
    }

    final aberto = await larguraDaLinha(1, 280);
    final ampliado = await larguraDaLinha(1.6, 280);
    expect(ampliado, greaterThan(aberto));

    final apertado = await larguraDaLinha(1.6, 90);
    expect(apertado, lessThanOrEqualTo(90));
  });
}

double _larguraPintada(WidgetTester tester, Text texto) {
  final contexto = tester.element(find.text(texto.data!));
  final painter = TextPainter(
    text: TextSpan(text: texto.data, style: texto.style),
    textDirection: TextDirection.ltr,
    textScaler: texto.textScaler ?? MediaQuery.textScalerOf(contexto),
    maxLines: 1,
  )..layout();
  final largura = painter.width;
  painter.dispose();
  return largura;
}
