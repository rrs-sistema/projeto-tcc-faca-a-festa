import '../endereco/endereco_usuario.dart';
import '../servico_produto/categoria_servico_model.dart';
import '../servico_produto/fornecedor_categoria_model.dart';
import '../servico_produto/fornecedor_produto_servico_model.dart';
import '../servico_produto/subcategoria_servico_model.dart';
import 'fornecedor_model.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_admin_snapshot.dart'
    as domain;


class FornecedorAdminSnapshot extends domain.FornecedorAdminSnapshot {
  const FornecedorAdminSnapshot({
    required List<FornecedorModel> fornecedores,
    required List<EnderecoUsuarioModel> enderecos,
    required List<FornecedorCategoriaModel> categoriasFornecedor,
    required List<CategoriaServicoModel> categorias,
    required List<SubcategoriaServicoModel> subcategorias,
    required List<FornecedorProdutoServicoModel> servicosFornecedor,
  }) : super(
          fornecedores: fornecedores,
          enderecos: enderecos,
          categoriasFornecedor: categoriasFornecedor,
          categorias: categorias,
          subcategorias: subcategorias,
          servicosFornecedor: servicosFornecedor,
        );
}
