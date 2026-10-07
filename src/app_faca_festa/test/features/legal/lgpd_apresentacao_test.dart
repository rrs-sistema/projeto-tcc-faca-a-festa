import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_faca_festa/core/legal/convidados_csv.dart';
import 'package:app_faca_festa/core/legal/preferencias_notificacao.dart';
import 'package:app_faca_festa/domain/entities/convidado.dart';
import 'package:app_faca_festa/presentation/modules/legal/widgets/aceite_privacidade_tile.dart';

void main() {
  test('exporta convidados em CSV com vírgula escapada', () {
    final csv = exportarConvidadosCsv([
      Convidado(
        idConvidado: '1',
        idEvento: 'evento',
        nome: 'Ana, Silva',
        contato: '11999999999',
        email: 'ana@email.com',
        status: StatusConvidado.confirmado,
        tipoConvidado: TipoConvidado.crianca,
        nomeGrupo: 'Família Silva',
        dataCadastro: DateTime(2026, 10, 6),
        dataAtualizacao: DateTime(2026, 10, 6),
      ),
    ]);

    expect(
      csv,
      'nome,contato,email,status,tipo,grupo\n'
      '"Ana, Silva",11999999999,ana@email.com,Confirmado,Criança,Família Silva',
    );
  });

  test('preferências ausentes ficam ligadas', () {
    final preferencias = PreferenciasNotificacao.fromMap(null);
    expect(preferencias.convites, isTrue);
    expect(preferencias.cotacoes, isTrue);
    expect(preferencias.chat, isTrue);
    expect(
      PreferenciasNotificacao.fromMap({'chat': false}).chat,
      isFalse,
    );
  });

  testWidgets('aceite da política começa desmarcado e pode ser ligado',
      (tester) async {
    var aceito = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AceitePrivacidadeTile(
            aceito: aceito,
            cor: const Color(0xFFFF2D7B),
            onChanged: (valor) => aceito = valor,
          ),
        ),
      ),
    );

    expect(find.text('Política de Privacidade'), findsOneWidget);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(aceito, isTrue);
  });
}
