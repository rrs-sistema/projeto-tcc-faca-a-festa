import 'package:app_faca_festa/data/datasources/remote/cotacao_remote_datasource.dart';
import 'package:app_faca_festa/data/models/cotacao/cotacao_model.dart';
import 'package:app_faca_festa/data/repositories_impl/cotacao_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('delega observacao das cotacoes do organizador', () async {
    final cotacao = _cotacao();
    final remote = _CotacaoRemoteFake(
      idEvento: 'evento-1',
      cotacoes: [cotacao],
    );
    final repository = CotacaoRepositoryImpl(remote);

    final resultado =
        await repository.observarMinhasCotacoes('usuario-1').first;

    expect(resultado, same(remote.cotacoes));
    expect(resultado.single, same(cotacao));
    expect(remote.idUsuarioObservado, 'usuario-1');
  });

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
  _CotacaoRemoteFake({
    required this.idEvento,
    this.cotacoes = const [],
  });

  final String idEvento;
  final List<CotacaoModel> cotacoes;
  String? idUsuarioObservado;
  String? idCotacao;
  String? idFornecedor;
  String? nomeFornecedor;
  String? idSolicitante;
  String? nomeSolicitante;

  @override
  Stream<List<CotacaoModel>> observarMinhasCotacoes(String idUsuario) {
    idUsuarioObservado = idUsuario;
    return Stream.value(cotacoes);
  }

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

CotacaoModel _cotacao() {
  return CotacaoModel(
    id: 'cotacao-1',
    idEvento: 'evento-1',
    idUsuarioSolicitante: 'usuario-1',
    nomeUsuarioSolicitante: 'Ana',
    dataCadastro: DateTime(2026),
    status: StatusCotacao.pendente,
    categoriaNome: 'Buffet',
    descricao: 'Doces e salgados',
    fornecedores: const [],
    servicos: const [],
  );
}
