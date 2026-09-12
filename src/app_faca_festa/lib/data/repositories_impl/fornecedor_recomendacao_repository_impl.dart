import 'package:app_faca_festa/domain/entities/fornecedor_recomendacao.dart';
import 'package:app_faca_festa/domain/repositories/fornecedor_recomendacao_repository.dart';
import '../datasources/remote/fornecedor_recomendacao_remote_datasource.dart';

class FornecedorRecomendacaoRepositoryImpl
    implements FornecedorRecomendacaoRepository {
  FornecedorRecomendacaoRepositoryImpl(this.remote);

  final FornecedorRecomendacaoRemoteDatasource remote;

  @override
  Future<List<FornecedorRecomendacao>> carregarRecomendacoesSalvas({
    required String idEvento,
    required String idUsuario,
    required int limite,
  }) {
    return remote.carregarRecomendacoesSalvas(
      idEvento: idEvento,
      idUsuario: idUsuario,
      limite: limite,
    );
  }

  @override
  Future<List<FornecedorRecomendacao>> gerarRecomendacoes({
    required String idEvento,
    required int limite,
    required bool modoDemo,
  }) {
    return remote.gerarRecomendacoes(
      idEvento: idEvento,
      limite: limite,
      modoDemo: modoDemo,
    );
  }

  @override
  Future<void> registrarInteracao({
    required String idEvento,
    required String idFornecedor,
    required String acao,
    String? tipoEventoId,
    String? tipoEventoNome,
    String? cidade,
  }) {
    return remote.registrarInteracao(
      idEvento: idEvento,
      idFornecedor: idFornecedor,
      acao: acao,
      tipoEventoId: tipoEventoId,
      tipoEventoNome: tipoEventoNome,
      cidade: cidade,
    );
  }
}
