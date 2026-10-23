import 'package:flutter_test/flutter_test.dart';

import 'package:app_faca_festa/domain/entities/financeiro/contratacao_identidade.dart';
import 'package:app_faca_festa/domain/entities/financeiro/contrato_financeiro.dart';
import 'package:app_faca_festa/domain/entities/financeiro/valor_monetario.dart';

void main() {
  test('execução e comercial são dimensões distintas no contrato', () {
    final c = ContratoFinanceiro(
      id: 'c1',
      idEvento: 'e1',
      idOrcamento: 'o1',
      valor: ValorMonetario.centavos(1000000),
      estadoComercial: EstadoComercialContrato.contratado,
      estadoExecucao: EstadoExecucaoContrato.naoIniciado,
      snapshotIdentidade: SnapshotIdentidadeComercial(
        idEvento: 'e1',
        origem: 'teste',
        capturadoEm: '2026-01-01T00:00:00.000Z',
        nomeEvento: 'Aniversário da Sofia',
        nomeContratante: 'Ana Souza',
        nomeFornecedor: 'Decora Festas',
        nomeServico: 'Decoração do salão',
      ),
    );
    expect(c.estaContratado, isTrue);
    expect(c.estadoExecucao, EstadoExecucaoContrato.naoIniciado);
    expect(c.snapshotIdentidade?.nomeFornecedor, 'Decora Festas');

    final map = c.toMap();
    final roundtrip = ContratoFinanceiro.fromMap(
      map,
      idOrcamento: 'o1',
      idEvento: 'e1',
    );
    expect(roundtrip.estadoExecucao, EstadoExecucaoContrato.naoIniciado);
    expect(roundtrip.snapshotIdentidade?.nomeEvento, 'Aniversário da Sofia');
  });

  test('linha admin: dois fornecedores e oportunidade não é prestado', () {
    final contratado = LinhaContratacaoAdmin.fromMap({
      'id_contrato': 'orc-decor',
      'id_orcamento': 'orc-decor',
      'id_evento': 'ev-sofia',
      'nome_evento': 'Aniversário da Sofia',
      'nome_contratante': 'Ana Souza',
      'nome_fornecedor': 'Decora Festas',
      'nome_servico': 'Decoração do salão',
      'contratado': true,
      'estado_comercial': 'Contratado',
      'estado_execucao': 'nao_iniciado',
      'valor_contratado_centavos': 1000000,
    });
    final oportunidade = LinhaContratacaoAdmin.fromMap({
      'id_contrato': 'orc-buffet',
      'id_orcamento': 'orc-buffet',
      'id_evento': 'ev-sofia',
      'nome_evento': 'Aniversário da Sofia',
      'nome_contratante': 'Ana Souza',
      'nome_fornecedor': 'Buffet Sabor',
      'nome_servico': 'Buffet para convidados',
      'contratado': false,
      'estado_comercial': 'Em negociação',
      'estado_execucao': 'nao_iniciado',
    });
    expect(contratado.rotuloEvento, oportunidade.rotuloEvento);
    expect(contratado.rotuloFornecedor, 'Decora Festas');
    expect(oportunidade.rotuloFornecedor, 'Buffet Sabor');
    expect(contratado.contratado, isTrue);
    expect(oportunidade.contratado, isFalse);
    expect(contratado.rotuloEstadoCombinado, contains('execução ainda não'));
  });

  test('identidade incompleta não inventa rótulo de pessoa', () {
    final l = LinhaContratacaoAdmin.fromMap({
      'id_orcamento': 'x',
      'id_evento': 'e',
      'contratado': true,
      'estado_comercial': 'Contratado',
      'estado_execucao': 'nao_iniciado',
      'identidade_incompleta': true,
      'pendencias_identificacao': ['fornecedor', 'servico'],
    });
    expect(l.rotuloFornecedor, 'Fornecedor pendente');
    expect(l.rotuloServico, 'Serviço pendente');
    expect(l.pendenciasIdentificacao, contains('fornecedor'));
  });
}
