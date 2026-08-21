import '../../domain/repositories/fornecedor_recomendacao_repository.dart';
import '../datasources/remote/fornecedor_recomendacao_remote_datasource.dart';
import '../models/fornecedor/fornecedor_recomendacao_model.dart';

class FornecedorRecomendacaoRepositoryImpl
    implements FornecedorRecomendacaoRepository {
  FornecedorRecomendacaoRepositoryImpl(this.remote);

  final FornecedorRecomendacaoRemoteDatasource remote;

  @override
  Future<List<FornecedorRecomendacaoModel>> carregarRecomendacoesSalvas({
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
  Future<List<FornecedorRecomendacaoModel>> gerarRecomendacoes({
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
