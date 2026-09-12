import 'categoria_servico.dart';
import 'endereco_usuario.dart';
import 'fornecedor.dart';
import 'fornecedor_categoria.dart';
import 'fornecedor_produto_servico.dart';
import 'subcategoria_servico.dart';

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

  final List<Fornecedor> fornecedores;
  final List<EnderecoUsuario> enderecos;
  final List<FornecedorCategoria> categoriasFornecedor;
  final List<Map<String, dynamic>> categoriasServico;
  final List<CategoriaServico> categorias;
  final List<Map<String, dynamic>> subcategoriasServico;
  final List<SubcategoriaServico> subcategorias;
  final List<FornecedorProdutoServico> servicosFornecedor;
}
