import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_faca_festa/core/legal/dossie_titular.dart';
import 'package:app_faca_festa/core/legal/dossie_titular_documento.dart';
import 'package:app_faca_festa/core/legal/preferencias_notificacao.dart';
import 'package:app_faca_festa/core/legal/registro_tratamento.dart';
import 'package:app_faca_festa/domain/entities/usuario.dart';
import 'package:app_faca_festa/presentation/modules/legal/pages/central_privacidade_screen.dart';

void main() {
  test('o registro cobre os módulos pessoais do sistema', () {
    final modulos = RegistroTratamento.modulos;
    expect(modulos, contains('Conta e autenticação'));
    expect(modulos, contains('Convidados'));
    expect(modulos, contains('Financeiro'));
    expect(modulos, contains('Imagens'));
    expect(modulos, contains('Segurança'));
    expect(modulos, contains('Endereço e localização'));

    final campos = RegistroTratamento.itens.expand((item) => item.campos);
    expect(campos, contains('CNPJ'));
    expect(campos, contains('Token do convite'));
    expect(
      RegistroTratamento.itens.any((item) => item.baseLegal.contains('art. 14')),
      isTrue,
    );
    expect(
      RegistroTratamento.buscar('CNPJ').map((item) => item.tela),
      contains('Cadastro comercial e portfólio'),
    );
    expect(RegistroTratamento.buscar('campo que não existe'), isEmpty);
  });

  test('o dossiê leva a conta e as telas tratadas', () {
    final texto = montarDossieTitular(
      usuario: const Usuario(
        idUsuario: '1',
        nome: 'Maria Organizadora',
        email: 'maria@example.com',
        tipo: 'O',
      ),
      preferencias: const PreferenciasNotificacao(chat: false),
      geradoEm: DateTime.utc(2026, 10, 6, 15),
    );

    expect(texto, contains('maria@example.com'));
    expect(texto, contains('CPF: -'));
    expect(texto, contains('Chat: desligado'));
    expect(texto, contains('Lista, grupos, mesas e RSVP'));
    expect(texto, contains('Orçamento do organizador'));
    expect(texto, contains('ainda não é criptografada'));
    expect(texto.toLowerCase(), isNot(contains('senha_hash')));
  });

  test('o PDF do dossiê traduz o texto técnico da nuvem', () async {
    const bruto = '''
Faça a Festa — dossiê do titular
Gerado em 2026-10-07T02:11:42.311Z
Conta: abc123

1. Conta
Nome: Kamilly Ketully
Papel: O
CPF: -
Aceite: -
Avisos: padrão ligado

2. Endereços
Rua das Flores, 10

3. Eventos e convidados
Evento 15 anos da Kamilly
Data: 2027-07-11T19:30:00.000Z
Convidados neste recorte: 1
- Rivaldo R. | rivaldo@email.com | adulto

4. Cotações solicitadas
- Decoração | respondida

Recorte limitado a 15 eventos, 40 convidados por evento e 20 cotações.
''';

    final doc = interpretarDossie(bruto);
    final conta = doc.secoes.firstWhere((secao) => secao.titulo.startsWith('1.'));
    final campos = conta.linhas.whereType<LinhaDossie>();
    expect(
      campos.any((linha) => linha.rotulo == 'Papel' && linha.valor == 'Organizador'),
      isTrue,
    );
    expect(
      campos.any((linha) => linha.rotulo == 'CPF' && linha.valor == 'Não informado'),
      isTrue,
    );
    expect(
      campos.any((linha) => linha.rotulo == 'Aceite' && linha.valor == 'Não registrado'),
      isTrue,
    );
    expect(doc.cabecalho.any((linha) => linha.valor.contains('T02:')), isFalse);
    expect(doc.notaFinal, contains('15 eventos'));
    expect(doc.notaFinal, isNot(contains('Recorte limitado')));

    final pdf = await gerarPdfDossieTitular(bruto);
    expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
  });

  testWidgets('a central lista direitos e uma tela protegida', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 6000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(home: CentralPrivacidadeScreen()),
    );

    expect(find.text('Dados protegidos'), findsOneWidget);
    expect(find.text('Acessar e levar meus dados'), findsOneWidget);
    expect(find.text('Anonimizar ou bloquear'), findsOneWidget);
    expect(find.text('Registrar oposição'), findsOneWidget);
    expect(find.text('Solicitar exclusão'), findsOneWidget);

    await tester.tap(find.text('Telas e campos'));
    await tester.pumpAndSettle();

    expect(find.text('Cadastro e login'), findsOneWidget);
    expect(find.textContaining('Nome'), findsWidgets);
  });
}
