import 'dart:async';

import 'package:app_faca_festa/domain/entities/evento.dart';
import 'package:app_faca_festa/domain/entities/gift/gift.dart';
import 'package:app_faca_festa/domain/entities/gift/gift_contribution.dart';
import 'package:app_faca_festa/domain/repositories/gift_repository.dart';
import 'package:app_faca_festa/domain/usecases/get_gifts/gift_usecases.dart';
import 'package:app_faca_festa/presentation/modules/convidado/pages/area/presentes_section.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

class _RepositorioFalso implements GiftRepository {
  final presentes = StreamController<List<Gift>>.broadcast();

  @override
  Stream<List<Gift>> getGifts(String eventoId) => presentes.stream;

  @override
  Stream<List<Gift>> watchRemoteGifts(String eventoId) => presentes.stream;

  @override
  Future<void> createGift(String eventoId, Gift gift) async {}

  @override
  Future<void> updateGift(String eventoId, Gift gift) async {}

  @override
  Future<void> deleteGift(String eventoId, String giftId) async {}

  @override
  Future<bool> reservarGift(
          String eventoId, String giftId, String nome, String uid) async =>
      true;

  @override
  Future<void> contribuirPix(
          String eventoId, String giftId, GiftContribution contribution) async {}
}

Evento _evento() => Evento(
      idEvento: 'evt-1',
      idTipoEvento: 'aniversario',
      idUsuario: 'usuario',
      nomeEvento: 'Festa',
      localEvento: 'Salão',
      data: DateTime(2027, 7, 11),
    );

Gift _presente() => Gift(
      id: 'p-1',
      nome: 'Air fryer',
      categoria: 'casa',
      tipo: GiftType.fisico,
      valor: 350,
      // Sem link de loja: o presente físico vira reserva na própria festa.
      status: GiftStatus.disponivel,
      createdAt: DateTime(2027, 1, 1),
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late _RepositorioFalso repo;

  setUp(() {
    repo = _RepositorioFalso();
    Get.testMode = true;
  });

  tearDown(() async {
    await repo.presentes.close();
    Get.reset();
  });

  Future<void> pumpLista(
    WidgetTester tester,
    Future<void> Function(Gift presente) onReservar,
  ) async {
    tester.view.physicalSize = const Size(390 * 2.0, 844 * 2.0);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PresentesSection(
          evento: _evento(),
          theme: EventThemeController(),
          giftUseCases: GiftUseCases(repo),
          onReservar: onReservar,
        ),
      ),
    ));
    repo.presentes.add([_presente()]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('botão reservar abre confirmação e só reserva ao confirmar',
      (tester) async {
    final reservados = <String>[];
    await pumpLista(tester, (presente) async => reservados.add(presente.id));

    await tester.tap(find.text('Quero reservar').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Reservar Air fryer?'), findsOneWidget);
    expect(reservados, isEmpty, reason: 'não reserva antes da confirmação');

    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();
    expect(reservados, isEmpty, reason: 'cancelar não reserva');

    await tester.tap(find.text('Quero reservar').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Reservar'));
    await tester.pumpAndSettle();
    expect(reservados, ['p-1']);
  });

  testWidgets('enquanto reserva, um novo toque não dispara outra reserva',
      (tester) async {
    final espera = Completer<void>();
    var chamadas = 0;
    await pumpLista(tester, (presente) async {
      chamadas++;
      await espera.future;
    });

    await tester.tap(find.text('Quero reservar').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Reservar'));
    await tester.pump();

    // Enquanto a reserva está em andamento, o toque não abre nova confirmação.
    await tester.tap(find.text('Quero reservar').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Reservar Air fryer?'), findsNothing);

    espera.complete();
    await tester.pumpAndSettle();
    expect(chamadas, 1);
  });
}
