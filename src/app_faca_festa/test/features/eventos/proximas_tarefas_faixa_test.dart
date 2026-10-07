import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/domain/entities/tarefa.dart';
import 'package:app_faca_festa/presentation/modules/eventos/components/proximas_tarefas_faixa.dart';
import 'package:app_faca_festa/presentation/modules/eventos/home_organizador_copy.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('conclui, abre e cria a partir da faixa', (tester) async {
    final agora = DateTime(2026, 10, 6);
    final tarefa = Tarefa(
      idTarefa: 't1',
      idEvento: 'evento',
      titulo: 'Fazer cotação das chácaras',
      dataPrevista: DateTime(2026, 8, 27),
      idResponsavel: 'c1',
    );
    Tarefa? concluida;
    Tarefa? aberta;
    var verTodas = 0;
    var nova = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProximasTarefasFaixa(
            tarefas: [tarefa],
            total: 4,
            pendentes: 1,
            atrasadas: 1,
            primary: const Color(0xFF6D28D9),
            nomesResponsavel: const {'c1': 'Kamilly'},
            onVerTodas: () => verTodas++,
            onNova: () => nova++,
            onConcluir: (item) => concluida = item,
            onAbrir: (item) => aberta = item,
            agora: agora,
          ),
        ),
      ),
    );

    expect(find.text('1 atrasada'), findsOneWidget);
    expect(find.textContaining('Atrasada · 27/08'), findsOneWidget);
    expect(find.textContaining('Kamilly'), findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(concluida?.idTarefa, 't1');

    await tester.tap(find.text('Fazer cotação das chácaras'));
    await tester.pump();
    expect(aberta?.idTarefa, 't1');

    await tester.tap(find.text(HomeOrganizadorCopy.verTodasTarefas));
    await tester.tap(find.text(HomeOrganizadorCopy.novaTarefa));
    await tester.pump();
    expect(verTodas, 1);
    expect(nova, 1);
  });

  testWidgets('sem tarefas o botão cria a primeira', (tester) async {
    var nova = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProximasTarefasFaixa(
            tarefas: const [],
            total: 0,
            pendentes: 0,
            atrasadas: 0,
            primary: const Color(0xFF6D28D9),
            nomesResponsavel: const {},
            onVerTodas: () {},
            onNova: () => nova++,
            onConcluir: (_) {},
            onAbrir: (_) {},
          ),
        ),
      ),
    );

    expect(find.text(HomeOrganizadorCopy.nenhumaTarefa), findsOneWidget);
    expect(find.text(HomeOrganizadorCopy.verTodasTarefas), findsNothing);
    await tester.tap(find.text(HomeOrganizadorCopy.nenhumaTarefaAcao));
    await tester.pump();
    expect(nova, 1);
  });
}
