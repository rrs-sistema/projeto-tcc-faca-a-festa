import 'package:app_faca_festa/data/models/evento/tema_festa_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TemaFestaModel', () {
    test('normalizes event type names for matching', () {
      expect(TemaFestaModel.normalizarTipo('Aniversário'), 'aniversario');
      expect(TemaFestaModel.normalizarTipo('Festa Infantil'), 'festa_infantil');
      expect(TemaFestaModel.normalizarTipo('Chá de Bebê'), 'cha_de_bebe');
    });

    test('matches compatible event types', () {
      const neon = TemaFestaModel(
        idTema: 'balada_neon',
        slug: 'balada_neon',
        nome: 'Balada Neon',
        categoria: TemaFestaCategorias.adulto,
        tiposEvento: [TemaFestaTipos.aniversario],
      );

      expect(neon.compativelComTipo('Aniversário'), isTrue);
      expect(neon.compativelComTipo('Festa Infantil'), isFalse);
    });

    test('round-trips Firestore map', () {
      const original = TemaFestaModel(
        idTema: 'safari',
        slug: 'safari',
        nome: 'Safári',
        categoria: TemaFestaCategorias.infantil,
        tiposEvento: [TemaFestaTipos.festaInfantil],
        corPrimaria: '#8D6E63',
        corSecundaria: '#C5E1A5',
        icone: 'pets',
        ativo: true,
        ordem: 10,
      );

      final parsed = TemaFestaModel.fromMap(original.toMap(), id: 'safari');

      expect(parsed.idTema, 'safari');
      expect(parsed.nome, 'Safári');
      expect(parsed.tiposEvento, ['festa_infantil']);
      expect(parsed.corPrimaria, '#8D6E63');
    });

    test('derives a light surface and readable contrast from the palette', () {
      const safari = TemaFestaModel(
        idTema: 'safari',
        slug: 'safari',
        nome: 'Safári',
        categoria: TemaFestaCategorias.infantil,
        corPrimaria: '#8D6E63',
        corSecundaria: '#C5E1A5',
      );
      expect(safari.fundoClaro.computeLuminance(), greaterThan(0.7));
      expect(safari.onPrimary, const Color(0xFFFFFFFF));

      const claro = TemaFestaModel(
        idTema: 'claro',
        slug: 'claro',
        nome: 'Claro',
        categoria: TemaFestaCategorias.criativo,
        corPrimaria: '#FFD54F',
        corSecundaria: '#212121',
      );
      expect(claro.onPrimary, const Color(0xFF1F2937));
      expect(claro.gradient.colors.last.computeLuminance(), greaterThan(0.12));
    });
  });
}
