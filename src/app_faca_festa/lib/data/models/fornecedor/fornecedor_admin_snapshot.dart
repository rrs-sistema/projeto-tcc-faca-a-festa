import '../endereco/endereco_usuario.dart';
import '../servico_produto/categoria_servico_model.dart';
import '../servico_produto/fornecedor_categoria_model.dart';
import '../servico_produto/fornecedor_produto_servico_model.dart';
import '../servico_produto/subcategoria_servico_model.dart';
import 'fornecedor_model.dart';

class FornecedorAdminSnapshot {
  const FornecedorAdminSnapshot({
    required this.fornecedores,
    required this.enderecos,
    required this.categoriasFornecedor,
    required this.categoriasServico,
    required this.categorias,
    required this.subcategoriasServico,
    required this.subcategorias,
    required this.servicosFornecedor,
  });

  final List<FornecedorModel> fornecedores;
  final List<EnderecoUsuarioModel> enderecos;
  final List<FornecedorCategoriaModel> categoriasFornecedor;
  final List<Map<String, dynamic>> categoriasServico;
  final List<CategoriaServicoModel> categorias;
  final List<Map<String, dynamic>> subcategoriasServico;
  final List<SubcategoriaServicoModel> subcategorias;
  final List<FornecedorProdutoServicoModel> servicosFornecedor;
}
