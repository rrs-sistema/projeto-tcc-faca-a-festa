import 'dart:io';
import 'dart:typed_data';

import '../../data/models/evento/evento_model.dart';
import '../../data/models/fornecedor/fornecedor_admin_snapshot.dart';
import '../../data/models/fornecedor/fornecedor_estatisticas_model.dart';
import '../../data/models/fornecedor/fornecedor_model.dart';
import '../../data/models/servico_produto/fornecedor_categoria_model.dart';
import '../../data/models/servico_produto/fornecedor_produto_servico_model.dart';

abstract interface class FornecedorRepository {
  Future<FornecedorAdminSnapshot> carregarSnapshotAdmin({
    required bool incluirEnderecos,
  });

  Future<FornecedorModel?> buscarPorUsuario(String idUsuario);

  Future<FornecedorModel?> buscarPorIdUsuario(String idUsuario);

  Future<EventoModel?> buscarEventoPorId(String idEvento);

  Stream<FornecedorModel?> observarFornecedorAtivo(String idFornecedor);

  Stream<int> observarMensagensNaoLidas(String idFornecedor);

  Stream<int> observarSolicitacoesPendentes(String idFornecedor);

  Stream<List<FornecedorProdutoServicoModel>> observarServicosFornecedor(
    String idFornecedor,
  );

  Future<List<FornecedorProdutoServicoModel>> listarServicosPorEvento(
    String idEvento,
  );

  Future<List<FornecedorModel>> listarFornecedoresDoEvento(String idEvento);

  Future<List<Map<String, dynamic>>> listarSolicitacoesPendentesDetalhadas(
    String idFornecedor,
  );

  Future<FornecedorEstatisticasModel> carregarEstatisticas(
    String idFornecedor,
  );

  Future<void> atualizarFornecedor(FornecedorModel fornecedor);

  Future<void> salvarFornecedor(FornecedorModel fornecedor);

  Future<void> salvarCategoriaFornecedor(FornecedorCategoriaModel categoria);

  Future<void> atualizarStatusAtivo({
    required String idFornecedor,
    required bool ativo,
  });

  Future<void> atualizarAptoParaOperar({
    required String idFornecedor,
    required bool apto,
  });

  Future<void> atualizarFcmToken({
    required String idFornecedor,
    required String token,
  });

  Future<String> uploadBanner({
    required File imageFile,
    Uint8List? bytesWeb,
    required String uid,
  });

  Future<int> limparDuplicatasFornecedorCategoria();
}
