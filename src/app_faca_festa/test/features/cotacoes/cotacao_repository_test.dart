import 'package:app_faca_festa/data/datasources/remote/cotacao_remote_datasource.dart';
import 'package:app_faca_festa/data/repositories_impl/cotacao_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('delega confirmacao de fornecedor preservando os parametros', () async {
    final remote = _CotacaoRemoteFake(idEvento: 'evento-1');
    final repository = CotacaoRepositoryImpl(remote);

    final idEvento = await repository.confirmarFornecedorEscolhido(
      idCotacao: 'cotacao-1',
      idFornecedor: 'fornecedor-1',
      nomeFornecedor: 'Buffet Ana',
      idSolicitante: 'usuario-1',
      nomeSolicitante: 'Ana',
    );

    expect(idEvento, 'evento-1');
    expect(remote.idCotacao, 'cotacao-1');
    expect(remote.idFornecedor, 'fornecedor-1');
    expect(remote.nomeFornecedor, 'Buffet Ana');
    expect(remote.idSolicitante, 'usuario-1');
    expect(remote.nomeSolicitante, 'Ana');
  });
}

class _CotacaoRemoteFake implements CotacaoRemoteDatasource {
  _CotacaoRemoteFake({required this.idEvento});

  final String idEvento;
  String? idCotacao;
  String? idFornecedor;
  String? nomeFornecedor;
  String? idSolicitante;
  String? nomeSolicitante;

  @override
  Future<String> confirmarFornecedorEscolhido({
    required String idCotacao,
    required String idFornecedor,
    required String nomeFornecedor,
    required String idSolicitante,
    required String nomeSolicitante,
  }) async {
    this.idCotacao = idCotacao;
    this.idFornecedor = idFornecedor;
    this.nomeFornecedor = nomeFornecedor;
    this.idSolicitante = idSolicitante;
    this.nomeSolicitante = nomeSolicitante;
    return idEvento;
  }
}
