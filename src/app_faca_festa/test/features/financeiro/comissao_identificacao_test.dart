import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:app_faca_festa/data/services/comissao_identificacao_service.dart';
import 'package:app_faca_festa/data/datasources/remote/comissao_plataforma_remote_datasource.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/controllers/comissao_plataforma_controller.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/widgets/comissao_detalhe.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/widgets/comissao_modal.dart';

class FunctionsFake extends Fake implements FirebaseFunctions {}

void main() {
  test(
      'resolve nomes reais, mantém valores e reutiliza referências no mesmo extrato',
      () async {
    final consultas = <String>[];
    final service = ComissaoIdentificacaoService((colecao, id) async {
      consultas.add('$colecao/$id');
      return {
        'evento/e': {'nome_evento': 'Confraternização da equipe'},
        'fornecedor/f': {'razao_social': 'Buffet da Praça'},
        'usuarios/u': {'nome': 'Ana Silva'},
      }['$colecao/$id'];
    });
    final original = {
      'id_evento': 'e',
      'id_fornecedor': 'f',
      'id_pagador': 'u',
      'saldo_centavos': 15750
    };
    final resultado = await service.completar({
      'obrigacoes': [original, original]
    }, ehAdmin: true);
    final o = (resultado['obrigacoes'] as List).first as Map<String, dynamic>;
    expect(o['nome_evento'], 'Confraternização da equipe');
    expect(o['nome_fornecedor'], 'Buffet da Praça');
    expect(o['nome_pagador'], 'Ana Silva');
    expect(o['saldo_centavos'], 15750);
    expect(consultas.where((p) => p == 'evento/e'), hasLength(1));
    expect(original.containsKey('nome_evento'), false);
  });
  test(
      'referências ausentes não viram nomes e nomes existentes são preservados',
      () async {
    final service = ComissaoIdentificacaoService((_, __) async => null);
    final resultado = await service.completar({
      'obrigacoes': [
        {'id_evento': 'codigo-interno', 'id_pagador': 'outro'},
        {
          'nome_evento': 'Evento registrado',
          'nome_fornecedor': 'Empresa registrada'
        },
      ]
    }, ehAdmin: false);
    final lista = resultado['obrigacoes'] as List;
    expect(ComissaoPlataformaController.nomeEventoDe(lista.first),
        'Nome do evento indisponível');
    expect(ComissaoPlataformaController.nomeFornecedorDe(lista.last),
        'Empresa registrada');
  });
  testWidgets(
      'detalhe identifica evento, fornecedor e pagador antes dos códigos',
      (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final c = ComissaoPlataformaController(
        remote: ComissaoPlataformaRemoteDatasource(functions: FunctionsFake()),
        ehAdmin: () => true);
    final o = <String, dynamic>{
      'id': 'codigo-cobranca',
      'id_evento': 'codigo-evento',
      'id_fornecedor': 'codigo-fornecedor',
      'nome_evento': 'Festa da equipe',
      'nome_fornecedor': 'Buffet da Praça',
      'nome_pagador': 'Ana Silva',
      'saldo_centavos': 15750
    };
    c.obrigacoes.add(o);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                    onPressed: () => mostrarComissaoModal(
                        context: context,
                        builder: (_) => ComissaoDetalhe(
                            controller: c, obrigacao: o, accent: Colors.teal)),
                    child: const Text('Abrir'))))));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Festa da equipe'), findsOneWidget);
    expect(find.text('Buffet da Praça'), findsOneWidget);
    expect(find.text('Ana Silva'), findsOneWidget);
    expect(find.textContaining('Evento: codigo-evento'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
